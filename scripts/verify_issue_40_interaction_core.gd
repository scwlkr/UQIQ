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

	print("Issue #40 interaction core verification passed: Drag Logic uses a direct drag/drop playfield with failed-drop bounce-back, Physics Draw resolves from a direct draw-release surface, and both complete through Score Roastcard.")
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
	_require(_screen_has_label_text("Loose claims"), "Drag Logic should render the playfield with in-world state copy.")
	_require(not _screen_has_label_text("Drag the word into a box."), "Direct Drag Logic should not repeat instruction copy above the playfield.")
	_require(not _screen_has_label_text("drag tiles to drop zones"), "Drag Logic should not render old instruction-like playfield copy.")
	_require(_screen_has_label_text("Tile ready."), "Drag Logic should start with positive ready-state feedback.")
	_require(not _screen_has_label_text("No tile moving."), "Drag Logic should not render old negative idle feedback.")
	_require(not _has_button_prefix(_main, "Move:"), "Drag Logic should not expose Move: choice buttons as the primary interaction.")
	_require(not _has_button_prefix(_main, "Drop on:"), "Drag Logic should not expose Drop on: choice buttons as the primary interaction.")

	_release_tile_into_empty_space("word_right")
	_require(_screen_has_label_text("RIGHT missed every box."), "Direct Drag Logic miss feedback should use the visible tile label.")
	_require(not _screen_has_label_text("word_right"), "Direct Drag Logic miss feedback should not leak internal object ids.")

	_main.call("_show_play_screen", level)
	_release_tile_with_tiny_overlap("word_right", "confidence_box")
	_require(not _profile.is_level_completed(level_id), "Tiny edge overlap with pointer outside should not count as a drop.")
	_require(str(_main.get("_last_drag_drop_target_id")).is_empty(), "Tiny edge overlap should leave the drop target empty.")
	_require(_screen_has_label_text("RIGHT missed every box."), "Tiny edge overlap should fall back to miss feedback.")

	_main.call("_show_play_screen", level)
	_drag_tile_to_zone("word_right", "confidence_box", "Over Confidence Box. Release to drop RIGHT.")
	_require(not _profile.is_level_completed(level_id), "Wrong direct drag/drop should not complete Level 2.")
	_require(int(_main.get("_tap_count")) == 1, "Wrong direct drag/drop should count as one direct action.")
	_require(str(_main.get("_last_failed_drag_return_id")) == "word_right", "Wrong direct drag/drop should schedule the dragged tile to return to origin.")
	_require(_screen_has_label_text("RIGHT does not belong in Confidence Box."), "Wrong direct drag/drop feedback should use visible tile and box labels.")
	_require(not _screen_has_label_text("word_right"), "Wrong direct drag/drop feedback should not leak internal object ids.")

	_main.call("_show_play_screen", level)
	_release_overlapping_tile_with_bad_pointer("word_wrong", "truth_box")
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
	_require(_physics_hint_is_secondary(), "Physics Draw hint line should read as a faint guide, not a completed player stroke.")
	_require(not _has_button_prefix(_main, "Draw:"), "Physics Draw should not expose Draw: option buttons as the primary interaction.")
	_require(_screen_has_label_text("Ramp sketch"), "Physics Draw should render the playfield with in-world state copy.")
	_require(not _screen_has_label_text("Draw toward the cup"), "Physics Draw should not render old instruction-like playfield copy.")
	_require(_screen_has_label_text("Ramp ready"), "Physics Draw should start with no selected line.")
	_require(_screen_has_label_text("Line ready."), "Physics Draw should start with positive ready-state feedback.")
	_require(not _screen_has_label_text("No ramp drawn."), "Physics Draw should not render old negative idle feedback.")

	_draw_line_on_surface(Vector2(48, 220), Vector2(54, 216))
	_require(str(_main.get("_last_physics_result")) == "short", "A tiny Physics Draw stroke should record a short-stroke state.")
	_require(str(_main.get("_physics_choice")).is_empty(), "A tiny Physics Draw stroke should not select a ramp.")
	_require(int(_main.get("_tap_count")) == 0, "A tiny Physics Draw stroke should not spend an action.")
	_require(not _profile.is_level_completed(level_id), "A tiny Physics Draw stroke should not complete Level 6.")
	_require(_screen_has_label_text("Line too short."), "A tiny Physics Draw stroke should ask for a longer line.")

	_draw_curved_line_on_surface(Vector2(48, 220), [Vector2(-120, 360), Vector2(500, -80)], Vector2(260, 220))
	_require(str(_main.get("_last_physics_result")) == "fail", "A wrong curved Physics Draw stroke should fail without completing.")
	_require(_drawn_line_point_count() >= 4, "Physics Draw should preserve a multi-point finger path instead of snapping to start/end.")
	_require(_drawn_line_points_inside_surface(), "Physics Draw should clamp off-surface finger movement inside the playfield.")
	_require(not _profile.is_level_completed(level_id), "A wrong curved Physics Draw stroke should not complete Level 6.")

	_main.call("_show_play_screen", level)
	_draw_line_on_surface(Vector2(48, 220), Vector2(260, 110))
	_require(str(_main.get("_physics_choice")) == "ramp_to_cup", "A rising line from ball to cup should classify as the ramp.")
	_require(str(_main.get("_last_physics_result")) == "success", "Correct drawn ramp release should record success state.")
	_require(_profile.is_level_completed(level_id), "Correct drawn ramp should complete Level 6.")
	_require(_screen_has_label_text("Score Roastcard"), "Correct drawn ramp should route to Score Roastcard.")
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 1, "Draw-release should persist as one direct action.")


