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
