@tool
class_name ClueMarker
extends Node2D

# ── Public properties ─────────────────────────────────────────────────────────

var value: int = 0 :
	set(v):
		value = v
		queue_redraw()

# One entry per surrounding button: [NW, NE, SW, SE] = [top-left, top-right, bottom-left, bottom-right]
var surrounding_states: Array[bool] = [false, false, false, false]

func set_surrounding_state(idx: int, val: bool) -> void:
	surrounding_states[idx] = val
	queue_redraw()


var btn_size: float = 75.0 :
	set(v):
		btn_size = v
		queue_redraw()

var btn_spacing_half: float = 37.5 :
	set(v):
		btn_spacing_half = v
		queue_redraw()

# ── Colours ───────────────────────────────────────────────────────────────────
const BG_COLOR     := Color(0, 0, 0, 1)
const BORDER_COLOR := Color(0.0,  1.0,  0.0,  1.0)
const LINE_COLOR   := Color(0.0,  1.0,  0.0,  0.55)
const TEXT_COLOR   := Color(0.0,  1.0,  0.0,  1.0)

const FONT_PATH := "res://fonts/Silkscreen-Regular.ttf"

# Side length of each "pixel block" used for the Minecraft-style staircase.
# Every diagonal — diamond border and X lines — is drawn as a chain of
# BLOCK×BLOCK filled squares stepping one block at a time.
const BLOCK : int = 5

static var _static_font : Font = null

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # sharp pixel rendering for font
	if _static_font == null and ResourceLoader.exists(FONT_PATH):
		_static_font = load(FONT_PATH) as FontFile
	queue_redraw()

# ── Core primitive ────────────────────────────────────────────────────────────

## Draws a 45° staircase as a chain of BLOCK×BLOCK filled squares.
## `from` and `to` must satisfy |dx| == |dy| and both be on the BLOCK grid.
func _draw_block_diagonal(from: Vector2i, to: Vector2i, col: Color) -> void:
	var dx    : int = to.x - from.x
	var dy    : int = to.y - from.y
	var steps : int = abs(dx) / BLOCK
	if steps <= 0:
		return
	var sx : int = sign(dx) * BLOCK
	var sy : int = sign(dy) * BLOCK
	var hb : int = BLOCK / 2   # half-block offset so each square is centred on path
	for i in range(steps + 1):
		draw_rect(
			Rect2(from.x + i * sx - hb,
				  from.y + i * sy - hb,
				  BLOCK, BLOCK),
			col
		)

# ── _draw ─────────────────────────────────────────────────────────────────────

func _draw() -> void:
	# ── Geometry setup ────────────────────────────────────────────────────────
	# Diamond tip-to-centre distance, snapped to BLOCK so border squares land
	# exactly on the tips with no overshoot.
	var r   : int   = (roundi(btn_size * 0.375) / BLOCK) * BLOCK   # = 25 (75px btn)
	var bhg : float = btn_spacing_half                              # = 37.5

	# The NW/NE/SW/SE diagonal lines start just past the diamond border and end
	# just before the button corner.  All distances are the X (= Y) component
	# of positions along the 45° axis, snapped to the BLOCK grid.
	#
	#   The NW diagonal meets the diamond border at component r/2 from centre.
	#   Start one BLOCK further out for a clean gap.
	var ls_comp : int = (ceili(float(r) / 2.0 / float(BLOCK)) + 1) * BLOCK   # = 20
	#   Button inner corner is at bhg in each axis.  End one BLOCK before it.
	var le_comp : int = floori(bhg / float(BLOCK)) * BLOCK                    # = 35

	# Background changes when the player has matched the target count exactly
	var current_count : int = surrounding_states.count(true)
	var bg_col        : Color
	if current_count == value and GameSettings.glow_correct:
		bg_col = Color.WHITE
	elif current_count > value and GameSettings.show_mistakes:
		bg_col = GameSettings.hs(Color(0.6, 0.0, 0.0, 1.0))
	else:
		bg_col = BG_COLOR

	# ── X lines — each line lights up when its specific button is pressed ──────
	# Order matches surrounding_states: [NW, NE, SW, SE]
	var dirs : Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1),
								  Vector2i(-1,  1), Vector2i(1,  1)]
	for i in 4:
		var dir      : Vector2i = dirs[i]
		var line_col : Color
		if surrounding_states[i]:
			line_col = GameSettings.hs(LINE_COLOR)
		elif GameSettings.lines_always_visible:
			line_col = GameSettings.hs(Color(0.0, 1.0, 0.0, 0.25))
		else:
			line_col = Color.TRANSPARENT
		if line_col.a > 0.0:
			_draw_block_diagonal(
				Vector2i(dir.x * ls_comp, dir.y * ls_comp),
				Vector2i(dir.x * le_comp, dir.y * le_comp),
				line_col
			)

	# ── Diamond fill ─────────────────────────────────────────────────────────
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)
	]), bg_col)

	# ── Diamond border — four block-stepped edges ─────────────────────────────
	# N→W, N→E, W→S, E→S  (tips at cardinal directions, edges at 45°)
	_draw_block_diagonal(Vector2i(  0, -r), Vector2i(-r,  0), GameSettings.hs(BORDER_COLOR))
	_draw_block_diagonal(Vector2i(  0, -r), Vector2i( r,  0), GameSettings.hs(BORDER_COLOR))
	_draw_block_diagonal(Vector2i( -r,  0), Vector2i( 0,  r), GameSettings.hs(BORDER_COLOR))
	_draw_block_diagonal(Vector2i(  r,  0), Vector2i( 0,  r), GameSettings.hs(BORDER_COLOR))

	# ── Number text ───────────────────────────────────────────────────────────
	var fnt   : Font   = _static_font if _static_font != null else ThemeDB.fallback_font
	var fsize : int    = int(btn_size * 0.32)   # ≈ 24 — fills diamond cleanly
	var txt   : String = str(value)
	var tw    : float  = fnt.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var asc   : float  = fnt.get_ascent(fsize)
	var dsc   : float  = fnt.get_descent(fsize)
	draw_string(fnt, Vector2(-tw * 0.5, (asc - dsc) * 0.5), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, GameSettings.hs(TEXT_COLOR))
