@tool
extends Node2D

var score := 0
var _resetting_size_input := false
var _confirm_reset_popup  : Panel
var _reset_btn            : Button
var _hint_btn             : Button
var _hint_tween           : Tween         = null
var _hint_btn_target      : GridButton    = null
var _bg_mat               : ShaderMaterial = null
var _music_player         : AudioStreamPlayer = null
var _ui_rainbow_rect      : ColorRect = null
var _ui_hue_mat           : ShaderMaterial = null
var _beat_flash           : float = 0.0
var _last_beat            : int   = -1
const _EASTER_SEQ := ["A", "S", "W", "D"]
var _easter_keys  : Array[String] = []
var _easter_time  : float = 0.0
signal score_gained(new_score: int)

func _ready() -> void:
	_create_background()
	_apply_ninepatch_to_buttons()
	_add_popup_close_button()
	_build_reset_ui()
	_style_score_label()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	if Engine.is_editor_hint():
		await get_tree().process_frame
		_on_viewport_size_changed()
		return
	get_tree().root.content_scale_mode   = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_tree().root.content_scale_size   = Vector2i(0, 0)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	var stream := load("res://audio/Tetris Dubstep.ogg")
	if stream:
		_music_player.stream = stream
	_music_player.finished.connect(func() -> void:
		if GameSettings.rainbow_active:
			_music_player.play(0.0))
	$Grid.puzzle_solved.connect(_on_puzzle_solved)
	$Grid.next_puzzle_ready.connect(_on_next_puzzle_ready)
	$Grid.setup(5, 5)
	$Camera2D.configure(5, 5, $Grid.BUTTON_SIZE.x, $Grid.BUTTON_SIZE.x + $Grid.BUTTON_SPACING.x)
	# Hue-rotation shader applied directly to each UI button/label
	_ui_hue_mat        = ShaderMaterial.new()
	_ui_hue_mat.shader = load("res://ui_hue.gdshader") as Shader
	for ci : CanvasItem in [$CanvasLayer/ChangeSize, $CanvasLayer/LevelMode,
							$CanvasLayer/Button, $CanvasLayer/ScoreLabel]:
		ci.material = _ui_hue_mat
	if _reset_btn: _reset_btn.material = _ui_hue_mat
	if _hint_btn:  _hint_btn.material  = _ui_hue_mat
	# White-flash beat rect — ADD blend so it brightens without tinting hue
	var flash_mat := CanvasItemMaterial.new()
	flash_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_ui_rainbow_rect = ColorRect.new()
	_ui_rainbow_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_rainbow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_rainbow_rect.material = flash_mat
	_ui_rainbow_rect.color    = Color.BLACK
	$CanvasLayer.add_child(_ui_rainbow_rect)
	await get_tree().process_frame
	_on_viewport_size_changed()

func _create_background() -> void:
	var bg_layer       := CanvasLayer.new()
	bg_layer.name       = "BackgroundLayer"
	bg_layer.layer      = -10          # renders behind every other CanvasLayer
	add_child(bg_layer)

	var bg             := ColorRect.new()
	bg.name             = "LavaLampBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter     = Control.MOUSE_FILTER_IGNORE

	var mat            := ShaderMaterial.new()
	mat.shader          = load("res://lava_lamp.gdshader") as Shader
	bg.material         = mat
	_bg_mat             = mat

	bg_layer.add_child(bg)

func _style_score_label() -> void:
	var sl := $CanvasLayer/ScoreLabel as Label
	var bg := StyleBoxFlat.new()
	bg.bg_color                   = Color(0.0, 0.0, 0.0, 0.78)
	bg.border_width_left          = 2
	bg.border_width_right         = 2
	bg.border_width_top           = 2
	bg.border_width_bottom        = 2
	bg.border_color               = Color(0.0, 1.0, 0.0, 1.0)
	bg.corner_radius_top_left     = 8
	bg.corner_radius_top_right    = 8
	bg.corner_radius_bottom_left  = 8
	bg.corner_radius_bottom_right = 8
	bg.content_margin_left        = 14
	bg.content_margin_right       = 14
	bg.content_margin_top         = 6
	bg.content_margin_bottom      = 6
	sl.add_theme_stylebox_override("normal", bg)
	sl.add_theme_constant_override("outline_size", 2)
	sl.add_theme_color_override("font_outline_color", Color.BLACK)

