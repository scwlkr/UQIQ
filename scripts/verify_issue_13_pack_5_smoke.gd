extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")

const TEST_SAVE_PATH := "user://issue_13_pack_5_smoke_profile.json"
const PACK_1_ID := "pack_01_orientation_is_a_trap"
const PACK_2_ID := "pack_02_words_are_lying"
const PACK_3_ID := "pack_03_move_the_wrong_thing"
const PACK_4_ID := "pack_04_pattern_crimes"
const PACK_5_ID := "pack_05_brain_buffer_full"
const FIRST_LEVEL_NUMBER := 1
const PACK_2_FIRST_LEVEL := 11
const PACK_2_LAST_LEVEL := 20
const PACK_3_FIRST_LEVEL := 21
const PACK_3_LAST_LEVEL := 30
const PACK_4_FIRST_LEVEL := 31
const PACK_4_LAST_LEVEL := 40
const PACK_5_FIRST_LEVEL := 41
const PACK_5_LAST_LEVEL := 50
const TOTAL_LEVEL_COUNT := 50
const EXPECTED_PACK_IDS := [
	PACK_1_ID,
	PACK_2_ID,
	PACK_3_ID,
	PACK_4_ID,
	PACK_5_ID,
]
const SUPPORTED_TEMPLATES := [
	"Tap Logic",
	"Drag Logic",
	"Text Trap",
	"Pattern Grid",
	"Memory Flash",
	"Physics Draw",
]

