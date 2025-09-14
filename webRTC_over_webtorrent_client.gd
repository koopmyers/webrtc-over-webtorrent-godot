class_name WebRTCOverWebTorrentClient extends Node


signal session_created
signal session_joined

signal tracker_connection_initiated(url: String, socket: WebSocketPeer)
signal tracker_connection_state_changed(socket: WebSocketPeer)

signal data_sent_to_tracker(socket: WebSocketPeer, data)
signal data_received_from_tracker(socket: WebSocketPeer, data)

signal peer_connection_initiated(peer_id: String, peer: WebRTCPeerConnection)
signal peer_connection_state_changed(peer_id: String, peer: WebRTCPeerConnection)


signal peer_channel_initiated(peer_id: String, peer: WebRTCPeerConnection, channel: WebRTCDataChannel)
signal peer_channel_state_changed(peer_id: String, peer: WebRTCPeerConnection, channel: WebRTCDataChannel)
signal data_sent_to_peer(peer_id: String, peer: WebRTCPeerConnection, channel: WebRTCDataChannel, data)
signal data_received_from_peer(peer_id: String, peer: WebRTCPeerConnection, channel: WebRTCDataChannel, data)


signal error_raised(code: int, message: String)


@export var context: WebRTCOverWebTorrentContext


var session_id := "":
	set(x):
		session_id = x
		if not session_id.is_empty():
			info_hash = context.get_info_hash(session_id)

var info_hash: String
var peer_id: String
var _is_server: bool = false
var multipayer_peer := WebRTCMultiplayerPeer.new()

var trakers_sockets: Dictionary[WebSocketPeer, WebSocketPeer.State] = {}

var peers: Dictionary[String, WebRTCPeerConnection] = {}
var _peers_connection_states: Dictionary[WebRTCPeerConnection, WebRTCPeerConnection.ConnectionState] = {}
var _peers_gathering_states: Dictionary[WebRTCPeerConnection, WebRTCPeerConnection.GatheringState] = {}
var _peers_signaling_state: Dictionary[WebRTCPeerConnection, WebRTCPeerConnection.SignalingState] = {}


var peers_channels: Dictionary[String, Array] = {}
var channel_states: Dictionary[WebRTCDataChannel, WebRTCDataChannel.ChannelState] = {}


var peers_local_session_descriptions: Dictionary[String, Dictionary] = {}
var peers_remote_session_descriptions: Dictionary[String, Dictionary] = {}
var peers_ice_candidates: Dictionary[String, Array]



static func stringify_web_socket(p_socket: WebSocketPeer) -> String:
	return "{protocol}://{address}:{port}".format({
		"protocol": p_socket.get_selected_protocol(),
		"address": p_socket.get_connected_host(),
		"port": p_socket.get_connected_port(),
	})


func raise_error(p_code: int, p_message: String):
	printerr(p_message)
	error_raised.emit(p_code, p_message)


# TRACKER SESSION ###

func create_session() -> void:
	if null == context:
		raise_error(ERR_UNCONFIGURED, "Cannot create session, context is missing")
		return
	
	if not context.is_context_valid():
		raise_error(ERR_UNCONFIGURED, "Cannot create session, context is invalid")
		return
	
	session_id = context.get_random_session_id()
	peer_id = context.get_master_peer_id()
	_is_server = true
	
	if context.is_multiplayer_peer_mode:
		multipayer_peer.create_server()
		get_tree().get_multiplayer().multiplayer_peer = multipayer_peer

	
	for url in context.trackers_urls:
		connect_to_tracker(url)
	
	session_created.emit()


func join_session(p_session_id: String):
	if null == context:
		raise_error(ERR_UNCONFIGURED, "Cannot join session, context is missing")
		return
	
	if not context.is_context_valid():
		raise_error(ERR_UNCONFIGURED, "Cannot join session, context is invalid")
		return
	
	if not context.is_session_id_valid(p_session_id):
		raise_error(ERR_CANT_RESOLVE, "Cannot join session, session id invalid '{id}'".format({
			"id": p_session_id,
		}))
		return
	
	session_id = p_session_id
	peer_id = context.get_random_peer_id()
	_is_server = false
	
	if context.is_multiplayer_peer_mode:
		multipayer_peer.create_client(int(peer_id))
		get_tree().get_multiplayer().multiplayer_peer = multipayer_peer

	initiate_peer_connection(context.get_master_peer_id())
	for url in context.trackers_urls:
		connect_to_tracker(url)
	
	session_joined.emit()


