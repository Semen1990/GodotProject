extends Node

signal telemetry_updated(summary: Dictionary)
signal profile_changed(profile: Dictionary)

const InventoryEnums = preload("res://scripts/inventory/core/inventory_enums.gd")

const KNOWN_DAMAGE_TYPES: Array[String] = [
	"physical",
	"fire",
	"ice",
	"poison",
	"madness",
]

const TRACKED_EQUIP_SLOTS: Array[int] = [
	InventoryEnums.EquipSlot.MAIN_HAND,
	InventoryEnums.EquipSlot.OFF_HAND,
	InventoryEnums.EquipSlot.HEAD,
	InventoryEnums.EquipSlot.BODY,
	InventoryEnums.EquipSlot.LEGS,
	InventoryEnums.EquipSlot.FEET,
	InventoryEnums.EquipSlot.HANDS,
	InventoryEnums.EquipSlot.NECKLACE,
	InventoryEnums.EquipSlot.AMULET,
	InventoryEnums.EquipSlot.RING_1,
	InventoryEnums.EquipSlot.RING_2,
	InventoryEnums.EquipSlot.RING_3,
	InventoryEnums.EquipSlot.RING_4,
	InventoryEnums.EquipSlot.ARTIFACT_1,
	InventoryEnums.EquipSlot.ARTIFACT_2,
	InventoryEnums.EquipSlot.ARTIFACT_3,
	InventoryEnums.EquipSlot.ARTIFACT_4,
]

var room_history: Array[String] = []
var room_visit_counts: Dictionary = {}
var new_room_count: int = 0

var damage_dealt_by_type: Dictionary = {}
var damage_taken_by_type: Dictionary = {}
var damage_taken_by_reaction: Dictionary = {}
var action_counts: Dictionary = {}
var latest_build_snapshot: Dictionary = {}
var build_snapshots: Array[Dictionary] = []
var profile_snapshot: Dictionary = {}


func _ready() -> void:
	reset_run()


func reset_run() -> void:
	room_history.clear()
	room_visit_counts.clear()
	new_room_count = 0
	damage_dealt_by_type = _make_damage_type_dictionary()
	damage_taken_by_type = _make_damage_type_dictionary()
	damage_taken_by_reaction = {
		"light": 0,
		"hurt": 0,
		"heavy": 0,
	}
	action_counts = {
		"block_started": 0,
		"block_success": 0,
		"slide_started": 0,
		"backstabs": 0,
		"potions_hp": 0,
		"potions_mana": 0,
		"potions_buff": 0,
	}
	latest_build_snapshot.clear()
	build_snapshots.clear()
	_recompute_profile()


func record_room_visit(room_id: String, is_new_room: bool) -> void:
	if room_id.is_empty():
		return

	room_history.append(room_id)
	room_visit_counts[room_id] = int(room_visit_counts.get(room_id, 0)) + 1
	if is_new_room:
		new_room_count += 1

	_recompute_profile()


func record_damage_dealt(damage_type: String, amount: int, payload: Dictionary = {}) -> void:
	var normalized_type: String = _normalize_damage_type(damage_type)
	var safe_amount: int = maxi(0, amount)
	damage_dealt_by_type[normalized_type] = int(damage_dealt_by_type.get(normalized_type, 0)) + safe_amount

	if bool(payload.get("backstab", false)):
		action_counts["backstabs"] = int(action_counts.get("backstabs", 0)) + 1

	_recompute_profile()


func record_damage_taken(damage_type: String, amount: int, reaction_tag: String = "hurt", _payload: Dictionary = {}) -> void:
	var normalized_type: String = _normalize_damage_type(damage_type)
	var safe_amount: int = maxi(0, amount)
	damage_taken_by_type[normalized_type] = int(damage_taken_by_type.get(normalized_type, 0)) + safe_amount

	var normalized_reaction: String = reaction_tag if damage_taken_by_reaction.has(reaction_tag) else "hurt"
	damage_taken_by_reaction[normalized_reaction] = int(damage_taken_by_reaction.get(normalized_reaction, 0)) + 1

	_recompute_profile()


func record_combat_action(action_name: String, _payload: Dictionary = {}) -> void:
	match action_name:
		"block_started":
			action_counts["block_started"] = int(action_counts.get("block_started", 0)) + 1
		"block_success":
			action_counts["block_success"] = int(action_counts.get("block_success", 0)) + 1
		"slide_started":
			action_counts["slide_started"] = int(action_counts.get("slide_started", 0)) + 1
		"backstab":
			action_counts["backstabs"] = int(action_counts.get("backstabs", 0)) + 1
		_:
			return

	_recompute_profile()


