class_name FolderAnimationLoader
extends RefCounted


static func build_sprite_frames(animation_sources: Dictionary, animation_config: Dictionary = {}) -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()

	for animation_name_variant in animation_sources.keys():
		var animation_name := String(animation_name_variant)
		var folder_path := String(animation_sources[animation_name_variant])
		var textures := load_textures_from_folder(folder_path)

		if textures.is_empty():
			push_warning("FolderAnimationLoader: no PNG frames found in '%s'" % folder_path)
			continue

		sprite_frames.add_animation(animation_name)
		for texture in textures:
			sprite_frames.add_frame(animation_name, texture)

		var config: Dictionary = animation_config.get(animation_name, {})
		sprite_frames.set_animation_speed(animation_name, float(config.get("speed", 10.0)))
		sprite_frames.set_animation_loop(animation_name, bool(config.get("loop", false)))

	return sprite_frames


static func load_textures_from_folder(folder_path: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	if not DirAccess.dir_exists_absolute(folder_path):
		push_warning("FolderAnimationLoader: folder does not exist '%s'" % folder_path)
		return textures

	var files := DirAccess.get_files_at(folder_path)
	files.sort()

	for file_name in files:
		var file_name_string := String(file_name)
		if file_name_string.get_extension().to_lower() != "png":
			continue
		if not _is_frame_file_name(file_name_string):
			continue

		var texture_path := folder_path.path_join(file_name_string)
		var texture := load(texture_path) as Texture2D
		if texture != null:
			textures.append(texture)

	return textures

static func _is_frame_file_name(file_name: String) -> bool:
	var base_name := file_name.get_basename().to_lower()
	if base_name.is_valid_int():
		return true
	return base_name.begins_with("frame_")
