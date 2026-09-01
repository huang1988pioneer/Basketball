class_name CourtActor
extends RefCounted

var x: float = 0.0
var y: float = 0.0
var facing: float = 1.0
var bob: float = 0.0
var dash: float = 0.0


func _init(start_x := 0.0, start_y := 0.0, start_facing := 1.0) -> void:
	reset(start_x, start_y, start_facing)


func reset(start_x: float, start_y: float, start_facing: float) -> void:
	x = start_x
	y = start_y
	facing = start_facing
	bob = 0.0
	dash = 0.0


func pos() -> Vector2:
	return Vector2(x, y)


func tick_dash(dt: float) -> void:
	dash = maxf(0.0, dash - dt)
