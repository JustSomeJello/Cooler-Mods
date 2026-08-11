extends Node
class_name CoolerMods

signal config_saved(mod:ModLoader.Mod, data:Dictionary)

signal config_option_value_changed(mod:ModLoader.Mod, id:String, value:Variant)

signal config_menu_post_ready(mod:ModLoader.Mod, menu:Menu)

signal mods_menu_post_ready(menu:Menu)

signal mod_button_post_ready(mod:ModLoader.Mod, button)


static var master:Master
static var config_lines: Dictionary[String, PackedScene] = {}
static var config

static var MOD_ID = "justsomejello.coolermods"
static var MOD_NODE_PATH = "ModLoader/"+MOD_ID.validate_node_name()

static var COOLER_MODS_MENU: PackedScene = ResourceLoader.load("res://mods/coolermods/overrides/mods_menu.tscn", "PackedScene")
static var MOD_CONFIG_MENU: PackedScene = ResourceLoader.load("res://mods/coolermods/overrides/config_menu.tscn", "PackedScene")
static var COOLER_MODS_BUTTON: PackedScene = ResourceLoader.load("res://mods/coolermods/scenes/cooler_mods_button.tscn", "PackedScene")

static var MOD_DATA_PATH := "user://mod_data/"
#static var MOD_CONFIG_FILENAME := MOD_DATA_PATH+"mod_configs.json"
static var MOD_CONFIG_PATH := MOD_DATA_PATH.path_join("configs")
var CONFIG_LINES_PATH = "res://mods/coolermods/scenes/config_options/"

static var DEFAULT_NUM_MIN = 0
static var DEFAULT_NUM_MAX = 100

var config_line_names:Array[String] = [
	# Visual Elements // No Functionality
	"header",
	# Number Elements
	"spin_box", "slider",
	# String Elements
	"line_edit",
	# Boolean Elements
	"checkbox",
	# Misc.
	"option_picker"
]

static var temp_settings: Dictionary[String, Variant] = {
	"show_descs": true
}

var mods_with_configs: Dictionary[String, ModLoader.Mod] = {}

static var initial_enabled: Array[String] = []

static func find_self() -> CoolerMods:
	var cm = master.get_tree().root.get_node(CoolerMods.MOD_NODE_PATH)
	return cm

func load_config_option_scene(path:String) -> PackedScene:
	return ResourceLoader.load(CONFIG_LINES_PATH.path_join(path+".tscn"), "PackedScene")

func _init() -> void :
	pass

func _enter_tree() -> void :
	master = get_tree().current_scene as Master
	

func _ready() -> void :
	master.child_entered_tree.connect(_on_child_enter)
	master.child_exiting_tree.connect(_on_child_exit)
	
	print("[CoolerMods] im running!!! yeah, thats me, running.")
	if not DirAccess.dir_exists_absolute(MOD_CONFIG_PATH):
		DirAccess.make_dir_recursive_absolute(MOD_CONFIG_PATH)
	
	get_config_line_types()
	gen_default_configs()
	
	reload_self_config()
	
	var cm = CoolerMods.find_self()
	cm.config_option_value_changed.connect(on_config_value_adjust)
	cm.config_menu_post_ready.connect(on_config_menu_loaded)
	cm.mods_menu_post_ready.connect(on_mods_menu_loaded)
	cm.mod_button_post_ready.connect(on_mod_button_loaded)

static func reload_self_config():
	config = CoolerMods.get_mod_config_values(ModLoader.mods[CoolerMods.MOD_ID])

func _on_child_enter(node:Node):
	if node is GameLoader:
		_on_game_loader_load(node as GameLoader)
	elif not node is Menu:
		return
	# This was written in 1.0.2, and the mod menu doesn't have a type i can look for.
	# so, im just gonna. check for one random node that the mod menu has, and if it exists then
	# uhhhh its the mod menu!
	# fogwaves please release 1.0.3 i beg you
	#if node.has_node("CanvasLayer/Control/VBoxContainer/HBoxContainer2/ModsEnabled"):
	if node.name == "SettingsMenu" and node.has_node("UILayer/ModsButton"):
		var mb = node.get_node("UILayer/ModsButton")
		var cmb = COOLER_MODS_BUTTON.instantiate()
		
		cmb.position = mb.position
		mb.free()
		
		node.mods_button = cmb
		node.get_node("UILayer").add_child(cmb)
		#var cmenu = COOLER_MODS_MENU.instantiate() as CoolerModsMenu
		#cmenu.switch.connect(master.switch_scene)
		#switch_scene(cmenu)
	elif node.name == "ModConfigMenu":
		pass
		#load_mod_config(node.mod)
		#if FileAccess.file_exists(cur_filepath):
		#	print("sonion")
		#var file = FileAccess.open(MOD_CONFIG_FILENAME, FileAccess.READ_WRITE)
		#if not file:
			#push_error(FileAccess.get_open_error())
			#return

