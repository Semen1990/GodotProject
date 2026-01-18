# base_game_character.gd
extends CharacterBody2D

# ===========================================
# БАЗОВЫЙ КЛАСС ПЕРСОНАЖА (УЛУЧШЕННАЯ ВЕРСИЯ)
# ===========================================
# Этот класс содержит ВСЮ общую логику для всех персонажей.
# Дочерние классы (warrior, paladin, rogue, berserk) наследуют от него
# и только ПЕРЕОПРЕДЕЛЯЮТ специфичную логику.

# --- СИГНАЛЫ ---
# Используются для связи с UI и другими системами
signal health_changed(new_health: int)
signal mana_changed(new_mana: int)
signal armor_changed(new_armor: int)
signal died()
signal revived()

# --- БАЗОВЫЕ ХАРАКТЕРИСТИКИ ---
# Переопределяются в дочерних классах в _ready()
var character_name: String = "BaseCharacter"
var max_health: int = 100
var current_health: int = 100
var max_mana: int = 100
var current_mana: int = 100
var armor: int = 0
var base_speed: int = 200
var current_speed: int = 200

# --- СОСТОЯНИЯ ПЕРСОНАЖА ---
# Используются для контроля действий и анимаций
var is_dead: bool = false
var is_attacking: bool = false
var is_moving: bool = false
var is_blocking: bool = false
var is_sliding: bool = false
var is_casting: bool = false
var is_crouching: bool = false
var is_hurt: bool = false
var is_invincible: bool = false  # Неуязвимость после возрождения

# --- СИСТЕМА АТАКИ ---
var attack_combo: int = 0
var last_attack_time: float = 0.0
var attack_combo_timeout: float = 1.0

# --- ФИЗИКА ---
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var max_speed: float = 300.0
var acceleration: float = 1500.0
var friction: float = 1200.0
var jump_velocity: float = -400.0

# --- СИСТЕМА ДВОЙНОГО ПРЫЖКА ---
# Активируется артефактами (например, "Крылья Гермеса")
var enable_double_jump: bool = false
var has_double_jumped: bool = false
var can_double_jump: bool = false
var coyote_time: float = 0.1  # Время после падения с платформы, когда еще можно прыгнуть
var coyote_timer: float = 0.0

# --- РАЗМЕРЫ КОЛЛИЗИИ ДЛЯ ПРИСЕДАНИЯ ---
var standing_collision_height: float = 0.0
var crouching_collision_height: float = 0.0
var original_collision_position: Vector2 = Vector2.ZERO

# --- СТАТИСТИКА ---
var last_damage_source: String = "Неизвестно"

# --- ССЫЛКИ НА НОДЫ ---
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D
var player_controller: Node

# --- ВИЗУАЛ ---
var original_scale: Vector2 = Vector2.ONE

# --- МАППИНГ АЛЬТЕРНАТИВНЫХ НАЗВАНИЙ АНИМАЦИЙ ---
# Разные спрайтшиты могут иметь разные названия анимаций
const ANIMATION_NAME_MAPPING: Dictionary = {
	"hurt": ["hurt", "taking damage", "hit", "damage"],
	"shield_defence": ["shield_defence", "shield defence", "block", "defend"],
	"crouch": ["crouch", "duck", "crouching"],
	"sliding": ["sliding", "slide", "roll"],
	"spellcast": ["spellcast", "cast", "magic", "spell"]
}


func _ready():
	print("✅ ", character_name, " инициализирован")
	
	# --- Безопасное получение нодов ---
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	collision_shape = get_node_or_null("CollisionShape2D") 
	player_controller = get_node_or_null("PlayerController")
	
	# Сохраняем оригинальный масштаб спрайта
	if animated_sprite:
		original_scale = animated_sprite.scale
	
	# --- Настройка коллизии для приседания ---
	if collision_shape and collision_shape.shape:
		original_collision_position = collision_shape.position
		if collision_shape.shape is CapsuleShape2D:
			standing_collision_height = collision_shape.shape.height
			crouching_collision_height = standing_collision_height * 0.5
		elif collision_shape.shape is RectangleShape2D:
			standing_collision_height = collision_shape.shape.size.y
			crouching_collision_height = standing_collision_height * 0.5
	
	# --- Настройка контроллера ---
	if player_controller:
		player_controller.character = self
	else:
		print("⚠️ PlayerController не найден для: ", character_name)
	
	# --- Применение артефактов ---
	call_deferred("apply_artifacts")
	
	# --- Запуск анимации покоя ---
	if animated_sprite:
		play_animation("idle")


