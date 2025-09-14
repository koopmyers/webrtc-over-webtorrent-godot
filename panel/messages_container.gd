class_name WebRTCoWTTMessagesContainer extends Control


@export var message_control: WebRTCoWTTMessageControl


var _display_from: Object


@onready var list_container: Container = %ListContainer


func is_displaying_from(p_from) -> bool:
	return _display_from == p_from


func display_messages(p_controls: Array[WebRTCoWTTMessagesItemControl], p_from: Object = null):
	
	_display_from = p_from
	
	for child in list_container.get_children():
		list_container.remove_child(child)
	
	for control in p_controls:
		control.message_control = message_control
		list_container.add_child(control)


func _on_clipboard_button_pressed() -> void:
	var clipboard := ""
	for child in list_container.get_children():
		clipboard += str(child) + "\n"
	
	DisplayServer.clipboard_set(clipboard)
