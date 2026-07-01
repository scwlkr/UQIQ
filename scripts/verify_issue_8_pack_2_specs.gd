extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")

const PACK_PATH := "res://content/levels/pack_02_words_are_lying.json"
const EXPECTED_PACK_ID := "pack_02_words_are_lying"
const EXPECTED_LEVEL_COUNT := 10
const FIRST_LEVEL_NUMBER := 11
const SUPPORTED_TEMPLATES := [
	"Tap Logic",
	"Drag Logic",
	"Text Trap",
	"Pattern Grid",
	"Memory Flash",
	"Physics Draw",
]

var _errors := []


func _initialize() -> void:
	if not FileAccess.file_exists(PACK_PATH):
		_fail("Missing Pack 2 Level File: %s" % PACK_PATH)
		_finish()
		return

	var file := FileAccess.open(PACK_PATH, FileAccess.READ)
	if file == null:
		_fail("Could not open Pack 2 Level File: %s" % PACK_PATH)
		_finish()
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("Pack 2 Level File must be a JSON object: %s" % PACK_PATH)
		_finish()
		return

	_validate_pack(parsed)
	_finish()


func _validate_pack(pack: Dictionary) -> void:
	_validate_no_future_placeholder(pack, "pack")

	if not pack.has("pack_id"):
		_fail("Pack 2 file missing top-level pack_id.")
	elif str(pack.get("pack_id", "")).strip_edges() != EXPECTED_PACK_ID:
		_fail("Pack 2 pack_id must be %s." % EXPECTED_PACK_ID)

	var levels = pack.get("levels", [])
	if typeof(levels) != TYPE_ARRAY:
		_fail("Pack 2 file must contain a levels array.")
		return

	if levels.size() != EXPECTED_LEVEL_COUNT:
		_fail("Pack 2 must contain exactly %d Level Specs, found %d." % [EXPECTED_LEVEL_COUNT, levels.size()])

	var seen_level_ids := {}
	var seen_level_numbers := {}
	for index in range(levels.size()):
		var level = levels[index]
		var expected_number := FIRST_LEVEL_NUMBER + index
		if typeof(level) != TYPE_DICTIONARY:
			_fail("Level entry %d must be a JSON object." % (index + 1))
			continue

		var context := _level_context(level, expected_number)
		var level_id := str(level.get("id", "")).strip_edges()
		if not level_id.is_empty():
			if seen_level_ids.has(level_id):
				_fail("%s duplicates Level id %s." % [context, level_id])
			seen_level_ids[level_id] = true

		if _is_number(level.get("level_number", null)):
			var level_number := int(level.get("level_number", 0))
			if seen_level_numbers.has(level_number):
				_fail("%s duplicates level_number %d." % [context, level_number])
			seen_level_numbers[level_number] = true

		_validate_level(level, expected_number)


func _validate_level(level: Dictionary, expected_number: int) -> void:
	var context := _level_context(level, expected_number)
	for field in LevelLoaderScript.REQUIRED_LEVEL_FIELDS:
		if not level.has(field):
			_fail("%s missing required field %s." % [context, str(field)])

	if str(level.get("pack_id", "")).strip_edges() != EXPECTED_PACK_ID:
		_fail("%s pack_id must be %s." % [context, EXPECTED_PACK_ID])

	if not _is_number(level.get("level_number", null)):
		_fail("%s level_number must be numeric." % context)
	elif int(level.get("level_number", 0)) != expected_number:
		_fail("%s level_number must be %d." % [context, expected_number])

	for field in ["id", "title", "template", "challenge_type", "completion_mode", "prompt", "uqiq_moment"]:
		if not _has_nonempty_string(level, field):
			_fail("%s %s must be a non-empty string." % [context, field])

	var template := str(level.get("template", "")).strip_edges()
	if not SUPPORTED_TEMPLATES.has(template):
		_fail("%s uses unsupported template %s." % [context, template])

	if str(level.get("completion_mode", "")).strip_edges() == "future_placeholder":
		_fail("%s completion_mode must not be future_placeholder." % context)

	if _looks_like_placeholder(str(level.get("prompt", ""))):
		_fail("%s prompt still looks like placeholder text." % context)
	if _looks_like_placeholder(str(level.get("uqiq_moment", ""))):
		_fail("%s needs a concrete UQIQ Moment." % context)

	var rules := _dictionary_from(level.get("rules", {}))
	var solution := _dictionary_from(level.get("solution", {}))
	var scoring := _dictionary_from(level.get("scoring", {}))
	var roasts := _dictionary_from(level.get("roasts", {}))
	var assets := _dictionary_from(level.get("assets", {}))

	if rules.is_empty():
		_fail("%s rules must be a non-empty object." % context)
	if solution.is_empty():
		_fail("%s solution must be a non-empty object." % context)
	if scoring.is_empty():
		_fail("%s scoring must be a non-empty object." % context)
	if roasts.is_empty():
		_fail("%s roasts must be a non-empty object." % context)
	if assets.is_empty():
		_fail("%s assets must be a non-empty object." % context)

	_validate_scoring(scoring, context)
	_validate_roasts(roasts, context)
	_validate_template_contract(template, rules, solution, context)


