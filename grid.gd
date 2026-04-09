# grid.gd
extends Node2D

signal puzzle_solved
signal next_puzzle_ready

const BUTTON_SIZE    := Vector2(75, 75)
const BUTTON_SPACING := Vector2(75, 75)
const OFFSET         := Vector2(0, 0)
const LOCK_ON_PRESS  := false   # if true, buttons can't be untoggled

# ── GridButton configuration ──────────────────────────────────────────────────
const BUTTON_PIXEL_COUNT   := 15   # pixel-art resolution of each button
const BUTTON_CORNER_RADIUS := 4    # corner rounding in pixel-art pixels
const BUTTON_CORNER_POWER  := 1.5  # 1.0=chamfer, 2.0=circle, 3-4=barely rounded

var grid_width  := 0
var grid_height := 0

var _buttons      : Array[Button]      = []
var _labels       : Array[ClueMarker]  = []
var _button_states: Array[bool]        = []   # what the player has toggled
var _animating    : bool               = false

# ── Public API ────────────────────────────────────────────────────────────────

func setup(width: int, height: int) -> void:
	grid_width  = width
	grid_height = height
	_clear()
	_build_buttons()
	_build_labels()
	_randomize_and_label()

# ── Internal ──────────────────────────────────────────────────────────────────

func _clear() -> void:
	for b in _buttons:
		if is_instance_valid(b): b.queue_free()
	for l in _labels:
		if is_instance_valid(l): l.queue_free()
	_buttons.clear()
	_labels.clear()
	_button_states.clear()

func _build_buttons() -> void:
	for y in grid_height:
		for x in grid_width:
			var btn := GridButton.new()
			btn.pixel_count   = BUTTON_PIXEL_COUNT
			btn.corner_radius = BUTTON_CORNER_RADIUS
			btn.corner_power  = BUTTON_CORNER_POWER
			btn.size          = BUTTON_SIZE
			btn.toggle_mode   = true
			btn.pivot_offset  = BUTTON_SIZE / 2.0
			btn.position      = OFFSET + Vector2(
				x * (BUTTON_SIZE.x + BUTTON_SPACING.x),
				y * (BUTTON_SIZE.y + BUTTON_SPACING.y)
			)
			btn.toggled.connect(_on_button_toggled.bind(_buttons.size()))
			btn.button_down.connect(func():
				var tw := btn.create_tween()
				tw.tween_property(btn, "scale", Vector2(0.85, 0.85), 0.06)
			)
			btn.button_up.connect(func():
				var tw := btn.create_tween()
				tw.tween_property(btn, "scale", Vector2.ONE, 0.10)
			)
			$"../ButtonsContainer".add_child(btn)
			_buttons.append(btn)
			_button_states.append(false)

func _build_labels() -> void:
	var step_x := BUTTON_SIZE.x + BUTTON_SPACING.x
	var step_y := BUTTON_SIZE.y + BUTTON_SPACING.y
	for y in grid_height - 1:
		for x in grid_width - 1:
			var marker          := ClueMarker.new()
			marker.btn_size         = BUTTON_SIZE.x
			marker.btn_spacing_half = BUTTON_SPACING.x / 2.0
			# Position at the geometric centre of the 2×2 button block
			marker.position = OFFSET + Vector2(
				x * step_x + step_x * 0.75,
				y * step_y + step_y * 0.75
			)
			$"../LabelsContainer".add_child(marker)
			_labels.append(marker)

func _randomize_and_label() -> void:
	# Build a random solved state, derive clue numbers from it
	var solution: Array[bool] = []
	solution.resize(grid_width * grid_height)
	for i in solution.size():
		solution[i] = randi() % 2 == 1

	for y in grid_height - 1:
		for x in grid_width - 1:
			var sum := 0
			for dy in 2:
				for dx in 2:
					if solution[(y + dy) * grid_width + (x + dx)]:
						sum += 1
			_labels[y * (grid_width - 1) + x].value = sum