func record_potion_use(kind: String, _room_id: String = "") -> void:
	match kind:
		"hp":
			action_counts["potions_hp"] = int(action_counts.get("potions_hp", 0)) + 1
		"mana":
			action_counts["potions_mana"] = int(action_counts.get("potions_mana", 0)) + 1
		"buff":
			action_counts["potions_buff"] = int(action_counts.get("potions_buff", 0)) + 1
		_:
			return

	_recompute_profile()


func capture_build_snapshot(room_id: String, player: Node, inventory: Node) -> Dictionary:
	if player == null or inventory == null:
		return latest_build_snapshot.duplicate(true)

	var equipment_stats: Dictionary = {}
	if inventory.has_method("get_equipment_stats"):
		equipment_stats = inventory.get_equipment_stats().duplicate(true)

	var elemental_hints: Dictionary = _collect_elemental_hints(inventory)
	var snapshot: Dictionary = {
		"room_id": room_id,
		"armor": int(player.armor if "armor" in player else 0),
		"max_health": int(player.max_health if "max_health" in player else 0),
		"max_mana": int(player.max_mana if "max_mana" in player else 0),
		"damage": int(player.current_damage if "current_damage" in player else 0),
		"speed": int(player.current_speed if "current_speed" in player else 0),
		"equipment_stats": equipment_stats,
		"elemental_hints": elemental_hints,
		"equipped_items": _build_equipped_item_snapshot(inventory),
	}

	latest_build_snapshot = snapshot
	build_snapshots.append(snapshot.duplicate(true))
	if build_snapshots.size() > 24:
		build_snapshots.pop_front()

	_recompute_profile()
	return latest_build_snapshot.duplicate(true)


func get_profile_snapshot() -> Dictionary:
	return profile_snapshot.duplicate(true)


func get_latest_build_snapshot() -> Dictionary:
	return latest_build_snapshot.duplicate(true)


func get_style_scores() -> Dictionary:
	return profile_snapshot.get("style_scores", {}).duplicate(true)


func get_style_score(style_name: String) -> float:
	return float(profile_snapshot.get("style_scores", {}).get(style_name, 0.0))


func get_dominant_style() -> String:
	return String(profile_snapshot.get("dominant_style", ""))


func get_dominant_score() -> float:
	return float(profile_snapshot.get("dominant_score", 0.0))


func get_new_room_count() -> int:
	return int(profile_snapshot.get("new_room_count", 0))


func get_action_counts() -> Dictionary:
	return action_counts.duplicate(true)


func _make_damage_type_dictionary() -> Dictionary:
	var result: Dictionary = {}
	for damage_type in KNOWN_DAMAGE_TYPES:
		result[damage_type] = 0
	return result


func _normalize_damage_type(damage_type: String) -> String:
	var normalized: String = damage_type.strip_edges().to_lower()
	if normalized.is_empty():
		return "physical"
	if normalized in KNOWN_DAMAGE_TYPES:
		return normalized
	return "physical"


func _build_equipped_item_snapshot(inventory: Node) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if not inventory.has_method("get_equipped_item"):
		return items

	for slot in TRACKED_EQUIP_SLOTS:
		var item = inventory.get_equipped_item(slot)
		if item == null or item.data == null:
			continue

		var snapshot: Dictionary = {
			"slot": slot,
			"item_id": int(item.get_item_id()),
			"name": _get_item_display_name(item.data),
			"custom_data": _safe_duplicate_dictionary(_get_object_property(item.data, "custom_data")),
		}
		items.append(snapshot)

	return items


func _collect_elemental_hints(inventory: Node) -> Dictionary:
	var weights: Dictionary = {
		"fire": 0.0,
		"ice": 0.0,
		"poison": 0.0,
		"madness": 0.0,
	}
	if not inventory.has_method("get_equipped_item"):
		return weights

	for slot in TRACKED_EQUIP_SLOTS:
		var item = inventory.get_equipped_item(slot)
		if item == null or item.data == null:
			continue

		_extract_elemental_hints_from_variant(_get_object_property(item.data, "custom_data"), weights)
		_extract_elemental_hints_from_variant(_get_object_property(item.data, "effects"), weights)
		_extract_elemental_hints_from_variant(_get_item_display_name(item.data), weights)
		_extract_elemental_hints_from_variant(_get_object_property(item.data, "description"), weights)

	return weights


func _get_item_display_name(item_data: Object) -> String:
	var display_name: String = String(_get_object_property(item_data, "display_name"))
	if not display_name.is_empty():
		return display_name

	var legacy_name: String = String(_get_object_property(item_data, "item_name"))
	if not legacy_name.is_empty():
		return legacy_name

	var internal_name: String = String(_get_object_property(item_data, "internal_name"))
	if not internal_name.is_empty():
		return internal_name

	return ""


