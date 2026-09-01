extends Node2D

## 喵萌籃球大作戰
## Playable Godot 4 2D prototype. Match rules live in GameData/GameRules;
## this node owns the loop, input, and immediate-mode HUD.

const DESIGN_SIZE := GameData.DESIGN_SIZE
const COURT_RECT := GameData.COURT_RECT
const WORLD_RECT := GameData.WORLD_RECT
const RIGHT_RECT := GameData.RIGHT_RECT
const BOTTOM_RECT := GameData.BOTTOM_RECT
const HOOP := GameData.HOOP
const RIM_Y := GameData.RIM_Y
const FLOOR_Y := GameData.FLOOR_Y
const NAVY_950 := GameData.NAVY_950
const BLUE := GameData.BLUE
const BLUE_LIGHT := GameData.BLUE_LIGHT
const RED := GameData.RED
const GOLD := GameData.GOLD
const GREEN := GameData.GREEN
const PURPLE := GameData.PURPLE
const TEXT := GameData.TEXT
const MUTED := GameData.MUTED
const CREAM := GameData.CREAM
const INK := GameData.INK
const INK_MUTED := GameData.INK_MUTED
const START_RECT := GameData.START_RECT
const RESET_RECT := GameData.RESET_RECT
const MODE_RECT := GameData.MODE_RECT
const REPLAY_RECT := GameData.REPLAY_RECT
const MUTE_RECT := GameData.MUTE_RECT
const HELP_RECT := GameData.HELP_RECT
const HELP_CLOSE_RECT := GameData.HELP_CLOSE_RECT
const SKILL_ONE_RECT := GameData.SKILL_ONE_RECT
const SKILL_TWO_RECT := GameData.SKILL_TWO_RECT
const SHOT_RECT := GameData.SHOT_RECT
const PASS_RECT := GameData.PASS_RECT
const STEAL_RECT := GameData.STEAL_RECT
const SPRINT_RECT := GameData.SPRINT_RECT
const JOYSTICK_RECT := GameData.JOYSTICK_RECT
const PLAYER_CARD_RECT := GameData.PLAYER_CARD_RECT

var font: Font
var court_texture: Texture2D = preload("res://assets/generated-rooftop-court-v3.png")
var player_texture: Texture2D = preload("res://assets/generated-white-cat.png")
var opponent_texture: Texture2D = preload("res://assets/generated-calico-cat.png")
var story_opponent_texture: Texture2D = preload("res://assets/generated-orange-cat-v2.png")
var boss_opponent_texture: Texture2D = preload("res://assets/generated-boss-cat-v2.png")
var player_play_texture: Texture2D = preload("res://assets/generated-white-cat-play.png")
var opponent_play_texture: Texture2D = preload("res://assets/generated-calico-cat-play.png")
var story_opponent_play_texture: Texture2D = preload("res://assets/generated-orange-cat-play.png")
var boss_opponent_play_texture: Texture2D = preload("res://assets/generated-boss-cat-play.png")
var title_emblem_texture: Texture2D = preload("res://assets/generated-app-icon-v2.png")
var ui_frame_texture: Texture2D = preload("res://assets/generated-ui-frame-v2.png")
var feature_texture: Texture2D = preload("res://assets/generated-feature-icons-v2.png")
var skill_texture: Texture2D = preload("res://assets/generated-skill-sheet.png")
var mode_texture: Texture2D = preload("res://assets/generated-mode-sheet.png")
var progression_texture: Texture2D = preload("res://assets/generated-progression-badges.png")
var equipment_texture: Texture2D = preload("res://assets/generated-equipment-sheet.png")
var shooting_guide_texture: Texture2D = preload("res://assets/generated-shooting-guide.png")
var maid_texture: Texture2D = preload("res://assets/generated-support-cat-v2.png")
var fire_dunk_vfx_texture: Texture2D = preload("res://assets/generated-vfx-fire-dunk-v2.png")
var three_pointer_vfx_texture: Texture2D = preload("res://assets/generated-vfx-three-pointer-v2.png")
var crossover_vfx_texture: Texture2D = preload("res://assets/generated-vfx-crossover-v2.png")
var trophy_badge_texture: Texture2D = preload("res://assets/generated-trophy-badge-v2.png")
var protagonist_group_texture: Texture2D = preload("res://assets/generated-protagonist-group-v1.png")
var character_showcase_texture: Texture2D = preload("res://assets/generated-character-showcase-v1.png")
var skill_showcase_texture: Texture2D = preload("res://assets/generated-skill-showcase-v1.png")

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
var player_character := "white"
var period := 1

var player := CourtActor.new(302.0, 565.0, 1.0)
var opponent := CourtActor.new(570.0, 557.0, -1.0)
var ball := GameBall.new()
var flight := ShotFlight.new()

var charging := false
var charging_shooter := ""
var charge := 0.16
var charge_direction := 1.0
var shot_cooldown := 0.0
var opponent_think := 1.5
var opponent_shot_cooldown := 0.0
var opponent_defense_cooldown := 0.0
var next_shot_bonus := 0.0
var combo := 0
var best_combo := 0
var combo_timer := 0.0
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
var _panel_styles: Dictionary = {}
var visual_time := 0.0
var pending_reset_in := 0.0
var pending_possession := ""


func _ready() -> void:
	font = ThemeDB.fallback_font
	generated_art = not OS.has_feature("headless")
	ball.reset(329.0, 487.0)
	get_viewport().size_changed.connect(queue_redraw)
	reset_game(false)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.05)
	visual_time += dt
	var needs_draw := running or help_visible or game_over
	if running:
		update_game(dt)
		needs_draw = true
	else:
		_idle_ball(dt)
		if message_timer > 0.0:
			message_timer = maxf(0.0, message_timer - dt)
			needs_draw = true
		if skill_flash_timer > 0.0 or not particles.is_empty() or not floaters.is_empty() or not rings.is_empty():
			skill_flash_timer = maxf(0.0, skill_flash_timer - dt)
			update_effects(dt)
			needs_draw = true
		needs_draw = true
	if needs_draw:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_design = screen_to_design(event.position)
		if joystick_active:
			update_joystick(mouse_design)
		queue_redraw()
		return

	if event is InputEventKey:
		_handle_key(event as InputEventKey)
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			handle_pointer_down(screen_to_design(mouse_event.position))
		else:
			handle_pointer_up()
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			handle_pointer_down(screen_to_design(touch.position))
		else:
			handle_pointer_up()
		return

	if event is InputEventScreenDrag and joystick_active:
		update_joystick(screen_to_design((event as InputEventScreenDrag).position))


func _handle_key(key_event: InputEventKey) -> void:
	if key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_H:
			toggle_help()
		elif key_event.keycode == KEY_ENTER and mode == "duo":
			if help_visible:
				help_visible = false
				return
			begin_opponent_shot()
		elif key_event.keycode == KEY_ENTER:
			if help_visible:
				help_visible = false
				return
			if game_over:
				restart_match()
			else:
				toggle_start()
		elif key_event.keycode == KEY_C:
			cycle_player_character()
		elif key_event.keycode == KEY_1:
			request_mode("quick")
		elif key_event.keycode == KEY_2:
			request_mode("story")
		elif key_event.keycode == KEY_3:
			request_mode("challenge")
		elif key_event.keycode == KEY_4:
			request_mode("boss")
		elif key_event.keycode == KEY_5:
			request_mode("duo")
		elif key_event.keycode == KEY_SPACE:
			begin_shot()
		elif key_event.keycode == KEY_SLASH and mode == "duo":
			attempt_opponent_steal()
		elif key_event.keycode == KEY_X:
			attempt_steal()
		elif key_event.keycode == KEY_Q:
			trigger_skill(GameData.SKILL_FIRE)
		elif key_event.keycode == KEY_E:
			trigger_skill(GameData.SKILL_STEPBACK)
		elif key_event.keycode == KEY_R:
			trigger_skill(GameData.SKILL_DASH)
		elif key_event.keycode == KEY_F:
			trigger_skill(GameData.SKILL_METEOR)
		elif key_event.keycode == KEY_ESCAPE:
			if help_visible:
				help_visible = false
			else:
				running = false
	elif not key_event.pressed:
		if key_event.keycode == KEY_SPACE or (key_event.keycode == KEY_ENTER and mode == "duo"):
			release_shot()


func handle_pointer_down(p: Vector2) -> void:
	if help_visible:
		if HELP_CLOSE_RECT.has_point(p) or not GameData.HELP_PANEL_RECT.has_point(p):
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
	elif PLAYER_CARD_RECT.has_point(p):
		cycle_player_character()
	elif SHOT_RECT.has_point(p):
		begin_shot()
	elif PASS_RECT.has_point(p):
		perform_pass()
	elif STEAL_RECT.has_point(p):
		attempt_steal()
	elif SPRINT_RECT.has_point(p):
		sprinting = true
	elif SKILL_ONE_RECT.has_point(p):
		trigger_skill(GameData.SKILL_FIRE)
	elif SKILL_TWO_RECT.has_point(p):
		trigger_skill(GameData.SKILL_STEPBACK)
	elif JOYSTICK_RECT.has_point(p):
		joystick_active = true
		update_joystick(p)


func handle_pointer_up() -> void:
	release_shot()
	sprinting = false
	if joystick_active:
		joystick_active = false
		joystick = Vector2.ZERO