## Constraint-propagation hint.
## Returns one of:
##   { "index": int, "should_be_on": bool }  — a button the player has wrong / needs to set
##   { "impossible": true }                  — current state violates at least one clue
##   {}                                      — no provable hint (puzzle is ambiguous here)
# ── Constraint propagation ────────────────────────────────────────────────────
# hs: -1=unknown, 0=must OFF, 1=must ON  (modified in place)
# Returns false if a contradiction is found.
func _propagate(hs: Array[int]) -> bool:
	var lw := grid_width - 1
	var lh := grid_height - 1
	var changed := true
	while changed:
		changed = false
		for my in lh:
			for mx in lw:
				var lbl := _labels[my * lw + mx]
				var v   := lbl.value
				var nb  : Array[int] = [
					my * grid_width + mx,       my * grid_width + mx + 1,
					(my + 1) * grid_width + mx, (my + 1) * grid_width + mx + 1,
				]
				var on_count := 0
				var unknowns : Array[int] = []
				for ni : int in nb:
					if   hs[ni] == 1:  on_count += 1
					elif hs[ni] == -1: unknowns.append(ni)
				if on_count > v:                         return false  # too many ON
				if unknowns.size() < v - on_count:       return false  # not enough unknowns
				if on_count == v:
					for ni : int in unknowns:
						if hs[ni] != 0: hs[ni] = 0; changed = true
				elif unknowns.size() == v - on_count:
					for ni : int in unknowns:
						if hs[ni] != 1: hs[ni] = 1; changed = true
	return true

# ── Backtracking solver ───────────────────────────────────────────────────────
# Fills hs with a valid complete solution extending the current assignments.
# Returns false if no solution exists.
func _solve(hs: Array[int]) -> bool:
	if not _propagate(hs):
		return false
	var pick := -1
	for i in hs.size():
		if hs[i] == -1:
			pick = i
			break
	if pick == -1:
		return true
	for val in [0, 1]:
		var branch : Array[int] = hs.duplicate()
		branch[pick] = val
		if _solve(branch):
			for j in hs.size():
				hs[j] = branch[j]
			return true
	return false

# Like _solve but when branching, tries the player's current state first.
# This finds the valid solution closest to what the player has built so far.
func _solve_biased(hs: Array[int]) -> bool:
	if not _propagate(hs):
		return false
	var pick := -1
	for i in hs.size():
		if hs[i] == -1:
			pick = i
			break
	if pick == -1:
		return true
	var first := 1 if _button_states[pick] else 0
	for val in [first, 1 - first]:
		var branch : Array[int] = hs.duplicate()
		branch[pick] = val
		if _solve_biased(branch):
			for j in hs.size():
				hs[j] = branch[j]
			return true
	return false

# ── Wrong-button finder ───────────────────────────────────────────────────────
# Solves from scratch using the minimal solver (prefers OFF).
# Any player-ON button that's OFF in the minimal solution is wrong.
func _hint_wrong_button() -> Dictionary:
	var n := grid_width * grid_height
	var hs : Array[int] = []
	hs.resize(n)
	hs.fill(-1)
	if not _solve(hs):
		return {}
	# Find wrong buttons, prioritise closest to other player-ON buttons
	var wrongs : Array = []
	for i in n:
		if _button_states[i] and hs[i] == 0:
			var row_i := i / grid_width
			var col_i := i % grid_width
			var min_dist := n + 1
			for j in n:
				if _button_states[j] and j != i:
					min_dist = mini(min_dist, abs(row_i - j / grid_width) + abs(col_i - j % grid_width))
			wrongs.append({ "index": i, "dist": min_dist })
	if wrongs.is_empty():
		return {}
	wrongs.sort_custom(func(a, b): return a.dist < b.dist)
	return { "index": wrongs[0].index, "should_be_on": false }

# ── Public hint API ───────────────────────────────────────────────────────────
func get_hint() -> Dictionary:
	var n := grid_width * grid_height
	var hs : Array[int] = []
	hs.resize(n)
	# Seed from player's ON choices — they are treated as hard constraints
	for i in n:
		hs[i] = 1 if _button_states[i] else -1

	# Unsolvable — identify the specific wrong button instead of a generic error
	if not _propagate(hs):
		return _hint_wrong_button()
	if not _solve(hs):
		return _hint_wrong_button()

	# hs is now a complete valid solution that respects all player ON buttons.
	# Collect buttons the player hasn't pressed yet but the solution requires ON.
	var candidates : Array = []
	for i in n:
		if _button_states[i] or hs[i] != 1:
			continue
		# Score by Manhattan distance to the nearest already-ON button
		var row_i := i / grid_width
		var col_i := i % grid_width
		var min_dist := n + 1
		for j in n:
			if not _button_states[j]:
				continue
			min_dist = mini(min_dist, abs(row_i - j / grid_width) + abs(col_i - j % grid_width))
		candidates.append({ "index": i, "dist": min_dist })

	if candidates.is_empty():
		return {}   # puzzle already solved

	# Pick from the closest candidates (random tiebreak)
	candidates.sort_custom(func(a, b): return a.dist < b.dist)
	var best_dist : int = candidates[0].dist
	var best : Array = candidates.filter(func(c): return c.dist == best_dist)
	return { "index": best[randi() % best.size()].index, "should_be_on": true }

