extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_42_pattern_grid_interaction_profile.json"

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

	_verify_direct_pattern_grid()
	if _failed:
		return

	print("Issue #42 Pattern Grid verification passed: Level 4 renders a direct mark-grid interaction, rejects a wrong row, and completes from marked grid state.")
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_direct_pattern_grid() -> void:
	var level := _level_by_number(4)
	var level_id := str(level.get("id", ""))

	_main.call("_show_play_screen", level)
	_require(_node_named(_main, "pattern_mark_grid") != null, "Pattern Grid should render a direct mark-grid container.")
	_require(_node_named(_main, "pattern_mark_cell_r2c2") != null, "Pattern Grid should render named markable cells.")
	_require(_screen_has_label_text("Grid unmarked."), "Pattern Grid should start with positive ready-state feedback.")
	_require(not _screen_has_label_text("Tap the cell that breaks the pattern."), "Direct Pattern Grid should not repeat instruction copy above the grid.")
	_require(not _screen_has_label_text("Mark the whole broken set."), "Direct Pattern Grid should not repeat multi-mark instruction copy above the grid.")
	_require(not _screen_has_label_text("No cells marked."), "Pattern Grid should not render old negative idle feedback.")
	_require(not _has_button_text(_main, "Submit Pattern"), "Direct Pattern Grid should not use Submit Pattern as the primary interaction.")

	_press_cells(["r1c1"])
	_press_cells(["r1c1"])
	var marked_after_toggle: Array = _main.get("_pattern_marked_cells")
	_require(marked_after_toggle.is_empty(), "Tapping a marked Pattern Grid cell again should unmark it.")
	_require(_screen_has_label_text("Grid unmarked."), "Unmarking the last Pattern Grid cell should restore the ready-state feedback.")

	_main.call("_show_play_screen", level)
	_press_cells(["r1c1", "r1c2", "r1c3"])
	_require(not _profile.is_level_completed(level_id), "Wrong marked row should not complete Level 4.")
	_require(int(_main.get("_tap_count")) == 3, "Wrong row should count one action per marked cell.")
	var marked_after_wrong: Array = _main.get("_pattern_marked_cells")
	_require(marked_after_wrong.is_empty(), "Wrong full Pattern Grid set should clear marks for a clean retry.")
	_require(_pattern_cells_have_border(["r1c1", "r1c2", "r1c3"], Color(0.95, 0.22, 0.24)), "Wrong full Pattern Grid set should frame the rejected row as a fail state.")

	_main.call("_show_play_screen", level)
	_press_cells(["r2c1", "r2c2", "r2c3"])
	_require(_profile.is_level_completed(level_id), "Marked broken row should complete Level 4.")
	_require(_screen_has_label_text("Score Roastcard"), "Marked broken row should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 3, "Three marked cells should persist as three actions.")


func _press_cells(cell_ids: Array[String]) -> void:
	for cell_id in cell_ids:
		var button := _node_named(_main, "pattern_mark_cell_%s" % cell_id) as Button
		_require(button != null, "Expected markable Pattern Grid cell %s." % cell_id)
		if _failed:
			return
		button.emit_signal("pressed")


func _pattern_cells_have_border(cell_ids: Array[String], expected_color: Color) -> bool:
	for cell_id in cell_ids:
		var button := _node_named(_main, "pattern_mark_cell_%s" % cell_id) as Button
		_require(button != null, "Expected markable Pattern Grid cell %s." % cell_id)
		if button == null:
			return false
		var border_color := _button_border_color(button)
		if not border_color.is_equal_approx(expected_color):
			_require(false, "Pattern Grid cell %s border %s should match %s." % [cell_id, border_color, expected_color])
			return false
	return true


func _button_border_color(button: Button) -> Color:
	var style := button.get_theme_stylebox("normal") as StyleBoxFlat
	_require(style != null, "Expected framed Pattern Grid cell style.")
	if style == null:
		return Color.TRANSPARENT
	return style.border_color


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


func _node_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var match := _node_named(child, node_name)
		if match != null:
			return match
	return null


func _has_button_text(node: Node, text: String) -> bool:
	if node is Button and str(node.text) == text:
		return true
	for child in node.get_children():
		if _has_button_text(child, text):
			return true
	return false


func _screen_has_label_text(text: String) -> bool:
	return _node_has_label_text(_main, text)


func _node_has_label_text(node: Node, text: String) -> bool:
	if node is Label and str(node.text).contains(text):
		return true
	for child in node.get_children():
		if _node_has_label_text(child, text):
			return true
	return false


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
