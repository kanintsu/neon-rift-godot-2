class_name SkyBird
extends CharacterBody2D

signal died

const GRAVITY := 1750.0
const FLAP_SPEED := -560.0
const MAX_FALL_SPEED := 920.0

var active := false
var dead := false
var wing_phase := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 25.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func start() -> void:
	active = true
	dead = false
	velocity = Vector2.ZERO

func flap() -> void:
	if dead:
		return
	if not active:
		active = true
	velocity.y = FLAP_SPEED
	wing_phase = 1.0

func stop() -> void:
	dead = true
	active = false

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not active:
		wing_phase += delta * 3.5
		position.y += sin(wing_phase) * 0.35
		rotation = sin(wing_phase) * 0.04
		queue_redraw()
		return
	velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()
	if get_slide_collision_count() > 0:
		_die()
		return
	rotation = clamp(velocity.y / 1100.0, -0.42, 0.92)
	wing_phase = max(0.0, wing_phase - delta * 4.0)
	queue_redraw()
	if position.y < -90.0 or position.y > 1165.0:
		_die()

func _die() -> void:
	if dead:
		return
	dead = true
	died.emit()

func _draw() -> void:
	draw_circle(Vector2(-2, 3), 31.0, Color("#5b4636"))
	draw_circle(Vector2.ZERO, 27.0, Color("#ffd348"))
	draw_circle(Vector2(7, 6), 16.0, Color("#ffe979"))
	var wing_y := 13.0 - wing_phase * 14.0
	draw_colored_polygon(PackedVector2Array([Vector2(-28, wing_y - 7), Vector2(-53, wing_y + 4), Vector2(-29, wing_y + 17), Vector2(-5, wing_y + 6)]), Color("#f39b34"))
	draw_polyline(PackedVector2Array([Vector2(-28, wing_y - 7), Vector2(-53, wing_y + 4), Vector2(-29, wing_y + 17), Vector2(-5, wing_y + 6), Vector2(-28, wing_y - 7)]), Color("#6d4b32"), 6.0, true)
	draw_circle(Vector2(15, -12), 12.0, Color.WHITE)
	draw_circle(Vector2(18, -11), 5.0, Color("#20243b"))
	draw_colored_polygon(PackedVector2Array([Vector2(24, -1), Vector2(54, 7), Vector2(24, 17)]), Color("#f46b45"))
	draw_polyline(PackedVector2Array([Vector2(24, -1), Vector2(54, 7), Vector2(24, 17), Vector2(24, -1)]), Color("#6d4b32"), 5.0, true)
