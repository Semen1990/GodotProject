@tool
@icon("res://addons/inventory_forge/icons/inventory_forge_icon.svg")
class_name LootTableDatabase
extends Resource
## Database containing all loot tables.
## Manages LootTable collection and provides search/roll methods.
##
## Inventory Forge Plugin by Menkos
## License: MIT

# === Signals ===
signal table_added(table: LootTable)
signal table_removed(table: LootTable)
signal database_changed()

# === Data ===
@export var tables: Array[LootTable] = []:
	set(value):
		tables = value
		emit_changed()
		database_changed.emit()


# === Search Methods ===

## Gets a loot table by ID
func get_table_by_id(id: String) -> LootTable:
	for table in tables:
		if table and table.id == id:
			return table
	return null


## Gets the index of a table by ID
func get_table_index_by_id(id: String) -> int:
	for i in range(tables.size()):
		if tables[i] and tables[i].id == id:
			return i
	return -1


## Checks if a table with the specified ID exists
func has_table(id: String) -> bool:
	return get_table_by_id(id) != null


## Search tables by name or ID
func search_tables(query: String) -> Array[LootTable]:
	if query.is_empty():
		return tables.duplicate()
	
	var result: Array[LootTable] = []
	var query_lower := query.to_lower()
	
	for table in tables:
		if table == null:
			continue
		
		if table.id.to_lower().contains(query_lower):
			result.append(table)
			continue
		
		if table.name.to_lower().contains(query_lower):
			result.append(table)
			continue
	
	return result


# === Management Methods ===

## Adds a new table to the database
func add_table(table: LootTable) -> void:
	if table == null:
		return
	
	tables.append(table)
	emit_changed()
	table_added.emit(table)
	database_changed.emit()


## Creates and adds a new empty table
func create_new_table() -> LootTable:
	var new_table := LootTable.new()
	new_table.id = _generate_unique_id()
	new_table.name = "New Loot Table"
	add_table(new_table)
	return new_table


## Removes a table from the database
func remove_table(table: LootTable) -> bool:
	var index := tables.find(table)
	if index >= 0:
		tables.remove_at(index)
		emit_changed()
		table_removed.emit(table)
		database_changed.emit()
		return true
	return false


## Removes a table by ID
func remove_table_by_id(id: String) -> bool:
	var table := get_table_by_id(id)
	if table:
		return remove_table(table)
	return false


## Duplicates an existing table
func duplicate_table(table: LootTable) -> LootTable:
	if table == null:
		return null
	
	var new_table := table.duplicate_table()
	new_table.id = _generate_unique_id(table.id)
	add_table(new_table)
	return new_table


## Sorts tables by ID
func sort_by_id() -> void:
	tables.sort_custom(func(a, b): return a.id < b.id)
	emit_changed()
	database_changed.emit()


## Sorts tables by name
func sort_by_name() -> void:
	tables.sort_custom(func(a, b): return a.name < b.name)
	emit_changed()
	database_changed.emit()


# === Roll Methods ===

## Rolls a loot table by ID (without sub-tables)
func roll_table(id: String) -> LootTable.LootResult:
	var table := get_table_by_id(id)
	if table:
		return table.roll()
	return LootTable.LootResult.new()


## Rolls a loot table by ID including all its sub-tables
func roll_table_full(id: String) -> LootTable.LootResult:
	var table := get_table_by_id(id)
	if table:
		return table.roll_with_sub_tables(self)
	return LootTable.LootResult.new()


## Rolls multiple tables and combines results (without sub-tables)
func roll_tables(ids: Array[String]) -> LootTable.LootResult:
	var combined := LootTable.LootResult.new()
	
	for table_id in ids:
		var table := get_table_by_id(table_id)
		if table:
			var result := table.roll()
			for entry in result.items:
				combined.add(entry.item, entry.quantity)
	
	return combined


## Rolls multiple tables including their sub-tables and combines results
func roll_tables_full(ids: Array[String]) -> LootTable.LootResult:
	var combined := LootTable.LootResult.new()
	
	for table_id in ids:
		var table := get_table_by_id(table_id)
		if table:
			var result := table.roll_with_sub_tables(self)
			for entry in result.items:
				combined.add(entry.item, entry.quantity)
	
	return combined


# === Validation ===

## Gets all tables with warnings
func get_tables_with_warnings() -> Array[LootTable]:
	var result: Array[LootTable] = []
	for table in tables:
		if table and not table.get_validation_warnings().is_empty():
			result.append(table)
	return result


## Gets all duplicate IDs
func get_duplicate_ids() -> Array[String]:
	var id_count := {}
	var duplicates: Array[String] = []
	
	for table in tables:
		if table == null:
			continue
		if id_count.has(table.id):
			id_count[table.id] += 1
			if not duplicates.has(table.id):
				duplicates.append(table.id)
		else:
			id_count[table.id] = 1
	
	return duplicates


