extends Container
class_name ModConfigLine

signal value_changed(value)

@export var label:Label # name's protected, fml
@export var redo_button:TextureButton
@export var input:Control
@export var val_label:Label
@export var type := TYPE_NIL

var ui_data
var id:String
var option_name: String
var description: String

var config_value
var default_value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Name.text = option_name
	#default_value = ui_data["default"]
	
	update_ui()
	on_value_changed(config_value, false)

## i swear this function exists!!!
func update_ui():
	# godot crashed twice while i commented this function
	# so maybe its cursed
	pass
	#if input is Range:
		#input.value = config_value as float
	#elif input is CheckButton:
		#input.button_pressed = config_value as bool
	#elif input is LineEdit:
		#input.text = str(config_value)

func on_value_changed(value, emit = true):
	# check if its equal or not equal to the default value
	config_value = value
	
	#print(config_value == default_value)
	if config_value == default_value and not redo_button.disabled:
		redo_button.disabled = true
	elif not config_value == default_value and redo_button.disabled:
		redo_button.disabled = false
	
	if val_label:
		val_label.text = str(value)

	if emit: 
		value_changed.emit(value, id)


func _on_redo_pressed() -> void:
	CoolerMods.master.play_back_sound()
	config_value = default_value
	update_ui()
	on_value_changed(config_value)
	pass # Replace with function body.
