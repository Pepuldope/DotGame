@tool
extends Node2D

func _ready() -> void:
	if not Engine.is_editor_hint():
		GameSettings.load_settings()
	_create_background()
	$HUD/VBoxContainer/Title.text = "Welcome!"
	$HUD/VBoxContainer/ModeButton2.text = "Mode 2 (W.I.P.)"
	$HUD/VBoxContainer/ModeButton2.disabled = true
	$HUD/VBoxContainer/ModeButton3.text = "Mode 3 (W.I.P.)"
	$HUD/VBoxContainer/ModeButton3.disabled = true
	$HUD/VBoxContainer/PlayButton.text = "Play"
	$HUD/VBoxContainer/SettingsButton.text = "Settings"
	$HUD/SettingsPanel/SettingsLabel.text = "Settings"
	$HUD/SettingsPanel/SettingsCloseButton.text = "Close"
	$HUD/SettingsPanel.visible = false
	_build_settings_panel()
	_apply_ninepatch_to_buttons()
	if Engine.is_editor_hint():
		var logo := $HUD/VBoxContainer/Logo as TextureRect
		var mat := ShaderMaterial.new()
		mat.shader = load("res://logo_glint.gdshader") as Shader
		logo.material = mat
		return
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_tree().root.content_scale_size = Vector2i(400, 1100)
	await get_tree().process_frame
	_start_logo_animations()

func _start_logo_animations() -> void:
	var logo : TextureRect = $HUD/VBoxContainer/Logo
	var base_pos := logo.position + Vector2(0.0, 28.0)

	# Apply glint shader
	var mat := ShaderMaterial.new()
	mat.shader = load("res://logo_glint.gdshader") as Shader
	logo.material = mat

	# Drop in from above with a bounce
	logo.position = base_pos + Vector2(0.0, -300.0)
	var drop := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	drop.tween_property(logo, "position", base_pos, 1.3)
	await drop.finished

	# Gentle bob loop
	var bob := create_tween().set_loops()
	bob.set_ease(Tween.EASE_IN_OUT)
	bob.set_trans(Tween.TRANS_SINE)
	bob.tween_property(logo, "position", base_pos + Vector2(0.0, -14.0), 1.1)
	bob.tween_property(logo, "position", base_pos, 1.1)

	# Start glint loop
	_glint_loop(logo)

func _glint_loop(logo: TextureRect) -> void:
	await get_tree().create_timer(randf_range(3.0, 7.0)).timeout
	if not is_instance_valid(logo):
		return
	var mat := logo.material as ShaderMaterial
	var glint := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	glint.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("glint_progress", v),
		-0.3, 1.3, 1.4
	)
	await glint.finished
	_glint_loop(logo)

func _create_background() -> void:
	var bg_layer       := CanvasLayer.new()
	bg_layer.name       = "BackgroundLayer"
	bg_layer.layer      = -10
	add_child(bg_layer)
	var bg             := ColorRect.new()
	bg.name             = "LavaLampBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter     = Control.MOUSE_FILTER_IGNORE
	var mat            := ShaderMaterial.new()
	mat.shader          = load("res://lava_lamp.gdshader") as Shader
	bg.material         = mat
	bg_layer.add_child(bg)

