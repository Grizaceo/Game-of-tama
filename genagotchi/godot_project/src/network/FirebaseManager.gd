# Manages Firebase authentication and data synchronization using the GodotFirebase plugin.
extends Node

signal auth_ready(uid: String)
signal auth_failed(reason: String)
signal sync_success(collection: String)
signal sync_failed(collection: String, reason: String)

const FirestoreSerializerScript: Script = preload("res://src/network/Serializer.gd")

var uid: String = ""
var _signals_connected: bool = false

# Keep track of which collection a sync request belongs to
var _sync_context: Dictionary = {}

func _ready() -> void:
	# The Firebase singleton is autoloaded by the plugin. We connect to its signals.
	# We use call_deferred to ensure the singleton is ready.
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	if _signals_connected:
		return

	# Ensure Firebase node is ready
	if not get_tree().root.has_node("Firebase"):
		return

	var firebase_auth = get_node_or_null("/root/Firebase/Auth")
	var firebase_firestore = get_node_or_null("/root/Firebase/Firestore")
	if firebase_auth == null:
		call_deferred("_connect_signals")
		return
	if firebase_firestore == null:
		call_deferred("_connect_signals")
		return

	if firebase_auth.has_signal("login_succeeded"):
		if not firebase_auth.is_connected("login_succeeded", Callable(self, "_on_auth_login_succeeded")):
			firebase_auth.login_succeeded.connect(_on_auth_login_succeeded)
	if firebase_auth.has_signal("signup_succeeded"):
		if not firebase_auth.is_connected("signup_succeeded", Callable(self, "_on_auth_login_succeeded")):
			firebase_auth.signup_succeeded.connect(_on_auth_login_succeeded)
	if firebase_auth.has_signal("login_failed"):
		if not firebase_auth.is_connected("login_failed", Callable(self, "_on_auth_login_failed")):
			firebase_auth.login_failed.connect(_on_auth_login_failed)
	
	if firebase_firestore.has_signal("request_completed"):
		if not firebase_firestore.is_connected("request_completed", Callable(self, "_on_firestore_request_completed")):
			firebase_firestore.request_completed.connect(_on_firestore_request_completed)
	_signals_connected = true


func initialize_anonymous() -> void:
	if not _signals_connected:
		_connect_signals()

	var firebase_auth = get_node_or_null("/root/Firebase/Auth")
	if firebase_auth == null:
		auth_failed.emit("auth_node_missing")
		return
	
	# If already logged in (e.g. from a saved session), just emit the signal
	if firebase_auth.has_method("is_logged_in") and firebase_auth.is_logged_in():
		var auth_payload: Variant = firebase_auth.get("auth")
		var auth_dict: Dictionary = auth_payload if typeof(auth_payload) == TYPE_DICTIONARY else {}

		# The auth object structure might differ across plugin versions.
		if auth_dict.has("localId"):
			self.uid = str(auth_dict.get("localId", ""))
			auth_ready.emit(self.uid)
			return
		if auth_dict.has("localid"):
			self.uid = str(auth_dict.get("localid", ""))
			auth_ready.emit(self.uid)
			return

	if firebase_auth.has_method("login_anonymous"):
		firebase_auth.login_anonymous()
		return

	auth_failed.emit("auth_method_missing")


func sync_pet(pet_dict: Dictionary) -> bool:
	if not pet_dict.has("pet_id"):
		sync_failed.emit("pets", "missing_pet_id")
		return false
	var pet_id: String = str(pet_dict.get("pet_id", "")).strip_edges()
	if pet_id.is_empty():
		sync_failed.emit("pets", "empty_pet_id")
		return false
	return _sync_document("pets", pet_id, pet_dict)


func sync_user(user_dict: Dictionary) -> bool:
	# The user document ID should be the user's UID.
	if not user_dict.has("uid"):
		sync_failed.emit("users", "missing_uid")
		return false
	var user_uid: String = str(user_dict.get("uid", "")).strip_edges()
	if user_uid.is_empty():
		sync_failed.emit("users", "empty_uid_in_data")
		return false
	return _sync_document("users", user_uid, user_dict)