func screen_to_design(screen_pos: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale: float = minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset: Vector2 = (viewport_size - DESIGN_SIZE * scale) * 0.5
	return (screen_pos - offset) / scale


func update_game(dt: float) -> void:
	elapsed += dt
	time_left -= dt
	shot_cooldown = maxf(0.0, shot_cooldown - dt)
	opponent_shot_cooldown = maxf(0.0, opponent_shot_cooldown - dt)
	opponent_defense_cooldown = maxf(0.0, opponent_defense_cooldown - dt)
	combo_timer = maxf(0.0, combo_timer - dt)
	if combo_timer <= 0.0:
		combo = 0
	player.tick_dash(dt)
	opponent.tick_dash(dt)
	skill_flash_timer = maxf(0.0, skill_flash_timer - dt)
	message_timer = maxf(0.0, message_timer - dt)

	if pending_reset_in > 0.0:
		pending_reset_in = maxf(0.0, pending_reset_in - dt)
		if pending_reset_in <= 0.0 and pending_possession != "":
			var next_who := pending_possession
			pending_possession = ""
			reset_after_score(next_who)
	update_player(dt)
	update_opponent(dt)
	update_charge(dt)
	update_ball(dt)
	update_ai(dt)
	update_effects(dt)
	var total_duration: float = maxf(1.0, float(current_mode()["duration"]))
	period = clampi(int(((total_duration - maxf(0.0, time_left)) / total_duration) * 4.0) + 1, 1, 4)

	if time_left <= 0.0:
		end_game()
	elif score_player >= int(current_mode()["target"]) or score_opponent >= int(current_mode()["target"]):
		end_game()


func update_player(dt: float) -> void:
	var axis := Vector2.ZERO
	if Input.is_key_pressed(KEY_D) or (mode != "duo" and Input.is_key_pressed(KEY_RIGHT)):
		axis.x += 1.0
	if Input.is_key_pressed(KEY_A) or (mode != "duo" and Input.is_key_pressed(KEY_LEFT)):
		axis.x -= 1.0
	if Input.is_key_pressed(KEY_S) or (mode != "duo" and Input.is_key_pressed(KEY_DOWN)):
		axis.y += 1.0
	if Input.is_key_pressed(KEY_W) or (mode != "duo" and Input.is_key_pressed(KEY_UP)):
		axis.y -= 1.0
	axis += joystick
	if axis.length() > 1.0:
		axis = axis.normalized()

	var sprint_key := Input.is_key_pressed(KEY_SHIFT)
	var wants_sprint := (sprint_key or sprinting) and axis.length() > 0.05 and stamina > 0.0
	var speed := (380.0 if wants_sprint else 240.0) * GameRules.speed_factor(player_stat(0))
	if wants_sprint:
		stamina = maxf(0.0, stamina - dt * 20.0)
	else:
		stamina = minf(100.0, stamina + dt * 8.0)
	player.x = clampf(player.x + axis.x * speed * dt, 104.0, 702.0)
	player.y = clampf(player.y + axis.y * speed * 0.38 * dt, 456.0, 576.0)
	if absf(axis.x) > 0.02:
		player.facing = 1.0 if axis.x > 0.0 else -1.0
	player.bob += dt * (14.0 if wants_sprint else 9.0 if axis.length() > 0.05 else 3.0)
	if player.dash > 0.0:
		player.x = clampf(player.x + player.facing * 165.0 * dt, 104.0, 702.0)

	_try_grab_ball(player, "player")
	if possession == "player" and not ball.in_flight and not ball.loose:
		_dribble_with(player)


func update_opponent(dt: float) -> void:
	if mode == "duo":
		update_human_opponent(dt)
		return
	var target := Vector2(HOOP.x - 145.0, 520.0) if possession == "opponent" else Vector2(player.x + 106.0, player.y - 3.0)
	if ball.loose:
		target = Vector2(ball.x, ball.y + 62.0)
	var delta := target - opponent.pos()
	var dist: float = maxf(1.0, delta.length())
	var speed := float(current_mode()["opponent_speed"])
	opponent.x = clampf(opponent.x + delta.x / dist * speed * dt, 423.0, 810.0)
	opponent.y = clampf(opponent.y + delta.y / dist * speed * 0.38 * dt, 456.0, 576.0)
	if absf(delta.x) > 2.0:
		opponent.facing = 1.0 if delta.x > 0.0 else -1.0
	opponent.bob += dt * (9.0 if dist > 25.0 else 3.0)
	_attach_ball_to_opponent()


func update_human_opponent(dt: float) -> void:
	var axis := Vector2.ZERO
	if Input.is_key_pressed(KEY_RIGHT):
		axis.x += 1.0
	if Input.is_key_pressed(KEY_LEFT):
		axis.x -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		axis.y += 1.0
	if Input.is_key_pressed(KEY_UP):
		axis.y -= 1.0
	if axis.length() > 1.0:
		axis = axis.normalized()
	var speed := 245.0 * GameRules.speed_factor(float(GameData.character_info("calico")["stats"][0]))
	opponent.x = clampf(opponent.x + axis.x * speed * dt, 104.0, 810.0)
	opponent.y = clampf(opponent.y + axis.y * speed * 0.38 * dt, 456.0, 576.0)
	if absf(axis.x) > 0.02:
		opponent.facing = 1.0 if axis.x > 0.0 else -1.0
	opponent.bob += dt * (10.0 if axis.length() > 0.05 else 3.0)
	if opponent.dash > 0.0:
		opponent.x = clampf(opponent.x + opponent.facing * 165.0 * dt, 104.0, 810.0)
	_attach_ball_to_opponent()


func _attach_ball_to_opponent() -> void:
	_try_grab_ball(opponent, "opponent")
	if possession == "opponent" and not ball.in_flight and not ball.loose:
		_dribble_with(opponent)


func _dribble_with(actor: CourtActor) -> void:
	var hand := Vector2(actor.x - actor.facing * 52.0, actor.y - 100.0)
	var is_this_charging := charging and ((charging_shooter == "player" and actor == player) or (charging_shooter == "opponent" and actor == opponent))
	ball.hold_dribble(hand, actor.y, visual_time, is_this_charging)


func _idle_ball(_dt: float) -> void:
	if ball.in_flight or ball.loose:
		return
	if possession == "player":
		_dribble_with(player)
	elif possession == "opponent":
		_dribble_with(opponent)


func _try_grab_ball(actor: CourtActor, who: String) -> void:
	if not ball.loose or ball.in_flight or ball.scored or pending_reset_in > 0.0:
		return
	var reach := 82.0 if ball.bounces >= 1 else 54.0
	var my_dist := actor.pos().distance_to(ball.pos())
	if my_dist > reach:
		return
	var other: CourtActor = opponent if who == "player" else player
	if other.pos().distance_to(ball.pos()) + 10.0 < my_dist:
		return
	set_possession(who)


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
	if possession == "player" and not ball.in_flight and not ball.loose:
		return
	if possession == "opponent" and not ball.in_flight and not ball.loose:
		return
	if not ball.in_flight and not ball.loose:
		return
	var event := ball.step(dt, WORLD_RECT, HOOP, RIM_Y, FLOOR_Y, GameData.BACKBOARD_X)
	if event == "scored" and not flight.resolved:
		flight.resolved = true
		if flight.shooter == "player":
			resolve_player_shot(true)
		else:
			resolve_opponent_shot(true)
		pending_reset_in = GameData.SCORE_RESET_DELAY
		pending_possession = "opponent" if flight.shooter == "player" else "player"
	elif event == "missed" and not flight.resolved:
		flight.resolved = true
		if flight.shooter == "player":
			resolve_player_shot(false)
		else:
			resolve_opponent_shot(false)
	if ball.loose and not ball.scored and ball.bounces >= 2:
		var pd := player.pos().distance_to(ball.pos())
		var od := opponent.pos().distance_to(ball.pos())
		if pd < od and pd < 120.0:
			set_possession("player")
		elif od < 120.0:
			set_possession("opponent")


func update_ai(dt: float) -> void:
	if mode == "duo" or ball.in_flight or ball.loose:
		return
	if possession == "player":
		if charging and opponent_defense_cooldown <= 0.0:
			if player.pos().distance_to(opponent.pos()) < 126.0:
				opponent_defense_cooldown = 1.15
				var steal_chance := 0.16 + float(current_mode()["opponent_accuracy"]) * 0.18
				if randf() < steal_chance:
					charging = false
					charging_shooter = ""
					set_possession("opponent")
					player.dash = 0.16
					burst(opponent.x, opponent.y - 62.0, opponent_color(), 9)
					show_message("%s抓到你的蓄力空檔！" % opponent_display_name(), 1.2)
		return
	if possession != "opponent" or opponent_shot_cooldown > 0.0:
		return
	opponent_think -= dt
	if opponent_think > 0.0:
		return
	opponent_think = 1.4 + randf() * 1.5
	if absf(HOOP.x - opponent.x) < 500.0:
		opponent_shot_cooldown = 1.2
		shoot_for_opponent()
	else:
		opponent.dash = 0.35


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
	_compact_live(particles)
	_compact_live(floaters)
	_compact_live(rings)


func _compact_live(items: Array[Dictionary]) -> void:
	var write := 0
	for i in items.size():
		if float(items[i]["life"]) > 0.0:
			if write != i:
				items[write] = items[i]
			write += 1
	items.resize(write)


func begin_shot() -> void:
	if not running:
		show_message("先按「開始比賽」再上場！", 1.2)
		return
	if possession != "player":
		show_message("先把球搶回來！", 1.1)
		return
	if ball.in_flight or ball.loose or shot_cooldown > 0.0 or charging or pending_reset_in > 0.0:
		return
	charging = true
	charging_shooter = "player"
	charge = 0.16
	charge_direction = 1.0
	show_message("蓄力瞄準中 · 放開出手", 0.5)


func begin_opponent_shot() -> void:
	if mode != "duo":
		return
	if not running:
		show_message("先按「開始比賽」再上場！", 1.2)
		return
	if possession != "opponent":
		show_message("P2 先把球搶回來！", 1.1)
		return
	if ball.in_flight or ball.loose or opponent_shot_cooldown > 0.0 or charging or pending_reset_in > 0.0:
		return
	charging = true
	charging_shooter = "opponent"
	charge = 0.16
	charge_direction = 1.0
	show_message("P2 蓄力瞄準中 · 放開 Enter", 0.6)


func release_shot(force_charge: float = -1.0) -> void:
	if not charging:
		return
	var shooter := charging_shooter
	charging = false
	charging_shooter = ""
	if shooter == "opponent":
		if possession != "opponent" or ball.in_flight or ball.loose:
			return
		opponent_shot_cooldown = 0.55
		shoot_for_opponent(force_charge if force_charge >= 0.0 else charge)
		return
	if possession != "player" or ball.in_flight or ball.loose:
		return
	var final_charge: float = charge if force_charge < 0.0 else force_charge
	var distance_to_hoop: float = absf(HOOP.x - player.x)
	var spread := GameRules.shot_spread(player_stat(1), next_shot_bonus, float(current_mode()["shot_bonus"]))
	_launch_shot(
		"player",
		Vector2(player.x - player.facing * 52.0, player.y - 100.0),
		final_charge,
		distance_to_hoop,
		spread
	)
	shot_cooldown = 0.45
	add_floater("甜蜜點！" if GameRules.is_sweet(final_charge) else "出手！", player.x, player.y - 130.0, GREEN if GameRules.is_sweet(final_charge) else BLUE_LIGHT)


func shoot_for_opponent(charge_value: float = -1.0) -> void:
	var distance_to_hoop: float = absf(HOOP.x - opponent.x)
	var shot_charge: float = charge_value
	var spread := 0.012
	if shot_charge < 0.0:
		if mode == "duo":
			shot_charge = 0.72
		else:
			shot_charge = GameRules.ai_charge(float(current_mode()["opponent_accuracy"]))
			spread = clampf(0.07 - float(current_mode()["opponent_accuracy"]) * 0.06, 0.012, 0.055)
	elif mode == "duo":
		var calico: Dictionary = GameData.character_info("calico")
		spread = GameRules.shot_spread(float(calico["stats"][1]), 0.0, 0.0)
	_launch_shot(
		"opponent",
		Vector2(opponent.x - opponent.facing * 52.0, opponent.y - 100.0),
		shot_charge,
		distance_to_hoop,
		spread
	)
	add_floater("%s出手" % opponent_display_name(), opponent.x, opponent.y - 124.0, opponent_color().lightened(0.22))


func _launch_shot(shooter: String, start: Vector2, shot_charge: float, distance_to_hoop: float, spread: float, dunk: bool = false) -> void:
	var target := Vector2(HOOP.x, RIM_Y - 6.0)
	var flight_time := GameRules.shot_flight_time(distance_to_hoop, dunk)
	var velocity := GameRules.ballistic_velocity(start, target, GameBall.GRAVITY, flight_time)
	velocity *= GameRules.shot_power(shot_charge)
	velocity = GameRules.apply_spread(velocity, spread)
	flight.configure(shooter, start, target, shot_charge, distance_to_hoop)
	ball.launch(start, velocity)
	possession = "none"
	next_shot_bonus = 0.0


func resolve_player_shot(made: bool) -> void:
	if made:
		var points := GameRules.points_for(flight.distance)
		combo += 1
		best_combo = maxi(best_combo, combo)
		combo_timer = GameData.COMBO_WINDOW
		score_player += points
		energy = clampf(energy + 12.0, 0.0, 100.0)
		rings.append({"x": HOOP.x, "y": RIM_Y, "radius": 18.0, "speed": 115.0, "life": 0.7, "max_life": 0.7, "color": BLUE_LIGHT if points == 3 else GOLD})
		burst(HOOP.x, RIM_Y, BLUE_LIGHT if points == 3 else GOLD, 25 if points == 3 else 18)
		add_floater("+%d  %s" % [points, "三分命中！" if points == 3 else "漂亮！"], HOOP.x - 35.0, RIM_Y - 52.0, BLUE_LIGHT if points == 3 else GOLD)
		if combo >= 2:
			add_floater("連續命中 x%d" % combo, HOOP.x - 22.0, RIM_Y - 84.0, PURPLE)
		show_message("🌟 三分命中！" if points == 3 else "🏀 兩分拿下！", 1.8)
	else:
		break_combo()
		add_floater("籃框彈出", HOOP.x - 27.0, RIM_Y - 43.0, Color("ffb0b9"))
		show_message("差一點！調整蓄力再試一次。", 1.4)


func resolve_opponent_shot(made: bool) -> void:
	if made:
		var points := GameRules.points_for(flight.distance)
		break_combo()
		score_opponent += points
		rings.append({"x": HOOP.x, "y": RIM_Y, "radius": 18.0, "speed": 108.0, "life": 0.6, "max_life": 0.6, "color": opponent_color()})
		burst(HOOP.x, RIM_Y, opponent_color().lightened(0.18), 15)
		add_floater("%s +%d" % [opponent_display_name(), points], HOOP.x - 42.0, RIM_Y - 50.0, opponent_color().lightened(0.24))
		show_message("%s命中 %d 分" % [opponent_display_name(), points], 1.4)
	else:
		show_message("對手投丟了，快搶籃板！", 1.2)


func make_loose_ball(x: float, y: float, vx: float, vy: float) -> void:
	ball.x = x
	ball.y = y
	ball.vx = vx
	ball.vy = vy
	ball.bounces = 0
	ball.in_flight = false
	ball.loose = true
	possession = "none"


func set_possession(who: String) -> void:
	possession = who
	ball.loose = false
	ball.in_flight = false
	ball.scored = false
	ball.bounces = 0
	ball.vx = 0.0
	ball.vy = 0.0
	ball.trail.clear()
	if who == "player":
		_dribble_with(player)
	else:
		_dribble_with(opponent)


func reset_after_score(next_possession: String) -> void:
	ball.in_flight = false
	ball.loose = false
	ball.scored = false
	pending_reset_in = 0.0
	player.reset(302.0, 565.0, 1.0)
	opponent.reset(570.0, 557.0, -1.0)
	set_possession(next_possession)


func attempt_steal() -> void:
	if not running:
		show_message("先開始比賽！", 1.1)
		return
	if possession != "opponent":
		show_message("現在是你的球權，往籃框切入！", 1.1)
		return
	if player.pos().distance_to(opponent.pos()) > GameRules.STEAL_RANGE:
		show_message("靠近%s再按抄球" % opponent_display_name(), 1.2)
		return
	player.dash = 0.18
	stamina = maxf(0.0, stamina - 8.0)
	if randf() < GameRules.steal_chance(player_stat(3), 58.0, 0.68, 0.52, 0.84):
		set_possession("player")
		energy = clampf(energy + 8.0, 0.0, 100.0)
		burst(opponent.x, opponent.y - 60.0, GREEN, 10)
		add_floater("抄球成功！", player.x, player.y - 124.0, Color("a4ffc9"))
		show_message("✋ 抄球成功！", 1.3)
	else:
		show_message("差一點，抓準時機！", 1.1)


func attempt_opponent_steal() -> void:
	if mode != "duo":
		return
	if not running:
		show_message("先開始比賽！", 1.1)
		return
	if possession != "player":
		show_message("P2 需要等 P1 持球時抄球", 1.1)
		return
	if player.pos().distance_to(opponent.pos()) > GameRules.STEAL_RANGE:
		show_message("P2 靠近 P1 再按 / 抄球", 1.2)
		return
	opponent.dash = 0.18
	var defense_stat := float(GameData.character_info("calico")["stats"][3])
	if randf() < GameRules.steal_chance(defense_stat, 52.0, 0.64, 0.50, 0.82):
		set_possession("opponent")
		burst(player.x, player.y - 60.0, RED, 10)
		add_floater("P2 抄球成功！", opponent.x, opponent.y - 124.0, Color("ffb8c4"))
		show_message("P2 ✋ 抄球成功！", 1.3)
	else:
		show_message("P2 抄球失敗，抓準時機！", 1.1)


func perform_pass() -> void:
	if not running:
		show_message("先開始比賽！", 1.1)
		return
	if possession != "player" or ball.in_flight:
		show_message("先把球控好再傳球", 1.1)
		return
	player.x = clampf(player.x + player.facing * 56.0, 104.0, 702.0)
	player.dash = 0.24
	stamina = maxf(0.0, stamina - 4.0)
	energy = clampf(energy + 3.0, 0.0, 100.0)
	burst(player.x + player.facing * 20.0, player.y - 60.0, PURPLE, 7)
	add_floater("假傳變向！", player.x, player.y - 118.0, Color("d4bcff"))
	show_message("🤝 假傳變向，甩開防守！", 1.2)


func trigger_skill(skill_name: String) -> void:
	if not running:
		show_message("先開始比賽！", 1.1)
		return
	if possession != "player" and skill_name in [GameData.SKILL_FIRE, GameData.SKILL_STEPBACK, GameData.SKILL_METEOR]:
		show_message("先把球搶回來才能施放這招", 1.2)
		return
	var cost: float = float(GameData.SKILL_COSTS.get(skill_name, 25.0))
	if energy < cost:
		show_message("能量不足，需要 %d%%" % int(cost), 1.2)
		return
	energy -= cost
	skill_flash = skill_name
	skill_flash_timer = 0.75
	if skill_name == GameData.SKILL_FIRE:
		player.dash = 0.6
		player.x = clampf(HOOP.x - 165.0, 104.0, 702.0)
		burst(player.x, player.y - 70.0, Color("ff9c4a"), 20)
		if possession == "player" and not ball.in_flight and not ball.loose:
			_launch_shot("player", Vector2(player.x - player.facing * 52.0, player.y - 100.0), 0.72, absf(HOOP.x - player.x), 0.008, true)
		show_message("🔥 火焰灌籃！", 1.5)
	elif skill_name == GameData.SKILL_STEPBACK:
		player.x = clampf(player.x - 110.0, 104.0, 702.0)
		player.dash = 0.25
		next_shot_bonus = 0.2
		burst(player.x, player.y - 58.0, BLUE_LIGHT, 13)
		add_floater("三分加成 +25%", player.x, player.y - 122.0, BLUE_LIGHT)
		show_message("💠 後撤步完成！下一球命中率提升", 1.7)
	elif skill_name == GameData.SKILL_DASH:
		player.dash = 0.65
		player.x = clampf(player.x + player.facing * 160.0, 104.0, 702.0)
		burst(player.x, player.y - 55.0, PURPLE, 17)
		add_floater("幻影消失！", player.x, player.y - 122.0, Color("e0c8ff"))
		show_message("🌀 幻影變向！防守失去目標", 1.5)
	else:
		if possession == "player" and not ball.in_flight and not ball.loose:
			charging = true
			release_shot(0.72)
		burst(player.x, player.y - 84.0, Color("ff9de8"), 18)
		show_message("☄️ 流星投籃！", 1.5)


func toggle_start() -> void:
	if game_over:
		restart_match()
		return
	running = not running
	if running:
		show_message("開球！%s，掌握節奏！" % player_display_name(), 1.4)
	else:
		show_message("比賽暫停", 1.2)
	queue_redraw()


func toggle_help() -> void:
	help_visible = not help_visible
	if help_visible:
		running = false
	queue_redraw()


func end_game() -> void:
	running = false
	game_over = true
	charging = false
	charging_shooter = ""
	var won := score_player > score_opponent
	var tied := score_player == score_opponent
	show_message("🏆 勝利！%s 稱霸球場！" % player_display_name() if won else "平手！再來一場決勝負。" if tied else "終場！下一球一定更準。", 2.8)
	burst(HOOP.x, RIM_Y - 8.0, GOLD if won else BLUE_LIGHT, 32)


func reset_game(keep_mode: bool = true) -> void:
	if not keep_mode:
		mode = "quick"
		mode_name = "快速比賽"
	running = false
	game_over = false
	help_visible = false
	elapsed = 0.0
	time_left = float(current_mode()["duration"])
	period = 1
	score_player = 0
	score_opponent = 0
	energy = 68.0
	stamina = 86.0
	possession = "player"
	player.reset(302.0, 565.0, 1.0)
	opponent.reset(570.0, 557.0, -1.0)
	ball.reset(329.0, 487.0)
	flight = ShotFlight.new()
	visual_time = 0.0
	pending_reset_in = 0.0
	pending_possession = ""
	charging = false
	charging_shooter = ""
	charge = 0.16
	charge_direction = 1.0
	shot_cooldown = 0.0
	opponent_think = 1.5
	opponent_shot_cooldown = 0.0
	opponent_defense_cooldown = 0.0
	next_shot_bonus = 0.0
	combo = 0
	best_combo = 0
	combo_timer = 0.0
	sprinting = false
	joystick = Vector2.ZERO
	joystick_active = false
	particles.clear()
	floaters.clear()
	rings.clear()
	message = "球場已準備好，按下開始比賽！"
	message_timer = 2.0
	queue_redraw()


func set_mode(next_mode: String) -> void:
	if not GameData.MODES.has(next_mode):
		return
	if running:
		show_message("請先暫停比賽，再切換模式。", 1.2)
		return
	mode = next_mode
	mode_name = String(current_mode()["name"])
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
	set_mode(GameData.next_in(GameData.MODE_ORDER, mode))


func current_mode() -> Dictionary:
	return GameData.mode_info(mode)


func current_character() -> Dictionary:
	return GameData.character_info(player_character)


func player_texture_for_selection() -> Texture2D:
	match player_character:
		"calico":
			return opponent_texture
		"orange":
			return story_opponent_texture
		"boss":
			return boss_opponent_texture
		_:
			return player_texture


func player_court_texture() -> Texture2D:
	match player_character:
		"calico":
			return opponent_play_texture
		"orange":
			return story_opponent_play_texture
		"boss":
			return boss_opponent_play_texture
		_:
			return player_play_texture


func player_display_name() -> String:
	return String(current_character()["name"])


func player_team_label() -> String:
	return String(current_character()["team"])


func player_role() -> String:
	return String(current_character()["role"])


func player_color() -> Color:
	return current_character()["color"] as Color


func player_stat(index: int) -> float:
	var stats: Array = current_character()["stats"]
	return float(stats[clampi(index, 0, stats.size() - 1)])


func cycle_player_character() -> void:
	if running:
		show_message("請先暫停比賽，再切換角色。", 1.2)
		return
	player_character = GameData.next_in(GameData.CHARACTER_ORDER, player_character)
	show_message("%s 已上場 · 按 C 可切換" % player_display_name(), 1.3)
	queue_redraw()


func restart_match() -> void:
	reset_game()
	running = true
	show_message("重新開球！%s，掌握節奏！" % player_display_name(), 1.4)


func show_message(value: String, duration: float = 1.5) -> void:
	message = value
	message_timer = duration
	queue_redraw()


func break_combo() -> void:
	if combo >= 2:
		add_floater("連段中斷", player.x, player.y - 128.0, Color("ffb5c4"))
	combo = 0
	combo_timer = 0.0


func burst(x: float, y: float, color: Color, count: int = 16) -> void:
	for i in count:
		var angle := randf() * TAU
		var speed := 45.0 + randf() * 145.0
		particles.append({"x": x, "y": y, "vx": cos(angle) * speed, "vy": sin(angle) * speed - 40.0, "gravity": 145.0, "life": 0.62 + randf() * 0.45, "max_life": 1.0, "size": 2.0 + randf() * 3.5, "color": color, "star": i % 3 == 0})


func add_floater(value: String, x: float, y: float, color: Color) -> void:
	floaters.append({"text": value, "x": x, "y": y, "life": 1.1, "max_life": 1.1, "color": color})


func update_joystick(point: Vector2) -> void:
	var center := JOYSTICK_RECT.position + JOYSTICK_RECT.size * 0.5
	var radius := JOYSTICK_RECT.size.x * 0.38
	var delta := point - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	joystick = delta / radius


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	drawing_scale = minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	drawing_offset = (viewport_size - DESIGN_SIZE * drawing_scale) * 0.5
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
	var key := "%s|%s|%.1f" % [str(fill), str(border), radius]
	var style: StyleBoxFlat = _panel_styles.get(key)
	if style == null:
		style = StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(1)
		style.corner_radius_top_left = int(radius)
		style.corner_radius_top_right = int(radius)
		style.corner_radius_bottom_left = int(radius)
		style.corner_radius_bottom_right = int(radius)
		_panel_styles[key] = style
	draw_style_box(style, rect)


func label_text(value: String, position: Vector2, size: int, color: Color = TEXT) -> void:
	if font == null:
		return
	draw_string(font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func centered_text(value: String, center: Vector2, width: float, size: int, color: Color = TEXT) -> void:
	if font == null:
		return
	draw_string(font, Vector2(center.x - width * 0.5, center.y + size * 0.35), value, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)


func draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), NAVY_950)
	for i in 12:
		var t := float(i) / 11.0
		draw_rect(Rect2(0.0, t * 706.0, 1280.0, 66.0), Color(0.03 + t * 0.02, 0.07 + t * 0.03, 0.17 + t * 0.08, 1.0))
	draw_circle(Vector2(108.0, 270.0), 180.0, Color(0.07, 0.24, 0.60, 0.13))
	draw_circle(Vector2(1175.0, 558.0), 210.0, Color(0.42, 0.08, 0.40, 0.10))
	for i in 46:
		var x := float((i * 83 + 29) % 1280)
		var y := float(88 + ((i * 47) % 220))
		var radius := 1.4 if i % 6 == 0 else 0.75
		draw_circle(Vector2(x, y), radius, Color(0.69, 0.83, 1.0, 0.25 + float(i % 4) * 0.1))
	if generated_art and ui_frame_texture != null:
		draw_texture_rect(ui_frame_texture, Rect2(0.0, 0.0, DESIGN_SIZE.x, DESIGN_SIZE.y), false, Color(1.0, 1.0, 1.0, 0.12))


