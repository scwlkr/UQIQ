extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const TEST_SAVE_PATH := "user://issue_4_profile_verify.json"
const REQUIRED_TEMPLATES := [
	"Physics Draw",
	"Physics Draw",
	"Text Trap",
	"Pattern Grid",
	"Memory Flash",
	"Physics Draw",
]


func _initialize() -> void:
	_remove_test_save()

	var loader := LevelLoaderScript.new()
	var pack := loader.load_pack()
	_require(not pack.is_empty(), loader.last_error)

	var levels: Array[Dictionary] = []
	for level_number in range(1, 7):
		var level := loader.find_level_by_number(pack, level_number)
		_require(not level.is_empty(), "Level %d was not found." % level_number)
		levels.append(level)

	_require(_templates_match_vertical_slice(levels), "Levels 1-6 should match the current playable Pack 1 prototype templates.")
	for level in levels:
		_require(_level_has_template_solution(level), "Level %d has incomplete template rules." % int(level.get("level_number", 0)))
		_require(_level_has_roasts(level), "Level %d should have all Roast buckets." % int(level.get("level_number", 0)))

	var profile := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(profile.load_or_create(), profile.last_error)
	_require(profile.current_uqiq_score() == LocalProfileScript.DEFAULT_UQIQ_SCORE, "New profile should start at UQIQ 100.")
	_require(profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "New profile should start with 3 Dur Tokens.")
	_require(profile.is_level_unlocked(1), "Level 1 should start unlocked.")

	var score_before := profile.current_uqiq_score()
	_complete_and_assert(profile, levels[0], 2, 1, score_before)
	_require(profile.is_level_unlocked(2), "Completing Level 1 should unlock Level 2.")

	score_before = profile.current_uqiq_score()
	_complete_and_assert(profile, levels[1], 2, 1, score_before)
	_require(profile.is_level_unlocked(3), "Completing Level 2 should unlock Level 3.")

	var level_3_id := str(levels[2].get("id", ""))
	_require(profile.can_spend_dur_token(levels[2]), "Unlocked incomplete Level 3 should allow DUR spend.")
	_require(profile.spend_dur_token(levels[2]), profile.last_error)
	_require(profile.is_level_durd(level_3_id), "DUR spend should mark Level 3 as DUR'D.")
	_require(profile.dur_tokens() == 2, "DUR spend should decrement Dur Tokens.")
	_require(profile.is_level_unlocked(4), "DUR spend should unlock Level 4.")

	score_before = profile.current_uqiq_score()
	_complete_and_assert(profile, levels[2], 1, 1, score_before)
	_require(not profile.is_level_durd(level_3_id), "Completing a DUR'D Level should clear DUR'D state.")
	_require(profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "DUR'D completion should recover one Dur Token.")

	score_before = profile.current_uqiq_score()
	_complete_and_assert(profile, levels[3], 2, 1, score_before)
	_require(profile.is_level_unlocked(5), "Completing Level 4 should unlock Level 5.")

	score_before = profile.current_uqiq_score()
	_complete_and_assert(profile, levels[4], 5, 1, score_before)
	_require(profile.is_level_unlocked(6), "Completing Level 5 should unlock Level 6.")

	score_before = profile.current_uqiq_score()
	_complete_and_assert(profile, levels[5], 2, 1, score_before)
	_require(profile.is_level_unlocked(7), "Completing Level 6 should unlock Level 7.")

	var final_score := profile.current_uqiq_score()
	var final_tokens := profile.dur_tokens()
	var reload := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(reload.load_or_create(), reload.last_error)
	_require(reload.current_uqiq_score() == final_score, "Reload should preserve changed UQIQ Score.")
	_require(reload.dur_tokens() == final_tokens, "Reload should preserve Dur Token count.")
	_require(int(reload.data.get("unlocked_level", 0)) == 7, "Reload should preserve progress through completed Level 6.")
	for level in levels:
		var level_id := str(level.get("id", ""))
		_require(reload.is_level_completed(level_id), "Reload should preserve completion for %s." % level_id)
		var best := reload.get_best_attempt(level_id)
		_require(int(best.get("roast_count", 0)) == 1, "Reload should preserve Roast usage for %s." % level_id)
		_require(not reload.get_score_result(level_id).is_empty(), "Reload should preserve score result for %s." % level_id)

	print("Issue #4 verification passed: six Level Specs, six completions, Roast metrics, DUR spend/recovery, score persistence, and save/load.")
	_remove_test_save()
	quit(0)