func _on_viewport_size_changed() -> void:
	var vp := get_viewport().get_visible_rect().size
	# Scale with height. Also clamp so top bar (needs 579*s wide) fits in the width.
	var s := minf(vp.y / 1080.0, vp.x / 579.0)
	_apply_top_bar_scale(maxf(s, 0.35))

func _apply_top_bar_scale(s: float) -> void:
	# Pin each button to an exact size so text doesn't expand the rect unexpectedly.
	var cs := $CanvasLayer/ChangeSize as Button
	cs.custom_minimum_size = Vector2(160.0 * s, 84.0 * s)
	cs.offset_right  = 290.0 * s
	cs.offset_bottom = 84.0  * s
	cs.add_theme_font_size_override("font_size", roundi(40 * s))

	var lm := $CanvasLayer/LevelMode as Button
	lm.custom_minimum_size = Vector2(231.0 * s, 84.0 * s)
	lm.offset_top    = 120.0 * s
	lm.offset_right  = 231.0 * s
	lm.offset_bottom = 204.0 * s
	lm.add_theme_font_size_override("font_size", roundi(40 * s))

	# ScoreLabel: sits to the right of ChangeSize with a gap, same row.
	var sl := $CanvasLayer/ScoreLabel as Label
	var sl_x := cs.offset_right + 20.0 * s
	sl.offset_left   = sl_x
	sl.offset_top    = 20.0  * s
	sl.offset_right  = sl_x + 269.0 * s
	sl.offset_bottom = sl.offset_top + 57.0 * s
	sl.add_theme_font_size_override("font_size", roundi(32 * s))

	var bk := $CanvasLayer/Button as Button
	bk.custom_minimum_size = Vector2(130.0 * s, 84.0 * s)
	bk.offset_left   = -130.0 * s
	bk.offset_bottom = 84.0   * s
	bk.add_theme_font_size_override("font_size", roundi(40 * s))

	if _reset_btn:
		_reset_btn.custom_minimum_size = Vector2(84.0 * s, 84.0 * s)
		_reset_btn.offset_left   = 0.0
		_reset_btn.offset_right  = 84.0 * s
		_reset_btn.offset_top    = -100.0 * s
		_reset_btn.offset_bottom = -16.0  * s
		_reset_btn.add_theme_font_size_override("font_size", roundi(40 * s))

	if _hint_btn:
		_hint_btn.custom_minimum_size = Vector2(84.0 * s, 84.0 * s)
		_hint_btn.offset_left  = 92.0  * s
		_hint_btn.offset_right = 176.0 * s
		_hint_btn.offset_top    = -100.0 * s
		_hint_btn.offset_bottom = -16.0  * s
		_hint_btn.add_theme_font_size_override("font_size", roundi(40 * s))

	if _confirm_reset_popup:
		_confirm_reset_popup.offset_left   = -300.0 * s
		_confirm_reset_popup.offset_right  =  300.0 * s
		_confirm_reset_popup.offset_top    = -110.0 * s
		_confirm_reset_popup.offset_bottom =  110.0 * s

