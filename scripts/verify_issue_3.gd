extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const TEST_SAVE_PATH := "user://issue_3_profile_verify.json"


func _initialize() -> void:
	_remove_test_save()

	var loader := LevelLoaderScript.new()
	var pack := loader.load_pack()
	_require(not pack.is_empty(), loader.last_error)

	var level := loader.find_level_by_number(pack, 1)
	_require(not level.is_empty(), "Level 1 was not found.")
	var level_id := str(level.get("id", ""))

	var profile := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(profile.load_or_create(), profile.last_error)
	_require(profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "New profile should start with 3 Dur Tokens.")
	_require(profile.current_uqiq_score() == LocalProfileScript.DEFAULT_UQIQ_SCORE, "New profile should start at UQIQ 100.")
	_require(profile.can_spend_dur_token(level), "Unlocked incomplete Level 1 should allow DUR spend.")

	_require(profile.spend_dur_token(level), profile.last_error)
	_require(profile.is_level_durd(level_id), "DUR spend should mark Level 1 as DUR'D.")
	_require(profile.dur_tokens() == 2, "DUR spend should decrement Dur Tokens.")
	_require(profile.is_level_unlocked(2), "DUR spend should unlock the next Level.")

	var spent_reload := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(spent_reload.load_or_create(), spent_reload.last_error)
	_require(spent_reload.is_level_durd(level_id), "Reload should keep Level 1 DUR'D.")
	_require(spent_reload.dur_tokens() == 2, "Reload should keep spent Dur Token count.")

	var best := spent_reload.record_completed_attempt(level, 1, 1)
	_require(spent_reload.last_error.is_empty(), spent_reload.last_error)
	_require(int(best.get("action_count", 0)) == 1, "Best attempt should record action count.")
	_require(int(best.get("roast_count", 0)) == 1, "Best attempt should record Roast usage.")
	_require(bool(best.get("roast_used", false)), "Best attempt should mark Roast usage.")
	_require(bool(best.get("durd_at_start", false)), "Attempt should record DUR'D context.")
	_require(bool(best.get("dur_token_recovered", false)), "Completing a DUR'D Level should record recovery.")
	_require(not spent_reload.is_level_durd(level_id), "Completing a DUR'D Level should clear DUR'D state.")
	_require(spent_reload.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "DUR'D recovery should restore one Dur Token up to cap.")
	_require(spent_reload.current_uqiq_score() != LocalProfileScript.DEFAULT_UQIQ_SCORE, "Completion should change UQIQ Score.")

	var score_result := spent_reload.get_score_result(level_id)
	_require(not score_result.is_empty(), "Score result should persist for the completed Level.")
	_require(int(score_result.get("action_count", 0)) == 1, "Score result should keep action count input.")
	_require(int(score_result.get("roast_count", 0)) == 1, "Score result should keep Roast input.")
	_require(bool(score_result.get("durd_at_start", false)), "Score result should keep DUR'D input.")
	var score_after := spent_reload.current_uqiq_score()
	_require(int(score_result.get("score_after", 0)) == score_after, "Score result should keep score output.")

	var final_reload := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(final_reload.load_or_create(), final_reload.last_error)
	_require(final_reload.current_uqiq_score() == score_after, "Reload should keep changed UQIQ Score.")
	_require(final_reload.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "Reload should keep recovered Dur Token count.")
	var reloaded_score := final_reload.get_score_result(level_id)
	_require(int(reloaded_score.get("score_after", 0)) == score_after, "Reload should keep score result output.")
	var reloaded_best := final_reload.get_best_attempt(level_id)
	_require(int(reloaded_best.get("roast_count", 0)) == 1, "Reload should keep Roast usage in attempt metrics.")

	print("Issue #3 verification passed: DUR spend/recover, UQIQ Score persistence, and Roast usage metrics.")
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
