extends Area2D
class_name GoalArea2DCustom

signal player_reached_goal(player: Node)

@export var one_shot: bool = false
@export var respawn_delay: float = 0.0
@export var debug_color: Color = Color(0, 1, 0, 0.25)

var _triggered := false

func _ready() -> void:
	add_to_group("GOAL")
	monitoring = true
	monitorable = true
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if get_node_or_null("CollisionShape2D") == null:
		push_warning("[GoalArea2D] Falta CollisionShape2D.")
	if has_node("ColorRect"):
		$ColorRect.color = debug_color

func _on_body_entered(body: Node) -> void:
	if _triggered and one_shot: return
	if body is CharacterBody2D:
		_triggered = true
		emit_signal("player_reached_goal", body)
		if body.has_method("on_goal_reached"):
			body.on_goal_reached()
		if respawn_delay > 0.0:
			await get_tree().create_timer(respawn_delay).timeout
		if is_instance_valid(body):
			if body.has_method("respawn"):
				body.respawn()
			elif body.has_variable("respawn_point"):
				body.global_position = body.respawn_point
		if not one_shot:
			_triggered = false

func reset_goal() -> void:
	_triggered = false
