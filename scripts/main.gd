extends Control

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const DeviceSmokeRunnerScript := preload("res://scripts/device_smoke_runner.gd")

const COLOR_INK := Color(0.06, 0.07, 0.09)
const COLOR_PAPER := Color(0.97, 0.95, 0.86)
const COLOR_PANEL := Color(0.12, 0.13, 0.16)
const COLOR_PANEL_ALT := Color(0.18, 0.20, 0.24)
const COLOR_YELLOW := Color(1.00, 0.78, 0.15)
const COLOR_GREEN := Color(0.30, 0.82, 0.50)
const COLOR_RED := Color(0.95, 0.22, 0.24)
const COLOR_BLUE := Color(0.12, 0.58, 0.92)
const COLOR_ORANGE := Color(0.96, 0.43, 0.13)
const COLOR_TEXT := Color(0.98, 0.98, 0.96)
const COLOR_MUTED := Color(0.73, 0.75, 0.76)
const SCREEN_MARGIN_X := 20
const SCREEN_MARGIN_Y := 22
const DEVICE_SMOKE_ARG := "--uqiq-device-smoke"
const DEVICE_SMOKE_ENV := "UQIQ_DEVICE_SMOKE"
const PLAYTEST_LEVEL_ENV := "UQIQ_PLAYTEST_LEVEL"
const PLAYTEST_UNLOCK_ALL_ENV := "UQIQ_PLAYTEST_UNLOCK_ALL"
const FEEDBACK_MIX_RATE := 22050.0
const SUPPORTED_LEVEL_TEMPLATES := [
	"Tap Logic",
	"Drag Logic",
	"Text Trap",
	"Pattern Grid",
	"Memory Flash",
	"Memory/Reveal Level",
	"Physics Draw",
	"Rearrange Level",
]

var _loader := LevelLoaderScript.new()
var _profile := LocalProfileScript.new()
var _pack := {}
var _packs: Array = []
var _current_level := {}
var _tap_count := 0
var _roast_count := 0
var _last_best_attempt := {}
var _last_completed_attempt := {}
var _last_score_result := {}
var _level_list_notice := ""
var _level_started_at_msec := 0
var _last_direct_tap_target_id := ""
var _feedback_counts := {}
var _last_feedback_kind := ""
var _feedback_player: AudioStreamPlayer
var _feedback_generator: AudioStreamGenerator
var _judge_state := ""
var _judge_state_counts := {}
var _judge_face_label: Label
var _judge_caption_label: Label
var _transition_counts := {}
var _last_transition_name := ""
var _feedback_label: Label
var _text_input: LineEdit
var _text_keyboard_request_count := 0
var _last_text_keyboard_rect := Rect2()
var _last_text_focus_event_was_touch := false
var _direct_text_answer_label: Label
var _last_direct_text_tile_id := ""
var _selected_drag_id := ""
var _dragging_object_id := ""
var _dragging_tile: Control = null
var _drag_offset := Vector2.ZERO
var _drag_drop_zones := {}
var _last_drag_drop_target_id := ""
var _selected_pattern_cell := ""
var _pattern_marked_cells: Array[String] = []
var _pattern_cell_buttons := {}
var _memory_input: Array[String] = []
var _memory_slot_labels := {}
var _last_direct_memory_tile_id := ""
var _last_direct_memory_press_item_id := ""
var _last_direct_memory_press_msec := -1000
var _last_direct_memory_press_was_touch := false
var _physics_choice := ""
var _last_physics_result := ""
var _physics_choice_label: Label
var _physics_result_label: Label
var _physics_draw_surface: Control = null
var _physics_line: Line2D = null
var _physics_is_drawing := false
var _physics_has_drawn_line := false
var _physics_draw_start := Vector2.ZERO
var _physics_draw_end := Vector2.ZERO
var _freehand_physics_runtime: Node2D = null
var _freehand_stroke_body: StaticBody2D = null
var _freehand_built_in_body: StaticBody2D = null
var _freehand_ball_body: RigidBody2D = null
var _freehand_goal_area: Area2D = null
var _freehand_ball_visual: Control = null
var _freehand_cup_visual: Control = null
var _freehand_built_in_lines: Array[Line2D] = []
var _freehand_stroke_points: Array[Vector2] = []
var _freehand_ball_start := Vector2.ZERO
var _freehand_last_ball_position := Vector2.ZERO
var _freehand_ball_moved := false
var _reveal_visible := false
var _reveal_optional_reveals_remaining := 0
var _reveal_button: Button = null
var _reveal_hide_at_msec := 0
var _reveal_failure_flash_count := 0
var _rearrange_physics_runtime: Node2D = null
var _rearrange_built_in_body: StaticBody2D = null
var _rearrange_ball_body: RigidBody2D = null
var _rearrange_goal_area: Area2D = null
var _rearrange_ball_visual: Control = null
var _rearrange_cup: Control = null
var _rearrange_target_hint: Control = null
var _rearrange_cup_start_rect := Rect2()
var _rearrange_cup_rect := Rect2()
var _rearrange_allowed_rect := Rect2()
var _rearrange_target_rect := Rect2()
var _rearrange_ball_start := Vector2.ZERO
var _rearrange_last_ball_position := Vector2.ZERO
var _rearrange_cup_moved := false
var _rearrange_goal_rect := Rect2()
var _rearrange_rule_tile: Control = null
var _rearrange_rule_tile_start_rect := Rect2()
var _rearrange_rule_tile_rect := Rect2()
var _rearrange_rule_tile_moved := false
var _rearrange_gravity_slots := {}
var _rearrange_selected_gravity_slot_id := ""
var _rearrange_selected_gravity_vector := Vector2.ZERO
var _rearrange_released := false
var _rearrange_ball_moved := false
var _rearrange_dragging_object_id := ""
var _rearrange_dragging_tile: Control = null
var _rearrange_drag_offset := Vector2.ZERO


func _ready() -> void:
	_setup_feedback()
	_pack = _load_level_pack_set()
	_packs = _pack_groups_from_pack_set(_pack)
	_profile.load_or_create()
	_show_level_list()
	if _should_run_device_smoke():
		call_deferred("_run_device_smoke")
	elif _debug_playtest_level_number() > 0:
		call_deferred("_show_playtest_level_from_env")


func _process(_delta: float) -> void:
	if _reveal_hide_at_msec > 0 and Time.get_ticks_msec() >= _reveal_hide_at_msec:
		_hide_memory_reveal_from_timer()


func _should_run_device_smoke() -> bool:
	if not OS.is_debug_build():
		return false
	if OS.get_cmdline_args().has(DEVICE_SMOKE_ARG):
		return true
	return OS.get_environment(DEVICE_SMOKE_ENV) == "1"


func _run_device_smoke() -> void:
	var runner = DeviceSmokeRunnerScript.new()
	_show_device_smoke_result(runner.run(self))


func _debug_playtest_level_number() -> int:
	if not OS.is_debug_build():
		return 0

	var value := OS.get_environment(PLAYTEST_LEVEL_ENV).strip_edges()
	if value.is_empty():
		return 0
	return max(0, int(value))


func _debug_playtest_unlock_all() -> bool:
	if not OS.is_debug_build():
		return false

	var value := OS.get_environment(PLAYTEST_UNLOCK_ALL_ENV).strip_edges().to_lower()
	return ["1", "true", "yes", "on"].has(value)


func _show_playtest_level_from_env() -> void:
	var level_number := _debug_playtest_level_number()
	if level_number <= 0:
		return

	var level := _loader.find_level_by_number(_pack, level_number)
	if level.is_empty():
		_level_list_notice = "Playtest Level %02d not found." % level_number
		_show_level_list()
		return

	_show_play_screen(level)


func _show_device_smoke_result(result: Dictionary) -> void:
	var success := bool(result.get("success", false))
	_set_judge_state("success" if success else "fail")
	var root := _make_screen(COLOR_INK, "device_smoke")
	_add_label(root, "Device Smoke Passed" if success else "Device Smoke Failed", 34, COLOR_GREEN if success else COLOR_RED)
	_add_judge_face(root, _judge_state)
	_add_status(root, "Physical iPhone smoke proof", COLOR_YELLOW)

	var lines = result.get("lines", [])
	if typeof(lines) == TYPE_ARRAY:
		for line in lines:
			_add_status(root, str(line), COLOR_MUTED if success else COLOR_TEXT)


func _show_level_list() -> void:
	_set_judge_state("list")
	var root := _make_screen(COLOR_INK, "level_list")

	_add_label(root, "UQIQ", 44, COLOR_YELLOW)
	_add_judge_face(root, _judge_state)

	var packs := _visible_packs()
	if packs.is_empty():
		_add_status(root, _loader.last_error, COLOR_RED)
		return

	_add_status(root, "Loaded %d Level Specs from %d Packs" % [_loaded_level_count(packs), packs.size()], COLOR_GREEN)
	_add_profile_status(root)
	if not _level_list_notice.is_empty():
		_add_status(root, _level_list_notice, COLOR_YELLOW)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for pack in packs:
		if typeof(pack) != TYPE_DICTIONARY:
			continue

		_add_pack_heading(list, pack)
		var levels: Array = pack.get("levels", [])
		for level in levels:
			if typeof(level) != TYPE_DICTIONARY:
				continue

			_add_level_row(list, level)


func _load_level_pack_set() -> Dictionary:
	if _loader.has_method("load_default_packs"):
		var loaded = _loader.call("load_default_packs")
		if typeof(loaded) == TYPE_DICTIONARY:
			return loaded

		_loader.last_error = "load_default_packs() did not return a Level Pack dictionary."
		return {}

	return _load_fallback_pack_set()


func _load_fallback_pack_set() -> Dictionary:
	var paths := LevelLoaderScript.DEFAULT_PACK_PATHS
	var packs := []
	var levels := []
	var source_paths: Array[String] = []
	for path in paths:
		var pack := _loader.load_pack(path)
		if pack.is_empty():
			return {}

		var pack_levels: Array = pack.get("levels", [])
		packs.append(_pack_metadata(pack, path, pack_levels))
		source_paths.append(path)
		for level in pack_levels:
			levels.append(level)

	return {
		"pack_id": "local_packs",
		"pack_title": "Local Level Packs",
		"packs": packs,
		"levels": levels,
		"level_count": levels.size(),
		"source_path": ", ".join(source_paths),
		"source_paths": source_paths,
	}


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


func _pack_groups_from_pack_set(pack_set: Dictionary) -> Array:
	if pack_set.is_empty():
		return []

	var pack_metadata = pack_set.get("packs", [])
	if typeof(pack_metadata) != TYPE_ARRAY or pack_metadata.is_empty():
		return [pack_set]

	var levels = pack_set.get("levels", [])
	if typeof(levels) != TYPE_ARRAY:
		return []

	var groups := []
	for metadata in pack_metadata:
		if typeof(metadata) != TYPE_DICTIONARY:
			continue

		var first_level_number := int(metadata.get("first_level_number", 0))
		var last_level_number := int(metadata.get("last_level_number", 0))
		var group: Dictionary = metadata.duplicate(true)
		var group_levels := []
		for level in levels:
			if typeof(level) != TYPE_DICTIONARY:
				continue

			var level_number := int(level.get("level_number", 0))
			if level_number >= first_level_number and level_number <= last_level_number:
				group_levels.append(level)

		group["levels"] = group_levels
		groups.append(group)

	return groups


func _visible_packs() -> Array:
	if not _packs.is_empty():
		return _packs
	if not _pack.is_empty():
		return _pack_groups_from_pack_set(_pack)
	return []


func _loaded_level_count(packs: Array) -> int:
	var count := 0
	for pack in packs:
		if typeof(pack) != TYPE_DICTIONARY:
			continue

		var levels = pack.get("levels", [])
		if typeof(levels) == TYPE_ARRAY:
			count += levels.size()

	return count


func _add_pack_heading(parent: Node, pack: Dictionary) -> void:
	var heading := _new_label(_pack_heading_text(pack), 20, COLOR_TEXT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(heading)

	var source_path := str(pack.get("source_path", ""))
	if not source_path.is_empty():
		var source_label := _new_label(source_path, 13, COLOR_MUTED)
		source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		parent.add_child(source_label)


func _pack_heading_text(pack: Dictionary) -> String:
	var levels = pack.get("levels", [])
	var first_level_number := 0
	var last_level_number := 0
	if typeof(levels) == TYPE_ARRAY and not levels.is_empty():
		for level in levels:
			if typeof(level) != TYPE_DICTIONARY:
				continue

			var level_number := int(level.get("level_number", 0))
			if level_number <= 0:
				continue

			if first_level_number == 0 or level_number < first_level_number:
				first_level_number = level_number
			if level_number > last_level_number:
				last_level_number = level_number

	var pack_number := 1
	if first_level_number > 0:
		pack_number = int((first_level_number - 1) / 10) + 1

	var title := str(pack.get("pack_title", "Untitled Pack"))
	if first_level_number > 0 and last_level_number >= first_level_number:
		return "Pack %d: %s | Levels %02d-%02d" % [pack_number, title, first_level_number, last_level_number]
	return "Pack %d: %s" % [pack_number, title]


func _add_level_row(parent: Node, level: Dictionary) -> void:
	var level_number := int(level.get("level_number", 0))
	var title := str(level.get("title", "Untitled"))
	var is_playable := _is_level_playable(level)
	var button_text := "%02d  %s  |  %s" % [level_number, title, _level_state_text(level)]
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var button := _make_button(button_text, _level_button_color(level))
	button.disabled = not is_playable
	button.pressed.connect(Callable(self, "_show_play_screen").bind(level))
	row.add_child(button)

	var dur_button := _make_button("DUR", COLOR_ORANGE, Vector2(76, 58))
	dur_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	dur_button.disabled = not _is_supported_playable_level_spec(level) or not _profile.can_spend_dur_token(level)
	dur_button.pressed.connect(Callable(self, "_handle_dur_level").bind(level))
	row.add_child(dur_button)


func _show_play_screen(level: Dictionary) -> void:
	_cancel_memory_reveal_timer()
	_current_level = level
	_tap_count = 0
	_roast_count = 0
	_level_started_at_msec = Time.get_ticks_msec()
	_set_judge_state("start")
	_last_best_attempt = {}
	_last_completed_attempt = {}
	_last_score_result = {}
	_level_list_notice = ""
	_text_input = null
	_text_keyboard_request_count = 0
	_last_text_keyboard_rect = Rect2()
	_last_text_focus_event_was_touch = false
	_direct_text_answer_label = null
	_last_direct_text_tile_id = ""
	_last_direct_tap_target_id = ""
	_selected_drag_id = ""
	_dragging_object_id = ""
	_dragging_tile = null
	_drag_offset = Vector2.ZERO
	_drag_drop_zones = {}
	_last_drag_drop_target_id = ""
	_selected_pattern_cell = ""
	_pattern_marked_cells = []
	_pattern_cell_buttons = {}
	_memory_input = []
	_memory_slot_labels = {}
	_last_direct_memory_tile_id = ""
	_last_direct_memory_press_item_id = ""
	_last_direct_memory_press_msec = -1000
	_last_direct_memory_press_was_touch = false
	_physics_choice = ""
	_last_physics_result = ""
	_physics_choice_label = null
	_physics_result_label = null
	_physics_draw_surface = null
	_physics_line = null
	_physics_is_drawing = false
	_physics_has_drawn_line = false
	_physics_draw_start = Vector2.ZERO
	_physics_draw_end = Vector2.ZERO
	_freehand_physics_runtime = null
	_freehand_stroke_body = null
	_freehand_built_in_body = null
	_freehand_ball_body = null
	_freehand_goal_area = null
	_freehand_ball_visual = null
	_freehand_cup_visual = null
	_freehand_built_in_lines = []
	_freehand_stroke_points = []
	_freehand_ball_start = Vector2.ZERO
	_freehand_last_ball_position = Vector2.ZERO
	_freehand_ball_moved = false
	_reveal_visible = false
	_reveal_optional_reveals_remaining = 0
	_reveal_button = null
	_reveal_hide_at_msec = 0
	_reveal_failure_flash_count = 0
	_rearrange_physics_runtime = null
	_rearrange_built_in_body = null
	_rearrange_ball_body = null
	_rearrange_goal_area = null
	_rearrange_ball_visual = null
	_rearrange_cup = null
	_rearrange_target_hint = null
	_rearrange_cup_start_rect = Rect2()
	_rearrange_cup_rect = Rect2()
	_rearrange_allowed_rect = Rect2()
	_rearrange_target_rect = Rect2()
	_rearrange_ball_start = Vector2.ZERO
	_rearrange_last_ball_position = Vector2.ZERO
	_rearrange_cup_moved = false
	_rearrange_goal_rect = Rect2()
	_rearrange_rule_tile = null
	_rearrange_rule_tile_start_rect = Rect2()
	_rearrange_rule_tile_rect = Rect2()
	_rearrange_rule_tile_moved = false
	_rearrange_gravity_slots = {}
	_rearrange_selected_gravity_slot_id = ""
	_rearrange_selected_gravity_vector = Vector2.ZERO
	_rearrange_released = false
	_rearrange_ball_moved = false
	_rearrange_dragging_object_id = ""
	_rearrange_dragging_tile = null
	_rearrange_drag_offset = Vector2.ZERO

	var root := _make_screen(COLOR_PANEL, "play_screen", true)

	var top_bar := HBoxContainer.new()
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_theme_constant_override("separation", 12)
	root.add_child(top_bar)

	var back_button := _make_button("<", COLOR_INK, Vector2(48, 48))
	back_button.pressed.connect(Callable(self, "_show_level_list"))
	top_bar.add_child(back_button)

	var level_label := Label.new()
	level_label.text = "Level %02d" % int(level.get("level_number", 0))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", COLOR_TEXT)
	top_bar.add_child(level_label)

	var score_label := Label.new()
	score_label.text = "UQIQ %d" % _profile.current_uqiq_score()
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.add_theme_color_override("font_color", COLOR_YELLOW)
	top_bar.add_child(score_label)

	var token_label := Label.new()
	token_label.text = "Dur %d" % _profile.dur_tokens()
	token_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	token_label.add_theme_font_size_override("font_size", 16)
	token_label.add_theme_color_override("font_color", COLOR_ORANGE)
	top_bar.add_child(token_label)

	_add_label(root, str(level.get("title", "Untitled")), 30, COLOR_TEXT)
	_add_label(root, str(level.get("prompt", "")), 19, COLOR_MUTED)
	if _profile.is_level_durd(str(level.get("id", ""))):
		_add_status(root, "DUR'D: finish this Level to recover 1 Dur Token.", COLOR_YELLOW)
	_add_judge_face(root, _judge_state)

	var stage := PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", _flat_box(COLOR_PAPER, 8))
	root.add_child(stage)

	var stage_box := VBoxContainer.new()
	stage_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_box.add_theme_constant_override("separation", 14)
	stage.add_child(stage_box)

	_render_level_stage(stage_box, level)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)

	var roast_button := _make_button("Roast", COLOR_ORANGE)
	roast_button.pressed.connect(Callable(self, "_handle_roast_action"))
	actions.add_child(roast_button)


