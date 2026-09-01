class_name GameBall
extends RefCounted

var x: float = 0.0
var y: float = 0.0
var spin: float = 0.0
var in_flight: bool = false
var loose: bool = false
var vx: float = 0.0
var vy: float = 0.0
var bounces: int = 0


func reset(start_x: float, start_y: float) -> void:
	x = start_x
	y = start_y
	spin = 0.0
	in_flight = false
	loose = false
	vx = 0.0
	vy = 0.0
	bounces = 0


func pos() -> Vector2:
	return Vector2(x, y)
