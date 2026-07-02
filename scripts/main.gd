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
const DEVICE_SMOKE_ARG := "--uqiq-device-smoke"
const DEVICE_SMOKE_ENV := "UQIQ_DEVICE_SMOKE"
const FEEDBACK_MIX_RATE := 22050.0
const SUPPORTED_LEVEL_TEMPLATES := [
	"Tap Logic",
	"Drag Logic",
	"Text Trap",
	"Pattern Grid",
	"Memory Flash",
	"Physics Draw",
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
var _selected_drag_id := ""
var _dragging_object_id := ""
var _dragging_tile: Control = null
var _drag_offset := Vector2.ZERO
var _drag_drop_zones := {}
var _last_drag_drop_target_id := ""
var _selected_pattern_cell := ""
var _memory_input: Array[String] = []
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


func _ready() -> void:
	_setup_feedback()
	_pack = _load_level_pack_set()
	_packs = _pack_groups_from_pack_set(_pack)
	_profile.load_or_create()
	_show_level_list()
	if _should_run_device_smoke():
		call_deferred("_run_device_smoke")


func _should_run_device_smoke() -> bool:
	if not OS.is_debug_build():
		return false
	if OS.get_cmdline_args().has(DEVICE_SMOKE_ARG):
		return true
	return OS.get_environment(DEVICE_SMOKE_ENV) == "1"


func _run_device_smoke() -> void:
	var runner = DeviceSmokeRunnerScript.new()
	_show_device_smoke_result(runner.run(self))


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
	_selected_drag_id = ""
	_dragging_object_id = ""
	_dragging_tile = null
	_drag_offset = Vector2.ZERO
	_drag_drop_zones = {}
	_last_drag_drop_target_id = ""
	_selected_pattern_cell = ""
	_memory_input = []
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

	if target_id == winning_target:
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
	_tap_count += 1
	_trigger_feedback("tap")
	_physics_choice = draw_id
	_last_physics_result = "selected"
	_physics_has_drawn_line = true
	_update_physics_choice_label()
	_feedback_label.text = "Drew %s. Release the ball and let fake gravity judge you." % _physics_draw_label(draw_id)


func _handle_physics_release() -> void:
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

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)

	var replay_button := _make_button("Replay", COLOR_BLUE)
	replay_button.pressed.connect(Callable(self, "_show_play_screen").bind(_current_level))
	actions.add_child(replay_button)

	var list_button := _make_button("Level List", COLOR_GREEN)
	list_button.pressed.connect(Callable(self, "_show_level_list"))
	actions.add_child(list_button)


func _make_screen(background_color: Color, transition_name: String = "", use_scroll: bool = false) -> VBoxContainer:
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

		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 22)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 22)
		scroll.add_child(margin)

		root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(root)
	else:
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.offset_left = 20
		root.offset_top = 22
		root.offset_right = -20
		root.offset_bottom = -22
		add_child(root)
	root.add_theme_constant_override("separation", 14)
	_apply_screen_transition(root, transition_name)
	return root


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
		"Physics Draw":
			_render_physics_draw(stage_box)
		_:
			_add_label(stage_box, "Future template. Your brilliance has been postponed.", 18, COLOR_INK)
			_add_feedback(stage_box, "Return later when this Level stops being imaginary.")


func _render_tap_logic(stage_box: VBoxContainer) -> void:
	var targets = _rules().get("tap_targets", [])
	if typeof(targets) == TYPE_ARRAY:
		for target in targets:
			if typeof(target) != TYPE_DICTIONARY:
				continue

			var target_button := _make_button(str(target.get("label", "Tap")), _target_color(target))
			target_button.pressed.connect(Callable(self, "_handle_tap_target").bind(str(target.get("id", ""))))
			stage_box.add_child(target_button)

	_add_feedback(stage_box, "Choose carefully.")


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


