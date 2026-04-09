extends AnimatedSprite2D

const SPEED := 1.75
const SPIN := 1.0
const MIN_SCALE := 1.5
const MAX_SCALE := 2.5
const SPRITE_W := 96
const SPRITE_H := 73

var trajectory := Vector2.ZERO
var screen_size := Vector2.ZERO
var _hue_mat   : ShaderMaterial = null

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	screen_size = get_viewport().get_visible_rect().size
	var s = randf_range(MIN_SCALE, MAX_SCALE)
	scale = Vector2(s, s)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var angle_rad := deg_to_rad(randf_range(30.0, 60.0))
	trajectory = Vector2(-cos(angle_rad), sin(angle_rad)) * SPEED
	rotation_degrees = randf_range(0.0, 360.0)
	flip_h = randi() % 2 == 0
	position = Vector2(randf_range(0.0, screen_size.x), randf_range(0.0, screen_size.y))
	_hue_mat        = ShaderMaterial.new()
	_hue_mat.shader = load("res://ui_hue.gdshader") as Shader
	material        = _hue_mat
	play()

func _process(_delta: float) -> void:
	rotation_degrees += SPIN
	position += trajectory
	var leeway_x := scale.x * SPRITE_W
	var leeway_y := scale.y * SPRITE_H
	if position.x < -leeway_x or position.y > screen_size.y + leeway_y:
		_reset_position()
	if _hue_mat:
		_hue_mat.set_shader_parameter("hue_shift", GameSettings.rainbow_hue)

func _reset_position() -> void:
	flip_h = randi() % 2 == 0
	if randi() % 2 == 0:
		position = Vector2(randf_range(50, screen_size.x + 50), 0)
	else:
		position = Vector2(screen_size.x, randf_range(50, screen_size.y + 50))

func _on_viewport_size_changed() -> void:
	screen_size = get_viewport().get_visible_rect().size
