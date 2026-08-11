extends Menu
class_name ModConfigMenu

#signal menu_post_ready(menu:ModConfigMenu)

var CONFIG_LINES_PATH = "res://mods/coolermods/scenes/config_options/"

var settings_changed: = false:
	set(value):
		settings_changed = value
		save_button.disabled = not settings_changed


@onready var background: AnimatedSprite2D = %BG
@onready var header: Label = %Header
@onready var header_icon: TextureRect = %HeaderIcon
@onready var description: Label = %Description
@onready var config_elements: Control = %ConfigElements
@onready var save_button: Button = %SaveButton
@onready var sfx_beep: AudioStreamPlayer = %SFXBeep
@onready var ui: Control = $UILayer/UI
@export var _bg_viewport: SubViewport

var config_info: Dictionary = {}
var mod: ModLoader.Mod

var supported_types = [TYPE_FLOAT, TYPE_BOOL, TYPE_STRING]

func _ready():
	super ()

	#fullscreen_toggle.button_pressed = Settings.fullscreen
	#lang_selector.select(Settings.LANGS.find(Settings.language))
#
	#sensitivity_slider.value = Settings.power_sensitivity
	#invert_shot_toggle.button_pressed = Settings.invert_shot
	#buffer_shot_toggle.button_pressed = Settings.buffer_shot
#
	#master_slider.value = Settings.master_volume
	#music_slider.value = Settings.music_volume
	#sound_slider.value = Settings.sound_volume
	load_config_info()
	settings_changed = false

	if %Header.size.x > 262: # dont @ me for this magical number </3
		%Header.autowrap_mode = TextServer.AutowrapMode.AUTOWRAP_WORD_SMART
		%Header.custom_minimum_size.x = 262
	
	CoolerMods.find_self().config_menu_post_ready.emit(mod, self)

func is_cosmetic(info:Dictionary):
	return info.has("header") or info.has("cosmetic")

func load_config_info():
	var pure_data = CoolerMods.get_mod_config_values(mod)
	
	for i in config_info.keys():
		var config_line: ModConfigLine
		
		if is_cosmetic(config_info[i]):
			config_line = CoolerMods.config_lines["header"].instantiate()
		elif not config_info[i].has("default"):
			push_error("Config setting "+i+" has no default value. Skipping...")
			continue
		elif config_info[i].has("type_hint"):
			var base_scene = CoolerMods.config_lines[config_info[i]["type_hint"]["id"]]
			#ResourceLoader.load(CONFIG_LINES_PATH.path_join(config_info[i]["type_hint"]["id"]+".tscn"), "PackedScene")
			config_line = base_scene.instantiate()
		else:
			match typeof(config_info[i]["default"]):
				TYPE_INT, TYPE_FLOAT:
					config_line = CoolerMods.config_lines["spin_box"].instantiate()
				TYPE_STRING:
					config_line = CoolerMods.config_lines["line_edit"].instantiate()
				TYPE_BOOL:
					config_line = CoolerMods.config_lines["checkbox"].instantiate()
				_: # leaving it null
					pass
		# -------------------------------------------
		
		if not config_line and is_cosmetic(config_info[i]):
			config_line = CoolerMods.config_lines["header"].instantiate()
		if not config_line:
			push_error("Config setting "+i+" is null.")
			continue
		
		# now, let us shape it's LINE as your own.
		config_line.ui_data = config_info[i]
		config_line.name = i
		config_line.id = i
		config_line.option_name = config_info[i].get("name", i)
		config_line.mouse_entered.connect(%Description.set_text.bind(config_info[i].get("description", i)))
		config_line.value_changed.connect(on_value_changed)
		if not config_info[i].has("header"): #config_info[i].has("header") and not config_info[i].has("cosmetic"):
			if not typeof(config_info[i]["default"]) == config_line.type:
				push_error("Config setting "+i+" has type mismatch: Cannot assign default type "
				+type_string(typeof(config_info[i]["default"]))+" to type_hint type "+type_string(config_line.type)+".")
				continue
			elif not supported_types.has(typeof(config_info[i]["default"])):
				push_error("Config setting "+i+" has a default value with an unsupported type: Type "
				+type_string(typeof(config_info[i]["default"]))+" is not supported.")
				continue
			
			config_line.config_value = type_convert(pure_data[i], config_line.type)
			config_line.default_value = type_convert(config_info[i]["default"], config_line.type)
		
		#print(config_line.config_value)
		%ConfigElements.add_child(config_line)

func _on_ui_gui_input(event: InputEvent) -> void :
	if event is InputEventMouseMotion:
		description.text = "..."

func on_value_changed(value, id):
	if not settings_changed:
		settings_changed = true
	
	CoolerMods.find_self().config_option_value_changed.emit(mod, id, value)

func _on_save_set_pressed():
	var data:Dictionary = {}
	for cl: ModConfigLine in %ConfigElements.get_children():
		if cl.ui_data.has("header" or cl.ui_data.has("cosmetic")):
			continue
		
		data[cl.id] = cl.config_value
	
	CoolerMods.save_mod_config(mod, data)
	settings_changed = false
	#Settings.save_settings()


#func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void :
	#Settings.fullscreen = toggled_on
	#settings_changed = true
#
#
#func _on_lang_selector_item_selected(index: int) -> void :
	#Settings.language = Settings.LANGS[index]
	#settings_changed = true
#
#
#func _on_sensitivity_slider_value_changed(value: float) -> void :
	#Settings.power_sensitivity = value
	#settings_changed = true
	#sensitivity_percent.text = "%d%%" % int(value * 100.0)
#
#
#func _on_master_slider_value_changed(value: float) -> void :
	#Settings.master_volume = value
	#settings_changed = true
	#master_percent.text = "%d%%" % int(value * 100.0)
	#sfx_beep.play()
#
#
#func _on_music_slider_value_changed(value: float) -> void :
	#Settings.music_volume = value
	#settings_changed = true
	#music_percent.text = "%d%%" % int(value * 100.0)
#
#
#func _on_sound_slider_value_changed(value: float) -> void :
	#Settings.sound_volume = value
	#settings_changed = true
	#sound_percent.text = "%d%%" % int(value * 100.0)
	#sfx_beep.play()
#
#func _on_mods_button_pressed() -> void :
	#switch.emit(Master.GameScenes.MODS_MENU)
#
#
#func _on_invert_shot_toggle_toggled(toggled_on: bool) -> void :
	#Settings.invert_shot = toggled_on
	#settings_changed = true
#
#
#func _on_buffer_shot_toggle_toggled(toggled_on: bool) -> void :
	#Settings.buffer_shot = toggled_on
	#settings_changed = true
