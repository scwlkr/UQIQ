extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_65_brake_check_profile.json"

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

	await _verify_level_2_freehand_stopper()
	if _failed:
		return

	print("Issue #65 Brake Check verification passed: Level 2 renders freehand stopper physics, touch strokes create collision, ramp/short/misplaced strokes fail, reset clears runtime state, and a valid stopper reaches the cup by overlap.")
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


func _verify_level_2_freehand_stopper() -> void:
	var level := _level_by_number(2)
	var level_id := str(level.get("id", ""))
	var rules := _dictionary_from(level.get("rules", {}))
	_require(str(level.get("title", "")) == "Brake Check", "Level 2 should be titled Brake Check.")
	_require(str(level.get("template", "")) == "Physics Draw", "Level 2 should render as Physics Draw.")
	_require(str(rules.get("interaction_model", "")) == "freehand_physics_then_release", "Level 2 should use freehand physics.")
	_require(str(rules.get("freehand_solution_kind", "")) == "stopper", "Level 2 should use stopper solution geometry.")
	if _failed:
		return

	_main.call("_show_play_screen", level)
	await process_frame
	_assert_brake_check_surface()
	if _failed:
		return

	_draw_line_with_touch(Vector2(284, 184), Vector2(288, 210))
	_require(str(_main.get("_last_physics_result")) == "too_short", "Too-short stopper should fail before release.")
	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Too-short stopper should fail on release.")
	_require(_screen_has_label_text("Too short"), "Too-short failure should be readable.")
	_require(not _profile.is_level_completed(level_id), "Too-short stopper should not complete Level 2.")

	_press_button("Reset")
	_assert_freehand_reset_state()
	if _failed:
		return

	_draw_line_with_touch(Vector2(42, 232), Vector2(288, 176))
	_require(_stroke_collision_count() > 0, "Ramp-like stroke should create collision geometry before release.")
	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Ramp-like stroke should fail on release.")
	_require(_screen_has_label_text("Overshot"), "Ramp/bridge failure should explain overshoot.")
	_require(not _profile.is_level_completed(level_id), "Ramp-like stroke should not complete Level 2.")

	_press_button("Reset")
	_assert_freehand_reset_state()
	if _failed:
		return

	_draw_line_with_touch(Vector2(170, 164), Vector2(170, 230))
	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Misplaced stopper should fail on release.")
	_require(_screen_has_label_text("Missed the cup"), "Misplaced stopper failure should be readable.")
	_require(not _profile.is_level_completed(level_id), "Misplaced stopper should not complete Level 2.")

	_main.call("_show_play_screen", level)
	await process_frame
	_assert_brake_check_surface()
	if _failed:
		return

	_draw_line_with_touch(Vector2(286, 168), Vector2(286, 234))
	var line := _node_named(_main, "player_drawn_line") as Line2D
	_require(line != null and line.width >= 12.0, "Stopper stroke should render as a thick visible Line2D.")
	_require(line != null and line.points.size() >= 2, "Stopper stroke should create visible line points.")
	_require(_stroke_collision_count() > 0, "Valid stopper should create StaticBody2D collision shapes.")
	_require(not bool(_main.get("_freehand_ball_moved")), "Ball should wait until Release before moving.")
	_press_button("Release")
	_require(bool(_main.get("_freehand_ball_moved")), "Release should start ball motion.")
	_require(str(_main.get("_last_physics_result")) == "success", "Valid stopper should succeed by ball/cup overlap.")
	_require(_profile.is_level_completed(level_id), "Valid stopper should complete Level 2.")
	_require(_screen_has_label_text("Score Roastcard"), "Valid stopper should route to Score Roastcard.")

	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 2, "Drawing plus Release should persist as two actions.")


func _assert_brake_check_surface() -> void:
	_require(_node_named(_main, "physics_draw_surface") != null, "Level 2 should render a named draw surface.")
	_require(_node_named(_main, "freehand_ball") != null, "Level 2 should render a freehand ball.")
	_require(_node_named(_main, "freehand_cup") != null, "Level 2 should render a freehand cup.")
	_require(_node_named(_main, "freehand_goal_area") is Area2D, "Level 2 should create an Area2D goal zone.")
	_require(_node_named(_main, "freehand_built_in_geometry_starter_chute") is Line2D, "Level 2 should render the starter chute.")
	_require(_node_named(_main, "freehand_built_in_body") is StaticBody2D, "Level 2 starter chute should create StaticBody2D collision.")
	_require(_button_with_text(_main, "Release") != null, "Level 2 should expose Release.")
	_require(_button_with_text(_main, "Reset") != null, "Level 2 should expose Reset.")
	_require(_button_with_text(_main, "Release Ball") == null, "Level 2 should not use the old Release Ball copy.")
	_require(not _has_button_prefix(_main, "Draw:"), "Level 2 should not expose answer-choice Draw buttons.")
	_require(_node_named(_main, "drag_playfield") == null, "Level 2 should no longer render Drag Logic UI.")


func _assert_freehand_reset_state() -> void:
	_require(_node_named(_main, "freehand_stroke_body") == null, "Reset should clear old stroke collision.")
	var line := _node_named(_main, "player_drawn_line") as Line2D
	_require(line != null and line.points.size() == 0, "Reset should clear visible stroke points.")
	var ball_position = _main.get("_freehand_last_ball_position")
	_require(ball_position is Vector2 and (ball_position as Vector2).distance_to(Vector2(74, 118)) < 0.1, "Reset should return the ball to the Brake Check start.")
	_require(not bool(_main.get("_freehand_ball_moved")), "Reset should clear ball motion state.")


func _draw_line_with_touch(start: Vector2, end: Vector2) -> void:
	var surface := _node_named(_main, "physics_draw_surface") as Control
	_require(surface != null, "Physics Draw surface should exist before drawing.")
	if surface == null:
		return

	_main.call("_handle_physics_surface_input", _screen_touch_event(start, true), surface)
	_main.call("_handle_physics_surface_input", _screen_drag_event(end, end - start), surface)
	_main.call("_handle_physics_surface_input", _screen_touch_event(end, false), surface)


func _press_button(text: String) -> void:
	var button := _button_with_text(_main, text)
	_require(button != null, "Button should exist: %s" % text)
	if button != null:
		button.pressed.emit()


func _stroke_collision_count() -> int:
	var body := _node_named(_main, "freehand_stroke_body")
	if body == null:
		return 0
	return body.get_child_count()


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


func _node_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var match := _node_named(child, node_name)
		if match != null:
			return match
	return null


func _button_with_text(node: Node, text: String) -> Button:
	if node is Button and str(node.text) == text:
		return node as Button
	for child in node.get_children():
		var match := _button_with_text(child, text)
		if match != null:
			return match
	return null


func _has_button_prefix(node: Node, prefix: String) -> bool:
	if node is Button and str(node.text).begins_with(prefix):
		return true
	for child in node.get_children():
		if _has_button_prefix(child, prefix):
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


func _dictionary_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	_failed = true
	_cleanup()
	quit(1)


func _cleanup() -> void:
	if _main != null and is_instance_valid(_main):
		_main.queue_free()
	_remove_test_save()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