## Validates the entire database
func validate() -> Array[String]:
	var errors: Array[String] = []
	
	# Check for duplicate IDs
	var duplicate_ids := get_duplicate_ids()
	for dup_id in duplicate_ids:
		errors.append("Duplicate table ID: %s" % dup_id)
	
	# Check for invalid tables
	for table in tables:
		if table == null:
			errors.append("Null table found in database")
			continue
		
		var warnings := table.get_validation_warnings()
		for warning in warnings:
			errors.append("Table '%s': %s" % [table.id, warning])
	
	return errors


# === Statistics ===

## Gets database statistics
func get_stats() -> Dictionary:
	var total_entries := 0
	var tables_with_warnings := 0
	var empty_tables := 0
	var tables_with_sub_tables := 0
	var rarity_tier_counts := {}
	
	# Inizializza contatori per rarity tier
	for tier in LootTable.RarityTier.values():
		rarity_tier_counts[tier] = 0
	
	for table in tables:
		if table:
			total_entries += table.entries.size()
			if not table.get_validation_warnings().is_empty():
				tables_with_warnings += 1
			if table.entries.is_empty():
				empty_tables += 1
			if table.has_sub_tables():
				tables_with_sub_tables += 1
			rarity_tier_counts[table.rarity_tier] += 1
	
	var avg_entries := 0.0
	if tables.size() > 0:
		avg_entries = float(total_entries) / float(tables.size())
	
	return {
		"total_tables": tables.size(),
		"total_entries": total_entries,
		"avg_entries_per_table": avg_entries,
		"empty_tables": empty_tables,
		"tables_with_sub_tables": tables_with_sub_tables,
		"tables_with_warnings": tables_with_warnings,
		"duplicate_ids": get_duplicate_ids().size(),
		"rarity_tier_counts": rarity_tier_counts,
	}


# === Export Methods ===

## Exports the database to JSON format
func export_to_json() -> String:
	var data := {
		"version": "1.0",
		"export_date": Time.get_datetime_string_from_system(),
		"loot_tables": []
	}
	
	for table in tables:
		if table == null:
			continue
		data.loot_tables.append(_table_to_dict(table))
	
	return JSON.stringify(data, "\t")


## Exports the database to a JSON file
func export_to_json_file(path: String) -> Error:
	var json_string := export_to_json()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[InventoryForge] Failed to open file for writing: %s" % path)
		return FileAccess.get_open_error()
	
	file.store_string(json_string)
	file.close()
	return OK


## Exports the database to CSV format
func export_to_csv() -> String:
	var lines: Array[String] = []
	
	# Header
	var headers := [
		"id", "name", "description", "rarity_tier",
		"min_drops", "max_drops", "empty_chance", "allow_duplicates",
		"sub_table_ids", "entries"
	]
	lines.append(",".join(headers))
	
	# Data rows
	for table in tables:
		if table == null:
			continue
		
		# Serialize sub_table_ids as semicolon-separated
		var sub_tables_str := ";".join(table.sub_table_ids)
		
		# Serialize entries as semicolon-separated item_id:weight:min_qty:max_qty:enabled
		var entries_parts: Array[String] = []
		for entry in table.entries:
			if entry and entry.item:
				var enabled_str := "1" if entry.enabled else "0"
				entries_parts.append("%d:%.2f:%d:%d:%s" % [
					entry.item.id,
					entry.weight,
					entry.min_quantity,
					entry.max_quantity,
					enabled_str
				])
		var entries_str := ";".join(entries_parts)
		
		var row := [
			_escape_csv(table.id),
			_escape_csv(table.name),
			_escape_csv(table.description),
			LootTable.RarityTier.keys()[table.rarity_tier],
			str(table.min_drops),
			str(table.max_drops),
			str(table.empty_chance),
			"true" if table.allow_duplicates else "false",
			_escape_csv(sub_tables_str),
			_escape_csv(entries_str)
		]
		lines.append(",".join(row))
	
	return "\n".join(lines)


## Exports the database to a CSV file
func export_to_csv_file(path: String) -> Error:
	var csv_string := export_to_csv()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[InventoryForge] Failed to open file for writing: %s" % path)
		return FileAccess.get_open_error()
	
	file.store_string(csv_string)
	file.close()
	return OK


## Helper: Convert table to dictionary for JSON export
func _table_to_dict(table: LootTable) -> Dictionary:
	var entries_data: Array[Dictionary] = []
	for entry in table.entries:
		if entry and entry.item:
			entries_data.append({
				"item_id": entry.item.id,
				"weight": entry.weight,
				"min_quantity": entry.min_quantity,
				"max_quantity": entry.max_quantity,
				"enabled": entry.enabled
			})
	
	return {
		"id": table.id,
		"name": table.name,
		"description": table.description,
		"rarity_tier": LootTable.RarityTier.keys()[table.rarity_tier],
		"min_drops": table.min_drops,
		"max_drops": table.max_drops,
		"empty_chance": table.empty_chance,
		"allow_duplicates": table.allow_duplicates,
		"sub_table_ids": table.sub_table_ids.duplicate(),
		"entries": entries_data
	}


