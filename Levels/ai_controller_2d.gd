extends Node2D
class_name AIController2D2

enum ControlModes {HUMAN, TRAINING, ONNX_INFERENCE}

@export var control_mode: ControlModes = ControlModes.TRAINING
@export var player_path: NodePath
@export var goal_path: NodePath
@export var death_y: float = 2000.0
@export var reset_after: int = 1000

var heuristic := "human"
var done := false
var reward := 0.0
var needs_reset := false

var _player: CharacterBody2D
var _goal: Area2D

var _action: Dictionary = { "move": 0, "jump": false, "dash": false }

var _goal_reached := false
var _prev_goal_dist := INF


func _ready() -> void:
	add_to_group("AGENT")
	_setup_player_and_goal()
	_reset_goal_distance_cache()
	print("[AIController2D] ready -> player:%s goal:%s" % [str(_player), str(_goal)])


func _physics_process(_delta: float) -> void:
	# Si Sync pide reset, reseteamos aquí
	if needs_reset:
		_do_reset()
		return

	if not _player:
		return

	# Aplicar SIEMPRE la última acción recibida desde Python
	if _player.has_method("apply_ai_action"):
		_player.apply_ai_action(
			int(_action["move"]),
			bool(_action["jump"]),
			bool(_action["dash"])
		)

	# checar caída
	if _player.position.y > death_y:
		done = true


# ───────── CONFIGURACIÓN PLAYER / GOAL ─────────
func _setup_player_and_goal() -> void:
	# PLAYER
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path) as CharacterBody2D
	if _player == null:
		_player = _autodetect_player()

	# GOAL
	if goal_path != NodePath(""):
		_goal = get_node_or_null(goal_path) as Area2D
	if _goal == null:
		_goal = _autodetect_goal()

	if _goal and not _goal.is_connected("body_entered", Callable(self, "_on_goal_body_entered")):
		_goal.connect("body_entered", Callable(self, "_on_goal_body_entered"))


func _autodetect_player() -> CharacterBody2D:
	var root := get_tree().current_scene
	if root == null:
		return null

	# 1º: nodo llamado "Player"
	if root.has_node("Player"):
		var n := root.get_node("Player")
		if n is CharacterBody2D:
			return n

	# 2º: primer CharacterBody2D que encuentre
	for c in root.get_children():
		if c is CharacterBody2D:
			return c
	return null


func _autodetect_goal() -> Area2D:
	var root := get_tree().current_scene
	if root == null:
		return null

	# 1º: grupo "GOAL"
	var group := get_tree().get_nodes_in_group("GOAL")
	if group.size() > 0 and group[0] is Area2D:
		return group[0]

	# 2º: primera Area2D que encuentre
	for c in root.get_children():
		if c is Area2D:
			return c
	return null


# ───────── API PARA SYNC / PYTHON ─────────
func get_info() -> Dictionary:
	return {
		"observation_space": get_obs_space(),
		"action_space": get_action_space()
	}

func get_obs() -> Dictionary:
	if _player == null:
		return {"obs": [0, 0, 0, 0, 0, 0]}

	var on_floor := 1.0 if _player.is_on_floor() else 0.0
	var can_dash := 1.0
	if "canDash" in _player:
		can_dash = 1.0 if _player.canDash else 0.0

	return {
		"obs": [
			_player.position.x,
			_player.position.y,
			_player.velocity.x,
			_player.velocity.y,
			on_floor,
			can_dash
		]
	}

func get_obs_space() -> Dictionary:
	return {
		"obs": {
			"size": [6],
			"space": "box"
		}
	}

func get_action_space() -> Dictionary:
	return {
		"move": {"size": 3, "action_type": "discrete"}, # izq / nada / der
		"jump": {"size": 2, "action_type": "discrete"},
		"dash": {"size": 2, "action_type": "discrete"}
	}

func set_action(action: Dictionary) -> void:
	if action.is_empty():
		return

	_action["move"] = clampi(int(action.get("move", 0)), -1, 1)
	_action["jump"] = bool(action.get("jump", false))
	_action["dash"] = bool(action.get("dash", false))

	# DEBUG: ver que llegan acciones desde Python
	print("[AIController2D] action:", _action)


func get_reward() -> float:
	var r := 0.0

	if _player:
		# Avanzar hacia la derecha
		r += _player.velocity.x / 500.0

		# Acercarse al goal
		if _goal:
			var d := _goal.global_position.distance_to(_player.global_position)
			if is_finite(_prev_goal_dist):
				r += clampf((_prev_goal_dist - d) / 100.0, -0.05, 0.05)
			_prev_goal_dist = d

		# Pequeña penalización por tiempo
		r -= 0.003

		# Caer fuera
		if _player.position.y > death_y:
			r -= 3.0
			done = true

	# Llegar al goal
	if _goal_reached:
		r += 8.0
		_goal_reached = false
		done = true

	reward = r
	return r


func get_done() -> bool:
	return done


func reset() -> void:
	_do_reset()


func _do_reset() -> void:
	needs_reset = false
	done = false
	reward = 0.0
	_goal_reached = false
	_reset_goal_distance_cache()

	if _player:
		if _player.has_method("respawn"):
			_player.respawn()
		else:
			_player.velocity = Vector2.ZERO

func zero_reward() -> void:
	reward = 0.0

func set_done_false() -> void:
	done = false

func set_heuristic(h) -> void:
	heuristic = str(h)


# ───────── UTILIDADES / SEÑALES ─────────
func _reset_goal_distance_cache() -> void:
	if _player and _goal:
		_prev_goal_dist = _goal.global_position.distance_to(_player.global_position)
	else:
		_prev_goal_dist = INF


func _on_goal_body_entered(body: Node) -> void:
	if _player and body == _player:
		_goal_reached = true
