extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const TEST_SAVE_PATH := "user://issue_2_profile_verify.json"


func _initialize() -> void:
	_remove_test_save()

	var loader := LevelLoaderScript.new()
	var pack := loader.load_pack()
	_require(not pack.is_empty(), loader.last_error)

	var level := loader.find_level_by_number(pack, 1)
	_require(not level.is_empty(), "Level 1 was not found.")

	var first_profile := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(first_profile.load_or_create(), first_profile.last_error)
	_require(first_profile.is_level_unlocked(1), "Level 1 should be unlocked by default.")
	_require(not first_profile.is_level_unlocked(2), "Level 2 should start locked.")

	var first_best := first_profile.record_completed_attempt(level, 3)
	_require(first_profile.last_error.is_empty(), first_profile.last_error)
	_require(first_profile.is_level_completed(str(level.get("id", ""))), "Level 1 should be completed.")
	_require(first_profile.is_level_unlocked(2), "Level 2 should unlock after Level 1 completion.")
	_require(int(first_best.get("action_count", 0)) == 3, "First best attempt should save 3 actions.")

	var reloaded_profile := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(reloaded_profile.load_or_create(), reloaded_profile.last_error)
	_require(reloaded_profile.is_level_completed(str(level.get("id", ""))), "Reload should keep Level 1 completion.")
	_require(reloaded_profile.is_level_unlocked(2), "Reload should keep Level 2 unlocked.")

	var worse_best := reloaded_profile.record_completed_attempt(level, 5)
	_require(reloaded_profile.last_error.is_empty(), reloaded_profile.last_error)
	_require(int(worse_best.get("action_count", 0)) == 3, "Worse replay should keep the existing best attempt.")

	var better_best := reloaded_profile.record_completed_attempt(level, 1)
	_require(reloaded_profile.last_error.is_empty(), reloaded_profile.last_error)
	_require(int(better_best.get("action_count", 0)) == 1, "Better replay should improve the best attempt.")
	_require(int(reloaded_profile.data.get("unlocked_level", 0)) == 2, "Replay should not corrupt unlock order.")

	var final_reload := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(final_reload.load_or_create(), final_reload.last_error)
	var final_best := final_reload.get_best_attempt(str(level.get("id", "")))
	_require(int(final_best.get("action_count", 0)) == 1, "Final reload should keep improved best attempt.")

	print("Issue #2 Local Profile verification passed: create, complete Level 1, reload, worse replay kept, better replay improved, Level 2 stayed unlocked.")
	_remove_test_save()
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	_remove_test_save()
	quit(1)


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
