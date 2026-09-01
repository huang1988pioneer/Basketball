class_name ShotFlight
extends RefCounted

var shooter: String = ""
var start: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var charge: float = 0.0
var distance: float = 0.0
var resolved: bool = false


func configure(next_shooter: String, next_start: Vector2, next_target: Vector2, next_charge: float, next_distance: float) -> void:
	shooter = next_shooter
	start = next_start
	target = next_target
	charge = next_charge
	distance = next_distance
	resolved = false
