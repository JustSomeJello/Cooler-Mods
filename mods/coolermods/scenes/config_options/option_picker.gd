extends ModConfigLine


func _ready() -> void:
	#config_value = floorf(config_value)
	input.get_popup().canvas_item_default_texture_filter = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
	for o in ui_data["type_hint"]["options"] as Array[String]:
		input.add_item(o)
	super()

func update_ui():
	input.select(config_value)