func _apply_ninepatch_to_buttons() -> void:
	var build     := UiTheme.build_atlas()
	var atlas_img : Image = build[0]
	var raw_cw    : int   = build[1]
	var raw_ch    : int   = build[2]

	var buttons : Array = [
		$HUD/VBoxContainer/PlayButton,
		$HUD/VBoxContainer/ModeButton2,
		$HUD/VBoxContainer/ModeButton3,
		$HUD/VBoxContainer/SettingsButton,
		$HUD/SettingsPanel/SettingsCloseButton,
	]
	for btn: Button in buttons:
		btn.flat = false
		btn.icon = null
		var btn_height := btn.custom_minimum_size.y
		var corner := clampi(int(btn_height / 3.5), 4, raw_ch)
		var normal_style  := UiTheme.make_style_from_atlas(atlas_img, raw_cw, raw_ch, corner, Color.WHITE)
		var hover_style   := UiTheme.make_style_from_atlas(atlas_img, raw_cw, raw_ch, corner, Color(0.7, 0.7, 0.7))
		var pressed_style := UiTheme.make_style_from_atlas(atlas_img, raw_cw, raw_ch, corner, Color(0.7, 0.7, 0.7))
		btn.add_theme_stylebox_override("normal",        normal_style)
		btn.add_theme_stylebox_override("hover",         hover_style)
		btn.add_theme_stylebox_override("pressed",       pressed_style)
		btn.add_theme_stylebox_override("hover_pressed", pressed_style)
		btn.add_theme_stylebox_override("disabled",      pressed_style)
		btn.add_theme_stylebox_override("focus",         StyleBoxEmpty.new())
		btn.add_theme_color_override("font_hover_color", Color(0.7, 0.7, 0.7))
		btn.focus_mode = Control.FOCUS_NONE

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_mode.tscn")

func _on_mode_button_2_pressed() -> void:
	pass

func _on_mode_button_3_pressed() -> void:
	pass

func _build_settings_panel() -> void:
	var panel := $HUD/SettingsPanel as Panel

	# Restyle the panel background
	var bg := StyleBoxFlat.new()
	bg.bg_color                   = Color(0.01, 0.04, 0.01, 0.97)
	bg.border_width_left          = 3
	bg.border_width_right         = 3
	bg.border_width_top           = 3
	bg.border_width_bottom        = 3
	bg.border_color               = Color(0.0, 1.0, 0.0, 1.0)
	bg.corner_radius_top_left     = 10
	bg.corner_radius_top_right    = 10
	bg.corner_radius_bottom_left  = 10
	bg.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", bg)

	# Style the title label
	var title := $HUD/SettingsPanel/SettingsLabel as Label
	title.text = "SETTINGS"
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	title.add_theme_constant_override("outline_size", 2)
	if ResourceLoader.exists("res://fonts/Silkscreen-Regular.ttf"):
		title.add_theme_font_override("font", load("res://fonts/Silkscreen-Regular.ttf") as Font)

	# Pull the close button away from the panel edge
	var close_btn := $HUD/SettingsPanel/SettingsCloseButton as Button
	close_btn.offset_top    = -102
	close_btn.offset_bottom = -12

	# Divider below title
	var div := ColorRect.new()
	div.color    = Color(0.0, 1.0, 0.0, 0.45)
	div.position = Vector2(20, 112)
	div.size     = Vector2(680, 2)
	panel.add_child(div)

	# Load font once for all rows
	var fnt : Font = null
	if ResourceLoader.exists("res://fonts/Silkscreen-Regular.ttf"):
		fnt = load("res://fonts/Silkscreen-Regular.ttf") as Font

	# Settings rows
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(40, 128)
	vbox.size     = Vector2(640, 320)
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	_add_setting(vbox, fnt, "Hard mode (buttons lock on press)", GameSettings.lock_on_press,
		func(v: bool) -> void: GameSettings.lock_on_press = v)
	_add_setting(vbox, fnt, "Always show lines",                 GameSettings.lines_always_visible,
		func(v: bool) -> void: GameSettings.lines_always_visible = v)
	_add_setting(vbox, fnt, "Show mistakes in red",              GameSettings.show_mistakes,
		func(v: bool) -> void: GameSettings.show_mistakes = v)
	_add_setting(vbox, fnt, "Glow correct labels",               GameSettings.glow_correct,
		func(v: bool) -> void: GameSettings.glow_correct = v)
	_add_slider(vbox, fnt, "Music volume", GameSettings.music_volume,
		func(v: int) -> void:
			GameSettings.music_volume = v
			var bgm := get_node_or_null("/root/BGMusic") as MusicPlayer
			if bgm: bgm.apply_volume())

