extends Control

const LevelLoaderScript := preload("res://scripts/level_loader.gd")

const COLOR_INK := Color(0.06, 0.07, 0.09)
const COLOR_PAPER := Color(0.97, 0.95, 0.86)
const COLOR_PANEL := Color(0.12, 0.13, 0.16)
const COLOR_PANEL_ALT := Color(0.18, 0.20, 0.24)
const COLOR_YELLOW := Color(1.00, 0.78, 0.15)
const COLOR_GREEN := Color(0.30, 0.82, 0.50)
const COLOR_RED := Color(0.95, 0.22, 0.24)
const COLOR_BLUE := Color(0.12, 0.58, 0.92)
const COLOR_TEXT := Color(0.98, 0.98, 0.96)
const COLOR_MUTED := Color(0.73, 0.75, 0.76)

var _loader := LevelLoaderScript.new()
var _pack := {}
var _current_level := {}
var _tap_count := 0
var _feedback_label: Label


func _ready() -> void:
	_pack = _loader.load_pack()
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
		var is_playable := level_number == 1
		var button_text := "%02d  %s" % [level_number, title]
		if not is_playable:
			button_text += "  - later"

		var button := _make_button(button_text, COLOR_PANEL_ALT)
		button.disabled = not is_playable
		button.pressed.connect(Callable(self, "_show_play_screen").bind(level))
		list.add_child(button)


func _show_play_screen(level: Dictionary) -> void:
	_current_level = level
	_tap_count = 0

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
	score_label.text = "UQIQ 100"
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.add_theme_color_override("font_color", COLOR_YELLOW)
	top_bar.add_child(score_label)

	_add_label(root, str(level.get("title", "Untitled")), 30, COLOR_TEXT)
	_add_label(root, str(level.get("prompt", "")), 19, COLOR_MUTED)

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

	_add_label(stage_box, "Tap Logic", 24, COLOR_INK)

	var rules = level.get("rules", {})
	var targets = []
	if typeof(rules) == TYPE_DICTIONARY:
		targets = rules.get("tap_targets", [])

	if typeof(targets) == TYPE_ARRAY:
		for target in targets:
			if typeof(target) != TYPE_DICTIONARY:
				continue

			var target_button := _make_button(str(target.get("label", "Tap")), _target_color(target))
			target_button.pressed.connect(Callable(self, "_handle_tap_target").bind(str(target.get("id", ""))))
			stage_box.add_child(target_button)

	_feedback_label = _new_label("Choose carefully.", 18, COLOR_INK)
	stage_box.add_child(_feedback_label)


func _handle_tap_target(target_id: String) -> void:
	_tap_count += 1

	var solution = _current_level.get("solution", {})
	var winning_target := ""
	if typeof(solution) == TYPE_DICTIONARY:
		winning_target = str(solution.get("target_id", ""))

	if target_id == winning_target:
		_show_score_roastcard()
		return

	_feedback_label.text = _first_roast("failure", "Nope. Your finger has executive dysfunction.")


func _show_score_roastcard() -> void:
	var root := _make_screen(COLOR_INK)

	_add_label(root, "Score Roastcard", 38, COLOR_YELLOW)
	_add_label(root, str(_current_level.get("title", "Level complete")), 24, COLOR_TEXT)
	_add_status(root, "Completed in %d tap(s)" % _tap_count, COLOR_GREEN)

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

	_add_label(card_box, "UQIQ 100", 36, COLOR_YELLOW)
	_add_label(card_box, "Stub score only. Real scoring starts after issue #1.", 18, COLOR_MUTED)
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


func _first_roast(kind: String, fallback: String) -> String:
	var roasts = _current_level.get("roasts", {})
	if typeof(roasts) != TYPE_DICTIONARY:
		return fallback

	var lines = roasts.get(kind, [])
	if typeof(lines) == TYPE_ARRAY and not lines.is_empty():
		return str(lines[0])

	return fallback
