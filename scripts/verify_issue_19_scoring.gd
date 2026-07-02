extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_19_scoring_profile.json"
const TEST_DUR_SAVE_PATH := "user://issue_19_scoring_dur_profile.json"
const TEST_UI_SAVE_PATH := "user://issue_19_scoring_ui_profile.json"

var _loader := LevelLoaderScript.new()
var _pack_set := {}
var _main: Control
var _profile: RefCounted


func _initialize() -> void:
	_remove_test_save(TEST_SAVE_PATH)
	_remove_test_save(TEST_DUR_SAVE_PATH)
	_remove_test_save(TEST_UI_SAVE_PATH)

	_pack_set = _loader.load_default_packs()
	_require(not _pack_set.is_empty(), _loader.last_error)

	_verify_pack_representative_scoring()
	_verify_dur_recovery_and_score_caps()
	_verify_score_roastcard_rows()

	print("Issue #19 scoring verification passed: Pack 1-6 representative formula checks, score clamps, DUR recovery scoring, Best Attempt replay ranking, and Score Roastcard delta rows.")
	_cleanup()
	quit(0)


func _verify_pack_representative_scoring() -> void:
	var profile := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(profile.load_or_create(), profile.last_error)

	var level_numbers := [1, 11, 21, 31, 41, 51]
	for index in range(level_numbers.size()):
		var level := _level_by_number(int(level_numbers[index]))
		var scoring := _scoring(level)
		var speed := _dictionary_from(scoring.get("speed_seconds", {}))
		var actions := _dictionary_from(scoring.get("action_count", {}))
		var great_seconds := float(speed.get("great", 1.0))
		var ok_seconds := float(speed.get("ok", great_seconds))
		var great_actions := int(actions.get("great", 1))
		var ok_actions := int(actions.get("ok", great_actions))

		var elapsed_seconds := great_seconds
		var action_count := great_actions
		var roast_count := 0
		match index % 3:
			1:
				elapsed_seconds = (great_seconds + ok_seconds) / 2.0
				action_count = ok_actions
				roast_count = 1
			2:
				elapsed_seconds = ok_seconds + 5.0
				action_count = ok_actions + 2
				roast_count = 2

		var score_before: int = profile.current_uqiq_score()
		var best: Dictionary = profile.record_completed_attempt(level, action_count, roast_count, elapsed_seconds)
		_require(profile.last_error.is_empty(), profile.last_error)
		_require(not best.is_empty(), "Best Attempt should persist for Level %d." % int(level.get("level_number", 0)))
		_assert_score_result(level, profile.last_score_result, score_before, action_count, roast_count, elapsed_seconds, false, 0)


func _verify_dur_recovery_and_score_caps() -> void:
	var profile := LocalProfileScript.new(TEST_DUR_SAVE_PATH)
	_require(profile.load_or_create(), profile.last_error)

	var level := _level_by_number(1)
	var level_id := str(level.get("id", ""))
	_require(profile.spend_dur_token(level), profile.last_error)
	_require(profile.is_level_durd(level_id), "DUR spend should mark Level 1 DUR'D before scoring.")
	_require(profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS - 1, "DUR spend should decrement token count before completion.")

	var score_before: int = profile.current_uqiq_score()
	profile.record_completed_attempt(level, 1, 0, 1.0)
	_require(profile.last_error.is_empty(), profile.last_error)
	_assert_score_result(level, profile.last_score_result, score_before, 1, 0, 1.0, true, 1)
	_require(not profile.is_level_durd(level_id), "DUR'D completion should clear DUR state.")
	_require(profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "DUR'D completion should recover one Dur Token up to cap.")

	profile.data["uqiq_score"] = LocalProfileScript.MAX_UQIQ_SCORE - 1
	var upper_before: int = profile.current_uqiq_score()
	profile.record_completed_attempt(_level_by_number(11), 1, 0, 1.0)
	_require(int(profile.last_score_result.get("score_after", 0)) == LocalProfileScript.MAX_UQIQ_SCORE, "Score should clamp at UQIQ 420.")
	_require(int(profile.last_score_result.get("score_delta", 0)) == LocalProfileScript.MAX_UQIQ_SCORE - upper_before, "Score delta should reflect upper visible clamp.")
	_require(int(profile.last_score_result.get("attempt_score_delta", 0)) > int(profile.last_score_result.get("score_delta", 0)), "Attempt delta should preserve uncapped replay value.")

	profile.data["uqiq_score"] = LocalProfileScript.MIN_UQIQ_SCORE + 1
	var lower_before: int = profile.current_uqiq_score()
	profile.record_completed_attempt(_level_by_number(21), 99, 5, 999.0)
	_require(int(profile.last_score_result.get("score_after", 0)) == LocalProfileScript.MIN_UQIQ_SCORE, "Score should clamp at UQIQ -20.")
	_require(int(profile.last_score_result.get("score_delta", 0)) == LocalProfileScript.MIN_UQIQ_SCORE - lower_before, "Score delta should reflect lower visible clamp.")
	_require(int(profile.last_score_result.get("attempt_score_delta", 0)) < int(profile.last_score_result.get("score_delta", 0)), "Attempt delta should preserve uncapped negative replay value.")

	var replay_level := _level_by_number(31)
	profile.data["uqiq_score"] = LocalProfileScript.MAX_UQIQ_SCORE
	profile.record_completed_attempt(replay_level, 8, 2, 40.0)
	var first_best := profile.get_best_attempt(str(replay_level.get("id", "")))
	profile.record_completed_attempt(replay_level, 2, 0, 1.0)
	var better_best := profile.get_best_attempt(str(replay_level.get("id", "")))
	_require(int(better_best.get("attempt_score_delta", -999)) > int(first_best.get("attempt_score_delta", -999)), "Best Attempt should improve by attempt delta even when UQIQ Score is capped.")
	_require(int(better_best.get("roast_count", -1)) == 0, "Improved capped replay should keep lower Roast count.")


