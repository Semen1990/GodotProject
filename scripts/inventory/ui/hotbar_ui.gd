extends CanvasLayer
class_name HotbarUI
## HUD Р В Р’В Р РЋРІР‚вЂќР В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’ВµР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ° Р В Р’В Р вЂ™Р’В±Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р Р‹Р В РЎвЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р Р‹Р В РІР‚С™Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р Р‹Р Р†Р вЂљР’В¦ Р В Р Р‹Р В РЎвЂњР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚СћР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В  (Р В Р’В Р РЋРІР‚СњР В Р’В Р вЂ™Р’В»Р В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В Р В Р’В Р РЋРІР‚ВР В Р Р‹Р Р†РІР‚С™Р’В¬Р В Р’В Р РЋРІР‚В 1-4)
## Р В Р’В Р вЂ™Р’В Р В Р’В Р вЂ™Р’В°Р В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚вЂќР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В¶Р В Р’В Р вЂ™Р’ВµР В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’В° Р В Р’В Р В РІР‚В  Р В Р’В Р Р†Р вЂљРЎвЂќР В Р’В Р Р†Р вЂљРЎС›Р В Р’В Р Р†Р вЂљРІвЂћСћР В Р’В Р РЋРІР‚С”Р В Р’В Р РЋРЎв„ў Р В Р’В Р РЋРЎС™Р В Р’В Р вЂ™Р’ВР В Р’В Р Р†Р вЂљРІР‚СљР В Р’В Р РЋРЎС™Р В Р’В Р Р†Р вЂљРЎС›Р В Р’В Р РЋРЎв„ў Р В Р Р‹Р РЋРІР‚СљР В Р’В Р РЋРІР‚вЂњР В Р’В Р вЂ™Р’В»Р В Р Р‹Р РЋРІР‚Сљ Р В Р Р‹Р В Р Р‰Р В Р’В Р РЋРІР‚СњР В Р Р‹Р В РІР‚С™Р В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’В°
##
## Р В Р’В Р РЋРЎСџР В Р Р‹Р РЋРІР‚СљР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р Р‹Р В Р вЂ°: res://scripts/inventory/ui/hotbar_ui.gd

# ===========================================
# Р В Р’В Р В Р вЂ№Р В Р’В Р вЂ™Р’ВР В Р’В Р Р†Р вЂљРЎС™Р В Р’В Р РЋРЎС™Р В Р’В Р РЋРІР‚в„ўР В Р’В Р Р†Р вЂљРЎвЂќР В Р’В Р вЂ™Р’В«
# ===========================================

signal hotbar_slot_used(index: int)

# ===========================================
# Р В Р’В Р РЋРІвЂћСћР В Р’В Р РЋРІР‚С”Р В Р’В Р РЋРЎС™Р В Р’В Р В Р вЂ№Р В Р’В Р РЋРЎвЂєР В Р’В Р РЋРІР‚в„ўР В Р’В Р РЋРЎС™Р В Р’В Р РЋРЎвЂєР В Р’В Р вЂ™Р’В«
# ===========================================

const SLOT_SIZE = Vector2(50, 50)
const SLOT_SPACING = 6
const NUM_SLOTS = 4
const MARGIN_LEFT = 15
const MARGIN_BOTTOM = 15

# ===========================================
# Р В Р’В Р РЋРЎСџР В Р’В Р Р†Р вЂљРЎС›Р В Р’В Р вЂ™Р’В Р В Р’В Р Р†Р вЂљРЎС›Р В Р’В Р РЋРЎв„ўР В Р’В Р Р†Р вЂљРЎС›Р В Р’В Р РЋРЎС™Р В Р’В Р РЋРЎС™Р В Р’В Р вЂ™Р’В«Р В Р’В Р Р†Р вЂљРЎС›
# ===========================================

var slots: Array[Panel] = []
var slot_icons: Array[TextureRect] = []
var slot_quantities: Array[Label] = []
var key_labels: Array[Label] = []
var used_overlays: Array[ColorRect] = []  # Р В Р’В Р РЋРІР‚С”Р В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р В РІР‚С™Р В Р’В Р вЂ™Р’В»Р В Р’В Р вЂ™Р’ВµР В Р’В Р Р†РІР‚С›РІР‚вЂњ Р В Р’В Р СћРІР‚ВР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р РЏ Р В Р’В Р РЋРІР‚ВР В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚вЂќР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ°Р В Р’В Р вЂ™Р’В·Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦Р В Р’В Р В РІР‚В¦Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р Р‹Р Р†Р вЂљР’В¦ Р В Р’В Р вЂ™Р’В·Р В Р’В Р вЂ™Р’ВµР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚ВР В Р’В Р Р†РІР‚С›РІР‚вЂњ

