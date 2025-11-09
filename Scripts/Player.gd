extends CharacterBody2D

signal died

# === Entrada que puede escribir la IA ===
var movementInput: int = 0
var isJumpPressed: bool = false
var isDashPressed: bool = false
var isJumpReleased: bool = false
var lastDirection: int = 1
var canDash: bool = true

# === Físicas (ajusta a tu gusto) ===
var gravity: float = 700.0
var maxSpeed: float = 190.0
var acceleration: float = 25.0
var decceleration: float = 40.0
var air_friction: float = 60.0

# Vida / respawn
var hp: int = 1
var respawn_point: Vector2

func _ready() -> void:
	respawn_point = global_position

# ==== API para la IA (evita nombres mágicos de propiedades)
func apply_ai_action(move: int, jump: bool, dash: bool) -> void:
	movementInput = clamp(move, -1, 1)
	isJumpPressed = jump
	isDashPressed = dash
	if movementInput != 0:
		lastDirection = movementInput

# ==== Daño / respawn (usado por DamageArea)
func take_damage(amount: int = 1) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	emit_signal("died")
	respawn()

func set_respawn(pos: Vector2) -> void:
	respawn_point = pos

func respawn() -> void:
	hp = 1
	global_position = respawn_point
	velocity = Vector2.ZERO

# === Tu FSM / movimiento real va aquí (no lo reescribo si ya te funciona)
