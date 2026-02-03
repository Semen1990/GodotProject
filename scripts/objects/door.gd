extends Area2D
class_name Door

# ===========================================
# DOOR v4.0 - ПЕРЕХОД МЕЖДУ УРОВНЯМИ
# ===========================================
# Использует Global для ключей и сохранения HP
# Вызывает level.save_before_transition() перед переходом

signal door_opened
signal door_used

enum KeyColor { 
	GOLD = 0,
	SILVER = 1,
	RED = 2,
	BLUE = 3,
	GREEN = 4,
	PURPLE = 5,
	NONE = -1
}

const COLOR_NAMES = {
	KeyColor.GOLD: "золотой",
	KeyColor.SILVER: "серебряный",
	KeyColor.RED: "красный",
	KeyColor.BLUE: "синий",
	KeyColor.GREEN: "зелёный",
	KeyColor.PURPLE: "фиолетовый",
	KeyColor.NONE: "нет",
}

@export var target_scene: String = ""
@export var spawn_point_id: String = "SpawnPoint"
@export var required_key: KeyColor = KeyColor.GOLD
@export var requires_key: bool = true
@export var consumes_key: bool = true
@export var is_initially_open: bool = false

var animated_sprite: AnimatedSprite2D = null
var color_indicator = null  # Может быть ColorRect, Sprite2D или Node2D
var hint_label: Label = null

var is_open: bool = false
var player_in_range: bool = false


func _ready():
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	color_indicator = get_node_or_null("ColorIndicator")
	hint_label = get_node_or_null("HintLabel")
	
	is_open = is_initially_open
	
	# Проверяем была ли дверь открыта
	if Global and Global.is_door_opened(name):
		is_open = true
	
	if not requires_key:
		is_open = true
	
	# Подключаем сигналы
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	_update_visual()
	_setup_hint()
	
	var key_name = COLOR_NAMES.get(required_key, "нет") if requires_key else "не требуется"
	print("🚪 Дверь '%s': %s, target=%s, spawn=%s" % [name, key_name, target_scene, spawn_point_id])


func _setup_hint():
	if hint_label:
		hint_label.visible = false
		_update_hint_text()


func _update_hint_text():
	if not hint_label:
		return
	
	if is_open:
		hint_label.text = "[F] Войти"
	elif requires_key:
		var key_name = COLOR_NAMES.get(required_key, "ключ")
		hint_label.text = "[F] Открыть (%s ключ)" % key_name
	else:
		hint_label.text = "[F] Открыть"


func _update_visual():
	if animated_sprite:
		if is_open:
			if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("open"):
				animated_sprite.play("open")
			elif animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("opened"):
				animated_sprite.play("opened")
		else:
			if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("closed"):
				animated_sprite.play("closed")
			elif animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
	
	# Цвет индикатора
	if color_indicator:
		var colors = {
			KeyColor.GOLD: Color(1.0, 0.85, 0.0),
			KeyColor.SILVER: Color(0.75, 0.75, 0.85),
			KeyColor.RED: Color(1.0, 0.25, 0.25),
			KeyColor.BLUE: Color(0.3, 0.5, 1.0),
			KeyColor.GREEN: Color(0.3, 0.85, 0.3),
			KeyColor.PURPLE: Color(0.75, 0.3, 0.9),
		}
		var target_color = colors.get(required_key, Color.WHITE)
		
		if color_indicator is ColorRect:
			color_indicator.color = target_color
		elif color_indicator is Sprite2D:
			color_indicator.modulate = target_color
		else:
			color_indicator.modulate = target_color


func _process(_delta):
	if player_in_range:
		if Input.is_action_just_pressed("interact"):
			_try_use_door()


func _on_body_entered(body: Node2D):
	if _is_player(body):
		player_in_range = true
		if hint_label:
			hint_label.visible = true
			_update_hint_text()


func _on_body_exited(body: Node2D):
	if _is_player(body):
		player_in_range = false
		if hint_label:
			hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _try_use_door():
	if is_open:
		_use_door()
		return
	
	# Нужен ключ
	if requires_key:
		var key_color = int(required_key)
		
		if Global.has_key(key_color):
			# Есть ключ - открываем
			if consumes_key:
				Global.remove_key(key_color)
				print("🔑 Использован: %s" % COLOR_NAMES[required_key])
			
			_open_door()
		else:
			# Нет ключа
			print("🚪 Нужен %s ключ!" % COLOR_NAMES[required_key])
			_show_locked_feedback()
	else:
		_open_door()


func _open_door():
	is_open = true
	
	if Global:
		Global.mark_door_opened(name)
	
	_update_visual()
	_update_hint_text()
	
	door_opened.emit()
	print("🚪 ✅ '%s' открыта" % name)
	
	# НЕ переходим автоматически!
	# Игрок должен нажать F ещё раз чтобы войти


func _use_door():
	if target_scene.is_empty():
		print("⚠️ target_scene не указан!")
		return
	
	print("🚪 ═══════════════════════════════")
	print("🚪 ПЕРЕХОД: %s" % target_scene)
	print("🚪 SPAWN: '%s'" % spawn_point_id)
	print("🚪 ═══════════════════════════════")
	
	# Сохраняем HP перед переходом
	var level = get_parent()
	if level and level.has_method("save_before_transition"):
		level.save_before_transition()
	else:
		# Fallback: сохраняем напрямую
		_save_player_stats_direct()
	
	# Устанавливаем spawn point
	Global.spawn_point = spawn_point_id
	print("🚪 Global.spawn_point = '%s'" % spawn_point_id)
	
	door_used.emit()
	
	# Переход
	get_tree().change_scene_to_file(target_scene)


func _save_player_stats_direct():
	"""Fallback сохранение если level не имеет метода"""
	if not Global.current_player:
		return
	
	var player = Global.current_player
	Global.saved_player_health = player.current_health
	
	if "current_mana" in player:
		Global.saved_player_mana = player.current_mana
	
	print("💾 Сохранено: HP=%d, Mana=%d" % [Global.saved_player_health, Global.saved_player_mana])


func _show_locked_feedback():
	"""Визуальная обратная связь что дверь закрыта"""
	if animated_sprite:
		var original = animated_sprite.modulate
		animated_sprite.modulate = Color(1.5, 0.5, 0.5)
		
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", original, 0.3)
	
	if hint_label:
		var key_name = COLOR_NAMES.get(required_key, "ключ")
		hint_label.text = "🔒 Нужен %s ключ!" % key_name
		hint_label.add_theme_color_override("font_color", Color.RED)
		
		await get_tree().create_timer(1.5).timeout
		
		if hint_label:
			hint_label.remove_theme_color_override("font_color")
			_update_hint_text()
