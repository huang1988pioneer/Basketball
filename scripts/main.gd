extends Node2D

## 喵萌籃球大作戰
## A self-contained Godot 4 2D prototype.  The scene is intentionally drawn
## in code so the project can be opened without an asset or plugin pipeline.

const DESIGN_SIZE := Vector2(1280.0, 820.0)
const COURT_RECT := Rect2(24.0, 104.0, 846.0, 586.0)
const WORLD_RECT := Rect2(40.0, 184.0, 814.0, 458.0)
const RIGHT_RECT := Rect2(890.0, 104.0, 366.0, 586.0)
const BOTTOM_RECT := Rect2(24.0, 706.0, 1232.0, 94.0)
const HOOP := Vector2(766.0, 363.0)
const RIM_Y := 374.0
const FLOOR_Y := 584.0

const NAVY_950 := Color("050b1c")
const NAVY_900 := Color("091633")
const NAVY_800 := Color("122657")
const BLUE := Color("4c9cff")
const BLUE_LIGHT := Color("8bd5ff")
const RED := Color("ff6874")
const GOLD := Color("ffd16b")
const GREEN := Color("70e7a5")
const PURPLE := Color("c58cff")
const TEXT := Color("edf4ff")
const MUTED := Color("91a8d0")
const CREAM := Color("f4efe6")
const INK := Color("26344f")
const INK_MUTED := Color("66738b")

const START_RECT := Rect2(672.0, 648.0, 170.0, 34.0)
const RESET_RECT := Rect2(562.0, 648.0, 101.0, 34.0)
const MODE_RECT := Rect2(658.0, 104.0, 190.0, 34.0)
const REPLAY_RECT := Rect2(386.0, 434.0, 160.0, 36.0)
const MUTE_RECT := Rect2(1128.0, 28.0, 42.0, 28.0)
const HELP_RECT := Rect2(1180.0, 28.0, 76.0, 28.0)
const HELP_CLOSE_RECT := Rect2(785.0, 204.0, 86.0, 30.0)
const SKILL_ONE_RECT := Rect2(580.0, 741.0, 130.0, 42.0)
const SKILL_TWO_RECT := Rect2(718.0, 741.0, 130.0, 42.0)
const SHOT_RECT := Rect2(752.0, 535.0, 90.0, 90.0)
const PASS_RECT := Rect2(653.0, 570.0, 58.0, 58.0)
const STEAL_RECT := Rect2(716.0, 570.0, 58.0, 58.0)
const SPRINT_RECT := Rect2(590.0, 570.0, 58.0, 58.0)
const JOYSTICK_RECT := Rect2(58.0, 527.0, 122.0, 122.0)

var font: Font
var court_texture: Texture2D = preload("res://assets/generated-rooftop-court-v2.png")
var player_texture: Texture2D = preload("res://assets/generated-white-cat.png")
var opponent_texture: Texture2D = preload("res://assets/generated-calico-cat.png")
var title_emblem_texture: Texture2D = preload("res://assets/generated-title-emblem.png")
var feature_texture: Texture2D = preload("res://assets/generated-feature-icons-v2.png")
var skill_texture: Texture2D = preload("res://assets/generated-skill-sheet.png")
var mode_texture: Texture2D = preload("res://assets/generated-mode-sheet.png")
var progression_texture: Texture2D = preload("res://assets/generated-progression-badges.png")
var equipment_texture: Texture2D = preload("res://assets/generated-equipment-sheet.png")
var shooting_guide_texture: Texture2D = preload("res://assets/generated-shooting-guide.png")
var maid_texture: Texture2D = preload("res://assets/blue-maid.png")
var generated_art := true
var running := false
var game_over := false
var help_visible := false
var muted := false
var elapsed := 0.0
var time_left := 90.0
var score_player := 0
var score_opponent := 0
var energy := 68.0
var stamina := 86.0
var possession := "player"
var mode := "quick"
var mode_name := "快速比賽"
var period := 1

var player := {"x": 302.0, "y": 565.0, "facing": 1.0, "bob": 0.0, "dash": 0.0}
var opponent := {"x": 570.0, "y": 557.0, "facing": -1.0, "bob": 0.0, "dash": 0.0}
var ball := {"x": 329.0, "y": 487.0, "spin": 0.0, "in_flight": false, "loose": false, "vx": 0.0, "vy": 0.0, "bounces": 0}
var flight := {}

var charging := false
var charge := 0.16
var charge_direction := 1.0
var shot_cooldown := 0.0
var opponent_think := 1.5
var opponent_shot_cooldown := 0.0
var next_shot_bonus := 0.0
var sprinting := false
var joystick_active := false
var joystick := Vector2.ZERO
var mouse_design := Vector2.ZERO
var message := "球場已準備好，按下開始比賽！"
var message_timer := 2.0
var skill_flash := ""
var skill_flash_timer := 0.0
var drawing_scale := 1.0
var drawing_offset := Vector2.ZERO
var particles: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var rings: Array[Dictionary] = []

var mode_data := {
	"quick": {"name": "快速比賽", "duration": 90.0, "target": 11, "opponent_accuracy": .46, "opponent_speed": 148.0, "shot_bonus": .04, "tag": "快速比賽 · 先得 11 分"},
	"story": {"name": "故事模式", "duration": 105.0, "target": 15, "opponent_accuracy": .50, "opponent_speed": 156.0, "shot_bonus": .02, "tag": "故事模式 · 街區 15 分戰"},
	"challenge": {"name": "挑戰模式", "duration": 60.0, "target": 18, "opponent_accuracy": .55, "opponent_speed": 166.0, "shot_bonus": -.02, "tag": "挑戰模式 · 60 秒得 18 分"},
	"boss": {"name": "Boss 挑戰", "duration": 120.0, "target": 21, "opponent_accuracy": .67, "opponent_speed": 183.0, "shot_bonus": -.05, "tag": "Boss 挑戰 · 決戰 21 分"}
}

var skyline := [
	{"x": 42.0, "w": 72.0, "h": 108.0}, {"x": 110.0, "w": 52.0, "h": 75.0},
	{"x": 164.0, "w": 89.0, "h": 133.0}, {"x": 257.0, "w": 62.0, "h": 91.0},
	{"x": 326.0, "w": 112.0, "h": 150.0}, {"x": 446.0, "w": 67.0, "h": 88.0},
	{"x": 518.0, "w": 83.0, "h": 126.0}, {"x": 608.0, "w": 60.0, "h": 95.0},
	{"x": 674.0, "w": 95.0, "h": 144.0}, {"x": 777.0, "w": 66.0, "h": 102.0}
]

func _ready() -> void:
	font = ThemeDB.fallback_font
	generated_art = not OS.has_feature("headless")
	get_viewport().size_changed.connect(queue_redraw)
	reset_game(false)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.05)
	if running:
		update_game(dt)
	else:
		message_timer = max(0.0, message_timer - dt)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_design = screen_to_design(event.position)
		queue_redraw()
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_H:
				toggle_help()
			elif key_event.keycode == KEY_ENTER:
				if help_visible:
					help_visible = false
					return
				if game_over:
					restart_match()
				else:
					toggle_start()
			elif key_event.keycode == KEY_1:
				request_mode("quick")
			elif key_event.keycode == KEY_2:
				request_mode("story")
			elif key_event.keycode == KEY_3:
				request_mode("challenge")
			elif key_event.keycode == KEY_4:
				request_mode("boss")
			elif key_event.keycode == KEY_SPACE:
				begin_shot()
			elif key_event.keycode == KEY_Q:
				trigger_skill("火焰灌籃")
			elif key_event.keycode == KEY_E:
				trigger_skill("後撤步三分")
			elif key_event.keycode == KEY_R:
				trigger_skill("幻影變向")
			elif key_event.keycode == KEY_F:
				trigger_skill("流星投籃")
			elif key_event.keycode == KEY_ESCAPE:
				if help_visible:
					help_visible = false
				else:
					running = false
		elif not key_event.pressed and key_event.keycode == KEY_SPACE:
			release_shot()
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		var p := screen_to_design(mouse_event.position)
		if mouse_event.pressed:
			if help_visible:
				if HELP_CLOSE_RECT.has_point(p) or not Rect2(389.0, 180.0, 502.0, 398.0).has_point(p):
					help_visible = false
				return
			if HELP_RECT.has_point(p):
				toggle_help()
			elif MUTE_RECT.has_point(p):
				muted = not muted
				show_message("音效已關閉" if muted else "音效已開啟", 1.0)
			elif game_over and REPLAY_RECT.has_point(p):
				restart_match()
			elif MODE_RECT.has_point(p):
				cycle_mode()
			elif START_RECT.has_point(p):
				toggle_start()
			elif RESET_RECT.has_point(p):
				reset_game()
			elif SHOT_RECT.has_point(p):
				begin_shot()
			elif PASS_RECT.has_point(p):
				perform_pass()
			elif STEAL_RECT.has_point(p):
				attempt_steal()
			elif SPRINT_RECT.has_point(p):
				sprinting = true
			elif SKILL_ONE_RECT.has_point(p):
				trigger_skill("火焰灌籃")
			elif SKILL_TWO_RECT.has_point(p):
				trigger_skill("後撤步三分")
			elif JOYSTICK_RECT.has_point(p):
				joystick_active = true
				update_joystick(p)
		else:
			release_shot()
			sprinting = false
			if joystick_active:
				joystick_active = false
				joystick = Vector2.ZERO
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var p := screen_to_design(touch.position)
		if touch.pressed:
			if help_visible:
				if HELP_CLOSE_RECT.has_point(p) or not Rect2(389.0, 180.0, 502.0, 398.0).has_point(p):
					help_visible = false
				return
			if HELP_RECT.has_point(p):
				toggle_help()
			elif MUTE_RECT.has_point(p):
				muted = not muted
			elif game_over and REPLAY_RECT.has_point(p):
				restart_match()
			elif MODE_RECT.has_point(p):
				cycle_mode()
			elif SHOT_RECT.has_point(p):
				begin_shot()
			elif PASS_RECT.has_point(p):
				perform_pass()
			elif STEAL_RECT.has_point(p):
				attempt_steal()
			elif SPRINT_RECT.has_point(p):
				sprinting = true
			elif SKILL_ONE_RECT.has_point(p):
				trigger_skill("火焰灌籃")
			elif SKILL_TWO_RECT.has_point(p):
				trigger_skill("後撤步三分")
			elif JOYSTICK_RECT.has_point(p):
				joystick_active = true
				update_joystick(p)
		else:
			release_shot()
			sprinting = false
			joystick_active = false
			joystick = Vector2.ZERO
		return

	if event is InputEventScreenDrag and joystick_active:
		var drag := event as InputEventScreenDrag
		update_joystick(screen_to_design(drag.position))


