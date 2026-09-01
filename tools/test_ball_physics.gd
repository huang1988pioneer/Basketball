extends SceneTree

## Headless check that shots follow gravity and the ball stays visible.


func _init() -> void:
	var failed := 0
	failed += _expect("sweet spot from the elbow goes in", _simulate_shot(329.0, 0.72), "scored")
	failed += _expect("green charge window still goes in", _simulate_shot(329.0, 0.66), "scored")
	failed += _expect("high sweet charge still goes in", _simulate_shot(329.0, 0.83), "scored")
	failed += _expect("under-charged shot falls short", _simulate_shot(329.0, 0.28), "missed")
	failed += _expect("close-range sweet shot goes in", _simulate_shot(600.0, 0.72), "scored")
	failed += _expect("dunk trajectory goes in", _simulate_shot(601.0, 0.72, true), "scored")
	failed += _expect("gravity pulls the ball down", _gravity_increases_vy(), true)
	failed += _expect("held ball stays on-screen", _held_ball_visible(), true)
	if failed > 0:
		push_error("ball physics checks failed: %d" % failed)
		quit(1)
	else:
		print("ball physics checks passed")
		quit(0)


func _simulate_shot(start_x: float, charge: float, dunk := false) -> String:
	var start := Vector2(start_x, 487.0)
	var hoop := GameData.HOOP
	var distance: float = absf(hoop.x - start.x)
	var time := GameRules.shot_flight_time(distance, dunk)
	var velocity := GameRules.ballistic_velocity(start, Vector2(hoop.x, GameData.RIM_Y - 6.0), GameBall.GRAVITY, time)
	velocity *= GameRules.shot_power(charge)
	var ball := GameBall.new()
	ball.launch(start, velocity)
	var event := ""
	var guard := 0
	while guard < 400 and (ball.in_flight or ball.loose) and event != "scored" and event != "missed":
		var step_event := ball.step(1.0 / 60.0, GameData.WORLD_RECT, hoop, GameData.RIM_Y, GameData.FLOOR_Y, GameData.BACKBOARD_X)
		if step_event != "":
			event = step_event
		guard += 1
		if ball.x < -40.0 or ball.x > 980.0 or ball.y > 720.0:
			return "out"
	if event == "":
		return "timeout"
	return event


func _gravity_increases_vy() -> bool:
	var ball := GameBall.new()
	ball.launch(Vector2(300.0, 400.0), Vector2(80.0, -120.0))
	var before := ball.vy
	ball.step(0.05, GameData.WORLD_RECT, GameData.HOOP, GameData.RIM_Y, GameData.FLOOR_Y, GameData.BACKBOARD_X)
	return ball.vy > before and ball.y != 400.0


func _held_ball_visible() -> bool:
	var ball := GameBall.new()
	ball.hold_dribble(Vector2(329.0, 487.0), 565.0, 0.2, false)
	return ball.x > 40.0 and ball.x < 854.0 and ball.y > 180.0 and ball.y < GameData.FLOOR_Y and not ball.in_flight


func _expect(label: String, actual: Variant, expected: Variant) -> int:
	if actual == expected:
		print("ok  ", label)
		return 0
	print("fail  ", label, "  got=", actual, " expected=", expected)
	return 1