func draw_header() -> void:
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
	panel(Rect2(1001.0, 28.0, 118.0, 28.0), Color(0.11, 0.18, 0.36, 0.76), Color("2f5187"), 14.0)
	draw_circle(Vector2(1018.0, 42.0), 4.0, GREEN)
	label_text("遊戲原型 v%s" % GameData.VERSION, Vector2(1028.0, 46.0), 10, Color("a9c3eb"))
	panel(Rect2(1128.0, 28.0, 42.0, 28.0), Color(0.11, 0.18, 0.36, 0.76), Color("2f5187"), 10.0)
	centered_text("🔊" if not muted else "🔇", Vector2(1149.0, 42.0), 42.0, 14, TEXT)
	panel(Rect2(1180.0, 28.0, 76.0, 28.0), Color(0.11, 0.18, 0.36, 0.76), Color("2f5187"), 10.0)
	centered_text("操作說明", Vector2(1218.0, 42.0), 76.0, 10, Color("bdd0ef"))


func draw_court_card() -> void:
	panel(COURT_RECT, Color(0.055, 0.10, 0.22, 0.9), Color("2e4a7e"), 20.0)
	label_text("●  NEON ROOFTOP · NIGHT COURT", Vector2(43.0, 127.0), 10, GREEN)
	label_text(String(current_mode()["tag"]), Vector2(710.0, 127.0), 10, Color("88a5d6"))
	draw_mode_badge(Vector2(682.0, 121.0), mode)
	panel(Rect2(41.0, 139.0, 812.0, 42.0), Color(0.08, 0.15, 0.31, 0.88), Color("213d71"), 12.0)
	draw_circle(Vector2(62.0, 160.0), 13.0, player_color())
	if generated_art:
		draw_cat_portrait(player_texture_for_selection(), Rect2(49.0, 147.0, 26.0, 26.0))
	else:
		centered_text("🐱", Vector2(62.0, 160.0), 25.0, 14, TEXT)
	label_text("P1 · %s" % player_display_name(), Vector2(82.0, 156.0), 11, TEXT)
	label_text(player_team_label(), Vector2(82.0, 169.0), 7, player_color().lightened(0.12))
	label_text("%02d" % score_player, Vector2(185.0, 169.0), 28, TEXT)
	centered_text("第 %d 節" % period, Vector2(438.0, 150.0), 90.0, 9, Color("8da7d2"))
	centered_text(GameData.format_clock(time_left), Vector2(438.0, 169.0), 120.0, 20, TEXT)
	centered_text("進攻回合" if possession == "player" else "防守回合" if possession == "opponent" else "爭搶籃板", Vector2(438.0, 180.0), 120.0, 8, BLUE_LIGHT)
	label_text("%02d" % score_opponent, Vector2(670.0, 169.0), 28, TEXT)
	label_text("P2 · %s" % opponent_display_name(), Vector2(711.0, 156.0), 11, TEXT)
	label_text(opponent_team_label(), Vector2(711.0, 169.0), 7, opponent_color().lightened(0.12))
	draw_circle(Vector2(833.0, 160.0), 13.0, opponent_color())
	if generated_art:
		draw_cat_portrait(opponent_texture_for_mode(), Rect2(820.0, 147.0, 26.0, 26.0))
	else:
		centered_text("🐈", Vector2(833.0, 160.0), 25.0, 14, TEXT)
	draw_world()
	panel(Rect2(41.0, 646.0, 812.0, 34.0), Color(0.04, 0.08, 0.18, 0.72), Color("213d70"), 10.0)
	var control_hint := "🎮  P1 WASD／Space／X 抄球　·　P2 方向鍵／Enter／/ 抄球" if mode == "duo" else "🎮  WASD 移動　·　Space 蓄力投籃　·　Shift 衝刺　·　Q/E/R/F 必殺　·　1-5 模式"
	label_text(control_hint, Vector2(53.0, 667.0), 9, Color("90a8d0"))
	button_box(RESET_RECT, "重新開始", false)
	button_box(START_RECT, "Ⅱ  暫停比賽" if running else "▶  開始比賽", true)
	if message_timer > 0.0:
		panel(Rect2(278.0, 198.0, 310.0, 32.0), Color(0.04, 0.09, 0.20, 0.82), Color("426ca6"), 16.0)
		centered_text(message, Vector2(433.0, 214.0), 300.0, 10, TEXT)


