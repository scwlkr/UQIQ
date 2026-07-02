extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_51_scorecard_safe_area_profile.json"

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

	_verify_safe_area_margin_math()
	_complete_level_01_to_next_level()
	_complete_level_02_to_level_list()
	_assert_save_load_state()
	if _failed:
		return

	print("Issue #51 Score Roastcard verification passed: safe-area margins account for notched phones, Level 01 continues to Next Level, Level 02 returns to Level List, and score/profile persistence remains intact.")
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_require(_profile.load_or_create(), _profile.last_error)
	_main.set("_profile", _profile)
	_main.set("_pack", _pack_set)
	_main.set("_packs", _main.call("_pack_groups_from_pack_set", _pack_set))
	root.add_child(_main)
	_main.call("_setup_feedback")
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_safe_area_margin_math() -> void:
	var margins := _dictionary_from(_main.call(
		"_screen_margins_for_safe_area",
		Rect2i(0, 63, 1179, 2376),
		Vector2i(1179, 2556),
		Vector2(393, 852)
	))
	_require(int(margins.get("top", 0)) > 22, "Score Roastcard top margin should include notched-phone safe area.")
	_require(int(margins.get("bottom", 0)) > 22, "Score Roastcard bottom margin should include phone home-indicator safe area.")


func _complete_level_01_to_next_level() -> void:
	var level := _level_by_number(1)
	_complete_freehand_physics(level)
	_require(str(_main.get("_last_transition_name")) == "score_roastcard", "Level 01 should route to Score Roastcard.")
	_require(_screen_has_label_text("Score Roastcard"), "Level 01 Score Roastcard should render its title.")
	_require(_screen_has_button_text("Next Level"), "Level 01 Score Roastcard should expose a top-level Next Level action.")
	_require(_screen_has_button_text("Level List"), "Level 01 Score Roastcard should expose a Level List action.")
	_require(_button_min_height("Next Level") >= 58.0, "Next Level action should be touch-sized.")
	_press_button("Next Level")
	var current_level := _dictionary_from(_main.get("_current_level"))
	_require(int(current_level.get("level_number", 0)) == 2, "Next Level action should open Level 02 without debug entry.")


func _complete_level_02_to_level_list() -> void:
	var level := _level_by_number(2)
	_complete_freehand_physics(level)
	_require(str(_main.get("_last_transition_name")) == "score_roastcard", "Level 02 should route to Score Roastcard.")
	_require(_screen_has_button_text("Level List"), "Level 02 Score Roastcard should expose a Level List action.")
	_require(_button_min_height("Level List") >= 58.0, "Level List action should be touch-sized.")
	_press_button("Level List")
	_require(str(_main.get("_last_transition_name")) == "level_list", "Level List action should return to the Level List after a later Pack 1 completion.")


func _complete_freehand_physics(level: Dictionary) -> void:
	_main.call("_show_play_screen", level)
	_main.call("_handle_physics_draw", str(_solution(level).get("draw_id", "")))
	_main.call("_handle_physics_release")
	_assert_completion_persisted(level)


func _complete_drag_logic(level: Dictionary) -> void:
	var solution := _solution(level)
	_main.call("_handle_drag_select", str(solution.get("object_id", "")))
	_main.call("_handle_drag_drop", str(solution.get("drop_target_id", "")))
	_assert_completion_persisted(level)


func _assert_completion_persisted(level: Dictionary) -> void:
	var level_id := str(level.get("id", ""))
	_require(_profile.last_error.is_empty(), _profile.last_error)
	_require(_profile.is_level_completed(level_id), "Completion should persist for %s." % level_id)
	_require(not _profile.get_best_attempt(level_id).is_empty(), "Best Attempt should persist for %s." % level_id)
	_require(not _profile.get_score_result(level_id).is_empty(), "Score Roastcard result should persist for %s." % level_id)


func _assert_save_load_state() -> void:
	var reload := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(reload.load_or_create(), reload.last_error)
	for level_number in [1, 2]:
		var level := _level_by_number(level_number)
		var level_id := str(level.get("id", ""))
		_require(reload.is_level_completed(level_id), "Reload should preserve completion for %s." % level_id)
		_require(not reload.get_score_result(level_id).is_empty(), "Reload should preserve Score Roastcard result for %s." % level_id)
	_require(reload.current_uqiq_score() == _profile.current_uqiq_score(), "Reload should preserve UQIQ Score after Score Roastcard continuations.")


func _press_button(text: String) -> void:
	var button := _find_button(_main, text)
	_require(button != null, "Button should exist: %s" % text)
	if button == null:
		return
	button.pressed.emit()


func _button_min_height(text: String) -> float:
	var button := _find_button(_main, text)
	if button == null:
		return 0.0
	return button.custom_minimum_size.y


func _screen_has_button_text(text: String) -> bool:
	return _find_button(_main, text) != null


func _screen_has_label_text(text: String) -> bool:
	return _node_has_label_text(_main, text)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and str(node.text) == text:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


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


func _remove_test_save() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)


func _cleanup() -> void:
	_remove_test_save()


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	_failed = true
	push_error(message)
	_cleanup()
	quit(1)
