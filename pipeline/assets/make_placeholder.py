"""Generate the synthetic test input (no real person, no third-party image).

A mirror-composed "selfie" 540x960 like the shader sees it in the app: left-right
symmetric face, but deliberately *vertically* asymmetric (warm hair band on top,
cool shirt at the bottom, a small top-left marker square that survives only if
nothing flips the image) so headless renders reveal an upside-down port.

    python assets/make_placeholder.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

W, H = 540, 960
OUT = Path(__file__).parent / "test_input" / "placeholder_selfie.png"


def main() -> None:
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):  # background: teal at the top -> grey at the bottom
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=(int(40 + 90 * t), int(120 + 10 * t), int(130 - 10 * t)))
    cx = W // 2
    d.ellipse([cx - 230, 120, cx + 230, 520], fill=(120, 60, 30))  # hair (top)
    d.rectangle([cx - 250, 760, cx + 250, H], fill=(40, 70, 170))  # shirt (bottom)
    d.rectangle([cx - 55, 600, cx + 55, 780], fill=(225, 175, 140))  # neck
    d.ellipse([cx - 170, 220, cx + 170, 680], fill=(235, 185, 150))  # face
    for sx in (-1, 1):
        ex = cx + sx * 70
        d.ellipse([ex - 38, 380, ex + 38, 420], fill=(250, 250, 250))
        d.ellipse([ex - 15, 385, ex + 15, 415], fill=(60, 90, 50))
        d.line([(ex - 45, 350), (ex + 40, 345)], fill=(90, 50, 25), width=8)  # brows
    d.polygon([(cx, 430), (cx - 25, 520), (cx + 25, 520)], fill=(215, 160, 125))  # nose
    d.ellipse([cx - 70, 560, cx + 70, 600], fill=(190, 70, 80))  # mouth
    d.rectangle([12, 12, 52, 52], fill=(255, 230, 0))  # orientation marker (top-left)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, optimize=True)
    print(OUT)


if __name__ == "__main__":
    main()
