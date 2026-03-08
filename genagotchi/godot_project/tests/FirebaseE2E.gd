extends SceneTree

const FirebaseManagerScript: Script = preload("res://src/network/FirebaseManager.gd")
const PetStateScript: Script = preload("res://src/core/PetState.gd")

const AUTH_TIMEOUT_SEC := 60.0
const SYNC_TIMEOUT_SEC := 60.0

var _auth_done := false
var _auth_ok := false
var _user_sync_done := false
var _user_sync_ok := false
var _pet_sync_done := false
var _pet_sync_ok := false
var _last_reason := ""

func _initialize() -> void:
	call_deferred("_run_async")

func _run_async() -> void:
	await _run()

func _run() -> void:
	if not root.has_node("Firebase"):
		push_error("Firebase plugin autoload missing at /root/Firebase")
		print("RESULT=PLUGIN_MISSING")
		quit(2)
		return

	var manager: Object = FirebaseManagerScript.new()
	root.add_child(manager)
	await process_frame

	manager.auth_ready.connect(_on_auth_ready)
	manager.auth_failed.connect(_on_auth_failed)
	manager.sync_success.connect(_on_sync_success)
	manager.sync_failed.connect(_on_sync_failed)
	manager._connect_signals()

	manager.initialize_anonymous()

	if not await _wait_until(func() -> bool: return _auth_done, AUTH_TIMEOUT_SEC):
		push_error("Auth timeout")
		print("RESULT=AUTH_TIMEOUT")
		quit(4)
		return
	if not _auth_ok:
		push_error("Auth failed: %s" % _last_reason)
		print("RESULT=AUTH_FAILED reason=%s" % _last_reason)
		quit(5)
		return

	var pet_id: String = "e2e_pet_%s" % manager.uid.substr(0, 8)
	var user_dict: Dictionary = _build_user_dict(manager.uid, pet_id)
	var user_sync_started: bool = manager.sync_user(user_dict)
	if not user_sync_started:
		push_error("sync_user failed to start: %s" % _last_reason)
		print("RESULT=USER_SYNC_START_ERROR reason=%s" % _last_reason)
		quit(6)
		return

	if not await _wait_until(func() -> bool: return _user_sync_done, SYNC_TIMEOUT_SEC):
		push_error("User sync timeout")
		print("RESULT=USER_SYNC_TIMEOUT")
		quit(7)
		return
	if not _user_sync_ok:
		push_error("User sync failed: %s" % _last_reason)
		print("RESULT=USER_SYNC_FAILED reason=%s" % _last_reason)
		quit(8)
		return

	var pet_dict: Dictionary = _build_pet_dict(manager.uid, pet_id)
	var pet_sync_started: bool = manager.sync_pet(pet_dict)
	if not pet_sync_started:
		push_error("sync_pet failed to start: %s" % _last_reason)
		print("RESULT=PET_SYNC_START_ERROR reason=%s" % _last_reason)
		quit(9)
		return

	if not await _wait_until(func() -> bool: return _pet_sync_done, SYNC_TIMEOUT_SEC):
		push_error("Pet sync timeout")
		print("RESULT=PET_SYNC_TIMEOUT")
		quit(10)
		return
	if not _pet_sync_ok:
		push_error("Pet sync failed: %s" % _last_reason)
		print("RESULT=PET_SYNC_FAILED reason=%s" % _last_reason)
		quit(11)
		return

	print("RESULT=OK uid=%s pet_id=%s" % [manager.uid, pet_id])
	quit(0)

func _build_pet_dict(uid: String, pet_id: String) -> Dictionary:
	var pet: Object = PetStateScript.new()
	pet.pet_id = pet_id
	pet.owner_id = uid
	return pet.to_dict()

func _build_user_dict(uid: String, pet_id: String) -> Dictionary:
	return {
		"schema_version": 1,
		"uid": uid,
		"created_at": int(Time.get_unix_time_from_system()),
		"valid_clicks_total": 0,
		"active_pet_id": pet_id,
		"settings": { "sound": true }
	}

func _wait_until(predicate: Callable, timeout_sec: float) -> bool:
	var deadline_msec: int = Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline_msec:
		if bool(predicate.call()):
			return true
		await create_timer(0.1).timeout
	return false

func _on_auth_ready(_uid: String) -> void:
	_auth_done = true
	_auth_ok = true

func _on_auth_failed(reason: String) -> void:
	_last_reason = reason
	_auth_done = true
	_auth_ok = false

func _on_sync_success(collection: String) -> void:
	if collection == "users":
		_user_sync_done = true
		_user_sync_ok = true
	elif collection == "pets":
		_pet_sync_done = true
		_pet_sync_ok = true

func _on_sync_failed(collection: String, reason: String) -> void:
	_last_reason = "%s:%s" % [collection, reason]
	if collection == "users":
		_user_sync_done = true
		_user_sync_ok = false
	elif collection == "pets":
		_pet_sync_done = true
		_pet_sync_ok = false
