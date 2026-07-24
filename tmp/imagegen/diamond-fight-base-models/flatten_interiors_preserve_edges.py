#!/usr/bin/env python3
"""Flatten low-contrast interior color variation without touching smooth edges."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return mask
    image = Image.fromarray((mask.astype(np.uint8) * 255), mode="L")
    return np.asarray(image.filter(ImageFilter.MaxFilter(radius * 2 + 1))) > 0


def local_rgb_delta(rgb: np.ndarray) -> np.ndarray:
    rgb16 = rgb.astype(np.int16)
    delta = np.zeros(rgb.shape[:2], dtype=np.int16)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        shifted = np.roll(rgb16, (dy, dx), axis=(0, 1))
        difference = np.max(np.abs(rgb16 - shifted), axis=2)
        if dy == -1:
            difference[-1, :] = 255
        elif dy == 1:
            difference[0, :] = 255
        elif dx == -1:
            difference[:, -1] = 255
        else:
            difference[:, 0] = 255
        delta = np.maximum(delta, difference)
    return delta


def components(mask: np.ndarray):
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    for start_y, start_x in zip(*np.nonzero(mask)):
        if seen[start_y, start_x]:
            continue
        queue = deque([(int(start_y), int(start_x))])
        seen[start_y, start_x] = True
        ys: list[int] = []
        xs: list[int] = []
        while queue:
            y, x = queue.popleft()
            ys.append(y)
            xs.append(x)
            for next_y, next_x in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if (
                    0 <= next_y < height
                    and 0 <= next_x < width
                    and mask[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    queue.append((next_y, next_x))
        yield np.asarray(ys), np.asarray(xs)


def decontaminate_translucent_edge(rgba: np.ndarray) -> None:
    """Copy nearby solid outline color into translucent edge RGB; keep alpha exact."""
    alpha = rgba[:, :, 3]
    target = (alpha > 0) & (alpha < 255)
    known = alpha == 255
    height, width = target.shape

    for _ in range(16):
        pending_y, pending_x = np.nonzero(target & ~known)
        if len(pending_y) == 0:
            break
        assignments: list[tuple[int, int, np.ndarray]] = []
        for y, x in zip(pending_y.tolist(), pending_x.tolist()):
            neighbors = []
            for next_y in range(max(0, y - 1), min(height, y + 2)):
                for next_x in range(max(0, x - 1), min(width, x + 2)):
                    if known[next_y, next_x]:
                        neighbors.append(rgba[next_y, next_x, :3])
            if neighbors:
                colors = np.asarray(neighbors)
                luminance = colors[:, 0] * 3 + colors[:, 1] * 6 + colors[:, 2]
                assignments.append((y, x, colors[int(np.argmin(luminance))]))
        if not assignments:
            break
        for y, x, color in assignments:
            rgba[y, x, :3] = color
            known[y, x] = True


def remove_isolated_light_specks(rgba: np.ndarray) -> np.ndarray:
    """Replace isolated light contamination inside opaque fills, never near alpha edges."""
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]
    median = np.asarray(
        Image.fromarray(rgb, mode="RGB").filter(ImageFilter.MedianFilter(5))
    )
    rgb16 = rgb.astype(np.int16)
    median16 = median.astype(np.int16)
    delta = np.max(np.abs(rgb16 - median16), axis=2)
    luminance = rgb16[:, :, 0] * 3 + rgb16[:, :, 1] * 6 + rgb16[:, :, 2]
    median_luminance = (
        median16[:, :, 0] * 3 + median16[:, :, 1] * 6 + median16[:, :, 2]
    )
    near_alpha_edge = dilate(alpha < 255, 2)
    speck = (
        (alpha == 255)
        & ~near_alpha_edge
        & (delta >= 38)
        & ((luminance - median_luminance) >= 260)
    )
    rgba[speck, :3] = median[speck]
    return speck


def flatten_image(
    source: Path,
    destination: Path,
    edge_threshold: int,
    edge_radius: int,
    min_region: int,
) -> tuple[int, int, int]:
    original = np.asarray(Image.open(source).convert("RGBA"))
    output = original.copy()
    despeckled = remove_isolated_light_specks(output)
    rgb = output[:, :, :3]
    alpha = original[:, :, 3]

    alpha_boundary = alpha < 255
    color_boundary = local_rgb_delta(rgb) >= edge_threshold
    dark_ink = (rgb[:, :, 0].astype(np.int16) * 3 + rgb[:, :, 1].astype(np.int16) * 6 + rgb[:, :, 2]) < 650
    protected = dilate(alpha_boundary | color_boundary | dark_ink, edge_radius)
    interior = (alpha == 255) & ~protected

    changed_pixels = 0
    flattened_regions = 0
    for ys, xs in components(interior):
        if len(ys) < min_region:
            continue
        colors = rgb[ys, xs]
        fill = np.median(colors, axis=0).round().astype(np.uint8)
        changed_pixels += int(np.count_nonzero(np.any(colors != fill, axis=1)))
        output[ys, xs, :3] = fill
        flattened_regions += 1

    decontaminate_translucent_edge(output)
    output[alpha == 0, :3] = 0

    if not np.array_equal(output[:, :, 3], original[:, :, 3]):
        raise AssertionError("Alpha channel changed")
    protected_opaque = protected & (alpha == 255) & ~despeckled
    if not np.array_equal(output[protected_opaque], original[protected_opaque]):
        raise AssertionError("Protected opaque edge pixels changed")

    destination.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(output, mode="RGBA").save(destination)
    return changed_pixels, flattened_regions, int(protected.sum())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--edge-threshold", type=int, default=18)
    parser.add_argument("--edge-radius", type=int, default=2)
    parser.add_argument("--min-region", type=int, default=12)
    args = parser.parse_args()
    changed, regions, protected = flatten_image(
        args.source,
        args.destination,
        args.edge_threshold,
        args.edge_radius,
        args.min_region,
    )
    print(f"changed={changed} regions={regions} protected={protected}")


if __name__ == "__main__":
    main()
