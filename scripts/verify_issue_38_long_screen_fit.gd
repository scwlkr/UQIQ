extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_38_long_screen_fit_profile.json"

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

	_verify_play_screen_scroll(41, "memory_tile_surface")
	_verify_play_screen_scroll(51, "physics_draw_surface")
	_verify_score_roastcard_scroll()
	if _failed:
		return

	print("Issue #38 long-screen fit verification passed: content-heavy play screens and Score Roastcard expose lower actions inside portrait scroll containers.")
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


func _verify_play_screen_scroll(level_number: int, required_node_name: String) -> void:
	_main.call("_show_play_screen", _level_by_number(level_number))
	_require(_scroll_has_node_named(_main, required_node_name), "Level %d play screen should expose %s inside a scroll container." % [level_number, required_node_name])
	_require(_scroll_has_button_text(_main, "Roast"), "Level %d play screen should expose Roast inside a scroll container." % level_number)


func _verify_score_roastcard_scroll() -> void:
	var level := _level_by_number(1)
	_main.call("_show_play_screen", level)
	_main.call("_handle_tap_target", str(_solution(level).get("target_id", "")))
	_require(_scroll_has_label_text(_main, "The correct answer is the button labeled WRONG."), "Score Roastcard should expose lower UQIQ Moment content inside a scroll container.")
	_require(_scroll_has_button_text(_main, "Level List"), "Score Roastcard should expose Level List action inside a scroll container.")


func _scroll_has_button_text(node: Node, text: String) -> bool:
	if node is ScrollContainer:
		return _node_has_button_text(node, text)
	for child in node.get_children():
		if _scroll_has_button_text(child, text):
			return true
	return false


func _scroll_has_label_text(node: Node, text: String) -> bool:
	if node is ScrollContainer:
		return _node_has_label_text(node, text)
	for child in node.get_children():
		if _scroll_has_label_text(child, text):
			return true
	return false


func _scroll_has_node_named(node: Node, node_name: String) -> bool:
	if node is ScrollContainer:
		return _node_named(node, node_name) != null
	for child in node.get_children():
		if _scroll_has_node_named(child, node_name):
			return true
	return false


func _node_has_button_text(node: Node, text: String) -> bool:
	if node is Button and str(node.text).contains(text):
		return true
	for child in node.get_children():
		if _node_has_button_text(child, text):
			return true
	return false


func _node_has_label_text(node: Node, text: String) -> bool:
	if node is Label and str(node.text).contains(text):
		return true
	for child in node.get_children():
		if _node_has_label_text(child, text):
			return true
	return false


func _node_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var match := _node_named(child, node_name)
		if match != null:
			return match
	return null


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


func _solution(level: Dictionary) -> Dictionary:
	var solution = level.get("solution", {})
	if typeof(solution) == TYPE_DICTIONARY:
		return solution
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