var _main: Control
var _profile: RefCounted
var _combined_pack := {}
var _all_levels: Array[Dictionary] = []
var _pack_2_levels: Array[Dictionary] = []
var _pack_3_levels: Array[Dictionary] = []
var _pack_4_levels: Array[Dictionary] = []
var _pack_5_levels: Array[Dictionary] = []
var _completion_count := 0
var _pack_2_completion_count := 0
var _pack_3_completion_count := 0
var _pack_4_completion_count := 0
var _pack_5_completion_count := 0
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
	_load_combined_levels()
	if _failed:
		return
	_assert_clean_profile()
	if _failed:
		return
	_assert_level_list_exposes_all_levels()
	if _failed:
		return

	_run_pack_1_unlock_flow()
	if _failed:
		return
	_assert_save_load_state("Pack 1 completion through Level 10", _levels_between(FIRST_LEVEL_NUMBER, 10))
	if _failed:
		return

	_run_pack_2_completion_flow()
	if _failed:
		return
	_assert_pack_2_profile_state("Pack 2 completion")
	if _failed:
		return
	_assert_save_load_state("Pack 2 completion", _levels_between(FIRST_LEVEL_NUMBER, PACK_2_LAST_LEVEL))
	if _failed:
		return

	_run_pack_3_completion_flow()
	if _failed:
		return
	_assert_pack_3_profile_state("Pack 3 completion")
	if _failed:
		return
	_assert_save_load_state("Pack 3 completion", _levels_between(FIRST_LEVEL_NUMBER, PACK_3_LAST_LEVEL))
	if _failed:
		return

	_run_pack_4_completion_flow()
	if _failed:
		return
	_assert_pack_4_profile_state("Pack 4 completion")
	if _failed:
		return
	_assert_save_load_state("Pack 4 completion", _levels_between(FIRST_LEVEL_NUMBER, PACK_4_LAST_LEVEL))
	if _failed:
		return

	_run_pack_5_completion_flow()
	if _failed:
		return
	_assert_pack_5_profile_state("Pack 5 completion")
	if _failed:
		return
	_assert_save_load_state("Pack 5 completion", _all_levels)
	if _failed:
		return

	_run_level_50_replay_best_attempt_checks()
	if _failed:
		return
	_assert_save_load_state("Level 50 replay", _all_levels)
	if _failed:
		return
	_assert_restart_state()
	if _failed:
		return

	print("Issue #13 Pack 5 smoke passed: %d Level List rows, %d completion(s), %d Pack 2 completion(s), %d Pack 3 completion(s), %d Pack 4 completion(s), %d Pack 5 completion(s), %d replay(s), %d Score Roastcard(s), %d save/load check(s), %d restart check(s), %d Dur spend(s), %d Dur recovery event(s)." % [
		TOTAL_LEVEL_COUNT,
		_completion_count,
		_pack_2_completion_count,
		_pack_3_completion_count,
		_pack_4_completion_count,
		_pack_5_completion_count,
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

	if not _combined_pack.is_empty():
		_inject_combined_pack()


func _load_combined_levels() -> void:
	var loader := LevelLoaderScript.new()
	var loaded := loader.load_default_packs()
	if not _require(not loaded.is_empty(), loader.last_error):
		return

	_all_levels = []
	_pack_2_levels = []
	_pack_3_levels = []
	_pack_4_levels = []
	_pack_5_levels = []
	var packs := _packs(loaded)
	if not _require(packs.size() >= EXPECTED_PACK_IDS.size(), "Issue #13 smoke should load at least the first 5 Pack metadata entries."):
		return
	for index in range(EXPECTED_PACK_IDS.size()):
		var pack := _dictionary_from(packs[index])
		var expected_first_level := (index * 10) + 1
		var expected_last_level := expected_first_level + 9
		if not _require(str(pack.get("pack_id", "")) == EXPECTED_PACK_IDS[index], "Pack metadata %d should describe %s." % [index + 1, EXPECTED_PACK_IDS[index]]):
			return
		if not _require(int(pack.get("first_level_number", 0)) == expected_first_level, "Pack metadata %d should start at Level %d." % [index + 1, expected_first_level]):
			return
		if not _require(int(pack.get("last_level_number", 0)) == expected_last_level, "Pack metadata %d should end at Level %d." % [index + 1, expected_last_level]):
			return

	for level_number in range(FIRST_LEVEL_NUMBER, PACK_5_LAST_LEVEL + 1):
		var level := loader.find_level_by_number(loaded, level_number)
		if not _require(not level.is_empty(), "Level %d was not found in its Pack Level File." % level_number):
			return
		if not _require(_is_supported_level_spec(level), "Level %d is not a supported playable Level Spec." % level_number):
			return

		_all_levels.append(level)
		if level_number >= PACK_2_FIRST_LEVEL and level_number <= PACK_2_LAST_LEVEL:
			_pack_2_levels.append(level)
		elif level_number >= PACK_3_FIRST_LEVEL and level_number <= PACK_3_LAST_LEVEL:
			_pack_3_levels.append(level)
		elif level_number >= PACK_4_FIRST_LEVEL and level_number <= PACK_4_LAST_LEVEL:
			_pack_4_levels.append(level)
		elif level_number >= PACK_5_FIRST_LEVEL:
			_pack_5_levels.append(level)

	if not _require(_all_levels.size() == TOTAL_LEVEL_COUNT, "Issue #13 smoke should load exactly %d Level Specs." % TOTAL_LEVEL_COUNT):
		return
	if not _require(_pack_2_levels.size() == 10, "Issue #13 smoke should load exactly 10 Pack 2 Level Specs."):
		return
	if not _require(_pack_3_levels.size() == 10, "Issue #13 smoke should load exactly 10 Pack 3 Level Specs."):
		return
	if not _require(_pack_4_levels.size() == 10, "Issue #13 smoke should load exactly 10 Pack 4 Level Specs."):
		return
	if not _require(_pack_5_levels.size() == 10, "Issue #13 smoke should load exactly 10 Pack 5 Level Specs."):
		return

	if not _require(int(loaded.get("level_count", 0)) >= TOTAL_LEVEL_COUNT, "Combined pack metadata should include at least Levels 1-50."):
		return

	_combined_pack = loaded
	_inject_combined_pack()


func _inject_combined_pack() -> void:
	_main.set("_pack", _combined_pack)
	_main.set("_packs", [])
	_main.call("_show_level_list")


func _assert_clean_profile() -> void:
	if not _require(_profile.current_uqiq_score() == LocalProfileScript.DEFAULT_UQIQ_SCORE, "Clean Pack 5 smoke profile should start at UQIQ 100."):
		return
	if not _require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "Clean Pack 5 smoke profile should start with 3 Dur Tokens."):
		return
	if not _require(_profile.is_level_unlocked(1), "Clean Pack 5 smoke profile should start with Level 1 unlocked."):
		return
	if not _require(not _profile.is_level_unlocked(2), "Clean Pack 5 smoke profile should start with Level 2 locked."):
		return
	if not _require(not _profile.is_level_unlocked(PACK_3_FIRST_LEVEL), "Clean Pack 5 smoke profile should start with Level 21 locked."):
		return
	if not _require(not _profile.is_level_unlocked(PACK_4_FIRST_LEVEL), "Clean Pack 5 smoke profile should start with Level 31 locked."):
		return
	if not _require(not _profile.is_level_unlocked(PACK_5_FIRST_LEVEL), "Clean Pack 5 smoke profile should start with Level 41 locked."):
		return


func _assert_level_list_exposes_all_levels() -> void:
	_main.call("_show_level_list")
	for pack_number in range(1, 6):
		var first_level_number := ((pack_number - 1) * 10) + 1
		var last_level_number := first_level_number + 9
		if not _require(_screen_has_label_with("Pack %d:" % pack_number, "Levels %02d-%02d" % [first_level_number, last_level_number]), "Level List should render a Pack %d heading for Levels %02d-%02d." % [pack_number, first_level_number, last_level_number]):
			return

	if not _require(_screen_has_label_with("Pack 4:", "Pattern Crimes"), "Level List should render Pack 4 as Pattern Crimes."):
		return
	if not _require(_screen_has_label_with("Pack 5:", "Brain Buffer Full"), "Level List should render Pack 5 as Brain Buffer Full."):
		return

	for level_number in range(FIRST_LEVEL_NUMBER, PACK_5_LAST_LEVEL + 1):
		var row := _find_level_row(level_number)
		if not _require(row != null, "Level List should render a row for Level %d." % level_number):
			return
		var button := _find_level_button(level_number)
		if not _require(button != null, "Level List should render a play/replay button for Level %d." % level_number):
			return


func _run_pack_1_unlock_flow() -> void:
	for level_number in range(FIRST_LEVEL_NUMBER, 10):
		var level := _level_by_number(level_number)
		_start_level_from_list(level)
		if _failed:
			return
		_complete_with_scorecard(level, true, false, false)
		if _failed:
			return
		if not _require(_profile.is_level_unlocked(level_number + 1), "Completing Level %d should unlock Level %d." % [level_number, level_number + 1]):
			return

	var level_10 := _level_by_number(10)
	_spend_dur_from_level_list(level_10, "DUR'ing Level 10 should unlock Level 11.", PACK_2_FIRST_LEVEL)
	if _failed:
		return
	_assert_reload_preserves_dur_state(level_10, "Level 10 DUR unlock")
	if _failed:
		return

	_start_level_from_list(level_10)
	if _failed:
		return
	_complete_with_scorecard(level_10, true, false, true)
	if _failed:
		return
	if not _require(_profile.is_level_unlocked(PACK_2_FIRST_LEVEL), "Completing recovered Level 10 should keep Level 11 unlocked."):
		return


func _run_pack_2_completion_flow() -> void:
	for level in _pack_2_levels:
		var level_number := int(level.get("level_number", 0))

		if level_number == 14:
			_spend_dur_from_level_list(level, "DUR'ing Pack 2 Level 14 should unlock Level 15.", 15)
			if _failed:
				return
			_assert_reload_preserves_dur_state(level, "Pack 2 Level 14 DUR spend")
			if _failed:
				return

		if level_number == PACK_2_LAST_LEVEL:
			if not _require(not _profile.is_level_unlocked(PACK_3_FIRST_LEVEL), "Level 21 should stay locked before completing or DUR'ing Level 20."):
				return
			_spend_dur_from_level_list(level, "DUR'ing Level 20 should unlock Level 21.", PACK_3_FIRST_LEVEL)
			if _failed:
				return
			_assert_reload_preserves_dur_state(level, "Level 20 DUR unlock")
			if _failed:
				return

		_start_level_from_list(level)
		if _failed:
			return

		var was_durd: bool = _profile.is_level_durd(str(level.get("id", "")))
		_complete_with_scorecard(level, true, false, was_durd)
		if _failed:
			return
		_pack_2_completion_count += 1

		if level_number < PACK_2_LAST_LEVEL:
			if not _require(_profile.is_level_unlocked(level_number + 1), "Completing or DUR'ing Level %d should unlock Level %d." % [level_number, level_number + 1]):
				return
		else:
			if not _require(_profile.is_level_unlocked(PACK_3_FIRST_LEVEL), "Completing recovered Level 20 should keep Level 21 unlocked."):
				return


func _run_pack_3_completion_flow() -> void:
	for level in _pack_3_levels:
		var level_number := int(level.get("level_number", 0))

		if level_number == 24:
			_spend_dur_from_level_list(level, "DUR'ing Pack 3 Level 24 should unlock Level 25.", 25)
			if _failed:
				return
			_assert_reload_preserves_dur_state(level, "Pack 3 Level 24 DUR spend")
			if _failed:
				return

		if level_number == PACK_3_LAST_LEVEL:
			if not _require(not _profile.is_level_unlocked(PACK_4_FIRST_LEVEL), "Level 31 should stay locked before completing or DUR'ing Level 30."):
				return

		_start_level_from_list(level)
		if _failed:
			return

		var was_durd: bool = _profile.is_level_durd(str(level.get("id", "")))
		_complete_with_scorecard(level, true, false, was_durd)
		if _failed:
			return
		_pack_3_completion_count += 1

		if level_number < PACK_3_LAST_LEVEL:
			if not _require(_profile.is_level_unlocked(level_number + 1), "Completing or DUR'ing Level %d should unlock Level %d." % [level_number, level_number + 1]):
				return
		else:
			if not _require(_profile.is_level_unlocked(PACK_4_FIRST_LEVEL), "Completing Level 30 should unlock Level 31."):
				return


func _assert_pack_2_profile_state(context: String) -> void:
	for level in _pack_2_levels:
		var level_id := str(level.get("id", ""))
		if not _require(_profile.is_level_completed(level_id), "%s should preserve Pack 2 completion for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_best_attempt(level_id).is_empty(), "%s should preserve Best Attempt for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_score_result(level_id).is_empty(), "%s should preserve score result for %s." % [context, level_id]):
			return
	if not _require(_profile.is_level_unlocked(PACK_3_FIRST_LEVEL), "%s should preserve Level 21 unlock." % context):
		return


func _run_pack_4_completion_flow() -> void:
	for level in _pack_4_levels:
		var level_number := int(level.get("level_number", 0))

		if level_number == 34:
			_spend_dur_from_level_list(level, "DUR'ing Pack 4 Level 34 should unlock Level 35.", 35)
			if _failed:
				return
			_assert_reload_preserves_dur_state(level, "Pack 4 Level 34 DUR spend")
			if _failed:
				return

		if level_number == PACK_4_LAST_LEVEL:
			if not _require(not _profile.is_level_unlocked(PACK_5_FIRST_LEVEL), "Level 41 should stay locked before completing or DUR'ing Level 40."):
				return
			_spend_dur_from_level_list(level, "DUR'ing Level 40 should unlock Level 41.", PACK_5_FIRST_LEVEL)
			if _failed:
				return
			_assert_reload_preserves_dur_state(level, "Level 40 DUR unlock")
			if _failed:
				return

		_start_level_from_list(level)
		if _failed:
			return

		var was_durd: bool = _profile.is_level_durd(str(level.get("id", "")))
		_complete_with_scorecard(level, true, false, was_durd)
		if _failed:
			return
		_pack_4_completion_count += 1

		if level_number < PACK_4_LAST_LEVEL:
			if not _require(_profile.is_level_unlocked(level_number + 1), "Completing or DUR'ing Level %d should unlock Level %d." % [level_number, level_number + 1]):
				return
		else:
			if not _require(_profile.is_level_unlocked(PACK_5_FIRST_LEVEL), "Completing recovered Level 40 should keep Level 41 unlocked."):
				return


func _run_pack_5_completion_flow() -> void:
	for level in _pack_5_levels:
		var level_number := int(level.get("level_number", 0))

		if level_number == 44:
			_spend_dur_from_level_list(level, "DUR'ing Pack 5 Level 44 should unlock Level 45.", 45)
			if _failed:
				return
			_assert_reload_preserves_dur_state(level, "Pack 5 Level 44 DUR spend")
			if _failed:
				return

		_start_level_from_list(level)
		if _failed:
			return

		var was_durd: bool = _profile.is_level_durd(str(level.get("id", "")))
		_complete_with_scorecard(level, true, false, was_durd)
		if _failed:
			return
		_pack_5_completion_count += 1

		if level_number < PACK_5_LAST_LEVEL:
			if not _require(_profile.is_level_unlocked(level_number + 1), "Completing or DUR'ing Level %d should unlock Level %d." % [level_number, level_number + 1]):
				return
		else:
			if not _require(int(_profile.data.get("unlocked_level", 0)) >= PACK_5_LAST_LEVEL + 1, "Completing Level 50 should advance Local Profile beyond Pack 5."):
				return


func _run_level_50_replay_best_attempt_checks() -> void:
	var level := _level_by_number(PACK_5_LAST_LEVEL)
	var level_id := str(level.get("id", ""))

	var first_best: Dictionary = _profile.get_best_attempt(level_id)
	if not _require(not first_best.is_empty(), "Level 50 should have a Best Attempt before replay."):
		return
	if not _require(int(first_best.get("roast_count", -1)) > 0, "Initial Level 50 completion should include Roast usage so replay can improve it."):
		return

	_start_level_from_list(level)
	if _failed:
		return
	_complete_with_scorecard(level, false, true, false)
	if _failed:
		return
	var better_best: Dictionary = _profile.get_best_attempt(level_id)
	if not _require(int(better_best.get("roast_count", -1)) == 0, "Better Level 50 replay should improve Best Attempt Roast count."):
		return
	if not _require(int(better_best.get("action_count", 9999)) <= int(first_best.get("action_count", 9999)), "Better Level 50 replay should keep or improve Best Attempt action count."):
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
	if not _require(int(kept_best.get("roast_count", -1)) == 0, "Worse Level 50 replay should keep the improved Best Attempt Roast count."):
		return
	if not _require(int(kept_best.get("action_count", 9999)) == int(better_best.get("action_count", 9999)), "Worse Level 50 replay should keep the improved Best Attempt action count."):
		return


func _spend_dur_from_level_list(level: Dictionary, unlock_message: String, expected_unlocked_level: int) -> void:
	var level_number := int(level.get("level_number", 0))
	var level_id := str(level.get("id", ""))
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
	if not _require(_profile.is_level_unlocked(expected_unlocked_level), unlock_message):
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

	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	if not _require(not best_attempt.is_empty(), "Best Attempt should exist for %s." % level_id):
		return

	var completed_attempt := _dictionary_from(_main.get("_last_completed_attempt"))
	if not _require(not completed_attempt.is_empty(), "Main scene should keep completed Attempt Metrics for %s." % level_id):
		return
	if not _require(bool(completed_attempt.get("completed", false)), "Attempt Metrics should mark %s completed." % level_id):
		return
	if not _require(int(completed_attempt.get("action_count", 0)) > 0, "Attempt Metrics should record action_count for %s." % level_id):
		return
	if not _require(completed_attempt.has("score_delta"), "Attempt Metrics should record score_delta for %s." % level_id):
		return
	if use_roast:
		if not _require(int(completed_attempt.get("roast_count", 0)) > 0, "Attempt Metrics should record Roast usage for %s." % level_id):
			return

	var score_result: Dictionary = _profile.get_score_result(level_id)
	if not _require(not score_result.is_empty(), "Score result should persist for %s." % level_id):
		return
	if not _require(int(score_result.get("score_before", score_before)) == score_before, "Score result should preserve score_before for %s." % level_id):
		return
	if not replay:
		if not _require(int(score_result.get("score_after", score_before)) != score_before, "Completing %s should change UQIQ Score." % level_id):
			return
	if not _require(int(score_result.get("action_count", 0)) == int(completed_attempt.get("action_count", 0)), "Score result should preserve action_count for %s." % level_id):
		return
	if not _require(int(score_result.get("roast_count", 0)) == int(completed_attempt.get("roast_count", 0)), "Score result should preserve Roast count for %s." % level_id):
		return
	if not _require(not _dictionary_from(_main.get("_last_score_result")).is_empty(), "Main scene should keep the last Score Roastcard result for %s." % level_id):
		return
	_assert_scorecard_screen(level)
	if _failed:
		return
	_scorecard_count += 1

	if was_durd:
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
			var text_input := _main.get("_text_input") as LineEdit
			if not _require(text_input != null, "Text Trap should have an input before submit."):
				return
			text_input.text = str(_solution(level).get("answer", ""))
			_main.call("_handle_text_submit")
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
			if not _require(false, "Unsupported Level Template in Pack 5 smoke: %s" % str(level.get("template", ""))):
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


func _assert_save_load_state(context: String, levels_to_check: Array[Dictionary]) -> void:
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

	for level in levels_to_check:
		var level_id := str(level.get("id", ""))
		if not _require(reload.is_level_completed(level_id), "Reload should preserve completion for %s after %s." % [level_id, context]):
			return
		if not _require(not reload.get_best_attempt(level_id).is_empty(), "Reload should preserve Best Attempt for %s after %s." % [level_id, context]):
			return
		if not _require(not reload.get_score_result(level_id).is_empty(), "Reload should preserve Score Roastcard result for %s after %s." % [level_id, context]):
			return


func _assert_reload_preserves_dur_state(level: Dictionary, context: String) -> void:
	var level_id := str(level.get("id", ""))
	var reload := LocalProfileScript.new(TEST_SAVE_PATH)
	if not _require(reload.load_or_create(), reload.last_error):
		return
	_save_load_count += 1

	if not _require(reload.is_level_durd(level_id), "Reload should preserve DUR'D state for %s after %s." % [level_id, context]):
		return
	if not _require(reload.dur_tokens() == _profile.dur_tokens(), "Reload should preserve spent Dur Token count after %s." % context):
		return
	if not _require(int(reload.data.get("unlocked_level", 0)) == int(_profile.data.get("unlocked_level", 0)), "Reload should preserve unlock progress after %s." % context):
		return


func _assert_restart_state() -> void:
	var expected_score: int = _profile.current_uqiq_score()
	var expected_tokens: int = _profile.dur_tokens()
	var expected_unlocked := int(_profile.data.get("unlocked_level", 0))
	_boot_main_scene()
	if _failed:
		return
	_restart_count += 1

	if not _require(_profile.current_uqiq_score() == expected_score, "App restart should preserve UQIQ Score after Pack 5."):
		return
	if not _require(_profile.dur_tokens() == expected_tokens, "App restart should preserve Dur Tokens after Pack 5."):
		return
	if not _require(int(_profile.data.get("unlocked_level", 0)) == expected_unlocked, "App restart should preserve Level 50 unlock progress."):
		return
	_assert_pack_2_profile_state("app restart")
	if _failed:
		return
	_assert_pack_3_profile_state("app restart")
	if _failed:
		return
	_assert_pack_4_profile_state("app restart")
	if _failed:
		return
	_assert_pack_5_profile_state("app restart")


func _assert_pack_3_profile_state(context: String) -> void:
	for level in _pack_3_levels:
		var level_id := str(level.get("id", ""))
		if not _require(_profile.is_level_completed(level_id), "%s should preserve Pack 3 completion for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_best_attempt(level_id).is_empty(), "%s should preserve Best Attempt for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_score_result(level_id).is_empty(), "%s should preserve score result for %s." % [context, level_id]):
			return
	if not _require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "%s should preserve recovered Dur Token state." % context):
		return
	if not _require(int(_profile.data.get("unlocked_level", 0)) >= PACK_3_LAST_LEVEL + 1, "%s should preserve progress beyond Level 30." % context):
		return


