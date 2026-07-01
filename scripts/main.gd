extends Control

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")

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
var _current_level := {}
var _tap_count := 0
var _roast_count := 0
var _last_best_attempt := {}
var _last_completed_attempt := {}
var _last_score_result := {}
var _level_list_notice := ""
var _feedback_label: Label
var _text_input: LineEdit
var _selected_drag_id := ""
var _selected_pattern_cell := ""
var _memory_input: Array[String] = []
var _physics_choice := ""


func _ready() -> void:
	_pack = _loader.load_pack()
	_profile.load_or_create()
	_show_level_list()


func _show_level_list() -> void:
	var root := _make_screen(COLOR_INK)

	_add_label(root, "UQIQ", 44, COLOR_YELLOW)
	_add_label(root, "Pack 1: Orientation Is a Trap", 20, COLOR_TEXT)

	if _pack.is_empty():
		_add_status(root, _loader.last_error, COLOR_RED)
		return

	var source_path := str(_pack.get("source_path", LevelLoaderScript.DEFAULT_PACK_PATH))
	var levels: Array = _pack.get("levels", [])
	_add_status(root, "Loaded %d Level Specs from %s" % [levels.size(), source_path], COLOR_GREEN)
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

	for level in levels:
		if typeof(level) != TYPE_DICTIONARY:
			continue

		var level_number := int(level.get("level_number", 0))
		var title := str(level.get("title", "Untitled"))
		var is_playable := _is_level_playable(level)
		var button_text := "%02d  %s  |  %s" % [level_number, title, _level_state_text(level)]
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)

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
	_last_best_attempt = {}
	_last_completed_attempt = {}
	_last_score_result = {}
	_level_list_notice = ""
	_text_input = null
	_selected_drag_id = ""
	_selected_pattern_cell = ""
	_memory_input = []
	_physics_choice = ""

	var root := _make_screen(COLOR_PANEL)

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

	var solution = _current_level.get("solution", {})
	var winning_target := ""
	if typeof(solution) == TYPE_DICTIONARY:
		winning_target = str(solution.get("target_id", ""))

	if target_id == winning_target:
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Nope. Your finger has executive dysfunction.")


func _handle_drag_select(object_id: String) -> void:
	_tap_count += 1
	_selected_drag_id = object_id
	_feedback_label.text = "Holding %s. Now move it somewhere questionable." % object_id


func _handle_drag_drop(drop_target_id: String) -> void:
	_tap_count += 1

	var solution = _current_level.get("solution", {})
	var winning_object := ""
	var winning_target := ""
	if typeof(solution) == TYPE_DICTIONARY:
		winning_object = str(solution.get("object_id", ""))
		winning_target = str(solution.get("drop_target_id", ""))

	if _selected_drag_id == winning_object and drop_target_id == winning_target:
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Wrong thing, wrong place. Somehow both.")


func _handle_text_submit() -> void:
	_tap_count += 1

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


func _handle_text_submitted(_submitted_text: String) -> void:
	_handle_text_submit()


func _handle_pattern_cell(cell_id: String) -> void:
	_tap_count += 1
	_selected_pattern_cell = cell_id
	_feedback_label.text = "Selected %s. Submit it if your pattern organs agree." % cell_id


func _handle_pattern_submit() -> void:
	_tap_count += 1

	var solution := _solution()
	if _selected_pattern_cell == str(solution.get("cell_id", "")):
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Pattern detected: you being incorrect.")


func _handle_memory_flash(show_sequence: bool) -> void:
	_tap_count += 1

	var rules := _rules()
	var sequence = rules.get("flash_items", [])
	if show_sequence and typeof(sequence) == TYPE_ARRAY:
		_feedback_label.text = "Flash: %s" % "  ".join(_string_array(sequence))
	else:
		_feedback_label.text = "Hidden. Choose the sequence before your brain files bankruptcy."


func _handle_memory_choice(item_id: String) -> void:
	_tap_count += 1
	_memory_input.append(item_id)
	_feedback_label.text = "Input: %s" % "  ".join(_memory_input)


func _handle_memory_clear() -> void:
	_tap_count += 1
	_memory_input = []
	_feedback_label.text = "Cleared. That was probably wise."


