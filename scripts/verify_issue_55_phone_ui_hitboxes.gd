extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_55_phone_ui_hitboxes_profile.json"

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

	await _verify_level_01_direct_tap_labels_fit()
	if _failed:
		return

	await _verify_level_09_text_focus_and_completion()
	if _failed:
		return

	_verify_notched_phone_safe_margins()
	if _failed:
		return

	print("Issue #55 phone UI verification passed: Level 01 direct tap labels fit without word-splitting, Level 09 touch focus requests the virtual keyboard and completes with portrait, and notched-phone margins remain applied.")
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


func _verify_level_01_direct_tap_labels_fit() -> void:
	_main.call("_show_play_screen", _level_by_number(1))
	await process_frame

	var surface := _node_named(_main, "tap_scene_surface") as Control
	var correct_pad := _node_named(_main, "tap_scene_target_correct_button") as Control
	var wrong_pad := _node_named(_main, "tap_scene_target_wrong_button") as Control
	_require(surface != null, "Level 01 should render the direct tap surface.")
	_require(correct_pad != null, "Level 01 should render the CORRECT direct target.")
	_require(wrong_pad != null, "Level 01 should render the WRONG direct target.")
	if _failed:
		return

	_require(_control_fits_inside(correct_pad, surface), "CORRECT direct target should remain inside the phone play surface.")
	_require(_control_fits_inside(wrong_pad, surface), "WRONG direct target should remain inside the phone play surface.")
	_require(_target_label_fits_single_line(correct_pad, "CORRECT"), "CORRECT target label should fit as one readable line.")
	_require(_target_label_fits_single_line(wrong_pad, "WRONG"), "WRONG target label should fit as one readable line.")


func _verify_level_09_text_focus_and_completion() -> void:
	var level := _level_by_number(9)
	var level_id := str(level.get("id", ""))
	_main.call("_show_play_screen", level)
	await process_frame

	var text_input := _main.get("_text_input") as LineEdit
	_require(text_input != null, "Level 09 should render a single-line text input.")
	if _failed:
		return

	_require(text_input.virtual_keyboard_enabled, "Level 09 text input should have virtual keyboard enabled.")
	_require(text_input.virtual_keyboard_show_on_focus, "Level 09 text input should show the virtual keyboard on focus.")

	_main.call("_handle_text_input_focus_event", _screen_touch_event(true))
	await process_frame
	_require(text_input.has_focus(), "Normal touch on Level 09 text input should focus the field.")
	_require(text_input.is_editing(), "Normal touch on Level 09 text input should enter edit mode.")
	_require(bool(_main.get("_last_text_focus_event_was_touch")), "Level 09 focus path should record touch input.")
	_require(int(_main.get("_text_keyboard_request_count")) > 0, "Level 09 touch focus should request the virtual keyboard.")
	var keyboard_rect: Rect2 = _main.get("_last_text_keyboard_rect")
	_require(keyboard_rect.size.x > 0.0 and keyboard_rect.size.y > 0.0, "Level 09 keyboard request should include the text field screen rect.")

	text_input.text = "portrait"
	_main.call("_handle_text_submit")
	_require(_profile.is_level_completed(level_id), "Level 09 should still complete with portrait.")
	_require(_screen_has_label_text("Score Roastcard"), "Level 09 completion should still route to Score Roastcard.")


func _verify_notched_phone_safe_margins() -> void:
	var margins: Dictionary = _main.call(
		"_screen_margins_for_safe_area",
		Rect2i(Vector2i(0, 135), Vector2i(1290, 2659)),
		Vector2i(1290, 2796),
		Vector2(390, 844)
	)
	_require(int(margins.get("top", 0)) > 22, "Notched phone top margin should include safe-area inset.")
	_require(int(margins.get("bottom", 0)) > 22, "Notched phone bottom margin should include safe-area inset.")


func _target_label_fits_single_line(target: Control, expected_text: String) -> bool:
	var label := _first_label(target)
	if label == null:
		return false
	if label.text != expected_text:
		return false
	if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
		return false

	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var text_width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var content_width := maxf(target.size.x - 28.0, 0.0)
	return text_width <= content_width


func _control_fits_inside(control: Control, parent: Control) -> bool:
	var rect := Rect2(control.position, control.size)
	var parent_rect := Rect2(Vector2.ZERO, parent.size)
	return parent_rect.encloses(rect)


func _first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child in node.get_children():
		var match := _first_label(child)
		if match != null:
			return match
	return null


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