func connect_to_tracker(p_url: String) -> void:
	var socket := WebSocketPeer.new()
	#print("Trying to connect to {url}".format({
		#"url": p_url,
	#}))
	
	var error := socket.connect_to_url(p_url)
	if error:
		raise_error(error, "Cannot connect to tracker '{url}': {error}".format({
			"url": p_url,
			"error": error_string(error) 
		}))
		return
	
	#print("Opening connection with {url}".format({
		#"url": p_url,
	#}))
	
	socket.poll()
	var state := socket.get_ready_state()
	trakers_sockets[socket] = state
	tracker_connection_initiated.emit(p_url, socket)
	

func _socket_connection_opened(p_socket: WebSocketPeer):
	if _is_server:
		send_to_tracker(p_socket, get_announce_data())
	
	else:
		
		var master_id_hash := context.get_master_peer_id()
		if is_peer_ready(master_id_hash):
			send_to_tracker(p_socket, get_answer_data(master_id_hash))

# TRACKER SEND PACKET###

func get_announce_data() -> Dictionary:
	var data := {
		"action": "announce",
		"info_hash": info_hash,
		"peer_id": peer_id,
		
		"uploaded": 0,
		"downloaded": 0,
	}
	
	return data


func get_answer_data(to_peer_id: String) -> Dictionary:
	var description = peers_local_session_descriptions.get(to_peer_id)
	var candidates = peers_ice_candidates.get(to_peer_id, [])
	
	var data := {
		"action": "announce",
		"info_hash": info_hash,
		"peer_id": peer_id,
		
		"to_peer_id": to_peer_id,
		"answer": {
			"type": description.type,
			"sdp": description.sdp,
			"ice_candidates": candidates,
		},
		"offer_id": "0",
	}
	
	return data


func send_to_tracker(p_socket: WebSocketPeer, data: Variant):
	var json := JSON.stringify(data)
	p_socket.send_text(json)
	data_sent_to_tracker.emit(p_socket, data)


# TRACKER RECEIVE PACKET ###

func decode_packet(p_packet: PackedByteArray) -> Variant:
	var string := p_packet.get_string_from_ascii()
	var data = JSON.parse_string(string)
	return data


func handle_packet(p_socket: WebSocketPeer, p_packet: PackedByteArray):
	var data = decode_packet(p_packet)
	data_received_from_tracker.emit(p_socket, data)
	
	if not data is Dictionary:
		raise_error(ERR_INVALID_DATA, "Data is not dictionary")
		return
	
	if data.has("answer"):
		handle_signaling_data(p_socket, data, data.answer)


func handle_signaling_data(_socket: WebSocketPeer, p_data: Dictionary, p_signaling_data):
	if not p_data.has("peer_id"):
		raise_error(ERR_INVALID_DATA, "Signaling data has no peer_id")
		return
	
	var from_peer_id = p_data.peer_id
	if not from_peer_id is String:
		raise_error(ERR_INVALID_DATA, "peer_id invalid data type")
		return
	
	var peer: WebRTCPeerConnection = peers.get(from_peer_id)
	if null == peer:
		initiate_peer_connection(from_peer_id)
		peer = peers.get(from_peer_id)
		if null == peer:
			return
		
		#if is_peer_ready(from_peer_id):
			#send_to_tracker(p_socket, get_answer_data(from_peer_id))
	
	
	if not p_signaling_data is Dictionary:
		raise_error(ERR_INVALID_DATA, "Signaling data is not dictionary")
		return
	
	if not p_signaling_data.has("sdp"):
		raise_error(ERR_INVALID_DATA, "Signaling data has no sdp")
		return
	
	var sdp = p_signaling_data.sdp
	if not sdp is String:
		raise_error(ERR_INVALID_DATA, "sdp invalid data type")
		return
	
	if not p_signaling_data.has("type"):
		raise_error(ERR_INVALID_DATA, "Signaling data has no type")
		return
	
	var type = p_signaling_data.type
	if not type is String:
		raise_error(ERR_INVALID_DATA, "type invalid data type")
		return
	
	#offer_received.emit(p_socket, sdp)
	if not peers_remote_session_descriptions.get(from_peer_id):
		var error := peer.set_remote_description(type, sdp)
		if error:
			raise_error(error, "Cannot set remote description to peer '{peer_id}': {error}".format({
				"peer_id": from_peer_id,
				"error": error_string(error) 
			}))
			return
		
		peers_remote_session_descriptions[from_peer_id] = {
			"type": type,
			"sdp": sdp,
		}
	
	if not p_signaling_data.has("ice_candidates"):
		raise_error(ERR_INVALID_DATA, "Signaling data has no ice_candidates")
		return
	
	var ice_candidates = p_signaling_data.ice_candidates
	if not ice_candidates is Array:
		raise_error(ERR_INVALID_DATA, "ice_candidates invalid data type")
		return
	
	for candidate in ice_candidates:
		if not candidate is Dictionary:
			raise_error(ERR_INVALID_DATA, "Ice candidate invalid data type")
			continue
		
		if not candidate.has("media"):
			raise_error(ERR_INVALID_DATA, "Ice candidate has no media")
			continue
		
		var media = candidate.media
		if not media is String:
			raise_error(ERR_INVALID_DATA, "media invalid data type")
			return
		
		if not candidate.has("index"):
			raise_error(ERR_INVALID_DATA, "Ice candidate has no media")
			continue
		
		var index = candidate.index
		if not index is float:
			raise_error(ERR_INVALID_DATA, "index invalid data type")
			return
		index = int(index)
		
		if not candidate.has("sdp"):
			raise_error(ERR_INVALID_DATA, "Ice candidate has no media")
			continue
		
		var ice_sdp = candidate.sdp
		if not ice_sdp is String:
			raise_error(ERR_INVALID_DATA, "sdp invalid data type")
			return
		
		peer.add_ice_candidate(media, index, ice_sdp)
	


