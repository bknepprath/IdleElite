from hashlib import sha256
from pathlib import Path
from shutil import copyfile

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets/content/fight/enemies/werewolves"
BASELINE = 448
PIVOT_X = 256


def place(source: Path, target: Path, height: int | None) -> None:
    image = Image.open(source).convert("RGBA")
    alpha_box = image.getchannel("A").getbbox()
    assert alpha_box is not None, source
    crop = image.crop(alpha_box)
    if height is not None:
        width = round(crop.width * height / crop.height)
        crop = crop.resize((width, height), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (512, 512))
    canvas.alpha_composite(crop, (PIVOT_X - crop.width // 2, BASELINE - crop.height))
    canvas.save(target)


place(ROOT / "assets/content/fight/enemies/guys/guys-idle.png", OUT / "werewolves-transform-01.png", None)
place(Path(__file__).with_name("werewolf-transform-02-alpha.png"), OUT / "werewolves-transform-02.png", 386)
place(Path(__file__).with_name("werewolf-transform-03-alpha.png"), OUT / "werewolves-transform-03.png", 380)
place(Path(__file__).with_name("werewolf-transform-04-alpha.png"), OUT / "werewolves-transform-04.png", 375)
copyfile(OUT / "werewolves-move-01.png", OUT / "werewolves-transform-05.png")

for frame in range(1, 6):
    path = OUT / f"werewolves-transform-{frame:02d}.png"
    image = Image.open(path)
    box = image.getchannel("A").getbbox()
    assert image.mode == "RGBA" and image.size == (512, 512), path
    assert box is not None and box[0] >= 32 and box[1] >= 32 and box[2] <= 480 and box[3] <= 449, (path, box)

assert sha256((OUT / "werewolves-transform-05.png").read_bytes()).digest() == sha256((OUT / "werewolves-move-01.png").read_bytes()).digest()

proof_path = ROOT / "tmp/validation/fight-monster-real-game/werewolf-transform-frames-proof.png"
proof_path.parent.mkdir(parents=True, exist_ok=True)
proof = Image.new("RGB", (2560, 512), (248, 241, 229))
for frame in range(1, 6):
    image = Image.open(OUT / f"werewolves-transform-{frame:02d}.png").convert("RGBA")
    proof.paste(image, ((frame - 1) * 512, 0), image)
proof.save(proof_path)

print("werewolf-transform-normalization-ok")
