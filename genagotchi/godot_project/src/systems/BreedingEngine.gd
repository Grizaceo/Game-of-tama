class_name BreedingEngine
extends RefCounted

const MutationEngineScript: Script = preload("res://src/systems/MutationEngine.gd")

const SLOTS: Array[String] = ["head", "body", "aura"]

static func breed(parent_a: Object, parent_b: Object, valid_clicks: int, new_pet_id: String, owner_id: String):
	var child = preload("res://src/core/PetState.gd").new()
	
	parent_a.breed_count += 1
	parent_b.breed_count += 1
	
	child.pet_id = new_pet_id
	child.owner_id = owner_id
	child.generation = maxi(parent_a.generation, parent_b.generation) + 1
	child.breed_count = 0
	
	for i in range(SLOTS.size()):
		var slot: String = SLOTS[i]
		var a_dom: int = parent_a.genome[slot]["dom"]
		var a_rec: int = parent_a.genome[slot]["rec"]
		var b_dom: int = parent_b.genome[slot]["dom"]
		var b_rec: int = parent_b.genome[slot]["rec"]
		
		var punnett: Array = [[a_dom, b_dom], [a_dom, b_rec], [a_rec, b_dom],[a_rec, b_rec]]
		var chaos_index: int = (valid_clicks + i) % 4
		var selected = punnett[chaos_index]
		
		child.genome[slot] = {
			"dom": maxi(selected[0], selected[1]),
			"rec": mini(selected[0], selected[1])
		}
	
	child.ecosystem_hash = MutationEngineScript.call("_calculate_base_hash", child.genome)
	child.hunger = 100
	child.oxidation_level = 0
	return child
