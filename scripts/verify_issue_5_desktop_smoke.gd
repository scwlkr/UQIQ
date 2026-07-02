extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_5_desktop_smoke_profile.json"
const STABILITY_CYCLES := 20

var _main: Control
var _profile: RefCounted
var _levels: Array[Dictionary] = []
var _completion_count := 0
var _replay_count := 0
var _scorecard_count := 0
var _save_load_count := 0
var _dur_spend_count := 0
var _dur_recovery_count := 0


func _initialize() -> void:
	_remove_test_save()
	_boot_main_scene()
	_load_levels()
	_assert_clean_profile()

	_run_clean_six_level_flow()
	_run_best_attempt_replay_checks()
	_run_stability_replay_cycles()
	_assert_save_load_state("final")

	print("Issue #5 desktop smoke passed: %d completions, %d replays, %d Score Roastcards, %d save/load checks, %d Dur spend(s), %d Dur recovery event(s), %d stability cycles." % [
		_completion_count,
		_replay_count,
		_scorecard_count,
		_save_load_count,
		_dur_spend_count,
		_dur_recovery_count,
		STABILITY_CYCLES,
	])
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")

	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _load_levels() -> void:
	var loader := LevelLoaderScript.new()
	var pack := loader.load_pack()
	_require(not pack.is_empty(), loader.last_error)

	for level_number in range(1, 7):
		var level := loader.find_level_by_number(pack, level_number)
		_require(not level.is_empty(), "Level %d was not found." % level_number)
		_levels.append(level)


func _assert_clean_profile() -> void:
	_require(_profile.current_uqiq_score() == LocalProfileScript.DEFAULT_UQIQ_SCORE, "Clean smoke profile should start at UQIQ 100.")
	_require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "Clean smoke profile should start with 3 Dur Tokens.")
	_require(_profile.is_level_unlocked(1), "Level 1 should start unlocked.")


func _run_clean_six_level_flow() -> void:
	_start_level(_levels[0])
	_use_roast()
	_main.call("_handle_physics_draw", "flat_line")
	_main.call("_handle_physics_release")
	_complete_with_scorecard(_levels[0], Callable(self, "_physics_draw_win").bind(_levels[0]))
	_require(_profile.is_level_unlocked(2), "Level 2 should unlock after Level 1 completion.")

	_start_level(_levels[1])
	_use_roast()
	_main.call("_handle_physics_draw", "ramp_to_cup")
	_main.call("_handle_physics_release")
	_complete_with_scorecard(_levels[1], Callable(self, "_physics_draw_win").bind(_levels[1]))
	_require(_profile.is_level_unlocked(3), "Level 3 should unlock after Level 2 completion.")

	_spend_dur_on_level(_levels[2])
	_start_level(_levels[2])
	_use_roast()
	_rearrange_wrong(_levels[2])
	_complete_with_scorecard(_levels[2], Callable(self, "_rearrange_win").bind(_levels[2]))
	_require(not _profile.is_level_durd(str(_levels[2].get("id", ""))), "Completing Level 3 should clear DUR'D state.")
	_require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "Completing DUR'D Level 3 should recover the spent Dur Token.")
	_dur_recovery_count += 1

	_start_level(_levels[3])
	_use_roast()
	_main.call("_handle_pattern_cell", "r1c1")
	_main.call("_handle_pattern_submit")
	_complete_with_scorecard(_levels[3], Callable(self, "_rearrange_win").bind(_levels[3]))
	_require(_profile.is_level_unlocked(5), "Level 5 should unlock after Level 4 completion.")

	_start_level(_levels[4])
	_use_roast()
	_memory_reveal_wrong(_levels[4])
	_complete_with_scorecard(_levels[4], Callable(self, "_memory_reveal_win").bind(_levels[4]))
	_require(_profile.is_level_unlocked(6), "Level 6 should unlock after Level 5 completion.")

	_start_level(_levels[5])
	_use_roast()
	_main.call("_handle_physics_draw", "flat_line")
	_main.call("_handle_physics_release")
	_complete_with_scorecard(_levels[5], Callable(self, "_physics_draw_win").bind(_levels[5]))
	_require(_profile.is_level_unlocked(7), "Level 7 should unlock as a future placeholder after Level 6 completion.")
	_assert_save_load_state("clean six-level flow")


