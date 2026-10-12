#!/usr/bin/env python3
"""生成会员管家 PWA 图标（多尺寸 PNG + SVG favicon）"""
from PIL import Image, ImageDraw, ImageFont
import os

OUT = os.path.dirname(os.path.abspath(__file__))
SIZES = [192, 512]
BG_TOP = (108, 140, 255)     # #6c8cff
BG_BOT = (139, 92, 246)      # #8b5cf6

def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

def make_icon(size, maskable=False):
    S = size * 4  # 超采样抗锯齿
    img = Image.new("RGB", (S, S), BG_TOP)
    d = ImageDraw.Draw(img)
    # 垂直渐变
    for y in range(S):
        d.line([(0, y), (S, y)], fill=lerp(BG_TOP, BG_BOT, y / S))
    # 右上柔光装饰
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gr = int(S * 0.42)
    gd.ellipse([S - gr + int(S*0.12), -gr // 2, S + gr, gr], fill=(255, 255, 255, 34))
    img = Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB")
    d = ImageDraw.Draw(img)
    # 圆角（非 maskable 时留出圆角；maskable 时铺满）
    # 文字
    text = "会"
    font = None
    for path in [
        r"C:\Windows\Fonts\msyhbd.ttc", r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\simhei.ttf", r"C:\Windows\Fonts\arialbd.ttf",
    ]:
        if os.path.exists(path):
            try:
                font = ImageFont.truetype(path, int(S * 0.56))
                break
            except Exception:
                continue
    if font is None:
        font = ImageFont.load_default()
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((S - tw) / 2 - bbox[0], (S - th) / 2 - bbox[1]), text, font=font, fill=(255, 255, 255))
    # 缩放回目标尺寸
    img = img.resize((size, size), Image.LANCZOS)
    if not maskable:
        # 加圆角遮罩（iOS 会自动再裁圆角，这里保留方形更安全）
        pass
    return img

for s in SIZES:
    icon = make_icon(s)
    icon.save(os.path.join(OUT, f"icon-{s}.png"))
    print(f"icon-{s}.png written")
    if s == 512:
        icon.save(os.path.join(OUT, "icon-512-maskable.png"))

# favicon 32
make_icon(64).save(os.path.join(OUT, "favicon.png"))
print("favicon.png written")
print("done")