# ===========================================
# Р В Р’В Р вЂ™Р’ВР В Р’В Р РЋРЎС™Р В Р’В Р вЂ™Р’ВР В Р’В Р вЂ™Р’В¦Р В Р’В Р вЂ™Р’ВР В Р’В Р РЋРІР‚в„ўР В Р’В Р Р†Р вЂљРЎвЂќР В Р’В Р вЂ™Р’ВР В Р’В Р Р†Р вЂљРІР‚СњР В Р’В Р РЋРІР‚в„ўР В Р’В Р вЂ™Р’В¦Р В Р’В Р вЂ™Р’ВР В Р’В Р В РІР‚РЋ
# ===========================================

func _ready():
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_ui()
	_connect_signals()

	call_deferred("_refresh_hotbar")

	print("Р РЋР вЂљР РЋРЎСџР вЂ™Р’В§Р В РІР‚С› HotbarUI Р В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В·Р В Р’В Р СћРІР‚ВР В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦ (Р В Р’В Р вЂ™Р’В»Р В Р’В Р вЂ™Р’ВµР В Р’В Р В РІР‚В Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р’В Р Р†РІР‚С›РІР‚вЂњ Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚ВР В Р’В Р вЂ™Р’В¶Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚ВР В Р’В Р Р†РІР‚С›РІР‚вЂњ Р В Р Р‹Р РЋРІР‚СљР В Р’В Р РЋРІР‚вЂњР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»)")


func _create_ui():
	"""Р В Р’В Р В Р вЂ№Р В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В·Р В Р’В Р СћРІР‚ВР В Р’В Р вЂ™Р’В°Р В Р Р‹Р Р†Р вЂљР’ВР В Р Р‹Р Р†Р вЂљРЎв„ў UI Р В Р’В Р вЂ™Р’В±Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р Р‹Р В РЎвЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р Р‹Р В РІР‚С™Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р Р‹Р Р†Р вЂљР’В¦ Р В Р Р‹Р В РЎвЂњР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚СћР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В  Р В Р’В Р В РІР‚В  Р В Р’В Р Р†Р вЂљРЎвЂќР В Р’В Р Р†Р вЂљРЎС›Р В Р’В Р Р†Р вЂљРІвЂћСћР В Р’В Р РЋРІР‚С”Р В Р’В Р РЋРЎв„ў Р В Р’В Р РЋРЎС™Р В Р’В Р вЂ™Р’ВР В Р’В Р Р†Р вЂљРІР‚СљР В Р’В Р РЋРЎС™Р В Р’В Р Р†Р вЂљРЎС›Р В Р’В Р РЋРЎв„ў Р В Р Р‹Р РЋРІР‚СљР В Р’В Р РЋРІР‚вЂњР В Р’В Р вЂ™Р’В»Р В Р Р‹Р РЋРІР‚Сљ"""

	var container = Control.new()
	container.name = "HotbarContainer"

	var total_width = (SLOT_SIZE.x + SLOT_SPACING) * NUM_SLOTS + 10
	var total_height = SLOT_SIZE.y + 25

	container.anchor_left = 0
	container.anchor_top = 1
	container.anchor_right = 0
	container.anchor_bottom = 1
	container.offset_left = MARGIN_LEFT
	container.offset_top = -MARGIN_BOTTOM - total_height
	container.offset_right = MARGIN_LEFT + total_width
	container.offset_bottom = -MARGIN_BOTTOM

	add_child(container)

	# Р В Р’В Р вЂ™Р’В¤Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В¦ Р В Р’В Р РЋРІР‚вЂќР В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’ВµР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚В
	var background = Panel.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = -8
	background.offset_right = 8
	background.offset_top = -5
	background.offset_bottom = 5
	_style_panel(background)
	container.add_child(background)

	# Р В Р’В Р РЋРІвЂћСћР В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В¦Р В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р вЂ™Р’ВµР В Р’В Р Р†РІР‚С›РІР‚вЂњР В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р В РІР‚С™ Р В Р’В Р СћРІР‚ВР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р РЏ Р В Р Р‹Р В РЎвЂњР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚СћР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В
	var hbox = HBoxContainer.new()
	hbox.name = "SlotsHBox"
	hbox.position = Vector2(0, 0)
	hbox.add_theme_constant_override("separation", SLOT_SPACING)
	container.add_child(hbox)

	for i in range(NUM_SLOTS):
		var slot_container = _create_slot(i)
		hbox.add_child(slot_container)


