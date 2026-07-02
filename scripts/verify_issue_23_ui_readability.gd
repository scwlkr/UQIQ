extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_23_ui_readability_profile.json"

var _loader := LevelLoaderScript.new()
var _pack_set := {}
var _main: Control
var _profile: RefCounted
var _failed := false
var _checked_label_count := 0
var _checked_button_count := 0


func _initialize() -> void:
	_remove_test_save()
	_pack_set = _loader.load_default_packs()
	_require(not _pack_set.is_empty(), _loader.last_error)
	if _failed:
		return

	_boot_main_scene()
	if _failed:
		return
	_verify_main_flow_text_controls()
	if _failed:
		return

	print("Issue #23 UI readability verification passed: %d long labels and %d buttons use portrait-safe wrapping/overrun settings across list, play, Physics Draw, and Score Roastcard screens." % [_checked_label_count, _checked_button_count])
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_main.call("_setup_feedback")
	_profile.load_or_create()
	_main.set("_pack", _pack_set)
	_main.set("_packs", _main.call("_pack_groups_from_pack_set", _pack_set))
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_main_flow_text_controls() -> void:
	_prepare_level_list_status_rows()
	_main.call("_show_level_list")
	_assert_compact_level_row(1)
	_assert_compact_level_row(2)
	_assert_compact_level_row(3)
	_assert_text_controls("Level List")

	_main.call("_show_play_screen", _level_by_number(41))
	_assert_play_header_metrics_visible("Memory Flash Play Screen")
	_assert_roast_control_secondary("Memory Flash Play Screen")
	_assert_text_controls("Memory Flash Play Screen")

	_main.call("_show_play_screen", _level_by_number(51))
	_assert_play_header_metrics_visible("Physics Draw Play Screen")
	_assert_roast_control_secondary("Physics Draw Play Screen")
	_assert_text_controls("Physics Draw Play Screen")

	var level := _level_by_number(1)
	_main.call("_show_play_screen", level)
	_main.call("_handle_tap_target", str(_solution(level).get("target_id", "")))
	_require(_screen_has_label_text("Score Roastcard"), "Score Roastcard should render for readability sweep.")
	_assert_text_controls("Score Roastcard")


func _prepare_level_list_status_rows() -> void:
	var completed_level := _level_by_number(1)
	var best_attempt: Dictionary = _profile.record_completed_attempt(completed_level, 2, 0, 1.0)
	_require(not best_attempt.is_empty(), "Level 1 should be completed before compact row checks: %s" % _profile.last_error)
	if _failed:
		return

	var dur_level := _level_by_number(2)
	_require(_profile.spend_dur_token(dur_level), "Level 2 should enter DUR'D state before compact row checks: %s" % _profile.last_error)


func _assert_compact_level_row(level_number: int) -> void:
	var button := _level_button_for_number(level_number)
	_require(button != null, "Level List should expose a tappable compact row for Level %d. Saw buttons: %s" % [level_number, ", ".join(_visible_button_texts())])
	if button == null:
		return

	var text := str(button.text)
	_require(text.begins_with("%02d  " % level_number), "Level %d row text should keep the Level number first: %s" % [level_number, text])
	_require(not text.contains("completed"), "Completed Level %d row should not carry long status copy: %s" % [level_number, text])
	_require(not text.contains("replay"), "Completed Level %d row should not carry replay copy in the phone row title: %s" % [level_number, text])
	_require(not text.contains("finish to recover"), "DUR'D Level %d row should not carry recovery instructions in the row title: %s" % [level_number, text])
	_require(button.get_theme_font_size("font_size") <= 17, "Level %d row should use compact phone typography." % level_number)
	_require(button.custom_minimum_size.y <= 54, "Level %d row should keep a compact touch row height." % level_number)


func _assert_text_controls(context: String) -> void:
	_collect_text_controls(_main, context)


func _assert_play_header_metrics_visible(context: String) -> void:
	_assert_play_header_chip_visible(context, "UQIQ %d" % _profile.current_uqiq_score(), 100.0, "current UQIQ score")
	_assert_play_header_chip_visible(context, "Dur %d/%d" % [_profile.dur_tokens(), LocalProfileScript.MAX_DUR_TOKENS], 92.0, "current Dur Token count")


func _assert_play_header_chip_visible(context: String, text: String, minimum_width: float, description: String) -> void:
	var label := _label_with_text(_main, text)
	_require(label != null, "%s play header should show the %s." % [context, description])
	if label == null:
		return

	var chip := label.get_parent() as Control
	_require(chip != null and chip.custom_minimum_size.x >= minimum_width, "%s %s chip should be wide enough." % [context, text])


func _assert_roast_control_secondary(context: String) -> void:
	var roast_button := _button_with_exact_text(_main, "Roast")
	_require(roast_button != null, "%s should expose the Roast control." % context)
	if roast_button == null:
		return
	_require(roast_button.custom_minimum_size.x <= 120 and roast_button.custom_minimum_size.y <= 42, "%s Roast control should stay visually secondary." % context)
	_require(roast_button.get_theme_font_size("font_size") <= 16, "%s Roast control should use secondary-sized text." % context)


func _collect_text_controls(node: Node, context: String) -> void:
	if node is Label:
		var label := node as Label
		var text := str(label.text)
		if text.length() > 12:
			_checked_label_count += 1
			_require(label.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s long label should autowrap: %s" % [context, text])
			_require((label.size_flags_horizontal & Control.SIZE_EXPAND) != 0, "%s long label should expand horizontally: %s" % [context, text])
	if node is Button:
		var button := node as Button
		var text := str(button.text)
		if not text.is_empty():
			_checked_button_count += 1
			_require(button.clip_text, "%s button should clip safely: %s" % [context, text])
			_require(button.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "%s button should use ellipsis overrun: %s" % [context, text])

	for child in node.get_children():
		_collect_text_controls(child, context)


func _screen_has_label_text(text: String) -> bool:
	return _node_has_label_text(_main, text)


func _node_has_label_text(node: Node, text: String) -> bool:
	if node is Label and str(node.text).contains(text):
		return true
	for child in node.get_children():
		if _node_has_label_text(child, text):
			return true
	return false


func _label_with_text(node: Node, text: String) -> Label:
	if node is Label and str(node.text).contains(text):
		return node as Label
	for child in node.get_children():
		var label := _label_with_text(child, text)
		if label != null:
			return label
	return null


func _button_with_exact_text(node: Node, text: String) -> Button:
	if node is Button and str(node.text) == text:
		return node as Button
	for child in node.get_children():
		var button := _button_with_exact_text(child, text)
		if button != null:
			return button
	return null


func _level_button_for_number(level_number: int) -> Button:
	return _level_button_for_number_recursive(_main, level_number)


func _level_button_for_number_recursive(node: Node, level_number: int) -> Button:
	if node is Button and str((node as Button).text).begins_with("%02d  " % level_number):
		return node as Button
	for child in node.get_children():
		var button := _level_button_for_number_recursive(child, level_number)
		if button != null:
			return button
	return null


func _visible_button_texts() -> Array[String]:
	var texts: Array[String] = []
	_collect_button_texts(_main, texts)
	return texts


func _collect_button_texts(node: Node, texts: Array[String]) -> void:
	if node is Button:
		var text := str((node as Button).text)
		if not text.is_empty():
			texts.append(text)
	for child in node.get_children():
		_collect_button_texts(child, texts)


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


func _solution(level: Dictionary) -> Dictionary:
	return _dictionary_from(level.get("solution", {}))


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