func screen_to_design(screen_pos: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale: float = minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset: Vector2 = (viewport_size - DESIGN_SIZE * scale) * 0.5
	return (screen_pos - offset) / scale


func update_game(dt: float) -> void:
	elapsed += dt
	time_left -= dt
	shot_cooldown = max(0.0, shot_cooldown - dt)
	opponent_shot_cooldown = max(0.0, opponent_shot_cooldown - dt)
	player["dash"] = max(0.0, player["dash"] - dt)
	opponent["dash"] = max(0.0, opponent["dash"] - dt)
	skill_flash_timer = max(0.0, skill_flash_timer - dt)
	message_timer = max(0.0, message_timer - dt)

	update_player(dt)
	update_opponent(dt)
	update_charge(dt)
	update_ball(dt)
	update_loose_ball(dt)
	update_ai(dt)
	update_effects(dt)
	var total_duration: float = maxf(1.0, float(mode_data[mode]["duration"]))
	period = clampi(int(((total_duration - maxf(0.0, time_left)) / total_duration) * 4.0) + 1, 1, 4)

	if time_left <= 0.0:
		end_game()
	elif score_player >= int(mode_data[mode]["target"]) or score_opponent >= int(mode_data[mode]["target"]):
		end_game()


func update_player(dt: float) -> void:
	var axis := Vector2.ZERO
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		axis.x += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		axis.x -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		axis.y += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		axis.y -= 1.0
	axis += joystick
	if axis.length() > 1.0:
		axis = axis.normalized()

	var sprint_key := Input.is_key_pressed(KEY_SHIFT)
	var wants_sprint := (sprint_key or sprinting) and axis.length() > 0.05 and stamina > 0.0
	var speed := 380.0 if wants_sprint else 240.0
	if wants_sprint:
		stamina = max(0.0, stamina - dt * 20.0)
	else:
		stamina = min(100.0, stamina + dt * 8.0)
	player["x"] = clamp(float(player["x"]) + axis.x * speed * dt, 104.0, 702.0)
	player["y"] = clamp(float(player["y"]) + axis.y * speed * 0.38 * dt, 456.0, 576.0)
	if abs(axis.x) > 0.02:
		player["facing"] = 1.0 if axis.x > 0 else -1.0
	player["bob"] = float(player["bob"]) + dt * (14.0 if wants_sprint else 9.0 if axis.length() > .05 else 3.0)
	if float(player["dash"]) > 0.0:
		player["x"] = clamp(float(player["x"]) + float(player["facing"]) * 165.0 * dt, 104.0, 702.0)

	if possession == "player" and not bool(ball["in_flight"]):
		ball["x"] = float(player["x"]) + float(player["facing"]) * 26.0
		ball["y"] = float(player["y"]) - 75.0 + sin(elapsed * 10.0) * 6.0
		ball["loose"] = false


func update_opponent(dt: float) -> void:
	var target := Vector2(HOOP.x - 145.0, 520.0) if possession == "opponent" else Vector2(float(player["x"]) + 106.0, float(player["y"]) - 3.0)
	if bool(ball["loose"]):
		target = Vector2(float(ball["x"]), float(ball["y"]) + 62.0)
	var current := Vector2(float(opponent["x"]), float(opponent["y"]))
	var delta := target - current
	var dist: float = maxf(1.0, delta.length())
	var speed := float(mode_data[mode]["opponent_speed"])
	opponent["x"] = clamp(float(opponent["x"]) + delta.x / dist * speed * dt, 423.0, 810.0)
	opponent["y"] = clamp(float(opponent["y"]) + delta.y / dist * speed * 0.38 * dt, 456.0, 576.0)
	if abs(delta.x) > 2.0:
		opponent["facing"] = 1.0 if delta.x > 0 else -1.0
	opponent["bob"] = float(opponent["bob"]) + dt * (9.0 if dist > 25 else 3.0)
	if possession == "opponent" and not bool(ball["in_flight"]):
		ball["x"] = float(opponent["x"]) - float(opponent["facing"]) * 25.0
		ball["y"] = float(opponent["y"]) - 75.0 + sin(elapsed * 9.0 + 1.0) * 6.0
		ball["loose"] = false


func update_charge(dt: float) -> void:
	if not charging:
		return
	charge += charge_direction * dt * 1.45
	if charge >= 1.0:
		charge = 1.0
		charge_direction = -1.0
	if charge <= 0.12:
		charge = 0.12
		charge_direction = 1.0


func update_ball(dt: float) -> void:
	if not bool(ball["in_flight"]):
		return
	var t: float = minf(1.0, float(flight["t"]) + dt / float(flight["duration"]))
	flight["t"] = t
	var start: Vector2 = flight["start"]
	var target: Vector2 = flight["target"]
	ball["x"] = lerp(start.x, target.x, t)
	ball["y"] = lerp(start.y, target.y, t) - sin(t * PI) * float(flight["arc"])
	ball["spin"] = float(ball["spin"]) + dt * 15.0
	if float(flight["t"]) >= 1.0:
		ball["in_flight"] = false
		if String(flight["shooter"]) == "player":
			resolve_player_shot()
		else:
			resolve_opponent_shot()


func update_loose_ball(dt: float) -> void:
	if not bool(ball["loose"]) or bool(ball["in_flight"]):
		return
	ball["x"] = float(ball["x"]) + float(ball["vx"]) * dt
	ball["vy"] = float(ball["vy"]) + 360.0 * dt
	ball["y"] = float(ball["y"]) + float(ball["vy"]) * dt
	ball["vx"] = float(ball["vx"]) * pow(0.04, dt)
	ball["spin"] = float(ball["spin"]) + dt * 13.0
	if float(ball["y"]) >= FLOOR_Y - 22.0:
		ball["y"] = FLOOR_Y - 22.0
		ball["vy"] = float(ball["vy"]) * -0.47
		ball["vx"] = float(ball["vx"]) * 0.76
		ball["bounces"] = int(ball["bounces"]) + 1
		if int(ball["bounces"]) >= 2:
			var pd := Vector2(float(player["x"]), float(player["y"])).distance_to(Vector2(float(ball["x"]), float(ball["y"])))
			var od := Vector2(float(opponent["x"]), float(opponent["y"])).distance_to(Vector2(float(ball["x"]), float(ball["y"])))
			if pd < od and pd < 120.0:
				set_possession("player")
			elif od < 120.0:
				set_possession("opponent")


func update_ai(dt: float) -> void:
	if possession != "opponent" or bool(ball["in_flight"]):
		return
	if opponent_shot_cooldown > 0.0:
		return
	opponent_think -= dt
	if opponent_think > 0.0:
		return
	opponent_think = 1.4 + randf() * 1.5
	if abs(HOOP.x - float(opponent["x"])) < 500.0:
		opponent_shot_cooldown = 1.2
		shoot_for_opponent()
	else:
		opponent["dash"] = .35


func update_effects(dt: float) -> void:
	for particle in particles:
		particle["life"] = float(particle["life"]) - dt
		particle["x"] = float(particle["x"]) + float(particle["vx"]) * dt
		particle["y"] = float(particle["y"]) + float(particle["vy"]) * dt
		particle["vy"] = float(particle["vy"]) + float(particle["gravity"]) * dt
	for floater in floaters:
		floater["life"] = float(floater["life"]) - dt
		floater["y"] = float(floater["y"]) - dt * 31.0
	for ring in rings:
		ring["life"] = float(ring["life"]) - dt
		ring["radius"] = float(ring["radius"]) + dt * float(ring["speed"])
	particles = particles.filter(func(p): return float(p["life"]) > 0.0)
	floaters = floaters.filter(func(f): return float(f["life"]) > 0.0)
	rings = rings.filter(func(r): return float(r["life"]) > 0.0)


func begin_shot() -> void:
	if not running:
		show_message("先按「開始比賽」再上場！", 1.2)
		return
	if possession != "player":
		show_message("先把球搶回來！", 1.1)
		return
	if bool(ball["in_flight"]) or shot_cooldown > 0.0 or charging:
		return
	charging = true
	charge = 0.16
	charge_direction = 1.0
	show_message("蓄力瞄準中 · 放開出手", 0.5)


func release_shot(force_charge: float = -1.0) -> void:
	if not charging:
		return
	charging = false
	if possession != "player" or bool(ball["in_flight"]):
		return
	var final_charge: float = charge if force_charge < 0.0 else force_charge
	var distance_to_hoop: float = absf(HOOP.x - float(player["x"]))
	var duration: float = clampf(0.70 + distance_to_hoop / 1450.0, 0.72, 1.20)
	flight = {
		"shooter": "player", "start": Vector2(float(player["x"]) + float(player["facing"]) * 25.0, float(player["y"]) - 80.0),
		"target": Vector2(HOOP.x, RIM_Y - 12.0), "arc": 108.0 + final_charge * 47.0,
		"duration": duration, "t": 0.0, "charge": final_charge, "distance": distance_to_hoop
	}
	ball["in_flight"] = true
	ball["loose"] = false
	possession = "none"
	shot_cooldown = .45
	add_floater("甜蜜點！" if final_charge >= .61 and final_charge <= .83 else "出手！", float(player["x"]), float(player["y"]) - 130.0, GREEN if final_charge >= .61 and final_charge <= .83 else BLUE_LIGHT)


func shoot_for_opponent() -> void:
	var distance_to_hoop: float = absf(HOOP.x - float(opponent["x"]))
	flight = {
		"shooter": "opponent", "start": Vector2(float(opponent["x"]) - 25.0, float(opponent["y"]) - 78.0),
		"target": Vector2(HOOP.x, RIM_Y - 12.0), "arc": 118.0, "duration": clamp(.78 + distance_to_hoop / 1600.0, .8, 1.22),
		"t": 0.0, "charge": .72, "distance": distance_to_hoop
	}
	ball["in_flight"] = true
	ball["loose"] = false
	possession = "none"
	add_floater("喵布布出手", float(opponent["x"]), float(opponent["y"]) - 124.0, Color("ffb4bf"))


func resolve_player_shot() -> void:
	var sweet: float = 1.0 - minf(1.0, absf(float(flight["charge"]) - .72) / .72)
	var distance_bonus: float = clampf(1.0 - absf(float(flight["distance"]) - 535.0) / 800.0, .35, 1.0)
	var chance: float = clampf(.18 + sweet * .68 + distance_bonus * .08 + next_shot_bonus + float(mode_data[mode]["shot_bonus"]), .08, .96)
	var made: bool = sweet > .84 or randf() < chance
	next_shot_bonus = 0.0
	if made:
		var points := 3 if float(flight["distance"]) > 535.0 else 2
		score_player += points
		energy = clamp(energy + 12.0, 0.0, 100.0)
		rings.append({"x": HOOP.x, "y": RIM_Y, "radius": 18.0, "speed": 115.0, "life": .7, "max_life": .7, "color": BLUE_LIGHT if points == 3 else GOLD})
		burst(HOOP.x, RIM_Y, BLUE_LIGHT if points == 3 else GOLD, 25 if points == 3 else 18)
		add_floater("+%d  %s" % [points, "三分命中！" if points == 3 else "漂亮！"], HOOP.x - 35.0, RIM_Y - 52.0, BLUE_LIGHT if points == 3 else GOLD)
		show_message("🌟 三分命中！" if points == 3 else "🏀 兩分拿下！", 1.8)
		reset_after_score("opponent")
	else:
		add_floater("籃框彈出", HOOP.x - 27.0, RIM_Y - 43.0, Color("ffb0b9"))
		show_message("差一點！調整蓄力再試一次。", 1.4)
		make_loose_ball(HOOP.x - 12.0, RIM_Y + 12.0, -150.0, -205.0)


func resolve_opponent_shot() -> void:
	var made := randf() < float(mode_data[mode]["opponent_accuracy"])
	if made:
		var points := 3 if float(flight["distance"]) > 535.0 else 2
		score_opponent += points
		rings.append({"x": HOOP.x, "y": RIM_Y, "radius": 18.0, "speed": 108.0, "life": .6, "max_life": .6, "color": RED})
		burst(HOOP.x, RIM_Y, Color("ff94a6"), 15)
		add_floater("喵布布 +%d" % points, HOOP.x - 42.0, RIM_Y - 50.0, Color("ffb8c4"))
		show_message("喵布布命中 %d 分" % points, 1.4)
		reset_after_score("player")
	else:
		make_loose_ball(HOOP.x - 12.0, RIM_Y + 12.0, -120.0, -180.0)
		show_message("對手投丟了，快搶籃板！", 1.2)


func make_loose_ball(x: float, y: float, vx: float, vy: float) -> void:
	ball["x"] = x
	ball["y"] = y
	ball["vx"] = vx
	ball["vy"] = vy
	ball["bounces"] = 0
	ball["in_flight"] = false
	ball["loose"] = true
	possession = "none"


func set_possession(who: String) -> void:
	possession = who
	ball["loose"] = false
	ball["bounces"] = 0
	ball["vx"] = 0.0
	ball["vy"] = 0.0
	if who == "player":
		ball["x"] = float(player["x"]) + float(player["facing"]) * 26.0
		ball["y"] = float(player["y"]) - 75.0
	else:
		ball["x"] = float(opponent["x"]) - float(opponent["facing"]) * 25.0
		ball["y"] = float(opponent["y"]) - 75.0


func reset_after_score(next_possession: String) -> void:
	ball["in_flight"] = false
	ball["loose"] = false
	player["x"] = 302.0
	player["y"] = 565.0
	opponent["x"] = 570.0
	opponent["y"] = 557.0
	set_possession(next_possession)


func attempt_steal() -> void:
	if not running:
		show_message("先開始比賽！", 1.1)
		return
	if possession != "opponent":
		show_message("現在是你的球權，往籃框切入！", 1.1)
		return
	if Vector2(float(player["x"]), float(player["y"])).distance_to(Vector2(float(opponent["x"]), float(opponent["y"]))) > 148.0:
		show_message("靠近喵布布再按抄球", 1.2)
		return
	player["dash"] = .18
	stamina = max(0.0, stamina - 8.0)
	if randf() < .68:
		set_possession("player")
		energy = clamp(energy + 8.0, 0.0, 100.0)
		burst(float(opponent["x"]), float(opponent["y"]) - 60.0, GREEN, 10)
		add_floater("抄球成功！", float(player["x"]), float(player["y"]) - 124.0, Color("a4ffc9"))
		show_message("✋ 抄球成功！", 1.3)
	else:
		show_message("差一點，抓準時機！", 1.1)


func perform_pass() -> void:
	if not running:
		show_message("先開始比賽！", 1.1)
		return
	if possession != "player" or bool(ball["in_flight"]):
		show_message("先把球控好再傳球", 1.1)
		return
	player["x"] = clamp(float(player["x"]) + float(player["facing"]) * 56.0, 104.0, 702.0)
	player["dash"] = .24
	stamina = max(0.0, stamina - 4.0)
	energy = clamp(energy + 3.0, 0.0, 100.0)
	burst(float(player["x"]) + float(player["facing"]) * 20.0, float(player["y"]) - 60.0, PURPLE, 7)
	add_floater("假傳變向！", float(player["x"]), float(player["y"]) - 118.0, Color("d4bcff"))
	show_message("🤝 假傳變向，甩開防守！", 1.2)


func trigger_skill(skill_name: String) -> void:
	if not running:
		show_message("先開始比賽！", 1.1)
		return
	var costs := {"火焰灌籃": 34.0, "後撤步三分": 28.0, "幻影變向": 22.0, "流星投籃": 40.0}
	var cost: float = costs.get(skill_name, 25.0)
	if energy < cost:
		show_message("能量不足，需要 %d%%" % int(cost), 1.2)
		return
	energy -= cost
	skill_flash = skill_name
	skill_flash_timer = .75
	if skill_name == "火焰灌籃":
		player["dash"] = .6
		player["x"] = clamp(HOOP.x - 165.0, 104.0, 702.0)
		burst(float(player["x"]), float(player["y"]) - 70.0, Color("ff9c4a"), 20)
		if possession == "player" and not bool(ball["in_flight"]):
			flight = {"shooter": "player", "start": Vector2(float(player["x"]) + 25.0, float(player["y"]) - 78.0), "target": Vector2(HOOP.x, RIM_Y - 13.0), "arc": 100.0, "duration": .68, "t": 0.0, "charge": .74, "distance": abs(HOOP.x - float(player["x"]))}
			ball["in_flight"] = true
			possession = "none"
		show_message("🔥 火焰灌籃！", 1.5)
	elif skill_name == "後撤步三分":
		player["x"] = clamp(float(player["x"]) - 110.0, 104.0, 702.0)
		player["dash"] = .25
		next_shot_bonus = .2
		burst(float(player["x"]), float(player["y"]) - 58.0, BLUE_LIGHT, 13)
		add_floater("三分加成 +25%", float(player["x"]), float(player["y"]) - 122.0, BLUE_LIGHT)
		show_message("💠 後撤步完成！下一球命中率提升", 1.7)
	elif skill_name == "幻影變向":
		player["dash"] = .65
		player["x"] = clamp(float(player["x"]) + float(player["facing"]) * 160.0, 104.0, 702.0)
		burst(float(player["x"]), float(player["y"]) - 55.0, PURPLE, 17)
		add_floater("幻影消失！", float(player["x"]), float(player["y"]) - 122.0, Color("e0c8ff"))
		show_message("🌀 幻影變向！防守失去目標", 1.5)
	else:
		if possession == "player" and not bool(ball["in_flight"]):
			charging = true
			release_shot(.72)
		burst(float(player["x"]), float(player["y"]) - 84.0, Color("ff9de8"), 18)
		show_message("☄️ 流星投籃！", 1.5)


func toggle_start() -> void:
	if game_over:
		restart_match()
		return
	running = not running
	if running:
		show_message("開球！喵白白，掌握節奏！", 1.4)
	else:
		show_message("比賽暫停", 1.2)


func toggle_help() -> void:
	help_visible = not help_visible
	if help_visible:
		running = false


func end_game() -> void:
	running = false
	game_over = true
	charging = false
	var won := score_player > score_opponent
	var tied := score_player == score_opponent
	show_message("🏆 勝利！喵白白稱霸球場！" if won else "平手！再來一場決勝負。" if tied else "終場！下一球一定更準。", 2.8)
	burst(HOOP.x, RIM_Y - 8.0, GOLD if won else BLUE_LIGHT, 32)


func reset_game(keep_mode: bool = true) -> void:
	if not keep_mode:
		mode = "quick"
		mode_name = "快速比賽"
	running = false
	game_over = false
	help_visible = false
	elapsed = 0.0
	time_left = float(mode_data[mode]["duration"])
	period = 1
	score_player = 0
	score_opponent = 0
	energy = 68.0
	stamina = 86.0
	possession = "player"
	player = {"x": 302.0, "y": 565.0, "facing": 1.0, "bob": 0.0, "dash": 0.0}
	opponent = {"x": 570.0, "y": 557.0, "facing": -1.0, "bob": 0.0, "dash": 0.0}
	ball = {"x": 329.0, "y": 487.0, "spin": 0.0, "in_flight": false, "loose": false, "vx": 0.0, "vy": 0.0, "bounces": 0}
	flight = {}
	charging = false
	charge = .16
	charge_direction = 1.0
	shot_cooldown = 0.0
	opponent_think = 1.5
	opponent_shot_cooldown = 0.0
	next_shot_bonus = 0.0
	sprinting = false
	joystick = Vector2.ZERO
	joystick_active = false
	particles.clear()
	floaters.clear()
	rings.clear()
	message = "球場已準備好，按下開始比賽！"
	message_timer = 2.0


func set_mode(next_mode: String) -> void:
	if not mode_data.has(next_mode):
		return
	if running:
		show_message("請先暫停比賽，再切換模式。", 1.2)
		return
	mode = next_mode
	mode_name = mode_data[next_mode]["name"]
	reset_game()
	show_message("已切換至%s" % mode_name, 1.3)


func request_mode(next_mode: String) -> void:
	if mode == next_mode and not game_over:
		return
	set_mode(next_mode)


func cycle_mode() -> void:
	if running:
		show_message("請先暫停比賽，再切換模式。", 1.2)
		return
	var mode_order := ["quick", "story", "challenge", "boss"]
	var current_index: int = mode_order.find(mode)
	var next_index: int = (current_index + 1) % mode_order.size() if current_index >= 0 else 0
	set_mode(String(mode_order[next_index]))


func restart_match() -> void:
	reset_game()
	running = true
	show_message("重新開球！喵白白，掌握節奏！", 1.4)


func show_message(value: String, duration: float = 1.5) -> void:
	message = value
	message_timer = duration


func burst(x: float, y: float, color: Color, count: int = 16) -> void:
	for i in count:
		var angle := randf() * TAU
		var speed := 45.0 + randf() * 145.0
		particles.append({"x": x, "y": y, "vx": cos(angle) * speed, "vy": sin(angle) * speed - 40.0, "gravity": 145.0, "life": .62 + randf() * .45, "max_life": 1.0, "size": 2.0 + randf() * 3.5, "color": color, "star": i % 3 == 0})


func add_floater(value: String, x: float, y: float, color: Color) -> void:
	floaters.append({"text": value, "x": x, "y": y, "life": 1.1, "max_life": 1.1, "color": color})


func update_joystick(point: Vector2) -> void:
	var center := JOYSTICK_RECT.position + JOYSTICK_RECT.size * .5
	var radius := JOYSTICK_RECT.size.x * .38
	var delta := point - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	joystick = delta / radius


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	drawing_scale = minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	drawing_offset = (viewport_size - DESIGN_SIZE * drawing_scale) * .5
	draw_set_transform(drawing_offset, 0.0, Vector2(drawing_scale, drawing_scale))
	draw_background()
	draw_header()
	draw_court_card()
	draw_right_rail()
	draw_bottom_cards()
	if game_over:
		draw_game_over_overlay()
	if help_visible:
		draw_help_overlay()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func panel(rect: Rect2, fill: Color, border: Color = Color("29426f"), radius: float = 16.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	draw_style_box(style, rect)


func label_text(value: String, position: Vector2, size: int, color: Color = TEXT) -> void:
	if font == null:
		return
	draw_string(font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func centered_text(value: String, center: Vector2, width: float, size: int, color: Color = TEXT) -> void:
	if font == null:
		return
	draw_string(font, Vector2(center.x - width * .5, center.y + size * .35), value, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)


func draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), NAVY_950)
	for i in 12:
		var t := float(i) / 11.0
		draw_rect(Rect2(0.0, t * 706.0, 1280.0, 66.0), Color(0.03 + t * .02, 0.07 + t * .03, 0.17 + t * .08, 1.0))
	# soft ambient lights
	draw_circle(Vector2(108.0, 270.0), 180.0, Color(0.07, 0.24, 0.60, .13))
	draw_circle(Vector2(1175.0, 558.0), 210.0, Color(0.42, 0.08, 0.40, .10))
	# stars
	for i in 46:
		var x := float((i * 83 + 29) % 1280)
		var y := float(88 + ((i * 47) % 220))
		var radius := 1.4 if i % 6 == 0 else .75
		draw_circle(Vector2(x, y), radius, Color(0.69, 0.83, 1.0, .25 + float(i % 4) * .1))


func draw_header() -> void:
	# Generated emblem echoes the reference logo while keeping the title text crisp.
	if generated_art and title_emblem_texture != null:
		draw_texture_rect(title_emblem_texture, Rect2(17.0, 8.0, 61.0, 61.0), false, Color.WHITE)
	else:
		panel(Rect2(24.0, 22.0, 49.0, 45.0), Color("2864d0"), Color("68b8ff"), 13.0)
		draw_circle(Vector2(48.5, 41.0), 8.0, Color("ffc867"))
		draw_circle(Vector2(39.0, 32.5), 4.0, Color("ffc867"))
		draw_circle(Vector2(48.5, 29.5), 4.0, Color("ffc867"))
		draw_circle(Vector2(58.0, 32.5), 4.0, Color("ffc867"))
	label_text("喵萌籃球大作戰", Vector2(85.0, 45.0), 26, TEXT)
	label_text("2D STREET HOOPS  ·  GODOT PLAYABLE PROTOTYPE", Vector2(87.0, 61.0), 9, Color("81a9df"))
	panel(Rect2(1001.0, 28.0, 118.0, 28.0), Color(0.11, 0.18, 0.36, .76), Color("2f5187"), 14.0)
	draw_circle(Vector2(1018.0, 42.0), 4.0, GREEN)
	label_text("遊戲原型 v0.2", Vector2(1028.0, 46.0), 10, Color("a9c3eb"))
	panel(Rect2(1128.0, 28.0, 42.0, 28.0), Color(0.11, 0.18, 0.36, .76), Color("2f5187"), 10.0)
	centered_text("🔊" if not muted else "🔇", Vector2(1149.0, 42.0), 42.0, 14, TEXT)
	panel(Rect2(1180.0, 28.0, 76.0, 28.0), Color(0.11, 0.18, 0.36, .76), Color("2f5187"), 10.0)
	centered_text("操作說明", Vector2(1218.0, 42.0), 76.0, 10, Color("bdd0ef"))


func draw_court_card() -> void:
	panel(COURT_RECT, Color(0.055, 0.10, 0.22, .9), Color("2e4a7e"), 20.0)
	label_text("●  NEON ROOFTOP · NIGHT COURT", Vector2(43.0, 127.0), 10, GREEN)
	label_text(String(mode_data[mode]["tag"]), Vector2(710.0, 127.0), 10, Color("88a5d6"))
	draw_mode_badge(Vector2(682.0, 121.0), mode)
	# score strip
	panel(Rect2(41.0, 139.0, 812.0, 42.0), Color(0.08, 0.15, 0.31, .88), Color("213d71"), 12.0)
	draw_circle(Vector2(62.0, 160.0), 13.0, BLUE)
	if generated_art:
		draw_cat_portrait(player_texture, Rect2(49.0, 147.0, 26.0, 26.0))
	else:
		centered_text("🐱", Vector2(62.0, 160.0), 25.0, 14, TEXT)
	label_text("P1 · 喵白白", Vector2(82.0, 156.0), 11, TEXT)
	label_text("BLUE PAWS", Vector2(82.0, 169.0), 7, Color("7d9bcc"))
	label_text("%02d" % score_player, Vector2(185.0, 169.0), 28, TEXT)
	centered_text("第 %d 節" % period, Vector2(438.0, 150.0), 90.0, 9, Color("8da7d2"))
	centered_text(format_time(time_left), Vector2(438.0, 169.0), 120.0, 20, TEXT)
	centered_text("進攻回合" if possession == "player" else "防守回合" if possession == "opponent" else "爭搶籃板", Vector2(438.0, 180.0), 120.0, 8, BLUE_LIGHT)
	label_text("%02d" % score_opponent, Vector2(670.0, 169.0), 28, TEXT)
	label_text("P2 · 喵布布", Vector2(711.0, 156.0), 11, TEXT)
	label_text("RED CLAWS", Vector2(711.0, 169.0), 7, Color("c48aa0"))
	draw_circle(Vector2(833.0, 160.0), 13.0, RED)
	if generated_art:
		draw_cat_portrait(opponent_texture, Rect2(820.0, 147.0, 26.0, 26.0))
	else:
		centered_text("🐈", Vector2(833.0, 160.0), 25.0, 14, TEXT)
	# world viewport
	draw_world()
	# footer inside court
	panel(Rect2(41.0, 646.0, 812.0, 34.0), Color(0.04, 0.08, 0.18, .72), Color("213d70"), 10.0)
	label_text("🎮  WASD 移動　·　Space 蓄力投籃　·　Shift 衝刺　·　Q/E/R/F 必殺　·　1-4 模式", Vector2(53.0, 667.0), 9, Color("90a8d0"))
	button_box(RESET_RECT, "重新開始", false)
	button_box(START_RECT, "Ⅱ  暫停比賽" if running else "▶  開始比賽", true)
	if message_timer > 0.0:
		panel(Rect2(278.0, 198.0, 310.0, 32.0), Color(0.04, 0.09, 0.20, .82), Color("426ca6"), 16.0)
		centered_text(message, Vector2(433.0, 214.0), 300.0, 10, TEXT)


func draw_mode_badge(center: Vector2, mode_key: String) -> void:
	var mode_index := 0
	if mode_key == "story":
		mode_index = 1
	elif mode_key == "challenge":
		mode_index = 2
	elif mode_key == "boss":
		mode_index = 3
	if generated_art and mode_texture != null:
		var mode_source := Rect2(float(mode_index % 2) * 627.0 + 8.0, float(mode_index / 2) * 627.0 + 8.0, 611.0, 611.0)
		draw_texture_rect_region(mode_texture, Rect2(center - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), mode_source, Color.WHITE)
	else:
		draw_circle(center, 14.0, GOLD if mode_index == 0 else BLUE_LIGHT)


func draw_cat_portrait(texture: Texture2D, rect: Rect2) -> void:
	if texture == null:
		return
	var source := Rect2(float(texture.get_width()) * .30, 0.0, float(texture.get_width()) * .50, float(texture.get_height()) * .46)
	draw_texture_rect_region(texture, rect, source, Color.WHITE)


func draw_equipment_item(rect: Rect2, column: int, row: int) -> void:
	if equipment_texture == null:
		return
	var cell_width := float(equipment_texture.get_width()) / 3.0
	var cell_height := float(equipment_texture.get_height()) / 2.0
	var source := Rect2(float(column) * cell_width + 12.0, float(row) * cell_height + 12.0, cell_width - 24.0, cell_height - 24.0)
	draw_texture_rect_region(equipment_texture, rect, source, Color.WHITE)


func draw_game_over_overlay() -> void:
	var result_text := "喵白白 勝利！" if score_player > score_opponent else "喵布布 勝利！" if score_opponent > score_player else "平手！"
	var result_color := GOLD if score_player >= score_opponent else RED
	panel(Rect2(254.0, 274.0, 418.0, 202.0), Color(0.025, .05, .13, .95), Color("79baff"), 20.0)
	centered_text("終場", Vector2(463.0, 304.0), 210.0, 13, BLUE_LIGHT)
	centered_text(result_text, Vector2(463.0, 333.0), 350.0, 23, result_color)
	centered_text("%02d  —  %02d" % [score_player, score_opponent], Vector2(463.0, 374.0), 280.0, 30, TEXT)
	centered_text(String(mode_data[mode]["name"]), Vector2(463.0, 401.0), 220.0, 9, MUTED)
	button_box(REPLAY_RECT, "↻  再來一場", true)


func draw_help_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.01, .02, .06, .72))
	panel(Rect2(389.0, 180.0, 502.0, 398.0), CREAM, Color("7fbaff"), 22.0)
	draw_rect(Rect2(390.0, 181.0, 500.0, 69.0), Color("1956ad"))
	label_text("操作說明", Vector2(424.0, 224.0), 25, Color.WHITE)
	label_text("先拿到 %d 分，或時間結束時領先即可獲勝" % int(mode_data[mode]["target"]), Vector2(424.0, 242.0), 9, Color("cfe3ff"))
	button_box(HELP_CLOSE_RECT, "關閉  ESC", false)
	var rows := [
		["移動", "WASD / 方向鍵", "在半場內自由走位，靠近籃框命中率更穩。"],
		["投籃", "按住 Space，放開出手", "讓蓄力停在綠色甜蜜點；遠距離可得三分。"],
		["衝刺", "Shift", "消耗體力快速切入；停止後會逐步恢復。"],
		["抄球 / 假傳", "右側綠色 / 紫色按鈕", "靠近持球對手再抄球，假傳可瞬間變向。"]
	]
	for i in rows.size():
		var row_y := 278.0 + float(i) * 55.0
		draw_circle(Vector2(427.0, row_y + 9.0), 15.0, Color("3c79ce"))
		centered_text(str(i + 1), Vector2(427.0, row_y + 9.0), 24.0, 9, Color.WHITE)
		label_text(String(rows[i][0]), Vector2(453.0, row_y + 5.0), 12, INK)
		label_text(String(rows[i][1]), Vector2(545.0, row_y + 5.0), 10, Color("2f6cb6"))
		label_text(String(rows[i][2]), Vector2(453.0, row_y + 23.0), 8, INK_MUTED)
	label_text("必殺技能", Vector2(424.0, 511.0), 12, INK)
	var skill_names := ["Q 火焰灌籃", "E 後撤步三分", "R 幻影變向", "F 流星投籃"]
	for i in 4:
		if generated_art and skill_texture != null:
			var skill_source := Rect2(float(i % 2) * 627.0 + 8.0, float(i / 2) * 627.0 + 8.0, 611.0, 611.0)
			draw_texture_rect_region(skill_texture, Rect2(424.0 + float(i) * 109.0, 520.0, 34.0, 34.0), skill_source, Color.WHITE)
		label_text(skill_names[i], Vector2(461.0 + float(i) * 109.0, 541.0), 8, INK)


