extends Node

class FirebaseCompatTask:
	extends RefCounted

class FirebaseCompatCollection:
	extends RefCounted

	var _store: Dictionary
	var _collection: String

	func _init(store: Dictionary, collection: String) -> void:
		_store = store
		_collection = collection

	func set_doc(doc_id: StringName, data: Dictionary) -> void:
		var existing: Variant = _store.get(_collection, {})
		var collection_docs: Dictionary = existing if typeof(existing) == TYPE_DICTIONARY else {}
		collection_docs[String(doc_id)] = data.duplicate(true)
		_store[_collection] = collection_docs

	func get_doc(doc_id: String) -> Variant:
		var existing: Variant = _store.get(_collection, {})
		var collection_docs: Dictionary = existing if typeof(existing) == TYPE_DICTIONARY else {}
		return collection_docs.get(doc_id, null)

class FirebaseCompatAuth:
	extends Node

	signal login_succeeded(auth_result: Dictionary)
	signal login_failed(code: int, message: String)
	signal signup_succeeded(auth_result: Dictionary)

	var _logged_in: bool = false
	var auth: Dictionary = {}

	func is_logged_in() -> bool:
		return _logged_in

	func login_anonymous() -> void:
		if _logged_in:
			login_succeeded.emit(auth.duplicate(true))
			return

		var uid: String = "local_%s" % str(Time.get_unix_time_from_system())
		auth = {"localId": uid, "localid": uid}
		_logged_in = true
		call_deferred("_emit_login_succeeded")

	func _emit_login_succeeded() -> void:
		login_succeeded.emit(auth.duplicate(true))

class FirebaseCompatFirestore:
	extends Node

	signal request_completed(task, response_code: int, response_body: Dictionary)

	var _store: Dictionary = {}

	func update_document(collection: String, doc_id: String, data: Dictionary, _create_if_missing: bool):
		var existing: Variant = _store.get(collection, {})
		var collection_docs: Dictionary = existing if typeof(existing) == TYPE_DICTIONARY else {}
		collection_docs[doc_id] = data.duplicate(true)
		_store[collection] = collection_docs

		var task := FirebaseCompatTask.new()
		call_deferred("_emit_update_completed", task)
		return task

	func collection(collection_name: String) -> FirebaseCompatCollection:
		return FirebaseCompatCollection.new(_store, collection_name)

	func _emit_update_completed(task: Variant) -> void:
		request_completed.emit(task, 200, {})

func _ready() -> void:
	if get_node_or_null("Auth") == null:
		var auth := FirebaseCompatAuth.new()
		auth.name = "Auth"
		add_child(auth)

	if get_node_or_null("Firestore") == null:
		var firestore := FirebaseCompatFirestore.new()
		firestore.name = "Firestore"
		add_child(firestore)
