extends RefCounted

const PACK_1_PATH := "res://content/levels/pack_01_orientation_is_a_trap.json"
const PACK_2_PATH := "res://content/levels/pack_02_words_are_lying.json"
const PACK_3_PATH := "res://content/levels/pack_03_move_the_wrong_thing.json"
const PACK_4_PATH := "res://content/levels/pack_04_pattern_crimes.json"
const PACK_5_PATH := "res://content/levels/pack_05_brain_buffer_full.json"
const DEFAULT_PACK_PATH := PACK_1_PATH
const DEFAULT_PACK_PATHS := [
	PACK_1_PATH,
	PACK_2_PATH,
	PACK_3_PATH,
	PACK_4_PATH,
	PACK_5_PATH,
]
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


func load_default_packs() -> Dictionary:
	return load_packs(DEFAULT_PACK_PATHS)


func load_packs(paths: Array = DEFAULT_PACK_PATHS) -> Dictionary:
	last_error = ""

	if paths.is_empty():
		last_error = "At least one Pack Level File path is required."
		return {}

	var packs := []
	var levels := []
	var source_paths: Array[String] = []
	var seen_level_ids := {}
	var seen_level_numbers := {}

	for index in range(paths.size()):
		var path := str(paths[index]).strip_edges()
		if path.is_empty():
			last_error = "Pack Level File path %d is empty." % (index + 1)
			return {}

		var pack := load_pack(path)
		if pack.is_empty():
			return {}

		var pack_levels: Array = pack.get("levels", [])
		packs.append(_pack_metadata(pack, path, pack_levels))
		source_paths.append(path)

		for level in pack_levels:
			if typeof(level) != TYPE_DICTIONARY:
				last_error = "Pack Level File contains an invalid Level Spec after validation: %s" % path
				return {}

			var level_id := str(level.get("id", ""))
			var level_number := int(level.get("level_number", 0))
			if seen_level_ids.has(level_id):
				last_error = "Duplicate Level Spec id across Pack Level Files: %s (%s and %s)" % [level_id, str(seen_level_ids[level_id]), path]
				return {}
			if seen_level_numbers.has(level_number):
				last_error = "Duplicate level_number across Pack Level Files: %d (%s and %s)" % [level_number, str(seen_level_numbers[level_number]), path]
				return {}

			seen_level_ids[level_id] = path
			seen_level_numbers[level_number] = path
			levels.append(level)

	levels.sort_custom(Callable(self, "_sort_levels_by_number"))
	packs.sort_custom(Callable(self, "_sort_packs_by_first_level_number"))
	last_error = ""
	return {
		"pack_id": "local_packs",
		"pack_title": "Local Level Packs",
		"packs": packs,
		"levels": levels,
		"level_count": levels.size(),
		"source_path": ", ".join(source_paths),
		"source_paths": source_paths,
	}


func find_level_by_number(pack: Dictionary, level_number: int) -> Dictionary:
	var levels = pack.get("levels", [])
	if typeof(levels) != TYPE_ARRAY:
		return {}

	for level in levels:
		if typeof(level) == TYPE_DICTIONARY and int(level.get("level_number", 0)) == level_number:
			return level

	return {}


func _pack_metadata(pack: Dictionary, source_path: String, levels: Array) -> Dictionary:
	var first_level_number := 0
	var last_level_number := 0
	for level in levels:
		if typeof(level) != TYPE_DICTIONARY:
			continue

		var level_number := int(level.get("level_number", 0))
		if first_level_number == 0 or level_number < first_level_number:
			first_level_number = level_number
		if level_number > last_level_number:
			last_level_number = level_number

	return {
		"pack_id": str(pack.get("pack_id", "")),
		"pack_title": str(pack.get("pack_title", "")),
		"source_path": source_path,
		"level_count": levels.size(),
		"first_level_number": first_level_number,
		"last_level_number": last_level_number,
	}


func _sort_levels_by_number(a: Variant, b: Variant) -> bool:
	return int(a.get("level_number", 0)) < int(b.get("level_number", 0))


func _sort_packs_by_first_level_number(a: Variant, b: Variant) -> bool:
	return int(a.get("first_level_number", 0)) < int(b.get("first_level_number", 0))


func _missing_required_fields(level: Dictionary) -> Array:
	var missing := []
	for field in REQUIRED_LEVEL_FIELDS:
		if not level.has(field):
			missing.append(field)
	return missing
