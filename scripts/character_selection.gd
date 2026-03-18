extends CanvasLayer

const MAIN_MENU_PATH := "res://scenes/Ui/main_menu.tscn"
const LEVEL_PATH := "res://scenes/levels/level1.tscn"
const CARD_SIZE := Vector2(292, 188)
const CARD_PREVIEW_SIZE := Vector2(264, 98)
const CARD_PREVIEW_POSITION := Vector2(132, 70)
const CARD_PREVIEW_SCALE := Vector2(3.7, 3.7)
const CARD_PREVIEW_SELECTED_SCALE := Vector2(4.0, 4.0)
const WARRIOR_BANNER_HEIGHT := 28.0

const WARRIOR_PREVIEW := preload("res://scenes/characters/warrior.tscn")
const ROGUE_PREVIEW := preload("res://scenes/characters/rogue.tscn")
const BERSERK_PREVIEW := preload("res://scenes/characters/berserk.tscn")
const PALADIN_PREVIEW := preload("res://scenes/characters/paladin.tscn")

const HEART_ICON := "res://assets/icon/heart.jpg"
const ARMOR_ICON := "res://assets/icon/shield.png"
const MANA_ICON := "res://assets/icon/mana.png"
const WARRIOR_FRAME_ICON := "res://assets/icon/IconWarrior.png"
const START_BUTTON_TEXTURE := "res://assets/icon/ButtonWarrior.png"
const BLOCK_ICON := "res://assets/Spell/shield_defence.png"
const SHIELD_RUSH_ICON := "res://assets/Spell/Icon43.png"
const BULWARK_ICON := "res://assets/Spell/Bulwark Barrier.png"
const BASTION_ICON := "res://assets/Spell/Last Bastion.png"
const CHARACTER_ORDER := ["warrior", "rogue", "berserk", "paladin"]
const PREVIEW_SCENES := {
	"warrior": WARRIOR_PREVIEW,
	"rogue": ROGUE_PREVIEW,
	"berserk": BERSERK_PREVIEW,
	"paladin": PALADIN_PREVIEW,
}

