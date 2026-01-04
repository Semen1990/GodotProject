# res://scripts/game_characters/base_character_class.gd
class_name BaseGameCharacter
extends CharacterBody2D

# Сигналы
signal character_clicked(character)
signal health_changed(new_health)
signal mana_changed(new_mana)
signal died()

# Статы персонажа
var character_name: String = "BaseCharacter"
var max_health: int = 100
var current_health: int = 100
var max_mana: int = 100
var current_mana: int = 100
var armor: int = 0
var base_speed: int = 200
var current_speed: int = 200
var jump_force: int = 400

# Состояния персонажа
var is_dead: bool = false
var is_attacking: bool = false
var is_moving: bool = false
var was_on_floor: bool = true
var is_landing: bool = false
var landing_timer: float = 0.0
var landing_duration: float = 0.3

# Атака
var attack_combo: int = 0
var last_attack_time: float = 0.0
var attack_combo_timeout: float = 1.0

# Физика
var gravity: int = 1200
var floor_normal: Vector2 = Vector2.UP

# Добавьте остальные методы из base_game_character.gd сюда...
