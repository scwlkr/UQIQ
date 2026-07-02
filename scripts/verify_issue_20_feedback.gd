extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_20_feedback_profile.json"

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

	_boot_main_scene()
	if _failed:
		return
	_verify_tap_fail_roast_success_feedback()
	if _failed:
		return
	_verify_dur_spend_and_recovery_feedback()
	if _failed:
		return

	print("Issue #20 feedback verification passed: tap, fail, success, Roast, Dur Token spend, and Dur recovery hooks fired headlessly without changing action counts or persistence.")
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_main.call("_setup_feedback")
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_tap_fail_roast_success_feedback() -> void:
	var level := _level_by_number(1)
	var level_id := str(level.get("id", ""))
	_main.call("_show_play_screen", level)

	_main.call("_handle_physics_draw", "flat_line")
	_main.call("_handle_physics_release")
	_require(_feedback_count("tap") == 2, "Wrong freehand draw plus release should fire tap feedback.")
	_require(_feedback_count("fail") == 1, "Wrong freehand release should fire fail feedback.")
	_require(int(_main.get("_tap_count")) == 2, "Feedback should not add extra actions after wrong freehand release.")

	_main.call("_handle_roast_action")
	_require(_feedback_count("roast") == 1, "Roast action should fire Roast feedback.")
	_require(int(_main.get("_tap_count")) == 2, "Roast feedback should not change action count.")
	_require(int(_main.get("_roast_count")) == 1, "Roast action should still increment Roast count once.")

	_main.call("_handle_physics_draw", str(_solution(level).get("draw_id", "")))
	_main.call("_handle_physics_release")
	_require(_feedback_count("tap") == 4, "Correct freehand draw plus release should fire tap feedback.")
	_require(_feedback_count("success") == 1, "Completion should fire success feedback.")
	_require(_profile.is_level_completed(level_id), "Level 1 should complete after a valid freehand ramp.")

	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 4, "Feedback should not change Level 1 action count.")
	_require(int(best_attempt.get("roast_count", 0)) == 1, "Feedback should not change Level 1 Roast count.")
	_require(not _profile.get_score_result(level_id).is_empty(), "Feedback should not block Score Roastcard persistence.")


func _verify_dur_spend_and_recovery_feedback() -> void:
	var level := _level_by_number(2)
	var level_id := str(level.get("id", ""))
	var spend_before := _feedback_count("dur_spend")
	var recover_before := _feedback_count("dur_recover")
	var success_before := _feedback_count("success")

	_require(_profile.can_spend_dur_token(level), "Unlocked incomplete Level 2 should allow Dur Token spend.")
	_main.call("_handle_dur_level", level)
	_require(_feedback_count("dur_spend") == spend_before + 1, "Dur Token spend should fire spend feedback.")
	_require(_profile.is_level_durd(level_id), "Dur Token spend should still mark Level 2 DUR'D.")
	_require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS - 1, "Dur Token spend should still decrement token count once.")

	_main.call("_show_play_screen", level)
	_complete_level_by_template(level)
	_require(_feedback_count("success") == success_before + 1, "DUR'D completion should still fire success feedback.")
	_require(_feedback_count("dur_recover") == recover_before + 1, "DUR'D completion should fire Dur recovery feedback.")
	_require(not _profile.is_level_durd(level_id), "DUR'D completion should clear DUR state.")
	_require(_profile.dur_tokens() == LocalProfileScript.MAX_DUR_TOKENS, "DUR'D completion should recover one Dur Token.")

	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 2, "Feedback should not change Level 2 action count.")
	_require(bool(best_attempt.get("dur_token_recovered", false)), "DUR recovery should still persist in Attempt Metrics.")


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
			_require(text_input != null, "Text Trap should have an input before submit.")
			text_input.text = answer
			_main.call("_handle_text_submit")
		"Pattern Grid":
			_main.call("_handle_pattern_cell", str(_solution(level).get("cell_id", "")))
			_main.call("_handle_pattern_submit")
		"Memory Flash":
			var sequence = _solution(level).get("sequence", [])
			_require(typeof(sequence) == TYPE_ARRAY, "Memory Flash should have a solution sequence.")
			for item in sequence:
				_main.call("_handle_memory_choice", str(item))
			_main.call("_handle_memory_submit")
		"Physics Draw":
			_main.call("_handle_physics_draw", str(_solution(level).get("draw_id", "")))
			_main.call("_handle_physics_release")
		_:
			_require(false, "Unsupported template in issue #20 feedback verifier: %s" % str(level.get("template", "")))


func _feedback_count(kind: String) -> int:
	var counts := _dictionary_from(_main.get("_feedback_counts"))
	return int(counts.get(kind, 0))


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


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
	_failed = true
	_cleanup()
	quit(1)


func _cleanup() -> void:
	if _main != null:
		_main.queue_free()
	_remove_test_save()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