func button_box(rect: Rect2, value: String, primary: bool) -> void:
	var hover := rect.has_point(mouse_design)
	var fill := Color("4f9cff") if primary else Color(0.14, 0.22, 0.42, .86)
	if hover:
		fill = fill.lightened(.12)
	panel(rect, fill, Color("9dd9ff") if primary else Color("4a6eaa"), 9.0)
	centered_text(value, rect.position + rect.size * .5, rect.size.x, 10, NAVY_950 if primary else Color("b9cae7"))


func draw_world() -> void:
	if generated_art and court_texture != null:
		# The generated plate supplies the neon skyline, lamps and court texture.
		draw_texture_rect(court_texture, WORLD_RECT, false, Color(1.0, 1.0, 1.0, .96))
		# Keep a restrained tint so HUD elements still read against the artwork.
		draw_rect(WORLD_RECT, Color(0.02, 0.04, 0.12, .08))
	else:
		# sky and skyline
		draw_rect(Rect2(WORLD_RECT.position, Vector2(WORLD_RECT.size.x, 210.0)), Color("102b52"))
		draw_circle(Vector2(707.0, 247.0), 47.0, Color(0.97, 0.83, 0.58, .10))
		draw_circle(Vector2(707.0, 247.0), 15.0, Color("ffeab3"))
		for index in skyline.size():
			var building: Dictionary = skyline[index]
			var bx: float = float(building["x"]) + 40.0
			var by: float = 394.0 - float(building["h"])
			var bw: float = float(building["w"])
			draw_rect(Rect2(bx, by, bw, float(building["h"]) + 16.0), Color("162e54") if index % 2 == 0 else Color("19355e"))
			for row in int(float(building["h"]) / 24.0):
				for col in int(max(1.0, bw / 18.0)):
					if (row * 3 + col + index) % 4 == 0:
						draw_rect(Rect2(bx + 8.0 + col * 17.0, by + 12.0 + row * 22.0, 5.0, 7.0), Color(1.0, .76, .38, .55))
		# fence
		draw_rect(Rect2(40.0, 375.0, 814.0, 65.0), Color(0.04, 0.11, 0.19, .5))
		for x in range(40, 855, 18):
			draw_line(Vector2(x, 375.0), Vector2(x + 34.0, 440.0), Color(0.13, .23, .34, .65), 1.0)
			draw_line(Vector2(x + 34.0, 375.0), Vector2(x, 440.0), Color(0.13, .23, .34, .65), 1.0)
		for y in [376.0, 407.0, 439.0]:
			draw_line(Vector2(40.0, y), Vector2(854.0, y), Color(0.56, .70, .77, .28), 2.0)
		# floor
		draw_rect(Rect2(40.0, 439.0, 814.0, 203.0), Color("9a7156"))
		for i in 7:
			var y := 444.0 + i * 29.0
			draw_line(Vector2(40.0, y), Vector2(854.0, y + 16.0), Color(1.0, .87, .64, .18), 2.0)
		for x in range(-100, 950, 108):
			draw_line(Vector2(x, 438.0), Vector2(x + 100.0, 642.0), Color(0.18, .10, .14, .19), 1.0)
		# markings
		draw_arc(Vector2(624.0, FLOOR_Y), 94.0, -PI * .5, PI * .5, 32, Color(1.0, .94, .78, .75), 3.0)
		draw_arc(Vector2(530.0, FLOOR_Y), 166.0, -PI * .5, PI * .5, 40, Color(1.0, .94, .78, .30), 2.0)
		draw_line(Vector2(624.0, 439.0), Vector2(624.0, FLOOR_Y + 3.0), Color(1.0, .94, .78, .62), 3.0)
		draw_arc(Vector2(530.0, FLOOR_Y), 46.0, 0.0, TAU, 24, Color(1.0, .94, .78, .68), 3.0)
		# graffiti and lamps remain useful in the vector fallback only.
		label_text("PAW", Vector2(58.0, 490.0), 22, Color(0.94, .67, .44, .55))
		label_text("HOOPS", Vector2(52.0, 515.0), 17, Color(0.94, .67, .44, .48))
		for x in [74.0, 410.0, 824.0]:
			draw_line(Vector2(x, 320.0), Vector2(x, 378.0), Color(0.08, .13, .20, .9), 5.0)
			draw_circle(Vector2(x, 318.0), 34.0, Color(1.0, .83, .48, .07))
			draw_oval(Vector2(x, 317.0), 14.0, 5.0, Color("fff0b9"))
	draw_hoop()
	draw_aim_guide()
	draw_cat(Vector2(float(player["x"]), float(player["y"])), "blue", float(player["facing"]), float(player["bob"]), possession == "player")
	draw_cat(Vector2(float(opponent["x"]), float(opponent["y"])), "red", float(opponent["facing"]), float(opponent["bob"]), possession == "opponent")
	var tag_lift := 244.0 if generated_art else 175.0
	draw_tag(Vector2(float(player["x"]), float(player["y"]) - tag_lift), "P1", BLUE, possession == "player")
	draw_tag(Vector2(float(opponent["x"]), float(opponent["y"]) - tag_lift), "P2", RED, possession == "opponent")
	draw_ball()
	draw_mobile_controls()
	draw_effects()