func _sync_document(collection: String, doc_id: String, data: Dictionary) -> bool:
	if doc_id.strip_edges().is_empty():
		sync_failed.emit(collection, "empty_doc_id")
		return false

	var firebase_auth = get_node_or_null("/root/Firebase/Auth")
	if firebase_auth == null:
		sync_failed.emit(collection, "auth_node_missing")
		return false
	if not firebase_auth.has_method("is_logged_in") or not firebase_auth.is_logged_in():
		sync_failed.emit(collection, "not_authenticated")
		return false

	var serialized_data: Dictionary = FirestoreSerializerScript.call("godot_to_firestore", data)
	if serialized_data.is_empty():
		sync_failed.emit(collection, "serialization_failed")
		return false
	
	var firestore = get_node_or_null("/root/Firebase/Firestore")
	if firestore == null:
		sync_failed.emit(collection, "firestore_node_missing")
		return false

	# Legacy plugin API: returns a task and emits request_completed on Firestore.
	if firestore.has_method("update_document"):
		var task = firestore.update_document(collection, doc_id, serialized_data, true)
		if task == null or typeof(task) != TYPE_OBJECT or not is_instance_valid(task):
			sync_failed.emit(collection, "sync_task_creation_failed")
			return false
		_sync_context[task.get_instance_id()] = collection
		return true

	# Current plugin API: write through collection reference and verify readback.
	if firestore.has_method("collection"):
		call_deferred("_sync_document_v2", collection, doc_id, data)
		return true

	sync_failed.emit(collection, "unsupported_firestore_api")
	return false


func _sync_document_v2(collection: String, doc_id: String, data: Dictionary) -> void:
	var firestore = get_node_or_null("/root/Firebase/Firestore")
	if firestore == null:
		sync_failed.emit(collection, "firestore_node_missing")
		return
	if not firestore.has_method("collection"):
		sync_failed.emit(collection, "unsupported_firestore_api")
		return

	var collection_ref = firestore.collection(collection)
	if collection_ref == null:
		sync_failed.emit(collection, "collection_ref_failed")
		return
	if not collection_ref.has_method("set_doc") or not collection_ref.has_method("get_doc"):
		sync_failed.emit(collection, "collection_api_incomplete")
		return

	await collection_ref.set_doc(StringName(doc_id), data)
	var verified = await collection_ref.get_doc(doc_id)
	if verified == null:
		sync_failed.emit(collection, "verify_readback_failed")
		return
	sync_success.emit(collection)


# --- Signal Handlers for GodotFirebase Plugin ---

func _on_auth_login_succeeded(auth_result: Dictionary) -> void:
	# Firebase plugin returns user data in a dictionary.
	# The key for UID is 'localId' in new casing or 'localid' in old.
	var user_id_key = "localId" if auth_result.has("localId") else "localid"
	
	if auth_result.has(user_id_key):
		self.uid = auth_result[user_id_key]
		auth_ready.emit(self.uid)
	else:
		auth_failed.emit("auth_missing_localId")


func _on_auth_login_failed(code: Variant = "unknown", message: Variant = "") -> void:
	auth_failed.emit("auth_error_%s_%s" % [str(code), str(message)])


func _on_firestore_request_completed(task, response_code: int, response_body: Dictionary) -> void:
	var task_id = task.get_instance_id()
	if not _sync_context.has(task_id):
		return # Not a sync task we initiated

	var collection = _sync_context[task_id]
	_sync_context.erase(task_id)
	
	# HTTP status codes in the 200-299 range indicate success.
	if response_code >= 200 and response_code < 300:
		sync_success.emit(collection)
	else:
		var reason := "http_%s" % str(response_code)
		if response_body.has("error") and typeof(response_body.error) == TYPE_DICTIONARY and response_body.error.has("message"):
			reason = response_body.error.message
		sync_failed.emit(collection, reason)
