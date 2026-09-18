class_name PipePair
extends Node2D

var speed := 245.0
var gap_center := 620.0
var gap_size := 320.0
var pipe_width := 150.0
var scored := false
var running := true

const GROUND_Y := 1125.0

func setup(center: float, gap: float, movement_speed: float) -> void:
	gap_center = center
	gap_size = gap
	speed = movement_speed
	_build_collision()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if running:
		position.x -= speed * delta
	if position.x < -220.0:
		queue_free()

func freeze() -> void:
	running = false

func _build_collision() -> void:
	for child in get_children():
		child.queue_free()
	var top_h: float = maxf(40.0, gap_center - gap_size * 0.5)
	var bottom_y: float = gap_center + gap_size * 0.5
	var bottom_h: float = maxf(40.0, GROUND_Y - bottom_y)
	_make_wall(Vector2(0, top_h * 0.5), Vector2(pipe_width, top_h))
	_make_wall(Vector2(0, bottom_y + bottom_h * 0.5), Vector2(pipe_width, bottom_h))

func _make_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 1
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	collision.shape = rect
	collision.position = center
	body.add_child(collision)
	add_child(body)

func _draw() -> void:
	var top_h: float = maxf(40.0, gap_center - gap_size * 0.5)
	var bottom_y: float = gap_center + gap_size * 0.5
	var bottom_h: float = maxf(40.0, GROUND_Y - bottom_y)
	_draw_pipe(Rect2(-pipe_width * 0.5, 0, pipe_width, top_h), false)
	_draw_pipe(Rect2(-pipe_width * 0.5, bottom_y, pipe_width, bottom_h), true)

func _draw_pipe(rect: Rect2, is_bottom: bool) -> void:
	var outline := Color("#31522f")
	var dark := Color("#3d8e49")
	var base := Color("#69c95a")
	var light := Color("#9be873")
	draw_rect(rect.grow(7.0), outline)
	draw_rect(rect, dark)
	draw_rect(Rect2(rect.position + Vector2(12, 0), Vector2(rect.size.x - 24, rect.size.y)), base)
	draw_rect(Rect2(rect.position + Vector2(24, 0), Vector2(23, rect.size.y)), light)
	var cap_h := 54.0
	var cap_rect: Rect2
	if is_bottom:
		cap_rect = Rect2(rect.position.x - 14, rect.position.y, rect.size.x + 28, cap_h)
	else:
		cap_rect = Rect2(rect.position.x - 14, rect.end.y - cap_h, rect.size.x + 28, cap_h)
	draw_rect(cap_rect.grow(7.0), outline)
	draw_rect(cap_rect, dark)
	draw_rect(Rect2(cap_rect.position + Vector2(12, 0), Vector2(cap_rect.size.x - 24, cap_rect.size.y)), base)
	draw_rect(Rect2(cap_rect.position + Vector2(25, 0), Vector2(26, cap_rect.size.y)), light)
