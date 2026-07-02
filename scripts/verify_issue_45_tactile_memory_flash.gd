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

	_press_tiles_with_touch(["DUR", "SUN", "MOON"])
	_require(not _profile.is_level_completed(level_id), "Wrong direct memory row should not complete Level 5.")
	_require(int(_main.get("_tap_count")) == 3, "Wrong direct memory row should count one action per tile.")
	_require(str(_main.get("_last_direct_memory_tile_id")) == "MOON", "Direct memory handler should record the last touched tile.")
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
		_press_tile(item_id, _screen_touch_event(true), _screen_touch_event(false))


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


func _screen_touch_event(pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = pressed
	event.position = Vector2(16, 16)
	return event


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
