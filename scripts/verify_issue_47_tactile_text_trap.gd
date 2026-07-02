extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_47_tactile_text_trap_profile.json"

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

	_verify_tactile_text_trap()
	if _failed:
		return

	print("Issue #47 Text Trap verification passed: Level 3 renders direct word tiles, rejects a wrong tile, and completes through Score Roastcard from a direct tile tap.")
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_tactile_text_trap() -> void:
	var level := _level_by_number(3)
	var level_id := str(level.get("id", ""))
	var rules: Dictionary = level.get("rules", {})
	_require(str(rules.get("interaction_model", "")) == "direct_word_tiles", "Level 3 should declare direct_word_tiles.")

	_main.call("_show_play_screen", level)
	var surface := _node_named(_main, "text_tile_surface") as Control
	var slot := _node_named(_main, "text_answer_slot") as Control
	var blank_tile := _node_named(_main, "text_tile_blank") as Control
	var nothing_tile := _node_named(_main, "text_tile_nothing") as Control
	var empty_tile := _node_named(_main, "text_tile_empty") as Control
	_require(surface != null, "Text Trap should render a direct tile surface.")
	_require(slot != null, "Text Trap should render an answer slot.")
	_require(blank_tile != null, "Text Trap should render a blank decoy tile.")
	_require(nothing_tile != null, "Text Trap should render the NOTHING solution tile.")
	_require(empty_tile != null, "Text Trap should render an empty decoy tile.")
	_require(not _has_line_edit(_main), "Direct Text Trap should not render a LineEdit.")
	_require(not _has_button_text(_main, "Submit"), "Direct Text Trap should not expose a Submit button.")
	_require(not (nothing_tile is Button), "Direct Text Trap word tiles should not be Button answer choices.")

	_main.call("_handle_direct_text_tile_input", _screen_touch_event(true), "blank", "", blank_tile)
	_require(not _profile.is_level_completed(level_id), "Wrong direct Text Trap tile should not complete Level 3.")
	_require(int(_main.get("_tap_count")) == 1, "Wrong direct Text Trap tile should count as one action.")
	_require(str(_main.get("_last_direct_text_tile_id")) == "blank", "Direct Text Trap handler should record the wrong tile.")

	_main.call("_show_play_screen", level)
	nothing_tile = _node_named(_main, "text_tile_nothing") as Control
	_require(nothing_tile != null, "Text Trap should render solution tile after replay.")
	if _failed:
		return

	_main.call("_handle_direct_text_tile_input", _mouse_button_event(Vector2(16, 16), true), "nothing", "nothing", nothing_tile)
	_require(_profile.is_level_completed(level_id), "Correct direct Text Trap tile should complete Level 3.")
	_require(str(_main.get("_last_direct_text_tile_id")) == "nothing", "Direct Text Trap handler should record the winning tile.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct direct Text Trap tile should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 1, "Correct direct Text Trap tile should persist as one direct action.")


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


func _has_line_edit(node: Node) -> bool:
	if node is LineEdit:
		return true
	for child in node.get_children():
		if _has_line_edit(child):
			return true
	return false


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
