extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_7_pack_1_smoke_profile.json"
const PACK_LEVEL_COUNT := 10
const SUPPORTED_TEMPLATES := [
	"Tap Logic",
	"Drag Logic",
	"Text Trap",
	"Pattern Grid",
	"Memory Flash",
	"Physics Draw",
	"Rearrange Level",
]

var _main: Control
var _profile: RefCounted
var _levels: Array[Dictionary] = []
var _completion_count := 0
var _replay_count := 0
var _scorecard_count := 0
var _save_load_count := 0
var _restart_count := 0
var _dur_spend_count := 0
var _dur_recovery_count := 0
var _failed := false


func _initialize() -> void:
	_remove_test_save()
	_boot_main_scene()
	if _failed:
		return
	_load_levels()
	if _failed:
		return
	_assert_pack_1_content_complete()
	if _failed:
		return
	_assert_clean_profile()
	if _failed:
		return

	_run_pack_1_completion_flow()
	if _failed:
		return
	_assert_save_load_state("Pack 1 completion")
	if _failed:
		return
	_run_level_10_replay_best_attempt_checks()
	if _failed:
		return
	_assert_save_load_state("Level 10 replay")
	if _failed:
		return
	_assert_restart_state()
	if _failed:
		return

	print("Issue #7 Pack 1 smoke passed: %d completions, %d replays, %d Score Roastcards, %d save/load checks, %d restart check(s), %d Dur spend(s), %d Dur recovery event(s)." % [
		_completion_count,
		_replay_count,
		_scorecard_count,
		_save_load_count,
		_restart_count,
		_dur_spend_count,
		_dur_recovery_count,
	])
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	if _main != null and is_instance_valid(_main):
		root.remove_child(_main)
		_main.free()

	_main = MainScene.instantiate() as Control
	if not _require(_main != null, "Main scene could not be instantiated."):
		return

	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	if not _require(_profile.load_or_create(), _profile.last_error):
		return
	if not _require(_profile.last_error.is_empty(), _profile.last_error):
		return


func _load_levels() -> void:
	var loader := LevelLoaderScript.new()
	var pack := loader.load_pack()
	if not _require(not pack.is_empty(), loader.last_error):
		return
	_main.set("_pack", pack)

	_levels = []
	for level_number in range(1, PACK_LEVEL_COUNT + 1):
		var level := loader.find_level_by_number(pack, level_number)
		if not _require(not level.is_empty(), "Level %d was not found." % level_number):
			return
		_levels.append(level)


func _assert_pack_1_content_complete() -> void:
	if not _require(_levels.size() == PACK_LEVEL_COUNT, "Pack 1 should contain exactly 10 Level Specs."):
		return

	for level in _levels:
		var level_number := int(level.get("level_number", 0))
		if not _require(str(level.get("pack_id", "")) == "pack_01_orientation_is_a_trap", "Level %d should belong to Pack 1." % level_number):
			return
		if not _require(SUPPORTED_TEMPLATES.has(str(level.get("template", ""))), "Level %d uses an unsupported template: %s." % [level_number, str(level.get("template", ""))]):
			return
		if not _require(str(level.get("completion_mode", "")) != "future_placeholder", "Level %d is still a future placeholder completion mode." % level_number):
			return

		var rules := _dictionary_from(level.get("rules", {}))
		if not _require(not bool(rules.get("future_placeholder", false)), "Level %d is still marked future_placeholder." % level_number):
			return
		if not _require(not _looks_like_placeholder(str(level.get("prompt", ""))), "Level %d still has placeholder prompt text." % level_number):
			return
		if not _require(not _looks_like_placeholder(str(level.get("uqiq_moment", ""))), "Level %d still has placeholder UQIQ Moment text." % level_number):
			return
		if not _require(_level_has_template_solution(level), "Level %d has incomplete template rules or solution fields." % level_number):
			return
		if not _require(_level_has_scoring(level), "Level %d should have speed/action thresholds and Roast penalty." % level_number):
			return
		if not _require(_level_has_roasts(level), "Level %d should have failure, delay, and Score Roastcard Roast buckets." % level_number):
			return


func _assert_clean_profile() -> void:
	if not _require(_profile.current_uqiq_score() == LocalProfileScript.DEFAULT_UQIQ_SCORE, "Clean Pack 1 smoke profile should start at UQIQ 100."):
		return
	if not _require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "Clean Pack 1 smoke profile should start with 3 Dur Tokens."):
		return
	if not _require(_profile.is_level_unlocked(1), "Level 1 should start unlocked."):
		return
	if not _require(not _profile.is_level_unlocked(2), "Level 2 should start locked on a clean profile."):
		return


