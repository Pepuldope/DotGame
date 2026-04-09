extends Camera2D

var _drag_start := Vector2.ZERO
var _cam_start := Vector2.ZERO
var _is_dragging := false
var _press_started := false
var _current_grid_width  := 5
var _current_grid_height := 5
var _current_btn_size    := BUTTON_SIZE_VAL
var _current_cell_step   := BUTTON_TOTAL
var _min_pos  := Vector2.ZERO
var _max_pos  := Vector2.ZERO
var _min_zoom := 0.1   # updated dynamically: most zoomed out = fit whole grid
var _max_zoom := 3.0   # updated dynamically: most zoomed in  = see 3x3 grid area

const DRAG_THRESHOLD  := 5.0
const ZOOM_STEP       := 0.1
const BUTTON_TOTAL    := 150.0
const BUTTON_SIZE_VAL := 75.0
const PADDING         := 200.0

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func configure(grid_width: int, grid_height: int, btn_size: float = BUTTON_SIZE_VAL, cell_step: float = BUTTON_TOTAL, keep_position: bool = false) -> void:
	_current_grid_width  = grid_width
	_current_grid_height = grid_height
	_current_btn_size    = btn_size
	_current_cell_step   = cell_step
	var grid_pixel_size := Vector2(
		(grid_width  - 1) * cell_step + btn_size,
		(grid_height - 1) * cell_step + btn_size
	)
	var grid_center   := grid_pixel_size / 2.0
	var viewport_size := get_viewport().get_visible_rect().size
	var fit_pad       := 80.0

	# Most zoomed out = fit the whole grid on screen
	_min_zoom = minf(
		viewport_size.x / (grid_pixel_size.x + fit_pad * 2.0),
		viewport_size.y / (grid_pixel_size.y + fit_pad * 2.0)
	)
	# Most zoomed in = see a 3x3 grid's worth of area
	var grid_3x3 := 2.0 * cell_step + btn_size
	_max_zoom = minf(
		viewport_size.x / (grid_3x3 + fit_pad * 2.0),
		viewport_size.y / (grid_3x3 + fit_pad * 2.0)
	)

	var wiggle := grid_pixel_size / 2.0 + Vector2(PADDING, PADDING)
	wiggle.x = max(wiggle.x, viewport_size.x / 2.0)
	wiggle.y = max(wiggle.y, viewport_size.y / 2.0)
	_min_pos = grid_center - wiggle
	_max_pos = grid_center + wiggle

	if keep_position:
		zoom     = zoom.clamp(Vector2(_min_zoom, _min_zoom), Vector2(_max_zoom, _max_zoom))
		position = position.clamp(_min_pos, _max_pos)
	else:
		zoom     = Vector2(_min_zoom, _min_zoom)   # start at full-fit zoom
		position = Vector2(roundi(grid_center.x), roundi(grid_center.y))

func _on_viewport_size_changed() -> void:
	configure(_current_grid_width, _current_grid_height, _current_btn_size, _current_cell_step, true)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start = event.position
			_cam_start = position
			_is_dragging = false
			_press_started = true
		else:
			_is_dragging = false
			_press_started = false
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if not _press_started:
			return
		if event.position.distance_to(_drag_start) > DRAG_THRESHOLD:
			_is_dragging = true
		if _is_dragging:
			var raw : Vector2 = _cam_start - (event.position - _drag_start) / zoom.x
			raw = raw.clamp(_min_pos, _max_pos)
			position = Vector2(roundi(raw.x), roundi(raw.y))
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom + Vector2(ZOOM_STEP, ZOOM_STEP)).clamp(Vector2(_min_zoom, _min_zoom), Vector2(_max_zoom, _max_zoom))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom - Vector2(ZOOM_STEP, ZOOM_STEP)).clamp(Vector2(_min_zoom, _min_zoom), Vector2(_max_zoom, _max_zoom))
