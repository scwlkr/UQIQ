extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_48_debug_playtest_all_profile.json"
const PLAYTEST_LEVEL_ENV := "UQIQ_PLAYTEST_LEVEL"
const PLAYTEST_UNLOCK_ALL_ENV := "UQIQ_PLAYTEST_UNLOCK_ALL"

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

	await _verify_normal_launch_keeps_later_levels_locked()
	if _failed:
		return

	await _verify_debug_unlock_all()
	if _failed:
		return

	await _verify_direct_level_jump_still_wins()
	if _failed:
		return

	print("Issue #48 debug playtest-all verification passed: normal launch stays locked, debug unlock-all makes supported levels playable without mutating Local Profile, and direct level jump still works.")
	_cleanup()
	_remove_test_save()
	_clear_env()
	quit(0)


func _verify_normal_launch_keeps_later_levels_locked() -> void:
	_clear_env()
	_boot_main_scene()
	await process_frame

	var level_6 := _level_by_number(6)
	_require(str(_main.get("_last_transition_name")) == "level_list", "Normal launch should stay on Level List.")
	_require(not bool(_main.call("_is_level_playable", level_6)), "Normal clean profile should not make Level 6 playable.")
	_require(not _profile.is_level_unlocked(6), "Normal clean profile should not unlock Level 6.")
	_cleanup()


func _verify_debug_unlock_all() -> void:
	_clear_env()
	OS.set_environment(PLAYTEST_UNLOCK_ALL_ENV, "1")
	_boot_main_scene()
	await process_frame

	var level_6 := _level_by_number(6)
	_require(str(_main.get("_last_transition_name")) == "level_list", "Playtest unlock-all should still launch to Level List.")
	_require(bool(_main.call("_is_level_playable", level_6)), "Playtest unlock-all should make Level 6 playable.")
	_require(str(_main.call("_level_state_text", level_6)) == "playtest", "Playtest unlock-all should label normally locked supported levels as playtest.")
	_require(not _profile.is_level_unlocked(6), "Playtest unlock-all should not mutate normal unlock progression.")
	_require(int(_profile.data.get("unlocked_level", 0)) == 1, "Playtest unlock-all should leave Local Profile unlocked_level at 1.")
	_cleanup()


func _verify_direct_level_jump_still_wins() -> void:
	_clear_env()
	OS.set_environment(PLAYTEST_LEVEL_ENV, "3")
	_boot_main_scene()
	await process_frame

	var current_level: Dictionary = _main.get("_current_level")
	_require(int(current_level.get("level_number", 0)) == 3, "UQIQ_PLAYTEST_LEVEL should still open the requested level directly.")
	_require(not _profile.is_level_unlocked(3), "Direct playtest level jump should not mutate normal unlock progression.")
	_cleanup()


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	_failed = true
	_cleanup()
	_remove_test_save()
	_clear_env()
	quit(1)


func _cleanup() -> void:
	if _main != null:
		if _main.get_parent() != null:
			_main.get_parent().remove_child(_main)
		_main.queue_free()
		_main = null
	_profile = null


func _clear_env() -> void:
	OS.set_environment(PLAYTEST_LEVEL_ENV, "")
	OS.set_environment(PLAYTEST_UNLOCK_ALL_ENV, "")


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