## Helper: Escape CSV field
func _escape_csv(value: String) -> String:
	if value.contains(",") or value.contains("\"") or value.contains("\n"):
		return "\"%s\"" % value.replace("\"", "\"\"")
	return value


# === Import Methods ===

## Import mode for merging data
enum ImportMode {
	REPLACE_ALL,      # Clear database and import
	MERGE_SKIP,       # Skip tables with existing IDs
	MERGE_OVERWRITE,  # Overwrite tables with existing IDs
}


## Imports tables from JSON string
func import_from_json(json_string: String, mode: ImportMode = ImportMode.MERGE_SKIP, item_database: Resource = null) -> Dictionary:
	var result := {"success": false, "imported": 0, "skipped": 0, "errors": []}
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	
	if parse_result != OK:
		result.errors.append("Failed to parse JSON: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return result
	
	var data: Dictionary = json.data
	if not data.has("loot_tables") or not data.loot_tables is Array:
		result.errors.append("Invalid JSON structure: missing 'loot_tables' array")
		return result
	
	if mode == ImportMode.REPLACE_ALL:
		tables.clear()
	
	for table_data in data.loot_tables:
		var import_result := _import_table_from_dict(table_data, mode, item_database)
		if import_result.success:
			result.imported += 1
		elif import_result.skipped:
			result.skipped += 1
		else:
			result.errors.append(import_result.error)
	
	if result.imported > 0:
		emit_changed()
		database_changed.emit()
	
	result.success = result.errors.is_empty()
	return result


## Imports tables from a JSON file
func import_from_json_file(path: String, mode: ImportMode = ImportMode.MERGE_SKIP, item_database: Resource = null) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "imported": 0, "skipped": 0, "errors": ["Failed to open file: %s" % path]}
	
	var json_string := file.get_as_text()
	file.close()
	
	return import_from_json(json_string, mode, item_database)


## Imports tables from CSV string
func import_from_csv(csv_string: String, mode: ImportMode = ImportMode.MERGE_SKIP, item_database: Resource = null) -> Dictionary:
	var result := {"success": false, "imported": 0, "skipped": 0, "errors": []}
	
	var lines := csv_string.split("\n")
	if lines.size() < 2:
		result.errors.append("CSV file is empty or has no data rows")
		return result
	
	# Parse header
	var headers := _parse_csv_line(lines[0])
	
	if mode == ImportMode.REPLACE_ALL:
		tables.clear()
	
	# Parse data rows
	for i in range(1, lines.size()):
		var line := lines[i].strip_edges()
		if line.is_empty():
			continue
		
		var values := _parse_csv_line(line)
		if values.size() != headers.size():
			result.errors.append("Line %d: column count mismatch (expected %d, got %d)" % [i + 1, headers.size(), values.size()])
			continue
		
		var table_data := {}
		for j in range(headers.size()):
			table_data[headers[j]] = values[j]
		
		var import_result := _import_table_from_csv_row(table_data, mode, item_database)
		if import_result.success:
			result.imported += 1
		elif import_result.skipped:
			result.skipped += 1
		else:
			result.errors.append("Line %d: %s" % [i + 1, import_result.error])
	
	if result.imported > 0:
		emit_changed()
		database_changed.emit()
	
	result.success = result.errors.is_empty()
	return result


## Imports tables from a CSV file
func import_from_csv_file(path: String, mode: ImportMode = ImportMode.MERGE_SKIP, item_database: Resource = null) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "imported": 0, "skipped": 0, "errors": ["Failed to open file: %s" % path]}
	
	var csv_string := file.get_as_text()
	file.close()
	
	return import_from_csv(csv_string, mode, item_database)


