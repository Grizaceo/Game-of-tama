extends Node

signal event_logged(event_name: String, payload: Dictionary)

const MAX_BUFFERED_EVENTS: int = 250

var _events: Array[Dictionary] = []

func log_event(event_name: String, payload: Dictionary = {}) -> void:
	if event_name.is_empty():
		return

	var entry := {
		"event": event_name,
		"payload": payload.duplicate(true),
		"ts": int(Time.get_unix_time_from_system())
	}
	_events.append(entry)
	if _events.size() > MAX_BUFFERED_EVENTS:
		_events.remove_at(0)
	event_logged.emit(event_name, payload)

func snapshot() -> Array[Dictionary]:
	return _events.duplicate(true)

func clear() -> void:
	_events.clear()