func apply_artifacts():
	"""Применяем все собранные артефакты к персонажу"""
	if Global:
		Global.apply_all_artifacts_to_player()
		
		# Проверяем наличие способности двойного прыжка
		if Global.has_ability("double_jump"):
			enable_double_jump = true
			print("🦘 Двойной прыжок доступен для ", character_name)
		else:
			enable_double_jump = false


func _physics_process(delta: float):
	if is_dead:
		return
	
	# --- Эффект неуязвимости (мигание) ---
	if is_invincible and animated_sprite:
		animated_sprite.modulate.a = 0.7 + sin(Time.get_ticks_msec() * 0.01) * 0.3
	
	# --- Гравитация и coyote time ---
	if not is_on_floor():
		velocity.y += gravity * delta
		if coyote_timer > 0:
			coyote_timer -= delta
	else:
		# Сброс двойного прыжка при касании земли
		has_double_jumped = false
		can_double_jump = false
		coyote_timer = coyote_time
	
	# --- Обработка движения и анимаций ---
	handle_movement(delta)
	handle_animations()
	fix_sprite_scale()
	
	move_and_slide()


func fix_sprite_scale():
	"""Фиксирует масштаб спрайта (предотвращает баги с flip_h)"""
	if animated_sprite:
		var current_sign = sign(animated_sprite.scale.x)
		if current_sign == 0:
			current_sign = 1
		animated_sprite.scale = Vector2(
			abs(original_scale.x) * current_sign,
			original_scale.y
		)


# ===========================================
# СИСТЕМА ДВИЖЕНИЯ
# ===========================================

func handle_movement(delta: float):
	# --- Получение ввода ---
	var direction = Input.get_axis("move_left", "move_right")
	var is_jumping = Input.is_action_just_pressed("jump")
	var is_crouch_pressed = Input.is_action_pressed("crouch")
	var is_special = Input.is_action_just_pressed("special_ability")
	
	# --- Блокировка движения во время специальных действий ---
	if is_attacking or is_casting or is_sliding:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		return
	
	# --- ПРИСЕДАНИЕ ---
	if is_crouch_pressed and is_on_floor() and not is_blocking:
		if not is_crouching:
			start_crouch()
	elif is_crouching:
		stop_crouch()
	
	# --- СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ (E) ---
	if is_special and not is_crouching:
		use_special_ability()
	
	# --- ДВИЖЕНИЕ ---
	if not is_blocking and not is_crouching:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
			# Поворот спрайта
			if animated_sprite:
				animated_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	elif is_crouching:
		# При приседании - замедление до остановки
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		# При блоке - быстрая остановка
		velocity.x = move_toward(velocity.x, 0, friction * delta * 2)
	
	# --- ПРЫЖКИ ---
	if is_jumping and not is_blocking and not is_crouching:
		if is_on_floor() or coyote_timer > 0:
			# Обычный прыжок
			velocity.y = jump_velocity
			can_double_jump = enable_double_jump
			has_double_jumped = false
			coyote_timer = 0
			print("🦘 ", character_name, " прыгает!")
		elif enable_double_jump and can_double_jump and not has_double_jumped:
			# Двойной прыжок (слабее обычного)
			velocity.y = jump_velocity * 0.8
			has_double_jumped = true
			can_double_jump = false
			print("🦘✨ ", character_name, " использует двойной прыжок!")
			_show_double_jump_effect()


# ===========================================
# ПРИСЕДАНИЕ
# ===========================================

func start_crouch():
	"""Начать приседание"""
	if not is_on_floor() or is_crouching:
		return
	
	is_crouching = true
	print("🦆 Приседание!")


func stop_crouch():
	"""Закончить приседание"""
	if not is_crouching:
		return
	
	is_crouching = false
	print("🦆 Встал!")
	
	# Восстанавливаем коллизию
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CapsuleShape2D:
			collision_shape.shape.height = standing_collision_height
			collision_shape.position.y = original_collision_position.y
		elif collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size.y = standing_collision_height
			collision_shape.position.y = original_collision_position.y


# ===========================================
# СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ
# ===========================================

func use_special_ability():
	"""
	Виртуальная функция - ОБЯЗАТЕЛЬНО переопределяется в дочерних классах!
	
	- Воин: block() - блок щитом
	- Паладин: heal() - исцеление
	- Разбойник: slide() - подкат
	- Берсерк: rage() - ярость (если реализовано)
	"""
	print("⚡ ", character_name, " использует способность (базовая - не переопределена)")


