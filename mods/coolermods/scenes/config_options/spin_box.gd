extends ModConfigLine

func _ready() -> void:
	if ui_data.has("type_hint"):
		input.min_value = ui_data["type_hint"].get("min", 0)
		input.max_value = ui_data["type_hint"].get("max", 100)
		input.step = ui_data["type_hint"].get("step", 1)
	
	input.value_changed.connect(on_value_changed)
	super()

func update_ui():
	input.set_value_no_signal(config_value)
	#input.value = config_value