func _on_child_exit(node:Node):
	pass

func _on_game_loader_load(gl:GameLoader):
	# hookin' em alllll up now
	var cm = CoolerMods.find_self()
	
	for m:String in mods_with_configs.keys():
		var mod_node = get_tree().root.get_node("ModLoader/"+m.validate_node_name())
		if not mod_node: 
			continue
		
		if mod_node.has_method("_on_coolermods_config_saved"):
			var cur_mod = mods_with_configs[m]
			cm.config_saved.connect(mod_node._on_coolermods_config_saved)
			mod_node._on_coolermods_config_saved(cur_mod, get_mod_config_values(cur_mod)) # spoofing a signal call
	
	initial_enabled = ModLoader.enabled.duplicate()

static func get_mod_config_values(mod:ModLoader.Mod):
	var cur_filepath = get_config_path(mod)
	var file = FileAccess.open(cur_filepath, FileAccess.READ)
	if not file:
		push_error(error_string(FileAccess.get_open_error()))
		return
	
	return JSON.parse_string(file.get_as_text())

static func save_mod_config(mod:ModLoader.Mod, data:Dictionary):
	var cur_filepath = get_config_path(mod)
	var file_data = JSON.parse_string(FileAccess.get_file_as_string(cur_filepath))
	
	for d in data.keys():
		file_data[d] = data[d]
	
	var file = FileAccess.open(cur_filepath, FileAccess.WRITE)
	file.store_string(JSON.stringify(file_data, "\t"))
	file.close()
	
	var cm:CoolerMods = CoolerMods.find_self()
	cm.config_saved.emit(mod, data)

func get_config_line_types():
	for cl in config_line_names:
		config_lines[cl] = load_config_option_scene(cl)

func gen_default_configs():
	for mod in ModLoader.mods.values():
		var path = get_config_path(mod)
		var ui_data = JSON.parse_string(get_json_contents(mod, "config.json"))
		if not ui_data:
			continue
		
		if not FileAccess.file_exists(path) or not JSON.parse_string(FileAccess.get_file_as_string(path)):
			# less prep it
			var pure_data: Dictionary[String, Variant] = {}
			for d in ui_data.keys():
				if ui_data[d].has("default") and not ui_data[d].has("header"):
					pure_data[d] = ui_data[d]["default"]
			
			var file = FileAccess.open(path, FileAccess.WRITE)
			file.store_string(JSON.stringify(pure_data, "\t"))
			file.close()
		else:
			# less prep it
			var file = FileAccess.open(path, FileAccess.READ_WRITE)
			var pure_data: Dictionary = JSON.parse_string(file.get_as_text())
			for d in ui_data.keys():
				if ui_data[d].has("default") and not ui_data[d].has("header"):
					if not pure_data.has(d):
						# if the key doesn't exist
						pure_data[d] = ui_data[d]["default"]
					elif not typeof(pure_data[d]) == typeof(ui_data[d]["default"]):
						# if the key exists but is the wrong variant
						pure_data[d] = ui_data[d]["default"]
					
					# checking the associated type_hint...
					if ui_data[d].has("type_hint") and config_lines[ui_data[d]["type_hint"]["id"]]:
						var cl = config_lines[ui_data[d]["type_hint"]["id"]].instantiate()
						# correcting type
						if not typeof(pure_data[d]) == cl.type:
							pure_data[d] = type_convert(pure_data[d], cl.type)
						
						# type checks!
						# options / index clamping
						if ui_data[d]["type_hint"]["id"] == "option_picker":
							pure_data[d] = floorf(pure_data[d])
							pure_data[d] = clamp(pure_data[d], 0, ui_data[d]["type_hint"]["options"].size()-1)
						# number clamping
						elif pure_data[d] is float:
							pure_data[d] = clampf(pure_data[d], 
							ui_data[d]["type_hint"].get("min", DEFAULT_NUM_MIN),
							ui_data[d]["type_hint"].get("max", DEFAULT_NUM_MAX))
						# string resizing
						#elif pure_data[d] is String:
							#var str:String
							#str.left(ui_data[d]["type_hint"].get("max", 0))
							#pure_data[d]
					elif pure_data[d] is float:
							pure_data[d] = clampf(pure_data[d], DEFAULT_NUM_MIN, DEFAULT_NUM_MAX)
			
			file.store_string(JSON.stringify(pure_data, "\t"))
			file.close()
		
		mods_with_configs[mod.id] = mod
		#CoolerMods.find_self().config_saved.emit()
	pass

