extends Node2D

enum GameState { READY, PLAYING, GAME_OVER }

const PipePairScript = preload("res://scripts/pipe_pair.gd")
const BirdScript = preload("res://scripts/bird.gd")

const WIDTH := 720.0
const HEIGHT := 1280.0
const GROUND_Y := 1125.0
const BIRD_X := 210.0

var state := GameState.READY
var bird: SkyBird
var spawn_timer := 0.0
var score := 0
var best_score := 0
var pipes_speed := 245.0
var pipe_gap := 320.0
var rng := RandomNumberGenerator.new()

var score_label: Label
var best_label: Label
var title_label: Label
var info_label: Label
var card: Panel

func _ready() -> void:
	rng.randomize()
	load_best_score()
	_create_ground_collision()
	_create_ui()
	spawn_bird()
	queue_redraw()

func _process(delta: float) -> void:
	if state == GameState.PLAYING:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_pipe()
			spawn_timer = max(1.08, 1.42 - score * 0.008)
		_check_scores()
		pipes_speed = min(355.0, 245.0 + score * 3.0)
		pipe_gap = max(250.0, 320.0 - score * 2.0)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		pressed = true
	if not pressed:
		return
	match state:
		GameState.READY:
			start_game()
			bird.flap()
		GameState.PLAYING:
			bird.flap()
		GameState.GAME_OVER:
			restart_game()

func start_game() -> void:
	state = GameState.PLAYING
	score = 0
	spawn_timer = 0.65
	pipes_speed = 245.0
	pipe_gap = 320.0
	bird.start()
	title_label.visible = false
	info_label.visible = false
	card.visible = false
	score_label.visible = true
	_update_score_text()

func restart_game() -> void:
	for node in get_tree().get_nodes_in_group("pipes"):
		node.queue_free()
	if is_instance_valid(bird):
		bird.queue_free()
	spawn_bird()
	state = GameState.READY
	score = 0
	title_label.visible = true
	title_label.text = "SKY HOP"
	title_label.position = Vector2(0, 250)
	info_label.visible = true
	info_label.text = "TOQUE PARA VOAR"
	info_label.position = Vector2(0, 815)
	card.visible = false
	score_label.visible = false
	best_label.visible = true
	best_label.text = "MELHOR  %d" % best_score

func spawn_bird() -> void:
	bird = BirdScript.new()
	bird.position = Vector2(BIRD_X, 565)
	bird.died.connect(_on_bird_died)
	add_child(bird)

func spawn_pipe() -> void:
	var pair: PipePair = PipePairScript.new()
	pair.add_to_group("pipes")
	pair.position = Vector2(WIDTH + 110, 0)
	var center := rng.randf_range(365.0, 830.0)
	pair.setup(center, pipe_gap, pipes_speed)
	add_child(pair)

func _check_scores() -> void:
	for node in get_tree().get_nodes_in_group("pipes"):
		var pair := node as PipePair
		if pair and not pair.scored and pair.position.x + pair.pipe_width * 0.5 < BIRD_X:
			pair.scored = true
			score += 1
			_update_score_text()

func _on_bird_died() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.GAME_OVER
	bird.stop()
	for node in get_tree().get_nodes_in_group("pipes"):
		if node.has_method("freeze"):
			node.freeze()
	if score > best_score:
		best_score = score
		save_best_score()
	show_game_over()

func show_game_over() -> void:
	score_label.visible = false
	card.visible = true
	title_label.visible = true
	title_label.text = "FIM DE JOGO"
	title_label.position = Vector2(0, 272)
	info_label.visible = true
	info_label.text = "TOQUE PARA TENTAR DE NOVO"
	info_label.position = Vector2(0, 760)
	best_label.visible = false
	(card.get_node("ScoreValue") as Label).text = str(score)
	(card.get_node("BestValue") as Label).text = str(best_score)

