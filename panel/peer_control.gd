class_name WebRTCoWTTPeerControl extends Control


const STATE_COLOR_DEFAULT := Color.WHITE
const STATE_TEXT_DEFAULT := "Unknown"


@export var peer_item: WebRTCoWTTPeerItemControl:
	set(x):
		if peer_item != x:
			if null != peer_item:
				peer_item.updated.disconnect(update)
			
			if null != x:
				x.updated.connect(update)
		
		peer_item = x
		show()
		
		if is_instance_valid(id_label):
			id_label.text = peer_item.peer_id
		
		if is_instance_valid(channels_containers):
			for child in channels_containers.get_children():
				channels_containers.remove_child(child)
			
			for channel_item_control in peer_item.channel_item_controls:
				channels_containers.add_child(channel_item_control)
		
		update()

@export var channels_containers: Container
@export var messages_container: WebRTCoWTTMessagesContainer


@onready var id_label: Label = %IdLabel

@onready var connection_state_color_rect: ColorRect = %ConnectionStateColorRect
@onready var connection_state_label: Label = %ConnectionStateLabel

@onready var gathering_state_color_rect: ColorRect = %GatheringStateColorRect
@onready var gathering_state_label: Label = %GatheringStateLabel

@onready var signaling_state_color_rect: ColorRect = %SignalingStateColorRect
@onready var signaling_state_label: Label = %SignalingStateLabel


func _ready() -> void:
	hide()


func update():
	if is_instance_valid(connection_state_color_rect):
		connection_state_color_rect.color = STATE_COLOR_DEFAULT if not peer_item else peer_item.get_connection_state_color()
	
	if is_instance_valid(connection_state_label):
		connection_state_label.text = STATE_TEXT_DEFAULT if not peer_item else peer_item.get_connection_state_text()
	
	if is_instance_valid(gathering_state_color_rect):
		gathering_state_color_rect.color = STATE_COLOR_DEFAULT if not peer_item else peer_item.get_gathering_state_color()
	
	if is_instance_valid(gathering_state_label):
		gathering_state_label.text = STATE_TEXT_DEFAULT if not peer_item else peer_item.get_gathering_state_text()
	
	if is_instance_valid(signaling_state_color_rect):
		signaling_state_color_rect.color = STATE_COLOR_DEFAULT if not peer_item else peer_item.get_signaling_state_color()
	
	if is_instance_valid(signaling_state_label):
		signaling_state_label.text = STATE_TEXT_DEFAULT if not peer_item else peer_item.get_signaling_state_text()
	
	
	if null == peer_item:
		return
	
	if is_instance_valid(messages_container):
		messages_container.display_messages(peer_item.message_item_controls)


func add_channel_item_control(channel_item_control: WebRTCoWTTChannelItemControl):
	channels_containers.add_child(channel_item_control)
