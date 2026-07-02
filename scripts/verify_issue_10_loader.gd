extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")

const PACK_1_ID := "pack_01_orientation_is_a_trap"
const PACK_2_ID := "pack_02_words_are_lying"
const REQUIRED_PREFIX_LEVEL_COUNT := 20

var _errors := []


func _initialize() -> void:
	var loader := LevelLoaderScript.new()

	var pack_1 := loader.load_pack()
	_require(not pack_1.is_empty(), loader.last_error)
	_require(_levels(pack_1).size() == 10, "load_pack() should keep Pack 1 at exactly 10 Level Specs.")
	_require(not loader.find_level_by_number(pack_1, 1).is_empty(), "load_pack() should find Pack 1 Level 1.")
	_require(loader.find_level_by_number(pack_1, 11).is_empty(), "load_pack() should not include Pack 2 Levels.")

	var combined := loader.load_default_packs()
	_require(not combined.is_empty(), loader.last_error)
	var levels := _levels(combined)
	var packs := _packs(combined)
	_require(levels.size() >= REQUIRED_PREFIX_LEVEL_COUNT, "load_default_packs() should include at least Levels 1-20; found %d Level Specs." % levels.size())
	_require(int(combined.get("level_count", 0)) == levels.size(), "Combined pack metadata should match the loaded Level Spec count.")
	_require(packs.size() >= 2, "Combined pack metadata should include at least Pack 1 and Pack 2.")

	for index in range(mini(levels.size(), REQUIRED_PREFIX_LEVEL_COUNT)):
		var expected_level_number := index + 1
		_require(int(levels[index].get("level_number", 0)) == expected_level_number, "Combined Levels should keep Levels 1-20 ordered as the default prefix.")
		_require(not loader.find_level_by_number(combined, expected_level_number).is_empty(), "Combined pack should find Level %d." % expected_level_number)

	if packs.size() >= 2:
		_require(str(packs[0].get("pack_id", "")) == PACK_1_ID, "First pack metadata should describe Pack 1.")
		_require(int(packs[0].get("first_level_number", 0)) == 1, "Pack 1 metadata should start at Level 1.")
		_require(int(packs[0].get("last_level_number", 0)) == 10, "Pack 1 metadata should end at Level 10.")
		_require(str(packs[1].get("pack_id", "")) == PACK_2_ID, "Second pack metadata should describe Pack 2.")
		_require(int(packs[1].get("first_level_number", 0)) == 11, "Pack 2 metadata should start at Level 11.")
		_require(int(packs[1].get("last_level_number", 0)) == 20, "Pack 2 metadata should end at Level 20.")

	_finish(levels.size(), packs.size())


func _levels(pack: Dictionary) -> Array:
	var levels = pack.get("levels", [])
	if typeof(levels) == TYPE_ARRAY:
		return levels
	return []


func _packs(pack: Dictionary) -> Array:
	var packs = pack.get("packs", [])
	if typeof(packs) == TYPE_ARRAY:
		return packs
	return []


func _require(condition: bool, message: String) -> void:
	if condition:
		return

	_errors.append(message)


func _finish(default_level_count: int, default_pack_count: int) -> void:
	if _errors.is_empty():
		print("Issue #10 loader verification passed: load_pack() preserved Pack 1; load_default_packs() includes Pack 1/2 prefix Levels 1-20 within %d default Level Specs across %d Packs." % [
			default_level_count,
			default_pack_count,
		])
		quit(0)
		return

	for message in _errors:
		push_error(message)
	print("Issue #10 loader verification failed: %d error(s)." % _errors.size())
	quit(1)
