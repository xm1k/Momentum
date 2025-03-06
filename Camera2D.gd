extends Camera2D

@export var target: Node2D  # Ссылка на игрока
@export var smooth_speed: float = 0.1  # Коэффициент плавности (0.01 - медленно, 1 - мгновенно)


func _process(delta):
	if target:
		# Плавная интерполяция позиции
		position = position.lerp(target.position, smooth_speed)
		# Для более сложных сценариев можно добавить ограничения:
		# position.x = clamp(position.x, limit_left, limit_right)
