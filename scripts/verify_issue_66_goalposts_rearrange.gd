extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_66_goalposts_rearrange_profile.json"

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

	await _verify_level_3_goalposts_rearrange()
	if _failed:
		return

	print("Issue #66 Goalposts verification passed: Level 3 renders physics-linked cup rearrange, touch drag moves the cup, wrong/no movement fails, reset clears state, and correct placement completes by ball/cup overlap.")
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


func _verify_level_3_goalposts_rearrange() -> void:
	var level := _level_by_number(3)
	var level_id := str(level.get("id", ""))
	var rules := _dictionary_from(level.get("rules", {}))
	_require(str(level.get("title", "")) == "Goalposts Are Portable", "Level 3 should be titled Goalposts Are Portable.")
	_require(str(level.get("template", "")) == "Rearrange Level", "Level 3 should render as a Rearrange Level.")
	_require(str(rules.get("interaction_model", "")) == "physics_linked_rearrange_then_release", "Level 3 should use physics-linked rearrange.")
	_require(str(rules.get("rearrange_mode", "")) == "move_goal_marker", "Level 3 should move the goal marker.")
	if _failed:
		return

	_main.call("_show_play_screen", level)
	await process_frame
	_assert_goalposts_surface()
	if _failed:
		return

	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Unmoved cup should fail on Release.")
	_require(bool(_main.get("_rearrange_released")), "Release should record rearrange release state.")
	_require(bool(_main.get("_rearrange_ball_moved")), "Release should move the ball even on a visible miss.")
	_require(_screen_has_label_text("Move the cup"), "No-move failure should be readable.")
	_require(not _profile.is_level_completed(level_id), "Unmoved cup should not complete Level 3.")

	_press_button("Reset")
	_assert_rearrange_reset_state()
	if _failed:
		return

	_drag_cup_to(Vector2(72, 224))
	_require(bool(_main.get("_rearrange_cup_moved")), "Touch drag should mark the cup as moved.")
	_require(_cup_inside_allowed_rect(), "Touch drag should keep the cup inside its allowed drag rect.")
	_require(not bool(_main.get("_rearrange_ball_moved")), "Ball should wait until Release after cup drag.")
	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Wrong cup placement should fail on Release.")
	_require(_screen_has_label_text("Missed"), "Wrong placement failure should be readable.")
	_require(not _profile.is_level_completed(level_id), "Wrong cup placement should not complete Level 3.")

	_main.call("_show_play_screen", level)
	await process_frame
	_assert_goalposts_surface()
	if _failed:
		return

	_drag_cup_to(_target_rect().get_center())
	var cup_rect := _cup_rect()
	_require(_cup_inside_allowed_rect(), "Correct cup placement should stay inside the allowed drag rect.")
	_require(cup_rect.intersects(_target_rect().grow(18.0), true), "Correct drag should place the cup near the catch zone.")
	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "success", "Correct cup placement should succeed.")
	_require(bool(_main.get("_rearrange_ball_moved")), "Successful Release should move the ball.")
	_require(_profile.is_level_completed(level_id), "Correct cup placement should complete Level 3.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct cup placement should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 2, "Drag plus Release should persist as two actions.")


func _assert_goalposts_surface() -> void:
	_require(_node_named(_main, "rearrange_playfield") != null, "Level 3 should render a named rearrange playfield.")
	_require(_node_named(_main, "rearrange_ball") != null, "Level 3 should render the ball.")
	_require(_node_named(_main, "rearrange_ball_body") is RigidBody2D, "Level 3 should create a ball physics body.")
	_require(_node_named(_main, "rearrange_cup") != null, "Level 3 should render a draggable cup.")
	_require(_node_named(_main, "rearrange_goal_area") is Area2D, "Level 3 should create an Area2D goal zone from the moved cup.")
	_require(_node_named(_main, "rearrange_catch_zone_hint") != null, "Level 3 should render a subtle catch-zone hint.")
	_require(_node_named(_main, "rearrange_built_in_geometry_starter_chute") is Line2D, "Level 3 should render the starter chute.")
	_require(_node_named(_main, "rearrange_built_in_body") is StaticBody2D, "Level 3 starter chute should create StaticBody2D collision.")
	_require(_button_with_text(_main, "Release") != null, "Level 3 should expose Release.")
	_require(_button_with_text(_main, "Reset") != null, "Level 3 should expose Reset.")
	_require(_node_named(_main, "text_tile_surface") == null, "Level 3 should not render the old Text Trap surface.")
	_require(not _has_line_edit(_main), "Level 3 should not render old Text Trap input.")
	_require(not _has_button_prefix(_main, "Move:"), "Level 3 should not expose Move: answer-choice buttons.")
	_require(not _has_button_prefix(_main, "Drop on:"), "Level 3 should not expose Drop on: answer-choice buttons.")
	_require(_node_named(_main, "drag_playfield") == null, "Level 3 should not use the old Drag Logic playfield.")


func _assert_rearrange_reset_state() -> void:
	_require(not bool(_main.get("_rearrange_cup_moved")), "Reset should clear moved cup state.")
	_require(not bool(_main.get("_rearrange_released")), "Reset should clear release state.")
	_require(not bool(_main.get("_rearrange_ball_moved")), "Reset should clear ball motion state.")
	var ball_position = _main.get("_rearrange_last_ball_position")
	_require(ball_position is Vector2 and (ball_position as Vector2).distance_to(Vector2(72, 88)) < 0.1, "Reset should return the ball to the start.")
	var cup_rect := _cup_rect()
	_require(cup_rect.position.distance_to(Vector2(260, 214)) < 0.1, "Reset should return the cup to its wrong start position.")


func _drag_cup_to(target_center: Vector2) -> void:
	var cup := _node_named(_main, "rearrange_cup") as Control
	_require(cup != null, "Expected draggable cup before touch drag.")
	if cup == null:
		return

	var press_position := cup.size * 0.5
	_main.call("_handle_rearrange_object_input", _screen_touch_event(press_position, true), "cup", cup)
	var target_canvas := (cup.get_parent() as Control).get_global_transform_with_canvas() * target_center
	var drag_position := cup.get_global_transform_with_canvas().affine_inverse() * target_canvas
	_main.call("_handle_rearrange_object_input", _screen_drag_event(drag_position, drag_position - press_position), "cup", cup)
	_main.call("_handle_rearrange_object_input", _screen_touch_event(drag_position, false), "cup", cup)


func _cup_inside_allowed_rect() -> bool:
	return _allowed_rect().encloses(_cup_rect())


func _cup_rect() -> Rect2:
	var cup = _node_named(_main, "rearrange_cup") as Control
	if cup == null:
		return Rect2()
	return Rect2(cup.position, cup.size)


func _allowed_rect() -> Rect2:
	return Rect2(36, 156, 268, 112)


func _target_rect() -> Rect2:
	return Rect2(188, 214, 74, 58)


func _press_button(text: String) -> void:
	var button := _button_with_text(_main, text)
	_require(button != null, "Button should exist: %s" % text)
	if button != null:
		button.pressed.emit()


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


func _has_line_edit(node: Node) -> bool:
	if node is LineEdit:
		return true
	for child in node.get_children():
		if _has_line_edit(child):
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