func _complete_and_assert(profile: RefCounted, level: Dictionary, action_count: int, roast_count: int, score_before: int) -> void:
	var level_id := str(level.get("id", ""))
	var best: Dictionary = profile.record_completed_attempt(level, action_count, roast_count)
	_require(profile.last_error.is_empty(), profile.last_error)
	_require(profile.is_level_completed(level_id), "Completion should persist for %s." % level_id)
	_require(not best.is_empty(), "Best attempt should persist for %s." % level_id)
	_require(int(best.get("action_count", 0)) == action_count, "Best attempt should record action count for %s." % level_id)
	_require(int(best.get("roast_count", 0)) == roast_count, "Best attempt should record Roast count for %s." % level_id)
	_require(bool(best.get("roast_used", false)), "Best attempt should mark Roast usage for %s." % level_id)

	var score_result: Dictionary = profile.get_score_result(level_id)
	_require(not score_result.is_empty(), "Score result should persist for %s." % level_id)
	_require(int(score_result.get("score_before", 0)) == score_before, "Score result should keep score_before for %s." % level_id)
	_require(int(score_result.get("score_after", score_before)) != score_before, "Completing %s should change UQIQ Score." % level_id)


func _templates_match_vertical_slice(levels: Array[Dictionary]) -> bool:
	if levels.size() != REQUIRED_TEMPLATES.size():
		return false

	for index in range(REQUIRED_TEMPLATES.size()):
		if str(levels[index].get("template", "")) != str(REQUIRED_TEMPLATES[index]):
			return false

	return true


func _level_has_template_solution(level: Dictionary) -> bool:
	var rules = level.get("rules", {})
	var solution = level.get("solution", {})
	if typeof(rules) != TYPE_DICTIONARY or typeof(solution) != TYPE_DICTIONARY:
		return false

	match str(level.get("template", "")):
		"Tap Logic":
			return _has_array(rules, "tap_targets") and not str(solution.get("target_id", "")).is_empty()
		"Drag Logic":
			return _has_array(rules, "draggable_objects") and _has_array(rules, "drop_targets") \
				and not str(solution.get("object_id", "")).is_empty() \
				and not str(solution.get("drop_target_id", "")).is_empty()
		"Text Trap":
			return _has_array(rules, "accepted_inputs") and not str(solution.get("answer", "")).is_empty()
		"Pattern Grid":
			return _has_array(rules, "cells") and not str(solution.get("cell_id", "")).is_empty()
		"Memory Flash":
			return _has_array(rules, "flash_items") and _has_array(rules, "choices") and _has_array(solution, "sequence")
		"Physics Draw":
			if str(rules.get("interaction_model", "")) == "freehand_physics_then_release":
				var moving_object := _dictionary_from(rules.get("moving_object", {}))
				var goal_zone := _dictionary_from(rules.get("goal_zone", {}))
				var draw_limit := _dictionary_from(rules.get("draw_limit", {}))
				return _has_array(moving_object, "start") \
					and _has_array(goal_zone, "rect") \
					and draw_limit.has("min_length_px") \
					and draw_limit.has("collision_thickness_px") \
					and not str(solution.get("success_condition", "")).is_empty()
			return _has_array(rules, "draw_options") and not str(solution.get("draw_id", "")).is_empty()

	return false


func _level_has_roasts(level: Dictionary) -> bool:
	var roasts = level.get("roasts", {})
	if typeof(roasts) != TYPE_DICTIONARY:
		return false

	return _has_array(roasts, "failure") and _has_array(roasts, "delay") and _has_array(roasts, "scorecard")


func _has_array(source: Dictionary, key: String) -> bool:
	var value = source.get(key, [])
	return typeof(value) == TYPE_ARRAY and not value.is_empty()


func _dictionary_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	_remove_test_save()
	quit(1)


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
