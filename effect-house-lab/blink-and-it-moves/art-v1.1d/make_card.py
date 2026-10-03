# CaughtCard: a cream instant-photo card with a soft drop shadow, drawn from scratch (no outside assets).
# Object size in the scene is 200x350; the card itself is 170x320 inside a 15px shadow margin (2x pixels here).
from PIL import Image, ImageDraw, ImageFilter
import os

S = 2
W, H = 200 * S, 350 * S
M = 15 * S
img = Image.new('RGBA', (W, H), (0, 0, 0, 0))

shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle((M + 4 * S, M + 8 * S, W - M + 4 * S, H - M + 8 * S), 6 * S, fill=(0, 0, 0, 150))
img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(7 * S)))

card = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(card)
d.rounded_rectangle((M, M, W - M, H - M), 6 * S, fill=(242, 238, 228, 255))
# faint paper grain toward the bottom margin so it does not read as a flat UI box
for i in range(40):
    y = H - M - 44 * S + i * S
    d.line((M + 2 * S, y, W - M - 2 * S, y), fill=(236 - i // 8, 231 - i // 8, 220 - i // 8, 255))
img = Image.alpha_composite(img, card)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'CaughtCard.png')
img.save(out)
print(out, img.size)
