class_name WebRTCoWTTChannelControl extends Control


@export var channel_item: WebRTCoWTTChannelItemControl:
	set(x):
		channel_item = x
		show()
		
		if is_instance_valid(id_label):
			id_label.text = str(channel_item.channel.get_id())
		
		if is_instance_valid(label_label):
			label_label.text = channel_item.channel.get_label()
		
		update_messages()


@export var messages_container: WebRTCoWTTMessagesContainer


@onready var id_label: Label = %IdLabel
@onready var label_label: Label = %LabelLabel


@onready var line_edit: LineEdit = %LineEdit




func _ready() -> void:
	hide()


func update_messages():
	if null == channel_item:
		return
	
	if is_instance_valid(messages_container):
		messages_container.display_messages(channel_item.message_item_controls)


func sumit_text():
	channel_item.client.send_to_peer_on_channel(
		channel_item.peer_id,
		channel_item.peer,
		channel_item.channel,
		line_edit.text
	)
	
	line_edit.text = ""


func _on_button_pressed() -> void:
	sumit_text()


func _on_line_edit_text_submitted(_new_text: String) -> void:
	sumit_text()