func _handle_tap_target(target_id: String) -> void:
	_tap_count += 1
	_trigger_feedback("tap")

	var solution = _current_level.get("solution", {})
	var winning_target := ""
	if typeof(solution) == TYPE_DICTIONARY:
		winning_target = str(solution.get("target_id", ""))

	if not winning_target.is_empty() and target_id == winning_target:
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Nope. Your finger has executive dysfunction.")
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _handle_drag_select(object_id: String) -> void:
	_tap_count += 1
	_trigger_feedback("tap")
	_selected_drag_id = object_id
	_feedback_label.text = "Holding %s. Now move it somewhere questionable." % object_id


func _handle_drag_drop(drop_target_id: String) -> void:
	_tap_count += 1
	_trigger_feedback("tap")
	_resolve_drag_drop(_selected_drag_id, drop_target_id)


func _handle_direct_drag_drop(object_id: String, drop_target_id: String) -> void:
	_tap_count += 1
	_trigger_feedback("tap")
	_selected_drag_id = object_id
	_last_drag_drop_target_id = drop_target_id
	_resolve_drag_drop(object_id, drop_target_id)


func _resolve_drag_drop(object_id: String, drop_target_id: String) -> void:
	var solution = _current_level.get("solution", {})
	var winning_object := ""
	var winning_target := ""
	if typeof(solution) == TYPE_DICTIONARY:
		winning_object = str(solution.get("object_id", ""))
		winning_target = str(solution.get("drop_target_id", ""))

	if object_id == winning_object and drop_target_id == winning_target:
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Wrong thing, wrong place. Somehow both.")
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _handle_text_submit() -> void:
	_tap_count += 1
	_trigger_feedback("tap")

	var answer := ""
	if _text_input != null:
		answer = _normalize_answer(_text_input.text)

	_resolve_text_answer(answer)


func _resolve_text_answer(raw_answer: String) -> void:
	var answer := _normalize_answer(raw_answer)
	var rules := _rules()
	var accepted = rules.get("accepted_inputs", [])
	if typeof(accepted) == TYPE_ARRAY:
		for accepted_answer in accepted:
			if answer == _normalize_answer(str(accepted_answer)):
				_complete_current_level()
				return

	var solution := _solution()
	if answer == _normalize_answer(str(solution.get("answer", ""))):
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "The text was a trap and you brought snacks.")
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _handle_text_submitted(_submitted_text: String) -> void:
	_handle_text_submit()


func _handle_pattern_cell(cell_id: String) -> void:
	_tap_count += 1
	_trigger_feedback("tap")
	_selected_pattern_cell = cell_id
	_feedback_label.text = "Selected %s. Submit it if your pattern organs agree." % cell_id


func _handle_pattern_submit() -> void:
	_tap_count += 1
	_trigger_feedback("tap")

	var solution := _solution()
	if _selected_pattern_cell == str(solution.get("cell_id", "")):
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Pattern detected: you being incorrect.")
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _handle_pattern_mark_cell(cell_id: String, button: Button) -> void:
	_tap_count += 1
	_trigger_feedback("tap")

	if _pattern_marked_cells.has(cell_id):
		_pattern_marked_cells.erase(cell_id)
	else:
		_pattern_marked_cells.append(cell_id)

	_apply_pattern_mark_style(cell_id, button)
	_feedback_label.text = "Marked: %s" % "  ".join(_pattern_marked_cells)

	var solution_cells := _pattern_solution_cells()
	if _same_string_set(_pattern_marked_cells, solution_cells):
		_complete_current_level()
		return

	var mark_count := int(_rules().get("mark_count", solution_cells.size()))
	if mark_count > 0 and _pattern_marked_cells.size() >= mark_count:
		_feedback_label.text = _first_roast("failure", "Pattern detected: you being incorrect.")
		_set_judge_state("fail")
		_trigger_feedback("fail")


func _handle_memory_flash(show_sequence: bool) -> void:
	_tap_count += 1
	_trigger_feedback("tap")

	var rules := _rules()
	var sequence = rules.get("flash_items", [])
	if show_sequence and typeof(sequence) == TYPE_ARRAY:
		_feedback_label.text = "Flash: %s" % "  ".join(_string_array(sequence))
	else:
		_feedback_label.text = "Hidden. Choose the sequence before your brain files bankruptcy."


func _handle_memory_choice(item_id: String) -> void:
	_tap_count += 1
	_trigger_feedback("tap")
	_memory_input.append(item_id)
	_feedback_label.text = "Input: %s" % "  ".join(_memory_input)


func _handle_memory_clear() -> void:
	_tap_count += 1
	_trigger_feedback("tap")
	_memory_input = []
	_feedback_label.text = "Cleared. That was probably wise."


func _handle_memory_submit() -> void:
	_tap_count += 1
	_trigger_feedback("tap")

	var solution := _solution()
	var sequence = solution.get("sequence", [])
	if typeof(sequence) == TYPE_ARRAY and _memory_input == _string_array(sequence):
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Memory failed. The pixels had one job and so did you.")
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _handle_physics_draw(draw_id: String) -> void:
	if _uses_freehand_physics_draw():
		var points := _freehand_verifier_points(draw_id)
		var start := points[0]
		var end := points[points.size() - 1]
		_freehand_stroke_points = points
		_simulate_physics_draw_line(start, end)
		return

	_tap_count += 1
	_trigger_feedback("tap")
	_physics_choice = draw_id
	_last_physics_result = "selected"
	_physics_has_drawn_line = true
	_update_physics_choice_label()
	_feedback_label.text = "Drew %s. Release the ball and let fake gravity judge you." % _physics_draw_label(draw_id)


func _handle_physics_release() -> void:
	if _uses_freehand_physics_draw():
		_handle_freehand_physics_release()
		return

	_tap_count += 1
	_trigger_feedback("tap")

	var solution := _solution()
	if _physics_choice == str(solution.get("draw_id", "")):
		_last_physics_result = "success"
		_update_physics_result_label(true)
		_complete_current_level()
		return

	_last_physics_result = "fail"
	_update_physics_result_label(false)
	_feedback_label.text = _first_roast("failure", "The ball saw your line and requested a different universe.")
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _handle_roast_action() -> void:
	_roast_count += 1
	_set_judge_state("roast")
	_trigger_feedback("roast")
	_feedback_label.text = _roast_line("delay", "Roast used. Your dignity is now a renewable resource.", _roast_count - 1)


func _complete_current_level() -> void:
	_last_best_attempt = _profile.record_completed_attempt(_current_level, _tap_count, _roast_count, _elapsed_level_seconds())
	_last_completed_attempt = _profile.last_completed_attempt
	_last_score_result = _profile.last_score_result
	_set_judge_state("success")
	_trigger_feedback("success")
	if bool(_last_completed_attempt.get("dur_token_recovered", false)):
		_trigger_feedback("dur_recover")
	_show_score_roastcard()


func _show_score_roastcard() -> void:
	_set_judge_state("score")
	var root := _make_screen(COLOR_INK, "score_roastcard", true)

	_add_label(root, "Score Roastcard", 38, COLOR_YELLOW)
	_add_judge_face(root, _judge_state)
	_add_label(root, str(_current_level.get("title", "Level complete")), 24, COLOR_TEXT)
	_add_status(root, "Completed in %d action(s)" % int(_last_completed_attempt.get("action_count", _tap_count)), COLOR_GREEN)
	if not _last_best_attempt.is_empty():
		_add_status(root, "Best Attempt: %d action(s), %d Roast(s)" % [
			int(_last_best_attempt.get("action_count", _tap_count)),
			int(_last_best_attempt.get("roast_count", 0)),
		], COLOR_GREEN)
	if not _profile.last_error.is_empty():
		_add_status(root, _profile.last_error, COLOR_RED)
	else:
		_add_status(root, "Saved. Level %02d unlocked. UQIQ %d." % [
			int(_profile.data.get("unlocked_level", 1)),
			_profile.current_uqiq_score(),
		], COLOR_GREEN)
	_add_score_roastcard_actions(root)

	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _flat_box(COLOR_PANEL, 8))
	root.add_child(card)

	var card_box := VBoxContainer.new()
	card_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card_box.add_theme_constant_override("separation", 16)
	card.add_child(card_box)

	var score_before := int(_last_score_result.get("score_before", _profile.current_uqiq_score()))
	var score_after := int(_last_score_result.get("score_after", _profile.current_uqiq_score()))
	var score_delta := int(_last_score_result.get("score_delta", 0))
	var attempt_score_delta := int(_last_score_result.get("attempt_score_delta", score_delta))
	var score_components := _dictionary_from(_last_score_result.get("score_components", {}))
	var roast_count := int(_last_completed_attempt.get("roast_count", _roast_count))
	var action_count := int(_last_completed_attempt.get("action_count", _tap_count))
	_add_label(card_box, "UQIQ %d" % score_after, 36, COLOR_YELLOW)
	_add_label(card_box, "Total Delta: %+d  (%d -> %d)" % [score_delta, score_before, score_after], 18, COLOR_MUTED)
	if attempt_score_delta != score_delta:
		_add_label(card_box, "Attempt Delta: %+d before score cap" % attempt_score_delta, 16, COLOR_MUTED)
	_add_label(card_box, _score_component_text(score_components, "speed", "Speed", "Chrono shrug"), 18, COLOR_TEXT)
	_add_label(card_box, _score_component_text(score_components, "actions", "Actions", "Finger mystery"), 18, COLOR_TEXT)
	_add_label(card_box, _score_component_text(score_components, "roasts", "Roasts", "Dignity intact"), 18, COLOR_TEXT)
	if bool(_last_completed_attempt.get("durd_at_start", false)):
		_add_label(card_box, _score_component_text(score_components, "dur", "DUR", "DUR parole"), 18, COLOR_YELLOW)
	_add_label(card_box, "Raw: %d action(s), %d Roast(s)" % [action_count, roast_count], 16, COLOR_MUTED)
	_add_label(card_box, _first_roast("scorecard", "The score exists. Your dignity remains theoretical."), 20, COLOR_TEXT)
	_add_label(card_box, str(_current_level.get("uqiq_moment", "")), 17, COLOR_MUTED)


func _add_score_roastcard_actions(parent: Node) -> HBoxContainer:
	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	parent.add_child(actions)

	var replay_button := _make_button("Replay", COLOR_BLUE)
	replay_button.pressed.connect(Callable(self, "_show_play_screen").bind(_current_level))
	actions.add_child(replay_button)

	var next_level := _next_level_after_current()
	if not next_level.is_empty():
		var next_button := _make_button("Next Level", COLOR_GREEN)
		next_button.pressed.connect(Callable(self, "_show_play_screen").bind(next_level))
		actions.add_child(next_button)

	var list_button := _make_button("Level List", COLOR_GREEN)
	list_button.pressed.connect(Callable(self, "_show_level_list"))
	actions.add_child(list_button)
	return actions


func _next_level_after_current() -> Dictionary:
	var current_level_number := int(_current_level.get("level_number", 0))
	if current_level_number <= 0:
		return {}

	var next_level := _loader.find_level_by_number(_pack, current_level_number + 1)
	if next_level.is_empty() or not _is_level_playable(next_level):
		return {}
	return next_level


func _make_screen(background_color: Color, transition_name: String = "", use_scroll: bool = false) -> VBoxContainer:
	_cancel_memory_reveal_timer()
	for child in get_children():
		if child == _feedback_player:
			continue
		remove_child(child)
		child.queue_free()
	_judge_face_label = null
	_judge_caption_label = null

	var background := ColorRect.new()
	background.color = background_color
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	if use_scroll:
		var scroll := ScrollContainer.new()
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(scroll)

		var margins := _screen_margins()
		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", int(margins.get("left", SCREEN_MARGIN_X)))
		margin.add_theme_constant_override("margin_top", int(margins.get("top", SCREEN_MARGIN_Y)))
		margin.add_theme_constant_override("margin_right", int(margins.get("right", SCREEN_MARGIN_X)))
		margin.add_theme_constant_override("margin_bottom", int(margins.get("bottom", SCREEN_MARGIN_Y)))
		scroll.add_child(margin)

		root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(root)
	else:
		var margins := _screen_margins()
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.offset_left = int(margins.get("left", SCREEN_MARGIN_X))
		root.offset_top = int(margins.get("top", SCREEN_MARGIN_Y))
		root.offset_right = -int(margins.get("right", SCREEN_MARGIN_X))
		root.offset_bottom = -int(margins.get("bottom", SCREEN_MARGIN_Y))
		add_child(root)
	root.add_theme_constant_override("separation", 14)
	_apply_screen_transition(root, transition_name)
	return root


func _screen_margins() -> Dictionary:
	var viewport_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 390)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 844))
	)
	var viewport := get_viewport()
	if viewport != null:
		viewport_size = viewport.get_visible_rect().size

	return _screen_margins_for_safe_area(
		DisplayServer.get_display_safe_area(),
		DisplayServer.screen_get_size(),
		viewport_size
	)


func _screen_margins_for_safe_area(safe_area: Rect2i, screen_size: Vector2i, viewport_size: Vector2) -> Dictionary:
	var insets := _safe_area_insets_for_rect(safe_area, screen_size, viewport_size)
	return {
		"left": SCREEN_MARGIN_X + int(insets.get("left", 0)),
		"top": SCREEN_MARGIN_Y + int(insets.get("top", 0)),
		"right": SCREEN_MARGIN_X + int(insets.get("right", 0)),
		"bottom": SCREEN_MARGIN_Y + int(insets.get("bottom", 0)),
	}


func _safe_area_insets_for_rect(safe_area: Rect2i, screen_size: Vector2i, viewport_size: Vector2) -> Dictionary:
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return {"left": 0, "top": 0, "right": 0, "bottom": 0}
	if screen_size.x <= 0 or screen_size.y <= 0 or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return {"left": 0, "top": 0, "right": 0, "bottom": 0}

	var scale_x := viewport_size.x / float(screen_size.x)
	var scale_y := viewport_size.y / float(screen_size.y)
	var safe_right := safe_area.position.x + safe_area.size.x
	var safe_bottom := safe_area.position.y + safe_area.size.y
	return {
		"left": int(round(maxf(float(safe_area.position.x), 0.0) * scale_x)),
		"top": int(round(maxf(float(safe_area.position.y), 0.0) * scale_y)),
		"right": int(round(maxf(float(screen_size.x - safe_right), 0.0) * scale_x)),
		"bottom": int(round(maxf(float(screen_size.y - safe_bottom), 0.0) * scale_y)),
	}


func _elapsed_level_seconds() -> float:
	if _level_started_at_msec <= 0:
		return 0.0
	return maxf(float(Time.get_ticks_msec() - _level_started_at_msec) / 1000.0, 0.0)


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var label := _new_label(text, font_size, color)
	parent.add_child(label)
	return label


func _add_status(parent: Node, text: String, color: Color) -> Label:
	var label := _new_label(text, 16, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _add_judge_face(parent: Node, state: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _flat_box(COLOR_PANEL_ALT, 8))
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	_judge_face_label = _new_label(_judge_face_text(state), 28, COLOR_YELLOW)
	box.add_child(_judge_face_label)
	_judge_caption_label = _new_label(_judge_caption_text(state), 14, COLOR_MUTED)
	box.add_child(_judge_caption_label)
	return panel


func _new_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String, color: Color, min_size: Vector2 = Vector2(0, 58)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _flat_box(color, 8))
	button.add_theme_stylebox_override("hover", _flat_box(color.lightened(0.08), 8))
	button.add_theme_stylebox_override("pressed", _flat_box(color.darkened(0.08), 8))
	button.add_theme_stylebox_override("disabled", _flat_box(Color(0.22, 0.23, 0.25), 8))
	return button