const CHARACTER_PRESENTATION := {
	"warrior": {
		"name": "Воин",
		"button_name": "Воина",
		"role": "Тяжёлый фронтлайн",
		"card_note": "Щит, рывок и две защитные стойки",
		"summary": "Закрывает дистанцию щитом и выдерживает самый плотный pressure.",
		"mechanics": "Воин строится вокруг щита. Он блокирует фронтальные удары, врывается в цель рывком на своём этаже и держит темп боя двумя защитными активками.",
		"accent": Color(0.82, 0.67, 0.36, 1.0),
		"accent_soft": Color(0.24, 0.18, 0.1, 0.96),
		"stats": [
			{"label": "Здоровье", "value": "100", "icon": HEART_ICON},
			{"label": "Мана", "value": "0", "icon": MANA_ICON},
			{"label": "Броня", "value": "2", "icon": ARMOR_ICON},
			{"label": "Скорость", "value": "180"},
			{"label": "Прыжок", "value": "560"},
		],
		"active_skills": [
			{"name": "Блок щитом", "hotkey": "E", "description": "Открывает окно защиты и может наказать врага после удачного блока.", "icon": BLOCK_ICON},
			{"name": "Рывок щитом", "hotkey": "ПКМ", "description": "Стягивает воина вплотную к цели на том же этаже и заканчивается станом щитом.", "icon": SHIELD_RUSH_ICON},
			{"name": "Bulwark Barrier", "hotkey": "Q", "description": "Даёт барьер с запасом прочности 18 на 10 секунд.", "icon": BULWARK_ICON},
			{"name": "Last Bastion", "hotkey": "R", "description": "На 5 секунд усиливает броню и режет магический урон на 60%.", "icon": BASTION_ICON},
		],
	},
	"rogue": {
		"name": "Разбойник",
		"button_name": "Разбойника",
		"role": "Мобильный дуэлянт",
		"card_note": "Скорость, подкат и точные входы",
		"summary": "Самый быстрый класс. Живёт за счёт темпа и движения, а не за счёт лобового размена.",
		"mechanics": "Разбойник выигрывает позиционкой. Он быстрее всех меняет линию боя, проходит угрозу подкатом и хуже других терпит прямой pressure лицом в лицо.",
		"accent": Color(0.18, 0.76, 0.55, 1.0),
		"accent_soft": Color(0.08, 0.17, 0.14, 0.96),
		"stats": [
			{"label": "Здоровье", "value": "6", "icon": HEART_ICON},
			{"label": "Мана", "value": "8", "icon": MANA_ICON},
			{"label": "Броня", "value": "1", "icon": ARMOR_ICON},
			{"label": "Скорость", "value": "280"},
			{"label": "Прыжок", "value": "450"},
		],
		"active_skills": [
			{"name": "Подкат", "hotkey": "Shift", "description": "Быстро проводит героя под угрозой и позволяет пережить многие атаки за счёт движения.", "badge": "ПКМ"},
		],
	},
	"berserk": {
		"name": "Берсерк",
		"button_name": "Берсерка",
		"role": "Напористый штурмовик",
		"card_note": "Комбо-давление и ярость на низком HP",
		"summary": "Становится опаснее по мере затяжного боя и сильнее раскрывается, когда не даёт врагу выйти из серии.",
		"mechanics": "Берсерк давит длинной комбо-цепью. Вторая атака может критовать, третья завершает серию финишером, а на низком здоровье он режет входящий урон яростью.",
		"accent": Color(0.82, 0.28, 0.24, 1.0),
		"accent_soft": Color(0.2, 0.08, 0.08, 0.96),
		"stats": [
			{"label": "Здоровье", "value": "10", "icon": HEART_ICON},
			{"label": "Мана", "value": "0", "icon": MANA_ICON},
			{"label": "Броня", "value": "0", "icon": ARMOR_ICON},
			{"label": "Скорость", "value": "220"},
			{"label": "Прыжок", "value": "400"},
		],
		"active_skills": [
			{"name": "Комбо-цепь", "hotkey": "ЛКМ", "description": "Строит серию из трёх ударов: вторая атака может критовать, третья всегда завершает её тяжёлым финишером.", "badge": "3x"},
		],
	},
	"paladin": {
		"name": "Паладин",
		"button_name": "Паладина",
		"role": "Поддержка и выживаемость",
		"card_note": "Самоисцеление и стабильный затяжной бой",
		"summary": "Жертвует темпом ради контроля над здоровьем и лучше других держит долгий размен.",
		"mechanics": "Паладин использует ману как запас стабильности. Он может лечить себя во время боя, но должен беречь окна каста и не отдавать инициативу слишком рано.",
		"accent": Color(0.94, 0.83, 0.48, 1.0),
		"accent_soft": Color(0.2, 0.18, 0.09, 0.96),
		"button_accent": Color(0.22, 0.46, 0.88, 1.0),
		"button_font_color": Color(0.93, 0.96, 1.0, 1.0),
		"stats": [
			{"label": "Здоровье", "value": "8", "icon": HEART_ICON},
			{"label": "Мана", "value": "10", "icon": MANA_ICON},
			{"label": "Броня", "value": "1", "icon": ARMOR_ICON},
			{"label": "Скорость", "value": "200"},
			{"label": "Прыжок", "value": "380"},
		],
		"active_skills": [
			{"name": "Исцеление", "hotkey": "E", "description": "Тратит 10 маны и после каста восстанавливает 2 здоровья.", "badge": "+"},
		],
	},
}

@onready var ui_root: Control = $UiRoot
@onready var background_layer_1: TextureRect = $BackgroundLayer1

var character_cards: Dictionary = {}
var selected_character_key: String = ""

var character_grid: GridContainer
var info_placeholder: Label
var info_scroll: Control
var info_content: VBoxContainer
var selected_name_label: Label
var selected_role_label: Label
var selected_summary_label: Label
var mechanics_text_label: Label
var stats_grid: GridContainer
var active_skills_container: VBoxContainer
var passive_text_label: Label
var start_button: Button


