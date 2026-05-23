from __future__ import annotations

import math
from pathlib import Path
from textwrap import wrap

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "play-store" / "assets"

FONT = Path("C:/Windows/Fonts/segoeui.ttf")
FONT_BOLD = Path("C:/Windows/Fonts/segoeuib.ttf")


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    path = FONT_BOLD if bold else FONT
    return ImageFont.truetype(str(path), size)


INK = (24, 22, 20)
PAPER = (248, 241, 229)
PANEL = (255, 253, 248)
LINE = (217, 207, 188)
GOLD = (255, 213, 84)
GREEN = (54, 122, 82)
BLUE = (48, 132, 190)
PURPLE = (117, 87, 173)
RED = (189, 72, 61)


def rounded(draw: ImageDraw.ImageDraw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return img


def paste_contain(base: Image.Image, src: Image.Image, box, pad=0):
    x0, y0, x1, y1 = box
    max_w, max_h = x1 - x0 - pad * 2, y1 - y0 - pad * 2
    img = src.copy()
    img.thumbnail((max_w, max_h), Image.Resampling.LANCZOS)
    x = x0 + pad + (max_w - img.width) // 2
    y = y0 + pad + (max_h - img.height) // 2
    base.alpha_composite(img, (x, y))


def draw_centered(draw, text, y, fnt, fill=INK, width=1080):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    draw.text(((width - (bbox[2] - bbox[0])) // 2, y), text, font=fnt, fill=fill)


def draw_wrapped(draw, text, xy, fnt, fill, max_width, line_gap=8):
    x, y = xy
    words = text.split()
    lines = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if draw.textlength(candidate, font=fnt) <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    for line in lines:
        draw.text((x, y), line, font=fnt, fill=fill)
        y += fnt.size + line_gap
    return y


def load_asset(path: str) -> Image.Image:
    return Image.open(ROOT / path).convert("RGBA")


SKILL_ICONS = {
    "fight": load_asset("docs/assets/icons/fight.png"),
    "thieving": load_asset("docs/assets/icons/thieving.png"),
    "build": load_asset("docs/assets/icons/build.png"),
    "woodcutting": load_asset("docs/assets/icons/woodcutting.png"),
    "fishing": load_asset("docs/assets/icons/fishing.png"),
    "gear": load_asset("docs/assets/icons/gear.png"),
}
HERO = load_asset("docs/assets/characters/stick-hero.png")


def make_icon():
    img = draw_character_head_icon(512, rounded_frame=True)
    img.save(OUT / "app-icon-512.png")


def draw_character_head_icon(size: int, rounded_frame: bool = True) -> Image.Image:
    head_crop = HERO.crop((238, 78, 786, 626))
    return head_crop.resize((size, size), Image.Resampling.LANCZOS)


def phone_ui(w=560, h=995):
    img = Image.new("RGBA", (w, h), PAPER + (255,))
    d = ImageDraw.Draw(img)
    rounded(d, (0, 0, w - 1, h - 1), 46, (22, 21, 19), None)
    rounded(d, (16, 16, w - 17, h - 17), 34, PAPER, None)
    d.rectangle((16, 74, w - 17, h - 17), fill=PAPER)
    draw_centered(d, "IDLE ELITE", 42, font(38, True), width=w, fill=(75, 63, 21))
    d.text((44, 104), "Global Lv 12", font=font(23, True), fill=INK)
    d.text((w - 182, 104), "$14,500", font=font(23, True), fill=INK)

    y = 154
    skills = [
        ("Fight", RED, "Lv 3", "17/25"),
        ("Thieving", PURPLE, "Lv 2", "8/20"),
        ("Build", BLUE, "Lv 4", "28/30"),
        ("Woodcut", GREEN, "Lv 2", "12/20"),
        ("Fishing", (39, 151, 168), "Lv 3", "21/25"),
    ]
    for name, color, lvl, stamina in skills:
        rounded(d, (38, y, w - 38, y + 76), 18, PANEL, LINE, 3)
        d.ellipse((58, y + 15, 104, y + 61), fill=color)
        d.text((122, y + 13), name, font=font(27, True), fill=INK)
        d.text((122, y + 45), lvl, font=font(20), fill=(92, 84, 72))
        d.text((w - 172, y + 26), f"{stamina} stam", font=font(20, True), fill=color)
        y += 90

    rounded(d, (38, 622, w - 38, 834), 22, PANEL, LINE, 3)
    d.text((64, 646), "Fishing", font=font(31, True), fill=(29, 108, 128))
    d.text((64, 688), "Cast From Dock", font=font(27, True), fill=INK)
    d.text((64, 730), "XP  980 / 1300", font=font(21), fill=(92, 84, 72))
    rounded(d, (64, 768, w - 64, 796), 14, (228, 221, 207), None)
    rounded(d, (64, 768, 374, 796), 14, (56, 166, 188), None)
    rounded(d, (64, 820, w - 64, 884), 22, (33, 93, 108), None)
    draw_centered(d, "START CAST", 834, font(27, True), fill=(255, 255, 255), width=w)

    d.rectangle((16, h - 112, w - 17, h - 17), fill=(245, 237, 222))
    for i, label in enumerate(["Jobs", "Gear", "Hero"]):
        x = 75 + i * 155
        d.text((x, h - 78), label, font=font(26, True), fill=INK if i == 0 else (103, 94, 80))
    return img


def draw_store_screenshot(filename, headline, subhead, accent, scene_icon_keys, stat_lines):
    w, h = 1080, 1920
    img = gradient((w, h), (255, 247, 229), (226, 244, 242)).convert("RGBA")
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, w, 445), fill=accent + (255,))
    d.rectangle((0, 372, w, 445), fill=(24, 22, 20, 255))
    draw_centered(d, headline, 80, font(76, True), fill=(255, 255, 255), width=w)
    wrapped = "\n".join(wrap(subhead, 31))
    yy = 178
    for line in wrapped.splitlines():
        draw_centered(d, line, yy, font(39, True), fill=(255, 247, 210), width=w)
        yy += 48

    phone = phone_ui()
    shadow = Image.new("RGBA", (phone.width + 60, phone.height + 60), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    rounded(sd, (30, 30, phone.width + 30, phone.height + 30), 46, (0, 0, 0, 85), None)
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(shadow, (258, 508))
    img.alpha_composite(phone, (288, 526))

    hero = HERO.copy()
    hero.thumbnail((300, 450), Image.Resampling.LANCZOS)
    img.alpha_composite(hero, (60, 1248))

    x = 766
    y = 1118
    for key in scene_icon_keys:
        icon = SKILL_ICONS[key].copy()
        icon.thumbnail((124, 124), Image.Resampling.LANCZOS)
        img.alpha_composite(icon, (x, y))
        y += 142

    y = 1548
    for label, value in stat_lines:
        rounded(d, (660, y, 1018, y + 74), 20, (255, 253, 248, 235), LINE, 2)
        d.text((682, y + 15), label, font=font(24, True), fill=INK)
        d.text((900, y + 15), value, font=font(24, True), fill=accent)
        y += 86

    img.convert("RGB").save(OUT / filename, quality=95)


def make_feature_graphic():
    w, h = 1024, 500
    img = gradient((w, h), (41, 105, 119), (255, 219, 103)).convert("RGBA")
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, w, h), outline=(24, 22, 20), width=0)
    d.text((58, 72), "IDLE ELITE", font=font(82, True), fill=(255, 255, 255))
    d.text((62, 160), "Train every skill. Become absurdly elite.", font=font(31, True), fill=(255, 247, 210))
    rounded(d, (62, 232, 465, 306), 28, (24, 22, 20), None)
    d.text((92, 249), "Fight  Fish  Build  Sneak  Chop", font=font(27, True), fill=GOLD)
    hero = HERO.copy()
    hero.thumbnail((330, 430), Image.Resampling.LANCZOS)
    img.alpha_composite(hero, (662, 64))
    for i, key in enumerate(["fight", "fishing", "build", "thieving", "woodcutting"]):
        icon = SKILL_ICONS[key].copy()
        icon.thumbnail((102, 102), Image.Resampling.LANCZOS)
        img.alpha_composite(icon, (58 + i * 112, 352))
    img.convert("RGB").save(OUT / "feature-graphic-1024x500.png", quality=95)