func _apply_ninepatch_to_buttons() -> void:
	var build     := UiTheme.build_atlas()
	var atlas_img : Image = build[0]
	var raw_cw    : int   = build[1]
	var raw_ch    : int   = build[2]

	var buttons : Array = [
		$CanvasLayer/Button,
	]
	for btn: Button in buttons:
		var font_size := btn.get_theme_font_size("font_size", "Button")
		var corner    := clampi(int(font_size * 0.6), 4, raw_ch)
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

	# ChangeSize: same per-piece theme as LevelMode, inverted when popup is open (toggle on)
	var cs        : Button = $CanvasLayer/ChangeSize
	var cs_corner := clampi(int(cs.get_theme_font_size("font_size", "Button") * 0.6), 4, 108)
	cs.theme          = UiTheme.make_lm_theme(cs_corner)
	cs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cs.focus_mode     = Control.FOCUS_NONE
	cs.remove_theme_stylebox_override("normal")
	cs.remove_theme_stylebox_override("pressed")
	cs.add_theme_color_override("font_pressed_color",       Color.BLACK)
	cs.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
	cs.add_theme_color_override("font_hover_color",         Color(0.7, 0.7, 0.7))

	# LevelMode: dedicated theme using exact same per-piece approach as grid buttons
	var lm        : Button = $CanvasLayer/LevelMode
	var lm_corner := clampi(int(lm.get_theme_font_size("font_size", "Button") * 0.6), 4, 108)
	lm.theme          = UiTheme.make_lm_theme(lm_corner)
	lm.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lm.focus_mode     = Control.FOCUS_NONE
	lm.remove_theme_stylebox_override("normal")
	lm.remove_theme_stylebox_override("pressed")
	lm.add_theme_color_override("font_pressed_color",       Color.BLACK)
	lm.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
	lm.add_theme_color_override("font_hover_color",         Color(0.7, 0.7, 0.7))



func _on_puzzle_solved() -> void:
	score += 1
	emit_signal("score_gained", score)
	var nw : int = $Grid.grid_width  + (1 if $CanvasLayer/LevelMode.is_pressed() else 0)
	var nh : int = $Grid.grid_height + (1 if $CanvasLayer/LevelMode.is_pressed() else 0)
	$Grid.play_solve_animation(nw, nh)

func _on_next_puzzle_ready() -> void:
	$Camera2D.configure($Grid.grid_width, $Grid.grid_height, $Grid.BUTTON_SIZE.x, $Grid.BUTTON_SIZE.x + $Grid.BUTTON_SPACING.x, true)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Easter key timeout
	if not _easter_keys.is_empty():
		_easter_time += delta
		if _easter_time > 2.0:
			_easter_keys.clear()
	# Rainbow update
	if GameSettings.rainbow_active:
		GameSettings.rainbow_hue = fmod(GameSettings.rainbow_hue + delta * 0.15, 1.0)
		for btn in $Grid._buttons:
			btn.queue_redraw()
		for lbl in $Grid._labels:
			lbl.queue_redraw()
		if _bg_mat:
			_bg_mat.set_shader_parameter("hue_shift", GameSettings.rainbow_hue)
		if _ui_hue_mat:
			_ui_hue_mat.set_shader_parameter("hue_shift", GameSettings.rainbow_hue)
		# Beat flash — 150 BPM = one beat every 0.4 s
		_beat_flash = lerpf(_beat_flash, 0.0, delta * 10.0)
		if _music_player and _music_player.playing:
			var beat_num := int(_music_player.get_playback_position() / 0.4)
			if beat_num != _last_beat:
				_last_beat = beat_num
				_beat_flash = 1.0
		# White ADD-blend flash brightens everything on beat
		if _ui_rainbow_rect:
			_ui_rainbow_rect.color = Color(_beat_flash * 0.35, _beat_flash * 0.35, _beat_flash * 0.35, 1.0)

func _toggle_rainbow() -> void:
	GameSettings.rainbow_active = not GameSettings.rainbow_active
	if GameSettings.rainbow_active:
		BGMusic.pause_music()
		if _music_player and _music_player.stream:
			_music_player.volume_db = GameSettings.volume_db(10)
			_music_player.play(13.8)
	else:
		GameSettings.rainbow_hue = 0.0
		_beat_flash = 0.0
		_last_beat  = -1
		if _music_player:
			_music_player.stop()
		BGMusic.resume_music()
		for btn in $Grid._buttons:
			btn.queue_redraw()
		for lbl in $Grid._labels:
			lbl.queue_redraw()
		if _bg_mat:
			_bg_mat.set_shader_parameter("hue_shift", 0.0)
		if _ui_hue_mat:
			_ui_hue_mat.set_shader_parameter("hue_shift", 0.0)
		if _ui_rainbow_rect:
			_ui_rainbow_rect.color = Color.BLACK