func _verify_score_roastcard_rows() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_UI_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)

	var level := _level_by_number(1)
	_require(_profile.spend_dur_token(level), _profile.last_error)
	_main.call("_show_play_screen", level)
	_main.call("_handle_roast_action")
	_main.call("_handle_tap_target", str(_solution(level).get("target_id", "")))

	_require(_screen_has_label_text("Score Roastcard"), "Score Roastcard screen should render after completion.")
	_require(_screen_has_label_text("Score change:"), "Score Roastcard should show total score delta.")
	_require(_screen_has_label_text("Speed:"), "Score Roastcard should show Speed delta row.")
	_require(_screen_has_label_text("Actions:"), "Score Roastcard should show Actions delta row.")
	_require(_screen_has_label_text("Roasts:"), "Score Roastcard should show Roasts delta row.")
	_require(_screen_has_label_text("DUR:"), "Score Roastcard should show DUR context row after a DUR'D completion.")
	_require(_screen_has_label_text("Dignity tax"), "Score Roastcard should show absurd Roast flavor label.")
	_require(_screen_has_label_text("DUR parole"), "Score Roastcard should show absurd DUR flavor label.")

	var score_result := _dictionary_from(_main.get("_last_score_result"))
	_require(not score_result.is_empty(), "Main scene should keep the issue #19 score result.")
	var components := _dictionary_from(score_result.get("score_components", {}))
	for key in ["speed", "actions", "roasts", "dur"]:
		_require(components.has(key), "Score result should include %s component." % key)