func draw_mode_badge(center: Vector2, mode_key: String) -> void:
	var mode_index := GameData.MODE_ORDER.find(mode_key)
	if mode_index < 0 or mode_index > 3:
		mode_index = 0
	if generated_art and mode_texture != null:
		var mode_source := Rect2(float(mode_index % 2) * 627.0 + 8.0, float(mode_index / 2) * 627.0 + 8.0, 611.0, 611.0)
		draw_texture_rect_region(mode_texture, Rect2(center - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), mode_source, Color.WHITE)
	else:
		draw_circle(center, 14.0, GOLD if mode_index == 0 else BLUE_LIGHT)


func draw_cat_portrait(texture: Texture2D, rect: Rect2) -> void:
	if texture == null:
		return
	var source := Rect2(float(texture.get_width()) * 0.30, 0.0, float(texture.get_width()) * 0.50, float(texture.get_height()) * 0.46)
	draw_texture_rect_region(texture, rect, source, Color.WHITE)


func opponent_texture_for_mode() -> Texture2D:
	match GameData.opponent_id(mode):
		"orange":
			return story_opponent_texture
		"boss":
			return boss_opponent_texture
		_:
			return opponent_texture


func opponent_court_texture() -> Texture2D:
	match GameData.opponent_id(mode):
		"orange":
			return story_opponent_play_texture
		"boss":
			return boss_opponent_play_texture
		_:
			return opponent_play_texture


