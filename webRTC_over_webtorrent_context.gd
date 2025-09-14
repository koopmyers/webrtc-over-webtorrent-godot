@tool
class_name WebRTCOverWebTorrentContext extends Resource


enum Mode {SIMPLE, MULTIPLAYER_PEER}

const STRING_CHARACTER_SET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijqlmnopqrstuvwxyz1234567890"


@export var app_id: String
@export_tool_button("Randomize app id") var randomize_app_id_tool_button = (func():
	app_id = get_random_string(15)
)

@export var mode := Mode.SIMPLE

@export var trackers_urls: Array[String] = [
	"ws://localhost:8000",
]

@export var stun_servers_urls: Array[String] = []


var is_multiplayer_peer_mode: bool:
	get:
		return Mode.MULTIPLAYER_PEER == mode


func is_context_valid() -> bool:
	if null == trackers_urls or  trackers_urls.is_empty():
		printerr("Missing trackers urls")
		return false
	
	if null == stun_servers_urls or stun_servers_urls.is_empty():
		printerr("Missing stun servers urls")
		return false
	
	if null == app_id or 15 != app_id.length():
		return false
	
	return true


func get_ice_servers() -> Dictionary:
	return {
		"iceServers": [
			{
				"urls": stun_servers_urls,
			}
		]
	}


func get_random_string(p_size: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var character_set_length := STRING_CHARACTER_SET.length()
	
	var out := ""
	for i in range(p_size):
		var index := rng.randi()%character_set_length
		out += STRING_CHARACTER_SET[index]
	
	return out
	

func get_random_session_id() -> String:
	return get_random_string(5)


func is_session_id_valid(p_session_id: String) -> bool:
	return 5 == p_session_id.length()


func get_info_hash(p_session_id: String) -> String:
	if not is_session_id_valid(p_session_id):
		printerr("Invalid session id")
	
	return app_id + p_session_id


func get_master_peer_id() -> String:
	return str(1).pad_zeros(20)


func get_random_peer_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return str(rng.randi()%2147483647).pad_zeros(20)
