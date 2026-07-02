extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_45_tactile_memory_flash_profile.json"

var _loader := LevelLoaderScript.new()
var _pack_set := {}
var _main: Control
var _profile: RefCounted
var _failed := false


func _initialize() -> void:
	_remove_test_save()
	_pack_set = _loader.load_default_packs()
	_require(not _pack_set.is_empty(), _loader.last_error)
	if _failed:
		return

	_boot_main_scene()
	if _failed:
		return

	_verify_tactile_memory_flash()
	if _failed:
		return

	print("Issue #45 Memory Flash verification passed: Level 5 renders direct memory tiles and recall slots, rejects a wrong row, and completes through Score Roastcard from direct tile taps.")
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_tactile_memory_flash() -> void:
	var level := _level_by_number(5)
	var level_id := str(level.get("id", ""))

	_main.call("_show_play_screen", level)
	_require(_node_named(_main, "memory_tile_surface") != null, "Memory Flash should render a direct tile surface.")
	_require(_node_named(_main, "memory_recall_slot_0") != null, "Memory Flash should render recall slots.")
	_require(_node_named(_main, "memory_tile_sun") != null, "Memory Flash should render SUN as a direct tile.")
	_require(_node_named(_main, "memory_tile_moon") != null, "Memory Flash should render MOON as a direct tile.")
	_require(_node_named(_main, "memory_tile_dur") != null, "Memory Flash should render DUR as a direct tile.")
	_require_tile_label_fits("MOON")
	_require(_screen_has_label_text("Recall row ready."), "Direct Memory Flash should start with positive ready-state feedback.")
	_require(not _screen_has_label_text("Row empty."), "Direct Memory Flash should not render old negative idle feedback.")
	_require(not _has_button_text(_main, "Flash"), "Direct Memory Flash should not expose Flash button.")
	_require(not _has_button_text(_main, "Hide"), "Direct Memory Flash should not expose Hide button.")
	_require(not _has_button_text(_main, "Submit"), "Direct Memory Flash should not expose Submit button.")
	_require(not _has_button_text(_main, "SUN"), "Direct Memory Flash should not expose SUN as a choice button.")
	_require(not _has_button_text(_main, "MOON"), "Direct Memory Flash should not expose MOON as a choice button.")
	_require(not _has_button_text(_main, "DUR"), "Direct Memory Flash should not expose DUR as a choice button.")
	_require(not _screen_has_label_text("Tap tiles into the recall slots"), "Direct Memory Flash should not repeat instruction copy above the tile surface.")
	_main.call("_hide_direct_memory_flash", int(_main.get("_direct_memory_flash_generation")))
	_require(_screen_has_label_text("Receipt hidden"), "Direct Memory Flash hidden state should use concise in-world copy.")
	_require(not _screen_has_label_text("flash hidden - rebuild it from memory"), "Direct Memory Flash should not render old instruction-like hidden copy.")

	_cancel_tile_release_outside("SUN")
	_require(int(_main.get("_tap_count")) == 0, "Direct Memory Flash release outside should cancel without spending an action.")
	_require(str(_main.get("_last_direct_memory_tile_id")).is_empty(), "Direct Memory Flash release outside should not record a tile.")
	var memory_after_cancel: Array = _main.get("_memory_input")
	_require(memory_after_cancel.is_empty(), "Direct Memory Flash release outside should not add recall input.")

	_press_clear_with_touch()
	_require(int(_main.get("_tap_count")) == 0, "Direct Memory Flash empty clear should not spend an action.")
	_require(str(_main.get("_last_direct_memory_tile_id")).is_empty(), "Direct Memory Flash empty clear should not record CLEAR as a tile.")
	_require(_screen_has_label_text("Recall row ready."), "Direct Memory Flash empty clear should keep ready-state feedback.")
	_require(_memory_tile_has_border("CLEAR", Color(0.96, 0.43, 0.13)), "Direct Memory Flash empty clear should keep CLEAR on its orange idle frame.")

	_press_tile_with_touch("SUN")
	_press_clear_with_touch()
	_require(int(_main.get("_tap_count")) == 2, "Direct Memory Flash non-empty clear should count as one action after one tile.")
	_require(str(_main.get("_last_direct_memory_tile_id")) == "CLEAR", "Direct Memory Flash non-empty clear should record the CLEAR tile.")
	var memory_after_clear: Array = _main.get("_memory_input")
	_require(memory_after_clear.is_empty(), "Direct Memory Flash non-empty clear should reset recall input.")
	_require(_memory_tile_has_border("CLEAR", Color(0.96, 0.43, 0.13)), "Direct Memory Flash non-empty clear should return CLEAR to its orange idle frame.")

	_main.call("_show_play_screen", level)
	_press_tiles_with_touch(["DUR", "SUN", "MOON"])
	_require(not _profile.is_level_completed(level_id), "Wrong direct memory row should not complete Level 5.")
	_require(int(_main.get("_tap_count")) == 3, "Wrong direct memory row should count one action per tile.")
	_require(str(_main.get("_last_direct_memory_tile_id")) == "MOON", "Direct memory handler should record the last touched tile.")
	_require(not _memory_tiles_have_selected_border(["DUR", "SUN", "MOON"]), "Wrong full Memory Flash row should leave selected contact feedback.")
	_require(_memory_tiles_have_border(["DUR", "SUN", "MOON"], Color(0.95, 0.22, 0.24)), "Wrong full Memory Flash row should frame touched tiles as a fail state.")
	_require(_memory_tiles_shook(["DUR", "SUN", "MOON"]), "Wrong full Memory Flash row should shake touched tiles.")
	_require(_memory_recall_slots_have_border(3, Color(0.95, 0.22, 0.24)), "Wrong full Memory Flash row should frame recall slots as a fail state.")
	_require(_memory_recall_slots_pulsed(3), "Wrong full Memory Flash row should pulse recall slots.")
	var memory_after_wrong: Array = _main.get("_memory_input")
	_require(memory_after_wrong.is_empty(), "Wrong full Memory Flash row should clear recall input for a clean retry.")
	var first_slot_label := _node_named(_main, "memory_recall_slot_label_0") as Label
	_require(first_slot_label != null and str(first_slot_label.text) == "_", "Wrong full Memory Flash row should reset recall slot labels.")

	_main.call("_show_play_screen", level)
	_press_tiles_with_mouse(["SUN", "MOON", "DUR"])
	_require(_profile.is_level_completed(level_id), "Correct direct memory row should complete Level 5.")
	_require(str(_main.get("_last_direct_memory_tile_id")) == "DUR", "Direct memory handler should record the winning final tile.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct direct memory row should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 3, "Three direct tile taps should persist as three actions.")


func _press_tiles_with_touch(item_ids: Array[String]) -> void:
	for item_id in item_ids:
		_press_tile_with_touch(item_id)


func _press_tiles_with_mouse(item_ids: Array[String]) -> void:
	for item_id in item_ids:
		_press_tile(item_id, _mouse_button_event(Vector2(16, 16), true), _mouse_button_event(Vector2(16, 16), false))


func _press_tile(item_id: String, press_event: InputEvent, release_event: InputEvent) -> void:
	var tile := _node_named(_main, "memory_tile_%s" % item_id.to_lower()) as Control
	_require(tile != null, "Expected direct memory tile %s." % item_id)
	if _failed:
		return
	var tap_count_before_press := int(_main.get("_tap_count"))
	_main.call("_handle_direct_memory_tile_input", press_event, item_id, tile)
	_require(int(_main.get("_tap_count")) == tap_count_before_press, "Direct Memory Flash press should preview without spending an action.")
	_main.call("_handle_direct_memory_tile_input", release_event, item_id, tile)


func _press_tile_with_touch(item_id: String) -> void:
	var tile := _node_named(_main, "memory_tile_%s" % item_id.to_lower()) as Control
	_require(tile != null, "Expected direct memory tile %s." % item_id)
	if _failed:
		return
	var touch_position := _touch_position(tile)
	_press_tile(item_id, _screen_touch_event(true, touch_position), _screen_touch_event(false, touch_position))


func _cancel_tile_release_outside(item_id: String) -> void:
	var tile := _node_named(_main, "memory_tile_%s" % item_id.to_lower()) as Control
	_require(tile != null, "Expected direct memory tile %s." % item_id)
	if _failed:
		return
	_main.call("_handle_direct_memory_tile_input", _screen_touch_event(true, _touch_position(tile)), item_id, tile)
	_main.call("_handle_direct_memory_tile_input", _screen_touch_event(false, Vector2(-500, -500)), item_id, tile)


func _press_clear_with_touch() -> void:
	var tile := _node_named(_main, "memory_tile_clear") as Control
	_require(tile != null, "Expected direct memory CLEAR tile.")
	if _failed:
		return
	var touch_position := _touch_position(tile)
	var tap_count_before_press := int(_main.get("_tap_count"))
	_main.call("_handle_direct_memory_clear_input", _screen_touch_event(true, touch_position), tile)
	_require(int(_main.get("_tap_count")) == tap_count_before_press, "Direct Memory Flash CLEAR press should preview without spending an action.")
	_main.call("_handle_direct_memory_clear_input", _screen_touch_event(false, touch_position), tile)


func _memory_tiles_have_selected_border(item_ids: Array[String]) -> bool:
	for item_id in item_ids:
		var tile := _node_named(_main, "memory_tile_%s" % item_id.to_lower()) as Control
		_require(tile != null, "Expected direct memory tile %s." % item_id)
		if tile == null:
			return false
		if _panel_border_color(tile).is_equal_approx(Color(1.00, 0.78, 0.15)):
			return true
	return false


func _memory_tile_has_border(item_id: String, expected_color: Color) -> bool:
	var tile := _node_named(_main, "memory_tile_%s" % item_id.to_lower()) as Control
	_require(tile != null, "Expected direct memory tile %s." % item_id)
	if tile == null:
		return false
	return _panel_border_color(tile).is_equal_approx(expected_color)


func _memory_tiles_have_border(item_ids: Array[String], expected_color: Color) -> bool:
	for item_id in item_ids:
		if not _memory_tile_has_border(item_id, expected_color):
			return false
	return true


func _memory_tiles_shook(item_ids: Array[String]) -> bool:
	for item_id in item_ids:
		var tile := _node_named(_main, "memory_tile_%s" % item_id.to_lower()) as Control
		_require(tile != null, "Expected direct memory tile %s." % item_id)
		if tile == null:
			return false
		if int(tile.get_meta("failure_shake_count", 0)) <= 0:
			return false
	return true


func _memory_recall_slots_have_border(slot_count: int, expected_color: Color) -> bool:
	for index in range(slot_count):
		var slot := _node_named(_main, "memory_recall_slot_%d" % index) as Control
		_require(slot != null, "Expected direct memory recall slot %d." % index)
		if slot == null:
			return false
		if not _panel_border_color(slot).is_equal_approx(expected_color):
			return false
	return true


func _memory_recall_slots_pulsed(slot_count: int) -> bool:
	for index in range(slot_count):
		var slot := _node_named(_main, "memory_recall_slot_%d" % index) as Control
		_require(slot != null, "Expected direct memory recall slot %d." % index)
		if slot == null:
			return false
		if int(slot.get_meta("failure_pulse_count", 0)) <= 0:
			return false
	return true


func _panel_border_color(control: Control) -> Color:
	var panel := control as PanelContainer
	_require(panel != null, "Expected a framed direct memory tile.")
	if panel == null:
		return Color.TRANSPARENT
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	_require(style != null, "Expected direct memory tile style.")
	if style == null:
		return Color.TRANSPARENT
	return style.border_color


func _require_tile_label_fits(item_id: String) -> void:
	var tile := _node_named(_main, "memory_tile_%s" % item_id.to_lower()) as Control
	_require(tile != null, "Expected direct memory tile %s." % item_id)
	if _failed:
		return

	var label := _first_label(tile)
	_require(label != null, "Expected direct memory tile %s to have a label." % item_id)
	if _failed:
		return

	_require(label.autowrap_mode == TextServer.AUTOWRAP_OFF, "Direct memory tile labels should not wrap.")
	_require(label.get_minimum_size().x <= tile.size.x, "Direct memory tile %s label should fit in its tile." % item_id)


func _first_label(node: Node) -> Label:
	if node is Label:
		return node
	for child in node.get_children():
		var label := _first_label(child)
		if label != null:
			return label
	return null


func _mouse_button_event(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	return event


func _screen_touch_event(pressed: bool, position: Vector2 = Vector2(16, 16)) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = pressed
	event.position = position
	return event


func _touch_position(control: Control) -> Vector2:
	return control.get_global_rect().position + Vector2(16, 16)


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


func _node_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var match := _node_named(child, node_name)
		if match != null:
			return match
	return null


func _has_button_text(node: Node, text: String) -> bool:
	if node is Button and str(node.text) == text:
		return true
	for child in node.get_children():
		if _has_button_text(child, text):
			return true
	return false


func _screen_has_label_text(text: String) -> bool:
	return _node_has_label_text(_main, text)


func _node_has_label_text(node: Node, text: String) -> bool:
	if node is Label and str(node.text).contains(text):
		return true
	for child in node.get_children():
		if _node_has_label_text(child, text):
			return true
	return false


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	_failed = true
	_cleanup()
	quit(1)


func _cleanup() -> void:
	if _main != null:
		_main.queue_free()
	_remove_test_save()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
