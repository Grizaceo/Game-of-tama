class_name PetState
extends RefCounted

signal status_updated
signal genome_mutated

const MIN_VALUE: int = 0
const MAX_VALUE: int = 100
const SCHEMA_VERSION: int = 1

var schema_version: int = SCHEMA_VERSION
var pet_id: String = ""
var owner_id: String = ""
var generation: int = 1
var breed_count: int = 0

var engine_mutation_v: int = 1
var engine_breeding_v: int = 1
var ecosystem_hash: int = 0

var genome: Dictionary = {
	"head": { "dom": 100, "rec": 100 },
	"body": { "dom": 200, "rec": 200 },
	"aura": { "dom": 300, "rec": 300 }
}

var hunger: int = 100
var oxidation_level: int = 0
var last_interaction: int = 0
var valid_clicks_snapshot: int = 0

func _init() -> void:
	last_interaction = int(Time.get_unix_time_from_system())

func feed(amount: int) -> void:
	hunger = clampi(hunger + amount, MIN_VALUE, MAX_VALUE)
	_update_interaction()

func apply_tick_changes(hunger_delta: int, oxidation_delta: int) -> void:
	hunger = clampi(hunger + hunger_delta, MIN_VALUE, MAX_VALUE)
	oxidation_level = clampi(oxidation_level + oxidation_delta, MIN_VALUE, MAX_VALUE)

func add_oxidation(amount: int) -> void:
	oxidation_level = clampi(oxidation_level + amount, MIN_VALUE, MAX_VALUE)
	status_updated.emit()

func add_valid_clicks(amount: int) -> void:
	valid_clicks_snapshot += amount
	_update_interaction()

func _update_interaction() -> void:
	last_interaction = int(Time.get_unix_time_from_system())
	status_updated.emit()

func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"pet_id": pet_id,
		"owner_id": owner_id,
		"generation": generation,
		"breed_count": breed_count,
		"engine": { "mutation_v": engine_mutation_v, "breeding_v": engine_breeding_v },
		"ecosystem_hash": ecosystem_hash,
		"genome": genome.duplicate(true),
		"status": {
			"hunger": hunger,
			"oxidation_level": oxidation_level,
			"last_interaction": last_interaction
		},
		"telemetry": { "valid_clicks_snapshot": valid_clicks_snapshot }
	}

static func create_from_dict(data: Dictionary):
	var pet = preload("res://src/core/PetState.gd").new()
	pet.schema_version = data.get("schema_version", SCHEMA_VERSION)
	pet.pet_id = data.get("pet_id", "")
	pet.owner_id = data.get("owner_id", "")
	pet.generation = data.get("generation", 1)
	pet.breed_count = data.get("breed_count", 0)
	
	var engine_data: Dictionary = data.get("engine", {})
	pet.engine_mutation_v = engine_data.get("mutation_v", 1)
	pet.engine_breeding_v = engine_data.get("breeding_v", 1)
	
	pet.ecosystem_hash = data.get("ecosystem_hash", 0)
	
	var genome_data: Dictionary = data.get("genome", {})
	if not genome_data.is_empty(): pet.genome = genome_data.duplicate(true)
		
	var status_data: Dictionary = data.get("status", {})
	pet.hunger = clampi(status_data.get("hunger", 100), MIN_VALUE, MAX_VALUE)
	pet.oxidation_level = clampi(status_data.get("oxidation_level", 0), MIN_VALUE, MAX_VALUE)
	pet.last_interaction = status_data.get("last_interaction", int(Time.get_unix_time_from_system()))

	var telemetry_data: Dictionary = data.get("telemetry", {})
	pet.valid_clicks_snapshot = maxi(telemetry_data.get("valid_clicks_snapshot", 0), 0)
	
	return pet