func _render_text_trap(stage_box: VBoxContainer) -> void:
	_text_input = LineEdit.new()
	_text_input.placeholder_text = str(_rules().get("placeholder", "type answer"))
	_text_input.custom_minimum_size = Vector2(0, 56)
	_text_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_input.add_theme_font_size_override("font_size", 22)
	_text_input.text_submitted.connect(Callable(self, "_handle_text_submitted"))
	stage_box.add_child(_text_input)

	var submit_button := _make_button("Submit", COLOR_GREEN)
	submit_button.pressed.connect(Callable(self, "_handle_text_submit"))
	stage_box.add_child(submit_button)

	_add_feedback(stage_box, "Type the answer the prompt deserves, not the one it asked for.")


func _render_pattern_grid(stage_box: VBoxContainer) -> void:
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


func _render_memory_flash(stage_box: VBoxContainer) -> void:
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


func _render_physics_draw(stage_box: VBoxContainer) -> void:
	_add_label(stage_box, "Draw one line so the ball reaches the cup.", 17, COLOR_INK)
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


func _uses_direct_physics_draw() -> bool:
	return str(_rules().get("interaction_model", "")) == "direct_draw_line_then_release"


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
		_physics_is_drawing = true
		_physics_has_drawn_line = false
		_physics_choice = ""
		_last_physics_result = "drawing"
		_physics_draw_start = _event_position_in_control(event, surface, surface)
		_physics_draw_end = _physics_draw_start
		_set_physics_line_points(_physics_draw_start, _physics_draw_end)
		_update_physics_choice_label()
		_feedback_label.text = "Drawing. Aim like gravity is watching."
		_mark_input_handled()
		return

	if _is_pointer_drag(event) and _physics_is_drawing:
		_physics_draw_end = _event_position_in_control(event, surface, surface)
		_set_physics_line_points(_physics_draw_start, _physics_draw_end)
		_mark_input_handled()
		return

	if _is_primary_release(event) and _physics_is_drawing:
		_physics_draw_end = _event_position_in_control(event, surface, surface)
		_record_physics_drawn_line()
		_mark_input_handled()


func _record_physics_drawn_line() -> void:
	_physics_is_drawing = false
	_physics_has_drawn_line = true
	_tap_count += 1
	_trigger_feedback("tap")
	_set_physics_line_points(_physics_draw_start, _physics_draw_end)
	_physics_choice = _classify_physics_line(_physics_draw_start, _physics_draw_end)
	_last_physics_result = "selected"
	_update_physics_choice_label()
	_feedback_label.text = "Drew %s. Release the ball and let fake gravity judge you." % _physics_draw_label(_physics_choice)


func _simulate_physics_draw_line(start: Vector2, end: Vector2) -> void:
	_physics_draw_start = start
	_physics_draw_end = end
	_record_physics_drawn_line()


func _set_physics_line_points(start: Vector2, end: Vector2) -> void:
	if _physics_line == null or not is_instance_valid(_physics_line):
		return
	_physics_line.points = PackedVector2Array([start, end])


func _classify_physics_line(start: Vector2, end: Vector2) -> String:
	var delta := end - start
	if delta.length() < 36.0:
		return "wall"
	if abs(delta.x) < 28.0:
		return "wall"
	if abs(delta.y) < 22.0:
		return "flat_line"
	if delta.x > 48.0 and delta.y < -18.0:
		return "ramp_to_cup"
	return "flat_line"


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
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return local_node.get_global_transform_with_canvas() * event.position
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return event.position
	var viewport := get_viewport()
	if viewport != null:
		return viewport.get_mouse_position()
	return Vector2.ZERO


func _event_position_in_control(event: InputEvent, control: Control, local_node: Control) -> Vector2:
	return control.get_global_transform_with_canvas().affine_inverse() * _event_canvas_position(event, local_node)


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
	if role == "correct":
		return COLOR_RED
	if role == "decoy":
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
	if _profile.is_level_unlocked(level_number) and _is_supported_playable_level_spec(level):
		return COLOR_BLUE
	if _profile.is_level_unlocked(level_number):
		return COLOR_PANEL_ALT
	return Color(0.22, 0.23, 0.25)


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
