extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_40_interaction_core_profile.json"

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

	_verify_direct_drag_drop()
	if _failed:
		return

	_verify_direct_physics_draw()
	if _failed:
		return

	print("Issue #40 interaction core verification passed: Drag Logic uses a direct drag/drop playfield, Physics Draw uses a direct draw surface, and both complete through Score Roastcard.")
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _verify_direct_drag_drop() -> void:
	var level := _level_by_number(2)
	var level_id := str(level.get("id", ""))
	_main.call("_show_play_screen", level)

	_require(_node_named(_main, "drag_playfield") != null, "Drag Logic should render a named direct-manipulation playfield.")
	_require(_node_named(_main, "drag_tile_word_wrong") != null, "Drag Logic should render the correct word as a draggable tile.")
	_require(_node_named(_main, "drop_zone_truth_box") != null, "Drag Logic should render the Truth Box as a drop zone.")
	_require(not _has_button_prefix(_main, "Move:"), "Drag Logic should not expose Move: choice buttons as the primary interaction.")
	_require(not _has_button_prefix(_main, "Drop on:"), "Drag Logic should not expose Drop on: choice buttons as the primary interaction.")

	_drag_tile_to_zone("word_right", "confidence_box")
	_require(not _profile.is_level_completed(level_id), "Wrong direct drag/drop should not complete Level 2.")
	_require(int(_main.get("_tap_count")) == 1, "Wrong direct drag/drop should count as one direct action.")

	_main.call("_show_play_screen", level)
	_drag_tile_to_zone("word_wrong", "truth_box")
	_require(_profile.is_level_completed(level_id), "Correct direct drag/drop should complete Level 2.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct direct drag/drop should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 1, "Correct direct drag/drop should persist as one direct action.")


func _verify_direct_physics_draw() -> void:
	var level := _level_by_number(6)
	var level_id := str(level.get("id", ""))
	_main.call("_show_play_screen", level)

	_require(_node_named(_main, "physics_draw_surface") != null, "Physics Draw should render a named direct drawing surface.")
	_require(_node_named(_main, "player_drawn_line") != null, "Physics Draw should render the player's drawn line.")
	_require(not _has_button_prefix(_main, "Draw:"), "Physics Draw should not expose Draw: option buttons as the primary interaction.")
	_require(_screen_has_label_text("Selected line: none"), "Physics Draw should start with no selected line.")

	_draw_line_on_surface(Vector2(48, 220), Vector2(260, 110))
	_require(str(_main.get("_physics_choice")) == "ramp_to_cup", "A rising line from ball to cup should classify as the ramp.")
	_require(str(_main.get("_last_physics_result")) == "selected", "Drawing a line should record selected state before release.")
	_require(_screen_has_label_text("Selected line: ramp to cup"), "Physics Draw should show the classified drawn ramp.")

	_main.call("_handle_physics_release")
	_require(str(_main.get("_last_physics_result")) == "success", "Correct drawn ramp release should record success state.")
	_require(_profile.is_level_completed(level_id), "Correct drawn ramp should complete Level 6.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct drawn ramp should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 2, "Draw plus release should persist as two actions.")


func _drag_tile_to_zone(object_id: String, target_id: String) -> void:
	var tile := _node_named(_main, "drag_tile_%s" % object_id) as Control
	var zone := _node_named(_main, "drop_zone_%s" % target_id) as Control
	_require(tile != null, "Expected draggable tile for %s." % object_id)
	_require(zone != null, "Expected drop zone for %s." % target_id)
	if _failed:
		return

	var press := _mouse_button_event(Vector2(12, 12), true)
	_main.call("_handle_drag_tile_input", press, object_id, tile)
	var target_center := zone.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = tile.get_global_transform_with_canvas().affine_inverse() * target_center
	_main.call("_handle_drag_tile_input", motion, object_id, tile)
	target_center = zone.get_global_rect().get_center()
	var release_position := tile.get_global_transform_with_canvas().affine_inverse() * target_center
	var release := _mouse_button_event(release_position, false)
	_main.call("_handle_drag_tile_input", release, object_id, tile)


func _draw_line_on_surface(start: Vector2, end: Vector2) -> void:
	var surface := _node_named(_main, "physics_draw_surface") as Control
	_require(surface != null, "Expected physics drawing surface.")
	if _failed:
		return

	_main.call("_handle_physics_surface_input", _mouse_button_event(start, true), surface)
	var motion := InputEventMouseMotion.new()
	motion.position = end
	_main.call("_handle_physics_surface_input", motion, surface)
	_main.call("_handle_physics_surface_input", _mouse_button_event(end, false), surface)


func _mouse_button_event(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	return event


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


func _has_button_prefix(node: Node, prefix: String) -> bool:
	if node is Button and str(node.text).begins_with(prefix):
		return true
	for child in node.get_children():
		if _has_button_prefix(child, prefix):
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
