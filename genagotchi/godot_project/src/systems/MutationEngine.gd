class_name MutationEngine
extends RefCounted

const GeneCatalogScript: Script = preload("res://src/data/GeneCatalog.gd")

const OXIDATION_MUTATION_THRESHOLD = 50

static func apply_tick(pet: Object) -> bool:
	var mutated: bool = false
	var current_hash: int = _calculate_base_hash(pet.genome)
	var tags = GeneCatalogScript.get("Tags")
	
	if pet.oxidation_level >= OXIDATION_MUTATION_THRESHOLD:
		current_hash |= tags.OXIDO
	
	if (current_hash & tags.OXIDO) != 0:
		if pet.genome["head"]["dom"] == 100:
			pet.genome["head"]["dom"] = 102
			mutated = true
			
	if mutated:
		pet.ecosystem_hash = _calculate_base_hash(pet.genome)
		pet.genome_mutated.emit()
	
	return mutated

static func _calculate_base_hash(genome: Dictionary) -> int:
	var hash_val: int = 0
	hash_val |= GeneCatalogScript.call("get_mask", genome["head"]["dom"])
	hash_val |= GeneCatalogScript.call("get_mask", genome["body"]["dom"])
	hash_val |= GeneCatalogScript.call("get_mask", genome["aura"]["dom"])
	return hash_val
