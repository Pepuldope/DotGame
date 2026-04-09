from PIL import Image, ImageDraw, ImageFont
import math

SIZE   = 1024
BLOCK  = 18
r      = (int(SIZE * 0.40) // BLOCK) * BLOCK   # ~414, snapped to BLOCK grid

BG_COL     = (0,   0,   0)
FILL_COL   = (4,   12,  4)      # very dark green, distinct from pure black
BORDER_COL = (0,   255, 0)      # #00ff00
TEXT_COL   = (0,   255, 0)

img  = Image.new("RGB", (SIZE, SIZE), BG_COL)
draw = ImageDraw.Draw(img)

cx, cy = SIZE // 2, SIZE // 2

# ── Diamond fill (scanlines) ──────────────────────────────────────────────────
for py in range(-r, r + 1):
    x_ext = r - abs(py)
    if x_ext <= 0:
        continue
    draw.line([(cx - x_ext, cy + py), (cx + x_ext, cy + py)], fill=FILL_COL)

# ── Staircase diagonal helper ─────────────────────────────────────────────────
def block_diag(fx, fy, tx, ty, col):
    dx    = tx - fx
    dy    = ty - fy
    steps = abs(dx) // BLOCK
    if steps <= 0:
        return
    sx = (1 if dx > 0 else -1) * BLOCK
    sy = (1 if dy > 0 else -1) * BLOCK
    hb = BLOCK // 2
    for i in range(steps + 1):
        x = cx + fx + i * sx - hb
        y = cy + fy + i * sy - hb
        draw.rectangle([x, y, x + BLOCK - 1, y + BLOCK - 1], fill=col)

# ── Diamond border (four edges) ───────────────────────────────────────────────
block_diag(  0, -r, -r,  0, BORDER_COL)   # N → W
block_diag(  0, -r,  r,  0, BORDER_COL)   # N → E
block_diag( -r,  0,  0,  r, BORDER_COL)   # W → S
block_diag(  r,  0,  0,  r, BORDER_COL)   # E → S

# ── X lines (NW/NE/SW/SE) ────────────────────────────────────────────────────
import math as _math
ls_comp = (_math.ceil(r / 2.0 / BLOCK) + 1) * BLOCK   # just outside diamond edge
le_comp = ((SIZE // 2 - BLOCK * 2) // BLOCK) * BLOCK  # near image corner

LINE_COL = (0, 200, 0)   # slightly dimmer green

for dx, dy in [(-1,-1),(1,-1),(-1,1),(1,1)]:
    block_diag(dx * ls_comp, dy * ls_comp, dx * le_comp, dy * le_comp, LINE_COL)

# ── Number "1" in center ──────────────────────────────────────────────────────
FONT_PATH = "fonts/Silkscreen-Regular.ttf"
font_size = int(r * 0.72)
try:
    font = ImageFont.truetype(FONT_PATH, font_size)
except:
    font = ImageFont.load_default(size=font_size)

text = "1"
bbox = draw.textbbox((0, 0), text, font=font)
tw   = bbox[2] - bbox[0]
th   = bbox[3] - bbox[1]
tx   = cx - tw // 2 - bbox[0]
ty   = cy - th // 2 - bbox[1]
draw.text((tx, ty), text, fill=TEXT_COL, font=font)

# ── Save ──────────────────────────────────────────────────────────────────────
out = "icon_1024.png"
img.save(out)
print(f"Saved {out}  ({SIZE}x{SIZE})")
