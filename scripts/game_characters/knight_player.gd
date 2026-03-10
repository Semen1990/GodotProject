extends "res://scripts/game_characters/base_game_character.gd"

const FolderAnimationLoader = preload("res://scripts/utils/folder_animation_loader.gd")
const DEFAULT_SWORD_TEXTURE = preload("res://assets/items/An ordinary steel sword-nobg.png")
const ICE_SWORD_TEXTURE = preload("res://assets/items/The ice sword-nobg.png")

const TEST_STEEL_SWORD_ID := 900001
const TEST_ICE_SWORD_ID := 900002
const TEST_STEEL_SWORD_INTERNAL_NAME := "test_knight_steel_sword"
const TEST_ICE_SWORD_INTERNAL_NAME := "test_knight_ice_sword"
const TEST_STEEL_SWORD_TEXTURE_PATH := "res://assets/items/An ordinary steel sword-nobg.png"
const TEST_ICE_SWORD_TEXTURE_PATH := "res://assets/items/The ice sword-nobg.png"

const KNIGHT_ANIMATION_SOURCES := {
	"idle": "res://assets/characters/knight/Idle",
	"run": "res://assets/characters/knight/Run",
	"attack": "res://assets/characters/knight/attack",
	"jump": "res://assets/characters/knight/Jump",
	"fall": "res://assets/characters/knight/Fall",
	"death": "res://assets/characters/knight/dead",
	"shield_defence": "res://assets/characters/knight/block with a shield",
	"kick": "res://assets/characters/knight/Kick",
	"potion": "res://assets/characters/knight/potion",
}

const KNIGHT_ANIMATION_CONFIG := {
	"idle": {"loop": true, "speed": 10.0},
	"run": {"loop": true, "speed": 12.0},
	"attack": {"loop": false, "speed": 13.0},
	"jump": {"loop": false, "speed": 12.0},
	"fall": {"loop": true, "speed": 10.0},
	"death": {"loop": false, "speed": 10.0},
	"shield_defence": {"loop": false, "speed": 10.0},
	"kick": {"loop": false, "speed": 12.0},
	"potion": {"loop": false, "speed": 10.0},
}

@export_group("Combat")
@export var attack_damage_frame: int = 12
@export var attack_hitbox_radius: float = 60.0
@export var attack_hitbox_forward_offset: float = 78.0

@export_group("Weapon Visual")
@export var weapon_texture_data_key: String = "character_texture_path"
@export var weapon_texture_scale_data_key: String = "character_texture_scale"
@export var weapon_texture_offset_data_key: String = "character_texture_offset"
@export var weapon_scale: Vector2 = Vector2(0.055, 0.055)
@export var weapon_texture_offset: Vector2 = Vector2(0, 225)
@export var weapon_idle_offset: Vector2 = Vector2(14, -4)
@export var weapon_run_offset: Vector2 = Vector2(12, -2)
@export var weapon_jump_offset: Vector2 = Vector2(10, -8)
@export var weapon_fall_offset: Vector2 = Vector2(10, -2)
@export var weapon_attack_windup_offset: Vector2 = Vector2(8, -10)
@export var weapon_attack_swing_offset: Vector2 = Vector2(18, 6)
@export var weapon_attack_recovery_offset: Vector2 = Vector2(12, -2)
@export var weapon_idle_rotation_deg: float = 14.0
@export var weapon_run_rotation_deg: float = 26.0
@export var weapon_jump_rotation_deg: float = -8.0
@export var weapon_fall_rotation_deg: float = 22.0
@export var weapon_attack_windup_rotation_deg: float = -34.0
@export var weapon_attack_swing_rotation_deg: float = 58.0
@export var weapon_attack_recovery_rotation_deg: float = 20.0

@onready var weapon_pivot: Node2D = get_node_or_null("WeaponPivot") as Node2D
@onready var weapon_sprite: Sprite2D = get_node_or_null("WeaponPivot/WeaponSprite") as Sprite2D

var _attack_damage_dealt: bool = false
var _current_weapon_scale: Vector2 = Vector2.ZERO
var _current_weapon_texture_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_configure_sprite_frames()
	_apply_knight_data()
	super()
	_configure_weapon_sprite()
	_connect_inventory_signals()
	_ensure_test_weapons()
	_refresh_weapon_from_inventory()


