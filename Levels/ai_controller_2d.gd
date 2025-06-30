extends Node2D

enum ControlModes {
	INHERIT_FROM_SYNC,
	HUMAN,
	TRAINING,
	ONNX_INFERENCE,
	RECORD_EXPERT_DEMOS
}

@export var control_mode: ControlModes = ControlModes.TRAINING
@export var onnx_model_path: String = ""
@export var reset_after: int = 1000

@export_group("Record expert demos mode options")
@export var expert_demo_save_path: String
@export var remove_last_episode_key: InputEvent
@export var action_repeat: int = 1
@export_group("Multi-policy mode options")
@export var policy_name: String = "shared_policy"

var done: bool = false
var reward: float = 0.0
var n_steps: int = 0
var needs_reset: bool = false
var move := {"move": 0, "jump": false, "dash": false}

var heuristic: String = "human"  # ✅ ESTA LÍNEA FALTABA

var _player: CharacterBody2D

func get_info() -> Dictionary:
	return {
		"observation_space": get_obs_space(),
		"action_space": get_action_space(),
		"heuristic": heuristic,
		"policy": policy_name
	}

func _ready():
	add_to_group("AGENT")

func init(player: CharacterBody2D):
	_player = player
	

func _physics_process(_delta):
	n_steps += 1
	if n_steps > reset_after:
		needs_reset = true

	match control_mode:
		ControlModes.TRAINING:
			handle_ai_control()

func handle_ai_control():
	if _player:
		# Aplica las acciones almacenadas por el agente
		_player.movementInput = move["move"]
		_player.isJumpPressed = int(move["jump"])
		_player.isDashPressed = int(move["dash"])

func get_obs_space() -> Dictionary:
	return {
		"obs": {
			"shape": [6],
			"space": "box",
			"low": [-INF, -INF, -INF, -INF, 0, 0],
			"high": [INF, INF, INF, INF, 1, 1],
			"dtype": "float32"
		}
	}

func set_action(action: Dictionary) -> void:
	move = {
		"move": action.get("move", 0),
		"jump": action.get("jump", false),
		"dash": action.get("dash", false)
	}

func get_reward() -> float:
	# Recompensa negativa proporcional al tiempo
	return -1.0 * n_steps / 60.0  # cast a segundos si estás en 60 fps

func get_action_space() -> Dictionary:
	return {
		"move": {
			"space": "discrete",
			"size": 3
		},
		"jump": {
			"space": "discrete",
			"size": 2
		},
		"dash": {
			"space": "discrete",
			"size": 2
		}
	}

func reset():
	n_steps = 0
	reward = 0.0
	needs_reset = false
	done = false

func get_done() -> bool:
	return done

func set_done_false():
	done = false

func zero_reward():
	reward = 0.0
