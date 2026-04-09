class_name UiTheme
## Shared button-theme utilities used by both home_screen.gd and main_mode.gd.
## All functions are static — no node dependencies.

static func build_atlas() -> Array:
	var tl := load("res://imgs/ButtonChopped/corner_top_left.png")     as Texture2D
	var tr := load("res://imgs/ButtonChopped/corner_top_right.png")    as Texture2D
	var bl := load("res://imgs/ButtonChopped/corner_bottom_left.png")  as Texture2D
	var br := load("res://imgs/ButtonChopped/corner_bottom_right.png") as Texture2D
	var et := load("res://imgs/ButtonChopped/edge_top.png")            as Texture2D
	var eb := load("res://imgs/ButtonChopped/edge_bottom.png")         as Texture2D
	var el := load("res://imgs/ButtonChopped/edge_left.png")           as Texture2D
	var er := load("res://imgs/ButtonChopped/edge_right.png")          as Texture2D
	var ce := load("res://imgs/ButtonChopped/center.png")              as Texture2D
	var cw := tl.get_width();  var ch := tl.get_height()
	var ew := et.get_width();  var eh := el.get_height()
	var atlas := Image.create(cw + ew + cw, ch + eh + ch, false, Image.FORMAT_RGBA8)
	var blit := func(tex: Texture2D, dx: int, dy: int) -> void:
		var src := tex.get_image()
		src.convert(Image.FORMAT_RGBA8)
		atlas.blit_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(dx, dy))
	blit.call(tl, 0,       0      )
	blit.call(et, cw,      0      )
	blit.call(tr, cw + ew, 0      )
	blit.call(el, 0,       ch     )
	blit.call(ce, cw,      ch     )
	blit.call(er, cw + ew, ch     )
	blit.call(bl, 0,       ch + eh)
	blit.call(eb, cw,      ch + eh)
	blit.call(br, cw + ew, ch + eh)
	return [atlas, cw, ch]

static func make_style_from_atlas(atlas: Image, raw_cw: int, raw_ch: int, corner: int, modulate_col: Color, invert: bool = false) -> StyleBoxTexture:
	var s      := float(corner) / float(raw_ch)
	var scaled := atlas.duplicate()
	var interp := Image.INTERPOLATE_NEAREST if invert else Image.INTERPOLATE_LANCZOS
	scaled.resize(roundi(atlas.get_width() * s), roundi(atlas.get_height() * s), interp)
	if invert:
		for y in range(scaled.get_height()):
			for x in range(scaled.get_width()):
				var c : Color = scaled.get_pixel(x, y)
				if c.a > 0.5 and c.r < 0.1 and c.g < 0.1 and c.b < 0.1:
					scaled.set_pixel(x, y, Color.WHITE)
	var cm := maxi(4, corner / 2)
	var style := StyleBoxTexture.new()
	style.texture                = ImageTexture.create_from_image(scaled)
	style.texture_margin_left    = roundi(raw_cw * s)
	style.texture_margin_right   = roundi(raw_cw * s)
	style.texture_margin_top     = corner
	style.texture_margin_bottom  = corner
	style.content_margin_left    = cm
	style.content_margin_right   = cm
	style.content_margin_top     = cm
	style.content_margin_bottom  = cm
	style.modulate_color         = modulate_col
	return style

static func make_lm_theme(corner: int) -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("normal",        "Button", make_lm_stylebox(corner, false, 1.0))
	theme.set_stylebox("hover",         "Button", make_lm_stylebox(corner, false, 0.7))
	theme.set_stylebox("pressed",       "Button", make_lm_stylebox(corner, true,  1.0))
	theme.set_stylebox("hover_pressed", "Button", make_lm_stylebox(corner, true,  0.7))
	theme.set_stylebox("focus",         "Button", StyleBoxEmpty.new())
	return theme

static func make_lm_stylebox(corner: int, invert: bool, dim: float = 1.0) -> StyleBoxTexture:
	var pieces : Array = [
		["res://imgs/ButtonChopped/corner_top_left.png",     0,          0,          corner, corner],
		["res://imgs/ButtonChopped/corner_top_right.png",    corner + 1, 0,          corner, corner],
		["res://imgs/ButtonChopped/corner_bottom_left.png",  0,          corner + 1, corner, corner],
		["res://imgs/ButtonChopped/corner_bottom_right.png", corner + 1, corner + 1, corner, corner],
		["res://imgs/ButtonChopped/edge_top.png",            corner,     0,          1,      corner],
		["res://imgs/ButtonChopped/edge_bottom.png",         corner,     corner + 1, 1,      corner],
		["res://imgs/ButtonChopped/edge_left.png",           0,          corner,     corner, 1     ],
		["res://imgs/ButtonChopped/edge_right.png",          corner + 1, corner,     corner, 1     ],
		["res://imgs/ButtonChopped/center.png",              corner,     corner,     1,      1     ],
	]
	var atlas := Image.create(corner + 1 + corner, corner + 1 + corner, false, Image.FORMAT_RGBA8)
	for i in pieces.size():
		var piece : Array    = pieces[i]
		var tex   : Texture2D = load(piece[0]) as Texture2D
		var img   : Image     = tex.get_image()
		img.convert(Image.FORMAT_RGBA8)
		var tw : int = piece[3]
		var th : int = piece[4]
		img.resize(tw, th, Image.INTERPOLATE_NEAREST)
		if invert:
			var is_top : bool = (i == 0 or i == 1 or i == 4)
			for y in range(th):
				for x in range(tw):
					var c : Color = img.get_pixel(x, y)
					var is_black      : bool = c.r < 0.1 and c.g < 0.1 and c.b < 0.1
					var is_dark_green : bool = is_top and c.g > c.r + 0.05 and c.g > c.b + 0.05 and (c.r + c.g + c.b) < 0.75
					if c.a > 0.5 and (is_black or is_dark_green):
						img.set_pixel(x, y, Color.WHITE)
		if dim < 1.0:
			for y in range(th):
				for x in range(tw):
					var c : Color = img.get_pixel(x, y)
					if c.a > 0.5:
						img.set_pixel(x, y, Color(c.r * dim, c.g * dim, c.b * dim, c.a))
		atlas.blit_rect(img, Rect2i(0, 0, tw, th), Vector2i(piece[1], piece[2]))
	var style := StyleBoxTexture.new()
	style.texture                = ImageTexture.create_from_image(atlas)
	style.texture_margin_left    = corner
	style.texture_margin_right   = corner
	style.texture_margin_top     = corner
	style.texture_margin_bottom  = corner
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical   = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style
