extends "res://scripts/game_characters/base_game_character.gd"

var slide_cooldown: float = 0.0

func _ready():
	character_name = "Разбойник"
	max_health = 90
	current_health = 90
	max_mana = 30
	current_mana = 30
	armor = 2
	jump_velocity = -450
	base_speed = 280
	current_speed = 280
	max_speed = 280.0
	
	print("🗡️ Разбойник скрывается в тени!")
	super()

func _physics_process(delta):
	if slide_cooldown > 0:
		slide_cooldown -= delta
	
	super(delta)

func slide():
	if is_dead or is_attacking or is_blocking or is_sliding or slide_cooldown > 0:
		return
	
	is_sliding = true
	slide_cooldown = 2.0
	current_speed = base_speed * 1.5
	print("🔽 Разбойник: подкат!")
	
	play_animation("sliding")
	
	if animated_sprite:
		await animated_sprite.animation_finished
	
	current_speed = base_speed
	is_sliding = false
	handle_animations()
