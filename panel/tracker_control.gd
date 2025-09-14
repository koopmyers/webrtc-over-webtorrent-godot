class_name WebRTCoWTTTrackerControl extends Control


@export var tracker_item: WebRTCoWTTTrackerItemControl:
	set(x):
		tracker_item = x
		show()
		
		if is_instance_valid(url_label):
			url_label.text = tracker_item.url
		
		if is_instance_valid(address_label):
			address_label.text = "({address})".format({
				"address": WebRTCOverWebTorrentClient.stringify_web_socket(tracker_item.socket)
			})
		
		update_messages()

@export var messages_container: WebRTCoWTTMessagesContainer


@onready var url_label: Label = %UrlLabel
@onready var address_label: Label = %AddressLabel



func _ready() -> void:
	hide()


func update_messages():
	if null == tracker_item:
		return
	
	if is_instance_valid(messages_container):
		messages_container.display_messages(tracker_item.message_item_controls)