func _exit_tree() -> void:
	_disconnect_inventory_signals()


func _physics_process(delta: float) -> void:
	super(delta)
	_update_weapon_visual()


func _configure_sprite_frames() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	sprite.sprite_frames = FolderAnimationLoader.build_sprite_frames(
		KNIGHT_ANIMATION_SOURCES,
		KNIGHT_ANIMATION_CONFIG
	)


func _apply_knight_data() -> void:
	var data: Dictionary = {}
	if Global and Global.character_data:
		var candidate = Global.character_data.get("knight", {})
		if candidate is Dictionary:
			data = candidate

	character_name = String(data.get("name", "Рыцарь"))
	max_health = int(data.get("max_health", 12))
	current_health = int(data.get("current_health", max_health))
	max_mana = int(data.get("max_mana", 0))
	current_mana = int(data.get("current_mana", max_mana))
	armor = int(data.get("armor", 2))
	current_damage = int(data.get("damage", 2))
	base_speed = 185
	current_speed = base_speed
	max_speed = float(base_speed)
	jump_velocity = -365.0


func attack() -> void:
	if is_dead or is_attacking or is_blocking or is_casting or is_sliding or is_crouching or is_inventory_open:
		return

	is_attacking = true
	_attack_damage_dealt = false
	play_animation("attack")

	if animated_sprite and not animated_sprite.frame_changed.is_connected(_on_attack_frame_changed):
		animated_sprite.frame_changed.connect(_on_attack_frame_changed)

	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.65).timeout

	if animated_sprite and animated_sprite.frame_changed.is_connected(_on_attack_frame_changed):
		animated_sprite.frame_changed.disconnect(_on_attack_frame_changed)

	is_attacking = false
	handle_animations()


func _on_attack_frame_changed() -> void:
	if not is_attacking or _attack_damage_dealt or animated_sprite == null:
		return

	if animated_sprite.frame >= attack_damage_frame:
		_deal_damage_to_enemies()
		_attack_damage_dealt = true


func _deal_damage_to_enemies() -> void:
	if animated_sprite == null:
		return

	var facing_sign := -1.0 if animated_sprite.flip_h else 1.0
	var attack_center := global_position + Vector2(attack_hitbox_forward_offset * facing_sign, -10)

	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = attack_hitbox_radius
	query.shape = shape
	query.transform = Transform2D(0.0, attack_center)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var space_state := get_world_2d().direct_space_state
	for result in space_state.intersect_shape(query):
		var collider = result.get("collider")
		if collider == null or collider == self:
			continue
		if collider.has_method("take_damage"):
			collider.take_damage(current_damage, "physical")
			if Global and Global.has_method("add_damage_dealt"):
				Global.add_damage_dealt(current_damage)


func _configure_weapon_sprite() -> void:
	if weapon_sprite == null:
		return

	weapon_sprite.centered = true
	weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_current_weapon_scale = weapon_scale
	_current_weapon_texture_offset = weapon_texture_offset
	weapon_sprite.scale = _current_weapon_scale
	weapon_sprite.position = _current_weapon_texture_offset
	weapon_sprite.z_index = 12
	weapon_sprite.visible = false


func _connect_inventory_signals() -> void:
	if Inventory == null:
		return

	if not Inventory.equipment_changed.is_connected(_on_equipment_changed_for_weapon):
		Inventory.equipment_changed.connect(_on_equipment_changed_for_weapon)
	if not Inventory.item_equipped.is_connected(_on_item_equipped_for_weapon):
		Inventory.item_equipped.connect(_on_item_equipped_for_weapon)
	if not Inventory.item_unequipped.is_connected(_on_item_unequipped_for_weapon):
		Inventory.item_unequipped.connect(_on_item_unequipped_for_weapon)


func _disconnect_inventory_signals() -> void:
	if Inventory == null:
		return

	if Inventory.equipment_changed.is_connected(_on_equipment_changed_for_weapon):
		Inventory.equipment_changed.disconnect(_on_equipment_changed_for_weapon)
	if Inventory.item_equipped.is_connected(_on_item_equipped_for_weapon):
		Inventory.item_equipped.disconnect(_on_item_equipped_for_weapon)
	if Inventory.item_unequipped.is_connected(_on_item_unequipped_for_weapon):
		Inventory.item_unequipped.disconnect(_on_item_unequipped_for_weapon)


