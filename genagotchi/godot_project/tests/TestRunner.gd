extends SceneTree

const PetStateScript: Script = preload("res://src/core/PetState.gd")
const TickManagerScript: Script = preload("res://src/core/TickManager.gd")
const FirestoreSerializerScript: Script = preload("res://src/network/Serializer.gd")
const OfflineSyncScript: Script = preload("res://src/network/OfflineSync.gd")
const FirebaseManagerScript: Script = preload("res://src/network/FirebaseManager.gd")

class FakeAuth:
	extends Node

	signal login_succeeded(auth_result: Dictionary)
	signal login_failed(code: int, message: String)

	var _logged_in: bool = false
	var auth: Dictionary = {}

	func set_state(logged_in: bool, auth_payload: Dictionary = {}) -> void:
		_logged_in = logged_in
		auth = auth_payload.duplicate(true)

	func is_logged_in() -> bool:
		return _logged_in

	func login_anonymous() -> void:
		pass

class FakeFirestore:
	extends Node

	signal request_completed(task, response_code: int, response_body: Dictionary)

	var task_to_return: Variant = null

	func update_document(_collection: String, _doc_id: String, _data: Dictionary, _create_if_missing: bool):
		return task_to_return

class SyncFailureRecorder:
	extends RefCounted

	var collection: String = ""
	var reason: String = ""

	func on_sync_failed(sync_collection: String, sync_reason: String) -> void:
		collection = sync_collection
		reason = sync_reason

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run_and_exit")

func _run_and_exit() -> void:
	_run_tests()
	print("PASSED=%d FAILED=%d" % [_passed, _failed])
	quit(_failed)

func _run_tests() -> void:
	test_petstate_roundtrip_preserves_valid_clicks_snapshot()
	test_tickmanager_catchup_advances_without_time_corruption()
	test_firestore_serializer_array_roundtrip()
	test_offline_sync_preserves_server_identity()
	test_firebase_manager_validates_pet_id()
	test_firebase_manager_requires_authentication()
	test_firebase_manager_handles_task_creation_failure()
	test_firebase_manager_starts_sync_and_tracks_context()