func _validate_scoring(scoring: Dictionary, context: String) -> void:
	_validate_thresholds(scoring, "speed_seconds", context)
	_validate_thresholds(scoring, "action_count", context)

	if not scoring.has("roast_penalty"):
		_fail("%s scoring.roast_penalty is required." % context)
	elif not _is_number(scoring.get("roast_penalty", null)):
		_fail("%s scoring.roast_penalty must be numeric." % context)


func _validate_thresholds(scoring: Dictionary, key: String, context: String) -> void:
	var thresholds := _dictionary_from(scoring.get(key, {}))
	if thresholds.is_empty():
		_fail("%s scoring.%s must be a non-empty object." % [context, key])
		return

	for threshold in ["great", "ok"]:
		if not thresholds.has(threshold):
			_fail("%s scoring.%s.%s is required." % [context, key, threshold])
		elif not _is_number(thresholds.get(threshold, null)):
			_fail("%s scoring.%s.%s must be numeric." % [context, key, threshold])

	if _is_number(thresholds.get("great", null)) and _is_number(thresholds.get("ok", null)):
		if float(thresholds.get("ok", 0)) < float(thresholds.get("great", 0)):
			_fail("%s scoring.%s.ok must be greater than or equal to .great." % [context, key])


func _validate_roasts(roasts: Dictionary, context: String) -> void:
	for bucket in ["failure", "delay", "scorecard"]:
		var lines := _string_array_from(roasts.get(bucket, []), "%s roasts.%s" % [context, bucket])
		if lines.is_empty():
			_fail("%s roasts.%s must contain at least one non-empty Roast." % [context, bucket])
			continue

		for line in lines:
			if _looks_like_placeholder(line):
				_fail("%s roasts.%s contains placeholder text." % [context, bucket])


func _validate_template_contract(template: String, rules: Dictionary, solution: Dictionary, context: String) -> void:
	match template:
		"Tap Logic":
			var target_ids := _ids_from_items(rules.get("tap_targets", []), "%s rules.tap_targets" % context)
			_require_solution_id(solution, "target_id", target_ids, context)
		"Drag Logic":
			var object_ids := _ids_from_items(rules.get("draggable_objects", []), "%s rules.draggable_objects" % context)
			var drop_target_ids := _ids_from_items(rules.get("drop_targets", []), "%s rules.drop_targets" % context)
			_require_solution_id(solution, "object_id", object_ids, context)
			_require_solution_id(solution, "drop_target_id", drop_target_ids, context)
		"Text Trap":
			var accepted_inputs := _string_array_from(rules.get("accepted_inputs", []), "%s rules.accepted_inputs" % context)
			var answer := str(solution.get("answer", "")).strip_edges()
			if accepted_inputs.is_empty():
				_fail("%s rules.accepted_inputs must contain at least one answer." % context)
			if answer.is_empty():
				_fail("%s solution.answer must be a non-empty string." % context)
			elif not _normalized_array_has(accepted_inputs, answer):
				_fail("%s solution.answer must be included in rules.accepted_inputs." % context)
		"Pattern Grid":
			var cell_ids := _ids_from_items(rules.get("cells", []), "%s rules.cells" % context)
			_require_solution_id(solution, "cell_id", cell_ids, context)
		"Memory Flash":
			var flash_items := _string_array_from(rules.get("flash_items", []), "%s rules.flash_items" % context)
			var choices := _string_array_from(rules.get("choices", []), "%s rules.choices" % context)
			var sequence := _string_array_from(solution.get("sequence", []), "%s solution.sequence" % context)
			if flash_items.is_empty():
				_fail("%s rules.flash_items must contain at least one item." % context)
			if choices.is_empty():
				_fail("%s rules.choices must contain at least one choice." % context)
			if sequence.is_empty():
				_fail("%s solution.sequence must contain at least one item." % context)
			if not flash_items.is_empty() and not sequence.is_empty() and not _arrays_match(flash_items, sequence):
				_fail("%s solution.sequence must match rules.flash_items in order." % context)
			for item in sequence:
				if not choices.has(item):
					_fail("%s solution.sequence item %s must exist in rules.choices." % [context, item])
		"Physics Draw":
			var draw_ids := _ids_from_items(rules.get("draw_options", []), "%s rules.draw_options" % context)
			_require_solution_id(solution, "draw_id", draw_ids, context)


