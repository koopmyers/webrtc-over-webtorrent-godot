class_name WebRTCoWTTPeerItemControl extends Control


signal pressed
signal updated

const MESSAGE_ITEM_CONTROL_SCENE := preload("uid://cfsei3airwx4s")
const CHANNEL_ITEM_CONTROL_SCENE := preload("uid://dc3ssinymllca")

const STATE_COLOR_DEFAULT := Color.WHITE
const STATE_TEXT_DEFAULT := "Unknown"

const CONNECTION_STATE_COLOR := {
	WebRTCPeerConnection.STATE_NEW: Color.BEIGE,
	WebRTCPeerConnection.STATE_CONNECTING: Color.AQUAMARINE,
	WebRTCPeerConnection.STATE_CONNECTED: Color.PALE_GREEN,
	WebRTCPeerConnection.STATE_DISCONNECTED: Color.CRIMSON,
	WebRTCPeerConnection.STATE_FAILED: Color.GOLDENROD,
	WebRTCPeerConnection.STATE_CLOSED: Color.CRIMSON,
}
const CONNECTION_STATE_TEXT := {
	WebRTCPeerConnection.STATE_NEW: "New",
	WebRTCPeerConnection.STATE_CONNECTING: "Connecting",
	WebRTCPeerConnection.STATE_CONNECTED: "Connected",
	WebRTCPeerConnection.STATE_DISCONNECTED: 'Disconnected',
	WebRTCPeerConnection.STATE_FAILED: "Failed",
	WebRTCPeerConnection.STATE_CLOSED: "Closed",
}


const GATHERING_STATE_COLOR := {
	WebRTCPeerConnection.GATHERING_STATE_NEW: Color.BEIGE,
	WebRTCPeerConnection.GATHERING_STATE_GATHERING: Color.AQUAMARINE,
	WebRTCPeerConnection.GATHERING_STATE_COMPLETE: Color.PALE_GREEN,
}
const GATHERING_STATE_TEXT := {
	WebRTCPeerConnection.GATHERING_STATE_NEW: "New",
	WebRTCPeerConnection.GATHERING_STATE_GATHERING: "Gathering",
	WebRTCPeerConnection.GATHERING_STATE_COMPLETE: "Complete",
}


const SIGNALING_STATE_COLOR := {
	WebRTCPeerConnection.SIGNALING_STATE_STABLE: Color.PALE_GREEN,
	WebRTCPeerConnection.SIGNALING_STATE_HAVE_LOCAL_OFFER: Color.AQUAMARINE, 
	WebRTCPeerConnection.SIGNALING_STATE_HAVE_REMOTE_OFFER: Color.AQUAMARINE,
	WebRTCPeerConnection.SIGNALING_STATE_HAVE_LOCAL_PRANSWER: Color.AQUAMARINE,
	WebRTCPeerConnection.SIGNALING_STATE_HAVE_REMOTE_PRANSWER: Color.AQUAMARINE,
	WebRTCPeerConnection.SIGNALING_STATE_CLOSED: Color.CRIMSON,
}
const SIGNALING_STATE_TEXT := {
	WebRTCPeerConnection.SIGNALING_STATE_STABLE: "Stable",
	WebRTCPeerConnection.SIGNALING_STATE_HAVE_LOCAL_OFFER: "Have local offer", 
	WebRTCPeerConnection.SIGNALING_STATE_HAVE_REMOTE_OFFER: "Have remote offer",
	WebRTCPeerConnection.SIGNALING_STATE_HAVE_LOCAL_PRANSWER: "Have local answer",
	WebRTCPeerConnection.SIGNALING_STATE_HAVE_REMOTE_PRANSWER: "Have remote answer",
	WebRTCPeerConnection.SIGNALING_STATE_CLOSED: "Closed",
}







@export var peer_control: WebRTCoWTTPeerControl
@export var channel_control: WebRTCoWTTChannelControl

@export var client: WebRTCOverWebTorrentClient:
	set(x):
		if client != x:
			if null != client:
				client.peer_connection_state_changed.disconnect(_on_client_peer_connection_state_changed)
				
				client.peer_channel_initiated.disconnect(_on_client_peer_channel_initiated)
			
			if null != x:
				x.peer_connection_state_changed.connect(_on_client_peer_connection_state_changed)
				
				x.peer_channel_initiated.connect(_on_client_peer_channel_initiated)
		
		
		client = x


var peer_id: String:
	set(x):
		peer_id = x
		update()

var peer: WebRTCPeerConnection:
	set(x):
		peer = x
		update()


var message_item_controls: Array[WebRTCoWTTMessagesItemControl] = []
var channel_item_controls: Array[WebRTCoWTTChannelItemControl] = []

@onready var name_label: Label = $%NameLabel
@onready var state_color_rect: ColorRect = $%StateColorRect


func _ready() -> void:
	update()


func get_connection_state_color() -> Color:
	return STATE_COLOR_DEFAULT if not peer else CONNECTION_STATE_COLOR[peer.get_connection_state()]

func get_connection_state_text() -> String:
	return STATE_TEXT_DEFAULT if not peer else CONNECTION_STATE_TEXT[peer.get_connection_state()]


func get_gathering_state_color() -> Color:
	return STATE_COLOR_DEFAULT if not peer else GATHERING_STATE_COLOR[peer.get_connection_state()]

func get_gathering_state_text() -> String:
	return STATE_TEXT_DEFAULT if not peer else GATHERING_STATE_TEXT[peer.get_connection_state()]
	

func get_signaling_state_color() -> Color:
	return STATE_COLOR_DEFAULT if not peer else SIGNALING_STATE_COLOR[peer.get_connection_state()]

func get_signaling_state_text() -> String:
	return STATE_TEXT_DEFAULT if not peer else SIGNALING_STATE_TEXT[peer.get_connection_state()]


func _on_button_pressed() -> void:
	if is_instance_valid(peer_control):
		peer_control.peer_item = self
	
	pressed.emit()


func update():
	if is_instance_valid(name_label):
		name_label.text = peer_id
	
	if is_instance_valid(state_color_rect):
		state_color_rect.color = get_connection_state_color()
		state_color_rect.tooltip_text = get_connection_state_text()
	
	if is_instance_valid(peer_control):
		if self == peer_control.peer_item:
			peer_control.update()
	
	updated.emit()


func add_message_item_control(data):
	var message_item_control := MESSAGE_ITEM_CONTROL_SCENE.instantiate()
	message_item_controls.append(message_item_control)
	message_item_control.data = data
	return message_item_control


func add_channel_item_control(channel: WebRTCDataChannel):
	var channel_item_control := CHANNEL_ITEM_CONTROL_SCENE.instantiate()
	channel_item_controls.append(channel_item_control)
	
	channel_item_control.client = client
	channel_item_control.peer_id = peer_id
	channel_item_control.peer = peer
	channel_item_control.channel = channel
	channel_item_control.channel_control = channel_control
	
	if is_instance_valid(peer_control):
		if peer_control.peer_item == self:
			peer_control.add_channel_item_control(channel_item_control)


func _on_client_peer_connection_state_changed(p_peer_id_hash: String, _peer: WebRTCPeerConnection):
	if p_peer_id_hash != peer_id:
		return
	
	update()


func _on_client_peer_channel_initiated(p_peer_id: String, _peer: WebRTCPeerConnection, p_channel: WebRTCDataChannel):
	if p_peer_id != peer_id:
		return
	
	add_channel_item_control(p_channel)
	add_message_item_control(
		"Channel {label} initiated".format({
			"label": p_channel.get_label(),
		})
	)
