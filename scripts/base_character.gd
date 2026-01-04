extends CharacterBody2D

signal character_clicked(character)

# Данные персонажа
var character_name: String = ""
var max_health: int = 0
var current_health: int = 0
var max_mana: int = 0
var current_mana: int = 0
var armor: int = 0
var abilities: Array = []
var selection_animation: String = ""

# Используем AnimatedSprite2D для анимаций
@onready var animated_sprite = $AnimatedSprite2D
@onready var area_2d = $Area2D  # ДОБАВЛЕНО - прямая ссылка на Area2D

func _ready():
	print("🔄 Character _ready: ", name)
	# Ждем немного перед запуском анимации, чтобы все узлы были готовы
	call_deferred("initialize_character")

func initialize_character():
	print("🎯 Initializing character: ", name)
	
	# Проверяем и настраиваем Area2D
	if area_2d:
		print("✅ Area2D found for: ", character_name)
		# Убеждаемся, что Area2D может получать события
		area_2d.input_pickable = true
		area_2d.monitoring = true
		
		# Проверяем CollisionShape2D
		var collision = area_2d.get_node_or_null("CollisionShape2D")
		if collision:
			print("✅ CollisionShape2D found for: ", character_name)
			collision.disabled = false
		else:
			print("❌ No CollisionShape2D found for: ", character_name)
	else:
		print("❌ ERROR: No Area2D found for: ", character_name)
	
	play_idle_animation()

func setup_character(data):
	if data == null:
		print("❌ ERROR: setup_character received null data")
		setup_fallback_data()
		return
	
	if not data is Dictionary:
		print("❌ ERROR: setup_character expected Dictionary, got: ", typeof(data))
		setup_fallback_data()
		return
	
	print("🔧 Setting up character with data: ", data)
	
	character_name = data.get("name", "Unknown")
	max_health = data.get("max_health", 100)
	current_health = data.get("current_health", max_health)
	max_mana = data.get("max_mana", 0)
	current_mana = data.get("current_mana", max_mana)
	armor = data.get("armor", 0)
	abilities = data.get("abilities", [])
	selection_animation = data.get("selection_animation", "idle")
	
	print("✅ Character setup complete: ", character_name)

func setup_fallback_data():
	character_name = "Unknown Character"
	max_health = 100
	current_health = 100
	max_mana = 0
	current_mana = 0
	armor = 0
	abilities = ["Basic abilities"]
	selection_animation = "demonstration"

func play_idle_animation():
	if animated_sprite and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
			print("🔄 Playing IDLE: ", character_name)
		else:
			print("❌ No idle animation found for: ", character_name)
			# Если нет idle, пробуем проиграть первую доступную анимацию
			var anim_names = animated_sprite.sprite_frames.get_animation_names()
			if anim_names.size() > 0:
				animated_sprite.play(anim_names[0])
				print("⚠️ Playing fallback animation: ", anim_names[0])
	else:
		print("❌ AnimatedSprite2D or SpriteFrames not configured for: ", character_name)

func play_demonstration_animation():
	if animated_sprite and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation(selection_animation):
			animated_sprite.play(selection_animation)
			print("🎭 Playing SELECTION: ", character_name, " - ", selection_animation)
		else:
			print("❌ No selection animation '", selection_animation, "' for: ", character_name)
			# Если нет demonstration, пробуем проиграть idle
			play_idle_animation()
	else:
		print("❌ AnimatedSprite2D or SpriteFrames not configured for: ", character_name)

func on_selected():
	print("⭐ Character selected: ", character_name)
	play_demonstration_animation()

func on_deselected():
	print("🔙 Character deselected: ", character_name)
	play_idle_animation()

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# Проверяем, что это нажатие левой кнопки мыши
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("🎯 LEFT CLICK on: ", character_name)
		emit_signal("character_clicked", self)
