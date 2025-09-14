extends Node


@export var master_client: WebRTCOverWebTorrentClient
@export var client_01: WebRTCOverWebTorrentClient
@export var client_02: WebRTCOverWebTorrentClient


func _ready() -> void:
	master_client.create_session()
	
	await get_tree().create_timer(1.0).timeout
	client_01.join_session(master_client.session_id)
	
	await get_tree().create_timer(1.0).timeout
	client_02.join_session(master_client.session_id)
