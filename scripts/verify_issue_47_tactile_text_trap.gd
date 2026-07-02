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
	await process_frame

	await _verify_tactile_text_trap()
	if _failed:
		return

	print("Issue #47 Text Trap verification passed: Level 9 keeps touch-focused text input, rejects a wrong answer, and completes through Score Roastcard.")
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
	var level := _level_by_number(9)
	var level_id := str(level.get("id", ""))
	var rules: Dictionary = level.get("rules", {})
	_require(str(level.get("title", "")) == "No Rotate", "Level 9 should remain the Pack 1 Text Trap regression.")
	_require(str(level.get("template", "")) == "Text Trap", "Level 9 should render as Text Trap.")
	_require(_array_contains_string(rules.get("accepted_inputs", []), "portrait"), "Level 9 should accept portrait.")

	_main.call("_show_play_screen", level)
	await process_frame
	var text_input := _main.get("_text_input") as LineEdit
	_require(text_input != null, "Text Trap should render a text input.")
	_require(text_input != null and text_input.virtual_keyboard_enabled, "Text Trap input should keep virtual keyboard support.")
	_require(_has_button_text(_main, "Submit"), "Text Trap should expose Submit.")

	_main.call("_handle_text_input_focus_event", _screen_touch_event(true))
	text_input.text = "landscape"
	_main.call("_handle_text_submit")
	_require(not _profile.is_level_completed(level_id), "Wrong Text Trap answer should not complete Level 9.")
	_require(int(_main.get("_tap_count")) == 1, "Wrong Text Trap submit should count as one action.")
	_require(bool(_main.get("_last_text_focus_event_was_touch")), "Text Trap should record touch focus before typing.")

	_main.call("_show_play_screen", level)
	await process_frame
	text_input = _main.get("_text_input") as LineEdit
	_require(text_input != null, "Text Trap should render input after retry.")
	if _failed:
		return

	_main.call("_handle_text_input_focus_event", _screen_touch_event(true))
	text_input.text = "portrait"
	_main.call("_handle_text_submit")
	_require(_profile.is_level_completed(level_id), "Correct Text Trap answer should complete Level 9.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct Text Trap answer should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 1, "Correct Text Trap submit should persist as one action.")


func _screen_touch_event(pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = pressed
	event.position = Vector2(16, 16)
	return event


func _array_contains_string(values: Variant, expected: String) -> bool:
	if typeof(values) != TYPE_ARRAY:
		return false
	for value in values:
		if str(value) == expected:
			return true
	return false


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


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