# PEER SESSION ###

func initiate_peer_connection(p_peer_id_hash: String):
	var peer = WebRTCPeerConnection.new()
	var error := peer.initialize(context.get_ice_servers())
	if error:
		raise_error(error, "Cannot initialize peer '{peer_id}': {error}".format({
			"peer_id": p_peer_id_hash,
			"error": error_string(error) 
		}))
		return
	
	peers[p_peer_id_hash] = peer
	peer.ice_candidate_created.connect(_on_peer_ice_candidate_created.bind(p_peer_id_hash))
	peer.session_description_created.connect(_on_peer_session_description_created.bind(p_peer_id_hash))
	
	peer_connection_initiated.emit(p_peer_id_hash, peer)
	
	if context.is_multiplayer_peer_mode:
		multipayer_peer.add_peer(peer, int(p_peer_id_hash))
		
		for channel in multipayer_peer.get_peer(int(p_peer_id_hash)).channels:
			if not peers_channels.has(p_peer_id_hash):
				peers_channels[p_peer_id_hash] = []
			
			peers_channels[p_peer_id_hash].append(channel)
			peer_channel_initiated.emit(p_peer_id_hash, peer, channel)
	
	else:
		var channel = peer.create_data_channel("chat", {"negotiated": true, "id": 1})
		if not peers_channels.has(p_peer_id_hash):
				peers_channels[p_peer_id_hash] = []
			
		peers_channels[p_peer_id_hash].append(channel)
		peer_channel_initiated.emit(p_peer_id_hash, peer, channel)
	
	
	if not _is_server:
		error = peer.create_offer()
		if error:
			raise_error(error, "Cannot create offer '{peer_id}': {error}".format({
				"peer_id": p_peer_id_hash,
				"error": error_string(error) 
			}))
			return


func is_peer_ready(p_peer_id_hash: String) -> bool:
	if not peers_local_session_descriptions.has(p_peer_id_hash):
		return false
	
	if not peers.has(p_peer_id_hash):
		return false
	
	var peer := peers[p_peer_id_hash]
	return WebRTCPeerConnection.GATHERING_STATE_COMPLETE == peer.get_gathering_state()


func _on_peer_ice_candidate_created(p_media: String, p_index: int, p_sdp: String, p_peer_id_hash: String):
	if not peers_ice_candidates.has(p_peer_id_hash):
		peers_ice_candidates[p_peer_id_hash] = []
	
	peers_ice_candidates[p_peer_id_hash].append({
		"media": p_media,
		"index": p_index,
		"sdp": p_sdp,
	})
	
	for socket in trakers_sockets:
		if WebSocketPeer.STATE_OPEN != socket.get_ready_state():
			continue
		
		if is_peer_ready(p_peer_id_hash):
			send_to_tracker(socket, get_answer_data(p_peer_id_hash))


func _on_peer_session_description_created(p_type: String, p_sdp: String, p_peer_id_hash: String):
	peers[p_peer_id_hash].set_local_description(p_type, p_sdp)
	
	peers_local_session_descriptions[p_peer_id_hash] = {
		"type": p_type,
		"sdp": p_sdp,
	}
	
	for socket in trakers_sockets:
		if WebSocketPeer.STATE_OPEN != socket.get_ready_state():
			continue
		
		if is_peer_ready(p_peer_id_hash):
			send_to_tracker(socket, get_answer_data(p_peer_id_hash))

