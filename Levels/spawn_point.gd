extends Marker2D
class_name SpawnPoint

@export var spawn_id: int = 1     # 1 = Spawn1, 2 = Spawn2
@export var y_lift: float = 4.0   # para colocarlo un poco por encima del suelo

func get_spawn_position() -> Vector2:
	return global_position + Vector2(0, -y_lift)
