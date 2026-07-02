extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_22_physics_draw_profile.json"

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
	_verify_physics_draw_feedback()
	if _failed:
		return

	print("Issue #22 Physics Draw verification passed: selected-line state, release result state, wrong release, correct release, action count, scoring, and persistence remain deterministic.")
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


func _verify_physics_draw_feedback() -> void:
	var level := _level_by_number(6)
	var level_id := str(level.get("id", ""))
	var solution := _solution(level)
	var correct_draw_id := str(solution.get("draw_id", ""))
	var wrong_draw_id := _wrong_draw_id(level, correct_draw_id)
	var wrong_label := _draw_label(level, wrong_draw_id)
	var correct_label := _draw_label(level, correct_draw_id)

	_main.call("_show_play_screen", level)
	_require(_screen_has_label_text("BALL -> selected line -> CUP"), "Physics Draw should show the deterministic play surface.")
	_require(_screen_has_label_text("Selected line: none"), "Physics Draw should start with no selected line.")
	_require(_screen_has_label_text("Release result: waiting on fake gravity"), "Physics Draw should start with waiting release state.")

	_main.call("_handle_physics_draw", wrong_draw_id)
	_require(_screen_has_label_text("Selected line: %s" % wrong_label), "Physics Draw should show the selected wrong line label.")
	_require(_screen_has_label_text("Release result: ready to test"), "Physics Draw should show ready state after selecting a line.")
	_require(str(_main.get("_last_physics_result")) == "selected", "Physics Draw should record selected state before release.")

	_main.call("_handle_physics_release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Wrong Physics Draw release should record fail state.")
	_require(_screen_has_label_text("Release result: fake gravity rejected %s" % wrong_label), "Wrong release should show deterministic failure state.")
	_require(not _profile.is_level_completed(level_id), "Wrong Physics Draw release should not complete the Level.")
	_require(int(_main.get("_tap_count")) == 2, "Wrong draw plus release should count exactly two actions.")

	_main.call("_show_play_screen", level)
	_main.call("_handle_physics_draw", correct_draw_id)
	_require(_screen_has_label_text("Selected line: %s" % correct_label), "Physics Draw should show the selected correct line label.")
	_main.call("_handle_physics_release")
	_require(str(_main.get("_last_physics_result")) == "success", "Correct Physics Draw release should record success state.")
	_require(_profile.is_level_completed(level_id), "Correct Physics Draw release should complete the Level.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct Physics Draw release should route to Score Roastcard.")

	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 2, "Correct draw plus release should persist exactly two actions.")
	_require(not _profile.get_score_result(level_id).is_empty(), "Physics Draw completion should still persist score result.")


func _wrong_draw_id(level: Dictionary, correct_draw_id: String) -> String:
	var options = _rules(level).get("draw_options", [])
	if typeof(options) == TYPE_ARRAY:
		for option in options:
			if typeof(option) == TYPE_DICTIONARY:
				var draw_id := str(option.get("id", ""))
				if not draw_id.is_empty() and draw_id != correct_draw_id:
					return draw_id
	_require(false, "Physics Draw Level should include at least one wrong draw option.")
	return ""


func _draw_label(level: Dictionary, draw_id: String) -> String:
	var options = _rules(level).get("draw_options", [])
	if typeof(options) == TYPE_ARRAY:
		for option in options:
			if typeof(option) == TYPE_DICTIONARY and str(option.get("id", "")) == draw_id:
				return str(option.get("label", draw_id))
	return draw_id


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


func _rules(level: Dictionary) -> Dictionary:
	return _dictionary_from(level.get("rules", {}))


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