# PEER SEND PACKET ###

func send_to_peer_on_channel(p_peer_id_hash: String, p_peer: WebRTCPeerConnection, p_channel: WebRTCDataChannel, p_data: Variant):
	
	var encoded: PackedByteArray = []
	if not p_data is String:
		encoded = JSON.stringify(p_data).to_utf8_buffer()
	else:
		encoded = p_data.to_utf8_buffer()
	
	p_channel.put_packet(encoded)
	
	data_sent_to_peer.emit(p_peer_id_hash, p_peer, p_channel, p_data)

# PEER RECEIVE PACKET ###

func handle_peer_packet(p_peer_id_hash: String, p_peer: WebRTCPeerConnection, p_channel: WebRTCDataChannel, p_packet: PackedByteArray):
	var data := p_packet.get_string_from_utf8()
	data_received_from_peer.emit(p_peer_id_hash, p_peer, p_channel, data)


# PROCESS ###

func _process(_delta):
	var updated_tracker_sockets: Dictionary[WebSocketPeer, WebSocketPeer.State] = {}
	for i_socket in trakers_sockets:
		var updated_state := _process_socket(i_socket, trakers_sockets[i_socket])
		if WebSocketPeer.STATE_CLOSED == updated_state:
			continue
		
		updated_tracker_sockets[i_socket] = updated_state
	
	trakers_sockets = updated_tracker_sockets
	
	
	for i_peer_id_hash in peers:
		_process_peer(
			i_peer_id_hash,
		 	peers[i_peer_id_hash],
		)


func _process_socket(p_socket: WebSocketPeer, p_last_state: WebSocketPeer.State) -> WebSocketPeer.State:
	
	p_socket.poll()
	var state = p_socket.get_ready_state()
	
	if p_last_state != state:
		tracker_connection_state_changed.emit(p_socket)
	
	if WebSocketPeer.STATE_OPEN == state:
		if WebSocketPeer.STATE_OPEN != p_last_state:
			_socket_connection_opened(p_socket)
		
		while p_socket.get_available_packet_count():
			var packed := p_socket.get_packet()
			handle_packet(p_socket, packed)
	
	elif WebSocketPeer.STATE_CLOSING == state:
		# Keep polling to achieve proper close.
		pass
	
	elif WebSocketPeer.STATE_CLOSED == state:
		var code = p_socket.get_close_code()
		var reason = p_socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
	
	return state


func _process_peer(p_peer_id_hash: String, p_peer: WebRTCPeerConnection):
	#if not context.is_multiplayer_peer_mode:
	p_peer.poll()
	
	
	var state = p_peer.get_connection_state()
	var old_state = _peers_connection_states.get(p_peer, state)
	_peers_connection_states[p_peer] = state
	if old_state != state:
		peer_connection_state_changed.emit(p_peer_id_hash, p_peer)
	
	
	state = p_peer.get_gathering_state()
	old_state = _peers_gathering_states.get(p_peer, state)
	_peers_gathering_states[p_peer] = state
	if old_state != state:
		peer_connection_state_changed.emit(p_peer_id_hash, p_peer)
	
	
	state = p_peer.get_signaling_state()
	old_state = _peers_signaling_state.get(p_peer, state)
	_peers_signaling_state[p_peer] = state
	if old_state != state:
		peer_connection_state_changed.emit(p_peer_id_hash, p_peer)
		
	
	if context.is_multiplayer_peer_mode:
		return
	
	
	#if is_master:
		#print("Peer {id} states: C{c}, S{s}, G{g}, Channel{channel}".format({
			#"id": p_peer_id_hash,
			#"c": p_peer.get_connection_state(),
			#"g": p_peer.get_gathering_state(),
			#"s": p_peer.get_signaling_state(),
			#"channel": state,
		#}))
	
	for i_channel: WebRTCDataChannel in peers_channels.get(p_peer_id_hash, []):
	
		state = i_channel.get_ready_state()
		old_state = channel_states.get(i_channel, state)
		channel_states[i_channel] = state
		if old_state != state:
			peer_channel_state_changed.emit(p_peer_id_hash, p_peer, i_channel)
	
		if WebRTCDataChannel.STATE_OPEN == state:
			while 0 < i_channel.get_available_packet_count():
				var packet := i_channel.get_packet()
				handle_peer_packet(p_peer_id_hash, p_peer, i_channel, packet)