func _ready() -> void:
	if ui_root == null:
		push_error("CharacterSelection: UiRoot not found.")
		return

	_configure_background_layers()
	_build_layout()
	_build_character_cards()
	_apply_empty_state()


func _build_layout() -> void:
	_clear_children(ui_root)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 58)
	root_margin.add_theme_constant_override("margin_top", 28)
	root_margin.add_theme_constant_override("margin_right", 58)
	root_margin.add_theme_constant_override("margin_bottom", 22)
	ui_root.add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 12)
	root_margin.add_child(root_vbox)

	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(header_row)

	var header_vbox := VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vbox.add_theme_constant_override("separation", 6)
	header_row.add_child(header_vbox)

	var title_label := Label.new()
	title_label.text = "Выбор персонажа"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	header_vbox.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = "Выбери героя под свой стиль боя. Неактивные карточки затемнены, подробности и старт откроются после выбора."
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.add_theme_color_override("font_color", Color(0.77, 0.77, 0.82))
	header_vbox.add_child(subtitle_label)

	var back_button := Button.new()
	back_button.text = "Назад"
	back_button.custom_minimum_size = Vector2(136, 40)
	back_button.focus_mode = Control.FOCUS_NONE
	_apply_secondary_button_style(back_button)
	back_button.pressed.connect(_on_back_button_pressed)
	header_row.add_child(back_button)

	var content_row := HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 20)
	root_vbox.add_child(content_row)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(628, 0)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.05, 0.08, 0.15), Color(0.36, 0.4, 0.48, 0.44), 1))
	content_row.add_child(left_panel)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 14)
	left_margin.add_theme_constant_override("margin_top", 14)
	left_margin.add_theme_constant_override("margin_right", 14)
	left_margin.add_theme_constant_override("margin_bottom", 14)
	left_panel.add_child(left_margin)

	character_grid = GridContainer.new()
	character_grid.columns = 2
	character_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_grid.add_theme_constant_override("h_separation", 14)
	character_grid.add_theme_constant_override("v_separation", 14)
	left_margin.add_child(character_grid)

	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(424, 0)
	right_panel.size_flags_horizontal = Control.SIZE_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.05, 0.08, 0.14), Color(0.36, 0.4, 0.48, 0.44), 1))
	content_row.add_child(right_panel)

	var right_margin := MarginContainer.new()
	right_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_margin.add_theme_constant_override("margin_left", 12)
	right_margin.add_theme_constant_override("margin_top", 12)
	right_margin.add_theme_constant_override("margin_right", 12)
	right_margin.add_theme_constant_override("margin_bottom", 12)
	right_panel.add_child(right_margin)

	var right_stack := VBoxContainer.new()
	right_stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_stack.add_theme_constant_override("separation", 6)
	right_margin.add_child(right_stack)

	info_placeholder = Label.new()
	info_placeholder.text = "Выбери карточку героя слева,\nчтобы открыть его механику,\nточные характеристики и навыки."
	info_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_placeholder.add_theme_font_size_override("font_size", 20)
	info_placeholder.add_theme_color_override("font_color", Color(0.68, 0.7, 0.76))
	right_stack.add_child(info_placeholder)

	info_scroll = VBoxContainer.new()
	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_scroll.add_theme_constant_override("separation", 8)
	right_stack.add_child(info_scroll)

	info_content = info_scroll as VBoxContainer

	selected_name_label = Label.new()
	selected_name_label.add_theme_font_size_override("font_size", 20)
	selected_name_label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.88))
	info_content.add_child(selected_name_label)

	selected_role_label = Label.new()
	selected_role_label.add_theme_font_size_override("font_size", 13)
	info_content.add_child(selected_role_label)

	selected_summary_label = Label.new()
	selected_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_summary_label.add_theme_font_size_override("font_size", 12)
	selected_summary_label.add_theme_color_override("font_color", Color(0.86, 0.86, 0.9))
	info_content.add_child(selected_summary_label)

	info_content.add_child(_make_section_label("Механика класса"))

	mechanics_text_label = Label.new()
	mechanics_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mechanics_text_label.add_theme_font_size_override("font_size", 12)
	mechanics_text_label.add_theme_color_override("font_color", Color(0.78, 0.8, 0.86))
	info_content.add_child(mechanics_text_label)

	info_content.add_child(_make_section_label("Базовые характеристики"))

	stats_grid = GridContainer.new()
	stats_grid.columns = 5
	stats_grid.add_theme_constant_override("h_separation", 4)
	stats_grid.add_theme_constant_override("v_separation", 4)
	info_content.add_child(stats_grid)

	info_content.add_child(_make_section_label("Уникальные активные навыки"))

	active_skills_container = VBoxContainer.new()
	active_skills_container.add_theme_constant_override("separation", 4)
	info_content.add_child(active_skills_container)

	info_content.add_child(_make_section_label("Пассивные навыки"))

	var passive_panel := PanelContainer.new()
	passive_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.07, 0.08, 0.12, 0.18), Color(0.32, 0.36, 0.42, 0.36), 1))
	info_content.add_child(passive_panel)

	var passive_margin := MarginContainer.new()
	passive_margin.add_theme_constant_override("margin_left", 10)
	passive_margin.add_theme_constant_override("margin_top", 8)
	passive_margin.add_theme_constant_override("margin_right", 10)
	passive_margin.add_theme_constant_override("margin_bottom", 8)
	passive_panel.add_child(passive_margin)

	passive_text_label = Label.new()
	passive_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_text_label.add_theme_font_size_override("font_size", 11)
	passive_text_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
	passive_margin.add_child(passive_text_label)

	start_button = Button.new()
	start_button.text = "Начать игру"
	start_button.custom_minimum_size = Vector2(0, 52)
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.pressed.connect(_on_start_button_pressed)
	info_content.add_child(start_button)


