extends Area2D
class_name GoalArea2D

signal goal_reached

@export var target_spawn_path: NodePath    # en goal1 apúntalo al SpawnPoint2; en goal2 déjalo vacío
@export var target_spawn_id: int = 2
@export var set_player_respawn: bool = true
@export var y_lift: float = 4.0
@export var debug_prints: bool = false

func _ready() -> void:
	set_monitoring(true)
	set_monitorable(true)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody2D): return
	var player := body as CharacterBody2D

	var spawn := _resolve_target_spawn()
	if spawn:
		var pos: Vector2 = spawn.global_position + Vector2(0, -y_lift)
		if spawn.has_method("get_spawn_position"):
			pos = spawn.get_spawn_position()

		player.global_position = pos
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		if set_player_respawn and player.has_method("set_respawn"):
			player.set_respawn(pos)
		if debug_prints:
			print("[GoalArea2D:", name, "] TP:", pos)

	emit_signal("goal_reached")

func _resolve_target_spawn() -> Node:
	if target_spawn_path != NodePath(""):
		var n := get_node_or_null(target_spawn_path)
		if n: return n
	var root := get_tree().current_scene
	if root:
		for c in root.get_children():
			if c is Node and c.name.to_lower().begins_with("spawnpoint"):
				if c.has_variable("spawn_id") and c.spawn_id == target_spawn_id:
					return c
	return null
