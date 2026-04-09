class_name GameSettings

static var lock_on_press       : bool = false   # hard mode — buttons can't be untoggled
static var lines_always_visible: bool = false   # X lines visible at 0.25 alpha when off
static var show_mistakes        : bool = true   # label turns red when too many selected
static var glow_correct         : bool = true   # label background turns white when correct
static var music_volume         : int  = 50     # 0 = off, 100 = full (0 dB)

# Session-only (not saved) — easter egg rainbow mode
static var rainbow_active : bool  = false
static var rainbow_hue    : float = 0.0

## Hue-shift a colour by rainbow_hue when rainbow mode is active.
static func hs(col: Color) -> Color:
	if not rainbow_active:
		return col
	return Color.from_hsv(fmod(col.h + rainbow_hue, 1.0), col.s, col.v, col.a)

## Convert music_volume (0–100) to dB. min_pct clamps the lower bound (e.g. 10 = never below 10%).
static func volume_db(min_pct: int = 0) -> float:
	var vol := maxi(music_volume, min_pct)
	if vol <= 0:
		return -80.0
	return linear_to_db(pow(vol / 100.0, 2.5))

const _PATH := "user://settings.cfg"

static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "lock_on_press",        lock_on_press)
	cfg.set_value("settings", "lines_always_visible", lines_always_visible)
	cfg.set_value("settings", "show_mistakes",        show_mistakes)
	cfg.set_value("settings", "glow_correct",         glow_correct)
	cfg.set_value("settings", "music_volume",        music_volume)
	cfg.save(_PATH)

static func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_PATH) != OK:
		return
	lock_on_press        = cfg.get_value("settings", "lock_on_press",        lock_on_press)
	lines_always_visible = cfg.get_value("settings", "lines_always_visible", lines_always_visible)
	show_mistakes        = cfg.get_value("settings", "show_mistakes",        show_mistakes)
	glow_correct         = cfg.get_value("settings", "glow_correct",         glow_correct)
	music_volume         = cfg.get_value("settings", "music_volume",        music_volume)
