extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_21_judge_profile.json"

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
	_verify_judge_reactions_and_transitions()
	if _failed:
		return

	print("Issue #21 Judge Face verification passed: list/play/score transitions, start/fail/Roast/success/score reactions, replay, and Level List navigation remain non-blocking.")
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


func _verify_judge_reactions_and_transitions() -> void:
	var level := _level_by_number(1)
	_main.call("_show_level_list")
	_require(_transition_count("level_list") >= 1, "Level List should record a screen transition.")
	_require(_current_screen_root_is_visible(), "Headless transition hook should leave the current screen root fully visible.")
	_require(_judge_count("list") >= 1, "Level List should show neutral Judge Face state.")
	_require(_screen_has_label_text("watching quietly"), "Level List should render Judge Face caption.")

	_main.call("_show_play_screen", level)
	_require(_transition_count("play_screen") >= 1, "Play Screen should record a screen transition.")
	_require(_current_screen_root_is_visible(), "Headless Play Screen transition should not pause layout in a hidden state.")
	_require(_judge_count("start") >= 1, "Play Screen should show start Judge Face state.")
	_require(_screen_has_label_text("calibrating ego"), "Play Screen should render start Judge Face caption.")

	_main.call("_handle_tap_target", "wrong_target")
	_require(_judge_count("fail") >= 1, "Wrong action should set fail Judge Face state.")
	_require(_screen_has_label_text("incorrect aura detected"), "Fail Judge Face caption should render.")

	_main.call("_handle_roast_action")
	_require(_judge_count("roast") >= 1, "Roast action should set Roast Judge Face state.")
	_require(_screen_has_label_text("roast protocol armed"), "Roast Judge Face caption should render.")

	_main.call("_handle_tap_target", str(_solution(level).get("target_id", "")))
	_require(_judge_count("success") >= 1, "Completion should record success Judge Face state.")
	_require(_judge_count("score") >= 1, "Score Roastcard should set score Judge Face state.")
	_require(_transition_count("score_roastcard") >= 1, "Score Roastcard should record a screen transition.")
	_require(_screen_has_label_text("score tribunal convened"), "Score Roastcard should render score Judge Face caption.")
	_require(_profile.is_level_completed(str(level.get("id", ""))), "Judge Face transitions should not block Level completion.")

	_main.call("_show_play_screen", level)
	_require(_transition_count("play_screen") >= 2, "Replay should return to Play Screen through the transition hook.")
	_require(_judge_count("start") >= 2, "Replay should reset Judge Face to start state.")

	_main.call("_show_level_list")
	_require(_transition_count("level_list") >= 2, "Level List navigation should remain available after Score Roastcard.")
	_require(_screen_has_label_text("UQIQ"), "Level List should still render after transition hooks.")


func _transition_count(name: String) -> int:
	var counts := _dictionary_from(_main.get("_transition_counts"))
	return int(counts.get(name, 0))


func _judge_count(name: String) -> int:
	var counts := _dictionary_from(_main.get("_judge_state_counts"))
	return int(counts.get(name, 0))


func _current_screen_root_is_visible() -> bool:
	var root := _current_screen_root(_main)
	return root != null and is_equal_approx(root.modulate.a, 1.0)


func _current_screen_root(node: Node) -> Control:
	for child in node.get_children():
		if child is ColorRect:
			continue
		if child is VBoxContainer:
			return child as Control
		if child is ScrollContainer:
			return _first_vbox_descendant(child)
	return null


func _first_vbox_descendant(node: Node) -> Control:
	if node is VBoxContainer:
		return node as Control
	for child in node.get_children():
		var match := _first_vbox_descendant(child)
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