func _run_pack_1_completion_flow() -> void:
	for index in range(_levels.size()):
		var level := _levels[index]
		var level_number := int(level.get("level_number", 0))

		if level_number == 7:
			_spend_dur_from_level_list(level)
			if _failed:
				return

		_start_level_from_list(level)
		if _failed:
			return
		var was_durd: bool = _profile.is_level_durd(str(level.get("id", "")))
		_complete_with_scorecard(level, true, false, was_durd)
		if _failed:
			return

		if level_number < PACK_LEVEL_COUNT:
			if not _require(_profile.is_level_unlocked(level_number + 1), "Completing Level %d should unlock Level %d." % [level_number, level_number + 1]):
				return

	_assert_pack_1_profile_state("Pack 1 completion")
	if _failed:
		return
	if not _require(int(_profile.data.get("unlocked_level", 0)) >= 11, "Completing Pack 1 should advance Local Profile beyond Level 10."):
		return


func _run_level_10_replay_best_attempt_checks() -> void:
	var level := _levels[PACK_LEVEL_COUNT - 1]
	var level_id := str(level.get("id", ""))

	var first_best: Dictionary = _profile.get_best_attempt(level_id)
	if not _require(not first_best.is_empty(), "Level 10 should have a Best Attempt before replay."):
		return
	if not _require(int(first_best.get("roast_count", -1)) > 0, "Initial Level 10 completion should include Roast usage so replay can improve it."):
		return

	_start_level_from_list(level)
	if _failed:
		return
	_complete_with_scorecard(level, false, true, false)
	if _failed:
		return
	var better_best: Dictionary = _profile.get_best_attempt(level_id)
	if not _require(int(better_best.get("roast_count", -1)) == 0, "Better Level 10 replay should improve Best Attempt Roast count."):
		return
	if not _require(int(better_best.get("action_count", 9999)) <= int(first_best.get("action_count", 9999)), "Better Level 10 replay should keep or improve Best Attempt action count."):
		return

	_start_level_from_list(level)
	if _failed:
		return
	_use_roast()
	if _failed:
		return
	_use_roast()
	if _failed:
		return
	_complete_with_scorecard(level, false, true, false)
	if _failed:
		return
	var kept_best: Dictionary = _profile.get_best_attempt(level_id)
	if not _require(int(kept_best.get("roast_count", -1)) == 0, "Worse Level 10 replay should keep the improved Best Attempt Roast count."):
		return
	if not _require(int(kept_best.get("action_count", 9999)) == int(better_best.get("action_count", 9999)), "Worse Level 10 replay should keep the improved Best Attempt action count."):
		return


func _spend_dur_from_level_list(level: Dictionary) -> void:
	var level_number := int(level.get("level_number", 0))
	var level_id := str(level.get("id", ""))
	if not _require(level_number > 6, "Issue #7 Dur Token check should happen after Level 6."):
		return
	if not _require(_profile.is_level_unlocked(level_number), "Level %d should be unlocked before Dur Token spend." % level_number):
		return
	if not _require(_profile.can_spend_dur_token(level), "Level %d should allow Dur Token spend." % level_number):
		return

	_main.call("_show_level_list")
	var row := _find_level_row(level_number)
	if not _require(row != null, "Level List should render Level %d before Dur Token spend." % level_number):
		return
	var dur_button := _find_dur_button(row)
	if not _require(dur_button != null, "Level List should render a DUR button for Level %d." % level_number):
		return
	if not _require(not dur_button.disabled, "Level List should allow Dur Token spend on unlocked incomplete Level %d." % level_number):
		return

	var tokens_before: int = _profile.dur_tokens()
	dur_button.emit_signal("pressed")
	if not _require(_profile.is_level_durd(level_id), "Dur Token spend should mark Level %d DUR'D." % level_number):
		return
	if not _require(_profile.dur_tokens() == tokens_before - 1, "Dur Token spend should decrement Dur Tokens for Level %d." % level_number):
		return
	if not _require(_profile.is_level_unlocked(level_number + 1), "Dur Token spend should unlock Level %d." % (level_number + 1)):
		return
	_dur_spend_count += 1