## Helper: Import single table from dictionary (JSON)
func _import_table_from_dict(data: Dictionary, mode: ImportMode, item_database: Resource = null) -> Dictionary:
	var result := {"success": false, "skipped": false, "error": ""}
	
	if not data.has("id"):
		result.error = "Missing 'id' field"
		return result
	
	var id: String = str(data.get("id", ""))
	var existing := get_table_by_id(id)
	
	if existing and mode == ImportMode.MERGE_SKIP:
		result.skipped = true
		return result
	
	var table: LootTable
	if existing and mode == ImportMode.MERGE_OVERWRITE:
		table = existing
		table.entries.clear()
	else:
		table = LootTable.new()
		table.id = id
	
	# Set basic properties
	table.name = str(data.get("name", ""))
	table.description = str(data.get("description", ""))
	
	# Enum
	table.rarity_tier = _parse_rarity_tier(data.get("rarity_tier", "CUSTOM"))
	
	# Numeric values
	table.min_drops = int(data.get("min_drops", 1))
	table.max_drops = int(data.get("max_drops", 1))
	table.empty_chance = float(data.get("empty_chance", 0.0))
	
	# Booleans
	table.allow_duplicates = _parse_bool(data.get("allow_duplicates", true))
	
	# Sub-table IDs
	var sub_ids = data.get("sub_table_ids", [])
	if sub_ids is Array:
		table.sub_table_ids.clear()
		for sub_id in sub_ids:
			table.sub_table_ids.append(str(sub_id))
	
	# Entries - requires item_database to resolve items
	var entries_data = data.get("entries", [])
	if entries_data is Array and item_database:
		for entry_data in entries_data:
			if entry_data is Dictionary and entry_data.has("item_id"):
				var item_id: int = int(entry_data.get("item_id", -1))
				var item: ItemDefinition = item_database.get_item_by_id(item_id)
				if item:
					var entry := LootEntry.new()
					entry.item = item
					entry.weight = float(entry_data.get("weight", 1.0))
					entry.min_quantity = int(entry_data.get("min_quantity", 1))
					entry.max_quantity = int(entry_data.get("max_quantity", 1))
					entry.enabled = _parse_bool(entry_data.get("enabled", true))
					table.entries.append(entry)
	
	if not existing:
		tables.append(table)
	
	result.success = true
	return result


## Helper: Import single table from CSV row
func _import_table_from_csv_row(data: Dictionary, mode: ImportMode, item_database: Resource = null) -> Dictionary:
	# Convert CSV row to same format as JSON dict
	var converted := {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"description": data.get("description", ""),
		"rarity_tier": data.get("rarity_tier", "CUSTOM"),
		"min_drops": int(data.get("min_drops", "1")),
		"max_drops": int(data.get("max_drops", "1")),
		"empty_chance": float(data.get("empty_chance", "0.0")),
		"allow_duplicates": data.get("allow_duplicates", "true") == "true",
		"sub_table_ids": [],
		"entries": []
	}
	
	# Parse sub_table_ids from semicolon-separated string
	var sub_ids_str: String = data.get("sub_table_ids", "")
	if not sub_ids_str.is_empty():
		for sub_id in sub_ids_str.split(";"):
			if not sub_id.is_empty():
				converted.sub_table_ids.append(sub_id)
	
	# Parse entries from semicolon-separated string (item_id:weight:min_qty:max_qty:enabled)
	var entries_str: String = data.get("entries", "")
	if not entries_str.is_empty():
		for entry_str in entries_str.split(";"):
			var parts := entry_str.split(":")
			if parts.size() >= 4:
				converted.entries.append({
					"item_id": int(parts[0]),
					"weight": float(parts[1]),
					"min_quantity": int(parts[2]),
					"max_quantity": int(parts[3]),
					"enabled": parts[4] == "1" if parts.size() > 4 else true
				})
	
	return _import_table_from_dict(converted, mode, item_database)


## Helper: Parse CSV line respecting quoted fields
func _parse_csv_line(line: String) -> Array[String]:
	var result: Array[String] = []
	var current := ""
	var in_quotes := false
	var i := 0
	
	while i < line.length():
		var c := line[i]
		
		if c == "\"":
			if in_quotes and i + 1 < line.length() and line[i + 1] == "\"":
				# Escaped quote
				current += "\""
				i += 1
			else:
				in_quotes = not in_quotes
		elif c == "," and not in_quotes:
			result.append(current)
			current = ""
		else:
			current += c
		
		i += 1
	
	result.append(current)
	return result


## Helper: Parse rarity tier from string
func _parse_rarity_tier(value) -> LootTable.RarityTier:
	var value_str := str(value).to_upper()
	match value_str:
		"COMMON": return LootTable.RarityTier.COMMON
		"UNCOMMON": return LootTable.RarityTier.UNCOMMON
		"RARE": return LootTable.RarityTier.RARE
		"EPIC": return LootTable.RarityTier.EPIC
		"LEGENDARY": return LootTable.RarityTier.LEGENDARY
		_: return LootTable.RarityTier.CUSTOM


## Helper: Parse boolean from various formats
func _parse_bool(value) -> bool:
	if value is bool:
		return value
	var str_value := str(value).to_lower()
	return str_value == "true" or str_value == "1" or str_value == "yes"


# === Helper Methods ===

## Generates a unique ID
func _generate_unique_id(base: String = "loot_table") -> String:
	var counter := 1
	var new_id := base
	
	while has_table(new_id):
		new_id = "%s_%d" % [base, counter]
		counter += 1
	
	return new_id