func draw_oval(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)


func draw_hoop() -> void:
	draw_line(Vector2(812.0, 439.0), Vector2(812.0, 229.0), Color(0.08, .13, .19, .95), 9.0)
	draw_line(Vector2(812.0, 229.0), Vector2(766.0, 214.0), Color(0.08, .13, .19, .95), 5.0)
	var board := PackedVector2Array([Vector2(721.0, 221.0), Vector2(793.0, 202.0), Vector2(793.0, 315.0), Vector2(721.0, 332.0)])
	draw_colored_polygon(board, Color(0.82, .89, .92, .87))
	draw_polyline(PackedVector2Array([board[0], board[1], board[2], board[3], board[0]]), Color(0.11, .16, .25, .9), 4.0)
	draw_rect(Rect2(736.0, 244.0, 45.0, 45.0), Color(0.10, .16, .25, .78), false, 3.0)
	draw_circle(HOOP, 40.0, Color(1.0, .57, .16, .06))
	draw_arc(HOOP, 28.0, 0.0, TAU, 32, Color("e87426"), 5.0)
	for i in range(-3, 4):
		draw_line(Vector2(HOOP.x + i * 7.0, RIM_Y + 4.0), Vector2(HOOP.x + i * 4.5, RIM_Y + 41.0), Color(1.0, .92, .86, .72), 1.5)
	draw_arc(Vector2(HOOP.x, RIM_Y + 3.0), 31.0, 0.0, PI, 20, Color(1.0, .92, .86, .72), 1.5)


