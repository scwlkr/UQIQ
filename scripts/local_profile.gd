extends RefCounted

const DEFAULT_SAVE_PATH := "user://uqiq_local_profile_v1.json"
const SCHEMA_VERSION := 1
const DEFAULT_UNLOCKED_LEVEL := 1
const MAX_DUR_TOKENS := 3
const DEFAULT_UQIQ_SCORE := 100
const MIN_UQIQ_SCORE := -20
const MAX_UQIQ_SCORE := 420

var save_path: String
var last_error := ""
var last_completed_attempt: Dictionary = {}
var last_score_result: Dictionary = {}
var last_dur_spend_result: Dictionary = {}
var data: Dictionary = {}


func _init(path: String = DEFAULT_SAVE_PATH) -> void:
	save_path = path


func load_or_create() -> bool:
	last_error = ""

	if not FileAccess.file_exists(save_path):
		data = _default_data()
		return save()

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		last_error = "Could not open Local Profile: %s" % global_save_path()
		data = _default_data()
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Local Profile is not valid JSON. Reset it: %s" % global_save_path()
		data = _default_data()
		return false

	data = _merge_defaults(parsed)
	return save()


func save() -> bool:
	last_error = ""

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write Local Profile: %s" % global_save_path()
		return false

	file.store_string(JSON.stringify(data, "\t"))
	return true


func global_save_path() -> String:
	return ProjectSettings.globalize_path(save_path)


func is_level_unlocked(level_number: int) -> bool:
	return level_number <= int(data.get("unlocked_level", DEFAULT_UNLOCKED_LEVEL))


func is_level_completed(level_id: String) -> bool:
	var completed_levels := _completed_levels()
	return bool(completed_levels.get(level_id, false))


func is_level_durd(level_id: String) -> bool:
	var durd_levels := _durd_levels()
	return durd_levels.has(level_id)


func dur_tokens() -> int:
	return clampi(int(data.get("dur_tokens", MAX_DUR_TOKENS)), 0, MAX_DUR_TOKENS)


func current_uqiq_score() -> int:
	return clampi(int(data.get("uqiq_score", DEFAULT_UQIQ_SCORE)), MIN_UQIQ_SCORE, MAX_UQIQ_SCORE)


func get_best_attempt(level_id: String) -> Dictionary:
	var attempts := _best_attempts()
	var attempt: Variant = attempts.get(level_id, {})
	if typeof(attempt) == TYPE_DICTIONARY:
		return attempt
	return {}


func get_score_result(level_id: String) -> Dictionary:
	var score_results := _score_results()
	var result: Variant = score_results.get(level_id, {})
	if typeof(result) == TYPE_DICTIONARY:
		return result
	return {}


func can_spend_dur_token(level: Dictionary) -> bool:
	var level_id := str(level.get("id", ""))
	var level_number := int(level.get("level_number", 0))
	return not level_id.is_empty() \
		and level_number > 0 \
		and is_level_unlocked(level_number) \
		and not is_level_completed(level_id) \
		and not is_level_durd(level_id) \
		and dur_tokens() > 0


func spend_dur_token(level: Dictionary) -> bool:
	last_error = ""
	last_dur_spend_result = {}

	var level_id := str(level.get("id", ""))
	var level_number := int(level.get("level_number", 0))
	if level_id.is_empty() or level_number <= 0:
		last_error = "Cannot DUR a Level without a valid Level Spec."
		return false
	if not is_level_unlocked(level_number):
		last_error = "Cannot DUR a locked Level."
		return false
	if is_level_completed(level_id):
		last_error = "Cannot DUR a completed Level."
		return false
	if is_level_durd(level_id):
		last_error = "Level is already DUR'D."
		return false
	if dur_tokens() <= 0:
		last_error = "No Dur Tokens left."
		return false

	var tokens_before := dur_tokens()
	var tokens_after: int = maxi(tokens_before - 1, 0)
	var durd_levels := _durd_levels()
	durd_levels[level_id] = {
		"level_id": level_id,
		"level_number": level_number,
		"dur_token_spent": true,
		"tokens_before": tokens_before,
		"tokens_after": tokens_after,
	}

	data["durd_levels"] = durd_levels
	data["dur_tokens"] = tokens_after
	data["unlocked_level"] = max(int(data.get("unlocked_level", DEFAULT_UNLOCKED_LEVEL)), level_number + 1)
	last_dur_spend_result = {
		"level_id": level_id,
		"level_number": level_number,
		"tokens_before": tokens_before,
		"tokens_after": tokens_after,
		"unlocked_level": int(data.get("unlocked_level", DEFAULT_UNLOCKED_LEVEL)),
	}

	return save()