func opponent_display_name() -> String:
	return String(GameData.opponent_info(mode)["name"])


func opponent_team_label() -> String:
	return String(GameData.opponent_info(mode)["team"])


func opponent_color() -> Color:
	return GameData.opponent_info(mode)["color"] as Color


func draw_equipment_item(rect: Rect2, column: int, row: int) -> void:
	if equipment_texture == null:
		return
	var cell_width := float(equipment_texture.get_width()) / 3.0
	var cell_height := float(equipment_texture.get_height()) / 2.0
	var source := Rect2(float(column) * cell_width + 12.0, float(row) * cell_height + 12.0, cell_width - 24.0, cell_height - 24.0)
	draw_texture_rect_region(equipment_texture, rect, source, Color.WHITE)


func draw_game_over_overlay() -> void:
	var result_text := "%s 勝利！" % player_display_name() if score_player > score_opponent else "%s 勝利！" % opponent_display_name() if score_opponent > score_player else "平手！"
	var result_color := GOLD if score_player >= score_opponent else RED
	panel(Rect2(254.0, 274.0, 418.0, 202.0), Color(0.025, 0.05, 0.13, 0.95), Color("79baff"), 20.0)
	if generated_art and score_player > score_opponent and trophy_badge_texture != null:
		draw_texture_rect(trophy_badge_texture, Rect2(273.0, 286.0, 70.0, 70.0), false, Color(1.0, 1.0, 1.0, 0.92))
	centered_text("終場", Vector2(463.0, 304.0), 210.0, 13, BLUE_LIGHT)
	centered_text(result_text, Vector2(463.0, 333.0), 350.0, 23, result_color)
	centered_text("%02d  —  %02d" % [score_player, score_opponent], Vector2(463.0, 374.0), 280.0, 30, TEXT)
	centered_text("%s  ·  最高連段 x%d" % [String(current_mode()["name"]), best_combo], Vector2(463.0, 401.0), 300.0, 9, MUTED)
	button_box(REPLAY_RECT, "↻  再來一場", true)


func draw_help_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.01, 0.02, 0.06, 0.72))
	panel(GameData.HELP_PANEL_RECT, CREAM, Color("7fbaff"), 22.0)
	draw_rect(Rect2(390.0, 181.0, 500.0, 69.0), Color("1956ad"))
	label_text("操作說明", Vector2(424.0, 224.0), 25, Color.WHITE)
	label_text("先拿到 %d 分，或時間結束時領先即可獲勝" % int(current_mode()["target"]), Vector2(424.0, 242.0), 9, Color("cfe3ff"))
	button_box(HELP_CLOSE_RECT, "關閉  ESC", false)
	var rows := [["移動", "WASD / 方向鍵", "在半場內自由走位，靠近籃框命中率更穩。"], ["投籃", "按住 Space，放開出手", "讓蓄力停在綠色甜蜜點；遠距離可得三分。"], ["衝刺", "Shift", "消耗體力快速切入；停止後會逐步恢復。"], ["抄球 / 假傳", "右側綠色 / 紫色按鈕", "靠近持球對手再抄球，假傳可瞬間變向。"]]
	if mode == "duo":
		rows = [["P1 移動", "W A S D", "P1 控制藍隊；Space 蓄力投籃。"], ["P2 移動", "方向鍵", "P2 控制紅隊；Enter 蓄力投籃。"], ["P2 抄球", "/", "P2 靠近 P1 時按 / 嘗試抄球。"], ["籃板", "靠近落球處", "投失後靠近球，取得下一回合球權。"]]
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
	var fill := Color("4f9cff") if primary else Color(0.14, 0.22, 0.42, 0.86)
	if hover:
		fill = fill.lightened(0.12)
	panel(rect, fill, Color("9dd9ff") if primary else Color("4a6eaa"), 9.0)
	centered_text(value, rect.position + rect.size * 0.5, rect.size.x, 10, NAVY_950 if primary else Color("b9cae7"))


