extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")
const TEST_SAVE_PATH := "user://issue_41_pack_6_direct_drawing_profile.json"

var _loader := LevelLoaderScript.new()
var _pack_set := {}
var _main: Control
var _profile: RefCounted
var _failed := false
var _verified_levels := 0


func _initialize() -> void:
	_remove_test_save()
	_pack_set = _loader.load_default_packs()
	_require(not _pack_set.is_empty(), _loader.last_error)
	if _failed:
		return

	_boot_main_scene()
	if _failed:
		return

	for level in _pack_6_physics_levels():
		_verify_direct_drawing_level(level)
		if _failed:
			return

	_require(_verified_levels == 8, "Pack 6 should verify eight Physics Draw levels.")

	print("Issue #41 Pack 6 direct drawing verification passed: %d Physics Draw levels render direct drawing surfaces, reject a bad line, and complete via their encoded gestures." % _verified_levels)
	_cleanup()
	quit(0)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _pack_6_physics_levels() -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	for level_number in [51, 52, 53, 54, 56, 57, 59, 60]:
		var level := _loader.find_level_by_number(_pack_set, int(level_number))
		_require(not level.is_empty(), "Level %d should exist in default packs." % int(level_number))
		_require(str(level.get("template", "")) == "Physics Draw", "Level %d should be Physics Draw." % int(level_number))
		levels.append(level)
	return levels


func _verify_direct_drawing_level(level: Dictionary) -> void:
	var level_number := int(level.get("level_number", 0))
	var level_id := str(level.get("id", ""))
	var rules := _dictionary_from(level.get("rules", {}))
	var solution := _dictionary_from(level.get("solution", {}))
	var gesture := str(rules.get("direct_draw_gesture", ""))
	var correct_draw_id := str(solution.get("draw_id", ""))
	_require(not gesture.is_empty(), "Level %d should declare direct_draw_gesture." % level_number)
	if _failed:
		return

	_main.call("_show_play_screen", level)
	_require(_node_named(_main, "physics_draw_surface") != null, "Level %d should render a direct drawing surface." % level_number)
	_require(_node_named(_main, "player_drawn_line") != null, "Level %d should render the player's line." % level_number)
	_require(not _has_button_prefix(_main, "Draw:"), "Level %d should not expose Draw: fallback buttons." % level_number)

	_draw_line_on_surface(Vector2(30, 220), Vector2(48, 222))
	_require(str(_main.get("_physics_choice")) != correct_draw_id, "Level %d bad short line should not classify as correct." % level_number)
	_main.call("_handle_physics_release")
	_require(not _profile.is_level_completed(level_id), "Level %d bad line should not complete." % level_number)

	_main.call("_show_play_screen", level)
	_draw_line_on_surface(_gesture_start(gesture), _gesture_end(gesture))
	_require(str(_main.get("_physics_choice")) == correct_draw_id, "Level %d correct gesture should classify as %s." % [level_number, correct_draw_id])
	_main.call("_handle_physics_release")
	_require(_profile.is_level_completed(level_id), "Level %d correct gesture should complete." % level_number)
	_require(_screen_has_label_text("Score Roastcard"), "Level %d completion should route to Score Roastcard." % level_number)
	var best_attempt: Dictionary = _profile.get_best_attempt(level_id)
	_require(int(best_attempt.get("action_count", 0)) == 2, "Level %d draw plus release should persist as two actions." % level_number)
	_verified_levels += 1


func _gesture_start(gesture: String) -> Vector2:
	match gesture:
		"high_bridge":
			return Vector2(44, 92)
		"rising_vertical":
			return Vector2(152, 228)
		"right_flat":
			return Vector2(42, 152)
		"balloon_hook":
			return Vector2(132, 232)
		"falling_slope":
			return Vector2(44, 92)
		"shallow_rise":
			return Vector2(42, 176)
		_:
			return Vector2(48, 220)


func _gesture_end(gesture: String) -> Vector2:
	match gesture:
		"high_bridge":
			return Vector2(264, 98)
		"rising_vertical":
			return Vector2(162, 84)
		"right_flat":
			return Vector2(266, 156)
		"balloon_hook":
			return Vector2(184, 88)
		"falling_slope":
			return Vector2(264, 214)
		"shallow_rise":
			return Vector2(266, 140)
		_:
			return Vector2(260, 110)


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


func _dictionary_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


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
