extends ModConfigLine


func _ready() -> void:
	super()

func update_ui():
	input.set_pressed_no_signal(config_value)
	#input.button_pressed = config_value
