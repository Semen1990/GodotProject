extends "res://scripts/game_characters/base_game_character.gd"

var heal_cooldown: float = 0.0

func _ready():
	character_name = "Паладин"
	max_health = 130
	current_health = 130
	max_mana = 50
	current_mana = 50
	armor = 6
	jump_velocity = -380
	base_speed = 200
	current_speed = 200
	max_speed = 200.0
	
	print("✨ Паладин освещает путь!")
	super()

func _physics_process(delta):
	if heal_cooldown > 0:
		heal_cooldown -= delta
	
	super(delta)

func heal():
	if current_mana >= 10 and heal_cooldown <= 0 and not is_attacking and not is_blocking and not is_sliding:
		is_casting = true
		current_mana -= 10
		mana_changed.emit(current_mana)
		
		play_animation("spellcast")
		print("✨ Паладин лечится!")
		
		if animated_sprite:
			await animated_sprite.animation_finished
		
		current_health = min(current_health + 25, max_health)
		heal_cooldown = 5.0
		health_changed.emit(current_health)
		is_casting = false
		
		print("❤️ Здоровье: ", current_health, "/", max_health)
		handle_animations()
