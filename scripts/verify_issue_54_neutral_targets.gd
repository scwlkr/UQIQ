extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_54_neutral_targets_profile.json"
const COLOR_RED := Color(0.95, 0.22, 0.24)

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

	await _verify_pattern_grid_neutral_then_feedback()
	if _failed:
		return

	for level_number in [7, 8, 10]:
		_verify_tap_targets_neutral_then_feedback(level_number)
		if _failed:
			return

	print("Issue #54 neutral target verification passed: Level 17 grid and Levels 07/08/10 tap targets start role-neutral while wrong/correct input feedback still works.")
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


func _verify_pattern_grid_neutral_then_feedback() -> void:
	var level := _level_by_number(17)
	var level_id := str(level.get("id", ""))
	_main.call("_show_play_screen", level)
	await process_frame

	var cell_ids := ["r1c1", "r1c2", "r1c3", "r2c1", "r2c2", "r2c3", "r3c1", "r3c2", "r3c3"]
	_require(_buttons_share_normal_color(cell_ids.map(func(cell_id): return "pattern_mark_cell_%s" % cell_id)), "Level 17 grid cells should start with one neutral color.")
	_require(not _button_is_color(_node_named(_main, "pattern_mark_cell_r2c2") as Button, COLOR_RED), "Level 17 correct cell should not start red.")

	_press_pattern_cells(["r1c1"])
	_require(not _profile.is_level_completed(level_id), "Wrong Level 17 cell should not complete.")
	_require(str(_main.get("_judge_state")) == "fail", "Wrong Level 17 cell should still show fail feedback.")

	_main.call("_show_play_screen", level)
	await process_frame
	_press_pattern_cells(["r2c2"])
	_require(_profile.is_level_completed(level_id), "Correct Level 17 cell should still complete.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct Level 17 cell should route to Score Roastcard.")


func _verify_tap_targets_neutral_then_feedback(level_number: int) -> void:
	var level := _level_by_number(level_number)
	var level_id := str(level.get("id", ""))
	var rules := _dictionary_from(level.get("rules", {}))
	var targets := _array_from(rules.get("tap_targets", []))
	var solution := _dictionary_from(level.get("solution", {}))
	var correct_id := str(solution.get("target_id", ""))
	var labels: Array[String] = []
	var target_ids: Array[String] = []
	var wrong_target := {}
	var correct_label := ""

	_main.call("_show_play_screen", level)
	for target in targets:
		if typeof(target) != TYPE_DICTIONARY:
			continue
		var label := str(target.get("label", ""))
		labels.append(label)
		target_ids.append(str(target.get("id", "")))
		if str(target.get("id", "")) == correct_id:
			correct_label = label
		elif wrong_target.is_empty():
			wrong_target = target

	_require(labels.size() >= 2, "Level %02d should expose at least two tap targets." % level_number)
	if str(rules.get("interaction_model", "")) == "direct_tap_scene":
		_require(_tap_scene_targets_share_panel_color(target_ids), "Level %02d direct tap targets should start with one neutral color." % level_number)
		_require(not _control_is_color(_node_named(_main, "tap_scene_target_%s" % correct_id) as Control, COLOR_RED), "Level %02d correct direct tap target should not start red." % level_number)
	else:
		_require(_tap_buttons_share_normal_color(labels), "Level %02d tap targets should start with one neutral color." % level_number)
		_require(not _button_is_color(_button_with_text(_main, correct_label), COLOR_RED), "Level %02d correct tap target should not start red." % level_number)

	if str(rules.get("interaction_model", "")) == "direct_tap_scene":
		var wrong_pad := _node_named(_main, "tap_scene_target_%s" % str(wrong_target.get("id", ""))) as Control
		_require(wrong_pad != null, "Expected direct tap target %s." % str(wrong_target.get("id", "")))
		if _failed:
			return
		_main.call("_handle_direct_tap_scene_input", _screen_touch_event(true), str(wrong_target.get("id", "")), wrong_pad)
	else:
		_press_button_with_text(str(wrong_target.get("label", "")))
	_require(not _profile.is_level_completed(level_id), "Wrong Level %02d target should not complete." % level_number)
	_require(str(_main.get("_judge_state")) == "fail", "Wrong Level %02d tap should still show fail feedback." % level_number)

	_main.call("_show_play_screen", level)
	if str(rules.get("interaction_model", "")) == "direct_tap_scene":
		var correct_pad := _node_named(_main, "tap_scene_target_%s" % correct_id) as Control
		_require(correct_pad != null, "Expected direct tap target %s." % correct_id)
		if _failed:
			return
		_main.call("_handle_direct_tap_scene_input", _screen_touch_event(true), correct_id, correct_pad)
	else:
		_press_button_with_text(correct_label)
	_require(_profile.is_level_completed(level_id), "Correct Level %02d target should still complete." % level_number)
	_require(_screen_has_label_text("Score Roastcard"), "Correct Level %02d tap should route to Score Roastcard." % level_number)