func _build_character_cards() -> void:
	character_cards.clear()

	for character_key in CHARACTER_ORDER:
		var data: Dictionary = CHARACTER_PRESENTATION[character_key]
		var card := Button.new()
		card.flat = true
		card.text = ""
		card.focus_mode = Control.FOCUS_NONE
		card.clip_contents = false
		card.custom_minimum_size = CARD_SIZE
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_on_character_card_pressed.bind(character_key))
		character_grid.add_child(card)

		var accent_bar: PanelContainer = null
		var banner_label: Label = null

		var card_margin := MarginContainer.new()
		card_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_margin.add_theme_constant_override("margin_left", 14)
		card_margin.add_theme_constant_override("margin_top", 14)
		card_margin.add_theme_constant_override("margin_right", 14)
		card_margin.add_theme_constant_override("margin_bottom", 12)
		card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(card_margin)

		var card_vbox := VBoxContainer.new()
		card_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_vbox.add_theme_constant_override("separation", 4)
		card_margin.add_child(card_vbox)

		if character_key == "warrior":
			accent_bar = PanelContainer.new()
			accent_bar.custom_minimum_size = Vector2(0, WARRIOR_BANNER_HEIGHT)
			accent_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			accent_bar.add_theme_stylebox_override("panel", _make_warrior_banner_style())
			card_vbox.add_child(accent_bar)

			banner_label = Label.new()
			banner_label.text = data["name"]
			banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			banner_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			banner_label.add_theme_font_size_override("font_size", 16)
			banner_label.add_theme_color_override("font_color", Color(0.26, 0.08, 0.06))
			accent_bar.add_child(banner_label)

		var name_label := Label.new()
		name_label.text = data["name"]
		name_label.add_theme_font_size_override("font_size", 17)
		name_label.visible = character_key != "warrior"
		card_vbox.add_child(name_label)

		var role_label := Label.new()
		role_label.text = data["role"]
		role_label.add_theme_font_size_override("font_size", 12)
		card_vbox.add_child(role_label)

		var preview_stage := Control.new()
		preview_stage.custom_minimum_size = CARD_PREVIEW_SIZE
		preview_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
		preview_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(preview_stage)

		var preview_scene: PackedScene = PREVIEW_SCENES[character_key]
		var preview = preview_scene.instantiate()
		preview_stage.add_child(preview)
		preview.position = CARD_PREVIEW_POSITION
		preview.scale = CARD_PREVIEW_SCALE
		_disable_preview_input(preview)

		var note_label := Label.new()
		note_label.text = data["card_note"]
		note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note_label.add_theme_font_size_override("font_size", 10)
		note_label.add_theme_color_override("font_color", Color(0.73, 0.75, 0.8))
		card_vbox.add_child(note_label)

		character_cards[character_key] = {
			"button": card,
			"accent_bar": accent_bar,
			"banner_label": banner_label,
			"name_label": name_label,
			"role_label": role_label,
			"note_label": note_label,
			"preview": preview,
		}

		_apply_card_state(character_key, false)