func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error(message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func test_petstate_roundtrip_preserves_valid_clicks_snapshot() -> void:
	var pet: Object = PetStateScript.new()
	pet.valid_clicks_snapshot = 42
	pet.hunger = 77
	var loaded: Object = PetStateScript.call("create_from_dict", pet.to_dict())
	_assert_eq(loaded.get("valid_clicks_snapshot"), 42, "valid_clicks_snapshot must survive roundtrip")
	_assert_eq(loaded.get("hunger"), 77, "status fields should survive roundtrip")

func test_tickmanager_catchup_advances_without_time_corruption() -> void:
	var pet: Object = PetStateScript.new()
	var now: int = 10_000
	var seconds_per_tick: int = 3600
	pet.last_interaction = now - (3 * seconds_per_tick)
	var before: int = pet.last_interaction
	var processed: int = TickManagerScript.call("catch_up", pet, now)
	_assert_eq(processed, 3, "catch_up should process expected ticks")
	_assert_eq(pet.last_interaction, before + (3 * seconds_per_tick), "last_interaction should advance by processed ticks only")
	_assert_true(pet.last_interaction <= now, "last_interaction must never move into the future")

func test_firestore_serializer_array_roundtrip() -> void:
	var payload := {
		"name": "test",
		"values": [1, "x", {"flag": true}, [2, 3], null]
	}
	var fs_doc: Dictionary = FirestoreSerializerScript.call("godot_to_firestore", payload)
	var restored: Dictionary = FirestoreSerializerScript.call("firestore_to_godot", fs_doc)
	_assert_eq(restored.get("name", ""), "test", "string should roundtrip")
	var arr: Array = restored.get("values", [])
	_assert_eq(arr.size(), 5, "array size should roundtrip")
	_assert_eq(arr[0], 1, "array int should roundtrip")
	_assert_eq(arr[1], "x", "array string should roundtrip")
	_assert_eq(arr[2]["flag"], true, "array map should roundtrip")
	_assert_eq(arr[3][1], 3, "nested array should roundtrip")
	_assert_eq(arr[4], null, "null value should roundtrip")

func test_offline_sync_preserves_server_identity() -> void:
	var local_pet := {
		"pet_id": "hacked_local",
		"owner_id": "attacker",
		"generation": 1,
		"breed_count": 3,
		"ecosystem_hash": 55,
		"genome": {"head": {"dom": 102, "rec": 100}, "body": {"dom": 200, "rec": 200}, "aura": {"dom": 300, "rec": 300}},
		"status": {"hunger": 90, "oxidation_level": 8, "last_interaction": 2000},
		"telemetry": {"valid_clicks_snapshot": 88}
	}
	var server_pet := {
		"pet_id": "pet_001",
		"owner_id": "owner_001",
		"generation": 1,
		"status": {"hunger": 20, "oxidation_level": 60, "last_interaction": 1000},
		"extra_server_field": {"do_not_drop": true}
	}
	var merged: Dictionary = OfflineSyncScript.call("resolve_pet_conflict", local_pet, server_pet)
	_assert_eq(merged["pet_id"], "pet_001", "pet_id must remain server authoritative")
	_assert_eq(merged["owner_id"], "owner_001", "owner_id must remain server authoritative")
	_assert_eq(merged["status"]["hunger"], 90, "newer local status should win when local is newer")
	_assert_eq(merged["extra_server_field"]["do_not_drop"], true, "server-only fields must be preserved")

func _build_firebase_fixture(logged_in: bool, firestore_task: Variant) -> Dictionary:
	var existing_firebase: Node = root.get_node_or_null("Firebase")
	if existing_firebase != null and is_instance_valid(existing_firebase):
		root.remove_child(existing_firebase)
		existing_firebase.free()

	var firebase_root := Node.new()
	firebase_root.name = "Firebase"
	root.add_child(firebase_root)

	var auth := FakeAuth.new()
	auth.name = "Auth"
	auth.set_state(logged_in, {"localid": "uid_fixture"})
	firebase_root.add_child(auth)

	var firestore := FakeFirestore.new()
	firestore.name = "Firestore"
	firestore.task_to_return = firestore_task
	firebase_root.add_child(firestore)

	var manager: Object = FirebaseManagerScript.new()
	root.add_child(manager)

	return {
		"manager": manager,
		"firebase_root": firebase_root,
		"firestore": firestore
	}

func _teardown_firebase_fixture(fixture: Dictionary) -> void:
	var manager: Object = fixture.get("manager", null)
	if manager != null and is_instance_valid(manager):
		if manager.get_parent() != null:
			manager.get_parent().remove_child(manager)
		manager.free()

	var firebase_root: Node = fixture.get("firebase_root", null)
	if firebase_root != null and is_instance_valid(firebase_root):
		if firebase_root.get_parent() != null:
			firebase_root.get_parent().remove_child(firebase_root)
		firebase_root.free()

func test_firebase_manager_validates_pet_id() -> void:
	var manager: Object = FirebaseManagerScript.new()
	_assert_eq(manager.sync_pet({}), false, "sync_pet must fail when pet_id is missing")
	_assert_eq(manager.sync_pet({"pet_id": "   "}), false, "sync_pet must fail when pet_id is empty")

func test_firebase_manager_requires_authentication() -> void:
	var fixture: Dictionary = _build_firebase_fixture(false, RefCounted.new())
	var manager: Object = fixture["manager"]
	var recorder := SyncFailureRecorder.new()
	manager.sync_failed.connect(recorder.on_sync_failed)

	var started: bool = manager.sync_user({"uid": "uid_fixture"})
	_assert_eq(started, false, "sync_user must not start when auth is missing")
	_assert_eq(recorder.collection, "users", "failure should identify users collection")
	_assert_eq(recorder.reason, "not_authenticated", "failure reason should be not_authenticated")
	_teardown_firebase_fixture(fixture)

func test_firebase_manager_handles_task_creation_failure() -> void:
	var fixture: Dictionary = _build_firebase_fixture(true, null)
	var manager: Object = fixture["manager"]
	var recorder := SyncFailureRecorder.new()
	manager.sync_failed.connect(recorder.on_sync_failed)

	var started: bool = manager.sync_pet({"pet_id": "pet_fixture"})
	_assert_eq(started, false, "sync_pet must fail if Firestore does not return a task")
	_assert_eq(recorder.collection, "pets", "failure should identify pets collection")
	_assert_eq(recorder.reason, "sync_task_creation_failed", "failure reason should explain task creation failure")
	_teardown_firebase_fixture(fixture)

func test_firebase_manager_starts_sync_and_tracks_context() -> void:
	var task := RefCounted.new()
	var fixture: Dictionary = _build_firebase_fixture(true, task)
	var manager: Object = fixture["manager"]

	var started: bool = manager.sync_pet({"pet_id": "pet_fixture"})
	_assert_eq(started, true, "sync_pet should start when auth and task are valid")
	_assert_true(manager._sync_context.has(task.get_instance_id()), "sync context should track pending Firestore task")
	_teardown_firebase_fixture(fixture)