func _on_equipment_changed_for_weapon() -> void:
	_refresh_weapon_from_inventory()


func _on_item_equipped_for_weapon(_item: InventoryItem, _slot: InventoryEnums.EquipSlot) -> void:
	_refresh_weapon_from_inventory()


func _on_item_unequipped_for_weapon(_item: InventoryItem, _slot: InventoryEnums.EquipSlot) -> void:
	_refresh_weapon_from_inventory()


func _refresh_weapon_from_inventory() -> void:
	if weapon_sprite == null:
		return

	if Inventory == null:
		weapon_sprite.texture = null
		weapon_sprite.visible = false
		return

	var equipped_item: InventoryItem = Inventory.get_equipped_item(InventoryEnums.EquipSlot.MAIN_HAND)
	var weapon_texture := _resolve_weapon_texture(equipped_item)
	_current_weapon_scale = _resolve_weapon_scale(equipped_item)
	_current_weapon_texture_offset = _resolve_weapon_texture_offset(equipped_item)
	weapon_sprite.texture = weapon_texture
	weapon_sprite.scale = _current_weapon_scale
	weapon_sprite.position = _current_weapon_texture_offset
	weapon_sprite.visible = weapon_texture != null and not is_dead


func _resolve_weapon_texture(item: InventoryItem) -> Texture2D:
	if item == null or item.data == null:
		return null

	var custom_path := String(item.data.custom_data.get(weapon_texture_data_key, ""))
	if not custom_path.is_empty() and ResourceLoader.exists(custom_path):
		var custom_texture := load(custom_path) as Texture2D
		if custom_texture != null:
			return custom_texture

	if item.data.equipment_type == InventoryEnums.EquipmentType.SWORD:
		return DEFAULT_SWORD_TEXTURE

	return null


func _resolve_weapon_scale(item: InventoryItem) -> Vector2:
	if item != null and item.data != null and item.data.custom_data.has(weapon_texture_scale_data_key):
		var raw_scale = item.data.custom_data.get(weapon_texture_scale_data_key)
		if raw_scale is Vector2:
			return raw_scale
		if raw_scale is Array and raw_scale.size() >= 2:
			return Vector2(float(raw_scale[0]), float(raw_scale[1]))
	return weapon_scale


func _resolve_weapon_texture_offset(item: InventoryItem) -> Vector2:
	if item != null and item.data != null and item.data.custom_data.has(weapon_texture_offset_data_key):
		var raw_offset = item.data.custom_data.get(weapon_texture_offset_data_key)
		if raw_offset is Vector2:
			return raw_offset
		if raw_offset is Array and raw_offset.size() >= 2:
			return Vector2(float(raw_offset[0]), float(raw_offset[1]))
	return weapon_texture_offset


func _ensure_test_weapons() -> void:
	if Inventory == null or Inventory.current_slot_count <= 0:
		return

	_ensure_test_weapon(
		TEST_STEEL_SWORD_ID,
		TEST_STEEL_SWORD_INTERNAL_NAME,
		"Тестовый стальной меч",
		"Тестовое оружие рыцаря для проверки привязки спрайта.",
		TEST_STEEL_SWORD_TEXTURE_PATH,
		DEFAULT_SWORD_TEXTURE,
		2,
		InventoryEnums.ItemRarity.COMMON
	)
	_ensure_test_weapon(
		TEST_ICE_SWORD_ID,
		TEST_ICE_SWORD_INTERNAL_NAME,
		"Тестовый ледяной меч",
		"Тестовое оружие рыцаря для проверки смены спрайта при экипировке.",
		TEST_ICE_SWORD_TEXTURE_PATH,
		ICE_SWORD_TEXTURE,
		3,
		InventoryEnums.ItemRarity.RARE
	)

	if Inventory.get_equipped_item(InventoryEnums.EquipSlot.MAIN_HAND) != null:
		return

	var default_slot := _find_item_slot_by_internal_name(TEST_STEEL_SWORD_INTERNAL_NAME)
	if default_slot >= 0:
		Inventory.equip_item(default_slot, InventoryEnums.EquipSlot.MAIN_HAND)


