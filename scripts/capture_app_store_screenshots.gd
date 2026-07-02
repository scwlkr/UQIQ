extends SceneTree

const LevelLoaderScript := preload("res://scripts/level_loader.gd")
const LocalProfileScript := preload("res://scripts/local_profile.gd")
const MainScene := preload("res://scenes/Main.tscn")

const OUTPUT_DIR := "res://docs/app-store/screenshots"
const TEST_SAVE_PATH := "user://app_store_screenshot_profile.json"
const WINDOW_SIZE := Vector2i(1320, 2868)
const DESIGN_SIZE := Vector2i(390, 844)
const SCREENSHOT_CAPTURE_ENV := "UQIQ_SCREENSHOT_CAPTURE"

var _loader := LevelLoaderScript.new()
var _pack_set := {}
var _main: Control
var _profile: RefCounted
var _failed := false


func _initialize() -> void:
	OS.set_environment(SCREENSHOT_CAPTURE_ENV, "1")
	_configure_window()
	_prepare_output_dir()
	_remove_test_save()
	_pack_set = _loader.load_default_packs()
	_require(not _pack_set.is_empty(), _loader.last_error)
	if _failed:
		return _finish()

	_boot_main_scene()
	if _failed:
		return _finish()

	await _capture_level_list()
	await _capture_play_screen("02_level_01_play.png", 1)
	await _capture_play_screen("03_pattern_grid.png", 31)
	await _capture_play_screen("04_memory_flash.png", 41)
	await _capture_play_screen("05_physics_draw.png", 51)
	await _capture_score_roastcard()
	await _capture_play_screen("07_drag_logic.png", 2)

	print("App Store screenshot capture passed: wrote 7 draft screenshots to %s." % ProjectSettings.globalize_path(OUTPUT_DIR))
	_finish()


func _configure_window() -> void:
	root.size = WINDOW_SIZE
	root.content_scale_size = DESIGN_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DisplayServer.window_set_size(WINDOW_SIZE)


func _prepare_output_dir() -> void:
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_DIR)
	var error := DirAccess.make_dir_recursive_absolute(absolute_path)
	_require(error == OK, "Could not create screenshot output directory: %s" % absolute_path)


func _boot_main_scene() -> void:
	_main = MainScene.instantiate() as Control
	_require(_main != null, "Main scene could not be instantiated.")
	_profile = LocalProfileScript.new(TEST_SAVE_PATH)
	_main.set("_profile", _profile)
	root.add_child(_main)
	_main.call("_setup_feedback")
	_require(_profile.last_error.is_empty(), _profile.last_error)


func _capture_level_list() -> void:
	_main.call("_show_level_list")
	await _save_screenshot("01_level_list.png")


func _capture_play_screen(filename: String, level_number: int) -> void:
	var level := _level_by_number(level_number)
	_main.call("_show_play_screen", level)
	if str(level.get("template", "")) == "Memory Flash":
		_main.call("_hide_direct_memory_flash", int(_main.get("_direct_memory_flash_generation")))
		await process_frame
	await _save_screenshot(filename)


func _capture_score_roastcard() -> void:
	var level := _level_by_number(1)
	_main.call("_show_play_screen", level)
	_main.call("_handle_tap_target", str(_solution(level).get("target_id", "")))
	await _save_screenshot("06_score_roastcard.png")


func _save_screenshot(filename: String) -> void:
	await process_frame
	await process_frame
	var texture := root.get_texture()
	_require(texture != null, "%s capture texture should not be null." % filename)
	if _failed:
		return
	var image := texture.get_image()
	_require(image != null, "%s capture image should not be null." % filename)
	if _failed:
		return
	var source_size := Vector2i(image.get_width(), image.get_height())
	if source_size != WINDOW_SIZE:
		image.resize(WINDOW_SIZE.x, WINDOW_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])
	var error := image.save_png(path)
	_require(error == OK, "Could not save screenshot: %s" % path)
	if not _failed:
		print("Saved %s (%dx%d from %dx%d)" % [path, image.get_width(), image.get_height(), source_size.x, source_size.y])


func _level_by_number(level_number: int) -> Dictionary:
	var level := _loader.find_level_by_number(_pack_set, level_number)
	_require(not level.is_empty(), "Level %d should exist in default packs." % level_number)
	return level


func _solution(level: Dictionary) -> Dictionary:
	var solution = level.get("solution", {})
	if typeof(solution) == TYPE_DICTIONARY:
		return solution
	return {}


func _remove_test_save() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	OS.set_environment(SCREENSHOT_CAPTURE_ENV, "")
	_cleanup()
	if _failed:
		quit(1)
		return
	quit(0)


func _cleanup() -> void:
	if _main != null and is_instance_valid(_main):
		if _main.get_parent() != null:
			_main.get_parent().remove_child(_main)
		_main.free()
		_main = null
