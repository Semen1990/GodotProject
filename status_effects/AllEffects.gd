# ===========================================
# STATUS EFFECTS - ВСЕ ЭФФЕКТЫ
# ===========================================
# Путь: res://scripts/status_effects/AllEffects.gd
#
# Содержит все статус-эффекты игры


# ===========================================
# BURN EFFECT - ГОРЕНИЕ
# ===========================================

class BurnEffect extends BaseStatusEffect:
	func _init():
		effect_name = "Горение"
		effect_type = EffectType.BURN
		duration = 5.0
		tick_interval = 1.0
		value = 3.0  # Урон за тик
		is_stackable = true
		max_stacks = 3
	
	func _on_apply():
		print("🔥 %s горит!" % target.name)
	
	func _on_tick():
		if target and target.get_parent():
			var status = target.get_node_or_null("StatusEffects")
			if status:
				status.deal_effect_damage(get_total_value(), "Горение")
	
	func _on_remove():
		print("🔥 Горение закончилось")


# ===========================================
# POISON EFFECT - ЯД
# ===========================================

class PoisonEffect extends BaseStatusEffect:
	func _init():
		effect_name = "Отравление"
		effect_type = EffectType.POISON
		duration = 8.0
		tick_interval = 2.0
		value = 5.0  # Урон за тик
		is_stackable = true
		max_stacks = 5
	
	func _on_apply():
		print("☠️ %s отравлен!" % target.name)
	
	func _on_tick():
		if target and target.get_parent():
			var status = target.get_node_or_null("StatusEffects")
			if status:
				status.deal_effect_damage(get_total_value(), "Яд")
	
	func _on_remove():
		print("☠️ Отравление прошло")


# ===========================================
# BLEED EFFECT - КРОВОТЕЧЕНИЕ
# ===========================================

class BleedEffect extends BaseStatusEffect:
	var last_position: Vector2 = Vector2.ZERO
	
	func _init():
		effect_name = "Кровотечение"
		effect_type = EffectType.BLEED
		duration = 6.0
		tick_interval = 0.5
		value = 2.0  # Урон за тик при движении
		is_stackable = true
		max_stacks = 3
	
	func _on_apply():
		print("🩸 %s истекает кровью!" % target.name)
		if target:
			last_position = target.global_position
	
	func _on_tick():
		if not target:
			return
		
		# Урон только при движении
		var moved = target.global_position.distance_to(last_position) > 5.0
		last_position = target.global_position
		
		if moved:
			var status = target.get_node_or_null("StatusEffects")
			if status:
				status.deal_effect_damage(get_total_value(), "Кровотечение")
	
	func _on_remove():
		print("🩸 Кровотечение остановлено")


# ===========================================
# FROST EFFECT - ХОЛОД (ЗАМЕДЛЕНИЕ)
# ===========================================

class FrostEffect extends BaseStatusEffect:
	func _init():
		effect_name = "Обморожение"
		effect_type = EffectType.FROST
		duration = 4.0
		tick_interval = 0.0  # Нет тиков
		value = 30.0  # % замедления
		is_stackable = true
		max_stacks = 3
	
	func _on_apply():
		print("❄️ %s замедлен!" % target.name)
		_apply_slow()
	
	func _on_stack():
		_apply_slow()
	
	func _apply_slow():
		if not target:
			return
		# Замедление применяется через StatusEffects.speed_modifier
	
	func _on_remove():
		print("❄️ Замедление прошло")
		if target and "current_speed" in target and "base_speed" in target:
			target.current_speed = target.base_speed


# ===========================================
# STUN EFFECT - ОГЛУШЕНИЕ
# ===========================================

class StunEffect extends BaseStatusEffect:
	func _init():
		effect_name = "Оглушение"
		effect_type = EffectType.STUN
		duration = 2.0
		tick_interval = 0.0
		value = 0.0
		is_stackable = false
	
	func _on_apply():
		print("💫 %s оглушён!" % target.name)
		if target and "can_move" in target:
			target.can_move = false
		if target and "can_attack" in target:
			target.can_attack = false
	
	func _on_remove():
		print("💫 Оглушение прошло")
		if target and "can_move" in target:
			target.can_move = true
		if target and "can_attack" in target:
			target.can_attack = true


# ===========================================
# MADNESS EFFECT - БЕЗУМИЕ
# ===========================================

class MadnessEffect extends BaseStatusEffect:
	func _init():
		effect_name = "Безумие"
		effect_type = EffectType.MADNESS
		duration = 10.0
		tick_interval = 3.0
		value = 0.1  # 10% шанс ударить себя
		is_stackable = false
	
	func _on_apply():
		print("🌀 %s обезумел!" % target.name)
	
	func _on_tick():
		if not target:
			return
		
		# Шанс ударить себя
		if randf() < value:
			var status = target.get_node_or_null("StatusEffects")
			if status:
				var self_damage = 5
				if "current_damage" in target:
					self_damage = target.current_damage
				status.deal_effect_damage(self_damage, "Безумие")
				print("🌀 %s ударил себя!" % target.name)
	
	func _on_remove():
		print("🌀 Безумие прошло")


# ===========================================
# BUFF ARMOR - БАФФ БРОНИ
# ===========================================

class ArmorBuffEffect extends BaseStatusEffect:
	func _init():
		effect_name = "Каменная кожа"
		effect_type = EffectType.BUFF_ARMOR
		duration = 30.0
		tick_interval = 0.0
		value = 5.0  # +5 брони
		is_stackable = false
	
	func _on_apply():
		print("🛡️ +%.0f брони" % value)
		if target and "armor" in target:
			target.armor += int(value)
	
	func _on_remove():
		print("🛡️ Бафф брони закончился")
		if target and "armor" in target:
			target.armor -= int(value)


# ===========================================
# BUFF DAMAGE - БАФФ УРОНА
# ===========================================

class DamageBuffEffect extends BaseStatusEffect:
	func _init():
		effect_name = "Ярость"
		effect_type = EffectType.BUFF_DAMAGE
		duration = 20.0
		tick_interval = 0.0
		value = 25.0  # +25% урона
		is_stackable = false
	
	func _on_apply():
		print("⚔️ +%.0f%% урона" % value)
	
	func _on_remove():
		print("⚔️ Бафф урона закончился")
