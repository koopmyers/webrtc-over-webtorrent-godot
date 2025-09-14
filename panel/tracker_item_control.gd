class_name WebRTCoWTTTrackerItemControl extends Control


signal pressed


const MESSAGE_ITEM_CONTROL_SCENE := preload("uid://cfsei3airwx4s")


const STATE_COLOR_DEFAULT := Color.WHITE
const STATE_COLOR := {
	WebSocketPeer.STATE_CONNECTING: Color.AQUAMARINE,
	WebSocketPeer.STATE_OPEN: Color.PALE_GREEN,
	WebSocketPeer.STATE_CLOSING: Color.GOLDENROD,
	WebSocketPeer.STATE_CLOSED: Color.CRIMSON,
}
const STATE_TEXT_DEFAULT := "Unknown"
const STATE_TEXT := {
	WebSocketPeer.STATE_CONNECTING: "Connecting",
	WebSocketPeer.STATE_OPEN: "Open",
	WebSocketPeer.STATE_CLOSING: "Closing",
	WebSocketPeer.STATE_CLOSED: "Closed",
}


@export var tracker_control: WebRTCoWTTTrackerControl
#@export var messages_container: WebRTCoWTTMessagesContainer


@export var client: WebRTCOverWebTorrentClient:
	set(x):
		if client != x:
			if null != client:
				client.tracker_connection_state_changed.disconnect(_on_client_tracker_connection_state_changed)
				client.data_received_from_tracker.disconnect(_on_client_data_received_from_tracker)
				client.data_sent_to_tracker.disconnect(_on_client_data_send_to_tracker)
			
			if null != x:
				x.tracker_connection_state_changed.connect(_on_client_tracker_connection_state_changed)
				x.data_received_from_tracker.connect(_on_client_data_received_from_tracker)
				x.data_sent_to_tracker.connect(_on_client_data_send_to_tracker)
				
		
		client = x


var url: String:
	set(x):
		url = x
		update()

var socket: WebSocketPeer:
	set(x):
		socket = x
		update()


var message_item_controls: Array[WebRTCoWTTMessagesItemControl] = []

@onready var name_label: Label = $%NameLabel
@onready var state_color_rect: ColorRect = $%StateColorRect


func _ready() -> void:
	update()


func _on_button_pressed() -> void:
	if is_instance_valid(tracker_control):
		tracker_control.tracker_item = self
	
	pressed.emit()


func update():
	if is_instance_valid(name_label):
		name_label.text = url
	
	if is_instance_valid(state_color_rect):
		state_color_rect.color = STATE_COLOR_DEFAULT if not socket else STATE_COLOR[socket.get_ready_state()]
		state_color_rect.tooltip_text = STATE_TEXT_DEFAULT if not socket else STATE_TEXT[socket.get_ready_state()]
	
	if is_instance_valid(tracker_control):
		if self == tracker_control.tracker_item:
			tracker_control.update_messages()


func add_message_item_control(data):
	var message_item_control := MESSAGE_ITEM_CONTROL_SCENE.instantiate()
	message_item_controls.append(message_item_control)
	message_item_control.data = data
	return message_item_control


func _on_client_tracker_connection_state_changed(p_socket: WebSocketPeer):
	if p_socket != socket:
		return
	
	update()


func _on_client_data_received_from_tracker(p_socket: WebSocketPeer, data):
	if p_socket != socket:
		return
	
	add_message_item_control(data).received()
	update()


func _on_client_data_send_to_tracker(p_socket: WebSocketPeer, data):
	if p_socket != socket:
		return
	
	add_message_item_control(data).sent()
	update()