func _update_score_text() -> void:
	score_label.text = str(score)

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	score_label = _make_label("0", 86, Vector2(0, 70), Vector2(WIDTH, 110), HORIZONTAL_ALIGNMENT_CENTER)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_shadow_color", Color("#405566"))
	score_label.add_theme_constant_override("shadow_offset_x", 5)
	score_label.add_theme_constant_override("shadow_offset_y", 7)
	score_label.visible = false
	layer.add_child(score_label)
	title_label = _make_label("SKY HOP", 76, Vector2(0, 250), Vector2(WIDTH, 110), HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_color_override("font_color", Color("#fff4bd"))
	title_label.add_theme_color_override("font_shadow_color", Color("#5a4b3c"))
	title_label.add_theme_constant_override("shadow_offset_x", 5)
	title_label.add_theme_constant_override("shadow_offset_y", 7)
	layer.add_child(title_label)
	info_label = _make_label("TOQUE PARA VOAR", 34, Vector2(0, 815), Vector2(WIDTH, 80), HORIZONTAL_ALIGNMENT_CENTER)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_label.add_theme_color_override("font_shadow_color", Color("#456378"))
	info_label.add_theme_constant_override("shadow_offset_x", 3)
	info_label.add_theme_constant_override("shadow_offset_y", 4)
	layer.add_child(info_label)
	best_label = _make_label("MELHOR  %d" % best_score, 28, Vector2(0, 895), Vector2(WIDTH, 70), HORIZONTAL_ALIGNMENT_CENTER)
	best_label.add_theme_color_override("font_color", Color("#fef5d7"))
	layer.add_child(best_label)
	card = Panel.new()
	card.position = Vector2(115, 430)
	card.size = Vector2(490, 290)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f7e0a1")
	style.border_color = Color("#6c563c")
	style.set_border_width_all(8)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	card.add_theme_stylebox_override("panel", style)
	layer.add_child(card)
	var score_title := _make_label("PONTOS", 29, Vector2(35, 35), Vector2(200, 55), HORIZONTAL_ALIGNMENT_LEFT)
	score_title.add_theme_color_override("font_color", Color("#7b5b35"))
	card.add_child(score_title)
	var score_value := _make_label("0", 48, Vector2(255, 22), Vector2(190, 70), HORIZONTAL_ALIGNMENT_RIGHT)
	score_value.name = "ScoreValue"
	score_value.add_theme_color_override("font_color", Color("#5a4634"))
	card.add_child(score_value)
	var best_title := _make_label("MELHOR", 29, Vector2(35, 125), Vector2(200, 55), HORIZONTAL_ALIGNMENT_LEFT)
	best_title.add_theme_color_override("font_color", Color("#7b5b35"))
	card.add_child(best_title)
	var best_value := _make_label("0", 48, Vector2(255, 112), Vector2(190, 70), HORIZONTAL_ALIGNMENT_RIGHT)
	best_value.name = "BestValue"
	best_value.add_theme_color_override("font_color", Color("#5a4634"))
	card.add_child(best_value)
	var medal := Label.new()
	medal.text = "★"
	medal.position = Vector2(185, 195)
	medal.size = Vector2(120, 75)
	medal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medal.add_theme_font_size_override("font_size", 62)
	medal.add_theme_color_override("font_color", Color("#e6a13a"))
	card.add_child(medal)
	card.visible = false

func _make_label(text_value: String, size_px: int, pos: Vector2, label_size: Vector2, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = label_size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size_px)
	return label

func _create_ground_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, HEIGHT - GROUND_Y + 80)
	shape.shape = rect
	shape.position = Vector2(WIDTH * 0.5, GROUND_Y + (HEIGHT - GROUND_Y) * 0.5)
	body.add_child(shape)
	add_child(body)

func load_best_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		best_score = int(cfg.get_value("score", "best", 0))

func save_best_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", best_score)
	cfg.save("user://save.cfg")

func _draw() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color("#67c8e8"))
	_draw_cloud(Vector2(110, 165), 1.0)
	_draw_cloud(Vector2(510, 235), 0.8)
	_draw_cloud(Vector2(335, 390), 0.55)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 1010), Vector2(0, 900), Vector2(120, 825), Vector2(250, 918), Vector2(365, 790), Vector2(520, 915), Vector2(720, 805), Vector2(720, 1010)]), Color("#a6dd9a"))
	draw_polyline(PackedVector2Array([Vector2(0, 900), Vector2(120, 825), Vector2(250, 918), Vector2(365, 790), Vector2(520, 915), Vector2(720, 805)]), Color("#6bb67d"), 7.0, true)
	for i in range(12):
		var x := float(i * 68 - 20)
		var h := 55.0 + float((i * 37) % 90)
		draw_rect(Rect2(x, GROUND_Y - 180 - h, 48, h), Color("#87c4b4"))
	draw_rect(Rect2(0, GROUND_Y - 25, WIDTH, 34), Color("#e9ef9b"))
	draw_rect(Rect2(0, GROUND_Y, WIDTH, HEIGHT - GROUND_Y), Color("#d9bd63"))
	draw_rect(Rect2(0, GROUND_Y + 18, WIDTH, 16), Color("#b89a45"))
	for x in range(-10, 760, 52):
		draw_rect(Rect2(x, GROUND_Y + 45, 26, 8), Color("#c7a74d"))

func _draw_cloud(pos: Vector2, scale_value: float) -> void:
	var c := Color(1, 1, 1, 0.78)
	draw_circle(pos, 42 * scale_value, c)
	draw_circle(pos + Vector2(42, 10) * scale_value, 34 * scale_value, c)
	draw_circle(pos + Vector2(-42, 13) * scale_value, 29 * scale_value, c)
	draw_rect(Rect2(pos + Vector2(-52, 10) * scale_value, Vector2(106, 35) * scale_value), c)