func _render_level_stage(stage_box: VBoxContainer, level: Dictionary) -> void:
	var template := str(level.get("template", ""))
	_add_label(stage_box, template, 24, COLOR_INK)

	match template:
		"Tap Logic":
			_render_tap_logic(stage_box)
		"Drag Logic":
			_render_drag_logic(stage_box)
		"Text Trap":
			_render_text_trap(stage_box)
		"Pattern Grid":
			_render_pattern_grid(stage_box)
		"Memory Flash":
			_render_memory_flash(stage_box)
		"Memory/Reveal Level":
			_render_memory_reveal_level(stage_box)
		"Physics Draw":
			_render_physics_draw(stage_box)
		"Rearrange Level":
			_render_rearrange_level(stage_box)
		_:
			_add_label(stage_box, "Future template. Your brilliance has been postponed.", 18, COLOR_INK)
			_add_feedback(stage_box, "Return later when this Level stops being imaginary.")


func _render_tap_logic(stage_box: VBoxContainer) -> void:
	if _uses_direct_tap_scene():
		_render_direct_tap_scene(stage_box)
		return

	var targets = _rules().get("tap_targets", [])
	if typeof(targets) == TYPE_ARRAY:
		for target in targets:
			if typeof(target) != TYPE_DICTIONARY:
				continue

			var target_button := _make_button(str(target.get("label", "Tap")), _target_color(target))
			target_button.pressed.connect(Callable(self, "_handle_tap_target").bind(str(target.get("id", ""))))
			stage_box.add_child(target_button)

	_add_feedback(stage_box, "Choose carefully.")