func draw_aim_guide() -> void:
	if not charging or possession != "player":
		return
	var start := Vector2(float(player["x"]) + float(player["facing"]) * 26.0, float(player["y"]) - 78.0)
	var control := Vector2((start.x + HOOP.x) * .5, start.y - 160.0 - charge * 42.0)
	var previous := start
	for i in range(1, 19):
		var t := float(i) / 18.0
		var point := start.lerp(control, t).lerp(control.lerp(Vector2(HOOP.x, RIM_Y - 12.0), t), t)
		if i % 2 == 0:
			draw_line(previous, point, Color(0.73, .88, 1.0, .55), 2.0)
		previous = point
	draw_circle(HOOP, 34.0, Color(0.35, .92, .64, .10))
	# in-canvas power bar
	var meter_rect := Rect2(float(player["x"]) - 48.0, float(player["y"]) - 170.0, 96.0, 9.0)
	panel(meter_rect, Color(0.02, .05, .12, .86), Color("47628f"), 4.0)
	draw_rect(Rect2(meter_rect.position + Vector2(2.0, 2.0), Vector2(92.0 * charge, 5.0)), Color("67d79b"))
	centered_text("POWER", Vector2(meter_rect.position.x + 48.0, meter_rect.position.y - 6.0), 80.0, 8, Color(0.86, .95, .88, .9))


