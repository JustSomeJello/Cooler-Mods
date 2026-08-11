@tool
extends Node2D
class_name AfterImageGenerator

#@export var AFTERIMAGE_THRESHOLD_MIN: = 500.0
#@export var AFTERIMAGE_THRESHOLD_MAX: = 900.0
@export var AFTERIMAGE_OPACITY: = 0.75
@export var AFTERIMAGE_FADE_TIME: = 0.15
@export var AFTERIMAGE_RATE: = 0.05

var afterimage_cooldown: = 0.0

@export var sprite:Sprite2D
#@export_range(0.0, 1.0, 0.01) var weight := 0.5

func _process(delta:float):
	if get_parent() is SubViewport: return
	if not get_parent().visible: 
		return
	
	afterimage_cooldown -= delta
	if afterimage_cooldown <= 0.0:
		afterimage_cooldown += AFTERIMAGE_RATE
		var afterimage = Sprite2D.new()
		afterimage.texture = sprite.texture
		afterimage.material = sprite.material
		afterimage.global_position = sprite.global_position
		afterimage.global_scale = sprite.global_scale
		#afterimage.z_index = -1
		#var weight = inverse_lerp(AFTERIMAGE_THRESHOLD_MIN, AFTERIMAGE_THRESHOLD_MAX, velocity.length())
		var weight = 1.0 # lazy
		afterimage.modulate.a = lerpf(0.0, AFTERIMAGE_OPACITY, weight)
		var tween = afterimage.create_tween()
		tween.tween_property(afterimage, ^"modulate:a", 0.0, lerpf(0.0, AFTERIMAGE_FADE_TIME, weight))
		tween.tween_callback(afterimage.queue_free)
		$AfterImages.add_child(afterimage)
		#print($AfterImages.get_children())
