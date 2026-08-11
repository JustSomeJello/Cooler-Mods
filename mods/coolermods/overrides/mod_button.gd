class_name CoolerModButton
extends PanelContainer


signal enabled()
signal disabled()
signal ordered_up()
signal ordered_down()


@export_group("Internal References")
@export var _disable_button: Button
@export var _enable_button: Button
@export var _order_buttons: Control
@export var _icon: TextureRect # added by Cooler Mods
@export var _viewport: SubViewport
@export var _viewport_icon: AnimatedSprite2D
@export var _mod_bg: PanelContainer # added by Cooler Mods
@export var _name: RichTextLabel # Changed to RichTextLabel // Cooler Mods
@export var _author: RichTextLabel # Changed to RichTextLabel // Cooler Mods
@export var _version: Label
@export var _description: RichTextLabel # added by Cooler Mods
@export var _description_bg: PanelContainer # added by Cooler Mods
@export var _config_button: Button # added by Cooler Mods

@export var _content: Container

var config_string: String
var config_modulate: Color
var config_theme: Theme
var config_bg

var mods_menu: CoolerModsMenu

var mod: ModLoader.Mod:
	set(value):
		mod = value

		_name.text = mod.name
		_author.text = mod.author
		_version.text = mod.version
		_description.text = mod.description
		
		cooler_mod_tweaks(mod) # Added by Cooler Mods
		
		update()

# Added by Cooler Mods
func cooler_mod_tweaks(mod: ModLoader.Mod):
	# Getting custom json info, if it exists....
	var cool_json: String = CoolerMods.get_json_contents(mod, "coolermod.json")
	config_string = CoolerMods.get_json_contents(mod, "config.json")
	
	# Cooler Mods config stuff...
	if cool_json and not cool_json.is_empty():
		var dict = JSON.parse_string(cool_json)
		
		# Custom Mod Icon
		if dict.has("icon"):
			var tex = ResourceLoader.load(dict.get("icon"), "Texture", ResourceLoader.CACHE_MODE_IGNORE)
			if tex is Texture2D:
				_icon.texture = tex
			elif tex is SpriteFrames:
				var first_frame = tex.get_frame_texture(tex.get_animation_names()[0], 0)
				if CoolerMods.config["animate_icons"]:
					_viewport_icon.sprite_frames = tex
					_viewport_icon.play(tex.get_animation_names()[0])
					_viewport.size = first_frame.get_size()
					_icon.texture = _viewport.get_texture()
				else:
					_icon.texture = first_frame
		
		# Fancy Author Name
		if dict.has("author_fancy"):
			var au_bbcode:String = dict.get("author_fancy")
			if not au_bbcode.is_empty():
				_author.text = dict.get("author_fancy")
		
		# Fancy Mod Name
		if dict.has("name_fancy"):
			var fancy_name:String = dict.get("name_fancy")
			if not fancy_name.is_empty():
				_name.text = fancy_name
		
		# Custom Background / StyleBox
		if dict.has("bg_stylebox"):
			var sb = ResourceLoader.load(dict.get("bg_stylebox"), "StyleBox", ResourceLoader.CACHE_MODE_IGNORE)
			if sb:
				_mod_bg.add_theme_stylebox_override("panel", sb)
		# Simple Custom Colour for mod background
		elif dict.has("bg_color"):
			var sb: StyleBoxFlat = _mod_bg.get_theme_stylebox("panel") #StyleBoxFlat.new()
			sb.bg_color = dict.get("bg_color")
			_mod_bg.add_theme_stylebox_override("panel", sb)
		
		# Custom Description Stylebox
		if dict.has("description_stylebox"):
			var sb = ResourceLoader.load(dict.get("description_stylebox"), "StyleBox", ResourceLoader.CACHE_MODE_IGNORE)
			if sb:
				_description_bg.add_theme_stylebox_override("panel", sb)
		# Simple Custom Description Modulate
		elif dict.has("description_bgcolor"):
			var sb: StyleBoxTexture = _description_bg.get_theme_stylebox("panel")
			sb.modulate_color = dict.get("description_bgcolor")
			_description_bg.add_theme_stylebox_override("panel", sb)
		
		# Mod Config Background Modulate
		if dict.has("config_color"):
			config_modulate = dict.get("config_color")
		
		# Config Theme
		if dict.has("config_theme"):
			config_theme = ResourceLoader.load(dict.get("config_theme"), "Theme")
		
		if dict.has("config_bg"):
			config_bg = ResourceLoader.load(dict.get("config_bg"), "Theme")
	
	# Mod Config stuff...
	if config_string and not config_string.is_empty() and CoolerMods.initial_enabled.has(mod.id):
		_config_button.visible = true
	
	_description_bg.visible = CoolerMods.temp_settings["show_descs"]
# --------------------------- End of Cooler Mods additions

func _ready() -> void:
	CoolerMods.find_self().mod_button_post_ready.emit(mod, self)

func update() -> void :
	if mod.id in ModLoader.enabled:
		_disable_button.show()
		_order_buttons.show()
		_enable_button.hide()
	else:
		_enable_button.show()
		_disable_button.hide()
		_order_buttons.hide()


func _on_disable_pressed() -> void :
	ModLoader.enabled.erase(mod.id)
	update()
	disabled.emit()


func _on_enable_pressed() -> void :
	ModLoader.enabled.append(mod.id)
	update()
	enabled.emit()


func _on_order_up_pressed() -> void :
	var i = ModLoader.enabled.find(mod.id)
	if i > 0:
		var prev = ModLoader.enabled[i - 1]
		ModLoader.enabled[i - 1] = mod.id
		ModLoader.enabled[i] = prev
		ordered_up.emit()


func _on_order_down_pressed() -> void :
	var i = ModLoader.enabled.find(mod.id)
	if i < ModLoader.enabled.size() - 1:
		var next = ModLoader.enabled[i + 1]
		ModLoader.enabled[i + 1] = mod.id
		ModLoader.enabled[i] = next
		ordered_down.emit()

func _on_config_button_pressed() -> void:
	CoolerMods.master.play_select_sound()
	var config_menu = CoolerMods.MOD_CONFIG_MENU.instantiate() as ModConfigMenu
	config_menu.mod = mod
	config_menu.config_info = JSON.parse_string(config_string)
	
	config_menu.get_node("%Header").text = mod.name
	config_menu.get_node("%HeaderIcon").texture = _icon.texture
	config_menu.get_node("%BG").frame = mods_menu.get_node("UILayer/BG").frame
	if config_modulate:
		config_menu.get_node("%BG").modulate = config_modulate
	if config_theme:
		config_menu.get_node("UILayer/UI").theme = config_theme
	if config_bg:
		#var an = AnimatedSprite2D.new()
		var first_frame = config_bg.get_frame_texture(config_bg.get_animation_names()[0], 0)
		config_menu.get_node("%BG").sprite_frames = config_bg
		config_menu._bg_viewport.size = first_frame.get_size()
		config_menu.get_node("%BG").frame = 0
	
	var conf_dancer:CoolerModsDancer = mods_menu.get_node("%Dancer").duplicate()
	if mods_menu.get_node("%Dancer").dead or CoolerMods.config["config_dancer"]:
		conf_dancer.get_node("MusicNotes").self_modulate = config_menu.get_node("%BG").modulate
		conf_dancer.dead = mods_menu.get_node("%Dancer").dead
		config_menu.get_node("UILayer/UI").add_child(conf_dancer)
	
	CoolerMods.overlay_scene(config_menu)
	pass # Replace with function body.
