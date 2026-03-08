class_name TickManager
extends RefCounted

const MutationEngineScript: Script = preload("res://src/systems/MutationEngine.gd")

const SECONDS_PER_TICK: int = 3600
const MAX_CATCHUP_TICKS: int = 720
const HUNGER_DECAY: int = -5
const OXIDATION_RATE: int = 2

static func catch_up(pet: Object, current_unix_time: int) -> int:
	var delta_time: int = current_unix_time - pet.last_interaction
	if delta_time < SECONDS_PER_TICK: return 0
		
	var missed_ticks: int = delta_time / SECONDS_PER_TICK
	var ticks_to_process: int = mini(missed_ticks, MAX_CATCHUP_TICKS)
	
	for i in range(ticks_to_process):
		pet.apply_tick_changes(HUNGER_DECAY, OXIDATION_RATE)
		MutationEngineScript.call("apply_tick", pet)

	# Advance only processed ticks; if capped, keep pending debt for next sync.
	pet.last_interaction += (ticks_to_process * SECONDS_PER_TICK)
	pet.status_updated.emit()
	return ticks_to_process
