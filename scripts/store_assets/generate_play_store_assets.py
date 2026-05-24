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


def paste_cover(base: Image.Image, src: Image.Image, box):
    x0, y0, x1, y1 = box
    target_w, target_h = x1 - x0, y1 - y0
    img = src.copy()
    ratio = max(target_w / img.width, target_h / img.height)
    img = img.resize((math.ceil(img.width * ratio), math.ceil(img.height * ratio)), Image.Resampling.LANCZOS)
    x = (img.width - target_w) // 2
    y = (img.height - target_h) // 2
    base.alpha_composite(img.crop((x, y, x + target_w, y + target_h)), (x0, y0))


def chroma_to_alpha(src: Image.Image, keys=((255, 0, 255), (0, 255, 0)), tolerance=74) -> Image.Image:
    img = src.convert("RGBA")
    pixels = []
    data = img.get_flattened_data() if hasattr(img, "get_flattened_data") else img.getdata()
    for r, g, b, a in data:
        remove = False
        for kr, kg, kb in keys:
            if abs(r - kr) + abs(g - kg) + abs(b - kb) < tolerance:
                remove = True
                break
        pixels.append((r, g, b, 0 if remove else a))
    img.putdata(pixels)
    return img


def paste_shadow(base: Image.Image, src: Image.Image, xy, blur=18, offset=(0, 18), opacity=110):
    x, y = xy
    alpha = src.getchannel("A").point(lambda a: int(a * opacity / 255))
    shadow = Image.new("RGBA", src.size, (0, 0, 0, 0))
    shadow.putalpha(alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(shadow, (x + offset[0], y + offset[1]))
    base.alpha_composite(src, xy)


def draw_fit_center(draw, text, y, max_width, max_size, min_size, fill, bold=True, stroke_fill=None, stroke_width=0):
    size = max_size
    fnt = font(size, bold)
    while size > min_size and draw.textlength(text, font=fnt) > max_width:
        size -= 2
        fnt = font(size, bold)
    bbox = draw.textbbox((0, 0), text, font=fnt, stroke_width=stroke_width)
    x = (1080 - (bbox[2] - bbox[0])) // 2
    draw.text((x, y), text, font=fnt, fill=fill, stroke_width=stroke_width, stroke_fill=stroke_fill)
    return y + bbox[3] - bbox[1]


def draw_pill(draw, xy, text, fill, text_fill=(255, 255, 255), outline=None):
    x0, y0, x1, y1 = xy
    rounded(draw, xy, (y1 - y0) // 2, fill, outline, 3 if outline else 1)
    fnt = font(34, True)
    bbox = draw.textbbox((0, 0), text, font=fnt)
    draw.text((x0 + (x1 - x0 - bbox[2] + bbox[0]) // 2, y0 + (y1 - y0 - bbox[3] + bbox[1]) // 2 - 2), text, font=fnt, fill=text_fill)


def background_from(path, top, bottom):
    raw = load_asset(path)
    canvas = Image.new("RGBA", (1080, 1920), (0, 0, 0, 255))
    paste_cover(canvas, raw, (0, 0, 1080, 1920))
    canvas = canvas.filter(ImageFilter.GaussianBlur(16))
    wash = gradient((1080, 1920), top, bottom).convert("RGBA")
    wash.putalpha(204)
    canvas.alpha_composite(wash)
    return canvas


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


def old_ad_files():
    return [
        "ad-landscape-1200x628.png",
        "ad-landscape-1200x628.png.import",
        "ad-square-1200x1200.png",
        "ad-square-1200x1200.png.import",
        "ad-portrait-1200x1500.png",
        "ad-portrait-1200x1500.png.import",
    ]


def remove_old_ads():
    for name in old_ad_files():
        path = OUT / name
        if path.exists():
            path.unlink()


def phone_card(scale=0.78) -> Image.Image:
    phone = phone_ui()
    w = int(phone.width * scale)
    h = int(phone.height * scale)
    return phone.resize((w, h), Image.Resampling.LANCZOS)


def hero_cutout(max_size) -> Image.Image:
    hero = chroma_to_alpha(load_asset("docs/assets/characters/stick-hero-transparent.png"))
    hero.thumbnail(max_size, Image.Resampling.LANCZOS)
    return hero


def action_tile(path, label, color, size=(286, 236)) -> Image.Image:
    tile = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    rounded(d, (0, 0, size[0] - 1, size[1] - 1), 24, PANEL + (255,), (24, 22, 20), 4)
    art = load_asset(path)
    paste_cover(tile, art, (14, 14, size[0] - 14, size[1] - 70))
    rounded(d, (14, 14, size[0] - 14, size[1] - 70), 18, None, (24, 22, 20), 3)
    d.text((24, size[1] - 54), label, font=font(25, True), fill=color)
    return tile


def draw_stat_chip(draw, xy, value, label, fill=(255, 253, 248, 238)):
    rounded(draw, xy, 14, fill, LINE, 2)
    x0, y0, x1, y1 = xy
    value_font = font(23, True)
    label_font = font(15, True)
    value_box = draw.textbbox((0, 0), value, font=value_font)
    label_box = draw.textbbox((0, 0), label, font=label_font)
    draw.text((x0 + (x1 - x0 - value_box[2] + value_box[0]) // 2, y0 + 8), value, font=value_font, fill=INK)
    draw.text((x0 + (x1 - x0 - label_box[2] + label_box[0]) // 2, y0 + 37), label, font=label_font, fill=(104, 94, 80))


def fight_activity_card(action_path, bg_path, title, stats, progress, mastery, size=(510, 244)) -> Image.Image:
    card = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    rounded(d, (0, 0, size[0] - 1, size[1] - 1), 28, (255, 253, 248, 248), (24, 22, 20), 4)
    bg = load_asset(bg_path).filter(ImageFilter.GaussianBlur(2))
    paste_cover(card, bg, (8, 8, size[0] - 8, size[1] - 8))
    shade = Image.new("RGBA", size, (255, 253, 248, 184))
    card.alpha_composite(shade)
    rounded(d, (0, 0, size[0] - 1, size[1] - 1), 28, None, (24, 22, 20), 4)

    rounded(d, (26, 34, 166, 174), 22, PANEL + (245,), (24, 22, 20), 3)
    art = load_asset(action_path)
    paste_contain(card, art, (32, 40, 160, 168), 2)

    title_font = font(30, True)
    title_lines = wrap(title, 19)
    y = 34
    for line in title_lines[:2]:
        d.text((190, y), line, font=title_font, fill=INK)
        y += 36

    chip_y = 112
    chip_w = 70
    for idx, (value, label) in enumerate(stats):
        draw_stat_chip(d, (190 + idx * (chip_w + 10), chip_y, 190 + idx * (chip_w + 10) + chip_w, chip_y + 62), value, label)

    rounded(d, (190, 190, 476, 206), 8, (222, 214, 198), None)
    rounded(d, (190, 190, 190 + int(286 * mastery), 206), 8, GOLD, None)
    rounded(d, (24, 216, 486, 236), 10, (222, 214, 198), None)
    rounded(d, (24, 216, 24 + int(462 * progress), 236), 10, GREEN, None)
    return card


def fight_activity_phone() -> Image.Image:
    w, h = 620, 1104
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rounded(d, (0, 0, w - 1, h - 1), 54, (22, 21, 19), None)
    rounded(d, (18, 18, w - 19, h - 19), 40, PAPER, None)
    d.rectangle((18, 76, w - 19, h - 112), fill=PAPER)
    draw_centered(d, "IDLE ELITE", 42, font(40, True), width=w, fill=(75, 63, 21))
    d.text((50, 108), "Global Lv 12", font=font(23, True), fill=INK)
    d.text((w - 198, 108), "$14,500", font=font(23, True), fill=INK)

    rounded(d, (44, 154, w - 44, 280), 24, PANEL, LINE, 3)
    fight_icon = SKILL_ICONS["fight"].copy()
    fight_icon.thumbnail((92, 92), Image.Resampling.LANCZOS)
    img.alpha_composite(fight_icon, (66, 171))
    d.text((178, 170), "Fight", font=font(36, True), fill=RED)
    d.text((178, 214), "Lv 7 - XP 1.3k / 1.8k", font=font(21), fill=(92, 84, 72))
    rounded(d, (178, 246, 396, 266), 10, (224, 216, 202), None)
    rounded(d, (178, 246, 312, 266), 10, RED, None)
    rounded(d, (422, 178, 552, 246), 22, (255, 238, 218), RED, 3)
    d.text((446, 190), "17/25", font=font(24, True), fill=RED)
    d.text((452, 218), "stam", font=font(18, True), fill=(92, 84, 72))

    cards = [
        (
            "docs/assets/fight/actions/01-shove-wobbly-hay-bale.png",
            "docs/assets/fight/backgrounds/01-early.png",
            "Shove Wobbly Hay Bale",
            [("+1", "XP"), ("1", "Stam"), ("1.6s", "Time"), ("95%", "Rate")],
            0.74,
            0.46,
            312,
        ),
        (
            "docs/assets/fight/actions/05-duel-leaning-fence-post.png",
            "docs/assets/fight/backgrounds/01-early.png",
            "Duel Leaning Fence Post",
            [("+9", "XP"), ("2", "Stam"), ("2.5s", "Time"), ("87%", "Rate")],
            0.35,
            0.18,
            584,
        ),
        (
            "docs/assets/fight/actions/06-outmuscle-angry-wheelbarrow.png",
            "docs/assets/fight/backgrounds/02-rising.png",
            "Outmuscle Angry Wheelbarrow",
            [("+11", "XP"), ("2", "Stam"), ("2.5s", "Time"), ("85%", "Rate")],
            0.0,
            0.0,
            856,
        ),
    ]
    for action_path, bg_path, title, stats, progress, mastery, y in cards:
        card = fight_activity_card(action_path, bg_path, title, stats, progress, mastery)
        paste_shadow(img, card, (55, y), 10, (0, 8), 58)

    d.rectangle((18, h - 112, w - 19, h - 19), fill=(245, 237, 222))
    for i, label in enumerate(["Jobs", "Gear", "Hero"]):
        x = 88 + i * 172
        d.text((x, h - 78), label, font=font(27, True), fill=INK if i == 0 else (103, 94, 80))
    return img


def draw_ad_frame(img, headline, subhead, accent, cta="PLAY NOW"):
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 1080, 1920), outline=(24, 22, 20, 80), width=0)
    d.rounded_rectangle((50, 58, 1030, 1862), radius=48, outline=(255, 253, 248, 170), width=4)
    draw_fit_center(d, headline, 96, 930, 92, 54, (255, 255, 255), True, (24, 22, 20), 4)
    draw_fit_center(d, subhead, 208, 840, 43, 28, (255, 247, 210), True, (24, 22, 20), 3)
    draw_pill(d, (346, 1750, 734, 1830), cta, accent, (255, 255, 255), (24, 22, 20))


def make_vertical_train_skills():
    img = background_from("docs/assets/fight/backgrounds/03-mid.png", (170, 65, 58), (33, 123, 142))
    d = ImageDraw.Draw(img)
    draw_ad_frame(img, "TRAIN 5 IDLE SKILLS", "Fight. Fish. Build. Sneak. Chop.", RED)

    phone = phone_card(0.83)
    paste_shadow(img, phone, (298, 470), 28, (0, 22), 105)

    cx, cy = 540, 1048
    keys = ["fight", "fishing", "build", "thieving", "woodcutting"]
    for i, key in enumerate(keys):
        angle = -math.pi * 0.86 + i * math.pi * 0.43
        icon = SKILL_ICONS[key].copy()
        icon.thumbnail((162, 162), Image.Resampling.LANCZOS)
        x = int(cx + math.cos(angle) * 412 - icon.width / 2)
        y = int(cy + math.sin(angle) * 450 - icon.height / 2)
        paste_shadow(img, icon, (x, y), 12, (0, 8), 96)

    hero = hero_cutout((330, 520))
    paste_shadow(img, hero, (68, 1294), 16, (0, 14), 90)
    d.text((666, 1412), "Short sessions", font=font(42, True), fill=(255, 255, 255), stroke_width=3, stroke_fill=(24, 22, 20))
    d.text((666, 1466), "steady progress", font=font(42, True), fill=(255, 255, 255), stroke_width=3, stroke_fill=(24, 22, 20))
    img.convert("RGB").save(OUT / "ad-vertical-01-train-five-skills-1080x1920.png", quality=95)


def make_vertical_offline_progress():
    img = background_from("docs/assets/fishing/backgrounds/10-storm-ocean.png", (43, 88, 130), (230, 180, 74))
    d = ImageDraw.Draw(img)
    draw_ad_frame(img, "PROGRESS WHILE AWAY", "Come back stronger.", BLUE)

    phone = phone_card(0.76).rotate(-5, resample=Image.Resampling.BICUBIC, expand=True)
    paste_shadow(img, phone, (402, 452), 28, (0, 24), 112)

    reward_box = Image.new("RGBA", (430, 430), (0, 0, 0, 0))
    rd = ImageDraw.Draw(reward_box)
    rounded(rd, (0, 0, 429, 429), 34, (255, 253, 248, 244), (24, 22, 20), 5)
    rd.text((38, 34), "AWAY REWARDS", font=font(36, True), fill=INK)
    rewards = [("+XP", "2h"), ("+$", "14.5k"), ("Fish", "21"), ("Logs", "18")]
    y = 112
    for label, value in rewards:
        rounded(rd, (34, y, 396, y + 58), 18, (244, 237, 220, 255), LINE, 2)
        rd.text((58, y + 11), label, font=font(28, True), fill=BLUE)
        rd.text((284, y + 11), value, font=font(28, True), fill=INK)
        y += 72
    paste_shadow(img, reward_box, (88, 880), 18, (0, 14), 110)

    hero = hero_cutout((318, 500))
    paste_shadow(img, hero, (84, 1264), 16, (0, 14), 96)
    draw_pill(d, (604, 1398, 966, 1470), "CLAIM THE GAINS", GREEN, (255, 255, 255), (24, 22, 20))
    img.convert("RGB").save(OUT / "ad-vertical-02-progress-while-away-1080x1920.png", quality=95)


def make_vertical_small_tasks():
    img = background_from("docs/assets/woodcutting/backgrounds/05-finale.png", (51, 118, 83), (160, 92, 174))
    d = ImageDraw.Draw(img)
    draw_ad_frame(img, "TAP. LEVEL. REPEAT.", "Tiny jobs. Huge numbers.", GREEN)

    tiles = [
        ("docs/assets/fight/actions/01-shove-wobbly-hay-bale.png", "Fight", RED),
        ("docs/assets/fishing/actions/03-cast-bamboo-rod.png", "Fish", (39, 151, 168)),
        ("docs/assets/woodcutting/actions/09-fell-oak-tree.png", "Chop", GREEN),
        ("docs/assets/thieving/actions/06-pick-the-world-s-friendliest-lock.png", "Sneak", PURPLE),
    ]
    positions = [(84, 442), (710, 492), (84, 1118), (710, 1148)]
    for spec, pos in zip(tiles, positions):
        tile = action_tile(*spec)
        paste_shadow(img, tile, pos, 14, (0, 12), 102)

    phone = phone_card(0.74)
    paste_shadow(img, phone, (302, 648), 28, (0, 22), 100)

    hero = hero_cutout((340, 520))
    paste_shadow(img, hero, (368, 1222), 16, (0, 14), 92)
    d.text((226, 1586), "One more level is always close.", font=font(43, True), fill=(255, 255, 255), stroke_width=3, stroke_fill=(24, 22, 20))
    img.convert("RGB").save(OUT / "ad-vertical-03-tap-level-repeat-1080x1920.png", quality=95)


def make_vertical_become_elite():
    img = background_from("docs/assets/thieving/backgrounds/05-finale.png", (124, 78, 174), (232, 142, 54))
    d = ImageDraw.Draw(img)
    draw_ad_frame(img, "BECOME IDLE ELITE", "A cozy idle RPG for quick check-ins.", PURPLE)

    icon = draw_character_head_icon(330)
    icon = chroma_to_alpha(icon)
    badge = Image.new("RGBA", (410, 410), (0, 0, 0, 0))
    bd = ImageDraw.Draw(badge)
    rounded(bd, (0, 0, 409, 409), 76, (255, 213, 84, 255), (24, 22, 20), 8)
    badge.alpha_composite(icon.resize((330, 330), Image.Resampling.LANCZOS), (40, 40))
    paste_shadow(img, badge, (334, 430), 28, (0, 24), 116)

    phone = phone_card(0.66).rotate(4, resample=Image.Resampling.BICUBIC, expand=True)
    paste_shadow(img, phone, (426, 900), 24, (0, 20), 100)

    hero = hero_cutout((300, 470))
    paste_shadow(img, hero, (118, 1186), 16, (0, 14), 96)
    facts = [("5 skills", RED), ("20+ jobs", BLUE), ("offline gains", GREEN)]
    y = 906
    for text, color in facts:
        draw_pill(d, (88, y, 420, y + 72), text.upper(), color, (255, 255, 255), (24, 22, 20))
        y += 92
    img.convert("RGB").save(OUT / "ad-vertical-04-become-idle-elite-1080x1920.png", quality=95)


def make_vertical_fighting_activity():
    img = background_from("docs/assets/fight/backgrounds/03-mid.png", (146, 48, 45), (232, 150, 61))
    d = ImageDraw.Draw(img)
    draw_ad_frame(img, "FIGHT YOUR WAY UP", "Real activity page. Fast idle battles.", RED)

    action = load_asset("docs/assets/fight/actions/12-fight-the-barn-door-at-midnight.png")
    action.thumbnail((300, 300), Image.Resampling.LANCZOS)
    burst = Image.new("RGBA", (352, 352), (0, 0, 0, 0))
    bd = ImageDraw.Draw(burst)
    rounded(bd, (0, 0, 351, 351), 48, (255, 213, 84, 250), (24, 22, 20), 7)
    burst.alpha_composite(action, ((352 - action.width) // 2, (352 - action.height) // 2))
    paste_shadow(img, burst, (642, 368), 18, (0, 14), 94)

    phone = fight_activity_phone()
    paste_shadow(img, phone, (118, 438), 30, (0, 24), 112)

    callout = Image.new("RGBA", (384, 330), (0, 0, 0, 0))
    cd = ImageDraw.Draw(callout)
    rounded(cd, (0, 0, 383, 329), 30, (255, 253, 248, 242), (24, 22, 20), 5)
    cd.text((30, 26), "FIGHT ACTIONS", font=font(34, True), fill=RED)
    rows = [("+9 XP", "Duel fence posts"), ("87%", "success rate"), ("2.5s", "quick rounds")]
    y = 92
    for value, label in rows:
        rounded(cd, (26, y, 358, y + 58), 18, (244, 237, 220, 255), LINE, 2)
        cd.text((48, y + 10), value, font=font(26, True), fill=RED)
        cd.text((164, y + 12), label, font=font(22, True), fill=INK)
        y += 72
    paste_shadow(img, callout, (626, 1038), 18, (0, 12), 98)

    hero = hero_cutout((300, 470))
    paste_shadow(img, hero, (700, 1358), 16, (0, 14), 96)
    draw_pill(d, (348, 1750, 732, 1830), "PLAY NOW", RED, (255, 255, 255), (24, 22, 20))
    img.convert("RGB").save(OUT / "ad-vertical-05-fighting-activity-1080x1920.png", quality=95)


def make_ads():
    remove_old_ads()
    make_vertical_train_skills()
    make_vertical_offline_progress()
    make_vertical_small_tasks()
    make_vertical_become_elite()
    make_vertical_fighting_activity()


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