func _run_best_attempt_replay_checks() -> void:
	var level := _levels[0]
	var level_id := str(level.get("id", ""))

	_start_level(level)
	_complete_with_scorecard(level, Callable(self, "_physics_draw_win").bind(level), true)
	var better_best: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(better_best.get("action_count", 0)) == 2, "Better replay should improve Level 1 best action count.")
	_require(int(better_best.get("roast_count", -1)) == 0, "Better replay should improve Level 1 best Roast count.")

	_start_level(level)
	_use_roast()
	_use_roast()
	_main.call("_handle_physics_draw", "flat_line")
	_main.call("_handle_physics_release")
	_complete_with_scorecard(level, Callable(self, "_physics_draw_win").bind(level), true)
	var kept_best: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(kept_best.get("action_count", 0)) == 2, "Worse replay should keep Level 1 best action count.")
	_require(int(kept_best.get("roast_count", -1)) == 0, "Worse replay should keep Level 1 best Roast count.")
	_assert_save_load_state("best attempt replay")


func _run_stability_replay_cycles() -> void:
	for cycle_number in range(1, STABILITY_CYCLES + 1):
		for level in _levels:
			_start_level(level)
			_complete_level_by_template(level, true)

		_assert_save_load_state("stability cycle %d" % cycle_number)


func _spend_dur_on_level(level: Dictionary) -> void:
	var level_id := str(level.get("id", ""))
	_require(_profile.can_spend_dur_token(level), "Level %d should allow Dur Token spend." % int(level.get("level_number", 0)))
	var tokens_before: int = _profile.dur_tokens()
	_main.call("_handle_dur_level", level)
	_require(_profile.is_level_durd(level_id), "Dur Token spend should mark Level %d DUR'D." % int(level.get("level_number", 0)))
	_require(_profile.dur_tokens() == tokens_before - 1, "Dur Token spend should decrement token count.")
	_dur_spend_count += 1


func _start_level(level: Dictionary) -> void:
	_require(_profile.is_level_unlocked(int(level.get("level_number", 0))), "Level %d should be unlocked before play." % int(level.get("level_number", 0)))
	_main.call("_show_play_screen", level)
	var current_level := _dictionary_from(_main.get("_current_level"))
	_require(str(current_level.get("id", "")) == str(level.get("id", "")), "Play Screen should hold the requested Level.")


func _use_roast() -> void:
	var roasts_before := int(_main.get("_roast_count"))
	_main.call("_handle_roast_action")
	_require(int(_main.get("_roast_count")) == roasts_before + 1, "Roast action should increment Roast count.")


func _complete_level_by_template(level: Dictionary, replay: bool = false) -> void:
	match str(level.get("template", "")):
		"Tap Logic":
			_complete_with_scorecard(level, Callable(self, "_tap_logic_win").bind(level), replay)
		"Drag Logic":
			_complete_with_scorecard(level, Callable(self, "_drag_logic_win").bind(level), replay)
		"Text Trap":
			_complete_with_scorecard(level, Callable(self, "_text_trap_win").bind(level), replay)
		"Rearrange Level":
			_complete_with_scorecard(level, Callable(self, "_rearrange_win").bind(level), replay)
		"Pattern Grid":
			_complete_with_scorecard(level, Callable(self, "_pattern_grid_win").bind(level), replay)
		"Memory Flash":
			_complete_with_scorecard(level, Callable(self, "_memory_flash_win").bind(level), replay)
		"Memory/Reveal Level":
			_complete_with_scorecard(level, Callable(self, "_memory_reveal_win").bind(level), replay)
		"Physics Draw":
			_complete_with_scorecard(level, Callable(self, "_physics_draw_win").bind(level), replay)
		_:
			_require(false, "Unsupported Level Template in smoke: %s" % str(level.get("template", "")))


func _complete_with_scorecard(level: Dictionary, win_action: Callable, replay: bool = false) -> void:
	var level_id := str(level.get("id", ""))
	var score_before: int = _profile.current_uqiq_score()
	win_action.call()
	_completion_count += 1
	if replay:
		_replay_count += 1

	_require(_profile.last_error.is_empty(), _profile.last_error)
	_require(_profile.is_level_completed(level_id), "Completion should persist for %s." % level_id)
	_require(not _profile.get_best_attempt(level_id).is_empty(), "Best Attempt should exist for %s." % level_id)
	var score_result: Dictionary = _profile.get_score_result(level_id)
	_require(not score_result.is_empty(), "Score Roastcard-equivalent score result should exist for %s." % level_id)
	_require(int(score_result.get("score_before", score_before)) == score_before, "Score result should preserve score_before for %s." % level_id)
	_require(not _dictionary_from(_main.get("_last_score_result")).is_empty(), "Main scene should keep the last Score Roastcard result.")
	_scorecard_count += 1