func _start_level_from_list(level: Dictionary) -> void:
	var level_number := int(level.get("level_number", 0))
	if not _require(_profile.is_level_unlocked(level_number), "Level %d should be unlocked before play." % level_number):
		return

	_main.call("_show_level_list")
	var button := _find_level_button(level_number)
	if not _require(button != null, "Level List should render a button for Level %d." % level_number):
		return
	if not _require(not button.disabled, "Level List should allow Level %d to open when unlocked." % level_number):
		return

	button.emit_signal("pressed")
	var current_level := _dictionary_from(_main.get("_current_level"))
	if not _require(str(current_level.get("id", "")) == str(level.get("id", "")), "Play Screen should hold Level %d after Level List selection." % level_number):
		return


func _complete_with_scorecard(level: Dictionary, use_roast: bool, replay: bool, was_durd: bool) -> void:
	var level_id := str(level.get("id", ""))
	var score_before: int = _profile.current_uqiq_score()
	var tokens_before: int = _profile.dur_tokens()

	if use_roast:
		_use_roast()
		if _failed:
			return

	_complete_level_by_template(level)
	if _failed:
		return
	_completion_count += 1
	if replay:
		_replay_count += 1

	if not _require(_profile.last_error.is_empty(), _profile.last_error):
		return
	if not _require(_profile.is_level_completed(level_id), "Completion should persist for %s." % level_id):
		return
	if not _require(not _profile.get_best_attempt(level_id).is_empty(), "Best Attempt should exist for %s." % level_id):
		return

	var score_result: Dictionary = _profile.get_score_result(level_id)
	if not _require(not score_result.is_empty(), "Score result should persist for %s." % level_id):
		return
	if not _require(int(score_result.get("score_before", score_before)) == score_before, "Score result should preserve score_before for %s." % level_id):
		return
	if not _require(int(score_result.get("score_after", score_before)) != score_before, "Completing %s should change UQIQ Score." % level_id):
		return
	if not _require(not _dictionary_from(_main.get("_last_score_result")).is_empty(), "Main scene should keep the last Score Roastcard result for %s." % level_id):
		return
	_assert_scorecard_screen(level)
	if _failed:
		return
	_scorecard_count += 1

	if was_durd:
		var completed_attempt := _dictionary_from(_main.get("_last_completed_attempt"))
		if not _require(bool(completed_attempt.get("dur_token_recovered", false)), "Completing DUR'D %s should record Dur Token recovery." % level_id):
			return
		if not _require(not _profile.is_level_durd(level_id), "Completing DUR'D %s should clear DUR'D state." % level_id):
			return
		if not _require(_profile.dur_tokens() == min(tokens_before + 1, LocalProfileScript.MAX_DUR_TOKENS), "Completing DUR'D %s should recover one Dur Token." % level_id):
			return
		_dur_recovery_count += 1


func _complete_level_by_template(level: Dictionary) -> void:
	match str(level.get("template", "")):
		"Tap Logic":
			_main.call("_handle_tap_target", str(_solution(level).get("target_id", "")))
		"Drag Logic":
			_main.call("_handle_drag_select", str(_solution(level).get("object_id", "")))
			_main.call("_handle_drag_drop", str(_solution(level).get("drop_target_id", "")))
		"Text Trap":
			var answer := str(_solution(level).get("answer", ""))
			if bool(_main.call("_uses_direct_text_tiles")):
				_main.call("_handle_direct_text_tile_choice", answer, answer, null)
				return
			var text_input := _main.get("_text_input") as LineEdit
			if not _require(text_input != null, "Text Trap should have an input before submit."):
				return
			text_input.text = answer
			_main.call("_handle_text_submit")
		"Rearrange Level":
			_main.call("_set_rearrange_cup_center", Vector2(225, 243))
			_main.call("_finish_rearrange_drag")
			_main.call("_handle_rearrange_release")
		"Pattern Grid":
			_main.call("_handle_pattern_cell", str(_solution(level).get("cell_id", "")))
			_main.call("_handle_pattern_submit")
		"Memory Flash":
			_main.call("_handle_memory_flash", true)
			_main.call("_handle_memory_flash", false)
			var sequence = _solution(level).get("sequence", [])
			if not _require(typeof(sequence) == TYPE_ARRAY, "Memory Flash should have a solution sequence."):
				return
			for item in sequence:
				_main.call("_handle_memory_choice", str(item))
			_main.call("_handle_memory_submit")
		"Physics Draw":
			_main.call("_handle_physics_draw", str(_solution(level).get("draw_id", "")))
			_main.call("_handle_physics_release")
		_:
			if not _require(false, "Unsupported Level Template in Pack 1 smoke: %s" % str(level.get("template", ""))):
				return


func _use_roast() -> void:
	var roasts_before := int(_main.get("_roast_count"))
	_main.call("_handle_roast_action")
	if not _require(int(_main.get("_roast_count")) == roasts_before + 1, "Roast action should increment Roast count."):
		return