func draw_world() -> void:
	if generated_art and court_texture != null:
		draw_texture_rect(court_texture, WORLD_RECT, false, Color(1.0, 1.0, 1.0, 0.96))
		draw_rect(WORLD_RECT, Color(0.02, 0.04, 0.12, 0.08))
	else:
		draw_rect(Rect2(WORLD_RECT.position, Vector2(WORLD_RECT.size.x, 210.0)), Color("102b52"))
		draw_circle(Vector2(707.0, 247.0), 47.0, Color(0.97, 0.83, 0.58, 0.10))
		draw_circle(Vector2(707.0, 247.0), 15.0, Color("ffeab3"))
		for index in GameData.SKYLINE.size():
			var building: Dictionary = GameData.SKYLINE[index]
			var bx: float = float(building["x"]) + 40.0
			var by: float = 394.0 - float(building["h"])
			var bw: float = float(building["w"])
			draw_rect(Rect2(bx, by, bw, float(building["h"]) + 16.0), Color("162e54") if index % 2 == 0 else Color("19355e"))
			for row in int(float(building["h"]) / 24.0):
				for col in int(maxf(1.0, bw / 18.0)):
					if (row * 3 + col + index) % 4 == 0:
						draw_rect(Rect2(bx + 8.0 + col * 17.0, by + 12.0 + row * 22.0, 5.0, 7.0), Color(1.0, 0.76, 0.38, 0.55))
		draw_rect(Rect2(40.0, 375.0, 814.0, 65.0), Color(0.04, 0.11, 0.19, 0.5))
		for x in range(40, 855, 18):
			draw_line(Vector2(x, 375.0), Vector2(x + 34.0, 440.0), Color(0.13, 0.23, 0.34, 0.65), 1.0)
			draw_line(Vector2(x + 34.0, 375.0), Vector2(x, 440.0), Color(0.13, 0.23, 0.34, 0.65), 1.0)
		for y in [376.0, 407.0, 439.0]:
			draw_line(Vector2(40.0, y), Vector2(854.0, y), Color(0.56, 0.70, 0.77, 0.28), 2.0)
		draw_rect(Rect2(40.0, 439.0, 814.0, 203.0), Color("9a7156"))
		for i in 7:
			var y := 444.0 + i * 29.0
			draw_line(Vector2(40.0, y), Vector2(854.0, y + 16.0), Color(1.0, 0.87, 0.64, 0.18), 2.0)
		for x in range(-100, 950, 108):
			draw_line(Vector2(x, 438.0), Vector2(x + 100.0, 642.0), Color(0.18, 0.10, 0.14, 0.19), 1.0)
		draw_arc(Vector2(624.0, FLOOR_Y), 94.0, -PI * 0.5, PI * 0.5, 32, Color(1.0, 0.94, 0.78, 0.75), 3.0)
		draw_arc(Vector2(530.0, FLOOR_Y), 166.0, -PI * 0.5, PI * 0.5, 40, Color(1.0, 0.94, 0.78, 0.30), 2.0)
		draw_line(Vector2(624.0, 439.0), Vector2(624.0, FLOOR_Y + 3.0), Color(1.0, 0.94, 0.78, 0.62), 3.0)
		draw_arc(Vector2(530.0, FLOOR_Y), 46.0, 0.0, TAU, 24, Color(1.0, 0.94, 0.78, 0.68), 3.0)
		label_text("PAW", Vector2(58.0, 490.0), 22, Color(0.94, 0.67, 0.44, 0.55))
		label_text("HOOPS", Vector2(52.0, 515.0), 17, Color(0.94, 0.67, 0.44, 0.48))
		for x in [74.0, 410.0, 824.0]:
			draw_line(Vector2(x, 320.0), Vector2(x, 378.0), Color(0.08, 0.13, 0.20, 0.9), 5.0)
			draw_circle(Vector2(x, 318.0), 34.0, Color(1.0, 0.83, 0.48, 0.07))
			draw_oval(Vector2(x, 317.0), 14.0, 5.0, Color("fff0b9"))
	if generated_art and protagonist_group_texture != null and not running and not game_over:
		draw_texture_rect(protagonist_group_texture, Rect2(108.0, 258.0, 654.0, 368.0), false, Color(1.0, 1.0, 1.0, 0.28))
	draw_combo_badge()
	draw_hoop()
	draw_aim_guide()
	draw_cat(player.pos(), "blue", player.facing, player.bob, possession == "player")
	draw_cat(opponent.pos(), "red", opponent.facing, opponent.bob, possession == "opponent")
	var tag_lift := 244.0 if generated_art else 175.0
	draw_tag(Vector2(player.x, player.y - tag_lift), "P1", BLUE, possession == "player")
	draw_tag(Vector2(opponent.x, opponent.y - tag_lift), "P2", opponent_color(), possession == "opponent")
	draw_ball()
	draw_mobile_controls()
	draw_effects()


func draw_combo_badge() -> void:
	if not running or combo < 2:
		return
	var progress: float = clampf(combo_timer / GameData.COMBO_WINDOW, 0.0, 1.0)
	var badge := Rect2(54.0, 202.0, 156.0, 32.0)
	panel(badge, Color(0.31, 0.16, 0.50, 0.84), Color(0.79, 0.55, 1.0, 0.72), 11.0)
	centered_text("連續命中 x%d" % combo, badge.position + Vector2(78.0, 12.0), 145.0, 12, Color("fff0a8"))
	draw_rect(Rect2(badge.position + Vector2(8.0, 26.0), Vector2(140.0 * progress, 2.0)), GOLD)


func draw_oval(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)


func draw_hoop() -> void:
	draw_line(Vector2(812.0, 439.0), Vector2(812.0, 229.0), Color(0.08, 0.13, 0.19, 0.95), 9.0)
	draw_line(Vector2(812.0, 229.0), Vector2(766.0, 214.0), Color(0.08, 0.13, 0.19, 0.95), 5.0)
	var board := PackedVector2Array([Vector2(721.0, 221.0), Vector2(793.0, 202.0), Vector2(793.0, 315.0), Vector2(721.0, 332.0)])
	draw_colored_polygon(board, Color(0.82, 0.89, 0.92, 0.87))
	draw_polyline(PackedVector2Array([board[0], board[1], board[2], board[3], board[0]]), Color(0.11, 0.16, 0.25, 0.9), 4.0)
	draw_rect(Rect2(736.0, 244.0, 45.0, 45.0), Color(0.10, 0.16, 0.25, 0.78), false, 3.0)
	draw_circle(HOOP, 40.0, Color(1.0, 0.57, 0.16, 0.06))
	draw_arc(HOOP, 28.0, 0.0, TAU, 32, Color("e87426"), 5.0)
	for i in range(-3, 4):
		draw_line(Vector2(HOOP.x + i * 7.0, RIM_Y + 4.0), Vector2(HOOP.x + i * 4.5, RIM_Y + 41.0), Color(1.0, 0.92, 0.86, 0.72), 1.5)
	draw_arc(Vector2(HOOP.x, RIM_Y + 3.0), 31.0, 0.0, PI, 20, Color(1.0, 0.92, 0.86, 0.72), 1.5)


func draw_aim_guide() -> void:
	if not charging:
		return
	var actor := player if charging_shooter == "player" else opponent
	if possession != charging_shooter:
		return
	var start := Vector2(actor.x - actor.facing * 52.0, actor.y - 100.0)
	var flight_time := GameRules.shot_flight_time(absf(HOOP.x - actor.x))
	var velocity := GameRules.ballistic_velocity(start, Vector2(HOOP.x, RIM_Y - 6.0), GameBall.GRAVITY, flight_time)
	velocity *= GameRules.shot_power(charge)
	var previous := start
	for i in range(1, 22):
		var t := float(i) * 0.055
		var point := Vector2(start.x + velocity.x * t, start.y + velocity.y * t + 0.5 * GameBall.GRAVITY * t * t)
		if point.y > FLOOR_Y - 8.0:
			break
		if i % 2 == 0:
			draw_line(previous, point, Color(0.73, 0.88, 1.0, 0.62), 2.0)
		previous = point
	draw_circle(HOOP, 34.0, Color(0.35, 0.92, 0.64, 0.10))
	var meter_rect := Rect2(actor.x - 48.0, actor.y - 170.0, 96.0, 9.0)
	panel(meter_rect, Color(0.02, 0.05, 0.12, 0.86), Color("47628f"), 4.0)
	draw_rect(Rect2(meter_rect.position + Vector2(2.0, 2.0), Vector2(92.0 * charge, 5.0)), Color("67d79b") if GameRules.is_sweet(charge) else Color("ffd16b"))
	centered_text("POWER", Vector2(meter_rect.position.x + 48.0, meter_rect.position.y - 6.0), 80.0, 8, Color(0.86, 0.95, 0.88, 0.9))


func draw_tag(position: Vector2, value: String, color: Color, active: bool) -> void:
	var fill := color if active else color.darkened(0.25)
	panel(Rect2(position.x - 18.0, position.y, 36.0, 21.0), fill, Color(1.0, 1.0, 1.0, 0.25), 6.0)
	centered_text(value, position + Vector2(0.0, 10.0), 36.0, 10, Color.WHITE)


