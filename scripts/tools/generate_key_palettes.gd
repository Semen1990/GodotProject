@tool
extends EditorScript

const SOURCE_DIR := "res://assets/items/keys_game/gold"
const TARGET_DIRS := {
	"silver": "res://assets/items/keys_game/silver",
	"red": "res://assets/items/keys_game/red",
	"blue": "res://assets/items/keys_game/blue",
	"green": "res://assets/items/keys_game/green",
	"purple": "res://assets/items/keys_game/purple",
}

# Four-step metal ramps: shadow -> mid -> light -> highlight.
const TARGET_RAMPS := {
	"silver": [
		Color8(95, 102, 112),
		Color8(155, 166, 179),
		Color8(211, 218, 226),
		Color8(244, 247, 250),
	],
	"red": [
		Color8(109, 31, 36),
		Color8(181, 58, 68),
		Color8(229, 106, 114),
		Color8(255, 211, 216),
	],
	"blue": [
		Color8(32, 58, 115),
		Color8(62, 111, 192),
		Color8(115, 168, 240),
		Color8(214, 232, 255),
	],
	"green": [
		Color8(36, 92, 45),
		Color8(60, 154, 78),
		Color8(115, 214, 129),
		Color8(221, 248, 225),
	],
	"purple": [
		Color8(75, 42, 112),
		Color8(125, 73, 182),
		Color8(180, 136, 235),
		Color8(240, 223, 255),
	],
}


func _run() -> void:
	var source_files: Array[String] = _collect_png_files(SOURCE_DIR)
	if source_files.is_empty():
		push_error("Key palette generator: no PNG files found in %s" % SOURCE_DIR)
		return

	for color_name in TARGET_DIRS.keys():
		var target_dir: String = TARGET_DIRS[color_name]
		var ramp: Array[Color] = _get_ramp(color_name)
		if ramp.size() != 4:
			push_error("Key palette generator: invalid ramp for %s" % color_name)
			continue

		_ensure_directory(target_dir)
		_generate_color_set(source_files, target_dir, ramp)

	if get_editor_interface():
		get_editor_interface().get_resource_filesystem().scan()

	print("Key palette generator: done.")


func _get_ramp(color_name: String) -> Array[Color]:
	var ramp: Array[Color] = []
	var raw_ramp: Array = TARGET_RAMPS.get(color_name, [])
	for entry in raw_ramp:
		ramp.append(entry)
	return ramp


func _generate_color_set(source_files: Array[String], target_dir: String, ramp: Array[Color]) -> void:
	for source_path in source_files:
		var image: Image = Image.new()
		var load_error: Error = image.load(ProjectSettings.globalize_path(source_path))
		if load_error != OK:
			push_error("Key palette generator: failed to load %s" % source_path)
			continue

		var recolored: Image = _recolor_image(image, ramp)
		var file_name: String = source_path.get_file()
		var output_path: String = target_dir.path_join(file_name)
		var save_error: Error = recolored.save_png(ProjectSettings.globalize_path(output_path))
		if save_error != OK:
			push_error("Key palette generator: failed to save %s" % output_path)


func _recolor_image(image: Image, ramp: Array[Color]) -> Image:
	var result: Image = image.duplicate()
	result.convert(Image.FORMAT_RGBA8)

	for y in range(result.get_height()):
		for x in range(result.get_width()):
			var pixel: Color = result.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue

			var brightness: float = _compute_brightness(pixel)
			var target_color: Color = _sample_ramp(ramp, brightness)
			target_color.a = pixel.a
			result.set_pixel(x, y, target_color)

	return result


func _compute_brightness(pixel: Color) -> float:
	# Use luminance so the new color keeps the original shading depth.
	return clamp(pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114, 0.0, 1.0)


func _sample_ramp(ramp: Array[Color], t: float) -> Color:
	if t <= 0.33:
		return ramp[0].lerp(ramp[1], t / 0.33)
	if t <= 0.66:
		return ramp[1].lerp(ramp[2], (t - 0.33) / 0.33)
	return ramp[2].lerp(ramp[3], (t - 0.66) / 0.34)


func _collect_png_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return files

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension().to_lower() != "png":
			continue
		files.append(dir_path.path_join(file_name))
	dir.list_dir_end()

	files.sort()
	return files


func _ensure_directory(dir_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