func _on_button_toggled(pressed: bool, index: int) -> void:
	if _animating:
		return
	_button_states[index] = pressed
	_update_surrounding_states(index % grid_width, index / grid_width)
	if GameSettings.lock_on_press:
		_buttons[index].disabled = true
	_check_win()

func _update_surrounding_states(bx: int, by: int) -> void:
	var pressed := _button_states[by * grid_width + bx]
	# Button (bx,by) is one of 4 surrounding buttons for up to 4 markers.
	# The index within surrounding_states depends on which corner of that marker it is.
	# surrounding_states order: [NW=0, NE=1, SW=2, SE=3] = [top-left, top-right, bottom-left, bottom-right]
	var affected : Array = [
		[bx,     by,     0],   # marker(bx,  by)   → button is its top-left  (NW)
		[bx - 1, by,     1],   # marker(bx-1,by)   → button is its top-right (NE)
		[bx,     by - 1, 2],   # marker(bx,  by-1) → button is its bot-left  (SW)
		[bx - 1, by - 1, 3],   # marker(bx-1,by-1) → button is its bot-right (SE)
	]
	for entry in affected:
		var mx  : int = entry[0]
		var my  : int = entry[1]
		var idx : int = entry[2]
		if mx < 0 or mx >= grid_width - 1 or my < 0 or my >= grid_height - 1:
			continue
		_labels[my * (grid_width - 1) + mx].set_surrounding_state(idx, pressed)

func play_solve_animation(next_width: int, next_height: int) -> void:
	_animating = true
	for btn in _buttons:
		btn.disabled = true

	var corner := randi() % 4
	var cx     := (grid_width  - 1) * (corner & 1)
	var cy     := (grid_height - 1) * ((corner >> 1) & 1)
	var opp_cx := (grid_width  - 1) - cx
	var opp_cy := (grid_height - 1) - cy

	var step_delay  := 0.04
	var squeeze_dur := 0.08
	var restore_dur := 0.10
	var max_dist    := (grid_width - 1) + (grid_height - 1)

	var use_scale := grid_width * grid_height <= 225   # skip scale tweens on grids > 15x15

	if use_scale:
		# Small grid: per-button Tweens with squeeze animation
		for y in grid_height:
			for x in grid_width:
				var dist : int = abs(x - cx) + abs(y - cy)
				var btn  := _buttons[y * grid_width + x]
				var tw   := create_tween()
				tw.tween_interval(dist * step_delay)
				tw.tween_callback(func(): if is_instance_valid(btn): btn.button_pressed = true)
				tw.tween_property(btn, "scale", Vector2(0.75, 0.75), squeeze_dur) \
				  .set_ease(Tween.EASE_OUT)

		var w1_end := max_dist * step_delay + squeeze_dur
		for y in grid_height:
			for x in grid_width:
				var dist : int = abs(x - opp_cx) + abs(y - opp_cy)
				var btn  := _buttons[y * grid_width + x]
				var tw   := create_tween()
				tw.tween_interval(w1_end + dist * step_delay)
				tw.tween_callback(func(): if is_instance_valid(btn): btn.button_pressed = false)
				tw.tween_property(btn, "scale", Vector2.ONE, restore_dur) \
				  .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		var total_wait := w1_end + max_dist * step_delay + restore_dur + 0.05
		get_tree().create_timer(total_wait).timeout.connect(
			func(): _phase2_rebuild_and_glitch(next_width, next_height)
		)
	else:
		# Large grid: ring-based timers — one timer per distance level (max ~2*(W+H) timers)
		var rings_on  : Dictionary = {}   # dist -> Array[Button]
		var rings_off : Dictionary = {}
		for y in grid_height:
			for x in grid_width:
				var d1 : int = abs(x - cx)     + abs(y - cy)
				var d2 : int = abs(x - opp_cx) + abs(y - opp_cy)
				var btn := _buttons[y * grid_width + x]
				if not rings_on.has(d1):  rings_on[d1]  = []
				if not rings_off.has(d2): rings_off[d2] = []
				rings_on[d1].append(btn)
				rings_off[d2].append(btn)

		var w1_end := max_dist * step_delay + 0.05
		for dist in rings_on:
			var btns : Array = rings_on[dist]
			get_tree().create_timer(dist * step_delay).timeout.connect(func():
				for b in btns:
					if is_instance_valid(b): b.button_pressed = true
			)
		for dist in rings_off:
			var btns : Array = rings_off[dist]
			get_tree().create_timer(w1_end + dist * step_delay).timeout.connect(func():
				for b in btns:
					if is_instance_valid(b): b.button_pressed = false
			)

		var total_wait := w1_end + max_dist * step_delay + 0.05
		get_tree().create_timer(total_wait).timeout.connect(
			func(): _phase2_rebuild_and_glitch(next_width, next_height)
		)