func draw_tag(position: Vector2, value: String, color: Color, active: bool) -> void:
	var fill := color if active else color.darkened(.25)
	panel(Rect2(position.x - 18.0, position.y, 36.0, 21.0), fill, Color(1.0, 1.0, 1.0, .25), 6.0)
	centered_text(value, position + Vector2(0.0, 10.0), 36.0, 10, Color.WHITE)


func draw_cat(position: Vector2, team: String, facing: float, bob: float, active: bool) -> void:
	var is_blue := team == "blue"
	var main := BLUE.darkened(.20) if is_blue else RED.darkened(.10)
	var light := BLUE_LIGHT if is_blue else Color("ff9a84")
	var dark := Color("1c3b88") if is_blue else Color("742447")
	var skin := Color("fff5e8") if is_blue else Color("f8ede2")
	var bounce := sin(bob) * (2.4 if active else 1.2)
	draw_set_transform(drawing_offset + (position + Vector2(0.0, bounce)) * drawing_scale, 0.0, Vector2(facing * drawing_scale, drawing_scale))
	if generated_art:
		var cat_texture: Texture2D = player_texture if is_blue else opponent_texture
		# The generated cutouts carry the detailed fur, uniforms, shoes and ball.
		draw_oval(Vector2(0.0, 3.0), 78.0, 13.0, Color(0.02, .03, .08, .42))
		draw_texture_rect(cat_texture, Rect2(-112.0, -240.0, 224.0, 240.0), false, Color.WHITE)
		if active:
			draw_arc(Vector2(0.0, -112.0), 119.0, 0.0, TAU, 36, Color(0.40, .80, 1.0, .72) if is_blue else Color(1.0, .55, .52, .72), 2.0)
		draw_set_transform(drawing_offset, 0.0, Vector2(drawing_scale, drawing_scale))
		return
	draw_oval(Vector2(0.0, 4.0), 47.0, 9.0, Color(0.04, .03, .08, .37))
	# tail
	draw_arc(Vector2(-26.0, -77.0), 34.0, -2.4, .55, 20, skin, 12.0)
	draw_arc(Vector2(-26.0, -77.0), 34.0, -2.4, .55, 20, dark, 3.0)
	# legs and shoes
	panel(Rect2(-23.0, -48.0, 15.0, 37.0), skin, Color(1.0, 1.0, 1.0, .13), 6.0)
	panel(Rect2(8.0, -48.0, 15.0, 37.0), skin, Color(1.0, 1.0, 1.0, .13), 6.0)
	panel(Rect2(-29.0, -17.0, 28.0, 13.0), dark, Color(1.0, 1.0, 1.0, .16), 5.0)
	panel(Rect2(6.0, -17.0, 28.0, 13.0), dark, Color(1.0, 1.0, 1.0, .16), 5.0)
	draw_line(Vector2(-24.0, -14.0), Vector2(-8.0, -14.0), Color(1.0, 1.0, 1.0, .55), 2.0)
	draw_line(Vector2(12.0, -14.0), Vector2(28.0, -14.0), Color(1.0, 1.0, 1.0, .55), 2.0)
	# jersey
	var body := PackedVector2Array([Vector2(-34.0, -116.0), Vector2(-22.0, -127.0), Vector2(22.0, -127.0), Vector2(34.0, -116.0), Vector2(27.0, -48.0), Vector2(-27.0, -48.0)])
	draw_colored_polygon(body, main)
	draw_line(Vector2(-27.0, -112.0), Vector2(-23.0, -52.0), Color(1.0, 1.0, 1.0, .45), 2.0)
	draw_line(Vector2(27.0, -112.0), Vector2(23.0, -52.0), Color(1.0, 1.0, 1.0, .45), 2.0)
	centered_text("23", Vector2(0.0, -78.0), 34.0, 17, Color(1.0, 1.0, 1.0, .88))
	# arms
	draw_line(Vector2(27.0, -105.0), Vector2(49.0, -72.0), skin, 12.0)
	draw_line(Vector2(-27.0, -105.0), Vector2(-49.0, -78.0), skin, 12.0)
	# head and ears
	draw_circle(Vector2(0.0, -149.0), 31.0, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-28.0, -166.0), Vector2(-24.0, -196.0), Vector2(-3.0, -172.0)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(28.0, -166.0), Vector2(24.0, -196.0), Vector2(3.0, -172.0)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-22.0, -170.0), Vector2(-20.0, -186.0), Vector2(-8.0, -173.0)]), Color("e8a0a9"))
	draw_colored_polygon(PackedVector2Array([Vector2(22.0, -170.0), Vector2(20.0, -186.0), Vector2(8.0, -173.0)]), Color("e8a0a9"))
	# hair / calico patch
	draw_arc(Vector2(0.0, -164.0), 27.0, PI, TAU, 20, light, 8.0)
	if not is_blue:
		draw_colored_polygon(PackedVector2Array([Vector2(2.0, -181.0), Vector2(17.0, -168.0), Vector2(6.0, -159.0)]), Color("f18b3c"))
	# eyes and face
	draw_circle(Vector2(-11.0, -150.0), 5.0, Color("1b1b2b"))
	draw_circle(Vector2(11.0, -150.0), 5.0, Color("1b1b2b"))
	draw_circle(Vector2(-9.0, -152.0), 1.6, Color.WHITE)
	draw_circle(Vector2(13.0, -152.0), 1.6, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(-3.0, -138.0), Vector2(3.0, -138.0), Vector2(0.0, -133.0)]), Color("ec8b8b"))
	draw_arc(Vector2(0.0, -132.0), 9.0, .2, PI - .2, 8, Color(0.35, .17, .25, .65), 1.2)
	draw_line(Vector2(-8.0, -138.0), Vector2(-39.0, -144.0), Color(1.0, 1.0, 1.0, .63), 1.0)
	draw_line(Vector2(-8.0, -133.0), Vector2(-40.0, -133.0), Color(1.0, 1.0, 1.0, .63), 1.0)
	draw_line(Vector2(8.0, -138.0), Vector2(39.0, -144.0), Color(1.0, 1.0, 1.0, .63), 1.0)
	draw_line(Vector2(8.0, -133.0), Vector2(40.0, -133.0), Color(1.0, 1.0, 1.0, .63), 1.0)
	if active:
		draw_arc(Vector2(0.0, -93.0), 47.0, 0.0, TAU, 28, Color(0.40, .80, 1.0, .85) if is_blue else Color(1.0, .55, .52, .85), 1.5)
	draw_set_transform(drawing_offset, 0.0, Vector2(drawing_scale, drawing_scale))


