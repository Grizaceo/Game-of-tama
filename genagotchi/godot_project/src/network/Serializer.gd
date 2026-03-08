class_name FirestoreSerializer
extends RefCounted

static func godot_to_firestore(data: Dictionary) -> Dictionary:
	return { "fields": _dict_to_fields(data) }

static func _dict_to_fields(data: Dictionary) -> Dictionary:
	var fields: Dictionary = {}
	for key in data.keys(): fields[key] = _wrap_value(data[key])
	return fields

static func _wrap_value(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_STRING: return { "stringValue": value }
		TYPE_INT: return { "integerValue": str(value) }
		TYPE_FLOAT: return { "doubleValue": value }
		TYPE_BOOL: return { "booleanValue": value }
		TYPE_DICTIONARY: return { "mapValue": { "fields": _dict_to_fields(value) } }
		TYPE_ARRAY: return { "arrayValue": { "values": _array_to_values(value) } }
		_: return { "nullValue": null }

static func _array_to_values(values: Array) -> Array:
	var wrapped: Array = []
	for item in values:
		wrapped.append(_wrap_value(item))
	return wrapped

static func firestore_to_godot(document: Dictionary) -> Dictionary:
	if not document.has("fields"): return {}
	return _fields_to_dict(document["fields"])

static func _fields_to_dict(fields: Dictionary) -> Dictionary:
	var dict: Dictionary = {}
	for key in fields.keys(): dict[key] = _unwrap_value(fields[key])
	return dict

static func _unwrap_value(fs_val: Dictionary) -> Variant:
	if fs_val.has("stringValue"): return fs_val["stringValue"]
	if fs_val.has("integerValue"): return fs_val["integerValue"].to_int()
	if fs_val.has("doubleValue"): return fs_val["doubleValue"]
	if fs_val.has("booleanValue"): return fs_val["booleanValue"]
	if fs_val.has("mapValue"): return _fields_to_dict(fs_val["mapValue"].get("fields", {}))
	if fs_val.has("arrayValue"): return _values_to_array(fs_val["arrayValue"].get("values", []))
	return null

static func _values_to_array(values: Array) -> Array:
	var out: Array = []
	for fs_item in values:
		out.append(_unwrap_value(fs_item))
	return out
