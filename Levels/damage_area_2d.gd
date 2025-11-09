extends Area2D
class_name DamageArea2D

@export var instant_kill: bool = true
@export var damage_amount: int = 999

func _ready() -> void:
	set_monitoring(true)
	set_monitorable(true)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody2D): return
	if instant_kill and body.has_method("die"):
		body.die()
	elif body.has_method("take_damage"):
		body.take_damage(damage_amount)
