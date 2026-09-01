class_name ShotFlight
extends RefCounted

var shooter: String = ""
var start: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var arc: float = 0.0
var duration: float = 1.0
var t: float = 0.0
var charge: float = 0.0
var distance: float = 0.0


func configure(next_shooter: String, next_start: Vector2, next_target: Vector2, next_arc: float, next_duration: float, next_charge: float, next_distance: float) -> void:
	shooter = next_shooter
	start = next_start
	target = next_target
	arc = next_arc
	duration = next_duration
	t = 0.0
	charge = next_charge
	distance = next_distance