func draw_cat(position: Vector2, team: String, facing: float, bob: float, active: bool) -> void:
	var is_blue := team == "blue"
	var player_tint := player_color()
	var opponent_tint := opponent_color()
	var main := player_tint.darkened(0.20) if is_blue else opponent_tint.darkened(0.10)
	var light := player_tint.lightened(0.18) if is_blue else opponent_tint.lightened(0.18)
	var dark := player_tint.darkened(0.42) if is_blue else opponent_tint.darkened(0.42)
	var skin := Color("fff5e8") if is_blue else Color("f8ede2")
	var bounce := sin(bob) * (2.4 if active else 1.2)
	draw_set_transform(drawing_offset + (position + Vector2(0.0, bounce)) * drawing_scale, 0.0, Vector2(facing * drawing_scale, drawing_scale))
	if generated_art:
		var cat_texture: Texture2D = player_court_texture() if is_blue else opponent_court_texture()
		draw_oval(Vector2(0.0, 3.0), 78.0, 13.0, Color(0.02, 0.03, 0.08, 0.42))
		draw_texture_rect(cat_texture, Rect2(-112.0, -240.0, 224.0, 240.0), false, Color.WHITE)
		if active:
			draw_arc(Vector2(0.0, -112.0), 119.0, 0.0, TAU, 36, Color(player_tint, 0.72) if is_blue else Color(opponent_tint, 0.72), 2.0)
		draw_set_transform(drawing_offset, 0.0, Vector2(drawing_scale, drawing_scale))
		return
	draw_oval(Vector2(0.0, 4.0), 47.0, 9.0, Color(0.04, 0.03, 0.08, 0.37))
	draw_arc(Vector2(-26.0, -77.0), 34.0, -2.4, 0.55, 20, skin, 12.0)
	draw_arc(Vector2(-26.0, -77.0), 34.0, -2.4, 0.55, 20, dark, 3.0)
	panel(Rect2(-23.0, -48.0, 15.0, 37.0), skin, Color(1.0, 1.0, 1.0, 0.13), 6.0)
	panel(Rect2(8.0, -48.0, 15.0, 37.0), skin, Color(1.0, 1.0, 1.0, 0.13), 6.0)
	panel(Rect2(-29.0, -17.0, 28.0, 13.0), dark, Color(1.0, 1.0, 1.0, 0.16), 5.0)
	panel(Rect2(6.0, -17.0, 28.0, 13.0), dark, Color(1.0, 1.0, 1.0, 0.16), 5.0)
	draw_line(Vector2(-24.0, -14.0), Vector2(-8.0, -14.0), Color(1.0, 1.0, 1.0, 0.55), 2.0)
	draw_line(Vector2(12.0, -14.0), Vector2(28.0, -14.0), Color(1.0, 1.0, 1.0, 0.55), 2.0)
	var body := PackedVector2Array([Vector2(-34.0, -116.0), Vector2(-22.0, -127.0), Vector2(22.0, -127.0), Vector2(34.0, -116.0), Vector2(27.0, -48.0), Vector2(-27.0, -48.0)])
	draw_colored_polygon(body, main)
	draw_line(Vector2(-27.0, -112.0), Vector2(-23.0, -52.0), Color(1.0, 1.0, 1.0, 0.45), 2.0)
	draw_line(Vector2(27.0, -112.0), Vector2(23.0, -52.0), Color(1.0, 1.0, 1.0, 0.45), 2.0)
	centered_text("23", Vector2(0.0, -78.0), 34.0, 17, Color(1.0, 1.0, 1.0, 0.88))
	draw_line(Vector2(27.0, -105.0), Vector2(49.0, -72.0), skin, 12.0)
	draw_line(Vector2(-27.0, -105.0), Vector2(-49.0, -78.0), skin, 12.0)
	draw_circle(Vector2(0.0, -149.0), 31.0, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-28.0, -166.0), Vector2(-24.0, -196.0), Vector2(-3.0, -172.0)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(28.0, -166.0), Vector2(24.0, -196.0), Vector2(3.0, -172.0)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-22.0, -170.0), Vector2(-20.0, -186.0), Vector2(-8.0, -173.0)]), Color("e8a0a9"))
	draw_colored_polygon(PackedVector2Array([Vector2(22.0, -170.0), Vector2(20.0, -186.0), Vector2(8.0, -173.0)]), Color("e8a0a9"))
	draw_arc(Vector2(0.0, -164.0), 27.0, PI, TAU, 20, light, 8.0)
	if not is_blue:
		draw_colored_polygon(PackedVector2Array([Vector2(2.0, -181.0), Vector2(17.0, -168.0), Vector2(6.0, -159.0)]), Color("f18b3c"))
	draw_circle(Vector2(-11.0, -150.0), 5.0, Color("1b1b2b"))
	draw_circle(Vector2(11.0, -150.0), 5.0, Color("1b1b2b"))
	draw_circle(Vector2(-9.0, -152.0), 1.6, Color.WHITE)
	draw_circle(Vector2(13.0, -152.0), 1.6, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(-3.0, -138.0), Vector2(3.0, -138.0), Vector2(0.0, -133.0)]), Color("ec8b8b"))
	draw_arc(Vector2(0.0, -132.0), 9.0, 0.2, PI - 0.2, 8, Color(0.35, 0.17, 0.25, 0.65), 1.2)
	draw_line(Vector2(-8.0, -138.0), Vector2(-39.0, -144.0), Color(1.0, 1.0, 1.0, 0.63), 1.0)
	draw_line(Vector2(-8.0, -133.0), Vector2(-40.0, -133.0), Color(1.0, 1.0, 1.0, 0.63), 1.0)
	draw_line(Vector2(8.0, -138.0), Vector2(39.0, -144.0), Color(1.0, 1.0, 1.0, 0.63), 1.0)
	draw_line(Vector2(8.0, -133.0), Vector2(40.0, -133.0), Color(1.0, 1.0, 1.0, 0.63), 1.0)
	if active:
		draw_arc(Vector2(0.0, -93.0), 47.0, 0.0, TAU, 28, Color(player_tint, 0.85) if is_blue else Color(opponent_tint, 0.85), 1.5)
	draw_set_transform(drawing_offset, 0.0, Vector2(drawing_scale, drawing_scale))


func draw_ball() -> void:
	var p := ball.pos()
	var height := clampf((FLOOR_Y - p.y) / 280.0, 0.0, 1.0)
	var shadow_scale: float = clampf(1.0 - height * 0.62, 0.28, 1.0)
	draw_oval(Vector2(p.x, FLOOR_Y - 6.0), 17.0 * shadow_scale, 6.0 * shadow_scale, Color(0.02, 0.03, 0.08, 0.32 * shadow_scale))
	if ball.in_flight or ball.loose:
		for i in ball.trail.size():
			var alpha: float = float(i + 1) / float(maxi(ball.trail.size(), 1)) * 0.28
			draw_circle(ball.trail[i], 5.0 + float(i) * 0.4, Color(1.0, 0.62, 0.22, alpha))
	draw_set_transform(drawing_offset + p * drawing_scale, ball.spin, Vector2(drawing_scale, drawing_scale))
	draw_circle(Vector2.ZERO, 28.0, Color(1.0, 0.58, 0.20, 0.14 if ball.in_flight else 0.08))
	draw_circle(Vector2.ZERO, GameBall.RADIUS, Color("ed7f29"))
	draw_circle(Vector2(-4.0, -5.0), 5.0, Color(1.0, 0.82, 0.45, 0.35))
	draw_arc(Vector2.ZERO, 14.0, -0.9, 0.9, 16, Color(0.38, 0.13, 0.08, 0.78), 1.7)
	draw_arc(Vector2.ZERO, 14.0, PI - 0.9, PI + 0.9, 16, Color(0.38, 0.13, 0.08, 0.78), 1.7)
	draw_arc(Vector2.ZERO, 14.0, 0.2, PI - 0.2, 16, Color(0.38, 0.13, 0.08, 0.78), 1.7)
	draw_set_transform(drawing_offset, 0.0, Vector2(drawing_scale, drawing_scale))


func draw_mobile_controls() -> void:
	var joy_center := JOYSTICK_RECT.position + JOYSTICK_RECT.size * 0.5
	draw_circle(joy_center, 58.0, Color(0.70, 0.82, 0.98, 0.07))
	draw_arc(joy_center, 58.0, 0.0, TAU, 32, Color(0.80, 0.90, 1.0, 0.28), 1.5)
	var knob := joy_center + joystick * 34.0
	draw_circle(knob, 18.0, Color(0.88, 0.93, 1.0, 0.74))
	draw_action_circle(PASS_RECT.position + PASS_RECT.size * 0.5, 28.0, PURPLE, "↗", "傳球")
	draw_action_circle(STEAL_RECT.position + STEAL_RECT.size * 0.5, 28.0, GREEN, "✋", "抄球")
	draw_action_circle(SPRINT_RECT.position + SPRINT_RECT.size * 0.5, 28.0, BLUE, "⚡", "衝刺")
	draw_action_circle(SHOT_RECT.position + SHOT_RECT.size * 0.5, 41.0, Color("ec8529"), "🏀", "投籃")


func draw_action_circle(center: Vector2, radius: float, color: Color, icon: String, caption: String) -> void:
	var is_hover := Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)).has_point(mouse_design)
	draw_circle(center, radius + 4.0, Color(color.r, color.g, color.b, 0.13))
	draw_circle(center, radius, color.lightened(0.10) if is_hover else color)
	draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.48), 1.4)
	centered_text(icon, center + Vector2(0.0, -5.0), radius * 1.7, int(radius * 0.55), Color.WHITE)
	centered_text(caption, center + Vector2(0.0, radius * 0.58), radius * 1.9, 8, Color.WHITE)
	if caption == "投籃" and charging:
		draw_arc(center, radius + 7.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 26, GOLD, 3.0)


func draw_effects() -> void:
	var active_skill_vfx := skill_vfx_texture()
	if generated_art and skill_flash_timer > 0.0 and active_skill_vfx != null:
		var vfx_alpha: float = clampf(skill_flash_timer / 0.75, 0.0, 1.0) * 0.78
		var vfx_rect := Rect2(player.x - 142.0, player.y - 272.0, 284.0, 284.0)
		if skill_flash == GameData.SKILL_FIRE:
			vfx_rect = Rect2(player.x - 132.0, player.y - 286.0, 264.0, 294.0)
		draw_texture_rect(active_skill_vfx, vfx_rect, false, Color(1.0, 1.0, 1.0, vfx_alpha))
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
		var flash_color: Color = Color("ff7c35") if skill_flash == GameData.SKILL_FIRE else BLUE_LIGHT
		draw_rect(Rect2(40.0, 184.0, 814.0, 458.0), Color(flash_color, skill_flash_timer / 0.75 * 0.10))


func skill_vfx_texture() -> Texture2D:
	match skill_flash:
		GameData.SKILL_FIRE:
			return fire_dunk_vfx_texture
		GameData.SKILL_STEPBACK:
			return three_pointer_vfx_texture
		GameData.SKILL_DASH:
			return crossover_vfx_texture
		_:
			return null


