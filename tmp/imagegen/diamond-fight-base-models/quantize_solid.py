from __future__ import annotations

import argparse
from collections import Counter, deque
from pathlib import Path

import numpy as np
from PIL import Image


def quantize_solid(
    input_path: Path,
    output_path: Path,
    colors: int,
    alpha_threshold: int,
    min_island: int,
    ink_threshold: int,
) -> None:
    image = Image.open(input_path).convert("RGBA")
    pixels = np.asarray(image).copy()
    opaque = pixels[:, :, 3] >= alpha_threshold
    samples = pixels[:, :, :3][opaque]
    if not len(samples):
        raise ValueError(f"No opaque pixels found in {input_path}")

    strip = Image.fromarray(samples.reshape(1, -1, 3), "RGB")
    palette_image = strip.quantize(
        colors=colors,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    )
    palette = np.asarray(palette_image.getpalette(), dtype=np.int32).reshape(-1, 3)[:colors]

    source = pixels[:, :, :3][opaque].astype(np.int32)
    distances = ((source[:, None, :] - palette[None, :, :]) ** 2).sum(axis=2)
    indices = np.argmin(distances, axis=1)
    index_map = np.full(opaque.shape, -1, dtype=np.int16)
    index_map[opaque] = indices

    height, width = opaque.shape
    visited = np.zeros(opaque.shape, dtype=bool)
    replacements: list[tuple[list[tuple[int, int]], int]] = []
    for start_y, start_x in zip(*np.nonzero(opaque)):
        if visited[start_y, start_x]:
            continue
        color_index = int(index_map[start_y, start_x])
        visited[start_y, start_x] = True
        queue = deque([(start_y, start_x)])
        component: list[tuple[int, int]] = []
        neighbors: Counter[int] = Counter()
        while queue:
            y, x = queue.popleft()
            component.append((y, x))
            for next_y in range(max(0, y - 1), min(height, y + 2)):
                for next_x in range(max(0, x - 1), min(width, x + 2)):
                    next_index = int(index_map[next_y, next_x])
                    if next_index == color_index and not visited[next_y, next_x]:
                        visited[next_y, next_x] = True
                        queue.append((next_y, next_x))
                    elif next_index >= 0 and next_index != color_index:
                        neighbors[next_index] += 1

        if (
            len(component) < min_island
            and palette[color_index].max() > ink_threshold
            and neighbors
        ):
            replacements.append((component, neighbors.most_common(1)[0][0]))

    for component, replacement in replacements:
        ys, xs = zip(*component)
        index_map[ys, xs] = replacement

    pixels[:, :, :3][opaque] = palette[index_map[opaque]].astype(np.uint8)
    pixels[:, :, :3][~opaque] = 0
    pixels[:, :, 3] = np.where(opaque, 255, 0).astype(np.uint8)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(pixels, "RGBA").save(output_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--colors", type=int, default=10)
    parser.add_argument("--alpha-threshold", type=int, default=128)
    parser.add_argument("--min-island", type=int, default=16)
    parser.add_argument("--ink-threshold", type=int, default=55)
    args = parser.parse_args()
    quantize_solid(
        args.input,
        args.output,
        args.colors,
        args.alpha_threshold,
        args.min_island,
        args.ink_threshold,
    )


if __name__ == "__main__":
    main()