func _apply_empty_state() -> void:
	selected_character_key = ""
	info_placeholder.visible = true
	info_scroll.visible = false
	start_button.visible = false


func _on_character_card_pressed(character_key: String) -> void:
	if selected_character_key == character_key:
		return

	var previous_key := selected_character_key
	selected_character_key = character_key

	if previous_key != "" and character_cards.has(previous_key):
		_apply_card_state(previous_key, false)

	_apply_card_state(character_key, true)
	_populate_info_panel(character_key)


func _populate_info_panel(character_key: String) -> void:
	var data: Dictionary = CHARACTER_PRESENTATION[character_key]

	info_placeholder.visible = false
	info_scroll.visible = true
	start_button.visible = true

	selected_name_label.text = data["name"]
	selected_role_label.text = data["role"]
	selected_summary_label.text = data["summary"]
	mechanics_text_label.text = data["mechanics"]
	passive_text_label.text = "Пассивные навыки ещё не вынесены в отдельную систему. Этот блок зарезервирован под будущие пассивы класса."

	var accent: Color = data["accent"]
	var button_accent: Color = data.get("button_accent", accent)
	var button_font_color: Color = data.get("button_font_color", Color(0.13, 0.08, 0.04))
	selected_role_label.add_theme_color_override("font_color", accent)
	start_button.text = "Начать за %s" % data["button_name"]
	_apply_start_button_style(button_accent, button_font_color)

	_rebuild_stats(data["stats"], accent)
	_rebuild_active_skills(data["active_skills"], accent)


func _rebuild_stats(stats: Array, accent: Color) -> void:
	_clear_children(stats_grid)

	for stat: Dictionary in stats:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", _make_panel_style(Color(0.07, 0.08, 0.12, 0.18), accent.darkened(0.4), 1))
		chip.custom_minimum_size = Vector2(0, 44)
		stats_grid.add_child(chip)

		var chip_margin := MarginContainer.new()
		chip_margin.add_theme_constant_override("margin_left", 6)
		chip_margin.add_theme_constant_override("margin_top", 5)
		chip_margin.add_theme_constant_override("margin_right", 6)
		chip_margin.add_theme_constant_override("margin_bottom", 5)
		chip.add_child(chip_margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		chip_margin.add_child(row)

		if stat.has("icon"):
			var icon_texture: Texture2D = load(stat["icon"]) as Texture2D
			if icon_texture != null:
				var icon_holder := Control.new()
				icon_holder.custom_minimum_size = Vector2(16, 16)
				row.add_child(icon_holder)

				var icon_rect := TextureRect.new()
				icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
				icon_rect.texture = icon_texture
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_holder.add_child(icon_rect)

		var text_box := VBoxContainer.new()
		text_box.add_theme_constant_override("separation", 1)
		row.add_child(text_box)

		var label := Label.new()
		label.text = stat["label"]
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.68, 0.7, 0.76))
		text_box.add_child(label)

		var value := Label.new()
		value.text = stat["value"]
		value.add_theme_font_size_override("font_size", 13)
		value.add_theme_color_override("font_color", Color(0.94, 0.94, 0.96))
		text_box.add_child(value)


func _rebuild_active_skills(skills: Array, accent: Color) -> void:
	_clear_children(active_skills_container)

	for skill: Dictionary in skills:
		active_skills_container.add_child(_create_skill_row(skill, accent))