func _create_slot(index: int) -> Control:
	"""Р В Р’В Р В Р вЂ№Р В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В·Р В Р’В Р СћРІР‚ВР В Р’В Р вЂ™Р’В°Р В Р Р‹Р Р†Р вЂљР’ВР В Р Р‹Р Р†Р вЂљРЎв„ў Р В Р’В Р РЋРІР‚СћР В Р’В Р СћРІР‚ВР В Р’В Р РЋРІР‚ВР В Р’В Р В РІР‚В¦ Р В Р Р‹Р В РЎвЂњР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚СћР В Р Р‹Р Р†Р вЂљРЎв„ў Р В Р’В Р вЂ™Р’В±Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р Р‹Р В РЎвЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р Р‹Р В РІР‚С™Р В Р’В Р РЋРІР‚СћР В Р’В Р РЋРІР‚вЂњР В Р’В Р РЋРІР‚Сћ Р В Р’В Р СћРІР‚ВР В Р’В Р РЋРІР‚СћР В Р Р‹Р В РЎвЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р Р‹Р РЋРІР‚СљР В Р’В Р РЋРІР‚вЂќР В Р’В Р вЂ™Р’В°"""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	# Р В Р’В Р вЂ™Р’В¤Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В¦ Р В Р Р‹Р В РЎвЂњР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚СћР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р вЂ™Р’В°
	var slot_bg = Panel.new()
	slot_bg.name = "Slot%d" % index
	slot_bg.custom_minimum_size = SLOT_SIZE
	_style_slot(slot_bg)
	vbox.add_child(slot_bg)
	slots.append(slot_bg)

	# Р В Р’В Р вЂ™Р’ВР В Р’В Р РЋРІР‚СњР В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚СњР В Р’В Р вЂ™Р’В° Р В Р’В Р РЋРІР‚вЂќР В Р Р‹Р В РІР‚С™Р В Р’В Р вЂ™Р’ВµР В Р’В Р СћРІР‚ВР В Р’В Р РЋР’ВР В Р’В Р вЂ™Р’ВµР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р вЂ™Р’В°
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_bg.add_child(icon)
	slot_icons.append(icon)

	# Р В Р’В Р РЋРІвЂћСћР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚ВР В Р Р‹Р Р†Р вЂљР Р‹Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р В РЎвЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р В РІР‚В Р В Р’В Р РЋРІР‚Сћ
	var qty_label = Label.new()
	qty_label.name = "Quantity"
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	qty_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	qty_label.offset_right = -3
	qty_label.offset_bottom = -1
	qty_label.add_theme_font_size_override("font_size", 12)
	qty_label.add_theme_color_override("font_color", Color.WHITE)
	qty_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	qty_label.add_theme_constant_override("shadow_offset_x", 1)
	qty_label.add_theme_constant_override("shadow_offset_y", 1)
	qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qty_label.visible = false
	slot_bg.add_child(qty_label)
	slot_quantities.append(qty_label)

	# Р В Р’В Р РЋРІР‚С”Р В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р В РІР‚С™Р В Р’В Р вЂ™Р’В»Р В Р’В Р вЂ™Р’ВµР В Р’В Р Р†РІР‚С›РІР‚вЂњ "Р В Р’В Р вЂ™Р’ВР В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚вЂќР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ°Р В Р’В Р вЂ™Р’В·Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚Сћ"
	var used_overlay = ColorRect.new()
	used_overlay.name = "UsedOverlay"
	used_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	used_overlay.color = Color(0.3, 0.3, 0.3, 0.7)  # Р В Р’В Р В Р вЂ№Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р В РІР‚С™Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р’В Р Р†РІР‚С›РІР‚вЂњ Р В Р’В Р РЋРІР‚вЂќР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р Р‹Р РЋРІР‚СљР В Р’В Р РЋРІР‚вЂќР В Р Р‹Р В РІР‚С™Р В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В·Р В Р Р‹Р В РІР‚С™Р В Р’В Р вЂ™Р’В°Р В Р Р‹Р Р†Р вЂљР Р‹Р В Р’В Р В РІР‚В¦Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р’В Р Р†РІР‚С›РІР‚вЂњ
	used_overlay.visible = false
	used_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_bg.add_child(used_overlay)
	used_overlays.append(used_overlay)

	# Р В Р’В Р РЋРЎС™Р В Р’В Р РЋРІР‚СћР В Р’В Р РЋР’ВР В Р’В Р вЂ™Р’ВµР В Р Р‹Р В РІР‚С™ Р В Р’В Р РЋРІР‚СњР В Р’В Р вЂ™Р’В»Р В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В Р В Р’В Р РЋРІР‚ВР В Р Р‹Р Р†РІР‚С™Р’В¬Р В Р’В Р РЋРІР‚В
	var key_label = Label.new()
	key_label.text = str(index + 1)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	key_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	key_label.add_theme_constant_override("shadow_offset_x", 1)
	key_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(key_label)
	key_labels.append(key_label)

	return vbox


