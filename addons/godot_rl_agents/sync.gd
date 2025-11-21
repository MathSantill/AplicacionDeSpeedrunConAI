extends Node
# Bridge Godot <-> Python (Stable-Baselines3)

const DEFAULT_PORT := 11008

var _port: int = DEFAULT_PORT
var _tcp: StreamPeerTCP = null
var _connected: bool = false

var _rx_buf: PackedByteArray = PackedByteArray()
var _agents: Array = []

func _ready() -> void:
	print("[sync] starting…")
	_port = _get_port_from_args()
	print("[sync] trying 127.0.0.1:%d" % _port)

	_collect_agents()
	print("[sync] found agents:%d" % _agents.size())

	set_process(true) # MUY IMPORTANTE


func _process(_dt: float) -> void:
	if not _connected:
		_attempt_connect()
	else:
		_poll_messages()

# ───────────────── CONEXIÓN (reintenta hasta conectar) ─────────────────
func _attempt_connect() -> void:
	if _tcp == null:
		_tcp = StreamPeerTCP.new()
		var err := _tcp.connect_to_host("127.0.0.1", _port)
		if err != OK:
			# Aún no hay servidor Python; probamos en el siguiente frame
			_tcp = null
			return
		# Si err == OK, empezará a conectar en segundo plano
		return

	var status := _tcp.get_status()
	match status:
		StreamPeerTCP.STATUS_CONNECTING:
			# seguimos esperando
			pass
		StreamPeerTCP.STATUS_CONNECTED:
			_connected = true
			if _tcp.has_method("set_no_delay"):
				_tcp.set_no_delay(true)
			print("[sync] TCP connected, sending hello")
			_send_json({
				"cmd": "hello",
				"engine": "godot",
				"version": Engine.get_version_info().get("string", "unknown"),
				"supports": ["multi_agent", "stable_baselines3"]
			})
		StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
			# fallo, reintentaremos creando un socket nuevo
			print("[sync] connect failed, will retry…")
			_tcp = null

# ───────────────── JSON send/recv ─────────────────
func _send_json(d: Dictionary) -> void:
	if not _connected or _tcp == null:
		return
	var s := JSON.stringify(d)
	var data := s.to_utf8_buffer()
	data.append(0x0A)
	_tcp.put_data(data)


func _poll_messages() -> void:
	if _tcp == null:
		return

	var avail := _tcp.get_available_bytes()
	if avail > 0:
		# Godot 4: get_partial_data() → [Error, PackedByteArray]
		var res := _tcp.get_partial_data(avail)
		var err: int = res[0]
		if err != OK:
			print("[sync] TCP read error:", err)
			return
		var chunk: PackedByteArray = res[1]
		_rx_buf.append_array(chunk)

	while true:
		var nl := _rx_buf.find(0x0A)
		if nl == -1:
			break
		var line := _rx_buf.slice(0, nl)
		_rx_buf = _rx_buf.slice(nl + 1, _rx_buf.size() - (nl + 1))

		var msg := _parse_json_line(line)
		if msg != null:
			_process_single_message(msg)


func _parse_json_line(bytes: PackedByteArray) -> Variant:
	var s := bytes.get_string_from_utf8().strip_edges()
	if s == "":
		return null
	var parsed := JSON.parse_string(s)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return null

# ───────────────── PROTOCOLO CON PYTHON ─────────────────
func _process_single_message(msg: Dictionary) -> void:
	var cmd := str(msg.get("cmd", ""))

	print("[sync] recv cmd:", cmd)  # DEBUG

	match cmd:
		"hello_ack":
			print("[sync] handshake complete")

		"get_info":
			_send_json({"cmd": "info", "agents": _agents_map_info()})

		"get_obs":
			_send_json({"cmd": "obs", "agents": _agents_map_obs()})

		"set_action":
			var actions: Dictionary = msg.get("actions", {})
			# print("[sync] actions from py:", actions)
			_apply_actions_from_py(actions)
			_send_json({"cmd": "ok"})

		"reset":
			_reset_episode()
			_send_json({"cmd": "reset_ok"})

		"ping":
			_send_json({"cmd": "pong"})

		"get_step":
			_send_step_after_physics()

		_:
			_send_json({"cmd": "noop", "recv": msg})

# ───────────────── STEP (para SB3) ─────────────────
func _send_step_after_physics() -> void:
	await get_tree().physics_frame

	var obs_arr: Array = []
	var rew_arr: Array = []
	var done_arr: Array = []

	for a in _agents:
		if a.has_method("get_obs"):
			obs_arr.append(a.get_obs())
		else:
			obs_arr.append({"obs": [0,0,0,0,0,0]})

		var r := 0.0
		if a.has_method("get_reward"):
			r = float(a.get_reward())
		rew_arr.append(r)

		var d := false
		if a.has_method("get_done"):
			d = bool(a.get_done())
		done_arr.append(d)

		if a.has_method("zero_reward"):
			a.zero_reward()
		if d and a.has_method("set_done_false"):
			a.set_done_false()

	_send_json({
		"cmd": "step",
		"obs": obs_arr,
		"reward": rew_arr,
		"done": done_arr
	})

# ───────────────── AGENTES ─────────────────
func _collect_agents() -> void:
	_agents.clear()
	for n in get_tree().get_nodes_in_group("AGENT"):
		_agents.append(n)

func _agents_map_info() -> Array:
	var arr: Array = []
	for a in _agents:
		if a.has_method("get_info"):
			arr.append(a.get_info())
		else:
			arr.append({
				"observation_space": {"obs": {"size": [6], "space": "box"}},
				"action_space": {
					"move": {"size": 3, "action_type": "discrete"},
					"jump": {"size": 2, "action_type": "discrete"},
					"dash": {"size": 2, "action_type": "discrete"},
				},
				"heuristic": "human",
				"policy": "shared_policy"
			})
	return arr

func _agents_map_obs() -> Array:
	var arr: Array = []
	for a in _agents:
		if a.has_method("get_obs"):
			arr.append(a.get_obs())
		else:
			arr.append({"obs": [0,0,0,0,0,0]})
	return arr

func _apply_actions_from_py(actions: Dictionary) -> void:
	for i in _agents.size():
		var a = _agents[i]
		var key := str(i)
		if not actions.has(key):
			continue

		var act: Dictionary = actions[key]
		var raw := int(act.get("move", 1))  # 0/1/2 desde SB3

		# 0/1/2 -> -1/0/1
		var mv := 0
		if raw <= 0:
			mv = -1
		elif raw == 1:
			mv = 0
		else:
			mv = 1

		var j := bool(act.get("jump", false))
		var d := bool(act.get("dash", false))

		if a.has_method("set_action"):
			a.set_action({"move": mv, "jump": j, "dash": d})
		elif a.has_method("apply_ai_action"):
			a.apply_ai_action(mv, j, d)

func _reset_episode() -> void:
	for a in _agents:
		if a.has_method("respawn"):
			a.respawn()
		elif a.has_method("reset"):
			a.reset()

# ───────────────── UTILS ─────────────────
func _get_port_from_args() -> int:
	for s in OS.get_cmdline_args():
		if s.begins_with("--port="):
			return int(s.substr(7, s.length() - 7))
	return DEFAULT_PORT