func _press_pattern_cells(cell_ids: Array[String]) -> void:
	for cell_id in cell_ids:
		var button := _node_named(_main, "pattern_mark_cell_%s" % cell_id) as Button
		_require(button != null, "Expected Pattern Grid cell %s." % cell_id)
		if _failed:
			return
		button.pressed.emit()


func _press_button_with_text(text: String) -> void:
	var button := _button_with_text(_main, text)
	_require(button != null, "Expected button with text: %s" % text)
	if button == null:
		return
	button.pressed.emit()


func _buttons_share_normal_color(node_names: Array) -> bool:
	var reference := Color.TRANSPARENT
	var has_reference := false
	for node_name in node_names:
		var button := _node_named(_main, str(node_name)) as Button
		if button == null:
			return false
		var color := _button_normal_color(button)
		if not has_reference:
			reference = color
			has_reference = true
		elif not _same_color(reference, color):
			return false
	return has_reference


func _tap_buttons_share_normal_color(labels: Array[String]) -> bool:
	var reference := Color.TRANSPARENT
	var has_reference := false
	for label in labels:
		var button := _button_with_text(_main, label)
		if button == null:
			return false
		var color := _button_normal_color(button)
		if not has_reference:
			reference = color
			has_reference = true
		elif not _same_color(reference, color):
			return false
	return has_reference


func _tap_scene_targets_share_panel_color(target_ids: Array[String]) -> bool:
	var reference := Color.TRANSPARENT
	var has_reference := false
	for target_id in target_ids:
		var control := _node_named(_main, "tap_scene_target_%s" % target_id) as Control
		if control == null:
			return false
		var color := _control_panel_color(control)
		if not has_reference:
			reference = color
			has_reference = true
		elif not _same_color(reference, color):
			return false
	return has_reference


func _button_is_color(button: Button, color: Color) -> bool:
	if button == null:
		return false
	return _same_color(_button_normal_color(button), color)


func _control_is_color(control: Control, color: Color) -> bool:
	if control == null:
		return false
	return _same_color(_control_panel_color(control), color)


func _button_normal_color(button: Button) -> Color:
	var stylebox := button.get_theme_stylebox("normal") as StyleBoxFlat
	if stylebox == null:
		return Color.TRANSPARENT
	return stylebox.bg_color


func _control_panel_color(control: Control) -> Color:
	var stylebox := control.get_theme_stylebox("panel") as StyleBoxFlat
	if stylebox == null:
		return Color.TRANSPARENT
	return stylebox.bg_color


func _same_color(left: Color, right: Color) -> bool:
	return absf(left.r - right.r) < 0.001 \
		and absf(left.g - right.g) < 0.001 \
		and absf(left.b - right.b) < 0.001 \
		and absf(left.a - right.a) < 0.001


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
	if text.is_empty():
		return true
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


func _array_from(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _screen_touch_event(pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = pressed
	event.position = Vector2(16, 16)
	return event


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