def make_ads():
    specs = [
        ("ad-landscape-1200x628.png", 1200, 628),
        ("ad-square-1200x1200.png", 1200, 1200),
        ("ad-portrait-1200x1500.png", 1200, 1500),
    ]
    for filename, w, h in specs:
        img = gradient((w, h), (250, 239, 214), (214, 241, 238)).convert("RGBA")
        d = ImageDraw.Draw(img)
        margin = int(min(w, h) * 0.08)
        rounded(d, (margin, margin, w - margin, h - margin), 40, (255, 253, 248, 230), LINE, 4)
        hero = HERO.copy()
        hero.thumbnail((int(w * 0.34), int(h * 0.64)), Image.Resampling.LANCZOS)
        img.alpha_composite(hero, ((w - hero.width) // 2, int(h * 0.18)))
        radius = min(w, h) * 0.32
        cx, cy = w // 2, int(h * 0.52)
        keys = ["fight", "fishing", "build", "thieving", "woodcutting"]
        for i, key in enumerate(keys):
            angle = -math.pi / 2 + i * 2 * math.pi / len(keys)
            icon = SKILL_ICONS[key].copy()
            icon.thumbnail((int(min(w, h) * 0.18), int(min(w, h) * 0.18)), Image.Resampling.LANCZOS)
            x = int(cx + math.cos(angle) * radius - icon.width / 2)
            y = int(cy + math.sin(angle) * radius - icon.height / 2)
            img.alpha_composite(icon, (x, y))
        img.convert("RGB").save(OUT / filename, quality=95)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    make_icon()
    make_feature_graphic()
    screenshots = [
        ("screenshot-01-train-five-skills-1080x1920.png", "TRAIN FIVE SKILLS", "Fight, fish, chop, build, and sneak your way up.", RED, ["fight", "woodcutting", "fishing"], [("Skills", "5"), ("Jobs", "20+"), ("Goal", "Elite")]),
        ("screenshot-02-stamina-choices-1080x1920.png", "ROTATE JOBS", "Each skill has its own stamina, so every check-in has a plan.", GREEN, ["woodcutting", "build", "gear"], [("Stamina", "Full"), ("Boosts", "Ready"), ("Cash", "+$450")]),
        ("screenshot-03-level-up-1080x1920.png", "LEVEL UP FAST", "Earn XP, cash, fish, logs, and better actions.", BLUE, ["fishing", "fight", "thieving"], [("Global", "Lv 12"), ("Next", "Pier"), ("XP", "76%")]),
        ("screenshot-04-offline-progress-1080x1920.png", "COME BACK STRONGER", "Offline progress and upgrades keep the idle loop moving.", PURPLE, ["gear", "build", "fishing"], [("Away", "2h"), ("Bonus", "x2"), ("Loot", "Claim")]),
        ("screenshot-05-idle-elitist-1080x1920.png", "BECOME ELITE", "A handmade idle RPG about small jobs and huge progress.", (196, 119, 38), ["fight", "gear", "woodcutting"], [("Title", "Elitist"), ("Prestige", "Soon"), ("Vibe", "Cozy")]),
    ]
    for args in screenshots:
        draw_store_screenshot(*args)
    make_ads()


if __name__ == "__main__":
    main()
