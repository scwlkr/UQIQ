extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_46_playtest_level_jump_profile.json"
const PLAYTEST_LEVEL_ENV := "UQIQ_PLAYTEST_LEVEL"

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

	await _verify_normal_launch()
	if _failed:
		return

	await _verify_debug_playtest_jump()
	if _failed:
		return

	print("Issue #46 playtest jump verification passed: normal launch stays on Level List, debug env opens Level 5 directly without changing unlock progression.")
	_cleanup()
	_remove_test_save()
	OS.set_environment(PLAYTEST_LEVEL_ENV, "")
	quit(0)


func _verify_normal_launch() -> void:
	OS.set_environment(PLAYTEST_LEVEL_ENV, "")
	_boot_main_scene()
	await process_frame
	_require(str(_main.get("_last_transition_name")) == "level_list", "Normal launch should start on Level List.")
	if _failed:
		return
	_require(not _profile.is_level_unlocked(5), "Clean normal profile should not unlock Level 5.")
	_require(_node_named(_main, "memory_tile_surface") == null, "Normal launch should not jump into Level 5 Memory Flash.")
	_cleanup()


func _verify_debug_playtest_jump() -> void:
	OS.set_environment(PLAYTEST_LEVEL_ENV, "5")
	_boot_main_scene()
	await process_frame

	var current_level: Dictionary = _main.get("_current_level")
	_require(int(current_level.get("level_number", 0)) == 5, "Debug playtest env should open Level 5 directly.")
	if _failed:
		return
	_require(_node_named(_main, "memory_tile_surface") != null, "Debug playtest Level 5 should render the target Memory Flash surface.")
	_require(not _profile.is_level_unlocked(5), "Debug playtest jump should not mutate normal unlock progression.")
	_cleanup()
	OS.set_environment(PLAYTEST_LEVEL_ENV, "")


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _node_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var match := _node_named(child, node_name)
		if match != null:
			return match
	return null


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	_failed = true
	_cleanup()
	_remove_test_save()
	OS.set_environment(PLAYTEST_LEVEL_ENV, "")
	quit(1)


func _cleanup() -> void:
	if _main != null:
		if _main.get_parent() != null:
			_main.get_parent().remove_child(_main)
		_main.queue_free()
		_main = null
	_profile = null


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