func _ensure_test_weapon(
	item_id: int,
	internal_name: String,
	display_name: String,
	description: String,
	texture_path: String,
	icon_texture: Texture2D,
	damage_bonus: int,
	rarity: InventoryEnums.ItemRarity
) -> void:
	if _has_item_with_internal_name(internal_name):
		return

	var item_data := GameItemData.new()
	item_data.id = item_id
	item_data.internal_name = internal_name
	item_data.display_name = display_name
	item_data.description = description
	item_data.icon = icon_texture
	item_data.category = InventoryEnums.ItemCategory.EQUIPMENT
	item_data.equipment_type = InventoryEnums.EquipmentType.SWORD
	item_data.equip_slot = InventoryEnums.EquipSlot.MAIN_HAND
	item_data.required_class = InventoryEnums.CharacterClass.WARRIOR
	item_data.rarity = rarity
	item_data.stat_damage = damage_bonus
	item_data.stackable = false
	item_data.max_stack = 1
	item_data.custom_data = {
		weapon_texture_data_key: texture_path,
		weapon_texture_scale_data_key: _get_test_weapon_scale(texture_path),
		weapon_texture_offset_data_key: _get_test_weapon_texture_offset(texture_path),
	}

	var item := InventoryItem.new(item_data, 1)
	Inventory.add_item(item)


func _has_item_with_internal_name(internal_name: String) -> bool:
	if Inventory == null:
		return false

	for item in Inventory.inventory_slots:
		if _item_matches_internal_name(item, internal_name):
			return true

	for slot in Inventory.equipment_slots:
		if _item_matches_internal_name(Inventory.equipment_slots.get(slot), internal_name):
			return true

	return false


func _find_item_slot_by_internal_name(internal_name: String) -> int:
	if Inventory == null:
		return -1

	for index in range(Inventory.current_slot_count):
		if _item_matches_internal_name(Inventory.inventory_slots[index], internal_name):
			return index

	return -1


func _item_matches_internal_name(item: InventoryItem, internal_name: String) -> bool:
	return item != null and item.data != null and item.data.internal_name == internal_name


func _get_test_weapon_scale(texture_path: String) -> Vector2:
	if texture_path == TEST_ICE_SWORD_TEXTURE_PATH:
		return Vector2(0.05, 0.05)
	return Vector2(0.055, 0.055)


func _get_test_weapon_texture_offset(texture_path: String) -> Vector2:
	if texture_path == TEST_ICE_SWORD_TEXTURE_PATH:
		return Vector2(0, 245)
	return Vector2(0, 225)


func _update_weapon_visual() -> void:
	if weapon_sprite == null or weapon_pivot == null or animated_sprite == null:
		return

	if weapon_sprite.texture == null or is_dead:
		weapon_sprite.visible = false
		return

	weapon_sprite.visible = true
	weapon_sprite.scale = _current_weapon_scale
	weapon_sprite.position = _current_weapon_texture_offset

	var pose := _get_weapon_pose(String(animated_sprite.animation), animated_sprite.frame)
	var offset: Vector2 = pose.get("offset", weapon_idle_offset)
	var rotation_deg: float = float(pose.get("rotation", weapon_idle_rotation_deg))

	if animated_sprite.flip_h:
		offset.x = -offset.x
		rotation_deg = -rotation_deg
		weapon_sprite.flip_h = true
	else:
		weapon_sprite.flip_h = false

	weapon_pivot.position = offset
	weapon_sprite.rotation_degrees = rotation_deg


func _get_weapon_pose(animation_name: String, frame: int) -> Dictionary:
	match animation_name:
		"run":
			return {"offset": weapon_run_offset, "rotation": weapon_run_rotation_deg}
		"jump":
			return {"offset": weapon_jump_offset, "rotation": weapon_jump_rotation_deg}
		"fall":
			return {"offset": weapon_fall_offset, "rotation": weapon_fall_rotation_deg}
		"attack":
			if frame < maxi(1, attack_damage_frame / 2):
				return {"offset": weapon_attack_windup_offset, "rotation": weapon_attack_windup_rotation_deg}
			if frame <= attack_damage_frame + 2:
				return {"offset": weapon_attack_swing_offset, "rotation": weapon_attack_swing_rotation_deg}
			return {"offset": weapon_attack_recovery_offset, "rotation": weapon_attack_recovery_rotation_deg}
		_:
			return {"offset": weapon_idle_offset, "rotation": weapon_idle_rotation_deg}





