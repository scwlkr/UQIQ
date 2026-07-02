extends RefCounted

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")

const TEST_SAVE_PATH := "user://issue_24_device_smoke_profile.json"
const EXPECTED_LEVEL_COUNT := 60

var _main: Control
var _profile
var _levels: Array[Dictionary] = []
var _checks: Array[String] = []
var _failure := ""
var _completion_count := 0
var _scorecard_count := 0
var _save_load_count := 0
var _dur_spend_count := 0
var _dur_recovery_count := 0


func run(main: Control) -> Dictionary:
	_main = main
	_remove_test_save()

	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	if not _require(_profile.load_or_create(), _profile.last_error):
		return _finish(false)

	if not _load_levels():
		return _finish(false)
	if not _assert_clean_profile():
		return _finish(false)
	if not _assert_level_list():
		return _finish(false)
	if not _run_smoke_path():
		return _finish(false)
	if not _assert_save_load_state("device smoke final"):
		return _finish(false)

	return _finish(true)


func _load_levels() -> bool:
	var loader := LevelLoaderScript.new()
	var pack := loader.load_default_packs()
	if not _require(not pack.is_empty(), loader.last_error):
		return false
	if not _require(int(pack.get("level_count", 0)) == EXPECTED_LEVEL_COUNT, "Device smoke should load all 60 Level Specs."):
		return false

	for level_number in range(1, 4):
		var level := loader.find_level_by_number(pack, level_number)
		if not _require(not level.is_empty(), "Level %02d should exist for device smoke." % level_number):
			return false
		_levels.append(level)

	_checks.append("Loaded 60 specs and selected Levels 01-03")
	return true


func _assert_clean_profile() -> bool:
	if not _require(_profile.current_uqiq_score() == LocalProfileScript.DEFAULT_UQIQ_SCORE, "Device smoke profile should start at UQIQ 100."):
		return false
	if not _require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "Device smoke profile should start with 3 Dur Tokens."):
		return false
	if not _require(_profile.is_level_unlocked(1), "Level 01 should start unlocked."):
		return false

	_checks.append("Isolated Local Profile started clean")
	return true


func _assert_level_list() -> bool:
	_main.call("_show_level_list")
	if not _require(_screen_has_label_text("UQIQ"), "Level List should render UQIQ title."):
		return false
	if not _require(_screen_has_label_containing("Loaded 60 Level Specs"), "Level List should render the 60-Level load status."):
		return false

	_checks.append("Level List rendered on device")
	return true


func _run_smoke_path() -> bool:
	if not _start_level(_levels[0]):
		return false
	_use_roast()
	if not _complete_with_scorecard(_levels[0], Callable(self, "_physics_draw_win").bind(_levels[0])):
		return false
	if not _require(_profile.is_level_unlocked(2), "Level 02 should unlock after Level 01 completion."):
		return false

	if not _start_level(_levels[1]):
		return false
	if not _complete_with_scorecard(_levels[1], Callable(self, "_physics_draw_win").bind(_levels[1])):
		return false
	if not _require(_profile.is_level_unlocked(3), "Level 03 should unlock after Level 02 completion."):
		return false

	if not _spend_dur_on_level(_levels[2]):
		return false
	if not _start_level(_levels[2]):
		return false
	if not _complete_with_scorecard(_levels[2], Callable(self, "_rearrange_win").bind(_levels[2]), true):
		return false
	if not _require(not _profile.is_level_durd(str(_levels[2].get("id", ""))), "Completing DUR'D Level 03 should clear DUR state."):
		return false
	if not _require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "Completing DUR'D Level 03 should recover one Dur Token."):
		return false

	_dur_recovery_count += 1
	_checks.append("Play -> Score Roastcard path passed through Level 03")
	return true


func _spend_dur_on_level(level: Dictionary) -> bool:
	var level_id := str(level.get("id", ""))
	var tokens_before: int = _profile.dur_tokens()
	if not _require(_profile.can_spend_dur_token(level), "Level 03 should allow Dur Token spend."):
		return false

	_main.call("_handle_dur_level", level)
	if not _require(_profile.is_level_durd(level_id), "Dur spend should mark Level 03 DUR'D."):
		return false
	if not _require(_profile.dur_tokens() == tokens_before - 1, "Dur spend should decrement Dur Tokens."):
		return false
	if not _require(_screen_has_label_containing("DUR'D Level 03"), "Level List should show the DUR spend notice."):
		return false

	_dur_spend_count += 1
	_checks.append("Dur Token spend rendered on Level List")
	return true


func _start_level(level: Dictionary) -> bool:
	var level_number := int(level.get("level_number", 0))
	if not _require(_profile.is_level_unlocked(level_number), "Level %02d should be unlocked before play." % level_number):
		return false

	_main.call("_show_play_screen", level)
	var current_level := _dictionary_from(_main.get("_current_level"))
	if not _require(str(current_level.get("id", "")) == str(level.get("id", "")), "Play Screen should hold Level %02d." % level_number):
		return false
	if not _require(str(_main.get("_last_transition_name")) == "play_screen", "Play Screen transition should be recorded."):
		return false
	if not _require(_screen_has_label_text(str(level.get("title", ""))), "Play Screen should render Level %02d title." % level_number):
		return false

	return true


