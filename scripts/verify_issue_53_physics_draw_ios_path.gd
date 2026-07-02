extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_53_physics_draw_ios_path_profile.json"

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

	_verify_invalid_flat_touch_line_fails()
	if _failed:
		return

	_verify_rising_ramp_touch_line_completes()
	if _failed:
		return

	print("Issue #53 Physics Draw iOS-path verification passed: screen-touch drawing stays inside the surface, flat lines fail, and a rising ramp classifies as ramp_to_cup then completes through Score Roastcard.")
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_main.call("_setup_feedback")
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_invalid_flat_touch_line_fails() -> void:
	var level := _level_by_number(6)
	var level_id := str(level.get("id", ""))
	_main.call("_show_play_screen", level)
	await process_frame

	_draw_line_with_touch(Vector2(48, 220), Vector2(260, 218))
	_require(str(_main.get("_physics_choice")) != "ramp_to_cup", "Flat touch line should not classify as ramp_to_cup.")
	_require(str(_main.get("_last_physics_result")) == "selected", "Flat touch line should still select a line before release.")
	_press_release_ball()
	_require(str(_main.get("_last_physics_result")) == "fail", "Invalid flat touch line should fail after release.")
	_require(not _profile.is_level_completed(level_id), "Invalid flat touch line should not complete Level 06.")


func _verify_rising_ramp_touch_line_completes() -> void:
	var level := _level_by_number(6)
	var level_id := str(level.get("id", ""))
	_main.call("_show_play_screen", level)
	await process_frame

	_draw_line_with_touch(Vector2(48, 220), Vector2(260, 110))
	_require(_drawn_line_stays_inside_surface(), "Touch-drawn line should stay inside the Physics Draw surface.")
	_require(str(_main.get("_physics_choice")) == "ramp_to_cup", "Rising touch ramp should classify as ramp_to_cup.")
	_require(_screen_has_label_text("Selected line: ramp to cup"), "Rising touch ramp should show the ramp label.")
	_press_release_ball()
	_require(str(_main.get("_last_physics_result")) == "success", "Valid touch ramp should succeed after release.")
	_require(_profile.is_level_completed(level_id), "Valid touch ramp should complete Level 06.")
	_require(_screen_has_label_text("Score Roastcard"), "Valid touch ramp should route to Score Roastcard.")

	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 2, "Draw plus Release Ball should persist as two actions.")


func _draw_line_with_touch(start: Vector2, end: Vector2) -> void:
	var surface := _physics_surface()
	if _failed:
		return

	_main.call("_handle_physics_surface_input", _screen_touch_event(start, true), surface)
	_main.call("_handle_physics_surface_input", _screen_drag_event(end, end - start), surface)
	_main.call("_handle_physics_surface_input", _screen_touch_event(end, false), surface)


func _press_release_ball() -> void:
	var button := _button_with_text(_main, "Release Ball")
	_require(button != null, "Release Ball button should exist.")
	if button == null:
		return
	button.pressed.emit()


func _drawn_line_stays_inside_surface() -> bool:
	var surface := _physics_surface()
	var line := _node_named(_main, "player_drawn_line") as Line2D
	if surface == null or line == null:
		return false

	for point in line.points:
		if point.x < 0.0 or point.y < 0.0:
			return false
		if surface.size.x > 0.0 and point.x > surface.size.x:
			return false
		if surface.size.y > 0.0 and point.y > surface.size.y:
			return false
	return true


func _physics_surface() -> Control:
	var surface := _node_named(_main, "physics_draw_surface") as Control
	_require(surface != null, "Physics Draw surface should exist.")
	return surface


func _screen_touch_event(position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	return event


func _screen_drag_event(position: Vector2, relative: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.position = position
	event.relative = relative
	return event


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


func _button_with_text(node: Node, text: String) -> Button:
	if node is Button and str(node.text) == text:
		return node as Button
	for child in node.get_children():
		var match := _button_with_text(child, text)
		if match != null:
			return match
	return null


func _node_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var match := _node_named(child, node_name)
		if match != null:
			return match
	return null


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