func _unhandled_input(event: InputEvent) -> void:
	var popup := $CanvasLayer/Popup
	if popup.visible and event.is_action_pressed("ui_cancel"):
		popup.visible = false
		$CanvasLayer/ChangeSize.button_pressed = false
		get_viewport().set_input_as_handled()
	if not Engine.is_editor_hint() and event is InputEventKey and event.pressed and not event.echo:
		var key := OS.get_keycode_string(event.keycode).to_upper()
		var expected : String = _EASTER_SEQ[_easter_keys.size()]
		if key == expected:
			if _easter_keys.is_empty():
				_easter_time = 0.0
			_easter_keys.append(key)
			if _easter_keys.size() == 4:
				_easter_keys.clear()
				_toggle_rainbow()
		elif key == _EASTER_SEQ[0]:
			_easter_keys = [key]
			_easter_time = 0.0
		else:
			_easter_keys.clear()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	var popup := $CanvasLayer/Popup
	if not popup.visible:
		return
	var lw := $CanvasLayer/Popup/Panel/VBoxContainer/LineWidth  as LineEdit
	var lh := $CanvasLayer/Popup/Panel/VBoxContainer/LineHeight as LineEdit
	if not lw.has_focus() and not lh.has_focus():
		popup.visible = false
		$CanvasLayer/ChangeSize.button_pressed = false
		get_viewport().set_input_as_handled()

func _on_change_size_pressed() -> void:
	var popup := $CanvasLayer/Popup
	popup.visible = ($CanvasLayer/ChangeSize as Button).button_pressed
	if popup.visible:
		($CanvasLayer/Popup/Panel/VBoxContainer/LineWidth  as LineEdit).text = str($Grid.grid_width)
		($CanvasLayer/Popup/Panel/VBoxContainer/LineHeight as LineEdit).text = str($Grid.grid_height)

func _on_level_mode_pressed() -> void:
	pass

func _on_line_width_text_changed(new_text: String) -> void:
	if _resetting_size_input:
		return
	if new_text.is_valid_int() and int(new_text) >= 2:
		$Grid.setup(int(new_text), $Grid.grid_height)
		$Camera2D.configure($Grid.grid_width, $Grid.grid_height, $Grid.BUTTON_SIZE.x, $Grid.BUTTON_SIZE.x + $Grid.BUTTON_SPACING.x)

func _on_line_height_text_changed(new_text: String) -> void:
	if _resetting_size_input:
		return
	if new_text.is_valid_int() and int(new_text) >= 2:
		$Grid.setup($Grid.grid_width, int(new_text))
		$Camera2D.configure($Grid.grid_width, $Grid.grid_height, $Grid.BUTTON_SIZE.x, $Grid.BUTTON_SIZE.x + $Grid.BUTTON_SPACING.x)

func _on_line_width_submitted(new_text: String) -> void:
	if new_text.is_valid_int() and int(new_text) >= 2:
		_close_size_popup()
	else:
		_resetting_size_input = true
		($CanvasLayer/Popup/Panel/VBoxContainer/LineWidth as LineEdit).text = str($Grid.grid_width)
		_resetting_size_input = false
		get_viewport().gui_release_focus()

func _on_line_height_submitted(new_text: String) -> void:
	if new_text.is_valid_int() and int(new_text) >= 2:
		_close_size_popup()
	else:
		_resetting_size_input = true
		($CanvasLayer/Popup/Panel/VBoxContainer/LineHeight as LineEdit).text = str($Grid.grid_height)
		_resetting_size_input = false
		get_viewport().gui_release_focus()

