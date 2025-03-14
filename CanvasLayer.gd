extends CanvasLayer

@export var base_resolution: Vector2 = Vector2(1152, 648)
@export var start_time: float = 0.0  # 5 минут в секундах

var current_time: float = start_time
var is_running: bool = true

func _ready():
	current_time = start_time
	_update_scale()
	get_viewport().size_changed.connect(_update_scale)

func _process(delta):
	if is_running:
		current_time += delta
		current_time = max(current_time, 0)
		_update_timer_display()
		
		if current_time <= 0:
			_timer_completed()

func _update_scale():
	var viewport = get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		var min_scale = min(viewport_size.x / base_resolution.x, viewport_size.y / base_resolution.y)
		self.scale = Vector2(min_scale, min_scale)

func _update_timer_display():
	var minutes = floor(current_time / 60)
	var seconds = floor(fmod(current_time, 60))
	$Time.text = "%02d:%02d" % [minutes, seconds]

func _timer_completed():
	is_running = false
	print("Таймер завершен")
	# Дополнительные действия по завершению таймера

func reset_timer(new_time: float = start_time):
	current_time = new_time
	is_running = true
	_update_timer_display()