static func get_config_path(mod:ModLoader.Mod):
	return MOD_CONFIG_PATH.path_join(mod.id+".json")


# doing these in the modscript as an example, & to see if the signals work...
var cur_config_menu
var cur_mods_menu

func on_mod_button_loaded(mod:ModLoader.Mod, button):
	#var label:Label = Label.new()
	#label.text = "Added via modscript!"
	#label.position = Vector2(256, 16)
	#label.z_index = 128
	#button.add_child(label)
	pass

func on_mods_menu_loaded(menu:Menu):
	cur_mods_menu = menu
	#var label:Label = Label.new()
	#label.text = "Added via modscript!"
	#label.position = Vector2(256, 16)
	#label.z_index = 128
	#menu.add_child(label)

func _on_coolermods_config_saved(mod:ModLoader.Mod, data:Dictionary):
	print("[CoolerMods] Mod ",mod.id," config data has been saved.")
	if mod.id == CoolerMods.MOD_ID:
		config = data
	
	# oh okay what else is happening here???
	if mod.id == CoolerMods.MOD_ID and cur_config_menu:
		if not data["config_dancer"] and cur_config_menu.has_node("UILayer/UI/Dancer"):
			var dancer:CoolerModsDancer = cur_config_menu.get_node("UILayer/UI/Dancer")
			if dancer.dead: return
			dancer.murder()
			#dancer.get_node("Car/CarCrash").play()
			#master.play_music(Master.Music.PEACE)
			cur_mods_menu.get_node("Sounds/mus").stream_paused = true
			cur_mods_menu.get_node("%Dancer").make_inactive()
			
	

func on_config_menu_loaded(mod:ModLoader.Mod, menu:Menu):
	if mod.id == CoolerMods.MOD_ID:
		cur_config_menu = menu #as ModConfigMenu

func on_config_value_adjust(mod:ModLoader.Mod, id:String, value):
	#print(id," adjusted.")
	if mod.id == CoolerMods.MOD_ID and id == "config_dancer":
		var dancer:CoolerModsDancer = cur_config_menu.get_node("UILayer/UI/Dancer")
		if not dancer: return
		if not value:
			dancer.make_scared()
		else:
			dancer.reset_anim()

# Added by Cooler Mods
static func get_json_contents(mod:ModLoader.Mod, source:String):
	# ---------------------------------- Copied & tweaked from mod_loader.gd
	var json: String
	
	var json_path = mod.mod_script.get_base_dir()
	if mod.path == "DEBUG": # Mods loaded via. DEBUG and not exported
		if FileAccess.file_exists(json_path.path_join(source)):
			var file = FileAccess.open(json_path.path_join(source), FileAccess.READ)
			if not file:
				push_error(FileAccess.get_open_error())
			json = file.get_as_text()
	else: # Mods found in your mods folder
		var zr = ZIPReader.new()
		var err = zr.open(mod.path)
		json_path = json_path.trim_prefix("res://")
		if err == OK and zr.file_exists(json_path.path_join(source)):
			json = zr.read_file(json_path.path_join(source)).get_string_from_utf8()
	# -----------------------------------
	return json

# i just stole these and modified them slightly
# :P
static func switch_scene(to_scene: Node, with_state: int = 0) -> void :
	if is_instance_valid(master.base_scene):
		master.base_scene.queue_free()
	for overlay in master.overlays:
		overlay.queue_free()
	master.overlays.clear()

	master.thinker.visible = true
	master.menu_bg.visible = true
	master.base_scene = to_scene as GameScene
	master.base_scene.switch.connect(switch_scene)
	master.base_scene.overlay.connect(overlay_scene)
	master.base_scene.state = with_state
	master.base_scene.play_music.connect(master.play_music)
	master.add_child.call_deferred(master.base_scene)

static func overlay_scene(to_scene: Node, with_state: int = 0) -> void :
	var overlay: = to_scene as GameScene
	if overlay.pause_last_scene:
		master.get_topmost_scene().process_mode = Node.PROCESS_MODE_DISABLED
	if overlay.hide_last_scene:
		master.get_topmost_scene().visible = false

	overlay.switch.connect(switch_scene)
	overlay.overlay.connect(overlay_scene)
	overlay.back.connect(master.back)
	overlay.state = with_state
	master.overlays.append(overlay)
	
	master.add_child.call_deferred(overlay)