func _assert_score_result(level: Dictionary, score_result: Dictionary, score_before: int, action_count: int, roast_count: int, elapsed_seconds: float, was_durd: bool, tokens_restored: int) -> void:
	_require(not score_result.is_empty(), "Score result should exist for Level %d." % int(level.get("level_number", 0)))

	var scoring := _scoring(level)
	var raw_delta := LocalProfileScript.COMPLETION_DELTA
	raw_delta += _expected_speed_delta(scoring, elapsed_seconds)
	raw_delta += _expected_action_delta(scoring, action_count)
	raw_delta -= roast_count * _roast_penalty(scoring)
	if was_durd:
		raw_delta += LocalProfileScript.DUR_RECOVERY_DELTA

	var expected_attempt_delta := clampi(raw_delta, LocalProfileScript.MIN_ATTEMPT_DELTA, LocalProfileScript.MAX_ATTEMPT_DELTA)
	var expected_score_after := clampi(score_before + expected_attempt_delta, LocalProfileScript.MIN_UQIQ_SCORE, LocalProfileScript.MAX_UQIQ_SCORE)
	var expected_score_delta := expected_score_after - score_before

	_require(int(score_result.get("score_before", 0)) == score_before, "Score result should preserve score_before.")
	_require(int(score_result.get("raw_score_delta", 999)) == raw_delta, "Score result should expose expected raw score delta.")
	_require(int(score_result.get("attempt_score_delta", 999)) == expected_attempt_delta, "Score result should expose expected attempt delta.")
	_require(int(score_result.get("score_delta", 999)) == expected_score_delta, "Score result should expose visible score delta.")
	_require(int(score_result.get("score_after", 0)) == expected_score_after, "Score result should preserve clamped score_after.")
	_require(int(score_result.get("action_count", 0)) == action_count, "Score result should preserve action count.")
	_require(int(score_result.get("roast_count", -1)) == roast_count, "Score result should preserve Roast count.")
	_require(is_equal_approx(float(score_result.get("elapsed_seconds", -1.0)), elapsed_seconds), "Score result should preserve elapsed seconds.")
	_require(bool(score_result.get("durd_at_start", false)) == was_durd, "Score result should preserve DUR'D context.")
	_require(int(score_result.get("dur_tokens_restored", 0)) == tokens_restored, "Score result should preserve Dur Token recovery count.")

	var components := _dictionary_from(score_result.get("score_components", {}))
	_require(_component_delta(components, "speed") == _expected_speed_delta(scoring, elapsed_seconds), "Speed component delta should match thresholds.")
	_require(_component_delta(components, "actions") == _expected_action_delta(scoring, action_count), "Action component delta should match thresholds.")
	_require(_component_delta(components, "roasts") == -roast_count * _roast_penalty(scoring), "Roast component delta should match penalty.")
	_require(_component_delta(components, "dur") == (LocalProfileScript.DUR_RECOVERY_DELTA if was_durd else 0), "DUR component delta should match recovery context.")
	for key in ["speed", "actions", "roasts"]:
		var component := _dictionary_from(components.get(key, {}))
		_require(not str(component.get("label", "")).is_empty(), "%s component should have a flavor label." % key)
		_require(not str(component.get("detail", "")).is_empty(), "%s component should have detail text." % key)


func _expected_speed_delta(scoring: Dictionary, elapsed_seconds: float) -> int:
	var speed := _dictionary_from(scoring.get("speed_seconds", {}))
	var great_seconds := maxf(float(speed.get("great", 0.0)), 0.0)
	var ok_seconds := maxf(float(speed.get("ok", great_seconds)), great_seconds)
	if elapsed_seconds <= great_seconds:
		return LocalProfileScript.GREAT_SPEED_DELTA
	if elapsed_seconds <= ok_seconds:
		return LocalProfileScript.OK_SPEED_DELTA
	return LocalProfileScript.SLOW_SPEED_DELTA


func _expected_action_delta(scoring: Dictionary, action_count: int) -> int:
	var actions := _dictionary_from(scoring.get("action_count", {}))
	var great_actions := maxi(int(actions.get("great", 1)), 1)
	var ok_actions := maxi(int(actions.get("ok", great_actions)), great_actions)
	if action_count <= great_actions:
		return LocalProfileScript.GREAT_ACTION_DELTA
	if action_count <= ok_actions:
		return LocalProfileScript.OK_ACTION_DELTA
	return LocalProfileScript.HIGH_ACTION_DELTA


func _roast_penalty(scoring: Dictionary) -> int:
	return maxi(int(scoring.get("roast_penalty", LocalProfileScript.DEFAULT_ROAST_PENALTY)), 0)


func _component_delta(components: Dictionary, key: String) -> int:
	var component := _dictionary_from(components.get(key, {}))
	return int(component.get("delta", 0))


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


func _scoring(level: Dictionary) -> Dictionary:
	return _dictionary_from(level.get("scoring", {}))


func _solution(level: Dictionary) -> Dictionary:
	return _dictionary_from(level.get("solution", {}))


func _dictionary_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _screen_has_label_text(text: String) -> bool:
	return _node_has_label_text(_main, text)


func _node_has_label_text(node: Node, text: String) -> bool:
	if node is Label and str(node.text).contains(text):
		return true
	for child in node.get_children():
		if _node_has_label_text(child, text):
			return true
	return false


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	_cleanup()
	quit(1)


func _cleanup() -> void:
	if _main != null:
		_main.queue_free()
	_remove_test_save(TEST_SAVE_PATH)
	_remove_test_save(TEST_DUR_SAVE_PATH)
	_remove_test_save(TEST_UI_SAVE_PATH)


func _remove_test_save(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
