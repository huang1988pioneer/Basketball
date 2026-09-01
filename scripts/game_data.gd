class_name GameData
extends Object

const VERSION := "1.1.0"
const DESIGN_SIZE := Vector2(1280.0, 820.0)
const COURT_RECT := Rect2(24.0, 104.0, 846.0, 586.0)
const WORLD_RECT := Rect2(40.0, 184.0, 814.0, 458.0)
const RIGHT_RECT := Rect2(890.0, 104.0, 366.0, 586.0)
const BOTTOM_RECT := Rect2(24.0, 706.0, 1232.0, 94.0)
const HOOP := Vector2(766.0, 363.0)
const RIM_Y := 374.0
const FLOOR_Y := 584.0
const THREE_DISTANCE := 535.0
const SWEET_CHARGE := 0.72
const COMBO_WINDOW := 4.0
const BACKBOARD_X := 793.0
const BACKBOARD_TOP := 202.0
const BACKBOARD_BOTTOM := 332.0
const RIM_PIPE_OFFSET := 38.0
const SCORE_HALF_WIDTH := 24.0
const SCORE_RESET_DELAY := 0.85

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
const HELP_PANEL_RECT := Rect2(389.0, 180.0, 502.0, 398.0)
const HELP_CLOSE_RECT := Rect2(785.0, 204.0, 86.0, 30.0)
const SKILL_ONE_RECT := Rect2(580.0, 741.0, 130.0, 42.0)
const SKILL_TWO_RECT := Rect2(718.0, 741.0, 130.0, 42.0)
const SHOT_RECT := Rect2(752.0, 535.0, 90.0, 90.0)
const PASS_RECT := Rect2(653.0, 570.0, 58.0, 58.0)
const STEAL_RECT := Rect2(716.0, 570.0, 58.0, 58.0)
const SPRINT_RECT := Rect2(590.0, 570.0, 58.0, 58.0)
const JOYSTICK_RECT := Rect2(58.0, 527.0, 122.0, 122.0)
const PLAYER_CARD_RECT := Rect2(35.0, 714.0, 520.0, 80.0)

const SKILL_FIRE := "火焰灌籃"
const SKILL_STEPBACK := "後撤步三分"
const SKILL_DASH := "幻影變向"
const SKILL_METEOR := "流星投籃"
const SKILL_COSTS := {
	SKILL_FIRE: 34.0,
	SKILL_STEPBACK: 28.0,
	SKILL_DASH: 22.0,
	SKILL_METEOR: 40.0,
}
const CHARACTER_ORDER := ["white", "calico", "orange", "boss"]
const MODE_ORDER := ["quick", "story", "challenge", "boss", "duo"]

const MODES := {
	"quick": {"name": "快速比賽", "duration": 90.0, "target": 11, "opponent_accuracy": 0.46, "opponent_speed": 148.0, "shot_bonus": 0.04, "tag": "快速比賽 · 先得 11 分"},
	"story": {"name": "故事模式", "duration": 105.0, "target": 15, "opponent_accuracy": 0.50, "opponent_speed": 156.0, "shot_bonus": 0.02, "tag": "故事模式 · 街區 15 分戰"},
	"challenge": {"name": "挑戰模式", "duration": 60.0, "target": 18, "opponent_accuracy": 0.55, "opponent_speed": 166.0, "shot_bonus": -0.02, "tag": "挑戰模式 · 60 秒得 18 分"},
	"boss": {"name": "Boss 挑戰", "duration": 120.0, "target": 21, "opponent_accuracy": 0.67, "opponent_speed": 183.0, "shot_bonus": -0.05, "tag": "Boss 挑戰 · 決戰 21 分"},
	"duo": {"name": "雙人對戰", "duration": 90.0, "target": 11, "opponent_accuracy": 0.46, "opponent_speed": 148.0, "shot_bonus": 0.04, "tag": "雙人對戰 · P1/P2 先得 11 分"}
}

const CHARACTERS := {
	"white": {"name": "喵白白", "team": "BLUE PAWS", "role": "控球後衛", "color": BLUE, "stats": [76, 82, 68, 58]},
	"calico": {"name": "喵布布", "team": "RED CLAWS", "role": "得分後衛", "color": RED, "stats": [65, 88, 91, 52]},
	"orange": {"name": "喵橘橘", "team": "TEAL TIGERS", "role": "敏捷前鋒", "color": Color("24c3bf"), "stats": [92, 74, 70, 64]},
	"boss": {"name": "喵霸霸", "team": "VIOLET BOSS", "role": "全能中鋒", "color": Color("a875ff"), "stats": [48, 80, 72, 96]}
}

const OPPONENTS := {
	"quick": "calico",
	"story": "orange",
	"challenge": "calico",
	"boss": "boss",
	"duo": "calico",
}

const SKYLINE := [
	{"x": 42.0, "w": 72.0, "h": 108.0}, {"x": 110.0, "w": 52.0, "h": 75.0},
	{"x": 164.0, "w": 89.0, "h": 133.0}, {"x": 257.0, "w": 62.0, "h": 91.0},
	{"x": 326.0, "w": 112.0, "h": 150.0}, {"x": 446.0, "w": 67.0, "h": 88.0},
	{"x": 518.0, "w": 83.0, "h": 126.0}, {"x": 608.0, "w": 60.0, "h": 95.0},
	{"x": 674.0, "w": 95.0, "h": 144.0}, {"x": 777.0, "w": 66.0, "h": 102.0}
]


static func mode_info(mode_key: String) -> Dictionary:
	return MODES.get(mode_key, MODES["quick"])


static func character_info(character_id: String) -> Dictionary:
	return CHARACTERS.get(character_id, CHARACTERS["white"])


static func opponent_id(mode_key: String) -> String:
	return String(OPPONENTS.get(mode_key, "calico"))


static func opponent_info(mode_key: String) -> Dictionary:
	return character_info(opponent_id(mode_key))


static func next_in(order: Array, current: String) -> String:
	var current_index: int = order.find(current)
	var next_index: int = (current_index + 1) % order.size() if current_index >= 0 else 0
	return String(order[next_index])


static func format_clock(seconds: float) -> String:
	var safe: int = maxi(0, int(ceil(seconds)))
	return "%02d:%02d" % [safe / 60, safe % 60]
