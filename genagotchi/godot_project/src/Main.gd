extends Control

const PetStateScript: Script = preload("res://src/core/PetState.gd")
const TickManagerScript: Script = preload("res://src/core/TickManager.gd")
const OfflineSyncScript: Script = preload("res://src/network/OfflineSync.gd")
const MutationEngineScript: Script = preload("res://src/systems/MutationEngine.gd")
const MainFont: FontFile = preload("res://assets/fonts/KenneyFuture.ttf")
const PET_VARIANT_PATHS: PackedStringArray = [
	"res://assets/sprites/pets/pet_fiu_1.png",
	"res://assets/sprites/pets/pet_fiu_2.png",
	"res://assets/sprites/pets/pet_loica_1.png",
	"res://assets/sprites/pets/pet_condor_1.png",
	"res://assets/sprites/pets/pet_salchicha_1.png",
	"res://assets/sprites/pets/pet_salchicha_2.png",
	"res://assets/sprites/pets/pet_salchicha_3.png",
	"res://assets/sprites/pets/pet_salchicha_4.png",
	"res://assets/sprites/pet_dog.png"
]

const LOCAL_SAVE_PATH: String = "user://genagotchi_save_v1.json"
const FEED_AMOUNT: int = 12
const CLEAN_AMOUNT: int = -10
const PLAY_HUNGER_DELTA: int = -1

enum ConnectionState { OFFLINE, CONNECTING, SYNCING, ONLINE, ERROR }

var _pet: Object
var _user_state: Dictionary = {}
var _firebase_manager: Node = null
var _telemetry: Node = null

var _connection_state: int = ConnectionState.OFFLINE
var _pending_sync: Dictionary = {}
var _last_message: String = "Ready."
var _ticks_applied_on_start: int = 0
var _last_time_refresh_second: int = -1
var _pet_skin_index: int = -1
var _pet_variants: Array[Texture2D] = []

@onready var _pet_name_label: Label = $RootMargin/RootVBox/BodyRow/PetPanel/PetVBox/PetNameLabel
@onready var _pet_placeholder: TextureRect = $RootMargin/RootVBox/BodyRow/PetPanel/PetVBox/PetPlaceholder
@onready var _generation_label: Label = $RootMargin/RootVBox/BodyRow/PetPanel/PetVBox/GenerationLabel
@onready var _connection_label: Label = $RootMargin/RootVBox/BodyRow/PetPanel/PetVBox/ConnectionLabel
@onready var _sync_label: Label = $RootMargin/RootVBox/BodyRow/PetPanel/PetVBox/SyncLabel
@onready var _message_label: Label = $RootMargin/RootVBox/BodyRow/PetPanel/PetVBox/MessageLabel

@onready var _hunger_label: Label = $RootMargin/RootVBox/BodyRow/StatusPanel/StatusVBox/HungerLabel
@onready var _hunger_bar: ProgressBar = $RootMargin/RootVBox/BodyRow/StatusPanel/StatusVBox/HungerBar
@onready var _oxidation_label: Label = $RootMargin/RootVBox/BodyRow/StatusPanel/StatusVBox/OxidationLabel
@onready var _oxidation_bar: ProgressBar = $RootMargin/RootVBox/BodyRow/StatusPanel/StatusVBox/OxidationBar
@onready var _clicks_label: Label = $RootMargin/RootVBox/BodyRow/StatusPanel/StatusVBox/ClicksLabel
@onready var _last_interaction_label: Label = $RootMargin/RootVBox/BodyRow/StatusPanel/StatusVBox/LastInteractionLabel
@onready var _ticks_label: Label = $RootMargin/RootVBox/BodyRow/StatusPanel/StatusVBox/TicksLabel

@onready var _feed_button: Button = $RootMargin/RootVBox/ActionsPanel/ActionsVBox/ButtonsRow/FeedButton
@onready var _clean_button: Button = $RootMargin/RootVBox/ActionsPanel/ActionsVBox/ButtonsRow/CleanButton
@onready var _play_button: Button = $RootMargin/RootVBox/ActionsPanel/ActionsVBox/ButtonsRow/PlayButton
@onready var _sync_button: Button = $RootMargin/RootVBox/ActionsPanel/ActionsVBox/SyncButton
@onready var _title_label: Label = $RootMargin/RootVBox/TitleLabel
@onready var _status_title: Label = $RootMargin/RootVBox/BodyRow/StatusPanel/StatusVBox/StatusTitle
@onready var _actions_title: Label = $RootMargin/RootVBox/ActionsPanel/ActionsVBox/ActionsTitle