func draw_star(center: Vector2, outer: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := outer if i % 2 == 0 else outer * 0.44
		var angle := -PI * 0.5 + float(i) * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)


func draw_right_rail() -> void:
	var rail_fill := CREAM if generated_art else Color(0.055, 0.10, 0.22, 0.88)
	var rail_border := Color("b6c6de") if generated_art else Color("2e4a7e")
	panel(RIGHT_RECT, rail_fill, rail_border, 20.0)
	label_text("01", Vector2(910.0, 130.0), 9, Color("6f9fea"))
	label_text("遊戲特色", Vector2(934.0, 131.0), 16, INK if generated_art else TEXT)
	draw_line(Vector2(1006.0, 126.0), Vector2(1237.0, 126.0), Color(0.18, 0.30, 0.52, 0.35) if generated_art else Color(0.38, 0.57, 0.85, 0.35), 1.0)
	var feature_rows := [
		["⚡", "簡單操作，輕鬆上手", "方向鍵＋動作鍵，馬上開始街頭對決。", GOLD],
		["◎", "精準投籃，挑戰手感", "蓄力對準綠色區域，享受空心入網。", GREEN],
		["✦", "必殺技能，逆轉比賽", "累積能量，釋放火焰灌籃與急停三分。", BLUE_LIGHT],
		["◆", "可愛角色，多變造型", "解鎖球衣、籃球與鞋子，打造球星。", Color("ef8fff")]
	]
	for i in feature_rows.size():
		var row_y := 156.0 + i * 47.0
		draw_circle(Vector2(927.0, row_y + 12.0), 18.0, Color(feature_rows[i][3], 0.16))
		if generated_art and feature_texture != null:
			var feature_source := Rect2(float(i % 2) * 627.0 + 8.0, float(i / 2) * 627.0 + 8.0, 611.0, 611.0)
			draw_texture_rect_region(feature_texture, Rect2(909.0, row_y - 6.0, 36.0, 36.0), feature_source, Color.WHITE)
		else:
			centered_text(String(feature_rows[i][0]), Vector2(927.0, row_y + 11.0), 28.0, 13, Color.WHITE)
		label_text(String(feature_rows[i][1]), Vector2(953.0, row_y + 9.0), 10, INK if generated_art else TEXT)
		label_text(String(feature_rows[i][2]), Vector2(953.0, row_y + 23.0), 8, INK_MUTED if generated_art else MUTED)
	panel(Rect2(906.0, 359.0, 334.0, 168.0), Color(0.85, 0.88, 0.95, 0.96), Color("b7ccef"), 14.0)
	label_text("02", Vector2(920.0, 382.0), 9, Color("477ac4"))
	label_text("投籃系統", Vector2(944.0, 383.0), 16, Color("202f50"))
	var step_x := [930.0, 1005.0, 1081.0, 1160.0]
	var step_labels := ["按住投籃", "調整力量", "放開按鈕", "投籃出手"]
	if generated_art and shooting_guide_texture != null:
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
	draw_line(Vector2(922.0, 496.0), Vector2(1223.0, 496.0), Color(0.35, 0.80, 0.59, 0.65), 3.0)
	centered_text("綠色甜蜜點 ＝ 高命中率", Vector2(1072.0, 514.0), 210.0, 8, Color("7d8ca9"))
	label_text("LIVE", Vector2(910.0, 553.0), 9, Color("2e7cc8"))
	label_text("球員狀態", Vector2(910.0, 571.0), 15, INK if generated_art else TEXT)
	panel(Rect2(1155.0, 548.0, 68.0, 24.0), Color(0.13, 0.38, 0.29, 0.45), Color(0.35, 0.85, 0.62, 0.35), 8.0)
	centered_text("P1 持球" if possession == "player" else "P2 持球" if possession == "opponent" else "球在空中", Vector2(1189.0, 560.0), 64.0, 8, GREEN if possession == "player" else GOLD)
	draw_circle(Vector2(932.0, 611.0), 20.0, player_color())
	if generated_art:
		draw_cat_portrait(player_texture_for_selection(), Rect2(912.0, 591.0, 40.0, 40.0))
	else:
		centered_text("🐱", Vector2(932.0, 611.0), 35.0, 17, TEXT)
	label_text(player_display_name(), Vector2(962.0, 606.0), 11, INK if generated_art else TEXT)
	label_text("%s · Lv. 5" % player_role(), Vector2(962.0, 620.0), 8, INK_MUTED if generated_art else MUTED)
	draw_circle(Vector2(1182.0, 607.0), 25.0, Color("193c74"))
	draw_arc(Vector2(1182.0, 607.0), 25.0, -PI * 0.5, -PI * 0.5 + TAU * energy / 100.0, 25, PURPLE, 3.0)
	centered_text("%d" % int(energy), Vector2(1182.0, 606.0), 45.0, 12, BLUE_LIGHT)
	centered_text("ENERGY", Vector2(1182.0, 620.0), 52.0, 6, Color("9cb0d7"))
	label_text("體力", Vector2(912.0, 650.0), 8, INK_MUTED if generated_art else MUTED)
	draw_bar(Rect2(944.0, 645.0, 176.0, 6.0), stamina / 100.0, GREEN)
	label_text("%d/100" % int(stamina), Vector2(1128.0, 652.0), 8, INK_MUTED if generated_art else Color("bccbea"))
	label_text("必殺", Vector2(912.0, 670.0), 8, INK_MUTED if generated_art else MUTED)
	draw_bar(Rect2(944.0, 665.0, 176.0, 6.0), energy / 100.0, PURPLE)
	label_text("%d%%" % int(energy), Vector2(1128.0, 672.0), 8, INK_MUTED if generated_art else Color("bccbea"))


func draw_bar(rect: Rect2, amount: float, color: Color) -> void:
	panel(rect, Color(0.02, 0.05, 0.12, 0.8), Color(0.22, 0.34, 0.56, 0.45), 3.0)
	draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), Vector2(maxf(0.0, rect.size.x - 2.0) * clampf(amount, 0.0, 1.0), rect.size.y - 2.0)), color)


func draw_bottom_cards() -> void:
	var bottom_fill := CREAM if generated_art else Color(0.055, 0.10, 0.22, 0.86)
	var bottom_border := Color("b6c6de") if generated_art else Color("2e4a7e")
	var bottom_text := INK if generated_art else TEXT
	var bottom_muted := INK_MUTED if generated_art else MUTED
	panel(BOTTOM_RECT, bottom_fill, bottom_border, 16.0)
	if generated_art and character_showcase_texture != null:
		draw_texture_rect(character_showcase_texture, Rect2(111.0, 713.0, 442.0, 84.0), false, Color(1.0, 1.0, 1.0, 0.11))
	if generated_art and skill_showcase_texture != null:
		draw_texture_rect(skill_showcase_texture, Rect2(575.0, 735.0, 292.0, 61.0), false, Color(1.0, 1.0, 1.0, 0.18))
	label_text("03  角色設定", Vector2(43.0, 729.0), 11, Color("83b5ff"))
	draw_circle(Vector2(80.0, 764.0), 25.0, player_color())
	if generated_art:
		draw_cat_portrait(player_texture_for_selection(), Rect2(55.0, 739.0, 50.0, 50.0))
	else:
		centered_text("🐱", Vector2(80.0, 762.0), 44.0, 20, TEXT)
	label_text(player_display_name(), Vector2(116.0, 756.0), 13, bottom_text)
	label_text("%s · %s" % [player_team_label(), player_role()], Vector2(116.0, 771.0), 8, player_color().lightened(0.12))
	label_text("C / 點擊切換角色", Vector2(116.0, 786.0), 7, bottom_muted)
	label_text("速度", Vector2(258.0, 751.0), 8, bottom_muted)
	draw_bar(Rect2(291.0, 747.0, 76.0, 6.0), player_stat(0) / 100.0, BLUE_LIGHT)
	label_text("投籃", Vector2(258.0, 768.0), 8, bottom_muted)
	draw_bar(Rect2(291.0, 764.0, 76.0, 6.0), player_stat(1) / 100.0, GOLD)
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
	label_text("04  必殺技能", Vector2(580.0, 729.0), 11, Color("83b5ff"))
	draw_skill_chip(Rect2(580.0, 741.0, 130.0, 42.0), "🔥", "火焰灌籃", GOLD, 0)
	draw_skill_chip(Rect2(718.0, 741.0, 130.0, 42.0), "💠", "後撤步三分", BLUE_LIGHT, 1)
	label_text("05  遊戲進程", Vector2(914.0, 729.0), 11, Color("83b5ff"))
	draw_line(Vector2(924.0, 762.0), Vector2(1228.0, 762.0), Color(0.37, 0.61, 0.96, 0.5), 3.0)
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
	panel(rect, Color(color, 0.14), Color(color, 0.38), 9.0)
	var skill_text := INK if generated_art else TEXT
	var skill_muted := INK_MUTED if generated_art else MUTED
	if generated_art and skill_texture != null and skill_index >= 0:
		var skill_source := Rect2(float(skill_index % 2) * 627.0 + 8.0, float(skill_index / 2) * 627.0 + 8.0, 611.0, 611.0)
		draw_texture_rect_region(skill_texture, Rect2(rect.position + Vector2(3.0, 4.0), Vector2(34.0, 34.0)), skill_source, Color.WHITE)
	else:
		centered_text(icon, Vector2(rect.position.x + 19.0, rect.position.y + 20.0), 26.0, 16, skill_text)
	label_text(title, Vector2(rect.position.x + 36.0, rect.position.y + 19.0), 9, skill_text)
	label_text("按鍵施放", Vector2(rect.position.x + 36.0, rect.position.y + 31.0), 7, skill_muted)
