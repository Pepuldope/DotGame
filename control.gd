@tool
extends Control

func _ready() -> void:
	# Panel background + border
	var ps := StyleBoxFlat.new()
	ps.bg_color                   = Color(0.04, 0.12, 0.04, 1.0)
	ps.border_width_left          = 2
	ps.border_width_right         = 2
	ps.border_width_top           = 2
	ps.border_width_bottom        = 2
	ps.border_color               = Color(0.0, 1.0, 0.0, 1.0)
	ps.corner_radius_top_left     = 10
	ps.corner_radius_top_right    = 10
	ps.corner_radius_bottom_left  = 10
	ps.corner_radius_bottom_right = 10
	$Panel.add_theme_stylebox_override("panel", ps)

	# Title label colour
	var title := $Panel/VBoxContainer/TitleLabel as Label
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color.BLACK)

	# LineEdit base style
	var le_base := StyleBoxFlat.new()
	le_base.bg_color                   = Color(0.0, 0.07, 0.0, 1.0)
	le_base.border_width_left          = 2
	le_base.border_width_right         = 2
	le_base.border_width_top           = 2
	le_base.border_width_bottom        = 2
	le_base.border_color               = Color(0.0, 1.0, 0.0, 0.55)
	le_base.corner_radius_top_left     = 6
	le_base.corner_radius_top_right    = 6
	le_base.corner_radius_bottom_left  = 6
	le_base.corner_radius_bottom_right = 6
	le_base.content_margin_left        = 12
	le_base.content_margin_right       = 12
	le_base.content_margin_top         = 8
	le_base.content_margin_bottom      = 8

	# LineEdit focused style (brighter border)
	var le_focus := StyleBoxFlat.new()
	le_focus.bg_color                   = Color(0.0, 0.09, 0.0, 1.0)
	le_focus.border_width_left          = 2
	le_focus.border_width_right         = 2
	le_focus.border_width_top           = 2
	le_focus.border_width_bottom        = 2
	le_focus.border_color               = Color(0.0, 1.0, 0.0, 1.0)
	le_focus.corner_radius_top_left     = 6
	le_focus.corner_radius_top_right    = 6
	le_focus.corner_radius_bottom_left  = 6
	le_focus.corner_radius_bottom_right = 6
	le_focus.content_margin_left        = 12
	le_focus.content_margin_right       = 12
	le_focus.content_margin_top         = 8
	le_focus.content_margin_bottom      = 8

	for le : LineEdit in [$Panel/VBoxContainer/LineWidth, $Panel/VBoxContainer/LineHeight]:
		le.add_theme_stylebox_override("normal", le_base)
		le.add_theme_stylebox_override("focus",  le_focus)
		le.add_theme_color_override("font_color",              Color.WHITE)
		le.add_theme_color_override("font_placeholder_color",  Color(0.0, 0.45, 0.0, 1.0))
		le.add_theme_color_override("caret_color",             Color(0.0, 1.0, 0.0, 1.0))
		le.focus_mode = Control.FOCUS_ALL
