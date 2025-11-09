extends Node2D
class_name AIController2DGoal

enum ControlModes { INHERIT_FROM_SYNC, HUMAN, TRAINING, ONNX_INFERENCE, RECORD_EXPERT_DEMOS }

@export var control_mode: ControlModes = ControlModes.TRAINING
@export var onnx_model_path: String = ""
@export var reset_after: int = 2000
@export var policy_name: String = "shared_policy"   # <- lo usa sync.gd

# Rutas opcionales (si están vacías hay autodetección)
@export var player_path: NodePath
@export var goal1_path: NodePath
@export var goal2_path: NodePath

@export var death_y: float = 2000.0

# Estado RL
var done := false
var reward := 0.0
var n_steps := 0
var needs_reset := false
var heuristic := "human"

var _action := {"move": 0, "jump": false, "dash": false}

var _player: CharacterBody2D
var _goal1: Area2D
var _goal2: Area2D
var _current_goal: Area2D
var _prev_goal_dist := INF
var _goal1_reached := false
var _goal2_reached := false

func _ready() -> void:
	add_to_group("AGENT")
	_player = _resolve_player()
	if _player and _player.has_signal("died"):
		if not _player.is_connected("died", Callable(self, "_on_player_died")):
			_player.connect("died", Callable(self, "_on_player_died"))

	_goal1 = _resolve_goal(goal1_path, 1)
	_goal2 = _resolve_goal(goal2_path, 2)

	if _goal1 and _goal1.has_signal("goal_reached") and not _goal1.is_connected("goal_reached", Callable(self, "_on_goal1_reached")):
		_goal1.connect("goal_reached", Callable(self, "_on_goal1_reached"))
	if _goal2 and _goal2.has_signal("goal_reached") and not _goal2.is_connected("goal_reached", Callable(self, "_on_goal2_reached")):
		_goal2.connect("goal_reached", Callable(self, "_on_goal2_reached"))

	_current_goal = _goal1
	_reset_goal_distance_cache()

func init(player: CharacterBody2D) -> void:
	_player = player
	_reset_goal_distance_cache()

func _physics_process(_delta: float) -> void:
	n_steps += 1
	if n_steps > reset_after:
		needs_reset = true
	if _player and _player.position.y > death_y:
		done = true

	if heuristic == "human" or control_mode == ControlModes.HUMAN or control_mode == ControlModes.RECORD_EXPERT_DEMOS:
		_set_action_from_input()
		_apply_action_to_player(_action)
	else:
		_apply_action_to_player(_action)

# ========== API para sync.gd ==========
func get_info() -> Dictionary:
	return {
		"observation_space": get_obs_space(),
		"action_space": get_action_space(),
		"heuristic": heuristic,
		"policy": policy_name
	}

func get_obs() -> Dictionary:
	if _player == null:
		return {"obs": [0,0,0,0,0,0]}
	var on_floor := 1.0 if _player.is_on_floor() else 0.0
	var can_dash := 1.0 if ("canDash" in _player and _player.canDash) else 0.0
	return {"obs":[
		_player.position.x, _player.position.y,
		_player.velocity.x, _player.velocity.y,
		on_floor, can_dash
	]}

func get_obs_space() -> Dictionary: return {"obs":{"size":[6], "space":"box"}}
func get_action_space() -> Dictionary:
	return {
		"move":{"size":3,"action_type":"discrete"},
		"jump":{"size":2,"action_type":"discrete"},
		"dash":{"size":2,"action_type":"discrete"}
	}

func set_action(action: Dictionary = {}) -> void:
	if action.is_empty():
		_set_action_from_input()
	else:
		_action = {
			"move": action.get("move", 0),
			"jump": action.get("jump", false),
			"dash": action.get("dash", false)
		}

func get_action() -> Dictionary: return _action.duplicate()

func get_reward() -> float:
	var r := 0.0
	if _player:
		r += _player.velocity.x / 500.0
		if _current_goal:
			var d := _current_goal.global_position.distance_to(_player.global_position)
			if is_finite(_prev_goal_dist):
				r += clampf((_prev_goal_dist - d) / 100.0, -0.05, 0.05)
			_prev_goal_dist = d
		r -= 0.001
		if _player.position.y > death_y:
			r -= 3.0
			done = true

	if _goal1_reached:
		r += 2.5
		_goal1_reached = false
		_current_goal = _goal2
		_reset_goal_distance_cache()

	if _goal2_reached:
		r += 7.5
		_goal2_reached = false
		done = true

	return r

func get_done() -> bool: return done
func set_done_false() -> void: done = false
func zero_reward() -> void: reward = 0.0

func reset() -> void:
	n_steps = 0
	reward = 0.0
	needs_reset = false
	done = false
	_goal1_reached = false
	_goal2_reached = false
	_current_goal = _goal1
	_reset_goal_distance_cache()

func set_heuristic(h: String) -> void: heuristic = h

# ========== Internas ==========
func _set_action_from_input() -> void:
	var mv := 0
	if Input.is_action_pressed("right"): mv = 1
	elif Input.is_action_pressed("left"): mv = -1
	_action = {"move":mv, "jump":Input.is_action_just_pressed("jump"), "dash":Input.is_action_just_pressed("dash")}

func _apply_action_to_player(action: Dictionary) -> void:
	if _player == null: return
	var mv := int(clamp(action.get("move", 0), -1, 1))
	var j := bool(action.get("jump", false))
	var d := bool(action.get("dash", false))
	if _player.has_method("apply_ai_action"):
		_player.apply_ai_action(mv, j, d)
	else:
		# Fallback por si alguna vez quitas el método
		if "movementInput" in _player.get_property_list().map(func(p): return p.name):
			_player.set("movementInput", mv)
		if "isJumpPressed" in _player.get_property_list().map(func(p): return p.name):
			_player.set("isJumpPressed", j)
		if "isDashPressed" in _player.get_property_list().map(func(p): return p.name):
			_player.set("isDashPressed", d)

func _resolve_player() -> CharacterBody2D:
	if player_path != NodePath(""):
		var p := get_node_or_null(player_path)
		if p is CharacterBody2D: return p
	var root := get_tree().current_scene
	if root:
		for c in root.get_children():
			if c is CharacterBody2D: return c
	return null

func _resolve_goal(p: NodePath, want_index: int) -> Area2D:
	if p != NodePath(""):
		var g := get_node_or_null(p)
		if g is Area2D: return g
	var root := get_tree().current_scene
	if root:
		var candidates: Array[Area2D] = []
		for c in root.get_children():
			if c is Area2D and c.name.to_lower().begins_with("goal_area_2d"):
				candidates.append(c)
		if candidates.size() >= want_index: return candidates[want_index-1]
	if root:
		for c in root.get_children():
			if c is Area2D:
				for k in c.get_children():
					if k is CollisionShape2D: return c
	return null

# Señales
func _on_goal1_reached() -> void: _goal1_reached = true
func _on_goal2_reached() -> void: _goal2_reached = true
func _on_player_died() -> void: reward -= 3.0; done = true

func _reset_goal_distance_cache() -> void:
	if _player and _current_goal:
		_prev_goal_dist = _current_goal.global_position.distance_to(_player.global_position)
	else:
		_prev_goal_dist = INF
