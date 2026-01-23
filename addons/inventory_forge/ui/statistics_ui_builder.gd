@tool
class_name StatisticsUIBuilder
extends RefCounted
## Helper class for building statistics UI components.
## Reduces code duplication in the main panel.
##
## Inventory Forge Plugin by Menkos
## License: MIT


## Creates a stat card (panel with value and title)
static func create_stat_card(title: String, value: String, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 28)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value_label)
	
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	margin.add_child(vbox)
	card.add_child(margin)
	
	return card


## Creates a section title label
static func create_section_title(title: String) -> Label:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 1))
	return label


## Creates a progress row (label + progress bar + count)
static func create_progress_row(label_text: String, value: int, max_value: int, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 0)
	row.add_child(label)
	
	var progress := ProgressBar.new()
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.custom_minimum_size = Vector2(150, 20)
	progress.max_value = max_value if max_value > 0 else 1
	progress.value = value
	progress.show_percentage = false
	
	# Stilizza la progress bar
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	progress.add_theme_stylebox_override("fill", style)
	
	row.add_child(progress)
	
	var count_label := Label.new()
	var percentage := (float(value) / float(max_value) * 100.0) if max_value > 0 else 0.0
	count_label.text = "%d (%d%%)" % [value, int(percentage)]
	count_label.custom_minimum_size = Vector2(80, 0)
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	row.add_child(count_label)
	
	return row


## Creates a category distribution chart
static func create_category_chart(counts: Dictionary, total: int) -> VBoxContainer:
	var chart_container := VBoxContainer.new()
	chart_container.add_theme_constant_override("separation", 6)
	
	for category in ItemEnums.Category.values():
		var count: int = counts.get(category, 0)
		var category_name: String = ItemEnums.Category.keys()[category]
		var row := create_progress_row(category_name.capitalize(), count, total, Color.CORNFLOWER_BLUE)
		chart_container.add_child(row)
	
	return chart_container


## Creates a rarity distribution chart
static func create_rarity_chart(counts: Dictionary, total: int) -> VBoxContainer:
	var chart_container := VBoxContainer.new()
	chart_container.add_theme_constant_override("separation", 6)
	
	for rarity in ItemEnums.Rarity.values():
		var count: int = counts.get(rarity, 0)
		var rarity_name: String = ItemEnums.Rarity.keys()[rarity]
		var color := ItemEnums.get_rarity_color(rarity)
		var row := create_progress_row(rarity_name.capitalize(), count, total, color)
		chart_container.add_child(row)
	
	return chart_container


## Creates a material type distribution chart (two columns)
static func create_material_type_chart(counts: Dictionary, total: int) -> HBoxContainer:
	var chart_container := HBoxContainer.new()
	chart_container.add_theme_constant_override("separation", 20)
	
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 6)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 6)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var i := 0
	for mat_type in ItemEnums.MaterialType.values():
		if mat_type == ItemEnums.MaterialType.NONE:
			continue
		var count: int = counts.get(mat_type, 0)
		if count == 0:
			continue
		var mat_name: String = ItemEnums.MaterialType.keys()[mat_type]
		var target_col := left_col if i % 2 == 0 else right_col
		var row := create_progress_row(mat_name.capitalize(), count, total, Color.MEDIUM_PURPLE)
		target_col.add_child(row)
		i += 1
	
	chart_container.add_child(left_col)
	chart_container.add_child(right_col)
	
	return chart_container


## Creates a rarity tier distribution chart (for loot tables)
static func create_rarity_tier_chart(counts: Dictionary, total: int) -> VBoxContainer:
	var chart_container := VBoxContainer.new()
	chart_container.add_theme_constant_override("separation", 6)
	
	# Colori per i rarity tier
	var tier_colors := {
		LootTable.RarityTier.CUSTOM: Color(0.5, 0.5, 0.5, 1),
		LootTable.RarityTier.COMMON: Color(0.8, 0.8, 0.8, 1),
		LootTable.RarityTier.UNCOMMON: Color(0.3, 0.8, 0.3, 1),
		LootTable.RarityTier.RARE: Color(0.3, 0.5, 1.0, 1),
		LootTable.RarityTier.EPIC: Color(0.6, 0.3, 0.9, 1),
		LootTable.RarityTier.LEGENDARY: Color(1.0, 0.6, 0.1, 1),
	}
	
	for tier in LootTable.RarityTier.values():
		var count: int = counts.get(tier, 0)
		var tier_name: String = LootTable.get_rarity_name(tier)
		var color: Color = tier_colors.get(tier, Color.WHITE)
		var row := create_progress_row(tier_name, count, total, color)
		chart_container.add_child(row)
	
	return chart_container
