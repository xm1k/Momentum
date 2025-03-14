extends Camera2D

@export var base_resolution: Vector2 = Vector2(1152, 648)
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var target: CharacterBody2D

func _ready():
	_update_zoom()
	get_viewport().size_changed.connect(_update_zoom)

func _update_zoom():
	var viewport = get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		var width_ratio = viewport_size.x / base_resolution.x
		var height_ratio = viewport_size.y / base_resolution.y
		zoom = Vector2.ONE * clamp(min(width_ratio, height_ratio), min_zoom, max_zoom)

func _process(delta):
	if target:
		# Плавное следование за целью
		position = position.lerp(target.position, 0.1)
		# Обновление ограничений камеры
