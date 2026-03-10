extends "res://scripts/base_character.gd"

const FolderAnimationLoader = preload("res://scripts/utils/folder_animation_loader.gd")

const KNIGHT_ANIMATION_SOURCES := {
	"idle": "res://assets/characters/knight/Idle",
	"demonstration": "res://assets/characters/knight/attack",
}

const KNIGHT_ANIMATION_CONFIG := {
	"idle": {"loop": true, "speed": 10.0},
	"demonstration": {"loop": true, "speed": 12.0},
}


func _ready() -> void:
	_configure_sprite_frames()
	_load_knight_data()
	super()


func _configure_sprite_frames() -> void:
	if animated_sprite == null:
		return

	animated_sprite.sprite_frames = FolderAnimationLoader.build_sprite_frames(
		KNIGHT_ANIMATION_SOURCES,
		KNIGHT_ANIMATION_CONFIG
	)


func _load_knight_data() -> void:
	if Global and Global.character_data:
		var data = Global.character_data.get("knight")
		if data is Dictionary:
			setup_character(data)
			return

	setup_fallback_data()


func setup_fallback_data() -> void:
	character_name = "Рыцарь"
	max_health = 12
	current_health = 12
	max_mana = 0
	current_mana = 0
	armor = 2
	abilities = ["Тестовая привязка оружия", "Атака мечом"]
	selection_animation = "demonstration"