func _require_solution_id(solution: Dictionary, key: String, valid_ids: Array, context: String) -> void:
	var value := str(solution.get(key, "")).strip_edges()
	if value.is_empty():
		_fail("%s solution.%s must be a non-empty string." % [context, key])
	elif not valid_ids.has(value):
		_fail("%s solution.%s must reference an id present in rules." % [context, key])


func _ids_from_items(value: Variant, context: String) -> Array:
	var ids := []
	if typeof(value) != TYPE_ARRAY:
		_fail("%s must be a non-empty array." % context)
		return ids

	var items: Array = value
	if items.is_empty():
		_fail("%s must be a non-empty array." % context)
		return ids

	var seen := {}
	for index in range(items.size()):
		var item = items[index]
		if typeof(item) != TYPE_DICTIONARY:
			_fail("%s[%d] must be an object." % [context, index])
			continue

		var id := str(item.get("id", "")).strip_edges()
		if id.is_empty():
			_fail("%s[%d].id must be a non-empty string." % [context, index])
			continue
		if seen.has(id):
			_fail("%s has duplicate id %s." % [context, id])
			continue

		seen[id] = true
		ids.append(id)

	return ids


func _string_array_from(value: Variant, context: String) -> Array:
	var strings := []
	if typeof(value) != TYPE_ARRAY:
		_fail("%s must be a non-empty array." % context)
		return strings

	var values: Array = value
	if values.is_empty():
		_fail("%s must be a non-empty array." % context)
		return strings

	for index in range(values.size()):
		var text := str(values[index]).strip_edges()
		if text.is_empty():
			_fail("%s[%d] must be a non-empty string." % [context, index])
			continue
		strings.append(text)

	return strings


func _validate_no_future_placeholder(value: Variant, path: String) -> void:
	match typeof(value):
		TYPE_DICTIONARY:
			var dictionary: Dictionary = value
			for key in dictionary.keys():
				var key_text := str(key)
				if key_text == "future_placeholder":
					_fail("%s contains future_placeholder key." % path)
				_validate_no_future_placeholder(dictionary[key], "%s.%s" % [path, key_text])
		TYPE_ARRAY:
			var values: Array = value
			for index in range(values.size()):
				_validate_no_future_placeholder(values[index], "%s[%d]" % [path, index])
		TYPE_STRING:
			if str(value).strip_edges().to_lower().contains("future_placeholder"):
				_fail("%s contains future_placeholder text." % path)


func _has_nonempty_string(source: Dictionary, key: String) -> bool:
	return typeof(source.get(key, "")) == TYPE_STRING and not str(source.get(key, "")).strip_edges().is_empty()


func _dictionary_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _arrays_match(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false

	for index in range(left.size()):
		if str(left[index]) != str(right[index]):
			return false

	return true


func _normalized_array_has(values: Array, expected: String) -> bool:
	var normalized_expected := expected.strip_edges().to_lower()
	for value in values:
		if str(value).strip_edges().to_lower() == normalized_expected:
			return true
	return false


func _looks_like_placeholder(text: String) -> bool:
	var normalized := text.strip_edges().to_lower()
	return normalized.is_empty() \
		or normalized.begins_with("future ") \
		or normalized.contains("future_placeholder") \
		or normalized.contains("todo")


func _level_context(level: Dictionary, fallback_number: int) -> String:
	var level_number := fallback_number
	if _is_number(level.get("level_number", null)):
		level_number = int(level.get("level_number", fallback_number))

	var level_id := str(level.get("id", "")).strip_edges()
	if level_id.is_empty():
		return "Level %d" % level_number
	return "Level %d (%s)" % [level_number, level_id]


func _fail(message: String) -> void:
	_errors.append(message)


func _finish() -> void:
	if _errors.is_empty():
		print("Issue #8 Pack 2 spec verification passed: %d Level Specs, %s, Levels %d-%d, supported templates, scoring, Roasts, unique ids, and UQIQ Moments." % [
			EXPECTED_LEVEL_COUNT,
			EXPECTED_PACK_ID,
			FIRST_LEVEL_NUMBER,
			FIRST_LEVEL_NUMBER + EXPECTED_LEVEL_COUNT - 1,
		])
		quit(0)
		return

	for message in _errors:
		push_error(message)
	print("Issue #8 Pack 2 spec verification failed: %d error(s)." % _errors.size())
	quit(1)