func _assert_scorecard_screen(level: Dictionary) -> void:
	if not _require(_screen_has_label_text("Score Roastcard"), "Completing Level %d should show the Score Roastcard screen." % int(level.get("level_number", 0))):
		return
	if not _require(_screen_has_label_text(str(level.get("title", ""))), "Score Roastcard should include Level %d title." % int(level.get("level_number", 0))):
		return
	if not _require(_screen_has_label_text(str(level.get("uqiq_moment", ""))), "Score Roastcard should include Level %d UQIQ Moment." % int(level.get("level_number", 0))):
		return


func _assert_save_load_state(context: String) -> void:
	var reload := LocalProfileScript.new(TEST_SAVE_PATH)
	if not _require(reload.load_or_create(), reload.last_error):
		return
	_save_load_count += 1

	if not _require(reload.dur_tokens() == _profile.dur_tokens(), "Reload should preserve Dur Token count after %s." % context):
		return
	if not _require(reload.current_uqiq_score() == _profile.current_uqiq_score(), "Reload should preserve UQIQ Score after %s." % context):
		return
	if not _require(int(reload.data.get("unlocked_level", 0)) == int(_profile.data.get("unlocked_level", 0)), "Reload should preserve unlocked Level after %s." % context):
		return
	for level in _levels:
		var level_id := str(level.get("id", ""))
		if not _require(reload.is_level_completed(level_id), "Reload should preserve completion for %s after %s." % [level_id, context]):
			return
		if not _require(not reload.get_best_attempt(level_id).is_empty(), "Reload should preserve Best Attempt for %s after %s." % [level_id, context]):
			return
		if not _require(not reload.get_score_result(level_id).is_empty(), "Reload should preserve Score Roastcard result for %s after %s." % [level_id, context]):
			return


func _assert_restart_state() -> void:
	var expected_score: int = _profile.current_uqiq_score()
	var expected_tokens: int = _profile.dur_tokens()
	var expected_unlocked := int(_profile.data.get("unlocked_level", 0))
	_boot_main_scene()
	if _failed:
		return
	_restart_count += 1

	if not _require(_profile.current_uqiq_score() == expected_score, "App restart should preserve UQIQ Score."):
		return
	if not _require(_profile.dur_tokens() == expected_tokens, "App restart should preserve Dur Tokens."):
		return
	if not _require(int(_profile.data.get("unlocked_level", 0)) == expected_unlocked, "App restart should preserve Pack 1 unlock progress."):
		return
	_assert_pack_1_profile_state("app restart")


func _assert_pack_1_profile_state(context: String) -> void:
	for level in _levels:
		var level_id := str(level.get("id", ""))
		if not _require(_profile.is_level_completed(level_id), "%s should preserve completion for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_best_attempt(level_id).is_empty(), "%s should preserve Best Attempt for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_score_result(level_id).is_empty(), "%s should preserve score result for %s." % [context, level_id]):
			return
	if not _require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "%s should preserve recovered Dur Token state." % context):
		return


func _level_has_template_solution(level: Dictionary) -> bool:
	var rules := _dictionary_from(level.get("rules", {}))
	var solution := _solution(level)

	match str(level.get("template", "")):
		"Tap Logic":
			return _has_array(rules, "tap_targets") \
				and _has_nonempty_string(solution, "target_id") \
				and _array_has_id(rules.get("tap_targets", []), str(solution.get("target_id", "")))
		"Drag Logic":
			return _has_array(rules, "draggable_objects") \
				and _has_array(rules, "drop_targets") \
				and _has_nonempty_string(solution, "object_id") \
				and _has_nonempty_string(solution, "drop_target_id") \
				and _array_has_id(rules.get("draggable_objects", []), str(solution.get("object_id", ""))) \
				and _array_has_id(rules.get("drop_targets", []), str(solution.get("drop_target_id", "")))
		"Text Trap":
			return _has_array(rules, "accepted_inputs") \
				and _has_nonempty_string(solution, "answer")
		"Rearrange Level":
			var moving_object := _dictionary_from(rules.get("moving_object", {}))
			var target_placement := _dictionary_from(rules.get("target_placement", {}))
			return str(rules.get("interaction_model", "")) == "physics_linked_rearrange_then_release" \
				and _has_array(moving_object, "start") \
				and _has_array(rules, "built_in_geometry") \
				and _has_array(rules, "draggable_objects") \
				and _has_array(target_placement, "rect") \
				and _has_nonempty_string(solution, "success_condition")
		"Pattern Grid":
			return _has_array(rules, "cells") \
				and _has_nonempty_string(solution, "cell_id") \
				and _array_has_id(rules.get("cells", []), str(solution.get("cell_id", "")))
		"Memory Flash":
			return _has_array(rules, "flash_items") \
				and _has_array(rules, "choices") \
				and _has_array(solution, "sequence")
		"Physics Draw":
			if str(rules.get("interaction_model", "")) == "freehand_physics_then_release":
				var moving_object := _dictionary_from(rules.get("moving_object", {}))
				var goal_zone := _dictionary_from(rules.get("goal_zone", {}))
				var draw_limit := _dictionary_from(rules.get("draw_limit", {}))
				return _has_array(moving_object, "start") \
					and _has_array(goal_zone, "rect") \
					and draw_limit.has("min_length_px") \
					and draw_limit.has("collision_thickness_px") \
					and _has_nonempty_string(solution, "success_condition")
			return _has_array(rules, "draw_options") \
				and _has_nonempty_string(solution, "draw_id") \
				and _array_has_id(rules.get("draw_options", []), str(solution.get("draw_id", "")))

	return false


