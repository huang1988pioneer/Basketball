class_name GameRules
extends Object

const SWEET_MIN := 0.61
const SWEET_MAX := 0.83
const STEAL_RANGE := 148.0


static func is_sweet(charge: float) -> bool:
	return charge >= SWEET_MIN and charge <= SWEET_MAX


static func sweet_quality(charge: float) -> float:
	return 1.0 - minf(1.0, absf(charge - GameData.SWEET_CHARGE) / GameData.SWEET_CHARGE)


static func shot_chance(charge: float, distance: float, shot_stat: float, three_stat: float, next_bonus: float, mode_bonus: float) -> float:
	var distance_bonus := clampf(1.0 - absf(distance - GameData.THREE_DISTANCE) / 800.0, 0.35, 1.0)
	var shot_bonus := (shot_stat - 76.0) * 0.0035
	var three_bonus := (three_stat - 68.0) * 0.0025 if distance > GameData.THREE_DISTANCE else 0.0
	return clampf(0.18 + sweet_quality(charge) * 0.68 + distance_bonus * 0.08 + shot_bonus + three_bonus + next_bonus + mode_bonus, 0.08, 0.96)


static func is_automatic_make(charge: float) -> bool:
	return sweet_quality(charge) > 0.84


static func points_for(distance: float) -> int:
	return 3 if distance > GameData.THREE_DISTANCE else 2


static func speed_factor(speed_stat: float) -> float:
	return clampf(0.88 + speed_stat / 500.0, 0.92, 1.12)


static func steal_chance(defense_stat: float, baseline_stat: float, base_chance: float, min_chance: float, max_chance: float) -> float:
	return clampf(base_chance + (defense_stat - baseline_stat) * 0.004, min_chance, max_chance)


static func shot_flight_time(distance: float, dunk: bool = false) -> float:
	if dunk:
		return clampf(0.58 + distance / 1800.0, 0.54, 0.82)
	return clampf(0.70 + distance / 1400.0, 0.68, 1.28)


static func ballistic_velocity(start: Vector2, target: Vector2, gravity: float, time: float) -> Vector2:
	var t: float = maxf(0.12, time)
	return Vector2((target.x - start.x) / t, (target.y - start.y) / t - 0.5 * gravity * t)


static func shot_power(charge: float) -> float:
	return clampf(1.0 + (charge - GameData.SWEET_CHARGE) * 0.28, 0.58, 1.14)


static func shot_spread(shot_stat: float, next_bonus: float, mode_bonus: float) -> float:
	var spread := 0.052 - (shot_stat - 60.0) * 0.00042 - next_bonus * 0.09 + maxf(0.0, -mode_bonus) * 0.10
	return clampf(spread, 0.008, 0.075)


static func ai_charge(accuracy: float) -> float:
	var error := (1.0 - accuracy) * 0.30
	return clampf(GameData.SWEET_CHARGE + randf_range(-error, error), 0.20, 1.0)


static func apply_spread(velocity: Vector2, spread: float) -> Vector2:
	if spread <= 0.0:
		return velocity
	return Vector2(
		velocity.x * (1.0 + randf_range(-spread, spread)),
		velocity.y * (1.0 + randf_range(-spread * 0.65, spread * 0.65))
	)
