extends Control


const TRACKER_ITEM_CONTROL_SCENE := preload("uid://bc0iqgoaed12")
const PEER_ITEM_CONTROL_SCENE := preload("uid://dq2d125kftur6")

const MESSAGE_ITEM_CONTROL_SCENE := preload("uid://cfsei3airwx4s")


@export var client: WebRTCOverWebTorrentClient:
	set(x):
		if client != x:
			if null != client:
				
				client.error_raised.disconnect(_on_client_error_raised)
				client.session_created.disconnect(_on_client_session_created)
				client.session_joined.disconnect(_on_client_session_joined)
				client.tracker_connection_initiated.disconnect(_on_client_tracker_connection_initiated)
				client.tracker_connection_state_changed.disconnect(_on_client_tracker_connection_state_changed)
				
				client.peer_connection_initiated.disconnect(_on_client_peer_connection_initiated)
			
			
			if null != x:
				x.error_raised.connect(_on_client_error_raised)
				x.session_created.connect(_on_client_session_created)
				x.session_joined.connect(_on_client_session_joined)
				x.tracker_connection_initiated.connect(_on_client_tracker_connection_initiated)
				x.tracker_connection_state_changed.connect(_on_client_tracker_connection_state_changed)
				x.peer_connection_initiated.connect(_on_client_peer_connection_initiated)
				
		
		client = x
		update()


var message_item_controls: Array[WebRTCoWTTMessagesItemControl] = []

@onready var peer_label: Label = %PeerLabel
@onready var session_label: Label = %SessionLabel
@onready var session_line_edit: LineEdit = %SessionLineEdit
@onready var join_button: Button = %JoinButton
@onready var create_button: Button = %CreateButton

@onready var trackers_container: Container = %TrackersContainer
@onready var peers_container: Container = %PeersContainer

@onready var no_control: Control = %NoControl
@onready var tracker_control: WebRTCoWTTTrackerControl = %TrackerControl
@onready var peer_control: WebRTCoWTTPeerControl = %PeerControl
@onready var channel_control: WebRTCoWTTChannelControl = %ChannelControl
@onready var messages_container: WebRTCoWTTMessagesContainer = %MessagesContainer


func _ready() -> void:
	messages_container.display_messages([], self)
	update()


func _on_join_button_pressed() -> void:
	if not is_instance_valid(client):
		return
	
	client.join_session(session_line_edit.text)


func _on_create_button_pressed() -> void:
	if not is_instance_valid(client):
		return
	
	client.create_session()


func _on_header_button_pressed() -> void:
	no_control.show()
	if not messages_container.is_displaying_from(self):
		messages_container.display_messages(message_item_controls, self)


func update():
	if is_instance_valid(peer_label):
		peer_label.text = str(client.peer_id)
	
	if is_instance_valid(session_label):
		session_label.text = client.session_id
		session_line_edit.text = client.session_id
	
	if is_instance_valid(messages_container):
		if messages_container.is_displaying_from(self):
			messages_container.display_messages(message_item_controls, self)


func add_message_item_control(data) -> WebRTCoWTTMessagesItemControl:
	var message_item_control := MESSAGE_ITEM_CONTROL_SCENE.instantiate()
	message_item_controls.append(message_item_control)
	message_item_control.data = data
	return message_item_control


func add_tracker(p_url: String, p_socket: WebSocketPeer):
	var item_control := TRACKER_ITEM_CONTROL_SCENE.instantiate()
	trackers_container.add_child(item_control)
	
	item_control.client = client
	item_control.url = p_url
	item_control.socket = p_socket
	item_control.tracker_control = tracker_control


func add_peer(peer_id: String, peer: WebRTCPeerConnection):
	var item_control := PEER_ITEM_CONTROL_SCENE.instantiate()
	peers_container.add_child(item_control)
	
	item_control.client = client
	item_control.peer_id = peer_id
	item_control.peer = peer
	#item_control.channel = channel
	
	item_control.peer_control = peer_control
	item_control.channel_control = channel_control


func _on_client_error_raised(_code: int, message: String):
	var item := add_message_item_control(message)
	item.error()
	update()


func _on_client_session_created():
	session_line_edit.editable = false
	join_button.disabled = true
	create_button.disabled = true
	
	add_message_item_control("Create session {id}".format({
		"id": client.session_id
	}))
	update()


func _on_client_session_joined():
	session_line_edit.editable = false
	join_button.disabled = true
	create_button.disabled = true
	
	add_message_item_control("Join session {id}".format({
		"id": client.session_id
	}))
	update()


func _on_client_tracker_connection_initiated(url: String, socket: WebSocketPeer):
	add_tracker(url, socket)
	add_message_item_control("Tracker {url} initiated".format({
		"url": url
	}))
	update()


func _on_client_tracker_connection_state_changed(socket: WebSocketPeer):
	var tracker_item_control: WebRTCoWTTTrackerItemControl
	for i_control in trackers_container.get_children():
		if i_control.socket == socket:
			tracker_item_control = i_control
			break
	
	var state = socket.get_ready_state()
	
	if WebSocketPeer.STATE_OPEN == state:
		add_message_item_control("Connection open with tracker {url} ".format({
			"url": tracker_item_control.url
		}))
	
	elif WebSocketPeer.STATE_CLOSING == state:
		add_message_item_control("Connection closing on tracker {url} ".format({
			"url": tracker_item_control.url
		}))
	
	elif WebSocketPeer.STATE_CLOSED == state:
		var code := socket.get_close_code()
		var msg := "Connection closed with tracker {url}".format({
			"url": tracker_item_control.url,
		})
		if -1 != code: # not clean
			msg += ": {code}/{reason}".format({
				"code": socket.get_close_code(),
				"reason": socket.get_close_reason()
			})
		
		add_message_item_control(msg)
	
	update()


func _on_client_peer_connection_initiated(peer_id: String, peer: WebRTCPeerConnection):
	add_peer(peer_id, peer)
	add_message_item_control("Peer {peer_id} initiated".format({
		"peer_id": peer_id,
	}))
	update()


func _on_client_peer_connection_state_changed(peer_id: String, _peer: WebRTCPeerConnection, channel: WebRTCDataChannel):
	var state = channel.get_ready_state()
	
	if WebSocketPeer.STATE_OPEN == state:
		add_message_item_control("Connection open with peer {peer_id}".format({
			"peer_id": peer_id,
		}))
	
	elif WebSocketPeer.STATE_CLOSING == state:
		add_message_item_control("Connection closing on peer {peer_id}".format({
			"peer_id": peer_id,
		}))
	
	elif WebSocketPeer.STATE_CLOSED == state:
		add_message_item_control("Connection closed with peer {peer_id}".format({
			"peer_id": peer_id,
		}))
	
	update()
