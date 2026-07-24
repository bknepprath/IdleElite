from pathlib import Path

from PIL import Image


SOURCE_DIR = Path(__file__).resolve().parent / "adult-corrected-sources/keyed"
BASE = Path(__file__).resolve().parent / "dragon-final.png"
OUT = Path(__file__).resolve().parent / "adult-corrected-runtime"
CANVAS = 512
BASELINE = 448
SAFE_MARGIN = 32
GENERATED_SCALE = 0.38
BASE_TARGET_WIDTH = 404


def normalized(source: Path, scale: float | None = None, target_width: int | None = None) -> Image.Image:
    image = Image.open(source).convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    assert bbox is not None, source
    body = image.crop(bbox)
    if target_width is not None:
        scale = target_width / body.width
    assert scale is not None
    size = (round(body.width * scale), round(body.height * scale))
    body = body.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")
    canvas = Image.new("RGBA", (CANVAS, CANVAS))
    x = (CANVAS - body.width) // 2
    y = BASELINE - body.height
    canvas.alpha_composite(body, (x, y))
    final_bbox = canvas.getchannel("A").getbbox()
    assert final_bbox is not None
    assert final_bbox[0] >= SAFE_MARGIN and final_bbox[1] >= SAFE_MARGIN, (source, final_bbox)
    assert final_bbox[2] <= CANVAS - SAFE_MARGIN and final_bbox[3] <= CANVAS - SAFE_MARGIN, (source, final_bbox)
    return canvas


def save(image: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    image.save(OUT / name)


base = normalized(BASE, target_width=BASE_TARGET_WIDTH)
save(base, "dragons-move-01.png")
save(base, "dragons-idle.png")

for frame in range(2, 5):
    save(normalized(SOURCE_DIR / f"move-{frame:02d}-keyed.png", GENERATED_SCALE), f"dragons-move-{frame:02d}.png")

states = {
    "hit": "hit-keyed.png",
    "dizzy": "dizzy-keyed.png",
    "defeated": "defeated-keyed.png",
}
for state, source in states.items():
    save(normalized(SOURCE_DIR / source, GENERATED_SCALE), f"dragons-{state}.png")

for attack in ("claw", "breath"):
    for frame in range(1, 5):
        save(
            normalized(SOURCE_DIR / f"{attack}-{frame:02d}-keyed.png", GENERATED_SCALE),
            f"dragons-{attack}-{frame:02d}.png",
        )

reaction_names = ["dragons-hit.png", "dragons-dizzy.png", "dragons-defeated.png", "dragons-idle.png"]
for frame, source in enumerate(reaction_names, 1):
    Image.open(OUT / source).save(OUT / f"dragon-reaction-{frame:02d}.png")


def master(rows: list[list[str]], name: str) -> None:
    sheet = Image.new("RGBA", (CANVAS * 4, CANVAS * len(rows)))
    for row, names in enumerate(rows):
        for column, source in enumerate(names):
            sheet.alpha_composite(Image.open(OUT / source).convert("RGBA"), (column * CANVAS, row * CANVAS))
    sheet.save(OUT / name)


master(
    [
        [f"dragons-move-{frame:02d}.png" for frame in range(1, 5)],
        ["dragons-idle.png", "dragons-hit.png", "dragons-dizzy.png", "dragons-defeated.png"],
        [f"dragon-reaction-{frame:02d}.png" for frame in range(1, 5)],
    ],
    "fight-dragons-main-master.png",
)
master([[f"dragons-claw-{frame:02d}.png" for frame in range(1, 5)], [], []], "fight-dragons-claw-master.png")
master([[f"dragons-breath-{frame:02d}.png" for frame in range(1, 5)], [], []], "fight-dragons-breath-master.png")
master(
    [["dragons-idle.png", "dragons-hit.png", "dragons-dizzy.png", "dragons-defeated.png"]],
    "dragons-states-source.png",
)
master([[f"dragons-claw-{frame:02d}.png" for frame in range(1, 5)]], "dragons-claw-source.png")
master([[f"dragons-breath-{frame:02d}.png" for frame in range(1, 5)]], "dragons-breath-source.png")


def preview(names: list[str], name: str) -> None:
    frames = [Image.open(OUT / source).convert("RGBA") for source in names]
    frames[0].save(OUT / name, save_all=True, append_images=frames[1:], duration=140, loop=0, disposal=2)


claw_frames = [f"dragons-claw-{frame:02d}.png" for frame in range(1, 5)]
breath_frames = [f"dragons-breath-{frame:02d}.png" for frame in range(1, 5)]
preview(claw_frames, "dragons-attack-preview.gif")
preview(claw_frames, "dragons-claw-preview.gif")
preview(breath_frames, "dragons-breath-preview.gif")

expected_png = 4 + 4 + 8 + 4 + 6
assert len(list(OUT.glob("*.png"))) == expected_png
assert len(list(OUT.glob("*.gif"))) == 3
print(f"adult-dragon-runtime-ok files={expected_png + 3}")