func _assert_pack_4_profile_state(context: String) -> void:
	for level in _pack_4_levels:
		var level_id := str(level.get("id", ""))
		if not _require(_profile.is_level_completed(level_id), "%s should preserve Pack 4 completion for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_best_attempt(level_id).is_empty(), "%s should preserve Best Attempt for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_score_result(level_id).is_empty(), "%s should preserve score result for %s." % [context, level_id]):
			return
	if not _require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "%s should preserve recovered Dur Token state." % context):
		return
	if not _require(int(_profile.data.get("unlocked_level", 0)) >= PACK_4_LAST_LEVEL + 1, "%s should preserve progress beyond Level 40." % context):
		return


func _assert_pack_5_profile_state(context: String) -> void:
	for level in _pack_5_levels:
		var level_id := str(level.get("id", ""))
		if not _require(_profile.is_level_completed(level_id), "%s should preserve Pack 5 completion for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_best_attempt(level_id).is_empty(), "%s should preserve Best Attempt for %s." % [context, level_id]):
			return
		if not _require(not _profile.get_score_result(level_id).is_empty(), "%s should preserve score result for %s." % [context, level_id]):
			return
	if not _require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "%s should preserve recovered Dur Token state." % context):
		return
	if not _require(int(_profile.data.get("unlocked_level", 0)) >= PACK_5_LAST_LEVEL + 1, "%s should preserve progress beyond Level 50." % context):
		return