func _drag_tile_to_zone(object_id: String, target_id: String, expected_hover_text: String = "") -> void:
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
	_require(str(_main.get("_drag_hover_target_id")) == target_id, "Dragging over a drop zone should mark it as the current hover target.")
	if not expected_hover_text.is_empty():
		_require(_screen_has_label_text(expected_hover_text), "Dragging over a drop zone should show release guidance with visible labels.")
	target_center = zone.get_global_rect().get_center()
	var release_position := tile.get_global_transform_with_canvas().affine_inverse() * target_center
	var release := _mouse_button_event(release_position, false)
	_main.call("_handle_drag_tile_input", release, object_id, tile)
	_require(str(_main.get("_drag_hover_target_id")).is_empty(), "Releasing a drag should clear drop-zone hover state.")


func _release_overlapping_tile_with_bad_pointer(object_id: String, target_id: String) -> void:
	var tile := _node_named(_main, "drag_tile_%s" % object_id) as Control
	var zone := _node_named(_main, "drop_zone_%s" % target_id) as Control
	_require(tile != null, "Expected draggable tile for %s." % object_id)
	_require(zone != null, "Expected drop zone for %s." % target_id)
	if _failed:
		return

	var press := _mouse_button_event(Vector2(12, 12), true)
	_main.call("_handle_drag_tile_input", press, object_id, tile)
	tile.position = zone.position
	tile.move_to_front()
	var release := _mouse_button_event(Vector2(-500, -500), false)
	_main.call("_handle_drag_tile_input", release, object_id, tile)


func _release_tile_with_tiny_overlap(object_id: String, target_id: String) -> void:
	var tile := _node_named(_main, "drag_tile_%s" % object_id) as Control
	var zone := _node_named(_main, "drop_zone_%s" % target_id) as Control
	_require(tile != null, "Expected draggable tile for %s." % object_id)
	_require(zone != null, "Expected drop zone for %s." % target_id)
	if _failed:
		return

	var press := _mouse_button_event(Vector2(12, 12), true)
	_main.call("_handle_drag_tile_input", press, object_id, tile)
	tile.position = zone.position + Vector2(zone.size.x - 2.0, 0.0)
	tile.move_to_front()
	var release := _mouse_button_event(Vector2(-500, -500), false)
	_main.call("_handle_drag_tile_input", release, object_id, tile)


func _release_tile_into_empty_space(object_id: String) -> void:
	var tile := _node_named(_main, "drag_tile_%s" % object_id) as Control
	_require(tile != null, "Expected draggable tile for %s." % object_id)
	if _failed:
		return

	var press := _mouse_button_event(Vector2(12, 12), true)
	_main.call("_handle_drag_tile_input", press, object_id, tile)
	var release := _mouse_button_event(Vector2(-500, -500), false)
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


func _draw_curved_line_on_surface(start: Vector2, midpoints: Array, end: Vector2) -> void:
	var surface := _node_named(_main, "physics_draw_surface") as Control
	_require(surface != null, "Expected physics drawing surface.")
	if _failed:
		return

	_main.call("_handle_physics_surface_input", _mouse_button_event(start, true), surface)
	for midpoint in midpoints:
		var motion := InputEventMouseMotion.new()
		motion.position = midpoint
		_main.call("_handle_physics_surface_input", motion, surface)
	var release := _mouse_button_event(end, false)
	_main.call("_handle_physics_surface_input", release, surface)


func _drawn_line_point_count() -> int:
	var line := _node_named(_main, "player_drawn_line") as Line2D
	_require(line != null, "Expected Physics Draw player line.")
	if line == null:
		return 0
	return line.points.size()


func _drawn_line_points_inside_surface() -> bool:
	var surface := _node_named(_main, "physics_draw_surface") as Control
	var line := _node_named(_main, "player_drawn_line") as Line2D
	_require(surface != null, "Expected Physics Draw surface.")
	_require(line != null, "Expected Physics Draw player line.")
	if surface == null or line == null:
		return false

	var bounds := surface.size
	if bounds.x <= 0.0:
		bounds.x = maxf(surface.custom_minimum_size.x, 320.0)
	if bounds.y <= 0.0:
		bounds.y = maxf(surface.custom_minimum_size.y, 280.0)

	for point in line.points:
		if point.x < -0.01 or point.y < -0.01 or point.x > bounds.x + 0.01 or point.y > bounds.y + 0.01:
			return false

	return true


func _physics_hint_is_secondary() -> bool:
	var hint := _node_named(_main, "physics_draw_hint_line") as Line2D
	var player := _node_named(_main, "player_drawn_line") as Line2D
	_require(hint != null, "Expected Physics Draw hint line.")
	_require(player != null, "Expected Physics Draw player line.")
	if hint == null or player == null:
		return false
	return hint.default_color.a <= 0.24 and hint.width < player.width


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
