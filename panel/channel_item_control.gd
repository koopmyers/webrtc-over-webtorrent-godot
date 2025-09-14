class_name WebRTCoWTTChannelItemControl extends Control


signal pressed


const MESSAGE_ITEM_CONTROL_SCENE := preload("uid://cfsei3airwx4s")


const STATE_COLOR_DEFAULT := Color.WHITE
const STATE_COLOR := {
	WebRTCDataChannel.STATE_CONNECTING: Color.AQUAMARINE,
	WebRTCDataChannel.STATE_OPEN: Color.PALE_GREEN,
	WebRTCDataChannel.STATE_CLOSING: Color.GOLDENROD,
	WebRTCDataChannel.STATE_CLOSED: Color.CRIMSON,
}
const STATE_TEXT_DEFAULT := "Unknown"
const STATE_TEXT := {
	WebRTCDataChannel.STATE_CONNECTING: "Connecting",
	WebRTCDataChannel.STATE_OPEN: "Open",
	WebRTCDataChannel.STATE_CLOSING: "Closing",
	WebRTCDataChannel.STATE_CLOSED: "Closed",
}


@export var channel_control: WebRTCoWTTChannelControl



@export var client: WebRTCOverWebTorrentClient:
	set(x):
		if client != x:
			if null != client:
				client.peer_channel_state_changed.disconnect(_on_client_peer_channel_state_changed)
				client.data_received_from_peer.disconnect(_on_client_data_received_from_peer)
				client.data_sent_to_peer.disconnect(_on_client_data_send_to_peer)
			
			if null != x:
				x.peer_channel_state_changed.connect(_on_client_peer_channel_state_changed)
				x.data_received_from_peer.connect(_on_client_data_received_from_peer)
				x.data_sent_to_peer.connect(_on_client_data_send_to_peer)
				
		
		client = x


var peer_id: String:
	set(x):
		peer_id = x
		update()

var peer: WebRTCPeerConnection:
	set(x):
		peer = x
		update()


var channel: WebRTCDataChannel:
	set(x):
		channel = x
		update()


var message_item_controls: Array[WebRTCoWTTMessagesItemControl] = []

@onready var name_label: Label = $%NameLabel
@onready var state_color_rect: ColorRect = $%StateColorRect


func _ready() -> void:
	update()


func _on_button_pressed() -> void:
	if is_instance_valid(channel_control):
		channel_control.channel_item = self
	
	pressed.emit()


func update():
	if is_instance_valid(name_label):
		name_label.text = channel.get_label()
	
	if is_instance_valid(state_color_rect):
		state_color_rect.color = STATE_COLOR_DEFAULT if not channel else STATE_COLOR[channel.get_ready_state()]
		state_color_rect.tooltip_text = STATE_TEXT_DEFAULT if not channel else STATE_TEXT[channel.get_ready_state()]
	
	if is_instance_valid(channel_control):
		if self == channel_control.channel_item:
			channel_control.update_messages()


func add_message_item_control(data):
	var message_item_control := MESSAGE_ITEM_CONTROL_SCENE.instantiate()
	message_item_controls.append(message_item_control)
	message_item_control.data = data
	return message_item_control


func _on_client_peer_channel_state_changed(_peer_id: String, _peer: WebRTCPeerConnection, _channel: WebRTCDataChannel):
	update()


func _on_client_data_received_from_peer(_peer_id_hash: String, _peer: WebRTCPeerConnection, p_channel: WebRTCDataChannel, data):
	if channel != p_channel:
		return
	
	add_message_item_control(data).received()
	update()


func _on_client_data_send_to_peer(_peer_id_hash: String, _peer: WebRTCPeerConnection, p_channel: WebRTCDataChannel, data):
	if channel != p_channel:
		return
	
	add_message_item_control(data).sent()
	update()
