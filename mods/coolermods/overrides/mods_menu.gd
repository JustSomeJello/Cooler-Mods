extends Menu
class_name CoolerModsMenu # this menu is so cool it deserves its very own class_name


const MOD_BUTTON = preload("res://mods/coolermods/overrides/mod_button.tscn")


@export_group("Internal References")
@export var _disabled_mods: Control
@export var _enabled_mods: Control
@export var _activation_toggle: CheckButton
@export var _music_player: AudioStreamPlayer
@export var _background: AnimatedSprite2D

#var coolermods_config

func _ready() -> void :
	play_music.emit(music)
	_activation_toggle.button_pressed = ModLoader.activated
	
	%Dancer._ready()
	%ShowDescriptions.button_pressed = CoolerMods.temp_settings["show_descs"]
	
	#CoolerMods.reload_self_config()

	for id in ModLoader.enabled:
		var mod = ModLoader.mods.get(id, null)
		if not mod:
			continue

		var button = MOD_BUTTON.instantiate()
		button.mod = mod
		_connect_button_signals(button)
		_enabled_mods.add_child(button)
		

	for id in ModLoader.mods:
		if id in ModLoader.enabled:
			continue

		var mod = ModLoader.mods[id]
		var button = MOD_BUTTON.instantiate()
		button.mod = mod
		_connect_button_signals(button)
		_disabled_mods.add_child(button)
	
	_on_show_descriptions_toggled(CoolerMods.temp_settings["show_descs"])
	CoolerMods.find_self().mods_menu_post_ready.emit(self)


func _connect_button_signals(button: CoolerModButton) -> void :
	button.enabled.connect(_on_mod_enabled.bind(button))
	button.disabled.connect(_on_mod_disabled.bind(button))
	button.ordered_up.connect(_on_mod_ordered_up.bind(button))
	button.ordered_down.connect(_on_mod_ordered_down.bind(button))
	
	# yeah hi hello, im also doing another thing in here, dont mind me.
	button.mods_menu = self
	#print(button.mods_menu)


func _on_mod_enabled(button: CoolerModButton) -> void :
	button.reparent(_enabled_mods)

func _on_mod_disabled(button: CoolerModButton) -> void :
	button.reparent(_disabled_mods)


func _on_mod_ordered_up(button: CoolerModButton) -> void :
	_enabled_mods.move_child(button, button.get_index() - 1)

func _on_mod_ordered_down(button: CoolerModButton) -> void :
	_enabled_mods.move_child(button, button.get_index() + 1)


func _on_mods_enabled_toggled(toggled_on: bool) -> void :
	ModLoader.activated = toggled_on


func _on_apply_pressed() -> void :
	$Sounds/mus.stop()
	$UILayer/ClickEater.visible = true
	#CoolerMods.master.play_music(Master.Music.PEACE)
	%Apply.text = "RESTARTING..."
	if not %Dancer.dead:
		var gamba = randi_range(0, 1)
		match gamba:
			1:
				%Dancer.murder_springboard()
			_:
				%Dancer.murder()
		#%Dancer.murder_springboard()
		await %Dancer.get_node("AnimationPlayer").animation_finished
	else:
		await get_tree().create_timer(0.75)
	ModLoader.save_config()
	ModLoader.quit_cleanly()
	if OS.create_instance(PackedStringArray()) != -1:
		get_tree().quit()


func _on_real_back_button_pressed() -> void:
	queue_free() #, brah.
	pass # Replace with function body.


func _on_mod_folder_pressed() -> void:
	CoolerMods.master.play_select_sound()
	
	if not DirAccess.dir_exists_absolute(ModLoader.MODS_DIR):
		DirAccess.make_dir_recursive_absolute(ModLoader.MODS_DIR)
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(ModLoader.MODS_DIR))
	#$FileDialog.visible = true

func _on_show_descriptions_toggled(toggled_on: bool) -> void:
	CoolerMods.temp_settings["show_descs"] = toggled_on
	
	for m:CoolerModButton in _disabled_mods.get_children():
		m._description_bg.visible = toggled_on
	for m:CoolerModButton in _enabled_mods.get_children():
		m._description_bg.visible = toggled_on


func _on_refresh_pressed() -> void:
	if not DirAccess.dir_exists_absolute(ModLoader.MODS_DIR):
		$Sounds/sound.play()
		return
	
	CoolerMods.master.play_select_sound()
	var debug_mod:ModLoader.Mod
	for m in ModLoader.mods:
		var mod = ModLoader.mods[m] as ModLoader.Mod
		if mod.path == "DEBUG":
			debug_mod = mod
			break
	
	ModLoader.mods.clear()
	ModLoader._populate_mods()
	if debug_mod: ModLoader.mods[debug_mod.id] = debug_mod
	
	for b in _disabled_mods.get_children():
		b.queue_free()
	for b in _enabled_mods.get_children():
		b.queue_free()
	
	for id in ModLoader.enabled:
		var mod = ModLoader.mods.get(id, null)
		if not mod:
			continue

		var button = MOD_BUTTON.instantiate()
		button.mod = mod
		_connect_button_signals(button)
		_enabled_mods.add_child(button)
	
	for id in ModLoader.mods:
		if id in ModLoader.enabled:
			continue

		var mod = ModLoader.mods[id]
		var button = MOD_BUTTON.instantiate()
		button.mod = mod
		_connect_button_signals(button)
		_disabled_mods.add_child(button)

func _on_apply_mouse_entered() -> void:
	#%Dancer.make_scared()
	pass # Replace with function body.

func _on_apply_mouse_exited() -> void:
	#%Dancer.reset_anim()
	pass # Replace with function body.
