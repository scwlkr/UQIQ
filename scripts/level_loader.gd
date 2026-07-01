extends RefCounted

const DEFAULT_PACK_PATH := "res://content/levels/pack_01_orientation_is_a_trap.json"
const REQUIRED_LEVEL_FIELDS := [
	"id",
	"pack_id",
	"level_number",
	"title",
	"template",
	"challenge_type",
	"completion_mode",
	"prompt",
	"rules",
	"solution",
	"scoring",
	"roasts",
	"assets",
	"uqiq_moment",
]

var last_error := ""


func load_pack(path: String = DEFAULT_PACK_PATH) -> Dictionary:
	last_error = ""

	if not FileAccess.file_exists(path):
		last_error = "Missing Pack Level File: %s" % path
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Could not open Pack Level File: %s" % path
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Pack Level File is not a JSON object: %s" % path
		return {}

	var pack: Dictionary = parsed
	var levels = pack.get("levels", [])
	if typeof(levels) != TYPE_ARRAY:
		last_error = "Pack Level File must contain a levels array: %s" % path
		return {}

	if levels.size() != 10:
		last_error = "Pack Level File must contain exactly 10 Level Specs: %s" % path
		return {}

	for index in range(levels.size()):
		var level = levels[index]
		if typeof(level) != TYPE_DICTIONARY:
			last_error = "Level Spec %d is not a JSON object: %s" % [index + 1, path]
			return {}

		var missing_fields := _missing_required_fields(level)
		if not missing_fields.is_empty():
			last_error = "Level Spec %d missing fields: %s" % [index + 1, ", ".join(missing_fields)]
			return {}

	pack["source_path"] = path
	return pack


func find_level_by_number(pack: Dictionary, level_number: int) -> Dictionary:
	var levels = pack.get("levels", [])
	if typeof(levels) != TYPE_ARRAY:
		return {}

	for level in levels:
		if typeof(level) == TYPE_DICTIONARY and int(level.get("level_number", 0)) == level_number:
			return level

	return {}


func _missing_required_fields(level: Dictionary) -> Array:
	var missing := []
	for field in REQUIRED_LEVEL_FIELDS:
		if not level.has(field):
			missing.append(field)
	return missing
