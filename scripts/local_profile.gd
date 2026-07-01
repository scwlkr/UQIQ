extends RefCounted

const DEFAULT_SAVE_PATH := "user://uqiq_local_profile_v1.json"
const SCHEMA_VERSION := 1
const DEFAULT_UNLOCKED_LEVEL := 1

var save_path: String
var last_error := ""
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


func get_best_attempt(level_id: String) -> Dictionary:
	var attempts := _best_attempts()
	var attempt: Variant = attempts.get(level_id, {})
	if typeof(attempt) == TYPE_DICTIONARY:
		return attempt
	return {}


func record_completed_attempt(level: Dictionary, action_count: int) -> Dictionary:
	last_error = ""

	var level_id := str(level.get("id", ""))
	var level_number := int(level.get("level_number", 0))
	var completed_levels := _completed_levels()
	var attempts := _best_attempts()
	var attempt := {
		"completed": true,
		"level_id": level_id,
		"level_number": level_number,
		"tap_count": max(action_count, 0),
		"action_count": max(action_count, 0),
	}

	if level_id.is_empty() or level_number <= 0:
		last_error = "Cannot save attempt without a valid Level Spec."
		return {}

	completed_levels[level_id] = true

	var current_best := get_best_attempt(level_id)
	if current_best.is_empty() or _is_better_attempt(attempt, current_best):
		attempts[level_id] = attempt

	data["completed_levels"] = completed_levels
	data["best_attempts"] = attempts
	data["unlocked_level"] = max(int(data.get("unlocked_level", DEFAULT_UNLOCKED_LEVEL)), level_number + 1)

	save()
	return get_best_attempt(level_id)


func _default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"unlocked_level": DEFAULT_UNLOCKED_LEVEL,
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


func _is_better_attempt(candidate: Dictionary, current_best: Dictionary) -> bool:
	return int(candidate.get("action_count", 0)) < int(current_best.get("action_count", 0))