@onready var _bgm_player: AudioStreamPlayer = $BgmPlayer
@onready var _feed_sfx: AudioStreamPlayer = $FeedSfx
@onready var _clean_sfx: AudioStreamPlayer = $CleanSfx
@onready var _play_sfx: AudioStreamPlayer = $PlaySfx
@onready var _sync_sfx: AudioStreamPlayer = $SyncSfx

func _ready() -> void:
	_apply_visual_theme()
	_configure_audio()
	_wire_buttons()
	_telemetry = get_node_or_null("/root/Telemetry")
	_firebase_manager = get_node_or_null("/root/FirebaseManager")
	_load_pet_variants()

	_load_local_state()
	_apply_initial_catch_up()
	_refresh_ui()
	_set_message("MVP listo en modo local.")
	_save_local_state()

	_setup_online_sync()
	set_process(true)

func _process(_delta: float) -> void:
	var now: int = int(Time.get_unix_time_from_system())
	if now != _last_time_refresh_second:
		_last_time_refresh_second = now
		_refresh_time_only()

func _wire_buttons() -> void:
	_feed_button.pressed.connect(_on_feed_pressed)
	_clean_button.pressed.connect(_on_clean_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_sync_button.pressed.connect(_on_sync_now_pressed)

func _load_local_state() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var snapshot: Dictionary = _read_local_snapshot()

	if snapshot.has("pet") and typeof(snapshot["pet"]) == TYPE_DICTIONARY:
		_pet = PetStateScript.call("create_from_dict", snapshot["pet"])
	else:
		_pet = PetStateScript.new()
		_pet.pet_id = "local_pet_001"
		_pet.owner_id = "local"

	if _pet.pet_id.strip_edges().is_empty():
		_pet.pet_id = "local_pet_001"
	if _pet.owner_id.strip_edges().is_empty():
		_pet.owner_id = "local"

	_user_state = _normalize_user_state(snapshot.get("user", {}), now)
	if str(_user_state.get("active_pet_id", "")).is_empty():
		_user_state["active_pet_id"] = _pet.pet_id
	_ensure_pet_skin()

	_pet.status_updated.connect(_on_pet_status_updated)
	_pet.genome_mutated.connect(_on_pet_genome_mutated)

func _read_local_snapshot() -> Dictionary:
	var file := FileAccess.open(LOCAL_SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _normalize_user_state(state: Variant, now: int) -> Dictionary:
	var in_state: Dictionary = state if typeof(state) == TYPE_DICTIONARY else {}
	return {
		"schema_version": 1,
		"uid": str(in_state.get("uid", "")),
		"created_at": int(in_state.get("created_at", now)),
		"valid_clicks_total": maxi(int(in_state.get("valid_clicks_total", 0)), 0),
		"active_pet_id": str(in_state.get("active_pet_id", "")),
		"pet_skin_index": int(in_state.get("pet_skin_index", -1)),
		"settings": in_state.get("settings", {"sound": true})
	}

func _apply_initial_catch_up() -> void:
	_ticks_applied_on_start = TickManagerScript.call("catch_up", _pet, int(Time.get_unix_time_from_system()))
	if _ticks_applied_on_start > 0:
		_set_message("Se aplicaron %d ticks offline." % _ticks_applied_on_start)
		_log_event("ticks_applied", {"count": _ticks_applied_on_start})

func _setup_online_sync() -> void:
	if _firebase_manager == null:
		_set_connection_state(ConnectionState.OFFLINE, "Sin FirebaseManager, modo local.")
		return

	if not _firebase_manager.auth_ready.is_connected(_on_auth_ready):
		_firebase_manager.auth_ready.connect(_on_auth_ready)
	if not _firebase_manager.auth_failed.is_connected(_on_auth_failed):
		_firebase_manager.auth_failed.connect(_on_auth_failed)
	if not _firebase_manager.sync_success.is_connected(_on_sync_success):
		_firebase_manager.sync_success.connect(_on_sync_success)
	if not _firebase_manager.sync_failed.is_connected(_on_sync_failed):
		_firebase_manager.sync_failed.connect(_on_sync_failed)

	_set_connection_state(ConnectionState.CONNECTING, "Conectando Firebase...")
	_firebase_manager.initialize_anonymous()

func _on_auth_ready(uid: String) -> void:
	_user_state["uid"] = uid
	if _pet.owner_id == "local" or _pet.owner_id.is_empty():
		_pet.owner_id = uid
	if _pet.pet_id.begins_with("local_pet"):
		_pet.pet_id = "pet_%s" % uid.substr(0, 8)
	_user_state["active_pet_id"] = _pet.pet_id
	_ensure_pet_skin()
	_set_connection_state(ConnectionState.SYNCING, "Autenticado. Sincronizando...")
	_attempt_sync()

func _on_auth_failed(reason: String) -> void:
	_set_connection_state(ConnectionState.OFFLINE, "Offline (%s)." % reason)
	_set_message("No se pudo autenticar. Sigues en modo local.")
	_log_event("auth_failed", {"reason": reason})

func _attempt_sync() -> void:
	if _firebase_manager == null:
		return
	if str(_user_state.get("uid", "")).is_empty():
		return

	var user_started: bool = _firebase_manager.sync_user(_build_user_dict())
	var pet_started: bool = _firebase_manager.sync_pet(_pet.to_dict())

	_pending_sync.clear()
	if user_started:
		_pending_sync["users"] = true
	if pet_started:
		_pending_sync["pets"] = true

	if not _pending_sync.is_empty():
		_set_connection_state(ConnectionState.SYNCING, "Subiendo progreso...")

func _build_user_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"uid": str(_user_state.get("uid", "")),
		"created_at": int(_user_state.get("created_at", int(Time.get_unix_time_from_system()))),
		"valid_clicks_total": int(_user_state.get("valid_clicks_total", 0)),
		"active_pet_id": _pet.pet_id,
		"pet_skin_index": _pet_skin_index,
		"settings": _user_state.get("settings", {"sound": true})
	}

func _on_sync_success(collection: String) -> void:
	if _pending_sync.has(collection):
		_pending_sync.erase(collection)
	if _pending_sync.is_empty():
		_set_connection_state(ConnectionState.ONLINE, "Sincronizado.")
	_save_local_state()

func _on_sync_failed(collection: String, reason: String) -> void:
	if _pending_sync.has(collection):
		_pending_sync.erase(collection)
	_set_connection_state(ConnectionState.ERROR, "Error en %s: %s" % [collection, reason])

func _on_feed_pressed() -> void:
	_play_sound("feed")
	_pet.feed(FEED_AMOUNT)
	_register_action("action_feed", {"amount": FEED_AMOUNT})

func _on_clean_pressed() -> void:
	_play_sound("clean")
	_pet.add_oxidation(CLEAN_AMOUNT)
	_register_action("action_clean", {"amount": CLEAN_AMOUNT})

func _on_play_pressed() -> void:
	_play_sound("play")
	_pet.apply_tick_changes(PLAY_HUNGER_DELTA, 0)
	_pet.status_updated.emit()
	_register_action("action_play", {"hunger_delta": PLAY_HUNGER_DELTA})

func _on_sync_now_pressed() -> void:
	_play_sound("sync")
	_set_message("Intentando sync manual...")
	_attempt_sync()

func _register_action(event_name: String, payload: Dictionary) -> void:
	_user_state["valid_clicks_total"] = int(_user_state.get("valid_clicks_total", 0)) + 1
	_pet.add_valid_clicks(1)
	_set_message(_action_message(event_name))
	_log_event(event_name, payload)
	_save_local_state()
	_refresh_ui()
	_attempt_sync()

func _action_message(event_name: String) -> String:
	match event_name:
		"action_feed": return "Comida dada. La mascota está más llena."
		"action_clean": return "Limpieza aplicada. Oxidación reducida."
		"action_play": return "Sesión de juego completada."
		_: return "Acción aplicada."

func _on_pet_status_updated() -> void:
	_refresh_ui()

func _on_pet_genome_mutated() -> void:
	_set_message("Mutación detectada en tu mascota.")
	_log_event("genome_mutated", {"pet_id": _pet.pet_id})
	_refresh_ui()

func _save_local_state() -> void:
	_user_state["active_pet_id"] = _pet.pet_id
	_user_state["pet_skin_index"] = _pet_skin_index
	OfflineSyncScript.call("save_local", _pet.to_dict(), _build_user_dict())

func _refresh_ui() -> void:
	_pet_name_label.text = "Mascota: %s" % _pet.pet_id
	_generation_label.text = "Generación %d | Owner %s" % [_pet.generation, _pet.owner_id]

	_hunger_label.text = "Hunger: %d/100" % _pet.hunger
	_hunger_bar.value = _pet.hunger
	_oxidation_label.text = "Oxidación: %d/100" % _pet.oxidation_level
	_oxidation_bar.value = _pet.oxidation_level

	var mutation_threshold: int = int(MutationEngineScript.get("OXIDATION_MUTATION_THRESHOLD"))
	if _pet.oxidation_level >= mutation_threshold:
		_message_label.text = "Alerta: riesgo de mutación alto. " + _last_message
	else:
		_message_label.text = _last_message

	_clicks_label.text = "Clicks válidos: %d (snapshot pet: %d)" % [int(_user_state.get("valid_clicks_total", 0)), _pet.valid_clicks_snapshot]
	_ticks_label.text = "Ticks aplicados al iniciar: %d" % _ticks_applied_on_start
	_refresh_time_only()

func _refresh_time_only() -> void:
	_last_interaction_label.text = "Última interacción: %s" % _format_elapsed(_pet.last_interaction)

func _format_elapsed(timestamp: int) -> String:
	var now: int = int(Time.get_unix_time_from_system())
	var delta: int = maxi(now - timestamp, 0)
	if delta < 60:
		return "%ds" % delta
	if delta < 3600:
		return "%dm" % int(delta / 60)
	if delta < 86400:
		return "%dh" % int(delta / 3600)
	return "%dd" % int(delta / 86400)

func _set_message(text: String) -> void:
	_last_message = text
	_message_label.text = text

func _set_connection_state(state: int, detail: String) -> void:
	_connection_state = state
	match state:
		ConnectionState.OFFLINE:
			_connection_label.text = "Estado: OFFLINE"
			_connection_label.modulate = Color(0.95, 0.68, 0.24, 1.0)
		ConnectionState.CONNECTING:
			_connection_label.text = "Estado: CONNECTING"
			_connection_label.modulate = Color(0.55, 0.7, 0.98, 1.0)
		ConnectionState.SYNCING:
			_connection_label.text = "Estado: SYNCING"
			_connection_label.modulate = Color(0.29, 0.78, 0.82, 1.0)
		ConnectionState.ONLINE:
			_connection_label.text = "Estado: ONLINE"
			_connection_label.modulate = Color(0.35, 0.85, 0.45, 1.0)
		ConnectionState.ERROR:
			_connection_label.text = "Estado: SYNC ERROR"
			_connection_label.modulate = Color(0.93, 0.36, 0.36, 1.0)
	_sync_label.text = detail

func _log_event(event_name: String, payload: Dictionary = {}) -> void:
	if _telemetry != null and _telemetry.has_method("log_event"):
		_telemetry.log_event(event_name, payload)

func _ensure_pet_skin() -> void:
	if _pet_variants.is_empty():
		return

	var stored_index: int = int(_user_state.get("pet_skin_index", -1))
	if stored_index >= 0 and stored_index < _pet_variants.size():
		_pet_skin_index = stored_index
	else:
		_pet_skin_index = _stable_pet_skin_for_id(_pet.pet_id)
	_user_state["pet_skin_index"] = _pet_skin_index
	_apply_pet_skin()

func _stable_pet_skin_for_id(pet_id: String) -> int:
	if _pet_variants.is_empty():
		return -1
	var hash_value: int = abs(int(pet_id.hash()))
	return hash_value % _pet_variants.size()

func _apply_pet_skin() -> void:
	if _pet_placeholder == null:
		return
	if _pet_skin_index < 0 or _pet_skin_index >= _pet_variants.size():
		return
	_pet_placeholder.texture = _pet_variants[_pet_skin_index]

func _load_pet_variants() -> void:
	_pet_variants.clear()
	for path in PET_VARIANT_PATHS:
		var texture: Texture2D = load(path) as Texture2D
		if texture != null:
			_pet_variants.append(texture)

func _apply_visual_theme() -> void:
	for label in [_title_label, _status_title, _actions_title]:
		if label != null:
			label.add_theme_font_override("font", MainFont)

func _configure_audio() -> void:
	if _bgm_player != null:
		var bgm_stream := _bgm_player.stream as AudioStreamOggVorbis
		if bgm_stream != null:
			bgm_stream.loop = true
		if not _bgm_player.playing:
			_bgm_player.play()

func _play_sound(sound_key: String) -> void:
	match sound_key:
		"feed":
			if _feed_sfx != null: _feed_sfx.play()
		"clean":
			if _clean_sfx != null: _clean_sfx.play()
		"play":
			if _play_sfx != null: _play_sfx.play()
		"sync":
			if _sync_sfx != null: _sync_sfx.play()