func _close_size_popup() -> void:
	$CanvasLayer/Popup.visible = false
	$CanvasLayer/ChangeSize.button_pressed = false

func _on_button_pressed() -> void:
	if GameSettings.rainbow_active:
		_toggle_rainbow()
	get_tree().change_scene_to_file("res://home_screen.tscn")

func _add_popup_close_button() -> void:
	var vbox := $CanvasLayer/Popup/Panel/VBoxContainer
	var fnt  := load("res://fonts/Silkscreen-Regular.ttf") as Font
	var btn  := Button.new()
	btn.text = "CLOSE"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 64)
	if fnt:
		btn.add_theme_font_override("font", fnt)
	btn.add_theme_font_size_override("font_size", 28)
	btn.theme          = UiTheme.make_lm_theme(16)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_color_override("font_pressed_color",       Color.BLACK)
	btn.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
	btn.add_theme_color_override("font_hover_color",         Color(0.7, 0.7, 0.7))
	btn.pressed.connect(_close_size_popup)
	vbox.add_child(btn)

func _build_reset_ui() -> void:
	var fnt := load("res://fonts/Silkscreen-Regular.ttf") as Font

	# ── Reset button (bottom-left) ─────────────────────────────────────────────
	var rbtn           := Button.new()
	rbtn.text           = "↺"
	rbtn.focus_mode     = Control.FOCUS_NONE
	rbtn.custom_minimum_size = Vector2(84, 84)
	rbtn.anchor_left    = 0.0
	rbtn.anchor_right   = 0.0
	rbtn.anchor_top     = 1.0
	rbtn.anchor_bottom  = 1.0
	rbtn.offset_left    = 0
	rbtn.offset_right   = 84
	rbtn.offset_top     = -100  # 84 tall + 16 bottom margin
	rbtn.offset_bottom  = -16
	rbtn.add_theme_font_size_override("font_size", 40)
	rbtn.theme          = UiTheme.make_lm_theme(24)
	rbtn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rbtn.add_theme_color_override("font_pressed_color",       Color.BLACK)
	rbtn.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
	rbtn.add_theme_color_override("font_hover_color",         Color(0.7, 0.7, 0.7))
	rbtn.pressed.connect(_on_reset_pressed)
	$CanvasLayer.add_child(rbtn)
	_reset_btn = rbtn

	# ── Hint button (bottom-left, right of reset) ──────────────────────────────
	var hbtn           := Button.new()
	hbtn.text           = "?"
	hbtn.focus_mode     = Control.FOCUS_NONE
	hbtn.custom_minimum_size = Vector2(84, 84)
	hbtn.anchor_left    = 0.0
	hbtn.anchor_right   = 0.0
	hbtn.anchor_top     = 1.0
	hbtn.anchor_bottom  = 1.0
	hbtn.offset_left    = 92        # 84 (reset) + 8 gap
	hbtn.offset_right   = 176       # 92 + 84
	hbtn.offset_top     = -100  # 84 tall + 16 bottom margin
	hbtn.offset_bottom  = -16
	hbtn.add_theme_font_size_override("font_size", 40)
	hbtn.theme          = UiTheme.make_lm_theme(24)
	hbtn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbtn.add_theme_color_override("font_pressed_color",       Color.BLACK)
	hbtn.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
	hbtn.add_theme_color_override("font_hover_color",         Color(0.7, 0.7, 0.7))
	hbtn.pressed.connect(_on_hint_pressed)
	$CanvasLayer.add_child(hbtn)
	_hint_btn = hbtn

	# ── Hard-mode confirmation popup ───────────────────────────────────────────
	var panel           := Panel.new()
	panel.visible        = false
	panel.anchor_left    = 0.5
	panel.anchor_right   = 0.5
	panel.anchor_top     = 0.5
	panel.anchor_bottom  = 0.5
	panel.offset_left    = -300
	panel.offset_right   = 300
	panel.offset_top     = -110
	panel.offset_bottom  = 110

	var bg                          := StyleBoxFlat.new()
	bg.bg_color                      = Color(0.01, 0.04, 0.01, 0.97)
	bg.border_width_left             = 3
	bg.border_width_right            = 3
	bg.border_width_top              = 3
	bg.border_width_bottom           = 3
	bg.border_color                  = Color(0.0, 1.0, 0.0, 1.0)
	bg.corner_radius_top_left        = 10
	bg.corner_radius_top_right       = 10
	bg.corner_radius_bottom_left     = 10
	bg.corner_radius_bottom_right    = 10
	bg.content_margin_left           = 30
	bg.content_margin_right          = 30
	bg.content_margin_top            = 24
	bg.content_margin_bottom         = 24
	panel.add_theme_stylebox_override("panel", bg)

	var vbox     := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var lbl                    := Label.new()
	lbl.text                    = "Resetting will also clear your score.\nAre you sure?"
	lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color",         Color(0.0, 1.0, 0.0, 1.0))
	lbl.add_theme_constant_override("outline_size",    1)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	if fnt:
		lbl.add_theme_font_override("font", fnt)
	lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(lbl)

	var hbox     := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(hbox)

	for pair : Array in [["YES", true], ["NO", false]]:
		var b          := Button.new()
		b.text          = pair[0]
		b.focus_mode    = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(160, 64)
		if fnt:
			b.add_theme_font_override("font", fnt)
		b.add_theme_font_size_override("font_size", 28)
		b.theme          = UiTheme.make_lm_theme(16)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.add_theme_color_override("font_pressed_color",       Color.BLACK)
		b.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
		b.add_theme_color_override("font_hover_color",         Color(0.7, 0.7, 0.7))
		var confirm : bool = pair[1]
		b.pressed.connect(func() -> void:
			panel.visible = false
			if confirm:
				_do_reset(true)
		)
		hbox.add_child(b)

	$CanvasLayer.add_child(panel)
	_confirm_reset_popup = panel