func draw_ball() -> void:
	if generated_art and not bool(ball["in_flight"]) and not bool(ball["loose"]):
		# The generated player cutouts already include a hand-held ball.
		return
	var p := Vector2(float(ball["x"]), float(ball["y"]))
	draw_circle(p, 28.0, Color(1.0, .58, .20, .08))
	draw_circle(p, 15.0, Color("ed7f29"))
	draw_arc(p, 14.0, -.9, .9, 16, Color(0.38, .13, .08, .75), 1.7)
	draw_arc(p, 14.0, PI - .9, PI + .9, 16, Color(0.38, .13, .08, .75), 1.7)
	draw_arc(p, 14.0, .2, PI - .2, 16, Color(0.38, .13, .08, .75), 1.7)


func draw_mobile_controls() -> void:
	# Always visible but subtle on desktop; it becomes the touch HUD on mobile.
	var joy_center := JOYSTICK_RECT.position + JOYSTICK_RECT.size * .5
	draw_circle(joy_center, 58.0, Color(0.70, .82, .98, .07))
	draw_arc(joy_center, 58.0, 0.0, TAU, 32, Color(0.80, .90, 1.0, .28), 1.5)
	var knob := joy_center + joystick * 34.0
	draw_circle(knob, 18.0, Color(0.88, .93, 1.0, .74))
	# action circles
	draw_action_circle(PASS_RECT.position + PASS_RECT.size * .5, 28.0, PURPLE, "↗", "傳球")
	draw_action_circle(STEAL_RECT.position + STEAL_RECT.size * .5, 28.0, GREEN, "✋", "抄球")
	draw_action_circle(SPRINT_RECT.position + SPRINT_RECT.size * .5, 28.0, BLUE, "⚡", "衝刺")
	draw_action_circle(SHOT_RECT.position + SHOT_RECT.size * .5, 41.0, Color("ec8529"), "🏀", "投籃")


func draw_action_circle(center: Vector2, radius: float, color: Color, icon: String, caption: String) -> void:
	var is_hover := Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)).has_point(mouse_design)
	draw_circle(center, radius + 4.0, Color(color.r, color.g, color.b, .13))
	draw_circle(center, radius, color.lightened(.10) if is_hover else color)
	draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, .48), 1.4)
	centered_text(icon, center + Vector2(0.0, -5.0), radius * 1.7, int(radius * .55), Color.WHITE)
	centered_text(caption, center + Vector2(0.0, radius * .58), radius * 1.9, 8, Color.WHITE)
	if caption == "投籃" and charging:
		draw_arc(center, radius + 7.0, -PI * .5, -PI * .5 + TAU * charge, 26, GOLD, 3.0)


func draw_effects() -> void:
	for ring in rings:
		var alpha: float = clampf(float(ring["life"]) / float(ring["max_life"]), 0.0, 1.0)
		draw_arc(Vector2(float(ring["x"]), float(ring["y"])), float(ring["radius"]), 0.0, TAU, 28, Color(ring["color"], alpha), 3.0)
	for particle in particles:
		var alpha: float = clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		var c: Color = particle["color"]
		c.a = alpha
		if bool(particle["star"]):
			draw_star(Vector2(float(particle["x"]), float(particle["y"])), float(particle["size"]), c)
		else:
			draw_circle(Vector2(float(particle["x"]), float(particle["y"])), float(particle["size"]), c)
	for floater in floaters:
		var alpha: float = clampf(float(floater["life"]) / float(floater["max_life"]), 0.0, 1.0)
		var c: Color = floater["color"]
		c.a = alpha
		centered_text(String(floater["text"]), Vector2(float(floater["x"]), float(floater["y"])), 190.0, 14, c)
	if skill_flash_timer > 0.0:
		var flash_color: Color = Color("ff7c35") if skill_flash == "火焰灌籃" else BLUE_LIGHT
		draw_rect(Rect2(40.0, 184.0, 814.0, 458.0), Color(flash_color, skill_flash_timer / .75 * .10))


func draw_star(center: Vector2, outer: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := outer if i % 2 == 0 else outer * .44
		var angle := -PI * .5 + float(i) * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)


func draw_right_rail() -> void:
	var rail_fill := CREAM if generated_art else Color(0.055, 0.10, 0.22, .88)
	var rail_border := Color("b6c6de") if generated_art else Color("2e4a7e")
	panel(RIGHT_RECT, rail_fill, rail_border, 20.0)
	# features
	label_text("01", Vector2(910.0, 130.0), 9, Color("6f9fea"))
	label_text("遊戲特色", Vector2(934.0, 131.0), 16, INK if generated_art else TEXT)
	draw_line(Vector2(1006.0, 126.0), Vector2(1237.0, 126.0), Color(0.18, .30, .52, .35) if generated_art else Color(0.38, .57, .85, .35), 1.0)
	var feature_rows := [
		["⚡", "簡單操作，輕鬆上手", "方向鍵＋動作鍵，馬上開始街頭對決。", GOLD],
		["◎", "精準投籃，挑戰手感", "蓄力對準綠色區域，享受空心入網。", GREEN],
		["✦", "必殺技能，逆轉比賽", "累積能量，釋放火焰灌籃與急停三分。", BLUE_LIGHT],
		["◆", "可愛角色，多變造型", "解鎖球衣、籃球與鞋子，打造球星。", Color("ef8fff")]
	]
	for i in feature_rows.size():
		var row_y := 156.0 + i * 47.0
		draw_circle(Vector2(927.0, row_y + 12.0), 18.0, Color(feature_rows[i][3], .16))
		if generated_art and feature_texture != null:
			var feature_index := i
			var feature_source := Rect2(float(feature_index % 2) * 627.0 + 8.0, float(feature_index / 2) * 627.0 + 8.0, 611.0, 611.0)
			draw_texture_rect_region(feature_texture, Rect2(909.0, row_y - 6.0, 36.0, 36.0), feature_source, Color.WHITE)
		else:
			centered_text(String(feature_rows[i][0]), Vector2(927.0, row_y + 11.0), 28.0, 13, Color.WHITE)
		label_text(String(feature_rows[i][1]), Vector2(953.0, row_y + 9.0), 10, INK if generated_art else TEXT)
		label_text(String(feature_rows[i][2]), Vector2(953.0, row_y + 23.0), 8, INK_MUTED if generated_art else MUTED)
	# shot system panel
	panel(Rect2(906.0, 359.0, 334.0, 168.0), Color(0.85, .88, .95, .96), Color("b7ccef"), 14.0)
	label_text("02", Vector2(920.0, 382.0), 9, Color("477ac4"))
	label_text("投籃系統", Vector2(944.0, 383.0), 16, Color("202f50"))
	var step_x := [930.0, 1005.0, 1081.0, 1160.0]
	var step_labels := ["按住投籃", "調整力量", "放開按鈕", "投籃出手"]
	if generated_art and shooting_guide_texture != null:
		# The generated strip turns the four-step tutorial into a readable visual
		# sequence while the labels below remain crisp and localized.
		draw_texture_rect(shooting_guide_texture, Rect2(916.0, 395.0, 308.0, 88.0), false, Color.WHITE)
		for i in 4:
			var step_fill := Color("3f72bf") if i < 3 else Color("4ca968")
			draw_circle(Vector2(step_x[i], 488.0), 8.0, step_fill)
			centered_text(str(i + 1), Vector2(step_x[i], 488.0), 16.0, 8, Color.WHITE)
			centered_text(step_labels[i], Vector2(step_x[i], 500.0), 66.0, 7, Color("3c4c6a"))
	else:
		for i in 4:
			centered_text(str(i + 1), Vector2(step_x[i], 407.0), 18.0, 9, Color.WHITE)
			draw_circle(Vector2(step_x[i], 407.0), 9.0, Color("3f72bf"))
			centered_text(str(i + 1), Vector2(step_x[i], 407.0), 18.0, 9, Color.WHITE)
			if i < 3:
				label_text("›", Vector2(step_x[i] + 27.0, 414.0), 20, Color("7e8daa"))
			label_text(step_labels[i], Vector2(step_x[i] - 28.0, 472.0), 8, Color("3c4c6a"))
		if charging:
			draw_circle(Vector2(step_x[1], 440.0), 15.0, Color("273149"))
			draw_rect(Rect2(step_x[1] - 11.0, 431.0, 22.0 * charge, 18.0), GREEN)
		else:
			centered_text("🏀", Vector2(step_x[0], 438.0), 32.0, 18, Color("e77828"))
			centered_text("🏀", Vector2(step_x[2], 438.0), 32.0, 18, Color("e77828"))
		centered_text("PERFECT!", Vector2(step_x[3], 438.0), 70.0, 9, Color("579653"))
	draw_line(Vector2(922.0, 496.0), Vector2(1223.0, 496.0), Color(0.35, .80, .59, .65), 3.0)
	centered_text("綠色甜蜜點 ＝ 高命中率", Vector2(1072.0, 514.0), 210.0, 8, Color("7d8ca9"))
	# status panel
	label_text("LIVE", Vector2(910.0, 553.0), 9, Color("2e7cc8"))
	label_text("球員狀態", Vector2(910.0, 571.0), 15, INK if generated_art else TEXT)
	panel(Rect2(1155.0, 548.0, 68.0, 24.0), Color(0.13, .38, .29, .45), Color(0.35, .85, .62, .35), 8.0)
	centered_text("P1 持球" if possession == "player" else "P2 持球" if possession == "opponent" else "球在空中", Vector2(1189.0, 560.0), 64.0, 8, GREEN if possession == "player" else GOLD)
	# status avatar and bars
	draw_circle(Vector2(932.0, 611.0), 20.0, BLUE)
	if generated_art:
		draw_cat_portrait(player_texture, Rect2(912.0, 591.0, 40.0, 40.0))
	else:
		centered_text("🐱", Vector2(932.0, 611.0), 35.0, 17, TEXT)
	label_text("喵白白", Vector2(962.0, 606.0), 11, INK if generated_art else TEXT)
	label_text("控球後衛 · Lv. 5", Vector2(962.0, 620.0), 8, INK_MUTED if generated_art else MUTED)
	draw_circle(Vector2(1182.0, 607.0), 25.0, Color("193c74"))
	draw_arc(Vector2(1182.0, 607.0), 25.0, -PI * .5, -PI * .5 + TAU * energy / 100.0, 25, PURPLE, 3.0)
	centered_text("%d" % int(energy), Vector2(1182.0, 606.0), 45.0, 12, BLUE_LIGHT)
	centered_text("ENERGY", Vector2(1182.0, 620.0), 52.0, 6, Color("9cb0d7"))
	label_text("體力", Vector2(912.0, 650.0), 8, INK_MUTED if generated_art else MUTED)
	draw_bar(Rect2(944.0, 645.0, 176.0, 6.0), stamina / 100.0, GREEN)
	label_text("%d/100" % int(stamina), Vector2(1128.0, 652.0), 8, INK_MUTED if generated_art else Color("bccbea"))
	label_text("必殺", Vector2(912.0, 670.0), 8, INK_MUTED if generated_art else MUTED)
	draw_bar(Rect2(944.0, 665.0, 176.0, 6.0), energy / 100.0, PURPLE)
	label_text("%d%%" % int(energy), Vector2(1128.0, 672.0), 8, INK_MUTED if generated_art else Color("bccbea"))


