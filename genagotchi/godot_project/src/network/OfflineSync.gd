class_name OfflineSync
extends RefCounted

const SAVE_PATH: String = "user://genagotchi_save_v1.json"

static func save_local(pet_dict: Dictionary, user_dict: Dictionary) -> void:
	var save_data := {
		"pet": pet_dict, "user": user_dict,
		"client_updated_at": int(Time.get_unix_time_from_system())
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

static func resolve_pet_conflict(local_pet: Dictionary, server_pet: Dictionary) -> Dictionary:
	if local_pet.is_empty(): return server_pet
	if server_pet.is_empty(): return local_pet
	
	if server_pet.get("generation", 1) > local_pet.get("generation", 1):
		return server_pet.duplicate(true)

	var loc_int: int = local_pet.get("status", {}).get("last_interaction", 0)
	var srv_int: int = server_pet.get("status", {}).get("last_interaction", 0)
	
	if loc_int >= srv_int:
		# Keep authoritative identity/unknown server fields, then apply mutable local state.
		var merged = server_pet.duplicate(true)
		if local_pet.has("generation"): merged["generation"] = local_pet["generation"]
		if local_pet.has("breed_count"): merged["breed_count"] = local_pet["breed_count"]
		if local_pet.has("ecosystem_hash"): merged["ecosystem_hash"] = local_pet["ecosystem_hash"]
		if local_pet.has("genome"): merged["genome"] = local_pet["genome"].duplicate(true)
		if local_pet.has("status"): merged["status"] = local_pet["status"].duplicate(true)
		if local_pet.has("telemetry"): merged["telemetry"] = local_pet["telemetry"].duplicate(true)
		return merged
	return server_pet.duplicate(true)
