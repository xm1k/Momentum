extends TextureProgressBar
var time_since_last_gain: float = 0.0

var max_stamina=3

func _ready():
	value = 3

func _process(delta: float):
	if value >= max_stamina:
		return
	
	time_since_last_gain += delta
	if time_since_last_gain >= 3.0:
		value += 1  # Увеличиваем стамину
		time_since_last_gain = 0.0  # Сбрасываем таймер

# Обновление максимального значения при изменении в инспекторе
func set_max_stamina(value: int) -> void:
	max_stamina = value
	max_value = value  # Синхронизируем с ProgressBar