func _phase2_rebuild_and_glitch(nw: int, nh: int) -> void:
	# Reset button states — buttons stay visible, wave 2 already unpressed them
	for i in _button_states.size():
		_button_states[i] = false

	# If grid size changed, rebuild buttons and labels immediately
	if nw != grid_width or nh != grid_height:
		for b in _buttons:
			if is_instance_valid(b): b.queue_free()
		_buttons.clear()
		_button_states.clear()
		for l in _labels:
			if is_instance_valid(l): l.queue_free()
		_labels.clear()
		grid_width  = nw
		grid_height = nh
		_build_buttons()
		_build_labels()
	else:
		# Reuse existing labels — reset surrounding states
		for lbl in _labels:
			lbl.surrounding_states = [false, false, false, false]

	var solution: Array[bool] = []
	solution.resize(nw * nh)
	for i in solution.size():
		solution[i] = randi() % 2 == 1

	var new_values: Array[int] = []
	for y in nh - 1:
		for x in nw - 1:
			var sum := 0
			for dy in 2:
				for dx in 2:
					if solution[(y + dy) * nw + (x + dx)]:
						sum += 1
			new_values.append(sum)

	if _labels.is_empty():
		_phase3_finish()
		return

	_glitch_step(new_values, 0)

func _glitch_step(new_values: Array[int], step: int) -> void:
	const STEPS    := 9
	const INTERVAL := 0.055
	if step < STEPS:
		for lbl in _labels:
			lbl.value = randi_range(0, 4)
		get_tree().create_timer(INTERVAL).timeout.connect(
			func(): _glitch_step(new_values, step + 1)
		)
	else:
		for i in _labels.size():
			_labels[i].value = new_values[i]
		_phase3_finish()

func _phase3_finish() -> void:
	for btn in _buttons:
		if is_instance_valid(btn):
			btn.disabled = false
	_animating = false
	next_puzzle_ready.emit()

func play_reset_animation(on_complete: Callable) -> void:
	_animating = true
	for b in _buttons:
		if is_instance_valid(b):
			b.disabled = false

	var corner := randi() % 4
	var cx     := 0 if corner in [0, 2] else grid_width  - 1
	var cy     := 0 if corner in [0, 1] else grid_height - 1

	const STEP_DELAY := 0.04
	# Group ON buttons by Manhattan distance — one timer per ring
	var rings : Dictionary = {}
	var max_dist := 0
	for y in grid_height:
		for x in grid_width:
			var btn := _buttons[y * grid_width + x]
			if not btn.button_pressed:
				continue
			var dist : int = abs(x - cx) + abs(y - cy)
			max_dist = max(max_dist, dist)
			if not rings.has(dist):
				rings[dist] = []
			rings[dist].append(btn)

	for dist in rings:
		var btns : Array = rings[dist]
		get_tree().create_timer(dist * STEP_DELAY).timeout.connect(func():
			for b in btns:
				if is_instance_valid(b): b.button_pressed = false
		)

	get_tree().create_timer(max_dist * STEP_DELAY + 0.15).timeout.connect(func():
		for i in _button_states.size():
			_button_states[i] = false
		for lbl in _labels:
			lbl.surrounding_states = [false, false, false, false]
			lbl.queue_redraw()
		for b in _buttons:
			if is_instance_valid(b):
				b.disabled = false
		_animating = false
		on_complete.call()
	)

func _check_win() -> void:
	for y in grid_height - 1:
		for x in grid_width - 1:
			var expected := _labels[y * (grid_width - 1) + x].value
			var actual   := 0
			for dy in 2:
				for dx in 2:
					if _button_states[(y + dy) * grid_width + (x + dx)]:
						actual += 1
			if actual != expected:
				return
	puzzle_solved.emit()