func draw_bar(rect: Rect2, amount: float, color: Color) -> void:
	panel(rect, Color(0.02, .05, .12, .8), Color(0.22, .34, .56, .45), 3.0)
	draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), Vector2(max(0.0, rect.size.x - 2.0) * clamp(amount, 0.0, 1.0), rect.size.y - 2.0)), color)


func draw_bottom_cards() -> void:
	var bottom_fill := CREAM if generated_art else Color(0.055, 0.10, 0.22, .86)
	var bottom_border := Color("b6c6de") if generated_art else Color("2e4a7e")
	var bottom_text := INK if generated_art else TEXT
	var bottom_muted := INK_MUTED if generated_art else MUTED
	panel(BOTTOM_RECT, bottom_fill, bottom_border, 16.0)
	# character card
	label_text("03  角色設定", Vector2(43.0, 729.0), 11, Color("83b5ff"))
	draw_circle(Vector2(80.0, 764.0), 25.0, BLUE)
	if generated_art:
		draw_cat_portrait(player_texture, Rect2(55.0, 739.0, 50.0, 50.0))
	else:
		centered_text("🐱", Vector2(80.0, 762.0), 44.0, 20, TEXT)
	label_text("喵白白", Vector2(116.0, 756.0), 13, bottom_text)
	label_text("BLUE PAWS · 控球後衛", Vector2(116.0, 771.0), 8, Color("77a8ee"))
	label_text("速度", Vector2(258.0, 751.0), 8, bottom_muted)
	draw_bar(Rect2(291.0, 747.0, 76.0, 6.0), .76, BLUE_LIGHT)
	label_text("投籃", Vector2(258.0, 768.0), 8, bottom_muted)
	draw_bar(Rect2(291.0, 764.0, 76.0, 6.0), .82, GOLD)
	# Support character and equipment inventory fill the same compact utility slot
	# used by the reference UI, while the copy remains vector-sharp.
	if generated_art and maid_texture != null:
		draw_texture_rect(maid_texture, Rect2(396.0, 733.0, 46.0, 58.0), false, Color.WHITE)
	else:
		draw_circle(Vector2(419.0, 761.0), 23.0, Color("739dff"))
		centered_text("🐱", Vector2(419.0, 760.0), 40.0, 18, TEXT)
	label_text("喵藍藍", Vector2(450.0, 750.0), 12, bottom_text)
	label_text("支援角色 · 全隊命中 +10%", Vector2(450.0, 765.0), 8, bottom_muted)
	label_text("裝備", Vector2(450.0, 786.0), 7, bottom_muted)
	if generated_art and equipment_texture != null:
		draw_equipment_item(Rect2(474.0, 773.0, 24.0, 22.0), 0, 0)
		draw_equipment_item(Rect2(501.0, 773.0, 24.0, 22.0), 2, 0)
		draw_equipment_item(Rect2(528.0, 773.0, 24.0, 22.0), 2, 1)
	# skills card
	label_text("04  必殺技能", Vector2(580.0, 729.0), 11, Color("83b5ff"))
	draw_skill_chip(Rect2(580.0, 741.0, 130.0, 42.0), "🔥", "火焰灌籃", GOLD, 0)
	draw_skill_chip(Rect2(718.0, 741.0, 130.0, 42.0), "💠", "後撤步三分", BLUE_LIGHT, 1)
	# progression card
	label_text("05  遊戲進程", Vector2(914.0, 729.0), 11, Color("83b5ff"))
	draw_line(Vector2(924.0, 762.0), Vector2(1228.0, 762.0), Color(0.37, .61, .96, .5), 3.0)
	var milestones := [["🏆", "新手賽"], ["🎖", "街頭聯賽"], ["🛡", "城市盃賽"], ["♛", "全國大賽"], ["🏆", "世界冠軍"]]
	for i in milestones.size():
		var x := 924.0 + i * 76.0
		draw_circle(Vector2(x, 762.0), 17.0, Color("3f75c7") if i < 2 else Color("6c4d37") if i == 2 else Color("243354"))
		if generated_art and progression_texture != null:
			var badge_width := float(progression_texture.get_width()) / 5.0
			var badge_source := Rect2(badge_width * float(i), 0.0, badge_width, float(progression_texture.get_height()))
			draw_texture_rect_region(progression_texture, Rect2(x - 15.0, 747.0, 30.0, 30.0), badge_source, Color.WHITE)
		else:
			centered_text(String(milestones[i][0]), Vector2(x, 762.0), 28.0, 12, TEXT)
		centered_text(String(milestones[i][1]), Vector2(x, 786.0), 70.0, 7, Color("3f4f6c") if i <= 2 else bottom_muted)


func draw_skill_chip(rect: Rect2, icon: String, title: String, color: Color, skill_index: int = -1) -> void:
	panel(rect, Color(color, .14), Color(color, .38), 9.0)
	var skill_text := INK if generated_art else TEXT
	var skill_muted := INK_MUTED if generated_art else MUTED
	if generated_art and skill_texture != null and skill_index >= 0:
		var skill_source := Rect2(float(skill_index % 2) * 627.0 + 8.0, float(skill_index / 2) * 627.0 + 8.0, 611.0, 611.0)
		draw_texture_rect_region(skill_texture, Rect2(rect.position + Vector2(3.0, 4.0), Vector2(34.0, 34.0)), skill_source, Color.WHITE)
	else:
		centered_text(icon, Vector2(rect.position.x + 19.0, rect.position.y + 20.0), 26.0, 16, skill_text)
	label_text(title, Vector2(rect.position.x + 36.0, rect.position.y + 19.0), 9, skill_text)
	label_text("按鍵施放", Vector2(rect.position.x + 36.0, rect.position.y + 31.0), 7, skill_muted)


func format_time(seconds: float) -> String:
	var safe: int = maxi(0, int(ceil(seconds)))
	return "%02d:%02d" % [safe / 60, safe % 60]
