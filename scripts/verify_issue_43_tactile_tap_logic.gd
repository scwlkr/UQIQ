extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_43_tactile_tap_logic_profile.json"

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

	_verify_tactile_tap_logic()
	if _failed:
		return

	print("Issue #43 Tap Logic verification passed: Level 1 renders a tactile direct tap scene, rejects a wrong direct tap, and completes through Score Roastcard from a direct object tap.")
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_tactile_tap_logic() -> void:
	var level := _level_by_number(1)
	var level_id := str(level.get("id", ""))

	_main.call("_show_play_screen", level)
	var surface := _node_named(_main, "tap_scene_surface") as Control
	var decoy_pad := _node_named(_main, "tap_scene_target_correct_button") as Control
	var correct_pad := _node_named(_main, "tap_scene_target_wrong_button") as Control
	_require(surface != null, "Tap Logic should render a named direct tap surface.")
	_require(decoy_pad != null, "Tap Logic should render CORRECT as a direct scene target.")
	_require(correct_pad != null, "Tap Logic should render WRONG as a direct scene target.")
	_require(_screen_has_label_text("Evidence board"), "Direct Tap Logic should render the playfield as an in-world evidence board.")
	_require(not _screen_has_label_text("Tap the object, not an answer list."), "Direct Tap Logic should not repeat instruction copy above the scene.")
	_require(not _screen_has_label_text("Tap the right object in the scene."), "Direct Tap Logic should not render fallback instruction copy above the scene.")
	_require(not _screen_has_label_text("labels are evidence"), "Direct Tap Logic should not render old instruction-like playfield copy.")
	_require(_screen_has_label_text("Scene waiting."), "Direct Tap Logic should start with positive ready-state feedback.")
	_require(not _screen_has_label_text("No object tapped."), "Direct Tap Logic should not render old negative idle feedback.")
	_require(not (decoy_pad is Button), "Direct Tap Logic targets should not be Button answer choices.")
	_require(not (correct_pad is Button), "Direct Tap Logic targets should not be Button answer choices.")
	_require(not _has_button_text(_main, "CORRECT"), "Direct Tap Logic should not expose CORRECT as an answer-choice button.")
	_require(not _has_button_text(_main, "WRONG"), "Direct Tap Logic should not expose WRONG as an answer-choice button.")

	var decoy_touch_position := _touch_position(decoy_pad)
	_main.call("_handle_direct_tap_scene_input", _screen_touch_event(true, decoy_touch_position), "correct_button", decoy_pad)
	_main.call("_handle_direct_tap_scene_input", _screen_touch_event(false, Vector2(-500, -500)), "correct_button", decoy_pad)
	_require(int(_main.get("_tap_count")) == 0, "Direct tap release outside should cancel without spending an action.")
	_require(str(_main.get("_last_direct_tap_target_id")).is_empty(), "Direct tap release outside should not record a target.")

	_main.call("_handle_direct_tap_scene_input", _screen_touch_event(true, decoy_touch_position), "correct_button", decoy_pad)
	_require(int(_main.get("_tap_count")) == 0, "Direct tap press should preview without spending an action.")
	_main.call("_handle_direct_tap_scene_input", _screen_touch_event(false, decoy_touch_position), "correct_button", decoy_pad)
	_require(not _profile.is_level_completed(level_id), "Wrong direct tap should not complete Level 1.")
	_require(int(_main.get("_tap_count")) == 1, "Wrong direct tap should count as one action.")
	_require(str(_main.get("_last_direct_tap_target_id")) == "correct_button", "Direct tap handler should record the touched decoy target.")

	_main.call("_show_play_screen", level)
	correct_pad = _node_named(_main, "tap_scene_target_wrong_button") as Control
	_require(correct_pad != null, "Tap Logic should render WRONG scene target after replay.")
	if _failed:
		return

	_main.call("_handle_direct_tap_scene_input", _mouse_button_event(Vector2(16, 16), true), "wrong_button", correct_pad)
	_require(not _profile.is_level_completed(level_id), "Correct direct tap press should not complete until release.")
	_main.call("_handle_direct_tap_scene_input", _mouse_button_event(Vector2(16, 16), false), "wrong_button", correct_pad)
	_require(_profile.is_level_completed(level_id), "Correct direct tap should complete Level 1.")
	_require(str(_main.get("_last_direct_tap_target_id")) == "wrong_button", "Direct tap handler should record the touched winning target.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct direct tap should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 1, "Correct direct tap should persist as one direct action.")


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
