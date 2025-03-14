extends Node2D

var fade_color = Color(0, 0, 0, 0)
var is_fading = false

func _ready():
	# Создаем нод для затемнения
	var fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = fade_color
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade_rect)

func start_fade():
	if is_fading: return
	is_fading = true
	
	# Создаем твин для анимации
	var tween = create_tween()
	tween.tween_property($FadeRect, "color", Color.BLACK, 1.5)
	tween.tween_callback(_reload_scene)

func _reload_scene():
	# Перезагрузка текущей сцены
	find_child('player').find_child('Slide').stop()
	get_tree().reload_current_scene()

# Пример использования - вызовите start_fade() когда нужно начать затемнение
# func _on_player_died():
#     start_fade()
