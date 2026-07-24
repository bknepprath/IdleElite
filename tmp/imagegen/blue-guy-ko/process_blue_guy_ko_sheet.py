from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter


MAGENTA = (255, 0, 255)
FLAT_BLUE = (7, 153, 242)
INK = (12, 10, 18)
HIGHLIGHT = (255, 255, 255)
CELL_SIZE = 512
FRAME_SIZE = 640
GROUND_Y = 544


def _is_connected_background(pixel: tuple[int, int, int]) -> bool:
    red, green, blue = pixel
    magenta = red > 175 and blue > 145 and green < 135 and red + blue > green * 3
    white_grid = red > 238 and green > 238 and blue > 238
    return magenta or white_grid


def normalize_sheet_background(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGB")
    width, height = image.size
    pixels = image.load()
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if visited[index] or not _is_connected_background(pixels[x, y]):
            return
        visited[index] = 1
        queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        pixels[x, y] = MAGENTA
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)


def _flat_palette(frame: Image.Image) -> Image.Image:
    rgba = frame.convert("RGBA")
    red, green, blue, alpha = rgba.split()
    rgb = rgba.convert("RGB")

    dark_core = Image.new("L", rgba.size)
    white_core = Image.new("L", rgba.size)
    dark_pixels = dark_core.load()
    white_pixels = white_core.load()
    rgb_pixels = rgb.load()
    alpha_pixels = alpha.load()

    for y in range(rgba.height):
        for x in range(rgba.width):
            if alpha_pixels[x, y] < 8:
                continue
            r, g, b = rgb_pixels[x, y]
            luminance = (54 * r + 183 * g + 19 * b) // 256
            saturation = max(r, g, b) - min(r, g, b)
            if luminance < 66:
                dark_pixels[x, y] = 255
            elif luminance > 218 and saturation < 52:
                white_pixels[x, y] = 255

    dark_edge = dark_core.filter(ImageFilter.MaxFilter(5))
    white_edge = white_core.filter(ImageFilter.MaxFilter(5))
    dark_edge_pixels = dark_edge.load()
    white_edge_pixels = white_edge.load()
    out = rgba.copy()
    out_pixels = out.load()

    for y in range(rgba.height):
        for x in range(rgba.width):
            a = alpha_pixels[x, y]
            if a == 0:
                out_pixels[x, y] = (0, 0, 0, 0)
            elif dark_pixels[x, y]:
                out_pixels[x, y] = (*INK, a)
            elif white_pixels[x, y]:
                out_pixels[x, y] = (*HIGHLIGHT, a)
            elif dark_edge_pixels[x, y] or white_edge_pixels[x, y]:
                # Retain only the narrow generated antialias transition at ink/highlight edges.
                r, g, b = rgb_pixels[x, y]
                out_pixels[x, y] = (r, g, b, a)
            else:
                out_pixels[x, y] = (*FLAT_BLUE, a)
    return out


def _keep_largest_component(frame: Image.Image) -> Image.Image:
    rgba = frame.convert("RGBA")
    alpha = rgba.getchannel("A")
    width, height = rgba.size
    alpha_pixels = alpha.load()
    visited = bytearray(width * height)
    largest: list[tuple[int, int]] = []

    for start_y in range(height):
        for start_x in range(width):
            index = start_y * width + start_x
            if visited[index] or alpha_pixels[start_x, start_y] < 8:
                continue
            visited[index] = 1
            queue: deque[tuple[int, int]] = deque([(start_x, start_y)])
            component: list[tuple[int, int]] = []
            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if nx < 0 or nx >= width or ny < 0 or ny >= height:
                        continue
                    neighbor = ny * width + nx
                    if visited[neighbor] or alpha_pixels[nx, ny] < 8:
                        continue
                    visited[neighbor] = 1
                    queue.append((nx, ny))
            if len(component) > len(largest):
                largest = component

    keep_core = Image.new("L", rgba.size)
    keep_pixels = keep_core.load()
    for x, y in largest:
        keep_pixels[x, y] = 255
    keep = keep_core.filter(ImageFilter.MaxFilter(5))
    clean_alpha = Image.new("L", rgba.size)
    clean_pixels = clean_alpha.load()
    keep_pixels = keep.load()
    for y in range(height):
        for x in range(width):
            if keep_pixels[x, y]:
                clean_pixels[x, y] = alpha_pixels[x, y]
    rgba.putalpha(clean_alpha)
    return rgba


def slice_align_and_flatten(transparent_sheet: Path, output_dir: Path, preview: Path) -> None:
    sheet = Image.open(transparent_sheet).convert("RGBA")
    if sheet.size != (CELL_SIZE * 3, CELL_SIZE * 2):
        raise ValueError(f"Expected a 1536x1024 sheet, got {sheet.size}")
    output_dir.mkdir(parents=True, exist_ok=True)

    frames: list[Image.Image] = []
    for index in range(6):
        column = index % 3
        row = index // 3
        cell = sheet.crop(
            (
                column * CELL_SIZE,
                row * CELL_SIZE,
                (column + 1) * CELL_SIZE,
                (row + 1) * CELL_SIZE,
            )
        )
        flat = _flat_palette(_keep_largest_component(cell))
        bbox = flat.getchannel("A").getbbox()
        if bbox is None:
            raise ValueError(f"Frame {index + 1} is empty")
        content_center_x = (bbox[0] + bbox[2]) // 2
        paste_x = FRAME_SIZE // 2 - content_center_x
        paste_y = GROUND_Y - bbox[3]
        canvas = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        canvas.alpha_composite(flat, (paste_x, paste_y))
        frame_path = output_dir / f"blue-guy-ko-{index + 1:02d}.png"
        canvas.save(frame_path)
        frames.append(canvas)

    final_bbox = frames[-1].getchannel("A").getbbox()
    if final_bbox is None:
        raise ValueError("Final KO frame is empty")
    final_crop = frames[-1].crop(final_bbox)
    final_compat = Image.new(
        "RGBA",
        (final_crop.width + 96, final_crop.height + 96),
        (0, 0, 0, 0),
    )
    final_compat.alpha_composite(final_crop, (48, 48))
    final_compat.save(output_dir / "blue-guy-ko.png")

    checker = Image.new("RGB", (FRAME_SIZE * 3, FRAME_SIZE * 2), (245, 239, 220))
    for index, frame in enumerate(frames):
        checker.paste(frame, ((index % 3) * FRAME_SIZE, (index // 3) * FRAME_SIZE), frame)
    preview.parent.mkdir(parents=True, exist_ok=True)
    checker.save(preview)


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    normalize = subparsers.add_parser("normalize-background")
    normalize.add_argument("source", type=Path)
    normalize.add_argument("output", type=Path)

    finish = subparsers.add_parser("finish")
    finish.add_argument("transparent_sheet", type=Path)
    finish.add_argument("output_dir", type=Path)
    finish.add_argument("preview", type=Path)

    args = parser.parse_args()
    if args.command == "normalize-background":
        normalize_sheet_background(args.source, args.output)
    else:
        slice_align_and_flatten(args.transparent_sheet, args.output_dir, args.preview)


if __name__ == "__main__":
    main()