func _render_direct_tap_scene(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, str(_rules().get("scene_prompt", "Tap the right object in the scene.")), 17, COLOR_INK)

	var surface := Panel.new()
	surface.name = "tap_scene_surface"
	surface.custom_minimum_size = Vector2(0, 280)
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	surface.resized.connect(Callable(self, "_layout_direct_tap_targets").bind(surface))
	stage_box.add_child(surface)

	var hint := _new_label("labels are evidence, not instructions", 16, COLOR_INK)
	hint.position = Vector2(18, 18)
	hint.size = Vector2(300, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	surface.add_child(hint)

	var targets = _rules().get("tap_targets", [])
	if typeof(targets) == TYPE_ARRAY:
		for index in range(targets.size()):
			var target = targets[index]
			if typeof(target) != TYPE_DICTIONARY:
				continue

			surface.add_child(_make_direct_tap_target(target, index))
	call_deferred("_layout_direct_tap_targets", surface)

	_add_feedback(stage_box, "Tap an object on the surface. The list is gone.")


func _render_drag_logic(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, "Drag the word into a box.", 17, COLOR_INK)

	var playfield := Panel.new()
	playfield.name = "drag_playfield"
	playfield.custom_minimum_size = Vector2(0, 280)
	playfield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playfield.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	stage_box.add_child(playfield)

	var hint := _new_label("drag tiles -> drop zones", 15, COLOR_INK)
	hint.position = Vector2(18, 16)
	hint.size = Vector2(260, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	playfield.add_child(hint)

	var objects = _rules().get("draggable_objects", [])
	if typeof(objects) == TYPE_ARRAY:
		for index in range(objects.size()):
			var object = objects[index]
			if typeof(object) != TYPE_DICTIONARY:
				continue

			var tile := _make_drag_tile(object)
			tile.position = Vector2(20, 58 + (index * 78))
			playfield.add_child(tile)

	var targets = _rules().get("drop_targets", [])
	if typeof(targets) == TYPE_ARRAY:
		for index in range(targets.size()):
			var target = targets[index]
			if typeof(target) != TYPE_DICTIONARY:
				continue

			var zone := _make_drop_zone(target)
			zone.position = Vector2(190, 58 + (index * 88))
			playfield.add_child(zone)
			_drag_drop_zones[str(target.get("id", ""))] = zone

	_add_feedback(stage_box, "Drag the wrong thing into the right place.")


func _render_rearrange_level(stage_box: VBoxContainer) -> void:
	if not _uses_physics_linked_rearrange():
		_add_label(stage_box, "Future rearrange physics. Your cup is waiting on paperwork.", 18, COLOR_INK)
		_add_feedback(stage_box, "Return when this Level has a physics-linked rearrange spec.")
		return
	if _rearrange_mode() == "move_rule_tile":
		_render_rearrange_rule_tile_level(stage_box)
		return

	_add_label(stage_box, str(_rules().get("scene_prompt", _current_level.get("prompt", "Move the cup before release."))), 17, COLOR_INK)

	var playfield := Panel.new()
	playfield.name = "rearrange_playfield"
	playfield.custom_minimum_size = Vector2(0, 300)
	playfield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playfield.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	playfield.mouse_filter = Control.MOUSE_FILTER_STOP
	stage_box.add_child(playfield)

	_rearrange_physics_runtime = Node2D.new()
	_rearrange_physics_runtime.name = "rearrange_physics_runtime"
	playfield.add_child(_rearrange_physics_runtime)

	_rearrange_allowed_rect = _rearrange_allowed_drag_rect()
	_rearrange_target_rect = _rearrange_target_placement_rect()
	_rearrange_cup_start_rect = _rearrange_cup_start_rect_from_rules()
	_rearrange_cup_rect = _rearrange_cup_start_rect

	_create_rearrange_built_in_geometry(playfield)
	_create_rearrange_target_hint(playfield)
	_create_rearrange_goal(playfield)
	_create_rearrange_ball(playfield)

	_physics_choice_label = _new_label("Cup: start", 16, COLOR_INK)
	_physics_choice_label.position = Vector2(18, 16)
	_physics_choice_label.size = Vector2(304, 26)
	_physics_choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	playfield.add_child(_physics_choice_label)

	_physics_result_label = _new_label("Release result: waiting", 16, COLOR_INK)
	_physics_result_label.position = Vector2(18, 266)
	_physics_result_label.size = Vector2(320, 26)
	_physics_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	playfield.add_child(_physics_result_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	stage_box.add_child(actions)

	var release_button := _make_button("Release", COLOR_GREEN)
	release_button.pressed.connect(Callable(self, "_handle_rearrange_release"))
	actions.add_child(release_button)

	var reset_button := _make_button("Reset", COLOR_BLUE)
	reset_button.pressed.connect(Callable(self, "_handle_rearrange_reset"))
	actions.add_child(reset_button)

	_reset_rearrange_attempt(false)
	_add_feedback(stage_box, "Move the cup, then release the ball.")


func _render_rearrange_rule_tile_level(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, str(_rules().get("scene_prompt", _current_level.get("prompt", "Move GRAVITY to the wall with the cup."))), 17, COLOR_INK)

	var playfield := Panel.new()
	playfield.name = "rearrange_playfield"
	playfield.custom_minimum_size = Vector2(0, 300)
	playfield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playfield.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	playfield.mouse_filter = Control.MOUSE_FILTER_STOP
	stage_box.add_child(playfield)

	_rearrange_physics_runtime = Node2D.new()
	_rearrange_physics_runtime.name = "rearrange_physics_runtime"
	playfield.add_child(_rearrange_physics_runtime)

	_rearrange_goal_rect = _rearrange_rule_goal_rect()
	_rearrange_rule_tile_start_rect = _rearrange_rule_tile_start_rect_from_rules()
	_rearrange_rule_tile_rect = _rearrange_rule_tile_start_rect
	_rearrange_gravity_slots = {}
	_rearrange_selected_gravity_slot_id = _rearrange_default_gravity_slot_id()
	_rearrange_selected_gravity_vector = _rearrange_gravity_vector_for_slot(_rearrange_selected_gravity_slot_id)

	_create_rearrange_rule_goal(playfield)
	_create_rearrange_gravity_slots(playfield)
	_create_rearrange_rule_tile(playfield)
	_create_rearrange_ball(playfield)

	_physics_choice_label = _new_label("Gravity: floor", 16, COLOR_INK)
	_physics_choice_label.position = Vector2(18, 16)
	_physics_choice_label.size = Vector2(304, 26)
	_physics_choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	playfield.add_child(_physics_choice_label)

	_physics_result_label = _new_label("Release result: waiting", 16, COLOR_INK)
	_physics_result_label.name = "rearrange_release_result_label"
	_physics_result_label.position = Vector2(18, 48)
	_physics_result_label.size = Vector2(320, 26)
	_physics_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	playfield.add_child(_physics_result_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	stage_box.add_child(actions)

	var release_button := _make_button("Release", COLOR_GREEN)
	release_button.pressed.connect(Callable(self, "_handle_rearrange_release"))
	actions.add_child(release_button)

	var reset_button := _make_button("Reset", COLOR_BLUE)
	reset_button.pressed.connect(Callable(self, "_handle_rearrange_reset"))
	actions.add_child(reset_button)

	_reset_rearrange_attempt(false)
	_add_feedback(stage_box, "Move GRAVITY to the wall with the cup.")


func _create_rearrange_built_in_geometry(surface: Control) -> void:
	var geometries = _rules().get("built_in_geometry", [])
	if typeof(geometries) != TYPE_ARRAY or geometries.is_empty():
		return
	if _rearrange_physics_runtime == null or not is_instance_valid(_rearrange_physics_runtime):
		return

	_rearrange_built_in_body = StaticBody2D.new()
	_rearrange_built_in_body.name = "rearrange_built_in_body"
	_rearrange_physics_runtime.add_child(_rearrange_built_in_body)

	var collision_index := 0
	for geometry in geometries:
		if typeof(geometry) != TYPE_DICTIONARY:
			continue
		var geometry_id := str(geometry.get("id", "geometry"))
		var points := _vector2_points_from_pairs(geometry.get("points", []))
		if points.size() < 2:
			continue
		var thickness := float(geometry.get("collision_thickness_px", 12.0))

		var line := Line2D.new()
		line.name = "rearrange_built_in_geometry_%s" % geometry_id
		line.points = PackedVector2Array(points)
		line.width = thickness
		line.default_color = Color(0.12, 0.13, 0.16, 0.46)
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.z_index = 1
		surface.add_child(line)

		for index in range(points.size() - 1):
			collision_index = _add_segment_collision_shape(
				_rearrange_built_in_body,
				"rearrange_built_in_collision",
				points[index],
				points[index + 1],
				thickness,
				collision_index
			)

	_rearrange_built_in_body.set_meta("collision_shape_count", collision_index)


func _create_rearrange_target_hint(surface: Control) -> void:
	_rearrange_target_hint = Panel.new()
	_rearrange_target_hint.name = "rearrange_catch_zone_hint"
	_rearrange_target_hint.position = _rearrange_target_rect.position
	_rearrange_target_hint.size = _rearrange_target_rect.size
	_rearrange_target_hint.custom_minimum_size = _rearrange_target_rect.size
	_rearrange_target_hint.z_index = 0
	_rearrange_target_hint.add_theme_stylebox_override("panel", _flat_box(Color(0.12, 0.58, 0.92, 0.18), 8))
	surface.add_child(_rearrange_target_hint)


func _create_rearrange_goal(surface: Control) -> void:
	_rearrange_cup = Panel.new()
	_rearrange_cup.name = "rearrange_cup"
	_rearrange_cup.custom_minimum_size = _rearrange_cup_rect.size
	_rearrange_cup.mouse_filter = Control.MOUSE_FILTER_STOP
	_rearrange_cup.z_index = 4
	_rearrange_cup.set_meta("object_id", "cup")
	_rearrange_cup.add_theme_stylebox_override("panel", _flat_box(COLOR_GREEN, 8))
	_rearrange_cup.gui_input.connect(Callable(self, "_handle_rearrange_object_input").bind("cup", _rearrange_cup))
	surface.add_child(_rearrange_cup)

	var label := _new_label("CUP", 16, COLOR_INK)
	label.name = "rearrange_cup_label"
	label.position = Vector2.ZERO
	label.size = _rearrange_cup_rect.size
	label.custom_minimum_size = _rearrange_cup_rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rearrange_cup.add_child(label)

	if _rearrange_physics_runtime != null and is_instance_valid(_rearrange_physics_runtime):
		_rearrange_goal_area = Area2D.new()
		_rearrange_goal_area.name = "rearrange_goal_area"
		_rearrange_physics_runtime.add_child(_rearrange_goal_area)

		var collision := CollisionShape2D.new()
		collision.name = "rearrange_goal_collision"
		collision.shape = RectangleShape2D.new()
		_rearrange_goal_area.add_child(collision)

	_set_rearrange_cup_rect(_rearrange_cup_rect)


func _create_rearrange_rule_goal(surface: Control) -> void:
	var cup := Panel.new()
	cup.name = "rearrange_right_wall_cup"
	cup.position = _rearrange_goal_rect.position
	cup.size = _rearrange_goal_rect.size
	cup.custom_minimum_size = _rearrange_goal_rect.size
	cup.z_index = 3
	cup.add_theme_stylebox_override("panel", _flat_box(COLOR_GREEN, 8))
	surface.add_child(cup)

	var label := _new_label("CUP", 15, COLOR_INK)
	label.name = "rearrange_right_wall_cup_label"
	label.position = Vector2.ZERO
	label.size = _rearrange_goal_rect.size
	label.custom_minimum_size = _rearrange_goal_rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cup.add_child(label)

	if _rearrange_physics_runtime == null or not is_instance_valid(_rearrange_physics_runtime):
		return

	_rearrange_goal_area = Area2D.new()
	_rearrange_goal_area.name = "rearrange_goal_area"
	_rearrange_goal_area.position = _rearrange_goal_rect.grow(_rearrange_goal_forgiveness()).get_center()
	_rearrange_goal_area.set_meta("goal_rect", _rearrange_goal_rect)
	_rearrange_goal_area.set_meta("forgiveness_px", _rearrange_goal_forgiveness())
	_rearrange_physics_runtime.add_child(_rearrange_goal_area)

	var collision := CollisionShape2D.new()
	collision.name = "rearrange_goal_collision"
	collision.shape = RectangleShape2D.new()
	(collision.shape as RectangleShape2D).size = _rearrange_goal_rect.grow(_rearrange_goal_forgiveness()).size
	_rearrange_goal_area.add_child(collision)


func _create_rearrange_gravity_slots(surface: Control) -> void:
	var targets = _rules().get("drop_targets", [])
	if typeof(targets) != TYPE_ARRAY:
		return

	for target in targets:
		if typeof(target) != TYPE_DICTIONARY:
			continue
		var target_id := str(target.get("id", ""))
		var rect := _rect2_from_array(target.get("rect", []), Rect2())
		if target_id.is_empty() or rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue

		var slot := Panel.new()
		slot.name = "rearrange_gravity_slot_%s" % target_id
		slot.position = rect.position
		slot.size = rect.size
		slot.custom_minimum_size = rect.size
		slot.z_index = 1
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_theme_stylebox_override("panel", _flat_box(Color(0.17, 0.22, 0.28, 0.22), 8))
		surface.add_child(slot)

		var label := _new_label(_gravity_slot_symbol(target_id), 20, COLOR_INK)
		label.position = Vector2.ZERO
		label.size = rect.size
		label.custom_minimum_size = rect.size
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)

		_rearrange_gravity_slots[target_id] = {
			"rect": rect,
			"gravity_vector": _vector2_from_array(target.get("gravity_vector", []), Vector2.ZERO),
			"role": str(target.get("role", "decoy")),
		}


func _create_rearrange_rule_tile(surface: Control) -> void:
	_rearrange_rule_tile = Panel.new()
	_rearrange_rule_tile.name = "rearrange_gravity_tile"
	_rearrange_rule_tile.custom_minimum_size = _rearrange_rule_tile_rect.size
	_rearrange_rule_tile.mouse_filter = Control.MOUSE_FILTER_STOP
	_rearrange_rule_tile.z_index = 5
	_rearrange_rule_tile.set_meta("object_id", "gravity_tile")
	_rearrange_rule_tile.add_theme_stylebox_override("panel", _flat_box(COLOR_BLUE, 8))
	_rearrange_rule_tile.gui_input.connect(Callable(self, "_handle_rearrange_object_input").bind("gravity_tile", _rearrange_rule_tile))
	surface.add_child(_rearrange_rule_tile)

	var label := _new_label("GRAVITY", 16, COLOR_TEXT)
	label.name = "rearrange_gravity_tile_label"
	label.position = Vector2.ZERO
	label.size = _rearrange_rule_tile_rect.size
	label.custom_minimum_size = _rearrange_rule_tile_rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rearrange_rule_tile.add_child(label)

	_set_rearrange_rule_tile_rect(_rearrange_rule_tile_rect)


func _create_rearrange_ball(surface: Control) -> void:
	var radius := _rearrange_ball_radius()
	_rearrange_ball_start = _rearrange_ball_start_from_rules()
	_rearrange_last_ball_position = _rearrange_ball_start

	_rearrange_ball_visual = Panel.new()
	_rearrange_ball_visual.name = "rearrange_ball"
	_rearrange_ball_visual.position = _rearrange_ball_start - Vector2(radius, radius)
	_rearrange_ball_visual.size = Vector2(radius * 2.0, radius * 2.0)
	_rearrange_ball_visual.custom_minimum_size = _rearrange_ball_visual.size
	_rearrange_ball_visual.z_index = 5
	_rearrange_ball_visual.add_theme_stylebox_override("panel", _flat_box(COLOR_YELLOW, int(radius)))
	surface.add_child(_rearrange_ball_visual)

	if _rearrange_physics_runtime == null or not is_instance_valid(_rearrange_physics_runtime):
		return

	_rearrange_ball_body = RigidBody2D.new()
	_rearrange_ball_body.name = "rearrange_ball_body"
	_rearrange_ball_body.position = _rearrange_ball_start
	_rearrange_ball_body.freeze = true
	_rearrange_ball_body.gravity_scale = 1.0
	_rearrange_physics_runtime.add_child(_rearrange_ball_body)

	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.name = "rearrange_ball_collision"
	collision.shape = shape
	_rearrange_ball_body.add_child(collision)


func _handle_rearrange_object_input(event: InputEvent, object_id: String, tile: Control) -> void:
	if _rearrange_released:
		return

	if _is_primary_press(event):
		_rearrange_dragging_object_id = object_id
		_rearrange_dragging_tile = tile
		_rearrange_drag_offset = _event_position_in_control(event, tile, tile)
		tile.move_to_front()
		if object_id == "gravity_tile":
			_set_rearrange_status_text("Gravity: dragging", "Release result: waiting")
			_feedback_label.text = "Dragging GRAVITY. Put it on the wall with the cup."
		else:
			_set_rearrange_status_text("Cup: dragging", "Release result: waiting")
			_feedback_label.text = "Dragging the cup. Put it where the ball is actually going."
		_mark_input_handled()
		return

	if _is_pointer_drag(event) and _rearrange_dragging_tile == tile:
		_move_rearrange_tile(event, tile)
		_mark_input_handled()
		return

	if _is_primary_release(event) and _rearrange_dragging_tile == tile:
		_move_rearrange_tile(event, tile)
		_finish_rearrange_drag()
		_mark_input_handled()


func _move_rearrange_tile(event: InputEvent, tile: Control) -> void:
	var playfield := tile.get_parent() as Control
	if playfield == null:
		return

	var pointer_position := _event_position_in_control(event, playfield, tile)
	var next_position := pointer_position - _rearrange_drag_offset
	var next_rect := Rect2(
		next_position,
		tile.size
	)
	if _rearrange_dragging_object_id == "gravity_tile":
		_set_rearrange_rule_tile_rect(_clamped_rearrange_rule_tile_rect(next_rect, playfield))
		return

	_set_rearrange_cup_rect(_clamped_rearrange_cup_rect(next_rect))


func _finish_rearrange_drag() -> void:
	if _rearrange_dragging_object_id == "gravity_tile":
		_finish_rearrange_rule_tile_drag()
		return

	if _rearrange_cup_rect.intersects(_rearrange_target_rect.grow(_rearrange_goal_forgiveness()), true):
		_set_rearrange_cup_center(_rearrange_target_rect.get_center())

	_rearrange_cup_moved = _rearrange_cup_rect.position.distance_to(_rearrange_cup_start_rect.position) > 1.0
	_rearrange_dragging_object_id = ""
	_rearrange_dragging_tile = null
	_rearrange_drag_offset = Vector2.ZERO
	_tap_count += 1
	_trigger_feedback("tap")
	_set_rearrange_status_text("Cup: moved", "Release result: ready")
	_feedback_label.text = "Cup moved. Release the ball."


func _handle_rearrange_release() -> void:
	if _rearrange_mode() == "move_rule_tile":
		_handle_rearrange_rule_tile_release()
		return

	_tap_count += 1
	_trigger_feedback("tap")
	_rearrange_released = true
	_move_rearrange_ball_to(_rearrange_target_rect.get_center())

	if not _rearrange_cup_moved:
		_fail_rearrange("Move the cup under the fall, not near your hopes.")
		return
	if not _rearrange_cup_in_target():
		_fail_rearrange("Missed. The cup was decorative over there.")
		return

	_move_rearrange_ball_to(_rearrange_cup_rect.get_center())
	if _rearrange_ball_overlaps_goal():
		_last_physics_result = "success"
		_set_rearrange_status_text("Cup: caught", "Release result: ball reached the cup")
		_feedback_label.text = "Ball reached the moved cup."
		_complete_current_level()
		return

	_fail_rearrange("Missed. The cup was decorative over there.")


func _handle_rearrange_reset() -> void:
	_reset_rearrange_attempt(true)


func _reset_rearrange_attempt(count_action: bool = true) -> void:
	if _rearrange_mode() == "move_rule_tile":
		_reset_rearrange_rule_tile_attempt(count_action)
		return

	if count_action:
		_tap_count += 1
		_trigger_feedback("tap")

	_last_physics_result = "reset"
	_rearrange_released = false
	_rearrange_cup_moved = false
	_rearrange_ball_moved = false
	_rearrange_dragging_object_id = ""
	_rearrange_dragging_tile = null
	_rearrange_drag_offset = Vector2.ZERO
	_rearrange_ball_start = _rearrange_ball_start_from_rules()
	_rearrange_last_ball_position = _rearrange_ball_start
	_set_rearrange_cup_rect(_rearrange_cup_start_rect)
	_set_rearrange_ball_center(_rearrange_ball_start)
	_set_rearrange_status_text("Cup: start", "Release result: waiting")
	if _feedback_label != null and is_instance_valid(_feedback_label):
		_feedback_label.text = "Reset. Move the cup, then release the ball."


func _finish_rearrange_rule_tile_drag() -> void:
	var selected_slot_id := _rearrange_slot_id_for_rect(_rearrange_rule_tile_rect)
	if selected_slot_id.is_empty():
		selected_slot_id = _rearrange_selected_gravity_slot_id
	if selected_slot_id.is_empty():
		selected_slot_id = _rearrange_default_gravity_slot_id()

	_set_rearrange_rule_tile_slot(selected_slot_id)
	_rearrange_rule_tile_moved = _rearrange_rule_tile_rect.position.distance_to(_rearrange_rule_tile_start_rect.position) > 1.0
	_rearrange_dragging_object_id = ""
	_rearrange_dragging_tile = null
	_rearrange_drag_offset = Vector2.ZERO
	_tap_count += 1
	_trigger_feedback("tap")
	_set_rearrange_status_text("Gravity: %s" % _rearrange_gravity_label(), "Release result: ready")
	_feedback_label.text = "GRAVITY moved. Release the ball."


func _handle_rearrange_rule_tile_release() -> void:
	_tap_count += 1
	_trigger_feedback("tap")
	_rearrange_released = true
	_move_rearrange_ball_with_gravity()

	if _rearrange_selected_gravity_slot_id.is_empty() or _rearrange_selected_gravity_slot_id == _rearrange_default_gravity_slot_id():
		_fail_rearrange("Move GRAVITY to the wall with the cup.")
		return
	if not _rearrange_selected_gravity_slot_is_correct():
		_fail_rearrange("Wrong wall. Excellent confidence, poor universe.")
		return

	_move_rearrange_ball_to(_rearrange_goal_rect.get_center())
	if _rearrange_ball_overlaps_rule_goal():
		_last_physics_result = "success"
		_set_rearrange_status_text("Gravity: right wall", "Release result: ball reached the cup")
		_feedback_label.text = "The ball fell sideways into the cup."
		_complete_current_level()
		return

	_fail_rearrange("Gravity went that way. The cup did not.")


func _reset_rearrange_rule_tile_attempt(count_action: bool = true) -> void:
	if count_action:
		_tap_count += 1
		_trigger_feedback("tap")

	_last_physics_result = "reset"
	_rearrange_released = false
	_rearrange_rule_tile_moved = false
	_rearrange_ball_moved = false
	_rearrange_dragging_object_id = ""
	_rearrange_dragging_tile = null
	_rearrange_drag_offset = Vector2.ZERO
	_rearrange_ball_start = _rearrange_ball_start_from_rules()
	_rearrange_last_ball_position = _rearrange_ball_start
	_set_rearrange_rule_tile_rect(_rearrange_rule_tile_start_rect)
	_set_rearrange_rule_tile_slot(_rearrange_default_gravity_slot_id())
	_set_rearrange_ball_center(_rearrange_ball_start)
	_set_rearrange_status_text("Gravity: floor", "Release result: waiting")
	if _feedback_label != null and is_instance_valid(_feedback_label):
		_feedback_label.text = "Reset. Move GRAVITY to the wall with the cup."


func _fail_rearrange(message: String) -> void:
	_last_physics_result = "fail"
	if _rearrange_mode() == "move_rule_tile":
		_set_rearrange_status_text("Gravity: needs work", "Release result: %s" % message)
	else:
		_set_rearrange_status_text("Cup: needs work", "Release result: %s" % message)
	_feedback_label.text = message
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _set_rearrange_cup_center(center: Vector2) -> void:
	var next_rect := Rect2(center - (_rearrange_cup_rect.size * 0.5), _rearrange_cup_rect.size)
	_set_rearrange_cup_rect(_clamped_rearrange_cup_rect(next_rect))


func _clamped_rearrange_cup_rect(rect: Rect2) -> Rect2:
	var max_x := _rearrange_allowed_rect.position.x + maxf(_rearrange_allowed_rect.size.x - rect.size.x, 0.0)
	var max_y := _rearrange_allowed_rect.position.y + maxf(_rearrange_allowed_rect.size.y - rect.size.y, 0.0)
	return Rect2(
		Vector2(
			clampf(rect.position.x, _rearrange_allowed_rect.position.x, max_x),
			clampf(rect.position.y, _rearrange_allowed_rect.position.y, max_y)
		),
		rect.size
	)


func _set_rearrange_cup_rect(rect: Rect2) -> void:
	_rearrange_cup_rect = rect
	if _rearrange_cup != null and is_instance_valid(_rearrange_cup):
		_rearrange_cup.position = rect.position
		_rearrange_cup.size = rect.size
		_rearrange_cup.custom_minimum_size = rect.size
		_rearrange_cup.set_meta("cup_rect", rect)
		var label := _rearrange_cup.get_node_or_null("rearrange_cup_label") as Label
		if label != null:
			label.size = rect.size
			label.custom_minimum_size = rect.size

	if _rearrange_goal_area != null and is_instance_valid(_rearrange_goal_area):
		var visible_rect := rect.grow(_rearrange_goal_forgiveness())
		_rearrange_goal_area.position = visible_rect.get_center()
		_rearrange_goal_area.set_meta("goal_rect", rect)
		_rearrange_goal_area.set_meta("forgiveness_px", _rearrange_goal_forgiveness())
		var collision := _rearrange_goal_area.get_node_or_null("rearrange_goal_collision") as CollisionShape2D
		if collision != null and collision.shape is RectangleShape2D:
			(collision.shape as RectangleShape2D).size = visible_rect.size


func _set_rearrange_rule_tile_slot(slot_id: String) -> void:
	if not _rearrange_gravity_slots.has(slot_id):
		return

	var slot := _dictionary_from(_rearrange_gravity_slots.get(slot_id, {}))
	var slot_rect := _rect2_from_variant(slot.get("rect", Rect2()))
	if slot_id == _rearrange_default_gravity_slot_id():
		_set_rearrange_rule_tile_rect(_rearrange_rule_tile_start_rect)
	else:
		_set_rearrange_rule_tile_rect(Rect2(slot_rect.get_center() - (_rearrange_rule_tile_rect.size * 0.5), _rearrange_rule_tile_rect.size))
	_rearrange_selected_gravity_slot_id = slot_id
	_rearrange_selected_gravity_vector = _vector2_from_variant(slot.get("gravity_vector", Vector2.ZERO))


func _set_rearrange_rule_tile_rect(rect: Rect2) -> void:
	_rearrange_rule_tile_rect = rect
	if _rearrange_rule_tile != null and is_instance_valid(_rearrange_rule_tile):
		_rearrange_rule_tile.position = rect.position
		_rearrange_rule_tile.size = rect.size
		_rearrange_rule_tile.custom_minimum_size = rect.size
		_rearrange_rule_tile.set_meta("rule_tile_rect", rect)
		var label := _rearrange_rule_tile.get_node_or_null("rearrange_gravity_tile_label") as Label
		if label != null:
			label.size = rect.size
			label.custom_minimum_size = rect.size


func _clamped_rearrange_rule_tile_rect(rect: Rect2, playfield: Control) -> Rect2:
	var bounds := Rect2(Vector2.ZERO, playfield.size)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		bounds = Rect2(0, 0, 340, 300)
	var max_x := bounds.position.x + maxf(bounds.size.x - rect.size.x, 0.0)
	var max_y := bounds.position.y + maxf(bounds.size.y - rect.size.y, 0.0)
	return Rect2(
		Vector2(
			clampf(rect.position.x, bounds.position.x, max_x),
			clampf(rect.position.y, bounds.position.y, max_y)
		),
		rect.size
	)


func _move_rearrange_ball_to(center: Vector2) -> void:
	_rearrange_ball_moved = _rearrange_ball_start_from_rules().distance_to(center) > 1.0
	_rearrange_last_ball_position = center
	_set_rearrange_ball_center(center)


func _move_rearrange_ball_with_gravity() -> void:
	var vector := _rearrange_selected_gravity_vector
	if vector.length() <= 0.1:
		vector = Vector2(0, 720)
	var direction := vector.normalized()
	var miss_center := _rearrange_ball_start_from_rules() + (direction * 142.0)
	_move_rearrange_ball_to(miss_center)


func _set_rearrange_ball_center(center: Vector2) -> void:
	var radius := _rearrange_ball_radius()
	if _rearrange_ball_visual != null and is_instance_valid(_rearrange_ball_visual):
		_rearrange_ball_visual.position = center - Vector2(radius, radius)
	if _rearrange_ball_body != null and is_instance_valid(_rearrange_ball_body):
		_rearrange_ball_body.position = center


func _rearrange_ball_overlaps_goal() -> bool:
	return _circle_overlaps_rect(_rearrange_last_ball_position, _rearrange_ball_radius(), _rearrange_cup_rect.grow(_rearrange_goal_forgiveness()))


func _rearrange_ball_overlaps_rule_goal() -> bool:
	return _circle_overlaps_rect(_rearrange_last_ball_position, _rearrange_ball_radius(), _rearrange_goal_rect.grow(_rearrange_goal_forgiveness()))


func _rearrange_cup_in_target() -> bool:
	return _rearrange_cup_rect.intersects(_rearrange_target_rect.grow(_rearrange_goal_forgiveness()), true)


func _set_rearrange_status_text(cup_text: String, result_text: String) -> void:
	if _physics_choice_label != null and is_instance_valid(_physics_choice_label):
		_physics_choice_label.text = cup_text
	if _physics_result_label != null and is_instance_valid(_physics_result_label):
		_physics_result_label.text = result_text


func _rearrange_draggable_object() -> Dictionary:
	var objects = _rules().get("draggable_objects", [])
	if typeof(objects) == TYPE_ARRAY:
		var expected_id := "gravity_tile" if _rearrange_mode() == "move_rule_tile" else "cup"
		for object in objects:
			if typeof(object) == TYPE_DICTIONARY and str(object.get("id", "")) == expected_id:
				return object
		for object in objects:
			if typeof(object) == TYPE_DICTIONARY:
				return object
	return {}


func _rearrange_cup_start_rect_from_rules() -> Rect2:
	var object := _rearrange_draggable_object()
	return _rect2_from_array(object.get("start_rect", []), Rect2(260, 214, 58, 52))


func _rearrange_allowed_drag_rect() -> Rect2:
	var object := _rearrange_draggable_object()
	return _rect2_from_array(object.get("allowed_drag_rect", []), Rect2(36, 156, 268, 112))


func _rearrange_target_placement_rect() -> Rect2:
	var target := _dictionary_from(_rules().get("target_placement", {}))
	return _rect2_from_array(target.get("rect", []), Rect2(188, 214, 74, 58))


func _rearrange_goal_forgiveness() -> float:
	if _rearrange_mode() == "move_rule_tile":
		var goal_zone := _dictionary_from(_rules().get("goal_zone", {}))
		return float(goal_zone.get("forgiveness_px", 16.0))
	var target := _dictionary_from(_rules().get("target_placement", {}))
	return float(target.get("forgiveness_px", 18.0))


func _rearrange_ball_start_from_rules() -> Vector2:
	var moving_object := _dictionary_from(_rules().get("moving_object", {}))
	return _vector2_from_array(moving_object.get("start", []), Vector2(72, 88))


func _rearrange_ball_radius() -> float:
	var moving_object := _dictionary_from(_rules().get("moving_object", {}))
	return float(moving_object.get("radius", 16.0))


func _rearrange_mode() -> String:
	return str(_rules().get("rearrange_mode", "move_goal_marker"))


func _rearrange_rule_tile_start_rect_from_rules() -> Rect2:
	var object := _rearrange_draggable_object()
	return _rect2_from_array(object.get("start_rect", []), Rect2(132, 236, 96, 46))


func _rearrange_rule_goal_rect() -> Rect2:
	var goal_zone := _dictionary_from(_rules().get("goal_zone", {}))
	return _rect2_from_array(goal_zone.get("rect", []), Rect2(274, 128, 52, 64))


func _rearrange_default_gravity_slot_id() -> String:
	if _rearrange_gravity_slots.has("floor_slot"):
		return "floor_slot"
	var targets = _rules().get("drop_targets", [])
	if typeof(targets) == TYPE_ARRAY:
		for target in targets:
			if typeof(target) == TYPE_DICTIONARY:
				return str(target.get("id", ""))
	return ""


func _rearrange_gravity_vector_for_slot(slot_id: String) -> Vector2:
	if _rearrange_gravity_slots.has(slot_id):
		return _vector2_from_variant(_dictionary_from(_rearrange_gravity_slots.get(slot_id, {})).get("gravity_vector", Vector2.ZERO))

	var targets = _rules().get("drop_targets", [])
	if typeof(targets) == TYPE_ARRAY:
		for target in targets:
			if typeof(target) == TYPE_DICTIONARY and str(target.get("id", "")) == slot_id:
				return _vector2_from_array(target.get("gravity_vector", []), Vector2.ZERO)
	return Vector2.ZERO


func _rearrange_selected_gravity_slot_is_correct() -> bool:
	var slot := _dictionary_from(_rearrange_gravity_slots.get(_rearrange_selected_gravity_slot_id, {}))
	return str(slot.get("role", "decoy")) == "correct"


func _rearrange_slot_id_for_rect(rect: Rect2) -> String:
	var best_slot_id := ""
	var best_area := 0.0
	for slot_id in _rearrange_gravity_slots.keys():
		var slot := _dictionary_from(_rearrange_gravity_slots.get(slot_id, {}))
		var slot_rect := _rect2_from_variant(slot.get("rect", Rect2()))
		var overlap := rect.intersection(slot_rect)
		var area := overlap.size.x * overlap.size.y
		if area > best_area:
			best_area = area
			best_slot_id = str(slot_id)
	return best_slot_id


func _rearrange_gravity_label() -> String:
	match _rearrange_selected_gravity_slot_id:
		"left_wall_slot":
			return "left wall"
		"right_wall_slot":
			return "right wall"
		"floor_slot":
			return "floor"
		_:
			return "unset"


func _gravity_slot_symbol(slot_id: String) -> String:
	match slot_id:
		"left_wall_slot":
			return "<"
		"right_wall_slot":
			return ">"
		"floor_slot":
			return "v"
		_:
			return "."


func _render_text_trap(stage_box: VBoxContainer) -> void:
	if _uses_direct_text_tiles():
		_render_direct_text_tiles(stage_box)
		return

	_text_input = LineEdit.new()
	_text_input.placeholder_text = str(_rules().get("placeholder", "type answer"))
	_text_input.custom_minimum_size = Vector2(0, 56)
	_text_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_input.virtual_keyboard_enabled = true
	_text_input.virtual_keyboard_show_on_focus = true
	_text_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	_text_input.add_theme_font_size_override("font_size", 22)
	_text_input.focus_entered.connect(Callable(self, "_show_text_input_keyboard"))
	_text_input.gui_input.connect(Callable(self, "_handle_text_input_focus_event"))
	_text_input.text_submitted.connect(Callable(self, "_handle_text_submitted"))
	stage_box.add_child(_text_input)

	var submit_button := _make_button("Submit", COLOR_GREEN)
	submit_button.pressed.connect(Callable(self, "_handle_text_submit"))
	stage_box.add_child(submit_button)

	_add_feedback(stage_box, "Type the answer the prompt deserves, not the one it asked for.")


func _render_direct_text_tiles(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, str(_rules().get("scene_prompt", "Tap the literal word into the answer slot.")), 17, COLOR_INK)

	var surface := Panel.new()
	surface.name = "text_tile_surface"
	surface.custom_minimum_size = Vector2(0, 260)
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	stage_box.add_child(surface)

	var prompt_label := _new_label("answer slot", 15, COLOR_INK)
	prompt_label.position = Vector2(18, 16)
	prompt_label.size = Vector2(280, 28)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	surface.add_child(prompt_label)

	var answer_slot := PanelContainer.new()
	answer_slot.name = "text_answer_slot"
	answer_slot.position = Vector2(18, 50)
	answer_slot.size = Vector2(300, 70)
	answer_slot.custom_minimum_size = answer_slot.size
	answer_slot.add_theme_stylebox_override("panel", _flat_box(COLOR_PANEL_ALT, 8))
	surface.add_child(answer_slot)

	_direct_text_answer_label = _new_label("_", 24, COLOR_TEXT)
	_direct_text_answer_label.name = "text_answer_slot_label"
	_direct_text_answer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	answer_slot.add_child(_direct_text_answer_label)

	var tiles = _rules().get("word_tiles", [])
	if typeof(tiles) == TYPE_ARRAY:
		for index in range(tiles.size()):
			var tile_data = tiles[index]
			if typeof(tile_data) == TYPE_DICTIONARY:
				surface.add_child(_make_text_tile(tile_data, index))

	_add_feedback(stage_box, "Tap a word tile. The slot judges it immediately.")


func _render_pattern_grid(stage_box: VBoxContainer) -> void:
	if _uses_direct_pattern_grid():
		_render_direct_pattern_grid(stage_box)
		return

	var grid := GridContainer.new()
	grid.columns = int(_rules().get("columns", 3))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	stage_box.add_child(grid)

	var cells = _rules().get("cells", [])
	if typeof(cells) == TYPE_ARRAY:
		for cell in cells:
			if typeof(cell) != TYPE_DICTIONARY:
				continue

			var cell_button := _make_button(str(cell.get("label", "?")), _target_color(cell), Vector2(86, 58))
			cell_button.pressed.connect(Callable(self, "_handle_pattern_cell").bind(str(cell.get("id", ""))))
			grid.add_child(cell_button)

	var submit_button := _make_button("Submit Pattern", COLOR_GREEN)
	submit_button.pressed.connect(Callable(self, "_handle_pattern_submit"))
	stage_box.add_child(submit_button)

	_add_feedback(stage_box, "Find the cell that breaks the pattern.")


func _render_direct_pattern_grid(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, "Mark the whole broken row.", 17, COLOR_INK)

	var grid := GridContainer.new()
	grid.name = "pattern_mark_grid"
	grid.columns = int(_rules().get("columns", 3))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	stage_box.add_child(grid)

	var cells = _rules().get("cells", [])
	if typeof(cells) == TYPE_ARRAY:
		for cell in cells:
			if typeof(cell) != TYPE_DICTIONARY:
				continue

			var cell_id := str(cell.get("id", ""))
			var cell_button := _make_button(str(cell.get("label", "?")), _target_color(cell), Vector2(86, 64))
			cell_button.name = "pattern_mark_cell_%s" % cell_id
			cell_button.pressed.connect(Callable(self, "_handle_pattern_mark_cell").bind(cell_id, cell_button))
			grid.add_child(cell_button)
			_pattern_cell_buttons[cell_id] = cell_button

	_add_feedback(stage_box, "Mark cells in the row that broke the pattern. It will judge you automatically.")


func _render_memory_flash(stage_box: VBoxContainer) -> void:
	if _uses_direct_memory_tiles():
		_render_direct_memory_tiles(stage_box)
		return

	var flash_row := HBoxContainer.new()
	flash_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flash_row.add_theme_constant_override("separation", 8)
	stage_box.add_child(flash_row)

	var show_button := _make_button("Flash", COLOR_YELLOW)
	show_button.pressed.connect(Callable(self, "_handle_memory_flash").bind(true))
	flash_row.add_child(show_button)

	var hide_button := _make_button("Hide", COLOR_PANEL_ALT)
	hide_button.pressed.connect(Callable(self, "_handle_memory_flash").bind(false))
	flash_row.add_child(hide_button)

	var choices = _rules().get("choices", [])
	if typeof(choices) == TYPE_ARRAY:
		for choice in choices:
			var choice_button := _make_button(str(choice), COLOR_BLUE, Vector2(0, 52))
			choice_button.pressed.connect(Callable(self, "_handle_memory_choice").bind(str(choice)))
			stage_box.add_child(choice_button)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	stage_box.add_child(actions)

	var clear_button := _make_button("Clear", COLOR_ORANGE)
	clear_button.pressed.connect(Callable(self, "_handle_memory_clear"))
	actions.add_child(clear_button)

	var submit_button := _make_button("Submit", COLOR_GREEN)
	submit_button.pressed.connect(Callable(self, "_handle_memory_submit"))
	actions.add_child(submit_button)

	_add_feedback(stage_box, "Flash it, hide it, then rebuild the sequence.")


func _render_direct_memory_tiles(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, str(_rules().get("scene_prompt", "Tap tiles into the recall slots.")), 17, COLOR_INK)

	var surface := Panel.new()
	surface.name = "memory_tile_surface"
	surface.custom_minimum_size = Vector2(0, 312)
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	stage_box.add_child(surface)

	var flash_label := _new_label("flash: %s" % "  ".join(_string_array(_rules().get("flash_items", []))), 16, COLOR_INK)
	flash_label.name = "memory_flash_order"
	flash_label.position = Vector2(18, 18)
	flash_label.size = Vector2(320, 30)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	surface.add_child(flash_label)
	_hide_direct_memory_flash_after_delay(flash_label, maxf(float(_rules().get("flash_seconds", 1.0)), 0.1))

	_render_memory_recall_slots(surface)
	_render_memory_tile_bank(surface)
	_add_feedback(stage_box, "Tap tiles into slots. It judges the moment the row is full.")


func _hide_direct_memory_flash_after_delay(label: Label, delay_seconds: float) -> void:
	if not is_inside_tree():
		return

	var tree := get_tree()
	if tree == null:
		return

	var timer := tree.create_timer(delay_seconds)
	timer.timeout.connect(Callable(self, "_hide_direct_memory_flash_label").bind(label), CONNECT_ONE_SHOT)


func _hide_direct_memory_flash_label(label: Label) -> void:
	if label == null or not is_instance_valid(label):
		return
	label.text = "flash hidden"
	label.add_theme_color_override("font_color", Color(0.28, 0.29, 0.31))


func _render_memory_recall_slots(surface: Control) -> void:
	var sequence := _memory_solution_sequence()
	for index in range(sequence.size()):
		var slot := PanelContainer.new()
		slot.name = "memory_recall_slot_%d" % index
		slot.position = Vector2(18 + (index * 102), 70)
		slot.size = Vector2(96, 70)
		slot.custom_minimum_size = slot.size
		slot.add_theme_stylebox_override("panel", _flat_box(COLOR_PANEL_ALT, 8))
		surface.add_child(slot)

		var label := _new_label("_", 22, COLOR_TEXT)
		label.name = "memory_recall_slot_label_%d" % index
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)
		_memory_slot_labels[index] = label


func _render_memory_tile_bank(surface: Control) -> void:
	var choices = _rules().get("choices", [])
	if typeof(choices) == TYPE_ARRAY:
		for index in range(choices.size()):
			var item_id := str(choices[index])
			var tile := _make_memory_tile(item_id, index)
			surface.add_child(tile)

	var clear_tile := _make_memory_tile("CLEAR", 0, true)
	clear_tile.name = "memory_tile_clear"
	clear_tile.position = Vector2(18, 242)
	surface.add_child(clear_tile)


func _make_memory_tile(item_id: String, index: int, is_clear: bool = false) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.name = "memory_tile_%s" % item_id.to_lower()
	tile.position = Vector2(18 + (index * 102), 164)
	tile.size = Vector2(96, 62)
	tile.custom_minimum_size = tile.size
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.add_theme_stylebox_override("panel", _flat_box(COLOR_ORANGE if is_clear else COLOR_BLUE, 8))
	if is_clear:
		tile.gui_input.connect(Callable(self, "_handle_direct_memory_clear_input").bind(tile))
	else:
		tile.gui_input.connect(Callable(self, "_handle_direct_memory_tile_input").bind(item_id, tile))

	var label := _new_label(item_id, 18 if is_clear else 17, COLOR_TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)
	return tile


func _render_memory_reveal_level(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, str(_rules().get("scene_prompt", _current_level.get("prompt", "Remember, then act."))), 17, COLOR_INK)
	if _uses_reveal_freehand_physics():
		_render_freehand_physics_draw(stage_box)
		return

	_add_feedback(stage_box, "Future reveal physics. Your memory is in another prototype.")


func _render_physics_draw(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, str(_current_level.get("prompt", "Draw one line so the ball reaches the cup.")), 17, COLOR_INK)
	if _uses_freehand_physics_draw():
		_render_freehand_physics_draw(stage_box)
		return

	if not _uses_direct_physics_draw():
		_render_physics_draw_choice_fallback(stage_box)
		return

	var surface := Panel.new()
	surface.name = "physics_draw_surface"
	surface.custom_minimum_size = Vector2(0, 280)
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	surface.mouse_filter = Control.MOUSE_FILTER_STOP
	surface.gui_input.connect(Callable(self, "_handle_physics_surface_input").bind(surface))
	stage_box.add_child(surface)
	_physics_draw_surface = surface

	var ball := _new_label("BALL", 17, COLOR_INK)
	ball.position = Vector2(18, 216)
	ball.size = Vector2(76, 28)
	surface.add_child(ball)

	var cup := _new_label("CUP", 17, COLOR_INK)
	cup.position = Vector2(244, 84)
	cup.size = Vector2(76, 28)
	surface.add_child(cup)

	var guide := _new_label("BALL -> selected line -> CUP", 18, COLOR_INK)
	guide.position = Vector2(20, 18)
	guide.size = Vector2(300, 30)
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	surface.add_child(guide)

	_physics_line = Line2D.new()
	_physics_line.name = "player_drawn_line"
	_physics_line.width = 6.0
	_physics_line.default_color = COLOR_BLUE
	surface.add_child(_physics_line)

	_physics_choice_label = _new_label("Selected line: none", 16, COLOR_INK)
	_physics_choice_label.position = Vector2(20, 52)
	_physics_choice_label.size = Vector2(300, 26)
	_physics_choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	surface.add_child(_physics_choice_label)
	_physics_result_label = _new_label("Release result: waiting on fake gravity", 16, COLOR_INK)
	_physics_result_label.position = Vector2(20, 248)
	_physics_result_label.size = Vector2(320, 26)
	_physics_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	surface.add_child(_physics_result_label)

	var release_button := _make_button("Release Ball", COLOR_GREEN)
	release_button.pressed.connect(Callable(self, "_handle_physics_release"))
	stage_box.add_child(release_button)

	_add_feedback(stage_box, "Draw the ramp, then release the ball.")


func _render_freehand_physics_draw(stage_box: VBoxContainer) -> void:
	var surface := Panel.new()
	surface.name = "physics_draw_surface"
	surface.custom_minimum_size = Vector2(0, 300)
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	surface.mouse_filter = Control.MOUSE_FILTER_STOP
	surface.gui_input.connect(Callable(self, "_handle_physics_surface_input").bind(surface))
	stage_box.add_child(surface)
	_physics_draw_surface = surface

	_freehand_physics_runtime = Node2D.new()
	_freehand_physics_runtime.name = "freehand_physics_runtime"
	surface.add_child(_freehand_physics_runtime)

	_create_freehand_built_in_geometry(surface)
	_create_freehand_goal(surface)
	_create_freehand_ball(surface)

	_physics_line = Line2D.new()
	_physics_line.name = "player_drawn_line"
	_physics_line.width = _freehand_collision_thickness()
	_physics_line.default_color = COLOR_BLUE
	_physics_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_physics_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_physics_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_physics_line.z_index = 4
	surface.add_child(_physics_line)

	_physics_choice_label = _new_label("Stroke: none", 16, COLOR_INK)
	_physics_choice_label.position = Vector2(18, 16)
	_physics_choice_label.size = Vector2(304, 26)
	_physics_choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	surface.add_child(_physics_choice_label)

	_physics_result_label = _new_label("Release result: waiting", 16, COLOR_INK)
	_physics_result_label.position = Vector2(18, 266)
	_physics_result_label.size = Vector2(320, 26)
	_physics_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	surface.add_child(_physics_result_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	stage_box.add_child(actions)

	if _uses_reveal_freehand_physics():
		_reveal_button = _make_button("Reveal", COLOR_YELLOW)
		_reveal_button.pressed.connect(Callable(self, "_handle_memory_reveal"))
		actions.add_child(_reveal_button)

	var release_button := _make_button("Release", COLOR_GREEN)
	release_button.pressed.connect(Callable(self, "_handle_physics_release"))
	actions.add_child(release_button)

	var reset_button := _make_button("Reset", COLOR_BLUE)
	reset_button.pressed.connect(Callable(self, "_handle_freehand_physics_reset"))
	actions.add_child(reset_button)

	_reset_freehand_physics_attempt(false)
	if _uses_reveal_freehand_physics():
		_add_feedback(stage_box, "Remember the cup. Draw one ramp, then release the ball.")
	else:
		_add_feedback(stage_box, "Draw one ramp, then release the ball.")


func _render_physics_draw_choice_fallback(stage_box: VBoxContainer) -> void:
	var surface := PanelContainer.new()
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.add_theme_stylebox_override("panel", _flat_box(Color(0.91, 0.88, 0.76), 8))
	stage_box.add_child(surface)

	var surface_box := VBoxContainer.new()
	surface_box.alignment = BoxContainer.ALIGNMENT_CENTER
	surface_box.add_theme_constant_override("separation", 6)
	surface.add_child(surface_box)

	_add_label(surface_box, "BALL -> selected line -> CUP", 18, COLOR_INK)
	_physics_choice_label = _new_label("Selected line: none", 16, COLOR_INK)
	surface_box.add_child(_physics_choice_label)
	_physics_result_label = _new_label("Release result: waiting on fake gravity", 16, COLOR_INK)
	surface_box.add_child(_physics_result_label)

	var options = _rules().get("draw_options", [])
	if typeof(options) == TYPE_ARRAY:
		for option in options:
			if typeof(option) != TYPE_DICTIONARY:
				continue

			var option_button := _make_button("Draw: %s" % str(option.get("label", "Line")), _target_color(option))
			option_button.pressed.connect(Callable(self, "_handle_physics_draw").bind(str(option.get("id", ""))))
			stage_box.add_child(option_button)

	var release_button := _make_button("Release Ball", COLOR_GREEN)
	release_button.pressed.connect(Callable(self, "_handle_physics_release"))
	stage_box.add_child(release_button)

	_add_feedback(stage_box, "Deterministic choice fallback until this Level gets a direct drawing spec.")


func _create_freehand_built_in_geometry(surface: Control) -> void:
	_freehand_built_in_lines = []

	var geometries = _rules().get("built_in_geometry", [])
	if typeof(geometries) != TYPE_ARRAY or geometries.is_empty():
		return
	if _freehand_physics_runtime == null or not is_instance_valid(_freehand_physics_runtime):
		return

	_freehand_built_in_body = StaticBody2D.new()
	_freehand_built_in_body.name = "freehand_built_in_body"
	_freehand_physics_runtime.add_child(_freehand_built_in_body)

	var collision_index := 0
	for geometry in geometries:
		if typeof(geometry) != TYPE_DICTIONARY:
			continue
		var geometry_id := str(geometry.get("id", "geometry"))
		var points := _vector2_points_from_pairs(geometry.get("points", []))
		if points.size() < 2:
			continue
		var thickness := float(geometry.get("collision_thickness_px", _freehand_collision_thickness()))

		var line := Line2D.new()
		line.name = "freehand_built_in_geometry_%s" % geometry_id
		line.points = PackedVector2Array(points)
		line.width = thickness
		line.default_color = Color(0.12, 0.13, 0.16, 0.46)
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.z_index = 1
		surface.add_child(line)
		_freehand_built_in_lines.append(line)

		for index in range(points.size() - 1):
			collision_index = _add_segment_collision_shape(
				_freehand_built_in_body,
				"freehand_built_in_collision",
				points[index],
				points[index + 1],
				thickness,
				collision_index
			)

	_freehand_built_in_body.set_meta("collision_shape_count", collision_index)


func _create_freehand_goal(surface: Control) -> void:
	var goal_rect := _freehand_goal_rect()
	var visible_rect := goal_rect.grow(_freehand_goal_forgiveness())

	_freehand_cup_visual = Panel.new()
	_freehand_cup_visual.name = "freehand_cup"
	_freehand_cup_visual.position = visible_rect.position
	_freehand_cup_visual.size = visible_rect.size
	_freehand_cup_visual.custom_minimum_size = visible_rect.size
	_freehand_cup_visual.z_index = 2
	_freehand_cup_visual.set_meta("goal_rect", goal_rect)
	if _uses_reveal_freehand_physics():
		_freehand_cup_visual.visible = false
		_freehand_cup_visual.add_theme_stylebox_override("panel", _flat_box(Color(0.30, 0.82, 0.50, 0.72), 8))
	else:
		_freehand_cup_visual.add_theme_stylebox_override("panel", _flat_box(Color(0.30, 0.82, 0.50, 0.42), 8))
	surface.add_child(_freehand_cup_visual)

	var label := _new_label("CUP", 16, COLOR_INK)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_freehand_cup_visual.add_child(label)

	if _freehand_physics_runtime == null or not is_instance_valid(_freehand_physics_runtime):
		return

	_freehand_goal_area = Area2D.new()
	_freehand_goal_area.name = "freehand_goal_area"
	_freehand_goal_area.position = visible_rect.get_center()
	_freehand_goal_area.set_meta("goal_rect", goal_rect)
	_freehand_goal_area.set_meta("forgiveness_px", _freehand_goal_forgiveness())
	_freehand_physics_runtime.add_child(_freehand_goal_area)

	var shape := RectangleShape2D.new()
	shape.size = visible_rect.size
	var collision := CollisionShape2D.new()
	collision.name = "freehand_goal_collision"
	collision.shape = shape
	_freehand_goal_area.add_child(collision)


func _create_freehand_ball(surface: Control) -> void:
	var radius := _freehand_ball_radius()
	_freehand_ball_start = _freehand_ball_start_from_rules()
	_freehand_last_ball_position = _freehand_ball_start

	_freehand_ball_visual = Panel.new()
	_freehand_ball_visual.name = "freehand_ball"
	_freehand_ball_visual.position = _freehand_ball_start - Vector2(radius, radius)
	_freehand_ball_visual.size = Vector2(radius * 2.0, radius * 2.0)
	_freehand_ball_visual.custom_minimum_size = _freehand_ball_visual.size
	_freehand_ball_visual.z_index = 5
	_freehand_ball_visual.add_theme_stylebox_override("panel", _flat_box(COLOR_YELLOW, int(radius)))
	surface.add_child(_freehand_ball_visual)

	if _freehand_physics_runtime == null or not is_instance_valid(_freehand_physics_runtime):
		return

	_freehand_ball_body = RigidBody2D.new()
	_freehand_ball_body.name = "freehand_ball_body"
	_freehand_ball_body.position = _freehand_ball_start
	_freehand_ball_body.freeze = true
	_freehand_ball_body.gravity_scale = 1.0
	_freehand_physics_runtime.add_child(_freehand_ball_body)

	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.name = "freehand_ball_collision"
	collision.shape = shape
	_freehand_ball_body.add_child(collision)


func _uses_direct_tap_scene() -> bool:
	return str(_rules().get("interaction_model", "")) == "direct_tap_scene"


func _uses_direct_text_tiles() -> bool:
	return str(_rules().get("interaction_model", "")) == "direct_word_tiles"


func _uses_direct_memory_tiles() -> bool:
	return str(_rules().get("interaction_model", "")) == "direct_memory_tiles"


func _uses_direct_physics_draw() -> bool:
	return str(_rules().get("interaction_model", "")) == "direct_draw_line_then_release"


func _uses_freehand_physics_draw() -> bool:
	var model := str(_rules().get("interaction_model", ""))
	return model == "freehand_physics_then_release" or model == "reveal_then_freehand_physics"


func _uses_reveal_freehand_physics() -> bool:
	return str(_rules().get("interaction_model", "")) == "reveal_then_freehand_physics"


func _uses_physics_linked_rearrange() -> bool:
	return str(_rules().get("interaction_model", "")) == "physics_linked_rearrange_then_release"


func _make_direct_tap_target(target: Dictionary, index: int) -> PanelContainer:
	var target_id := str(target.get("id", "target"))
	var label_text := str(target.get("label", "Tap"))
	var pad := PanelContainer.new()
	pad.name = "tap_scene_target_%s" % target_id
	pad.custom_minimum_size = _vector2_from_array(target.get("scene_size", []), Vector2(138, 96))
	pad.size = pad.custom_minimum_size
	pad.position = _vector2_from_array(target.get("scene_position", []), Vector2(28 + (index * 162), 92))
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	pad.set_meta("target_id", target_id)
	pad.set_meta("scene_position", pad.position)
	pad.add_theme_stylebox_override("panel", _flat_box(COLOR_BLUE, 8))
	pad.gui_input.connect(Callable(self, "_handle_direct_tap_scene_input").bind(target_id, pad))

	var label := _new_label(label_text, _direct_tap_target_font_size(label_text), COLOR_TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(label)
	return pad


func _direct_tap_target_font_size(text: String) -> int:
	if text.length() >= 7:
		return 20
	if text.length() >= 4:
		return 21
	return 25


func _layout_direct_tap_targets(surface: Control) -> void:
	if surface == null or not is_instance_valid(surface):
		return

	var pads: Array[Control] = []
	for child in surface.get_children():
		if child is Control and str(child.name).begins_with("tap_scene_target_"):
			pads.append(child as Control)
	if pads.is_empty():
		return
	if surface.size.x <= 0.0:
		return

	var side_padding := 18.0
	var gap := 12.0
	var target_width := clampf(
		(surface.size.x - (side_padding * 2.0) - (gap * float(pads.size() - 1))) / float(pads.size()),
		84.0,
		156.0
	)
	var total_width := (target_width * float(pads.size())) + (gap * float(pads.size() - 1))
	var start_x := maxf(side_padding, (surface.size.x - total_width) * 0.5)
	for index in range(pads.size()):
		var pad := pads[index]
		var original_position: Vector2 = pad.get_meta("scene_position", Vector2(0, 92))
		pad.size = Vector2(target_width, maxf(pad.size.y, 96.0))
		pad.custom_minimum_size = pad.size
		var x := start_x + (float(index) * (target_width + gap))
		pad.position = Vector2(x, original_position.y)


func _make_text_tile(tile_data: Dictionary, index: int) -> PanelContainer:
	var tile_id := str(tile_data.get("id", "tile_%d" % index))
	var tile := PanelContainer.new()
	tile.name = "text_tile_%s" % tile_id
	tile.position = _vector2_from_array(tile_data.get("scene_position", []), Vector2(18 + ((index % 3) * 102), 148 + (int(index / 3) * 74)))
	tile.size = _vector2_from_array(tile_data.get("scene_size", []), Vector2(96, 62))
	tile.custom_minimum_size = tile.size
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.set_meta("token_id", tile_id)
	tile.add_theme_stylebox_override("panel", _flat_box(COLOR_BLUE, 8))
	tile.gui_input.connect(Callable(self, "_handle_direct_text_tile_input").bind(
		tile_id,
		str(tile_data.get("answer", tile_data.get("label", ""))),
		tile
	))

	var label := _new_label(str(tile_data.get("label", tile_id)), 18, COLOR_TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)
	return tile


func _make_drag_tile(object: Dictionary) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.name = "drag_tile_%s" % str(object.get("id", "object"))
	tile.custom_minimum_size = Vector2(136, 62)
	tile.size = tile.custom_minimum_size
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.add_theme_stylebox_override("panel", _flat_box(_target_color(object), 8))
	tile.set_meta("object_id", str(object.get("id", "")))
	tile.gui_input.connect(Callable(self, "_handle_drag_tile_input").bind(str(object.get("id", "")), tile))

	var label := _new_label(str(object.get("label", "Object")), 21, COLOR_TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.add_child(label)
	return tile


func _make_drop_zone(target: Dictionary) -> PanelContainer:
	var zone := PanelContainer.new()
	zone.name = "drop_zone_%s" % str(target.get("id", "target"))
	zone.custom_minimum_size = Vector2(150, 72)
	zone.size = zone.custom_minimum_size
	zone.mouse_filter = Control.MOUSE_FILTER_PASS
	zone.add_theme_stylebox_override("panel", _flat_box(COLOR_PANEL_ALT, 8))
	zone.set_meta("target_id", str(target.get("id", "")))

	var label := _new_label(str(target.get("label", "Target")), 17, COLOR_TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zone.add_child(label)
	return zone


func _handle_drag_tile_input(event: InputEvent, object_id: String, tile: Control) -> void:
	if _is_primary_press(event):
		_dragging_object_id = object_id
		_dragging_tile = tile
		_drag_offset = _event_position_in_control(event, tile, tile)
		tile.move_to_front()
		_feedback_label.text = "Dragging %s. Drop it where truth will tolerate it." % object_id
		_mark_input_handled()
		return

	if _is_pointer_drag(event) and _dragging_tile == tile:
		_move_drag_tile(event, tile)
		_mark_input_handled()
		return

	if _is_primary_release(event) and _dragging_tile == tile:
		var canvas_position := _event_canvas_position(event, tile)
		var drop_target_id := _drop_target_at_canvas_position(canvas_position)
		_dragging_object_id = ""
		_dragging_tile = null
		_drag_offset = Vector2.ZERO
		if drop_target_id.is_empty():
			_handle_direct_drag_miss(object_id)
		else:
			_handle_direct_drag_drop(object_id, drop_target_id)
		_mark_input_handled()


func _handle_direct_tap_scene_input(event: InputEvent, target_id: String, pad: Control) -> void:
	if not _is_primary_press(event):
		return

	_last_direct_tap_target_id = target_id
	if pad != null and is_instance_valid(pad):
		pad.add_theme_stylebox_override("panel", _flat_box(COLOR_YELLOW, 8))
	_handle_tap_target(target_id)
	_mark_input_handled()


func _handle_text_input_focus_event(event: InputEvent) -> void:
	if not _is_primary_press(event):
		return

	_last_text_focus_event_was_touch = event is InputEventScreenTouch
	_focus_text_input()


func _focus_text_input() -> void:
	if _text_input == null or not is_instance_valid(_text_input):
		return

	_text_input.grab_focus()
	_text_input.edit()
	call_deferred("_show_text_input_keyboard")


func _show_text_input_keyboard() -> void:
	if _text_input == null or not is_instance_valid(_text_input):
		return
	if not _text_input.has_focus():
		return

	_text_keyboard_request_count += 1
	_last_text_keyboard_rect = _text_input.get_global_rect()
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return

	var cursor := _text_input.caret_column
	DisplayServer.virtual_keyboard_show(
		_text_input.text,
		_last_text_keyboard_rect,
		DisplayServer.KEYBOARD_TYPE_DEFAULT,
		_text_input.max_length,
		cursor,
		cursor
	)


func _handle_direct_text_tile_input(event: InputEvent, tile_id: String, answer: String, tile: Control) -> void:
	if not _is_primary_press(event):
		return

	_handle_direct_text_tile_choice(tile_id, answer, tile)
	_mark_input_handled()


func _handle_direct_text_tile_choice(tile_id: String, answer: String, tile: Control = null) -> void:
	_last_direct_text_tile_id = tile_id
	if tile != null and is_instance_valid(tile):
		tile.add_theme_stylebox_override("panel", _flat_box(COLOR_YELLOW, 8))
	if _direct_text_answer_label != null:
		_direct_text_answer_label.text = answer if not answer.is_empty() else "(blank)"

	_tap_count += 1
	_trigger_feedback("tap")
	_resolve_text_answer(answer)


func _handle_direct_memory_tile_input(event: InputEvent, item_id: String, tile: Control) -> void:
	if not _is_primary_press(event):
		return
	if _should_ignore_duplicate_direct_memory_press(event, item_id):
		_mark_input_handled()
		return

	_remember_direct_memory_press(event, item_id)
	_last_direct_memory_tile_id = item_id
	if tile != null and is_instance_valid(tile):
		tile.add_theme_stylebox_override("panel", _flat_box(COLOR_YELLOW, 8))
	_handle_memory_choice(item_id)
	_update_memory_recall_slots()
	_resolve_direct_memory_if_full()
	_mark_input_handled()


func _handle_direct_memory_clear_input(event: InputEvent, tile: Control) -> void:
	if not _is_primary_press(event):
		return
	if _should_ignore_duplicate_direct_memory_press(event, "CLEAR"):
		_mark_input_handled()
		return

	_remember_direct_memory_press(event, "CLEAR")
	_last_direct_memory_tile_id = "CLEAR"
	if tile != null and is_instance_valid(tile):
		tile.add_theme_stylebox_override("panel", _flat_box(COLOR_YELLOW, 8))
	_handle_memory_clear()
	_update_memory_recall_slots()
	_mark_input_handled()


func _should_ignore_duplicate_direct_memory_press(event: InputEvent, item_id: String) -> bool:
	if not (event is InputEventMouseButton or event is InputEventScreenTouch):
		return false
	if item_id != _last_direct_memory_press_item_id:
		return false

	var current_press_is_touch := event is InputEventScreenTouch
	if current_press_is_touch == _last_direct_memory_press_was_touch:
		return false
	return Time.get_ticks_msec() - _last_direct_memory_press_msec <= 160


func _remember_direct_memory_press(event: InputEvent, item_id: String) -> void:
	_last_direct_memory_press_item_id = item_id
	_last_direct_memory_press_msec = Time.get_ticks_msec()
	_last_direct_memory_press_was_touch = event is InputEventScreenTouch


func _move_drag_tile(event: InputEvent, tile: Control) -> void:
	var playfield := tile.get_parent() as Control
	if playfield == null:
		return

	var pointer_position := _event_position_in_control(event, playfield, tile)
	var next_position := pointer_position - _drag_offset
	var max_x = max(0.0, playfield.size.x - tile.size.x)
	var max_y = max(42.0, playfield.size.y - tile.size.y)
	tile.position = Vector2(
		clamp(next_position.x, 0.0, max_x),
		clamp(next_position.y, 42.0, max_y)
	)


func _drop_target_at_canvas_position(canvas_position: Vector2) -> String:
	for target_id in _drag_drop_zones.keys():
		var zone = _drag_drop_zones[target_id] as Control
		if zone != null and is_instance_valid(zone) and zone.get_global_rect().has_point(canvas_position):
			return str(target_id)
	return ""


func _handle_direct_drag_miss(object_id: String) -> void:
	_tap_count += 1
	_trigger_feedback("tap")
	_last_drag_drop_target_id = ""
	_feedback_label.text = "%s hit empty space. The floor is not a valid argument." % object_id
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _handle_physics_surface_input(event: InputEvent, surface: Control) -> void:
	if _is_primary_press(event):
		if _uses_reveal_freehand_physics():
			_set_memory_reveal_visible(false)
		_physics_is_drawing = true
		_physics_has_drawn_line = false
		_physics_choice = ""
		_last_physics_result = "drawing"
		_physics_draw_start = _event_position_in_control_clamped(event, surface, surface)
		_physics_draw_end = _physics_draw_start
		if _uses_freehand_physics_draw():
			_clear_freehand_stroke_collision()
			_freehand_stroke_points = [_physics_draw_start]
			_set_physics_line_path(_freehand_stroke_points)
		else:
			_set_physics_line_points(_physics_draw_start, _physics_draw_end)
		_update_physics_choice_label()
		_feedback_label.text = "Drawing. Aim like gravity is watching."
		_mark_input_handled()
		return

	if _is_pointer_drag(event) and _physics_is_drawing:
		_physics_draw_end = _event_position_in_control_clamped(event, surface, surface)
		if _uses_freehand_physics_draw():
			_append_freehand_stroke_point(_physics_draw_end)
			_set_physics_line_path(_freehand_stroke_points)
		else:
			_set_physics_line_points(_physics_draw_start, _physics_draw_end)
		_mark_input_handled()
		return

	if _is_primary_release(event) and _physics_is_drawing:
		_physics_draw_end = _event_position_in_control_clamped(event, surface, surface)
		if _uses_freehand_physics_draw():
			_append_freehand_stroke_point(_physics_draw_end, true)
		_record_physics_drawn_line()
		_mark_input_handled()


func _record_physics_drawn_line() -> void:
	_physics_is_drawing = false
	_physics_has_drawn_line = true
	_tap_count += 1
	_trigger_feedback("tap")
	if _uses_freehand_physics_draw():
		if _freehand_stroke_points.is_empty():
			_freehand_stroke_points = [_physics_draw_start, _physics_draw_end]
		_set_physics_line_path(_freehand_stroke_points)
		_record_freehand_physics_stroke()
		return

	_set_physics_line_points(_physics_draw_start, _physics_draw_end)
	_physics_choice = _classify_physics_line(_physics_draw_start, _physics_draw_end)
	_last_physics_result = "selected"
	_update_physics_choice_label()
	_feedback_label.text = "Drew %s. Release the ball and let fake gravity judge you." % _physics_draw_label(_physics_choice)


func _simulate_physics_draw_line(start: Vector2, end: Vector2) -> void:
	_physics_draw_start = start
	_physics_draw_end = end
	if _uses_freehand_physics_draw():
		_freehand_stroke_points = [start, end]
	_record_physics_drawn_line()


func _set_physics_line_points(start: Vector2, end: Vector2) -> void:
	if _physics_line == null or not is_instance_valid(_physics_line):
		return
	_physics_line.points = PackedVector2Array([start, end])


func _set_physics_line_path(points: Array[Vector2]) -> void:
	if _physics_line == null or not is_instance_valid(_physics_line):
		return
	_physics_line.points = PackedVector2Array(points)


func _append_freehand_stroke_point(point: Vector2, force: bool = false) -> void:
	if _freehand_stroke_points.is_empty():
		_freehand_stroke_points.append(point)
		return

	var last_point := _freehand_stroke_points[_freehand_stroke_points.size() - 1]
	if not force and last_point.distance_to(point) < 6.0:
		return

	var max_points := _freehand_max_sampled_points()
	if _freehand_stroke_points.size() >= max_points:
		_freehand_stroke_points[_freehand_stroke_points.size() - 1] = point
		return

	_freehand_stroke_points.append(point)


func _record_freehand_physics_stroke() -> void:
	_physics_choice = ""
	_freehand_ball_moved = false
	_freehand_last_ball_position = _freehand_ball_start_from_rules()
	var length := _freehand_stroke_length(_freehand_stroke_points)
	if length < _freehand_min_length():
		_last_physics_result = "too_short"
		_clear_freehand_stroke_collision()
		_set_freehand_status_text("Stroke: too short", "Release result: too short")
		_feedback_label.text = _freehand_too_short_message()
		return

	_build_freehand_stroke_collision()
	_last_physics_result = "ready"
	_set_freehand_status_text("Stroke: solid %s" % _freehand_stroke_noun(), "Release result: ready")
	_feedback_label.text = "Stroke is solid. Tap Release."


func _handle_freehand_physics_release() -> void:
	_tap_count += 1
	_trigger_feedback("tap")

	if not _physics_has_drawn_line or _freehand_stroke_points.size() < 2:
		_fail_freehand_physics("Draw a %s before Release." % _freehand_stroke_noun(), "no_line")
		return

	var failure_text := _freehand_release_failure_text()
	if not failure_text.is_empty():
		_fail_freehand_physics(failure_text, "fail")
		return

	_move_freehand_ball_to_goal()
	if _freehand_ball_overlaps_goal():
		_last_physics_result = "success"
		if _uses_reveal_freehand_physics():
			_set_memory_reveal_visible(true, false)
		_set_freehand_status_text("Stroke: %s accepted" % _freehand_stroke_noun(), "Release result: ball reached the cup")
		_feedback_label.text = "Ball reached the cup."
		_complete_current_level()
		return

	_fail_freehand_physics(_freehand_missed_goal_message(), "fail")


func _handle_freehand_physics_reset() -> void:
	_reset_freehand_physics_attempt(true)


func _reset_freehand_physics_attempt(count_action: bool = true) -> void:
	if count_action:
		_tap_count += 1
		_trigger_feedback("tap")

	_physics_is_drawing = false
	_physics_has_drawn_line = false
	_physics_choice = ""
	_last_physics_result = "reset"
	_physics_draw_start = Vector2.ZERO
	_physics_draw_end = Vector2.ZERO
	_freehand_stroke_points = []
	_freehand_ball_moved = false
	_freehand_ball_start = _freehand_ball_start_from_rules()
	_freehand_last_ball_position = _freehand_ball_start
	_clear_freehand_stroke_collision()

	if _physics_line != null and is_instance_valid(_physics_line):
		_physics_line.points = PackedVector2Array()
	_set_freehand_ball_center(_freehand_ball_start)
	_set_freehand_status_text("Stroke: none", "Release result: waiting")
	if _uses_reveal_freehand_physics():
		_start_memory_reveal_attempt()
	if _feedback_label != null and is_instance_valid(_feedback_label):
		if _uses_reveal_freehand_physics():
			_feedback_label.text = "Reset. Remember the cup, draw one %s, then release the ball." % _freehand_stroke_noun()
		else:
			_feedback_label.text = "Reset. Draw one %s, then release the ball." % _freehand_stroke_noun()


func _start_memory_reveal_attempt() -> void:
	_cancel_memory_reveal_timer()
	_reveal_optional_reveals_remaining = _memory_reveal_optional_count()
	_update_memory_reveal_button_state()
	_show_memory_reveal_for_duration()


func _handle_memory_reveal() -> void:
	if not _uses_reveal_freehand_physics():
		return
	if _reveal_optional_reveals_remaining <= 0:
		_update_memory_reveal_button_state()
		return

	_tap_count += 1
	_trigger_feedback("tap")
	_reveal_optional_reveals_remaining -= 1
	_update_memory_reveal_button_state()
	_show_memory_reveal_for_duration()
	_feedback_label.text = "Cup revealed. Remember it before it gets shy."


func _show_memory_reveal_for_duration() -> void:
	_set_memory_reveal_visible(true)
	_schedule_memory_reveal_hide(_memory_reveal_seconds())


func _set_memory_reveal_visible(visible: bool, cancel_timer: bool = true) -> void:
	if cancel_timer and not visible:
		_cancel_memory_reveal_timer()
	_reveal_visible = visible
	if _freehand_cup_visual != null and is_instance_valid(_freehand_cup_visual):
		_freehand_cup_visual.visible = visible
		_freehand_cup_visual.set_meta("reveal_visible", visible)


func _schedule_memory_reveal_hide(delay_seconds: float) -> void:
	_cancel_memory_reveal_timer()
	_reveal_hide_at_msec = Time.get_ticks_msec() + int(maxf(delay_seconds, 0.1) * 1000.0)


func _hide_memory_reveal_from_timer() -> void:
	_reveal_hide_at_msec = 0
	_set_memory_reveal_visible(false, false)


func _cancel_memory_reveal_timer() -> void:
	_reveal_hide_at_msec = 0


func _update_memory_reveal_button_state() -> void:
	if _reveal_button != null and is_instance_valid(_reveal_button):
		_reveal_button.disabled = _reveal_optional_reveals_remaining <= 0


func _fail_freehand_physics(message: String, result: String) -> void:
	_last_physics_result = result
	_set_freehand_status_text("Stroke: needs work", "Release result: %s" % message)
	_feedback_label.text = message
	if _uses_reveal_freehand_physics():
		_reveal_failure_flash_count += 1
		_show_memory_reveal_for_duration()
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _freehand_release_failure_text() -> String:
	if _freehand_solution_kind() == "stopper":
		return _freehand_stopper_release_failure_text()
	return _freehand_ramp_release_failure_text()


func _freehand_ramp_release_failure_text() -> String:
	var length := _freehand_stroke_length(_freehand_stroke_points)
	if length < _freehand_min_length():
		return _freehand_too_short_message()

	var start := _freehand_stroke_points[0]
	var end := _freehand_stroke_points[_freehand_stroke_points.size() - 1]
	var delta := end - start
	if delta.x < 80.0:
		return "Missed the cup. Push the ramp toward the goal."
	if delta.y > -18.0:
		return "Too flat. Lift the end closer to the cup."

	var ball := _freehand_ball_start_from_rules()
	var starts_near_ball := start.distance_to(ball) <= 130.0
	starts_near_ball = starts_near_ball or _distance_point_to_segment(ball, start, end) <= 64.0
	if not starts_near_ball:
		return "Draw under the ball. Gravity can handle the paperwork."

	var goal_rect := _freehand_goal_rect()
	var generous_goal := goal_rect.grow(max(54.0, _freehand_goal_forgiveness() + 34.0))
	if not generous_goal.has_point(end):
		return "Missed the cup. Try lifting the end closer to the goal."

	return ""


func _freehand_stopper_release_failure_text() -> String:
	var length := _freehand_stroke_length(_freehand_stroke_points)
	if length < _freehand_min_length():
		return _freehand_too_short_message()

	var bounds := _freehand_stroke_bounds()
	if bounds.size.x > 96.0 or bounds.size.x > bounds.size.y * 1.25:
		return "Overshot. The ball did not need encouragement."
	if bounds.size.y < 36.0:
		return "Too flat. Draw a stopper the ball can actually hit."

	var sweet_spot := _freehand_stopper_sweet_spot_rect().grow(28.0)
	if not _freehand_stroke_overlaps_rect(sweet_spot):
		return "Missed the cup. Draw the stopper just past the cup."

	return ""


func _build_freehand_stroke_collision() -> void:
	_clear_freehand_stroke_collision()
	if _freehand_physics_runtime == null or not is_instance_valid(_freehand_physics_runtime):
		return

	_freehand_stroke_body = StaticBody2D.new()
	_freehand_stroke_body.name = "freehand_stroke_body"
	_freehand_stroke_body.set_meta("collision_thickness_px", _freehand_collision_thickness())
	_freehand_stroke_body.set_meta("sampled_point_count", _freehand_stroke_points.size())
	_freehand_physics_runtime.add_child(_freehand_stroke_body)

	var segment_count := 0
	for index in range(_freehand_stroke_points.size() - 1):
		var start := _freehand_stroke_points[index]
		var end := _freehand_stroke_points[index + 1]
		segment_count = _add_segment_collision_shape(
			_freehand_stroke_body,
			"freehand_stroke_collision",
			start,
			end,
			_freehand_collision_thickness(),
			segment_count
		)

	_freehand_stroke_body.set_meta("collision_shape_count", segment_count)


func _add_segment_collision_shape(parent: Node, name_prefix: String, start: Vector2, end: Vector2, thickness: float, segment_index: int) -> int:
	var delta := end - start
	var length := delta.length()
	if length < 2.0:
		return segment_index

	var shape := RectangleShape2D.new()
	shape.size = Vector2(length, thickness)
	var collision := CollisionShape2D.new()
	collision.name = "%s_%02d" % [name_prefix, segment_index]
	collision.shape = shape
	collision.position = start + (delta * 0.5)
	collision.rotation = delta.angle()
	parent.add_child(collision)
	return segment_index + 1


func _clear_freehand_stroke_collision() -> void:
	if _freehand_stroke_body == null or not is_instance_valid(_freehand_stroke_body):
		_freehand_stroke_body = null
		return

	var parent := _freehand_stroke_body.get_parent()
	if parent != null:
		parent.remove_child(_freehand_stroke_body)
	_freehand_stroke_body.queue_free()
	_freehand_stroke_body = null


func _move_freehand_ball_to_goal() -> void:
	var goal_center := _freehand_goal_rect().get_center()
	_freehand_ball_moved = _freehand_ball_start_from_rules().distance_to(goal_center) > 1.0
	_freehand_last_ball_position = goal_center
	_set_freehand_ball_center(goal_center)


func _set_freehand_ball_center(center: Vector2) -> void:
	var radius := _freehand_ball_radius()
	if _freehand_ball_visual != null and is_instance_valid(_freehand_ball_visual):
		_freehand_ball_visual.position = center - Vector2(radius, radius)
	if _freehand_ball_body != null and is_instance_valid(_freehand_ball_body):
		_freehand_ball_body.position = center


func _freehand_ball_overlaps_goal() -> bool:
	return _circle_overlaps_rect(_freehand_last_ball_position, _freehand_ball_radius(), _freehand_goal_rect().grow(_freehand_goal_forgiveness()))


func _freehand_stroke_noun() -> String:
	if _freehand_solution_kind() == "stopper":
		return "stopper"
	return "ramp"


func _freehand_solution_kind() -> String:
	var kind := str(_rules().get("freehand_solution_kind", "")).strip_edges().to_lower()
	if not kind.is_empty():
		return kind
	if _rules().has("stopper_sweet_spot"):
		return "stopper"
	return "ramp"


func _freehand_too_short_message() -> String:
	if _freehand_solution_kind() == "stopper":
		return "Too short. Draw something the ball can actually hit."
	return "Too short. Give the ball something real to roll on."


func _freehand_missed_goal_message() -> String:
	if _freehand_solution_kind() == "stopper":
		return "Overshot. The ball did not need encouragement."
	return "Missed the cup. Try lifting the end closer to the goal."


func _circle_overlaps_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(center.y, rect.position.y, rect.position.y + rect.size.y)
	)
	return center.distance_to(closest) <= radius


func _distance_point_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + (segment * t))


func _freehand_stroke_length(points: Array[Vector2]) -> float:
	var length := 0.0
	for index in range(points.size() - 1):
		length += points[index].distance_to(points[index + 1])
	return length


func _freehand_stroke_bounds() -> Rect2:
	if _freehand_stroke_points.is_empty():
		return Rect2()

	var min_x := _freehand_stroke_points[0].x
	var max_x := min_x
	var min_y := _freehand_stroke_points[0].y
	var max_y := min_y
	for point in _freehand_stroke_points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _freehand_stroke_overlaps_rect(rect: Rect2) -> bool:
	for point in _freehand_stroke_points:
		if rect.has_point(point):
			return true

	for index in range(_freehand_stroke_points.size() - 1):
		var segment_rect := _segment_bounds(_freehand_stroke_points[index], _freehand_stroke_points[index + 1]).grow(_freehand_collision_thickness() * 0.5)
		if segment_rect.intersects(rect, true):
			return true
	return false


func _segment_bounds(start: Vector2, end: Vector2) -> Rect2:
	var min_x := minf(start.x, end.x)
	var min_y := minf(start.y, end.y)
	return Rect2(min_x, min_y, absf(end.x - start.x), absf(end.y - start.y))


func _set_freehand_status_text(stroke_text: String, result_text: String) -> void:
	if _physics_choice_label != null and is_instance_valid(_physics_choice_label):
		_physics_choice_label.text = stroke_text
	if _physics_result_label != null and is_instance_valid(_physics_result_label):
		_physics_result_label.text = result_text


func _freehand_draw_limit() -> Dictionary:
	return _dictionary_from(_rules().get("draw_limit", {}))


func _memory_reveal_rules() -> Dictionary:
	return _dictionary_from(_rules().get("reveal", {}))


func _memory_reveal_seconds() -> float:
	return float(_memory_reveal_rules().get("auto_reveal_seconds", 1.1))


func _memory_reveal_optional_count() -> int:
	return max(0, int(_memory_reveal_rules().get("optional_reveal_count", 1)))


func _freehand_min_length() -> float:
	return float(_freehand_draw_limit().get("min_length_px", 70.0))


func _freehand_max_sampled_points() -> int:
	return max(2, int(_freehand_draw_limit().get("max_sampled_points", 30)))


func _freehand_collision_thickness() -> float:
	return float(_freehand_draw_limit().get("collision_thickness_px", 12.0))


func _freehand_ball_start_from_rules() -> Vector2:
	var moving_object := _dictionary_from(_rules().get("moving_object", {}))
	return _vector2_from_array(moving_object.get("start", []), Vector2(58, 218))


func _freehand_ball_radius() -> float:
	var moving_object := _dictionary_from(_rules().get("moving_object", {}))
	return float(moving_object.get("radius", 16.0))


func _freehand_goal_rect() -> Rect2:
	var goal_zone := _dictionary_from(_rules().get("goal_zone", {}))
	return _rect2_from_array(goal_zone.get("rect", []), Rect2(258, 146, 54, 58))


func _freehand_goal_forgiveness() -> float:
	var goal_zone := _dictionary_from(_rules().get("goal_zone", {}))
	return float(goal_zone.get("forgiveness_px", 14.0))


func _freehand_stopper_sweet_spot_rect() -> Rect2:
	var sweet_spot := _dictionary_from(_rules().get("stopper_sweet_spot", {}))
	if sweet_spot.has("rect"):
		return _rect2_from_array(sweet_spot.get("rect", []), Rect2(268, 166, 36, 72))
	return _rect2_from_array(_rules().get("stopper_sweet_spot", []), Rect2(268, 166, 36, 72))


func _freehand_verifier_points(draw_id: String) -> Array[Vector2]:
	if _freehand_solution_kind() == "stopper":
		if draw_id == "flat_line" or draw_id == "ramp_to_cup":
			return [Vector2(42, 232), Vector2(288, 176)]
		if draw_id == "wall":
			return [Vector2(170, 164), Vector2(170, 230)]
		if draw_id == "too_short":
			return [Vector2(284, 184), Vector2(288, 210)]
		return [Vector2(286, 168), Vector2(286, 234)]

	var start := Vector2(42, 232)
	var end := Vector2(288, 176)
	if draw_id == "flat_line":
		end = Vector2(288, 232)
	elif draw_id == "wall":
		end = Vector2(58, 174)
	return [start, end]


func _classify_physics_line(start: Vector2, end: Vector2) -> String:
	var gesture := str(_rules().get("direct_draw_gesture", ""))
	if not gesture.is_empty():
		if _line_matches_gesture(gesture, start, end):
			return str(_solution().get("draw_id", ""))
		return _first_wrong_physics_draw_id()

	var delta := end - start
	if delta.length() < 36.0:
		return "wall"
	if abs(delta.x) < 28.0:
		return "wall"
	if delta.x > 48.0 and delta.y < -12.0:
		return "ramp_to_cup"
	if abs(delta.y) < 22.0:
		return "flat_line"
	return "flat_line"


func _line_matches_gesture(gesture: String, start: Vector2, end: Vector2) -> bool:
	var delta := end - start
	var length := delta.length()
	if length < 36.0:
		return false

	match gesture:
		"rising_ramp":
			return delta.x > 48.0 and delta.y < -12.0
		"high_bridge":
			return abs(delta.y) < 24.0 and abs(delta.x) > 90.0 and min(start.y, end.y) < 130.0
		"rising_vertical":
			return abs(delta.x) < 36.0 and delta.y < -80.0
		"right_flat":
			return delta.x > 90.0 and abs(delta.y) < 26.0
		"balloon_hook":
			return delta.x > 18.0 and delta.x < 90.0 and delta.y < -90.0
		"falling_slope":
			return delta.x > 48.0 and delta.y > 18.0
		"shallow_rise":
			return delta.x > 90.0 and delta.y < -12.0 and delta.y > -60.0
		_:
			return false


func _first_wrong_physics_draw_id() -> String:
	var solution_id := str(_solution().get("draw_id", ""))
	var options = _rules().get("draw_options", [])
	if typeof(options) == TYPE_ARRAY:
		for option in options:
			if typeof(option) != TYPE_DICTIONARY:
				continue
			var draw_id := str(option.get("id", ""))
			if not draw_id.is_empty() and draw_id != solution_id:
				return draw_id
	return ""


func _is_primary_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	return false


func _is_primary_release(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


func _is_pointer_drag(event: InputEvent) -> bool:
	return event is InputEventMouseMotion or event is InputEventScreenDrag


func _event_canvas_position(event: InputEvent, local_node: Control) -> Vector2:
	if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return local_node.get_global_transform_with_canvas() * event.position
	var viewport := get_viewport()
	if viewport != null:
		return viewport.get_mouse_position()
	return Vector2.ZERO


func _event_position_in_control(event: InputEvent, control: Control, local_node: Control) -> Vector2:
	return control.get_global_transform_with_canvas().affine_inverse() * _event_canvas_position(event, local_node)


func _event_position_in_control_clamped(event: InputEvent, control: Control, local_node: Control) -> Vector2:
	return _clamp_point_to_control(_event_position_in_control(event, control, local_node), control)


func _clamp_point_to_control(point: Vector2, control: Control) -> Vector2:
	if control.size.x <= 0.0 or control.size.y <= 0.0:
		return point
	return Vector2(
		clampf(point.x, 0.0, control.size.x),
		clampf(point.y, 0.0, control.size.y)
	)


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _add_feedback(stage_box: VBoxContainer, text: String) -> void:
	_feedback_label = _new_label(text, 18, COLOR_INK)
	stage_box.add_child(_feedback_label)


func _flat_box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


func _target_color(target: Dictionary) -> Color:
	var role := str(target.get("role", "neutral"))
	if role == "correct" or role == "decoy":
		return COLOR_BLUE
	return COLOR_PANEL_ALT


func _handle_dur_level(level: Dictionary) -> void:
	if _profile.spend_dur_token(level):
		_trigger_feedback("dur_spend")
		var result := _profile.last_dur_spend_result
		_level_list_notice = "DUR'D Level %02d. Dur %d/%d. Level %02d unlocked." % [
			int(result.get("level_number", 0)),
			int(result.get("tokens_after", 0)),
			LocalProfileScript.MAX_DUR_TOKENS,
			int(result.get("unlocked_level", 1)),
		]
	else:
		_trigger_feedback("fail")
		_level_list_notice = _profile.last_error

	_show_level_list()


func _add_profile_status(parent: Node) -> void:
	if not _profile.last_error.is_empty():
		_add_status(parent, _profile.last_error, COLOR_RED)
		return

	_add_status(parent, "Local Profile: UQIQ %d | Dur %d/%d | Level %02d unlocked" % [
		_profile.current_uqiq_score(),
		_profile.dur_tokens(),
		LocalProfileScript.MAX_DUR_TOKENS,
		int(_profile.data.get("unlocked_level", 1)),
	], COLOR_MUTED)


func _is_level_playable(level: Dictionary) -> bool:
	var level_number := int(level.get("level_number", 0))
	if _debug_playtest_unlock_all() and _is_supported_playable_level_spec(level):
		return true
	return _profile.is_level_unlocked(level_number) and _is_supported_playable_level_spec(level)


func _is_supported_playable_level_spec(level: Dictionary) -> bool:
	if not SUPPORTED_LEVEL_TEMPLATES.has(str(level.get("template", ""))):
		return false

	var rules = level.get("rules", {})
	if typeof(rules) == TYPE_DICTIONARY and bool(rules.get("future_placeholder", false)):
		return false

	return true


func _level_state_text(level: Dictionary) -> String:
	var level_id := str(level.get("id", ""))
	var level_number := int(level.get("level_number", 0))

	if _profile.is_level_completed(level_id):
		var best_attempt := _profile.get_best_attempt(level_id)
		if not best_attempt.is_empty():
			return "completed - replay | best %d action(s)" % int(best_attempt.get("action_count", 0))
		return "completed - replay"

	if _profile.is_level_durd(level_id):
		return "DUR'D - finish to recover Dur"

	if _debug_playtest_unlock_all() and _is_supported_playable_level_spec(level):
		return "playtest"

	if not _profile.is_level_unlocked(level_number):
		return "locked"

	if _is_supported_playable_level_spec(level):
		return "playable"

	return "future placeholder"


func _level_button_color(level: Dictionary) -> Color:
	var level_id := str(level.get("id", ""))
	var level_number := int(level.get("level_number", 0))

	if _profile.is_level_completed(level_id):
		return COLOR_GREEN
	if _profile.is_level_durd(level_id):
		return COLOR_ORANGE
	if _debug_playtest_unlock_all() and _is_supported_playable_level_spec(level):
		return COLOR_BLUE
	if _profile.is_level_unlocked(level_number) and _is_supported_playable_level_spec(level):
		return COLOR_BLUE
	if _profile.is_level_unlocked(level_number):
		return COLOR_PANEL_ALT
	return Color(0.22, 0.23, 0.25)


func _uses_direct_pattern_grid() -> bool:
	return str(_rules().get("interaction_model", "")) == "direct_mark_cells"


func _pattern_solution_cells() -> Array[String]:
	var solution := _solution()
	var cell_ids = solution.get("cell_ids", [])
	if typeof(cell_ids) == TYPE_ARRAY and not cell_ids.is_empty():
		return _string_array(cell_ids)

	var cell_id := str(solution.get("cell_id", ""))
	if not cell_id.is_empty():
		return [cell_id]
	return []


func _memory_solution_sequence() -> Array[String]:
	var sequence = _solution().get("sequence", [])
	if typeof(sequence) == TYPE_ARRAY:
		return _string_array(sequence)
	return []


func _update_memory_recall_slots() -> void:
	for index in _memory_slot_labels.keys():
		var label = _memory_slot_labels[index] as Label
		if label == null or not is_instance_valid(label):
			continue
		if int(index) < _memory_input.size():
			label.text = _memory_input[int(index)]
		else:
			label.text = "_"


func _resolve_direct_memory_if_full() -> void:
	var sequence := _memory_solution_sequence()
	if sequence.is_empty() or _memory_input.size() < sequence.size():
		return

	if _memory_input == sequence:
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Memory failed. The pixels had one job and so did you.")
	_set_judge_state("fail")
	_trigger_feedback("fail")


func _apply_pattern_mark_style(cell_id: String, button: Button) -> void:
	var is_marked := _pattern_marked_cells.has(cell_id)
	var color := COLOR_YELLOW if is_marked else _target_color(_pattern_cell_by_id(cell_id))
	button.add_theme_stylebox_override("normal", _flat_box(color, 8))
	button.add_theme_stylebox_override("hover", _flat_box(color.lightened(0.08), 8))
	button.add_theme_stylebox_override("pressed", _flat_box(color.darkened(0.08), 8))


func _pattern_cell_by_id(cell_id: String) -> Dictionary:
	var cells = _rules().get("cells", [])
	if typeof(cells) == TYPE_ARRAY:
		for cell in cells:
			if typeof(cell) == TYPE_DICTIONARY and str(cell.get("id", "")) == cell_id:
				return cell
	return {}


func _same_string_set(left: Array[String], right: Array[String]) -> bool:
	if left.size() != right.size():
		return false
	for value in left:
		if not right.has(value):
			return false
	return true


func _rules() -> Dictionary:
	var rules = _current_level.get("rules", {})
	if typeof(rules) == TYPE_DICTIONARY:
		return rules
	return {}


func _solution() -> Dictionary:
	var solution = _current_level.get("solution", {})
	if typeof(solution) == TYPE_DICTIONARY:
		return solution
	return {}


func _normalize_answer(answer: String) -> String:
	return answer.strip_edges().to_lower()


func _string_array(values: Array) -> Array[String]:
	var strings: Array[String] = []
	for value in values:
		strings.append(str(value))
	return strings


func _dictionary_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _vector2_from_array(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_ARRAY:
		return fallback

	var values: Array = value
	if values.size() < 2:
		return fallback
	return Vector2(float(values[0]), float(values[1]))


func _vector2_from_variant(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	return _vector2_from_array(value, Vector2.ZERO)


func _vector2_points_from_pairs(value: Variant) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if typeof(value) != TYPE_ARRAY:
		return points

	for item in value:
		if typeof(item) == TYPE_ARRAY:
			points.append(_vector2_from_array(item, Vector2.ZERO))
	return points


func _rect2_from_array(value: Variant, fallback: Rect2) -> Rect2:
	if typeof(value) != TYPE_ARRAY:
		return fallback

	var values: Array = value
	if values.size() < 4:
		return fallback
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))


func _rect2_from_variant(value: Variant) -> Rect2:
	if value is Rect2:
		return value
	return _rect2_from_array(value, Rect2())


func _score_component_text(components: Dictionary, key: String, title: String, fallback_label: String) -> String:
	var component := _dictionary_from(components.get(key, {}))
	var label := str(component.get("label", fallback_label))
	var delta := int(component.get("delta", 0))
	var detail := str(component.get("detail", ""))
	if detail.is_empty():
		return "%s: %s (%+d)" % [title, label, delta]
	return "%s: %s (%+d) | %s" % [title, label, delta, detail]


func _physics_draw_label(draw_id: String) -> String:
	if draw_id.is_empty():
		return "none"
	var options = _rules().get("draw_options", [])
	if typeof(options) == TYPE_ARRAY:
		for option in options:
			if typeof(option) == TYPE_DICTIONARY and str(option.get("id", "")) == draw_id:
				return str(option.get("label", draw_id))
	return draw_id


func _update_physics_choice_label() -> void:
	if _uses_freehand_physics_draw():
		if _last_physics_result == "drawing":
			_set_freehand_status_text("Stroke: drawing...", "Release result: line not released yet")
		elif _last_physics_result == "reset":
			_set_freehand_status_text("Stroke: none", "Release result: waiting")
		return

	if _physics_choice_label != null and is_instance_valid(_physics_choice_label):
		if _last_physics_result == "drawing":
			_physics_choice_label.text = "Selected line: drawing..."
		else:
			_physics_choice_label.text = "Selected line: %s" % _physics_draw_label(_physics_choice)
	if _physics_result_label != null and is_instance_valid(_physics_result_label):
		if _last_physics_result == "drawing":
			_physics_result_label.text = "Release result: line not released yet"
		else:
			_physics_result_label.text = "Release result: ready to test"


func _update_physics_result_label(success: bool) -> void:
	if _physics_result_label == null or not is_instance_valid(_physics_result_label):
		return
	if success:
		_physics_result_label.text = "Release result: ball reached the cup"
	else:
		_physics_result_label.text = "Release result: fake gravity rejected %s" % _physics_draw_label(_physics_choice)


func _set_judge_state(state: String) -> void:
	_judge_state = state
	_judge_state_counts[state] = int(_judge_state_counts.get(state, 0)) + 1
	if _judge_face_label != null and is_instance_valid(_judge_face_label):
		_judge_face_label.text = _judge_face_text(state)
	if _judge_caption_label != null and is_instance_valid(_judge_caption_label):
		_judge_caption_label.text = _judge_caption_text(state)


func _judge_face_text(state: String) -> String:
	match state:
		"start":
			return "(o_o)"
		"fail":
			return "(>_<)"
		"roast":
			return "(=_=)"
		"success":
			return "(^_^)"
		"score":
			return "(O_O)"
		_:
			return "(-_-)"


func _judge_caption_text(state: String) -> String:
	match state:
		"start":
			return "calibrating ego"
		"fail":
			return "incorrect aura detected"
		"roast":
			return "roast protocol armed"
		"success":
			return "begrudging approval"
		"score":
			return "score tribunal convened"
		_:
			return "watching quietly"


func _apply_screen_transition(root: Control, transition_name: String) -> void:
	if transition_name.is_empty():
		return
	_last_transition_name = transition_name
	_transition_counts[transition_name] = int(_transition_counts.get(transition_name, 0)) + 1
	root.modulate = Color(1.0, 1.0, 1.0, 0.92)
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_property(root, "modulate:a", 1.0, 0.08)


func _setup_feedback() -> void:
	if _feedback_player != null:
		return
	if DisplayServer.get_name() == "headless":
		return

	_feedback_generator = AudioStreamGenerator.new()
	_feedback_generator.mix_rate = FEEDBACK_MIX_RATE
	_feedback_generator.buffer_length = 0.08
	_feedback_player = AudioStreamPlayer.new()
	_feedback_player.name = "FeedbackPlayer"
	_feedback_player.stream = _feedback_generator
	_feedback_player.volume_db = -18.0
	add_child(_feedback_player)
	if _feedback_player.is_inside_tree():
		_feedback_player.play()


func _trigger_feedback(kind: String) -> void:
	_last_feedback_kind = kind
	_feedback_counts[kind] = int(_feedback_counts.get(kind, 0)) + 1
	_play_feedback_tone(kind)
	_pulse_feedback(kind)


func _play_feedback_tone(kind: String) -> void:
	if _feedback_player == null:
		return
	if not _feedback_player.is_inside_tree():
		return
	if not _feedback_player.playing:
		_feedback_player.play()

	var playback := _feedback_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var spec := _feedback_spec(kind)
	var frequency := float(spec.get("frequency", 440.0))
	var duration := float(spec.get("duration", 0.04))
	var volume := float(spec.get("volume", 0.10))
	_feedback_player.volume_db = float(spec.get("volume_db", -18.0))

	var frames := maxi(int(FEEDBACK_MIX_RATE * duration), 1)
	for index in range(frames):
		var progress := float(index) / float(frames)
		var envelope: float = 1.0 - progress
		var sample := sin(TAU * frequency * float(index) / FEEDBACK_MIX_RATE) * volume * envelope
		playback.push_frame(Vector2(sample, sample))


func _pulse_feedback(kind: String) -> void:
	var spec := _feedback_spec(kind)
	var haptic_ms := int(spec.get("haptic_ms", 0))
	if haptic_ms > 0:
		Input.vibrate_handheld(haptic_ms)


func _feedback_spec(kind: String) -> Dictionary:
	match kind:
		"tap":
			return {"frequency": 620.0, "duration": 0.025, "volume": 0.08, "volume_db": -22.0, "haptic_ms": 8}
		"fail":
			return {"frequency": 170.0, "duration": 0.075, "volume": 0.14, "volume_db": -18.0, "haptic_ms": 24}
		"success":
			return {"frequency": 880.0, "duration": 0.090, "volume": 0.12, "volume_db": -17.0, "haptic_ms": 32}
		"roast":
			return {"frequency": 330.0, "duration": 0.050, "volume": 0.10, "volume_db": -19.0, "haptic_ms": 14}
		"dur_spend":
			return {"frequency": 240.0, "duration": 0.070, "volume": 0.12, "volume_db": -18.0, "haptic_ms": 28}
		"dur_recover":
			return {"frequency": 760.0, "duration": 0.085, "volume": 0.12, "volume_db": -17.0, "haptic_ms": 34}
		_:
			return {"frequency": 440.0, "duration": 0.035, "volume": 0.08, "volume_db": -20.0, "haptic_ms": 0}


func _first_roast(kind: String, fallback: String) -> String:
	return _roast_line(kind, fallback, 0)


func _roast_line(kind: String, fallback: String, index: int) -> String:
	var roasts = _current_level.get("roasts", {})
	if typeof(roasts) != TYPE_DICTIONARY:
		return fallback

	var lines = roasts.get(kind, [])
	if typeof(lines) == TYPE_ARRAY and not lines.is_empty():
		return str(lines[max(index, 0) % lines.size()])

	return fallback