# ===========================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ===========================================

func _show_double_jump_effect():
	"""Визуальный эффект при двойном прыжке"""
	if not animated_sprite:
		return
	
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(1.5, 1.5, 2.0, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original_modulate, 0.3)


func _show_damage_effect():
	"""Красная вспышка при получении урона"""
	if not animated_sprite:
		return
	
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original_modulate, 0.2)


# ===========================================
# СИСТЕМА АНИМАЦИЙ (УЛУЧШЕННАЯ)
# ===========================================

func handle_animations():
	"""Управляет анимациями в зависимости от состояния"""
	if not animated_sprite:
		return
	
	# Приоритет анимаций (от высшего к низшему)
	
	# 1. Смерть
	if is_dead:
		play_animation("death")
		return
	
	# 2. Атака - не прерываем
	if is_attacking:
		return
	
	# 3. Получение урона
	if is_hurt:
		play_animation("hurt")
		return
	
	# 4. Блок
	if is_blocking:
		play_animation("shield_defence")
		return
	
	# 5. Приседание
	if is_crouching and is_on_floor():
		play_animation("crouch")
		return
	
	# 6. В воздухе
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("fall")
		return
	
	# 7. Движение / Покой
	if abs(velocity.x) > 10:
		play_animation("run")
	else:
		play_animation("idle")


func play_animation(anim_name: String):
	"""
	Проигрывает анимацию с поддержкой альтернативных названий.
	
	Например, если запрошена "hurt", но в спрайтшите есть только
	"taking damage", функция автоматически найдёт правильное название.
	"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var actual_anim_name = _find_animation_name(anim_name)
	
	if actual_anim_name != "" and animated_sprite.animation != actual_anim_name:
		animated_sprite.play(actual_anim_name)


func _find_animation_name(requested_name: String) -> String:
	"""
	Ищет анимацию по запрошенному имени или его альтернативам.
	Возвращает реальное имя анимации или пустую строку если не найдена.
	"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return ""
	
	var frames = animated_sprite.sprite_frames
	
	# 1. Проверяем точное совпадение
	if frames.has_animation(requested_name):
		return requested_name
	
	# 2. Проверяем альтернативные названия из маппинга
	if ANIMATION_NAME_MAPPING.has(requested_name):
		for alt_name in ANIMATION_NAME_MAPPING[requested_name]:
			if frames.has_animation(alt_name):
				return alt_name
	
	# 3. Проверяем обратный маппинг (если запросили альтернативное имя)
	for base_name in ANIMATION_NAME_MAPPING:
		if requested_name in ANIMATION_NAME_MAPPING[base_name]:
			if frames.has_animation(base_name):
				return base_name
			for alt_name in ANIMATION_NAME_MAPPING[base_name]:
				if frames.has_animation(alt_name):
					return alt_name
	
	# Анимация не найдена
	return ""


func get_available_animations() -> Array:
	"""Возвращает список доступных анимаций"""
	if animated_sprite and animated_sprite.sprite_frames:
		return animated_sprite.sprite_frames.get_animation_names()
	return []


# ===========================================
# БОЕВАЯ СИСТЕМА
# ===========================================

func attack():
	"""Базовая атака - может быть переопределена в дочерних классах"""
	if is_dead or is_attacking or is_blocking or is_casting or is_sliding or is_crouching:
		return
	
	is_attacking = true
	attack_combo += 1
	
	play_animation("attack")
	
	# Ждём завершения анимации
	if animated_sprite:
		await animated_sprite.animation_finished
	
	is_attacking = false
	handle_animations()


func take_damage(amount: int, damage_type: String = "physical", source: String = "Неизвестно"):
	"""
	Получение урона.
	
	Параметры:
		amount - количество урона
		damage_type - тип урона ("physical", "magical", "true")
		source - источник урона (для статистики)
	
	ВАЖНО: При переопределении в дочерних классах сохраняйте сигнатуру!
	"""
	if is_dead or is_invincible:
		return
	
	# Запоминаем источник урона
	last_damage_source = source
	
	# Расчёт урона с учётом брони
	var reduced_amount = max(1, amount - armor)
	current_health -= reduced_amount
	current_health = max(0, current_health)
	
	# Отправляем сигнал
	health_changed.emit(current_health)
	
	print("💥 ", character_name, " получает урон: ", reduced_amount, " (", damage_type, ") от: ", source)
	print("   HP: ", current_health, "/", max_health)
	
	# Обновляем статистику
	if Global and Global.has_method("add_damage_taken"):
		Global.add_damage_taken(reduced_amount)
	
	# Визуальный эффект
	_show_damage_effect()
	
	# Проверка смерти
	if current_health <= 0:
		die()