func _add_setting(parent: Node, fnt: Font, label: String, initial: bool, on_toggle: Callable) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 74)
	row.add_theme_constant_override("separation", 22)
	parent.add_child(row)

	# GridButton-style toggle square
	var btn := GridButton.new()
	btn.pixel_count           = 15
	btn.corner_radius         = 4
	btn.corner_power          = 1.5
	btn.toggle_mode           = true
	btn.button_pressed        = initial
	btn.focus_mode            = Control.FOCUS_NONE
	btn.custom_minimum_size   = Vector2(54, 54)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	btn.pivot_offset          = Vector2(27, 27)
	btn.toggled.connect(func(v: bool) -> void:
		on_toggle.call(v)
		GameSettings.save_settings())
	btn.button_down.connect(func() -> void:
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.88, 0.88), 0.06))
	btn.button_up.connect(func() -> void:
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.10))
	row.add_child(btn)

	# Setting label
	var lbl := Label.new()
	lbl.text                = label
	lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 1)
	if fnt != null:
		lbl.add_theme_font_override("font", fnt)
	row.add_child(lbl)

func _add_slider(parent: Node, fnt: Font, label: String, initial: int, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 74)
	row.add_theme_constant_override("separation", 22)
	parent.add_child(row)

	# Label
	var lbl := Label.new()
	lbl.text                = label
	lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl.custom_minimum_size = Vector2(280, 0)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 1)
	if fnt != null:
		lbl.add_theme_font_override("font", fnt)
	row.add_child(lbl)

	# Slider
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step      = 1
	slider.value     = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size   = Vector2(200, 30)
	slider.focus_mode            = Control.FOCUS_NONE

	# Style the slider green
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.0, 1.0, 0.0, 1.0)
	grabber.corner_radius_top_left     = 4
	grabber.corner_radius_top_right    = 4
	grabber.corner_radius_bottom_left  = 4
	grabber.corner_radius_bottom_right = 4
	grabber.content_margin_left   = 12
	grabber.content_margin_right  = 12
	grabber.content_margin_top    = 12
	grabber.content_margin_bottom = 12
	slider.add_theme_stylebox_override("grabber_area", grabber)
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber)

	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.0, 1.0, 0.0, 0.25)
	track.corner_radius_top_left     = 2
	track.corner_radius_top_right    = 2
	track.corner_radius_bottom_left  = 2
	track.corner_radius_bottom_right = 2
	track.content_margin_top    = 4
	track.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track)

	# Green circle grabber dot (bigger than the track)
	var dot_size := 24
	var dot_img  := Image.create(dot_size, dot_size, false, Image.FORMAT_RGBA8)
	var center   := Vector2(dot_size / 2.0, dot_size / 2.0)
	var radius   := dot_size / 2.0
	for y in dot_size:
		for x in dot_size:
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius:
				dot_img.set_pixel(x, y, Color(0.0, 1.0, 0.0, 1.0))
			else:
				dot_img.set_pixel(x, y, Color.TRANSPARENT)
	var dot_tex := ImageTexture.create_from_image(dot_img)
	slider.add_theme_icon_override("grabber",             dot_tex)
	slider.add_theme_icon_override("grabber_highlight",   dot_tex)
	slider.add_theme_icon_override("grabber_disabled",    dot_tex)

	slider.value_changed.connect(func(v: float) -> void:
		on_change.call(int(v))
		GameSettings.save_settings())
	row.add_child(slider)

	# Value label
	var val_lbl := Label.new()
	val_lbl.text                = str(initial)
	val_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	val_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	val_lbl.custom_minimum_size = Vector2(50, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 22)
	val_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0, 1.0))
	val_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	val_lbl.add_theme_constant_override("outline_size", 1)
	if fnt != null:
		val_lbl.add_theme_font_override("font", fnt)
	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = str(int(v)))
	row.add_child(val_lbl)

func _on_settings_button_pressed() -> void:
	$HUD/SettingsPanel.visible = !$HUD/SettingsPanel.visible

func _on_settings_close_button_pressed() -> void:
	$HUD/SettingsPanel.visible = !$HUD/SettingsPanel.visible