func _create_skill_row(skill: Dictionary, accent: Color) -> PanelContainer:
	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.07, 0.08, 0.12, 0.16), accent.darkened(0.45), 1))

	var row_margin := MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left", 6)
	row_margin.add_theme_constant_override("margin_top", 6)
	row_margin.add_theme_constant_override("margin_right", 6)
	row_margin.add_theme_constant_override("margin_bottom", 6)
	row_panel.add_child(row_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row_margin.add_child(row)

	var icon_holder := CenterContainer.new()
	icon_holder.custom_minimum_size = Vector2(30, 30)
	row.add_child(icon_holder)

	var icon_path: String = String(skill.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var skill_icon := TextureRect.new()
		skill_icon.custom_minimum_size = Vector2(24, 24)
		skill_icon.texture = load(icon_path)
		skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_holder.add_child(skill_icon)
	else:
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(28, 28)
		badge.add_theme_stylebox_override("panel", _make_panel_style(accent.darkened(0.1), accent.lightened(0.08), 1))
		icon_holder.add_child(badge)

		var badge_label := Label.new()
		badge_label.text = skill.get("badge", skill.get("hotkey", "?"))
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.add_theme_font_size_override("font_size", 11)
		badge_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.1))
		badge_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge.add_child(badge_label)

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 3)
	row.add_child(info_box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	info_box.add_child(title_row)

	var skill_name := Label.new()
	skill_name.text = skill["name"]
	skill_name.add_theme_font_size_override("font_size", 13)
	skill_name.add_theme_color_override("font_color", Color(0.94, 0.94, 0.96))
	title_row.add_child(skill_name)

	var hotkey_label := Label.new()
	hotkey_label.text = skill["hotkey"]
	hotkey_label.add_theme_font_size_override("font_size", 10)
	hotkey_label.add_theme_color_override("font_color", accent)
	title_row.add_child(hotkey_label)

	var description_label := Label.new()
	description_label.text = skill["description"]
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 11)
	description_label.add_theme_color_override("font_color", Color(0.72, 0.74, 0.8))
	info_box.add_child(description_label)

	return row_panel


func _apply_card_state(character_key: String, is_selected: bool) -> void:
	var card_state: Dictionary = character_cards.get(character_key, {})
	if card_state.is_empty():
		return

	var data: Dictionary = CHARACTER_PRESENTATION[character_key]
	var button: Button = card_state["button"]
	var accent_bar: PanelContainer = card_state["accent_bar"] as PanelContainer
	var banner_label: Label = card_state.get("banner_label") as Label
	var name_label: Label = card_state["name_label"]
	var role_label: Label = card_state["role_label"]
	var note_label: Label = card_state["note_label"]
	var preview: Node2D = card_state["preview"]

	var accent: Color = data["accent"]
	var base_fill: Color = data["accent_soft"]
	var border_color: Color = accent if is_selected else Color(0.24, 0.26, 0.32, 0.95)
	var fill_color := Color(base_fill.r, base_fill.g, base_fill.b, 0.22 if is_selected else 0.08)
	var hover_fill := Color(base_fill.r, base_fill.g, base_fill.b, 0.3 if is_selected else 0.14)

	button.add_theme_stylebox_override("normal", _make_panel_style(fill_color, border_color, 2 if is_selected else 1))
	button.add_theme_stylebox_override("hover", _make_panel_style(hover_fill, accent.lightened(0.15), 2))
	button.add_theme_stylebox_override("pressed", _make_panel_style(hover_fill.darkened(0.06), accent.lightened(0.25), 2))
	button.add_theme_stylebox_override("focus", _make_panel_style(hover_fill, accent.lightened(0.25), 2))

	if accent_bar != null:
		accent_bar.modulate = Color(1, 1, 1, 1) if is_selected else Color(0.5, 0.5, 0.55, 0.65)
	if banner_label != null:
		banner_label.add_theme_color_override("font_color", Color(0.26, 0.08, 0.06) if is_selected else Color(0.35, 0.18, 0.16))
	name_label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.88) if is_selected else Color(0.58, 0.6, 0.66))
	role_label.add_theme_color_override("font_color", accent if is_selected else Color(0.47, 0.49, 0.55))
	note_label.add_theme_color_override("font_color", Color(0.75, 0.77, 0.82) if is_selected else Color(0.42, 0.44, 0.5))

	_set_preview_state(preview, is_selected)


