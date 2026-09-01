class_name GameBall
extends RefCounted

const RADIUS := 15.0
const GRAVITY := 980.0
const AIR_DRAG := 0.02
const FLOOR_RESTITUTION := 0.56
const FLOOR_FRICTION := 0.74
const RIM_RESTITUTION := 0.40
const BACKBOARD_RESTITUTION := 0.50
const RIM_PIPE_RADIUS := 6.0
const TRAIL_MAX := 12

var x: float = 0.0
var y: float = 0.0
var spin: float = 0.0
var in_flight: bool = false
var loose: bool = false
var vx: float = 0.0
var vy: float = 0.0
var bounces: int = 0
var scored: bool = false
var prev_x: float = 0.0
var prev_y: float = 0.0
var trail: Array[Vector2] = []


func reset(start_x: float, start_y: float) -> void:
	x = start_x
	y = start_y
	prev_x = start_x
	prev_y = start_y
	spin = 0.0
	in_flight = false
	loose = false
	vx = 0.0
	vy = 0.0
	bounces = 0
	scored = false
	trail.clear()


func pos() -> Vector2:
	return Vector2(x, y)


func launch(from: Vector2, velocity: Vector2) -> void:
	x = from.x
	y = from.y
	prev_x = from.x
	prev_y = from.y
	vx = velocity.x
	vy = velocity.y
	in_flight = true
	loose = false
	scored = false
	bounces = 0
	trail.clear()
	trail.append(from)


func hold_dribble(hand: Vector2, feet_y: float, time: float, is_charging: bool) -> void:
	in_flight = false
	loose = false
	scored = false
	vx = 0.0
	vy = 0.0
	x = hand.x
	if is_charging:
		y = hand.y - 16.0
		spin += 0.08
		return
	var high := hand.y
	var low := minf(feet_y - RADIUS - 8.0, hand.y + 36.0)
	var phase := fmod(time * 2.7, 1.0)
	var u := phase * 2.0 if phase < 0.5 else (1.0 - phase) * 2.0
	y = lerpf(high, low, u * u)
	spin += 0.22


func step(dt: float, court: Rect2, hoop: Vector2, rim_y: float, floor_y: float, backboard_x: float) -> String:
	if not in_flight and not loose:
		return ""
	var event := ""
	var speed := Vector2(vx, vy).length()
	var substeps := clampi(int(ceil(speed * dt / 4.0)), 1, 8)
	var h := dt / float(substeps)
	for _i in substeps:
		var sub_event := _integrate(h, court, hoop, rim_y, floor_y, backboard_x)
		if sub_event != "":
			event = sub_event
			if event == "scored" or event == "missed":
				break
	_record_trail()
	return event


func _integrate(dt: float, court: Rect2, hoop: Vector2, rim_y: float, floor_y: float, backboard_x: float) -> String:
	prev_x = x
	prev_y = y
	vy += GRAVITY * dt
	var drag := clampf(1.0 - AIR_DRAG * dt, 0.86, 1.0)
	vx *= drag
	x += vx * dt
	y += vy * dt
	spin += vx * dt * 0.018

	var event := _check_score(hoop, rim_y)
	_collide_rim(hoop, rim_y)
	_collide_backboard(backboard_x)
	_collide_walls(court)

	if y + RADIUS >= floor_y:
		y = floor_y - RADIUS
		if vy > 0.0:
			var incoming := vy
			vy *= -FLOOR_RESTITUTION
			vx *= FLOOR_FRICTION
			bounces += 1
			spin += absf(vx) * 0.01
			if incoming < 55.0:
				vy = 0.0
				vx *= 0.82
			if in_flight and not scored:
				in_flight = false
				loose = true
				return "missed"
			if scored:
				return "landed"
	return event


func _check_score(hoop: Vector2, rim_y: float) -> String:
	if scored or vy < 50.0:
		return ""
	if prev_y >= rim_y or y < rim_y:
		return ""
	var denom: float = maxf(y - prev_y, 0.0001)
	var x_cross: float = lerpf(prev_x, x, (rim_y - prev_y) / denom)
	if absf(x_cross - hoop.x) <= GameData.SCORE_HALF_WIDTH:
		scored = true
		x = x_cross
		y = rim_y + 2.0
		vx *= 0.18
		if vy < 90.0:
			vy = 90.0
		else:
			vy *= 0.55
		return "scored"
	return ""


func _collide_rim(hoop: Vector2, rim_y: float) -> void:
	if scored:
		return
	if absf(x - hoop.x) <= GameData.SCORE_HALF_WIDTH and y <= rim_y + 10.0:
		return
	_bounce_circle(Vector2(hoop.x - GameData.RIM_PIPE_OFFSET, rim_y), RIM_PIPE_RADIUS, RIM_RESTITUTION)
	_bounce_circle(Vector2(hoop.x + GameData.RIM_PIPE_OFFSET, rim_y), RIM_PIPE_RADIUS, RIM_RESTITUTION)


func _bounce_circle(center: Vector2, pipe_radius: float, restitution: float) -> void:
	var delta := Vector2(x - center.x, y - center.y)
	var dist: float = delta.length()
	var min_dist: float = RADIUS + pipe_radius
	if dist >= min_dist or dist <= 0.0001:
		return
	var normal := delta / dist
	x = center.x + normal.x * min_dist
	y = center.y + normal.y * min_dist
	var vn: float = vx * normal.x + vy * normal.y
	if vn < 0.0:
		vx -= (1.0 + restitution) * vn * normal.x
		vy -= (1.0 + restitution) * vn * normal.y


func _collide_backboard(backboard_x: float) -> void:
	if x + RADIUS < backboard_x or y < GameData.BACKBOARD_TOP or y > GameData.BACKBOARD_BOTTOM:
		return
	if vx > 0.0:
		x = backboard_x - RADIUS
		vx *= -BACKBOARD_RESTITUTION
		spin += 1.6


func _collide_walls(court: Rect2) -> void:
	var left := court.position.x + 10.0 + RADIUS
	var right := court.position.x + court.size.x - 10.0 - RADIUS
	if x < left:
		x = left
		vx = absf(vx) * 0.35
	elif x > right:
		x = right
		vx = -absf(vx) * 0.35


func _record_trail() -> void:
	if not in_flight and not loose:
		return
	trail.append(Vector2(x, y))
	if trail.size() > TRAIL_MAX:
		trail.remove_at(0)
