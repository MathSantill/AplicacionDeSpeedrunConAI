extends Area2D
class_name GoalArea2D1

@export var one_shot: bool = false
@export var respawn_delay: float = 0.0

signal player_reached_goal(player: Node)

var _activated: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	connect("body_entered", Callable(self, "_on_body_entered"))
	add_to_group("GOAL")

func _on_body_entered(body: Node) -> void:
	if not body:
		return
	if _activated and one_shot:
		return
	if body is CharacterBody2D:
		_activated = true
		emit_signal("player_reached_goal", body)

		if respawn_delay > 0.0:
			await get_tree().create_timer(respawn_delay).timeout

		if is_instance_valid(body):
			if body.has_method("respawn"):
				body.respawn()

		if not one_shot:
			_activated = false
