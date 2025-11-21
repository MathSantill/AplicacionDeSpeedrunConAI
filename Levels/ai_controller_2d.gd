extends Node2D
class_name AIController2DGoal

enum ControlModes { INHERIT_FROM_SYNC, HUMAN, TRAINING, ONNX_INFERENCE, RECORD_EXPERT_DEMOS }

@export var control_mode: ControlModes = ControlModes.TRAINING
@export var onnx_model_path: String = ""
@export var reset_after: int = 1000

@export var player_path: NodePath
@export var goal_path: NodePath
@export var death_y: float = 2000.0

@export_group("Record expert demos mode")
@export var expert_demo_save_path: String
@export var remove_last_episode_key: InputEvent
@export var action_repeat: int = 1

@export_group("Multi-policy mode")
@export var policy_name: String = "shared_policy"

var done: bool = false
var reward: float = 0.0
var n_steps: int = 0
var needs_reset: bool = false
var heuristic: String = "human"

var _action: Dictionary = {"move": 0, "jump": false, "dash": false}
var _player: CharacterBody2D
var _goal: Area2D

var _goal_reached: bool = false
var _prev_goal_dist: float = INF

# ⭐ NUEVO: seguimiento de vida/daño
var _last_hp: int = 0
var _took_damage: bool = false

func _ready() -> void:
	process_priority = -10
	add_to_group("AGENT")

	# --- PLAYER ---
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path) as CharacterBody2D
	if _player == null:
		_player = _autodetect_player()
	if _player and _player.has_signal("died") and not _player.is_connected("died", Callable(self, "_on_player_died")):
		_player.connect("died", Callable(self, "_on_player_died"))

	# ⭐ guardar vida inicial si existe
	if _player and "hp" in _player:
		_last_hp = int(_player.hp)

	# --- GOAL ---
	if goal_path != NodePath(""):
		_goal = get_node_or_null(goal_path) as Area2D
	if _goal == null:
		_goal = _autodetect_goal()
	if _goal:
		if _goal.has_signal("player_reached_goal"):
			if not _goal.is_connected("player_reached_goal", Callable(self, "_on_goal_reached")):
				_goal.connect("player_reached_goal", Callable(self, "_on_goal_reached"))
		else:
			if not _goal.is_connected("body_entered", Callable(self, "_on_goal_body_entered")):
				_goal.connect("body_entered", Callable(self, "_on_goal_body_entered"))

	_reset_goal_distance_cache()

func _physics_process(_delta: float) -> void:
	# Contador de pasos y check de muerte
	n_steps += 1
	if n_steps > reset_after:
		needs_reset = true

	if _player:
		if _player.position.y > death_y:
			done = true

		# ⭐ Detectar daño por cambio en hp
		if "hp" in _player:
			var current_hp: int = int(_player.hp)
			if current_hp < _last_hp:
				_took_damage = true      # castigaremos en get_reward()
			_last_hp = current_hp

	# 🔥 CLAVE: SIEMPRE aplicamos la última acción recibida
	_apply_action_to_player(_action)

# ───────── API sync.gd / Python ─────────
func get_info() -> Dictionary:
	return {
		"observation_space": get_obs_space(),
		"action_space": get_action_space(),
		"heuristic": heuristic,
		"policy": policy_name
	}

func get_obs() -> Dictionary:
	if _player == null:
		return {"obs": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]}

	var on_floor: float = 1.0 if _player.is_on_floor() else 0.0
	var can_dash: float = 1.0
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
	var obs: Dictionary = get_obs()
	var arr: Array = obs["obs"]
	return {
		"obs": {
			"size": [arr.size()],
			"space": "box"
		}
	}

func get_action_space() -> Dictionary:
	return {
		"move": {"size": 3, "action_type": "discrete"},
		"jump": {"size": 2, "action_type": "discrete"},
		"dash": {"size": 2, "action_type": "discrete"}
	}

func set_action(action: Dictionary = {}) -> void:
	# Lo llama sync.gd con move ya mapeado a -1,0,1
	if action.is_empty():
		return
	var mv: int = clampi(int(action.get("move", 0)), -1, 1)
	var j: bool = bool(action.get("jump", false))
	var d: bool = bool(action.get("dash", false))
	_action = {"move": mv, "jump": j, "dash": d}
	# print("[AIController] set_action desde Python:", _action)

func get_action() -> Dictionary:
	return _action.duplicate()

# ───────── RECOMPENSAS ─────────
func get_reward() -> float:
	var r: float = 0.0

	if _player:
		# 1) Avanzar hacia la derecha
		r += _player.velocity.x / 500.0

		# 2) Acercarse al GOAL
		if _goal:
			var d: float = _goal.global_position.distance_to(_player.global_position)
			if is_finite(_prev_goal_dist):
				r += clampf((_prev_goal_dist - d) / 100.0, -0.05, 0.05)
			_prev_goal_dist = d

		# 3) Penalización por tiempo (un poco más alta)
		r -= 0.005

		# 4) Penalización por caer
		if _player.position.y > death_y:
			r -= 3.0
			done = true

		# 5) Penalización por recibir daño (DamageArea2D)
		if _took_damage:
			r -= 2.0     # aquí puedes ajustar la severidad
			_took_damage = false

	# 6) Recompensa por llegar al GOAL
	if _goal_reached:
		r += 8.0        # más recompensa por terminar el episodio
		_goal_reached = false
		done = true

	return r

func get_done() -> bool:
	return done

func set_done_false() -> void:
	done = false

func zero_reward() -> void:
	reward = 0.0

func reset() -> void:
	n_steps = 0
	reward = 0.0
	needs_reset = false
	done = false
	_goal_reached = false
	_took_damage = false
	_reset_goal_distance_cache()

	# ⭐ resetear hp de referencia
	if _player and "hp" in _player:
		_last_hp = int(_player.hp)

# ───────── Aplicar acción al Player ─────────
func _apply_action_to_player(action: Dictionary) -> void:
	if _player == null:
		return

	var mv: int = int(clamp(action.get("move", 0), -1, 1))
	var j: bool = bool(action.get("jump", false))
	var d: bool = bool(action.get("dash", false))

	if _player.has_method("apply_ai_action"):
		_player.apply_ai_action(mv, j, d)
	else:
		if "movementInput" in _player:
			_player.movementInput = mv
		if "isJumpPressed" in _player:
			_player.isJumpPressed = j
		if "isDashPressed" in _player:
			_player.isDashPressed = d

# ───────── Autodetección / señales / utils ─────────
func _autodetect_player() -> CharacterBody2D:
	var root: Node = get_tree().current_scene
	if root == null:
		return null
	for n in root.get_children():
		if n is CharacterBody2D:
			return n
	return null

func _autodetect_goal() -> Area2D:
	var root: Node = get_tree().current_scene
	if root == null:
		return null
	var group := get_tree().get_nodes_in_group("GOAL")
	if group.size() > 0 and group[0] is Area2D:
		return group[0]
	for n in root.get_children():
		if n is Area2D:
			return n
	return null

func _on_goal_reached(_player_node: Node = null) -> void:
	_goal_reached = true

func _on_goal_body_entered(body: Node) -> void:
	if _player and body == _player:
		_goal_reached = true

func _on_player_died() -> void:
	reward -= 3.0
	done = true

func _reset_goal_distance_cache() -> void:
	if _player and _goal:
		_prev_goal_dist = _goal.global_position.distance_to(_player.global_position)
	else:
		_prev_goal_dist = INF
