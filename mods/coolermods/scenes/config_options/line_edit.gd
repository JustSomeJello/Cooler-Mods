extends ModConfigLine


func _ready() -> void:
	super()

func update_ui():
	input.text = str(config_value)