func _handle_memory_submit() -> void:
	_tap_count += 1

	var solution := _solution()
	var sequence = solution.get("sequence", [])
	if typeof(sequence) == TYPE_ARRAY and _memory_input == _string_array(sequence):
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "Memory failed. The pixels had one job and so did you.")


func _handle_physics_draw(draw_id: String) -> void:
	_tap_count += 1
	_physics_choice = draw_id
	_feedback_label.text = "Drew %s. Release the ball and let fake gravity judge you." % draw_id


func _handle_physics_release() -> void:
	_tap_count += 1

	var solution := _solution()
	if _physics_choice == str(solution.get("draw_id", "")):
		_complete_current_level()
		return

	_feedback_label.text = _first_roast("failure", "The ball saw your line and requested a different universe.")


func _handle_roast_action() -> void:
	_roast_count += 1
	_feedback_label.text = _roast_line("delay", "Roast used. Your dignity is now a renewable resource.", _roast_count - 1)


func _complete_current_level() -> void:
	_last_best_attempt = _profile.record_completed_attempt(_current_level, _tap_count, _roast_count)
	_last_completed_attempt = _profile.last_completed_attempt
	_last_score_result = _profile.last_score_result
	_show_score_roastcard()


func _show_score_roastcard() -> void:
	var root := _make_screen(COLOR_INK)

	_add_label(root, "Score Roastcard", 38, COLOR_YELLOW)
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
	var roast_count := int(_last_completed_attempt.get("roast_count", _roast_count))
	var action_count := int(_last_completed_attempt.get("action_count", _tap_count))
	_add_label(card_box, "UQIQ %d" % score_after, 36, COLOR_YELLOW)
	_add_label(card_box, "Score Delta: %+d  (%d -> %d)" % [score_delta, score_before, score_after], 18, COLOR_MUTED)
	_add_label(card_box, "Actions: %d" % action_count, 18, COLOR_TEXT)
	_add_label(card_box, "Roasts used: %d" % roast_count, 18, COLOR_TEXT)
	if bool(_last_completed_attempt.get("durd_at_start", false)):
		_add_label(card_box, "DUR'D recovery: spent earlier, restored %d Dur Token." % int(_last_completed_attempt.get("dur_tokens_restored", 0)), 18, COLOR_YELLOW)
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


func _make_screen(background_color: Color) -> VBoxContainer:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var background := ColorRect.new()
	background.color = background_color
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_top = 22
	root.offset_right = -20
	root.offset_bottom = -22
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	return root


func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var label := _new_label(text, font_size, color)
	parent.add_child(label)
	return label


func _add_status(parent: Node, text: String, color: Color) -> Label:
	var label := _new_label(text, 16, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _new_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
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
	_add_label(stage_box, "Pick the object, then pick where to drop it.", 17, COLOR_INK)

	var objects = _rules().get("draggable_objects", [])
	if typeof(objects) == TYPE_ARRAY:
		for object in objects:
			if typeof(object) != TYPE_DICTIONARY:
				continue

			var object_button := _make_button("Move: %s" % str(object.get("label", "Object")), _target_color(object))
			object_button.pressed.connect(Callable(self, "_handle_drag_select").bind(str(object.get("id", ""))))
			stage_box.add_child(object_button)

	var targets = _rules().get("drop_targets", [])
	if typeof(targets) == TYPE_ARRAY:
		for target in targets:
			if typeof(target) != TYPE_DICTIONARY:
				continue

			var target_button := _make_button("Drop on: %s" % str(target.get("label", "Target")), COLOR_PANEL_ALT)
			target_button.pressed.connect(Callable(self, "_handle_drag_drop").bind(str(target.get("id", ""))))
			stage_box.add_child(target_button)

	_add_feedback(stage_box, "Move the wrong thing into the right place.")


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

	_add_feedback(stage_box, "No physics sandbox yet. This deterministic line check is the slice.")


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
		var result := _profile.last_dur_spend_result
		_level_list_notice = "DUR'D Level %02d. Dur %d/%d. Level %02d unlocked." % [
			int(result.get("level_number", 0)),
			int(result.get("tokens_after", 0)),
			LocalProfileScript.MAX_DUR_TOKENS,
			int(result.get("unlocked_level", 1)),
		]
	else:
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
