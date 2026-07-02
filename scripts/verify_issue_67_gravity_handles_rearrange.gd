extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_67_gravity_handles_profile.json"

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

	await _verify_level_4_gravity_handles_rearrange()
	if _failed:
		return

	print("Issue #67 Gravity Handles verification passed: Level 4 renders physics-linked GRAVITY rearrange, touch drag selects slots, wrong/no slot fails, reset clears state, and right-wall gravity completes by ball/cup overlap.")
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


func _verify_level_4_gravity_handles_rearrange() -> void:
	var level := _level_by_number(4)
	var level_id := str(level.get("id", ""))
	var rules := _dictionary_from(level.get("rules", {}))
	_require(str(level.get("title", "")) == "Gravity Has Handles", "Level 4 should be titled Gravity Has Handles.")
	_require(str(level.get("template", "")) == "Rearrange Level", "Level 4 should render as a Rearrange Level.")
	_require(str(rules.get("interaction_model", "")) == "physics_linked_rearrange_then_release", "Level 4 should use physics-linked rearrange.")
	_require(str(rules.get("rearrange_mode", "")) == "move_rule_tile", "Level 4 should move a rule tile.")
	if _failed:
		return

	_main.call("_show_play_screen", level)
	await process_frame
	_assert_gravity_surface()
	if _failed:
		return

	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Unmoved GRAVITY should fail on Release.")
	_require(bool(_main.get("_rearrange_released")), "Release should record rearrange release state.")
	_require(bool(_main.get("_rearrange_ball_moved")), "Release should move the ball even on a visible miss.")
	_require(_screen_has_label_text("Move GRAVITY"), "No-slot failure should be readable.")
	_require(not _profile.is_level_completed(level_id), "Unmoved GRAVITY should not complete Level 4.")

	_press_button("Reset")
	_assert_gravity_reset_state()
	if _failed:
		return

	_drag_gravity_to(Vector2(54, 161))
	_require(bool(_main.get("_rearrange_rule_tile_moved")), "Touch drag should mark the GRAVITY tile as moved.")
	_require(str(_main.get("_rearrange_selected_gravity_slot_id")) == "left_wall_slot", "Left drag should select the left wall slot.")
	_require(_vector_close(_main.get("_rearrange_selected_gravity_vector"), Vector2(-720, 0)), "Left slot should select leftward gravity.")
	_require(not bool(_main.get("_rearrange_ball_moved")), "Ball should wait until Release after rule drag.")
	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Wrong gravity slot should fail on Release.")
	_require(_screen_has_label_text("Wrong wall") or _screen_has_label_text("Gravity went"), "Wrong gravity failure should be readable.")
	_require(not _profile.is_level_completed(level_id), "Wrong gravity slot should not complete Level 4.")

	_main.call("_show_play_screen", level)
	await process_frame
	_assert_gravity_surface()
	if _failed:
		return

	_drag_gravity_to(Vector2(160, 70))
	_require(str(_main.get("_rearrange_selected_gravity_slot_id")) == "floor_slot", "Invalid drop should return to the last valid floor slot.")
	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Invalid/no target slot should fail on Release.")
	_require(not _profile.is_level_completed(level_id), "Invalid/no target slot should not complete Level 4.")

	_main.call("_show_play_screen", level)
	await process_frame
	_assert_gravity_surface()
	if _failed:
		return

	_drag_gravity_to(Vector2(286, 161))
	_require(str(_main.get("_rearrange_selected_gravity_slot_id")) == "right_wall_slot", "Right drag should select the right wall slot.")
	_require(_vector_close(_main.get("_rearrange_selected_gravity_vector"), Vector2(720, 0)), "Right slot should select rightward gravity.")
	_press_button("Release")
	_require(str(_main.get("_last_physics_result")) == "success", "Right-wall gravity should succeed.")
	_require(bool(_main.get("_rearrange_ball_moved")), "Successful Release should move the ball.")
	_require(_profile.is_level_completed(level_id), "Right-wall gravity should complete Level 4.")
	_require(_screen_has_label_text("Score Roastcard"), "Right-wall gravity should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 2, "Drag plus Release should persist as two actions.")


func _assert_gravity_surface() -> void:
	_require(_node_named(_main, "rearrange_playfield") != null, "Level 4 should render a named rearrange playfield.")
	_require(_node_named(_main, "rearrange_ball") != null, "Level 4 should render the ball.")
	_require(_node_named(_main, "rearrange_ball_body") is RigidBody2D, "Level 4 should create a ball physics body.")
	_require(_node_named(_main, "rearrange_right_wall_cup") != null, "Level 4 should render a right-wall cup.")
	_require(_node_named(_main, "rearrange_goal_area") is Area2D, "Level 4 should create an Area2D goal zone.")
	_require(_node_named(_main, "rearrange_gravity_tile") != null, "Level 4 should render a draggable GRAVITY tile.")
	_require(_node_named(_main, "rearrange_gravity_slot_floor_slot") != null, "Level 4 should render a floor gravity slot.")
	_require(_node_named(_main, "rearrange_gravity_slot_left_wall_slot") != null, "Level 4 should render a left-wall gravity slot.")
	_require(_node_named(_main, "rearrange_gravity_slot_right_wall_slot") != null, "Level 4 should render a right-wall gravity slot.")
	var tile := _node_named(_main, "rearrange_gravity_tile") as Control
	var release_label := _node_named(_main, "rearrange_release_result_label") as Label
	_require(release_label != null, "Level 4 should render a named Release result label.")
	_require(tile == null or release_label == null or not _control_rect(tile).intersects(_control_rect(release_label)), "Release result label should not overlap the GRAVITY tile on phone.")
	var gravity_label := _node_named(_main, "rearrange_gravity_tile_label") as Label
	_require(gravity_label != null, "Level 4 should render a non-wrapping GRAVITY label.")
	_require(gravity_label == null or gravity_label.autowrap_mode == TextServer.AUTOWRAP_OFF, "GRAVITY label should not wrap vertically on phone.")
	_require(_button_with_text(_main, "Release") != null, "Level 4 should expose Release.")
	_require(_button_with_text(_main, "Reset") != null, "Level 4 should expose Reset.")
	_require(_node_named(_main, "pattern_mark_grid") == null, "Level 4 should not render the old Pattern Grid surface.")
	_require(not _has_button_text(_main, "Submit Pattern"), "Level 4 should not expose the old Pattern Grid submit button.")
	_require(not _has_button_prefix(_main, "Move:"), "Level 4 should not expose Move: answer-choice buttons.")
	_require(not _has_button_prefix(_main, "Drop on:"), "Level 4 should not expose Drop on: answer-choice buttons.")


func _assert_gravity_reset_state() -> void:
	_require(not bool(_main.get("_rearrange_rule_tile_moved")), "Reset should clear moved rule-tile state.")
	_require(not bool(_main.get("_rearrange_released")), "Reset should clear release state.")
	_require(not bool(_main.get("_rearrange_ball_moved")), "Reset should clear ball motion state.")
	_require(str(_main.get("_rearrange_selected_gravity_slot_id")) == "floor_slot", "Reset should return selected gravity to floor.")
	_require(_vector_close(_main.get("_rearrange_selected_gravity_vector"), Vector2(0, 720)), "Reset should return gravity vector to downward.")
	var ball_position = _main.get("_rearrange_last_ball_position")
	_require(ball_position is Vector2 and (ball_position as Vector2).distance_to(Vector2(112, 150)) < 0.1, "Reset should return the ball to the start.")
	var tile_rect := _gravity_tile_rect()
	_require(tile_rect.position.distance_to(Vector2(132, 236)) < 0.1, "Reset should return GRAVITY to its floor start position.")


func _drag_gravity_to(target_center: Vector2) -> void:
	var tile := _node_named(_main, "rearrange_gravity_tile") as Control
	_require(tile != null, "Expected draggable GRAVITY tile before touch drag.")
	if tile == null:
		return

	var press_position := tile.size * 0.5
	_main.call("_handle_rearrange_object_input", _screen_touch_event(press_position, true), "gravity_tile", tile)
	var target_canvas := (tile.get_parent() as Control).get_global_transform_with_canvas() * target_center
	var drag_position := tile.get_global_transform_with_canvas().affine_inverse() * target_canvas
	_main.call("_handle_rearrange_object_input", _screen_drag_event(drag_position, drag_position - press_position), "gravity_tile", tile)
	var release_position := tile.get_global_transform_with_canvas().affine_inverse() * target_canvas
	_main.call("_handle_rearrange_object_input", _screen_touch_event(release_position, false), "gravity_tile", tile)


func _gravity_tile_rect() -> Rect2:
	var tile = _node_named(_main, "rearrange_gravity_tile") as Control
	if tile == null:
		return Rect2()
	return Rect2(tile.position, tile.size)


func _control_rect(control: Control) -> Rect2:
	return Rect2(control.global_position, control.size)


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
	if node == null:
		return null
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


func _has_button_text(node: Node, text: String) -> bool:
	if node is Button and str(node.text) == text:
		return true
	for child in node.get_children():
		if _has_button_text(child, text):
			return true
	return false


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
	if node == null:
		return false
	if node is Label and str(node.text).contains(text):
		return true
	for child in node.get_children():
		if _node_has_label_text(child, text):
			return true
	return false


func _vector_close(value: Variant, expected: Vector2) -> bool:
	return value is Vector2 and (value as Vector2).distance_to(expected) < 0.1


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
	if _main != null:
		_main.queue_free()
	_remove_test_save()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