func _set_preview_state(preview: Node2D, is_selected: bool) -> void:
	if preview == null:
		return

	var animated_sprite := preview.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite != null:
		if is_selected:
			if preview.has_method("play_demonstration_animation"):
				preview.play_demonstration_animation()
			elif preview.has_method("on_selected"):
				preview.on_selected()
			else:
				animated_sprite.play()
		else:
			animated_sprite.stop()
			animated_sprite.frame = 0
			animated_sprite.frame_progress = 0.0

	preview.modulate = Color.WHITE if is_selected else Color(0.34, 0.34, 0.38, 1.0)
	preview.scale = CARD_PREVIEW_SELECTED_SCALE if is_selected else CARD_PREVIEW_SCALE


func _disable_preview_input(preview: Node) -> void:
	var area := preview.get_node_or_null("Area2D") as Area2D
	if area != null:
		area.input_pickable = false
		area.monitoring = false


func _apply_start_button_style(accent: Color, font_color: Color = Color(0.13, 0.08, 0.04)) -> void:
	start_button.add_theme_stylebox_override("normal", _make_button_style(accent))
	start_button.add_theme_stylebox_override("hover", _make_button_style(accent.lightened(0.08)))
	start_button.add_theme_stylebox_override("pressed", _make_button_style(accent.darkened(0.08)))
	start_button.add_theme_stylebox_override("focus", _make_button_style(accent.lightened(0.12)))
	start_button.add_theme_font_size_override("font_size", 19)
	start_button.add_theme_color_override("font_color", font_color)


func _apply_secondary_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_secondary_button_style(Color(0.16, 0.18, 0.24, 0.5)))
	button.add_theme_stylebox_override("hover", _make_secondary_button_style(Color(0.2, 0.22, 0.28, 0.64)))
	button.add_theme_stylebox_override("pressed", _make_secondary_button_style(Color(0.12, 0.14, 0.2, 0.72)))
	button.add_theme_stylebox_override("focus", _make_secondary_button_style(Color(0.2, 0.22, 0.28, 0.7)))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.92, 0.93, 0.96))


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
	return label


func _make_panel_style(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	return style


func _make_button_style(fill_color: Color) -> StyleBox:
	var texture := load(START_BUTTON_TEXTURE) as Texture2D
	if texture == null:
		var fallback := StyleBoxFlat.new()
		fallback.bg_color = fill_color
		fallback.corner_radius_top_left = 14
		fallback.corner_radius_top_right = 14
		fallback.corner_radius_bottom_right = 14
		fallback.corner_radius_bottom_left = 14
		return fallback

	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = fill_color
	style.texture_margin_left = 42
	style.texture_margin_top = 18
	style.texture_margin_right = 42
	style.texture_margin_bottom = 18
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style


func _make_warrior_banner_style() -> StyleBox:
	var texture := load(WARRIOR_FRAME_ICON) as Texture2D
	if texture == null:
		return _make_panel_style(Color(0.74, 0.56, 0.34, 0.96), Color(0.92, 0.74, 0.5, 1.0), 1)

	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 20
	style.texture_margin_top = 8
	style.texture_margin_right = 20
	style.texture_margin_bottom = 8
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style


func _make_secondary_button_style(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color(0.56, 0.6, 0.7, 0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	return style


func _configure_background_layers() -> void:
	if background_layer_1 != null:
		background_layer_1.stretch_mode = TextureRect.STRETCH_SCALE


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _on_start_button_pressed() -> void:
	if selected_character_key == "":
		OS.alert("Сначала выберите персонажа.", "Выбор персонажа")
		return

	Global.selected_character = selected_character_key
	get_tree().change_scene_to_file(LEVEL_PATH)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
