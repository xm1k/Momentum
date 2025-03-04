extends CharacterBody2D

# Настройки движения
var max_horizontal_speed = 500.0
var jump_force = -500.0
var gravity = 1000.0
var wall_stick_force = 50.0
var max_fall_speed = 1500.0

# Состояния движения
var is_on_wall = false
var wall_side = 0
var speed = 0
var acceleration = 25.0
var max_speed = 900.0
var friction = 0.9
var air_resistance = 1.0
var timer = 0


func _physics_process(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	check_collisions()
	handle_movement(direction, delta)
	apply_gravity(delta)
	handle_jump()
	
	move_and_slide()
	
	print(speed)

func check_collisions():
	if(is_on_wall && test_move(transform, Vector2(0,1) * 2)):
		is_on_wall = false
		rotation = 0.0
		if(wall_side==1):
			position.x-=20
		else:
			position.x+=20
		wall_side = 0
	elif test_move(transform, Vector2.RIGHT * 2):
		if(!is_on_wall):
			position.y-=10
			is_on_wall = true
			wall_side = 1
			rotation = deg_to_rad(-90 * wall_side)
	elif test_move(transform, Vector2.LEFT * 2):
		if(!is_on_wall):
			position.y-=10
			is_on_wall = true
			wall_side = -1
			rotation = deg_to_rad(-90 * wall_side)
	else:
		wall_side = 0
		is_on_wall = false
		rotation = 0.0

func handle_movement(direction, delta):
	#print(direction)
	if(timer>0):
		timer-=1
	if direction != 0:
		if sign(speed) != direction and abs(speed) > 10 && timer>0:
			speed *= 0.7
		else:
			# Разгон в текущем направлении
			speed += direction * acceleration
			speed = clamp(speed, -max_speed, max_speed)
	else:
		# Замедление при отпущенных клавишах
		if is_on_floor() or is_on_wall:
			speed *= friction
		else:
			speed *= air_resistance
		
		# Полная остановка при маленьких значениях
		if abs(speed) < 10:
			speed = 0
	if is_on_wall:
		var inverted_direction = -wall_side
		var target_speed = inverted_direction * speed
		velocity.y = target_speed
		velocity.x = wall_side * wall_stick_force
		
		if direction == 0:
			velocity.y += gravity * delta * 0.5
	else:
		velocity.x = speed
	
	if direction == 0 and not is_on_wall:
		velocity.x = speed

func apply_gravity(delta):
	if not is_on_floor() and not is_on_wall:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
func handle_jump():
	if Input.is_action_just_pressed("jump"):
		if is_on_wall:
			velocity.x = -wall_side * abs(jump_force) * 3
			velocity.y = jump_force * 0.8
			is_on_wall = false
			speed*=-1
			timer = 10
		elif is_on_floor():
			velocity.y = jump_force
