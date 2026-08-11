extends Node2D
class_name CoolerModsDancer
var song_position_in_beats = 0
var last_reported_beat = 0
var master: Master
var currentmusic: AudioStreamPlayer
var bpm
var song_position = 0
var anim_frame = 0

@export var player_override: AudioStreamPlayer
@export var dancer:Sprite2D
@export var particles:GPUParticles2D
@onready var anim: AnimationPlayer = $AnimationPlayer



var skews = [18.6, 0, -18.6, 0]
var positions = [Vector2(640, 428), Vector2(640, 444), Vector2(640, 428), Vector2(640, 444)]
var scales = [Vector2(0.109, 0.16), Vector2(0.172, 0.089), Vector2(0.109, 0.16), Vector2(0.172, 0.089)]

var dead = false

func _ready() -> void :
	#dancer.texture = Master.costume.graphic
	#dancer.material = Master.costume.material



	if player_override != null:
		currentmusic = player_override
	else:
		master = get_tree().current_scene as Master #get_parent().get_parent().get_parent() as Master
		currentmusic = master.current_song
	#print(currentmusic.stream.get_bpm())
	if currentmusic != null and currentmusic.stream != null:
		if currentmusic.stream is AudioStreamSynchronized:
			bpm = currentmusic.stream.get_sync_stream(0).get_bpm()
		else:
			bpm = currentmusic.stream.get_bpm()
		bpm *= 2
	
	dancer.texture = Master.costume.graphic
	dancer.material = Master.costume.material
	
	reset_anim()


func _process(delta: float) -> void :
	if $AnimationPlayer.current_animation == "dancing" and currentmusic != null and currentmusic.stream != null:
		song_position = currentmusic.get_playback_position() + AudioServer.get_time_since_last_mix()
		song_position -= AudioServer.get_output_latency()
		song_position_in_beats = song_position / (60 / bpm)
		song_position_in_beats += 0.5
		report_beat()

func report_beat():
	if $AnimationPlayer.current_animation == "dancing" and currentmusic != null and currentmusic.stream != null:

		if !currentmusic.stream_paused:
			if last_reported_beat != round(song_position_in_beats):
				last_reported_beat = round(song_position_in_beats)
				anim_frame += 1
				if anim_frame == 4:
					anim_frame = 0
				anim.seek(0.2 * (anim_frame - 1), true)

func reset_anim():
	if dead:
		return
	if Settings.music_volume > 0.0 and Settings.master_volume > 0.0:
		$AnimationPlayer.play("dancing")
		$MusicNotes.emitting = true
		#dancer.texture = Master.costume.graphic
		#dancer.material = Master.costume.material
	else:
		$AnimationPlayer.play("paused")
		$MusicNotes.emitting = false
		#dancer.texture = Master.ghost_costume.graphic
		#dancer.material = Master.ghost_costume.material

func make_scared():
	if not dead:
		$AnimationPlayer.play("scared")

func make_inactive():
	dead = true
	dancer.visible = false
	$MusicNotes.visible = false
	$Sweating.visible = false

func murder():
	if dead:
		return
	$AnimationPlayer.play("die")
	dead = true
	$MusicNotes.visible = false
	$Sweating.visible = false
func murder_springboard():
	if dead:
		return
	$AnimationPlayer.play("die_springboard")
	dead = true
	$MusicNotes.visible = false
	$Sweating.visible = false