func _level_has_scoring(level: Dictionary) -> bool:
	var scoring := _dictionary_from(level.get("scoring", {}))
	var speed := _dictionary_from(scoring.get("speed_seconds", {}))
	var actions := _dictionary_from(scoring.get("action_count", {}))
	return speed.has("great") \
		and speed.has("ok") \
		and actions.has("great") \
		and actions.has("ok") \
		and scoring.has("roast_penalty")


func _level_has_roasts(level: Dictionary) -> bool:
	var roasts := _dictionary_from(level.get("roasts", {}))
	return _has_nonplaceholder_array(roasts, "failure") \
		and _has_nonplaceholder_array(roasts, "delay") \
		and _has_nonplaceholder_array(roasts, "scorecard")


func _has_array(source: Dictionary, key: String) -> bool:
	var value = source.get(key, [])
	return typeof(value) == TYPE_ARRAY and not value.is_empty()


func _has_nonplaceholder_array(source: Dictionary, key: String) -> bool:
	var value = source.get(key, [])
	if typeof(value) != TYPE_ARRAY or value.is_empty():
		return false

	for item in value:
		if _looks_like_placeholder(str(item)):
			return false

	return true


func _has_nonempty_string(source: Dictionary, key: String) -> bool:
	return not str(source.get(key, "")).strip_edges().is_empty()


func _array_has_id(value: Variant, id: String) -> bool:
	if typeof(value) != TYPE_ARRAY or id.is_empty():
		return false

	for item in value:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == id:
			return true

	return false


func _looks_like_placeholder(text: String) -> bool:
	var normalized := text.strip_edges().to_lower()
	return normalized.is_empty() \
		or normalized == "future pack 1 twist." \
		or normalized.begins_with("future ") \
		or normalized.contains("future_placeholder")


func _find_level_button(level_number: int) -> Button:
	var row := _find_level_row(level_number)
	if row == null:
		return null

	for child in row.get_children():
		if child is Button and str(child.text).begins_with("%02d  " % level_number):
			return child as Button

	return null


func _find_dur_button(row: Node) -> Button:
	for child in row.get_children():
		if child is Button and str(child.text) == "DUR":
			return child as Button

	return null


func _find_level_row(level_number: int) -> HBoxContainer:
	return _find_level_row_recursive(_main, level_number)


func _find_level_row_recursive(node: Node, level_number: int) -> HBoxContainer:
	if node is HBoxContainer:
		for child in node.get_children():
			if child is Button and str(child.text).begins_with("%02d  " % level_number):
				return node as HBoxContainer

	for child in node.get_children():
		var found := _find_level_row_recursive(child, level_number)
		if found != null:
			return found

	return null


func _screen_has_label_text(text: String) -> bool:
	return _screen_has_label_text_recursive(_main, text)


func _screen_has_label_text_recursive(node: Node, text: String) -> bool:
	if node is Label and str(node.text) == text:
		return true

	for child in node.get_children():
		if _screen_has_label_text_recursive(child, text):
			return true

	return false


func _solution(level: Dictionary) -> Dictionary:
	return _dictionary_from(level.get("solution", {}))


func _dictionary_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true

	if not _failed:
		push_error(message)
		_failed = true
		_remove_test_save()
		quit(1)
	return false


func _cleanup() -> void:
	if _main != null and is_instance_valid(_main):
		root.remove_child(_main)
		_main.free()
	_main = null
	_remove_test_save()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
