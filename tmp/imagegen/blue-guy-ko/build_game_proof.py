from pathlib import Path

from PIL import Image


ROOT = Path(r"C:\Users\bknep\Documents\Idle Slop 1")
PROOF_DIR = ROOT / "outputs" / "blue-guy-ko-proof"
CROP = (300, 640, 780, 1000)


frames = [
    Image.open(PROOF_DIR / f"blue-guy-ko-sequence-{index:02d}.png")
    .convert("RGB")
    .crop(CROP)
    for index in range(1, 7)
]

contact = Image.new("RGB", (frames[0].width * 3, frames[0].height * 2), (245, 239, 220))
for index, frame in enumerate(frames):
    contact.paste(frame, ((index % 3) * frame.width, (index // 3) * frame.height))
contact.save(PROOF_DIR / "blue-guy-ko-in-game-contact-sheet.png")

frames[0].save(
    PROOF_DIR / "blue-guy-ko-in-game-preview.gif",
    save_all=True,
    append_images=frames[1:],
    duration=[140, 140, 140, 140, 180, 1100],
    loop=0,
    optimize=False,
)