func _style_panel(panel: Panel):
	"""Р В Р’В Р В Р вЂ№Р В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚ВР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ° Р В Р Р‹Р Р†Р вЂљРЎвЂєР В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’В° Р В Р’В Р РЋРІР‚вЂќР В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’ВµР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚В"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.4, 0.2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)


func _style_slot(panel: Panel):
	"""Р В Р’В Р В Р вЂ№Р В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚ВР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ° Р В Р Р‹Р В РЎвЂњР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚СћР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р вЂ™Р’В°"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.45)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)


func _connect_signals():
	"""Р В Р’В Р РЋРЎСџР В Р’В Р РЋРІР‚СћР В Р’В Р СћРІР‚ВР В Р’В Р РЋРІР‚СњР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В РІР‚в„–Р В Р Р‹Р Р†Р вЂљР Р‹Р В Р’В Р вЂ™Р’В°Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р Р†Р вЂљРЎв„ў Р В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚ВР В Р’В Р РЋРІР‚вЂњР В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’В°Р В Р’В Р вЂ™Р’В»Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“"""
	if Inventory:
		if Inventory.has_signal("hotbar_changed"):
			Inventory.hotbar_changed.connect(_on_hotbar_changed)
		if Inventory.has_signal("inventory_changed"):
			Inventory.inventory_changed.connect(_refresh_hotbar)


# ===========================================
# Р В Р’В Р РЋРІР‚С”Р В Р’В Р Р†Р вЂљР’ВР В Р’В Р РЋРЎС™Р В Р’В Р РЋРІР‚С”Р В Р’В Р Р†Р вЂљРІвЂћСћР В Р’В Р Р†Р вЂљРЎвЂќР В Р’В Р Р†Р вЂљРЎС›Р В Р’В Р РЋРЎС™Р В Р’В Р вЂ™Р’ВР В Р’В Р Р†Р вЂљРЎС›
# ===========================================

func _refresh_hotbar():
	"""РћР±РЅРѕРІР»СЏРµС‚ РѕС‚РѕР±СЂР°Р¶РµРЅРёРµ Р±С‹СЃС‚СЂС‹С… СЃР»РѕС‚РѕРІ"""
	if not Inventory:
		return

	for i in range(NUM_SLOTS):
		var item = Inventory.get_hotbar_item(i)

		if item and item.data and not item.is_empty():
			# РРєРѕРЅРєР°
			slot_icons[i].texture = item.get_icon()
			slot_icons[i].visible = true

			# РљРѕР»РёС‡РµСЃС‚РІРѕ
			if item.quantity > 1:
				slot_quantities[i].text = str(item.quantity)
				slot_quantities[i].visible = true
			else:
				slot_quantities[i].visible = false

			# РџСЂРѕРІРµСЂСЏРµРј, РёСЃРїРѕР»СЊР·РѕРІР°РЅРѕ Р»Рё Р·РµР»СЊРµ
			if Inventory.is_potion_blocked(item):
				used_overlays[i].visible = true
				slots[i].modulate = Color(0.6, 0.6, 0.6)  # Р—Р°С‚РµРјРЅСЏРµРј
			else:
				used_overlays[i].visible = false
				slots[i].modulate = Color.WHITE
		else:
			slot_icons[i].texture = null
			slot_icons[i].visible = false
			slot_quantities[i].visible = false
			used_overlays[i].visible = false
			slots[i].modulate = Color.WHITE


func _on_hotbar_changed(_index: int):
	_refresh_hotbar()


# ===========================================
# Р’Р’РћР”
# ===========================================

func _input(event: InputEvent):
	# РќРµ РѕР±СЂР°Р±Р°С‚С‹РІР°РµРј РЅР° РїР°СѓР·Рµ
	if get_tree().paused:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_use_slot(0)
			KEY_2:
				_use_slot(1)
			KEY_3:
				_use_slot(2)
			KEY_4:
				_use_slot(3)


