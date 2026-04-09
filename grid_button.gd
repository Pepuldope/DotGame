@tool
class_name GridButton
extends Button

# ── Palette ───────────────────────────────────────────────────────────────────
const COL_BORDER  := Color(0.0,  1.0,  0.0,  1.0)
const COL_FILL    := Color(0.02, 0.06, 0.02, 1.0)
const COL_PRESSED := Color(0.533, 1.0, 0.533, 1.0)

# ── Parameters ────────────────────────────────────────────────────────────────
@export var pixel_count: int = 9:
	set(v):
		pixel_count = maxi(2, v)
		_cache_key = ""
		queue_redraw()

@export var corner_radius: int = 3:
	set(v):
		corner_radius = clampi(v, 0, pixel_count / 2)
		_cache_key = ""
		queue_redraw()

@export var corner_power: float = 2.0:
	set(v):
		corner_power = maxf(0.5, v)
		_cache_key = ""
		queue_redraw()

# Tween this to flash only the fill area (border/shadow unaffected)
var hint_color : Color = Color.TRANSPARENT :
	set(v):
		hint_color = v
		queue_redraw()

# ── Static pixel cache (shared across all instances with same params) ─────────
# Built once, reused for every _draw() call on every button.
static var _cache_key      : String         = ""
static var _s_border       : Array[Vector2i] = []
static var _s_ext_shadow   : Array[Vector2i] = []
static var _s_inner_shadow : Array[Vector2i] = []
static var _s_fill         : Array[Vector2i] = []

# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	toggled.connect(func(_p: bool) -> void: queue_redraw())

# ── Pixel geometry (only called during cache rebuild) ─────────────────────────

func _is_inside(px: int, py: int) -> bool:
	if px < 0 or px >= pixel_count or py < 0 or py >= pixel_count:
		return false
	var r := mini(corner_radius, pixel_count / 2)
	if r <= 0:
		return true
	var in_left   := px < r
	var in_right  := px >= pixel_count - r
	var in_top    := py < r
	var in_bottom := py >= pixel_count - r
	if (in_left or in_right) and (in_top or in_bottom):
		var cx := float(r)              if in_left  else float(pixel_count - r)
		var cy := float(r)              if in_top   else float(pixel_count - r)
		var dx := float(px) + 0.5 - cx
		var dy := float(py) + 0.5 - cy
		return pow(absf(dx), corner_power) + pow(absf(dy), corner_power) <= pow(float(r), corner_power)
	return true

func _is_border(px: int, py: int) -> bool:
	if not _is_inside(px, py):
		return false
	return (
		not _is_inside(px - 1, py) or
		not _is_inside(px + 1, py) or
		not _is_inside(px, py - 1) or
		not _is_inside(px, py + 1)
	)

func _rebuild_cache() -> void:
	var key := "%d_%d_%.3f" % [pixel_count, corner_radius, corner_power]
	if _cache_key == key:
		return
	_cache_key = key
	_s_border.clear()
	_s_ext_shadow.clear()
	_s_inner_shadow.clear()
	_s_fill.clear()
	for py in pixel_count:
		for px in pixel_count:
			if _is_border(px, py):
				_s_border.append(Vector2i(px, py))
				if not _is_inside(px, py + 1):
					_s_ext_shadow.append(Vector2i(px, py + 1))
			elif _is_inside(px, py):
				if _is_border(px, py - 1):
					_s_inner_shadow.append(Vector2i(px, py))
				else:
					_s_fill.append(Vector2i(px, py))

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	_rebuild_cache()   # no-op if params unchanged (almost always)
	var ps      := size.x / float(pixel_count)
	var pressed := button_pressed
	var dim     := 0.7 if is_hovered() else 1.0
	var b_col   := GameSettings.hs(Color(0.0, dim, 0.0, 1.0))
	var s_col   := GameSettings.hs(Color(0.0, dim, 0.0, 0.55))
	var w_col   := GameSettings.hs(Color(COL_PRESSED.r * dim, COL_PRESSED.g * dim, COL_PRESSED.b * dim, 1.0))
	var hint    := hint_color.a > 0.0
	var f_col   := hint_color if hint else (w_col if pressed else GameSettings.hs(COL_FILL))
	var ish_col := hint_color if hint else (w_col if pressed else s_col)

	for pos in _s_ext_shadow:
		draw_rect(Rect2(pos.x * ps, pos.y * ps, ps, ps), s_col)
	for pos in _s_fill:
		draw_rect(Rect2(pos.x * ps, pos.y * ps, ps, ps), f_col)
	for pos in _s_inner_shadow:
		draw_rect(Rect2(pos.x * ps, pos.y * ps, ps, ps), ish_col)
	for pos in _s_border:
		draw_rect(Rect2(pos.x * ps, pos.y * ps, ps, ps), b_col)