# ===========================================
# СИСТЕМА СМЕРТИ И ВОЗРОЖДЕНИЯ
# ===========================================

func die():
	"""Смерть персонажа"""
	if is_dead:
		return
	
	is_dead = true
	print("💀 ", character_name, " погиб от: ", last_damage_source)
	
	# Останавливаем движение
	velocity = Vector2.ZERO
	
	# Отключаем коллизии
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Отправляем сигнал
	died.emit()
	
	# Обновляем статистику
	if Global and Global.has_method("set_death_reason"):
		Global.set_death_reason(last_damage_source)
	
	# Проигрываем анимацию смерти
	play_animation("death")
	
	# Ждём завершения анимации
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	
	# Скрываем игрока
	visible = false
	
	# Отключаем коллизию
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Показываем меню смерти
	_show_death_menu()


func _show_death_menu():
	"""Показывает меню смерти"""
	print("📜 Показываем меню смерти...")
	
	# Получаем статистику
	var stats = {}
	if Global and Global.has_method("get_run_statistics"):
		stats = Global.get_run_statistics()
	
	# Проверяем артефакт возрождения
	var revival_artifact = ""
	if Global and Global.has_method("get_revival_artifact"):
		revival_artifact = Global.get_revival_artifact()
	
	# Ищем или создаём меню смерти
	var death_menu = get_tree().get_first_node_in_group("death_menu")
	
	if not death_menu:
		var death_menu_scene = load("res://scenes/ui/death_menu.tscn")
		if death_menu_scene:
			death_menu = death_menu_scene.instantiate()
			death_menu.add_to_group("death_menu")
			get_tree().current_scene.add_child(death_menu)
	
	if death_menu:
		# Подключаем сигнал возрождения
		if death_menu.has_signal("revive_requested"):
			if not death_menu.revive_requested.is_connected(_on_revive_requested):
				death_menu.revive_requested.connect(_on_revive_requested)
		
		# Показываем меню
		if death_menu.has_method("show_death_menu"):
			death_menu.show_death_menu(stats, revival_artifact)


func _on_revive_requested(_data: Dictionary):
	"""Обработка возрождения из меню смерти"""
	print("🔮 Возрождение игрока!")
	
	if Global and Global.has_method("use_revival_artifact"):
		Global.use_revival_artifact()
	
	revive()


func revive():
	"""Возрождает персонажа"""
	print("✨ Возрождение ", character_name, "...")
	
	is_dead = false
	visible = true
	
	# Восстанавливаем здоровье (50%)
	current_health = max_health / 2
	health_changed.emit(current_health)
	
	# Включаем коллизию
	if collision_shape:
		collision_shape.disabled = false
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	# Перемещаем на точку спавна
	var player_spawn = get_tree().current_scene.get_node_or_null("PlayerSpawn")
	if player_spawn:
		global_position = player_spawn.global_position
	
	# Восстанавливаем визуал
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
		play_animation("idle")
	
	# Временная неуязвимость
	give_temporary_invincibility(3.0)
	
	revived.emit()
	print("✅ ", character_name, " возрождён с ", current_health, " HP")


func give_temporary_invincibility(duration: float):
	"""Даёт временную неуязвимость"""
	is_invincible = true
	print("🛡️ Неуязвимость на ", duration, " секунд")
	
	await get_tree().create_timer(duration).timeout
	
	is_invincible = false
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	print("🛡️ Неуязвимость закончилась")


# ===========================================
# БАЗОВЫЕ СПОСОБНОСТИ (переопределяются в дочерних классах)
# ===========================================

func heal():
	"""Базовое лечение - переопределяется в paladin_player.gd"""
	print("❤️ ", character_name, " базовое лечение (не реализовано)")


func slide():
	"""Базовый подкат - переопределяется в rogue_player.gd"""
	print("🔽 ", character_name, " базовый подкат (не реализован)")


func block():
	"""Базовый блок - переопределяется в warrior_player.gd"""
	pass


func stop_blocking():
	"""Прекращение блока - переопределяется в warrior_player.gd"""
	pass