func _is_supported_level_spec(level: Dictionary) -> bool:
	var level_number := int(level.get("level_number", 0))
	if not _require(SUPPORTED_TEMPLATES.has(str(level.get("template", ""))), "Level %d uses an unsupported template: %s." % [level_number, str(level.get("template", ""))]):
		return false
	if not _require(str(level.get("completion_mode", "")) != "future_placeholder", "Level %d is still a future placeholder completion mode." % level_number):
		return false

	var rules := _dictionary_from(level.get("rules", {}))
	if not _require(not bool(rules.get("future_placeholder", false)), "Level %d is still marked future_placeholder." % level_number):
		return false

	return true


func _levels_between(first_level_number: int, last_level_number: int) -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	for level in _all_levels:
		var level_number := int(level.get("level_number", 0))
		if level_number >= first_level_number and level_number <= last_level_number:
			levels.append(level)
	return levels


func _packs(pack: Dictionary) -> Array:
	var packs = pack.get("packs", [])
	if typeof(packs) == TYPE_ARRAY:
		return packs
	return []


func _level_by_number(level_number: int) -> Dictionary:
	for level in _all_levels:
		if int(level.get("level_number", 0)) == level_number:
			return level

	_require(false, "Level %d should be loaded for Issue #13 smoke." % level_number)
	return {}


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


func _screen_has_label_with(prefix: String, fragment: String) -> bool:
	return _screen_has_label_with_recursive(_main, prefix, fragment)


func _screen_has_label_with_recursive(node: Node, prefix: String, fragment: String) -> bool:
	if node is Label:
		var text := str(node.text)
		if text.begins_with(prefix) and text.contains(fragment):
			return true

	for child in node.get_children():
		if _screen_has_label_with_recursive(child, prefix, fragment):
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
