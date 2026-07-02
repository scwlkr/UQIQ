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
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_main_flow_text_controls() -> void:
	_main.call("_show_level_list")
	_assert_text_controls("Level List")

	_main.call("_show_play_screen", _level_by_number(41))
	_assert_text_controls("Memory Flash Play Screen")

	_main.call("_show_play_screen", _level_by_number(51))
	_assert_text_controls("Physics Draw Play Screen")

	var level := _level_by_number(1)
	_main.call("_show_play_screen", level)
	_main.call("_handle_tap_target", str(_solution(level).get("target_id", "")))
	_require(_screen_has_label_text("Score Roastcard"), "Score Roastcard should render for readability sweep.")
	_assert_text_controls("Score Roastcard")


func _assert_text_controls(context: String) -> void:
	_collect_text_controls(_main, context)


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
