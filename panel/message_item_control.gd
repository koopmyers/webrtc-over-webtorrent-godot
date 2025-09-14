class_name WebRTCoWTTMessagesItemControl extends Control


signal pressed


enum Type {INFO, ERROR, SENT, RECEIVED}



@export var type := Type.INFO:
	set(x):
		type = x
		if is_instance_valid(type_texture_rect):
			type_texture_rect.texture = icons.get(type)
			type_texture_rect.modulate = colors.get(type)

@export var message_control: WebRTCoWTTMessageControl


@export var icons: Dictionary[Type, Texture] = {}

@export var colors: Dictionary[Type, Color] = {
	Type.INFO: Color.BEIGE,
	Type.ERROR: Color.CRIMSON,
	Type.SENT: Color.DODGER_BLUE,
	Type.RECEIVED: Color.PALE_GREEN,
}

@export var strings: Dictionary[Type, String] = {
	Type.INFO: "-",
	Type.ERROR: "!",
	Type.SENT: "<",
	Type.RECEIVED: ">",
}


var data: Variant:
	set(x):
		data = x
		time = Time.get_time_string_from_system()
		
		if is_instance_valid(data_label):
			data_label.text = str(data)

var time: String:
	set(x):
		time = x
		if is_instance_valid(time_label):
			time_label.text = time

@onready var type_texture_rect: TextureRect = %TypeTextureRect
@onready var time_label: Label = %TimeLabel
@onready var data_label: Label = %DataLabel


func _ready() -> void:
	type = type
	data = data


func _to_string() -> String:
	return "{type}\t{time}\t{data}".format({
		"type": strings.get(type, "-"),
		"time": time,
		"data": str(data),
	})


func _on_button_pressed() -> void:
	if is_instance_valid(message_control):
		message_control.message_item_control = self
		
	pressed.emit()


func info():
	type = Type.INFO


func error():
	type = Type.ERROR


func received():
	type = Type.RECEIVED


func sent():
	type = Type.SENT