func _use_slot(index: int):
	"""РСЃРїРѕР»СЊР·СѓРµС‚ РїСЂРµРґРјРµС‚ РёР· Р±С‹СЃС‚СЂРѕРіРѕ СЃР»РѕС‚Р°"""
	if not Inventory:
		return

	var item = Inventory.get_hotbar_item(index)
	if not item or item.is_empty():
		print("рџ§Є РЎР»РѕС‚ %d РїСѓСЃС‚" % (index + 1))
		return


	# РџР РћР’Р•Р РљРђ: Р—РµР»СЊРµ СѓР¶Рµ РёСЃРїРѕР»СЊР·РѕРІР°РЅРѕ?
	if Inventory.is_potion_blocked(item):
		print("вљ пёЏ Р—РµР»СЊРµ '%s' СѓР¶Рµ РёСЃРїРѕР»СЊР·РѕРІР°РЅРѕ РІ СЌС‚РѕР№ РєРѕРјРЅР°С‚Рµ!" % item.get_display_name())
		_show_cannot_use_effect(index)
		return

	# РћС‚РїСЂР°РІР»СЏРµРј СЃРёРіРЅР°Р» (level1.gd РѕР±СЂР°Р±РѕС‚Р°РµС‚ СЌС„С„РµРєС‚С‹ Рё РїРѕРјРµС‚РёС‚ РєР°Рє РёСЃРїРѕР»СЊР·РѕРІР°РЅРЅРѕРµ)
	hotbar_slot_used.emit(index)

	print("рџ§Є РСЃРїРѕР»СЊР·РѕРІР°РЅ СЃР»РѕС‚ %d: %s" % [index + 1, item.get_display_name()])
	_highlight_slot(index)
	_refresh_hotbar()


func _highlight_slot(index: int):
	"""Р В Р’В Р РЋРЎСџР В Р’В Р РЋРІР‚СћР В Р’В Р СћРІР‚ВР В Р Р‹Р В РЎвЂњР В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚СњР В Р’В Р вЂ™Р’В° Р В Р’В Р РЋРІР‚ВР В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚вЂќР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ°Р В Р’В Р вЂ™Р’В·Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚СћР В Р’В Р РЋРІР‚вЂњР В Р’В Р РЋРІР‚Сћ Р В Р Р‹Р В РЎвЂњР В Р’В Р вЂ™Р’В»Р В Р’В Р РЋРІР‚СћР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р вЂ™Р’В°"""
	if index < 0 or index >= slots.size():
		return

	var slot = slots[index]
	var tween = create_tween()
	tween.tween_property(slot, "modulate", Color(1.8, 1.8, 1.8), 0.1)
	tween.tween_property(slot, "modulate", Color(0.6, 0.6, 0.6), 0.2)  # Р В Р’В Р Р†Р вЂљРІР‚СњР В Р’В Р вЂ™Р’В°Р В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р вЂ™Р’ВµР В Р’В Р РЋР’ВР В Р’В Р В РІР‚В¦Р В Р Р‹Р В Р РЏР В Р’В Р вЂ™Р’ВµР В Р’В Р РЋР’В Р В Р’В Р РЋРІР‚вЂќР В Р’В Р РЋРІР‚СћР В Р Р‹Р В РЎвЂњР В Р’В Р вЂ™Р’В»Р В Р’В Р вЂ™Р’Вµ Р В Р’В Р РЋРІР‚ВР В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚вЂќР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ°Р В Р’В Р вЂ™Р’В·Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚ВР В Р Р‹Р В Р РЏ


func _show_cannot_use_effect(index: int):
	"""Р В Р’В Р РЋРІвЂћСћР В Р Р‹Р В РІР‚С™Р В Р’В Р вЂ™Р’В°Р В Р Р‹Р В РЎвЂњР В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’В°Р В Р Р‹Р В Р РЏ Р В Р’В Р В РІР‚В Р В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚вЂќР В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р Р‹Р Р†РІР‚С™Р’В¬Р В Р’В Р РЋРІР‚СњР В Р’В Р вЂ™Р’В° - Р В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’ВµР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ°Р В Р’В Р вЂ™Р’В·Р В Р Р‹Р В Р РЏ Р В Р’В Р РЋРІР‚ВР В Р Р‹Р В РЎвЂњР В Р’В Р РЋРІР‚вЂќР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ°Р В Р’В Р вЂ™Р’В·Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’В°Р В Р Р‹Р Р†Р вЂљРЎв„ўР В Р Р‹Р В Р вЂ°"""
	if index < 0 or index >= slots.size():
		return

	var slot = slots[index]
	var original = slot.modulate

	var tween = create_tween()
	tween.tween_property(slot, "modulate", Color(1.5, 0.3, 0.3), 0.1)
	tween.tween_property(slot, "modulate", original, 0.2)
