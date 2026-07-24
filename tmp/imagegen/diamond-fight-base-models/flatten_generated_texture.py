from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


def flatten(
    input_path: Path,
    output_path: Path,
    ink_threshold: int,
    color_edge_threshold: int,
    min_region: int,
) -> None:
    image = Image.open(input_path).convert("RGBA")
    pixels = np.asarray(image).copy()
    rgb = pixels[:, :, :3]
    alpha = pixels[:, :, 3]
    ink = (alpha == 255) & (rgb.max(axis=2) <= ink_threshold)
    protected_ink = ink.copy()
    protected_ink[1:, :] |= ink[:-1, :]
    protected_ink[:-1, :] |= ink[1:, :]
    protected_ink[:, 1:] |= ink[:, :-1]
    protected_ink[:, :-1] |= ink[:, 1:]
    fill = (alpha == 255) & ~protected_ink

    height, width = fill.shape
    labels = np.full((height, width), -1, dtype=np.int32)
    regions: list[list[tuple[int, int]]] = []

    for start_y, start_x in zip(*np.nonzero(fill & (labels == -1))):
        if labels[start_y, start_x] != -1:
            continue
        label = len(regions)
        labels[start_y, start_x] = label
        queue = deque([(start_y, start_x)])
        region: list[tuple[int, int]] = []
        while queue:
            y, x = queue.popleft()
            region.append((y, x))
            for next_y, next_x in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if (
                    0 <= next_y < height
                    and 0 <= next_x < width
                    and fill[next_y, next_x]
                    and labels[next_y, next_x] == -1
                    and np.max(
                        np.abs(
                            rgb[y, x].astype(np.int16)
                            - rgb[next_y, next_x].astype(np.int16)
                        )
                    )
                    <= color_edge_threshold
                ):
                    labels[next_y, next_x] = label
                    queue.append((next_y, next_x))
        regions.append(region)

    for label, region in enumerate(regions):
        if len(region) < min_region:
            continue
        points = np.asarray(region)
        ys, xs = points[:, 0], points[:, 1]
        flat_color = np.median(rgb[ys, xs], axis=0).astype(np.uint8)
        rgb[ys, xs] = flat_color

    output_path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(pixels, "RGBA").save(output_path)


def main() -> None:
    parser = argparse.ArgumentParser(description="Flatten ImageGen texture inside thick-ink color regions.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--ink-threshold", type=int, default=55)
    parser.add_argument("--color-edge-threshold", type=int, default=48)
    parser.add_argument("--min-region", type=int, default=24)
    args = parser.parse_args()
    flatten(
        args.input,
        args.output,
        args.ink_threshold,
        args.color_edge_threshold,
        args.min_region,
    )


if __name__ == "__main__":
    main()