func record_completed_attempt(level: Dictionary, action_count: int, roast_count: int = 0) -> Dictionary:
	last_error = ""
	last_completed_attempt = {}
	last_score_result = {}

	var level_id := str(level.get("id", ""))
	var level_number := int(level.get("level_number", 0))
	if level_id.is_empty() or level_number <= 0:
		last_error = "Cannot save attempt without a valid Level Spec."
		return {}

	var completed_levels := _completed_levels()
	var attempts := _best_attempts()
	var durd_levels := _durd_levels()
	var was_durd := durd_levels.has(level_id)
	var tokens_before := dur_tokens()
	var tokens_after := tokens_before
	var tokens_restored := 0
	if was_durd:
		durd_levels.erase(level_id)
		tokens_after = mini(tokens_before + 1, MAX_DUR_TOKENS)
		tokens_restored = maxi(tokens_after - tokens_before, 0)

	var safe_action_count: int = maxi(action_count, 0)
	var safe_roast_count: int = maxi(roast_count, 0)
	var score_before := current_uqiq_score()
	var raw_delta := _calculate_score_delta(safe_action_count, safe_roast_count, was_durd)
	var score_after := clampi(score_before + raw_delta, MIN_UQIQ_SCORE, MAX_UQIQ_SCORE)
	var score_delta := score_after - score_before
	var attempt := {
		"completed": true,
		"level_id": level_id,
		"level_number": level_number,
		"tap_count": safe_action_count,
		"action_count": safe_action_count,
		"roast_count": safe_roast_count,
		"roast_used": safe_roast_count > 0,
		"durd_at_start": was_durd,
		"dur_token_spent": was_durd,
		"dur_token_recovered": was_durd,
		"dur_tokens_restored": tokens_restored,
		"dur_tokens_before_completion": tokens_before,
		"dur_tokens_after_completion": tokens_after,
		"score_before": score_before,
		"score_delta": score_delta,
		"score_after": score_after,
	}
	var score_result := {
		"level_id": level_id,
		"level_number": level_number,
		"score_before": score_before,
		"score_delta": score_delta,
		"score_after": score_after,
		"action_count": safe_action_count,
		"roast_count": safe_roast_count,
		"durd_at_start": was_durd,
		"dur_tokens_restored": tokens_restored,
	}
	var score_results := _score_results()

	completed_levels[level_id] = true
	score_results[level_id] = score_result

	var current_best := get_best_attempt(level_id)
	if current_best.is_empty() or _is_better_attempt(attempt, current_best):
		attempts[level_id] = attempt

	data["completed_levels"] = completed_levels
	data["best_attempts"] = attempts
	data["durd_levels"] = durd_levels
	data["dur_tokens"] = tokens_after
	data["uqiq_score"] = score_after
	data["score_results"] = score_results
	data["unlocked_level"] = max(int(data.get("unlocked_level", DEFAULT_UNLOCKED_LEVEL)), level_number + 1)
	last_completed_attempt = attempt
	last_score_result = score_result

	save()
	return get_best_attempt(level_id)


func _default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"unlocked_level": DEFAULT_UNLOCKED_LEVEL,
		"dur_tokens": MAX_DUR_TOKENS,
		"durd_levels": {},
		"uqiq_score": DEFAULT_UQIQ_SCORE,
		"score_results": {},
		"completed_levels": {},
		"best_attempts": {},
	}


func _merge_defaults(existing: Dictionary) -> Dictionary:
	var merged := _default_data()
	merged["schema_version"] = SCHEMA_VERSION
	merged["unlocked_level"] = max(DEFAULT_UNLOCKED_LEVEL, int(existing.get("unlocked_level", DEFAULT_UNLOCKED_LEVEL)))

	var completed_levels: Variant = existing.get("completed_levels", {})
	if typeof(completed_levels) == TYPE_DICTIONARY:
		merged["completed_levels"] = completed_levels

	var attempts: Variant = existing.get("best_attempts", {})
	if typeof(attempts) == TYPE_DICTIONARY:
		merged["best_attempts"] = attempts

	var durd_levels: Variant = existing.get("durd_levels", {})
	if typeof(durd_levels) == TYPE_DICTIONARY:
		merged["durd_levels"] = durd_levels

	merged["dur_tokens"] = clampi(int(existing.get("dur_tokens", MAX_DUR_TOKENS)), 0, MAX_DUR_TOKENS)
	merged["uqiq_score"] = clampi(int(existing.get("uqiq_score", DEFAULT_UQIQ_SCORE)), MIN_UQIQ_SCORE, MAX_UQIQ_SCORE)

	var score_results: Variant = existing.get("score_results", {})
	if typeof(score_results) == TYPE_DICTIONARY:
		merged["score_results"] = score_results

	return merged


func _completed_levels() -> Dictionary:
	var completed_levels: Variant = data.get("completed_levels", {})
	if typeof(completed_levels) == TYPE_DICTIONARY:
		return completed_levels
	return {}


func _best_attempts() -> Dictionary:
	var attempts: Variant = data.get("best_attempts", {})
	if typeof(attempts) == TYPE_DICTIONARY:
		return attempts
	return {}


func _durd_levels() -> Dictionary:
	var durd_levels: Variant = data.get("durd_levels", {})
	if typeof(durd_levels) == TYPE_DICTIONARY:
		return durd_levels
	return {}


func _score_results() -> Dictionary:
	var score_results: Variant = data.get("score_results", {})
	if typeof(score_results) == TYPE_DICTIONARY:
		return score_results
	return {}


func _calculate_score_delta(action_count: int, roast_count: int, was_durd: bool) -> int:
	var base_delta := 12
	var action_penalty: int = maxi(action_count - 1, 0) * 2
	var roast_penalty: int = maxi(roast_count, 0) * 5
	var dur_recovery_bonus := 0
	if was_durd:
		dur_recovery_bonus = 3

	return clampi(base_delta - action_penalty - roast_penalty + dur_recovery_bonus, -20, 20)


func _is_better_attempt(candidate: Dictionary, current_best: Dictionary) -> bool:
	var candidate_delta := int(candidate.get("score_delta", -9999))
	var current_delta := int(current_best.get("score_delta", -9999))
	if candidate_delta != current_delta:
		return candidate_delta > current_delta

	var candidate_actions := int(candidate.get("action_count", 0))
	var current_actions := int(current_best.get("action_count", 0))
	if candidate_actions != current_actions:
		return candidate_actions < current_actions

	return int(candidate.get("roast_count", 0)) < int(current_best.get("roast_count", 0))
