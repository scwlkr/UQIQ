extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")


func _initialize() -> void:
	var loader := LevelLoaderScript.new()

	var pack_1 := loader.load_pack()
	_require(not pack_1.is_empty(), loader.last_error)
	_require(_levels(pack_1).size() == 10, "load_pack() should keep Pack 1 at exactly 10 Level Specs.")
	_require(not loader.find_level_by_number(pack_1, 1).is_empty(), "load_pack() should find Pack 1 Level 1.")
	_require(loader.find_level_by_number(pack_1, 11).is_empty(), "load_pack() should not include Pack 2 Levels.")

	var combined := loader.load_default_packs()
	_require(not combined.is_empty(), loader.last_error)
	_require(_levels(combined).size() == 20, "load_default_packs() should load 20 Level Specs.")
	_require(int(combined.get("level_count", 0)) == 20, "Combined pack metadata should report 20 Level Specs.")
	_require(_packs(combined).size() == 2, "Combined pack metadata should include Pack 1 and Pack 2.")

	var levels := _levels(combined)
	for index in range(levels.size()):
		var expected_level_number := index + 1
		_require(int(levels[index].get("level_number", 0)) == expected_level_number, "Combined Levels should be ordered 1-20.")
		_require(not loader.find_level_by_number(combined, expected_level_number).is_empty(), "Combined pack should find Level %d." % expected_level_number)

	var packs := _packs(combined)
	_require(str(packs[0].get("pack_id", "")) == "pack_01_orientation_is_a_trap", "First pack metadata should describe Pack 1.")
	_require(int(packs[0].get("first_level_number", 0)) == 1, "Pack 1 metadata should start at Level 1.")
	_require(int(packs[0].get("last_level_number", 0)) == 10, "Pack 1 metadata should end at Level 10.")
	_require(str(packs[1].get("pack_id", "")) == "pack_02_words_are_lying", "Second pack metadata should describe Pack 2.")
	_require(int(packs[1].get("first_level_number", 0)) == 11, "Pack 2 metadata should start at Level 11.")
	_require(int(packs[1].get("last_level_number", 0)) == 20, "Pack 2 metadata should end at Level 20.")

	print("Issue #10 loader verification passed: load_pack() preserved Pack 1; load_default_packs() loads Levels 1-20 with Pack metadata.")
	quit(0)


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

	push_error(message)
	quit(1)