func _tap_logic_win(level: Dictionary) -> void:
	var solution := _solution(level)
	_main.call("_handle_tap_target", str(solution.get("target_id", "")))


func _drag_logic_win(level: Dictionary) -> void:
	var solution := _solution(level)
	_main.call("_handle_drag_select", str(solution.get("object_id", "")))
	_main.call("_handle_drag_drop", str(solution.get("drop_target_id", "")))


func _text_trap_win(level: Dictionary) -> void:
	var answer := str(_solution(level).get("answer", ""))
	if bool(_main.call("_uses_direct_text_tiles")):
		_main.call("_handle_direct_text_tile_choice", answer, answer, null)
		return

	var text_input := _main.get("_text_input") as LineEdit
	_require(text_input != null, "Text Trap should have an input before submit.")
	text_input.text = answer
	_main.call("_handle_text_submit")


func _text_trap_wrong(level: Dictionary) -> void:
	if bool(_main.call("_uses_direct_text_tiles")):
		_main.call("_handle_direct_text_tile_choice", "blank", "", null)
		return

	var text_input := _main.get("_text_input") as LineEdit
	_require(text_input != null, "Text Trap should create a LineEdit.")
	text_input.text = ""
	_main.call("_handle_text_submit")


func _rearrange_win(level: Dictionary) -> void:
	_complete_rearrange_level(level)


func _complete_rearrange_level(level: Dictionary) -> void:
	var rules := _dictionary_from(level.get("rules", {}))
	if str(rules.get("rearrange_mode", "")) == "move_rule_tile":
		_main.call("_set_rearrange_rule_tile_slot", "right_wall_slot")
	else:
		_main.call("_set_rearrange_cup_center", Vector2(225, 243))
	_main.call("_finish_rearrange_drag")
	_main.call("_handle_rearrange_release")


func _rearrange_wrong(_level: Dictionary) -> void:
	_main.call("_handle_rearrange_release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Wrong Rearrange release should fail before retry.")
	_main.call("_handle_rearrange_reset")


func _pattern_grid_win(level: Dictionary) -> void:
	_main.call("_handle_pattern_cell", str(_solution(level).get("cell_id", "")))
	_main.call("_handle_pattern_submit")


func _memory_flash_win(level: Dictionary) -> void:
	var sequence = _solution(level).get("sequence", [])
	_require(typeof(sequence) == TYPE_ARRAY, "Memory Flash should have a solution sequence.")
	for item in sequence:
		_main.call("_handle_memory_choice", str(item))
	_main.call("_handle_memory_submit")


func _memory_reveal_win(_level: Dictionary) -> void:
	_main.call("_handle_physics_draw", "ramp_to_cup")
	_main.call("_handle_physics_release")


func _memory_reveal_wrong(_level: Dictionary) -> void:
	_main.call("_handle_physics_draw", "flat_line")
	_main.call("_handle_physics_release")
	_require(str(_main.get("_last_physics_result")) == "fail", "Wrong Memory/Reveal draw should fail before retry.")
	_main.call("_handle_freehand_physics_reset")


func _physics_draw_win(level: Dictionary) -> void:
	_main.call("_handle_physics_draw", str(_solution(level).get("draw_id", "")))
	_main.call("_handle_physics_release")


func _assert_save_load_state(context: String) -> void:
	var reload := LocalProfileScript.new(TEST_SAVE_PATH)
	_require(reload.load_or_create(), reload.last_error)
	_save_load_count += 1

	_require(reload.dur_tokens() == _profile.dur_tokens(), "Reload should preserve Dur Token count after %s." % context)
	_require(reload.current_uqiq_score() == _profile.current_uqiq_score(), "Reload should preserve UQIQ Score after %s." % context)
	for level in _levels:
		var level_id := str(level.get("id", ""))
		_require(reload.is_level_completed(level_id), "Reload should preserve completion for %s after %s." % [level_id, context])
		_require(not reload.get_best_attempt(level_id).is_empty(), "Reload should preserve Best Attempt for %s after %s." % [level_id, context])
		_require(not reload.get_score_result(level_id).is_empty(), "Reload should preserve Score Roastcard result for %s after %s." % [level_id, context])


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
	_cleanup()
	quit(1)


func _cleanup() -> void:
	if _main != null and is_instance_valid(_main):
		_main.queue_free()
	_remove_test_save()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