func _on_reset_pressed() -> void:
	if $Grid._animating:
		return
	if GameSettings.lock_on_press:
		_confirm_reset_popup.visible = true
	else:
		_do_reset(false)

func _do_reset(reset_score: bool) -> void:
	if reset_score:
		score = 0
		emit_signal("score_gained", score)
	$Grid.play_reset_animation(func() -> void: pass)

func _on_hint_pressed() -> void:
	if $Grid._animating:
		return
	# Kill any previous hint flash and clean up the old button
	if _hint_tween and _hint_tween.is_running():
		_hint_tween.kill()
	if _hint_btn_target:
		_hint_btn_target.hint_color = Color.TRANSPARENT
		_hint_btn_target = null

	var hint : Dictionary = $Grid.get_hint()

	if hint.has("index"):
		var btn : GridButton = $Grid._buttons[hint["index"]] as GridButton
		var col : Color = Color(0.67, 0.67, 1.0) if hint["should_be_on"] else Color(1.0, 0.15, 0.15)
		_hint_btn_target = btn
		_hint_tween = _flash_fill(btn, col, 4)

func _flash_fill(btn: GridButton, col: Color, times: int) -> Tween:
	var tw := btn.create_tween().set_loops(times)
	tw.tween_property(btn, "hint_color", col,               0.07).set_trans(Tween.TRANS_LINEAR)
	tw.tween_interval(0.20)
	tw.tween_property(btn, "hint_color", Color.TRANSPARENT, 0.13).set_trans(Tween.TRANS_LINEAR)
	return tw

func _flash_node(node: CanvasItem, col: Color, times: int) -> void:
	var tw := node.create_tween().set_loops(times)
	tw.tween_property(node, "modulate", col,            0.07).set_trans(Tween.TRANS_LINEAR)
	tw.tween_interval(0.20)
	tw.tween_property(node, "modulate", Color(1,1,1,1), 0.13).set_trans(Tween.TRANS_LINEAR)