func _complete_with_scorecard(level: Dictionary, win_action: Callable, durd_completion: bool = false) -> bool:
	var level_id := str(level.get("id", ""))
	var score_before: int = _profile.current_uqiq_score()
	win_action.call()
	_completion_count += 1

	if not _require(_profile.last_error.is_empty(), _profile.last_error):
		return false
	if not _require(_profile.is_level_completed(level_id), "Completion should persist for %s." % level_id):
		return false
	if not _require(not _profile.get_best_attempt(level_id).is_empty(), "Best Attempt should exist for %s." % level_id):
		return false
	var score_result: Dictionary = _profile.get_score_result(level_id)
	if not _require(not score_result.is_empty(), "Score Roastcard result should exist for %s." % level_id):
		return false
	if not _require(int(score_result.get("score_before", score_before)) == score_before, "Score result should preserve score_before for %s." % level_id):
		return false
	if not _require(str(_main.get("_last_transition_name")) == "score_roastcard", "Score Roastcard transition should be recorded."):
		return false
	if not _require(_screen_has_label_text("Score Roastcard"), "Score Roastcard should render after completion."):
		return false
	if durd_completion:
		var completed_attempt := _dictionary_from(_main.get("_last_completed_attempt"))
		if not _require(bool(completed_attempt.get("dur_token_recovered", false)), "DUR'D completion should record token recovery."):
			return false

	_scorecard_count += 1
	return true


func _use_roast() -> void:
	_main.call("_handle_roast_action")


func _tap_logic_win(level: Dictionary) -> void:
	var solution := _dictionary_from(level.get("solution", {}))
	_main.call("_handle_tap_target", str(solution.get("target_id", "")))


func _physics_draw_win(level: Dictionary) -> void:
	var solution := _dictionary_from(level.get("solution", {}))
	_main.call("_handle_physics_draw", str(solution.get("draw_id", "")))
	_main.call("_handle_physics_release")


func _drag_logic_win(level: Dictionary) -> void:
	var solution := _dictionary_from(level.get("solution", {}))
	_main.call("_handle_drag_select", str(solution.get("object_id", "")))
	_main.call("_handle_drag_drop", str(solution.get("drop_target_id", "")))


func _text_trap_win(level: Dictionary) -> void:
	var solution := _dictionary_from(level.get("solution", {}))
	var answer := str(solution.get("answer", ""))
	if bool(_main.call("_uses_direct_text_tiles")):
		_main.call("_handle_direct_text_tile_choice", answer, answer, null)
		return

	var text_input := _main.get("_text_input") as LineEdit
	if text_input != null:
		text_input.text = answer
	_main.call("_handle_text_submit")


func _rearrange_win(_level: Dictionary) -> void:
	_main.call("_set_rearrange_cup_center", Vector2(225, 243))
	_main.call("_finish_rearrange_drag")
	_main.call("_handle_rearrange_release")


func _assert_save_load_state(context: String) -> bool:
	var reload = LocalProfileScript.new(TEST_SAVE_PATH)
	if not _require(reload.load_or_create(), reload.last_error):
		return false
	if not _require(reload.dur_tokens() == _profile.dur_tokens(), "Reload should preserve Dur Tokens after %s." % context):
		return false
	if not _require(reload.current_uqiq_score() == _profile.current_uqiq_score(), "Reload should preserve UQIQ Score after %s." % context):
		return false

	for level in _levels:
		var level_id := str(level.get("id", ""))
		if not _require(reload.is_level_completed(level_id), "Reload should preserve completion for %s after %s." % [level_id, context]):
			return false
		if not _require(not reload.get_best_attempt(level_id).is_empty(), "Reload should preserve Best Attempt for %s after %s." % [level_id, context]):
			return false
		if not _require(not reload.get_score_result(level_id).is_empty(), "Reload should preserve Score Roastcard result for %s after %s." % [level_id, context]):
			return false

	_save_load_count += 1
	_checks.append("Local Profile save/load preserved Level 01-03 state")
	return true


func _finish(success: bool) -> Dictionary:
	var lines: Array[String] = []
	if success:
		lines.append_array(_checks)
		lines.append("%d completions, %d Score Roastcards" % [_completion_count, _scorecard_count])
		lines.append("%d save/load check(s), %d Dur spend(s), %d Dur recovery event(s)" % [_save_load_count, _dur_spend_count, _dur_recovery_count])
		lines.append("No launch crash observed before/after smoke path")
	else:
		lines.append("FAILED: %s" % _failure)
		lines.append_array(_checks)

	print("Device smoke %s: %s" % ["passed" if success else "failed", " | ".join(lines)])
	_remove_test_save()
	return {
		"success": success,
		"lines": lines,
	}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	if _failure.is_empty():
		_failure = message
	return false


func _screen_has_label_text(text: String) -> bool:
	return _screen_has_label(text, false)


func _screen_has_label_containing(text: String) -> bool:
	return _screen_has_label(text, true)


func _screen_has_label(text: String, partial: bool) -> bool:
	for child in _all_children(_main):
		var label := child as Label
		if label == null:
			continue
		if partial and label.text.contains(text):
			return true
		if not partial and label.text == text:
			return true
	return false


func _all_children(node: Node) -> Array[Node]:
	var children: Array[Node] = []
	for child in node.get_children():
		children.append(child)
		children.append_array(_all_children(child))
	return children


func _dictionary_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