func _get_object_property(target: Object, property_name: String) -> Variant:
	if target == null:
		return null
	return target.get(property_name)


func _safe_duplicate_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _extract_elemental_hints_from_variant(value: Variant, weights: Dictionary) -> void:
	match typeof(value):
		TYPE_ARRAY:
			for entry in value:
				_extract_elemental_hints_from_variant(entry, weights)
		TYPE_DICTIONARY:
			for key in value:
				_extract_elemental_hints_from_variant(key, weights)
				_extract_elemental_hints_from_variant(value[key], weights)
		TYPE_STRING:
			var text: String = String(value).to_lower()
			if text.contains("fire") or text.contains("огн"):
				weights["fire"] = float(weights.get("fire", 0.0)) + 1.0
			if text.contains("ice") or text.contains("cold") or text.contains("frost") or text.contains("лед"):
				weights["ice"] = float(weights.get("ice", 0.0)) + 1.0
			if text.contains("poison") or text.contains("toxin") or text.contains("яд"):
				weights["poison"] = float(weights.get("poison", 0.0)) + 1.0
			if text.contains("madness") or text.contains("безум"):
				weights["madness"] = float(weights.get("madness", 0.0)) + 1.0
		_:
			pass


func _recompute_profile() -> void:
	var room_factor: float = maxf(1.0, float(maxi(new_room_count, 1)))
	var total_damage_dealt: float = maxf(1.0, float(_sum_dictionary_values(damage_dealt_by_type)))

	var equipment_stats: Dictionary = latest_build_snapshot.get("equipment_stats", {})
	var elemental_hints: Dictionary = latest_build_snapshot.get("elemental_hints", {})

	var block_attempts: float = float(action_counts.get("block_started", 0))
	var block_successes: float = float(action_counts.get("block_success", 0))
	var block_success_rate: float = block_successes / maxf(1.0, block_attempts)
	var total_potions: float = float(action_counts.get("potions_hp", 0) + action_counts.get("potions_mana", 0) + action_counts.get("potions_buff", 0))

	var style_scores: Dictionary = {
		"armor_focus": clampf((float(equipment_stats.get("armor", 0)) / 10.0) + (block_success_rate * 0.25), 0.0, 1.0),
		"block_focus": clampf((block_attempts / (room_factor * 2.0)) + (block_success_rate * 0.35), 0.0, 1.0),
		"backstab_focus": clampf(float(action_counts.get("backstabs", 0)) / room_factor, 0.0, 1.0),
		"potion_reliance": clampf(total_potions / (room_factor * 2.0), 0.0, 1.0),
		"fire_focus": clampf((float(damage_dealt_by_type.get("fire", 0)) / total_damage_dealt) + (float(elemental_hints.get("fire", 0.0)) * 0.15), 0.0, 1.0),
		"ice_focus": clampf((float(damage_dealt_by_type.get("ice", 0)) / total_damage_dealt) + (float(elemental_hints.get("ice", 0.0)) * 0.15), 0.0, 1.0),
		"poison_focus": clampf((float(damage_dealt_by_type.get("poison", 0)) / total_damage_dealt) + (float(elemental_hints.get("poison", 0.0)) * 0.15), 0.0, 1.0),
		"madness_focus": clampf((float(damage_dealt_by_type.get("madness", 0)) / total_damage_dealt) + (float(elemental_hints.get("madness", 0.0)) * 0.15), 0.0, 1.0),
	}

	var dominant_style: String = ""
	var dominant_score: float = 0.0
	for style_name in style_scores.keys():
		var score: float = float(style_scores.get(style_name, 0.0))
		if score > dominant_score:
			dominant_style = style_name
			dominant_score = score

	profile_snapshot = {
		"new_room_count": new_room_count,
		"room_history": room_history.duplicate(),
		"damage_dealt_by_type": damage_dealt_by_type.duplicate(true),
		"damage_taken_by_type": damage_taken_by_type.duplicate(true),
		"damage_taken_by_reaction": damage_taken_by_reaction.duplicate(true),
		"action_counts": action_counts.duplicate(true),
		"latest_build_snapshot": latest_build_snapshot.duplicate(true),
		"style_scores": style_scores,
		"dominant_style": dominant_style,
		"dominant_score": dominant_score,
	}

	profile_changed.emit(get_profile_snapshot())
	telemetry_updated.emit(get_profile_snapshot())


func _sum_dictionary_values(values: Dictionary) -> int:
	var total: int = 0
	for value in values.values():
		total += int(value)
	return total
