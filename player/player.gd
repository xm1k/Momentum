extends CharacterBody2D


@export var speed_label: Label
@export var stamina: ProgressBar

# Настройки движения
var max_horizontal_speed = 500.0
var jump_force = -500.0
var gravity = 1000.0
var wall_stick_force = 250.0
var max_fall_speed = 1500.0

# Состояния движения
var is_on_wall = false
var wall_side = 0
var speed = 0
var acceleration = 25.0
var max_speed = 900.0
var friction = 0.97
var air_resistance = 1.0
var timer = 0


var is_sitting = false
var double_jump = false
var rebound = 0
var direction
var is_skiing = false


func _physics_process(delta):
	direction = Input.get_axis("move_left", "move_right")
	
	check_collisions()
	handle_movement(direction, delta)
	apply_gravity(delta)
	handle_jump()
	handle_sit()
	handle_dash()
	
	move_and_slide()
	speed_label.text = str(abs(round(speed)))
	#print(speed)

func check_collisions():
	var save_speed = false
	var tilemap = get_parent().find_child("TileMap")
	var tile_pos = tilemap.local_to_map(position)
	var tile_data = tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1))
	if(is_on_wall && test_move(transform, Vector2(0,-1))):
		speed = 0
	if(is_on_wall && test_move(transform, Vector2(0,1) * 1)):
		is_on_wall = false
		rotation = 0.0
		if(wall_side==1):
			position.x-=20
		else:
			position.x+=20
		wall_side = 0
		save_speed = false
	elif test_move(transform, Vector2(1,0)):
		var right_tile_pos = tile_pos + Vector2i(1,0)
		var right_tile_data = tilemap.get_cell_tile_data(0, right_tile_pos)
		if right_tile_data and right_tile_data.get_custom_data('climbable'):
			if(!is_on_wall && speed>30):
				timer = 15
				if(!is_on_floor()):
					rebound = speed
					speed=0
				if (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1)) and tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1)).get_custom_data('curve')):
					save_speed = true
				elif (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)) and tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)).get_custom_data('curve')):
					save_speed = true
				elif (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)) and tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)).get_custom_data('curve')):
					save_speed = true
				position.y-=30
				is_on_wall = true
				wall_side = 1
				rotation = deg_to_rad(-90 * wall_side)
				if(save_speed):
					speed+=300
	elif test_move(transform, Vector2(-1,0)):
		var left_tile_pos = tile_pos + Vector2i(-2,0)
		var left_tile_data = tilemap.get_cell_tile_data(0, left_tile_pos)
		if left_tile_data and left_tile_data.get_custom_data('climbable'):
			if(!is_on_wall && speed<-30):
				timer = 15
				if(!is_on_floor()):
					rebound = speed
					speed=0
				if (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1)) and tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1)).get_custom_data('curve')):
					save_speed = true
				elif (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)) and tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)).get_custom_data('curve')):
					save_speed = true
				elif (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)) and tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)).get_custom_data('curve')):
					save_speed = true
				position.y-=30
				is_on_wall = true
				wall_side = -1
				rotation = deg_to_rad(-90 * wall_side)
				if(save_speed):
					speed-=300
				save_speed = false
	else:
		wall_side = 0
		is_on_wall = false
		rotation = 0.0

func handle_movement(direction, delta):
	#print(direction)
	if(is_sitting):
		direction=0
	if(timer>0):
		timer-=1
	if direction != 0 && (is_on_floor() or is_on_wall):
		if sign(speed) != direction and abs(speed) > 10:
			speed *= 0.7
		else:
			# Разгон в текущем направлении
			if(speed<max_speed && speed>-max_speed):
				speed += direction * acceleration
			if(speed>max_speed):
				speed -= direction * acceleration*0.5
			elif(speed<-max_speed):
				speed -= direction * acceleration*0.5
	else:
		# Замедление при отпущенных клавишах
		if is_on_floor() or is_on_wall:
			if is_sitting:
				if !is_skiing:
					speed *= friction
			else:
				speed *= friction*friction*friction
		elif !is_skiing:
			speed *= air_resistance
		
		# Полная остановка при маленьких значениях
		if abs(speed) < 10:
			speed = 0
	if is_on_wall:
		var inverted_direction = -wall_side
		var target_speed = inverted_direction * speed
		velocity.y = target_speed
		velocity.x = wall_side * wall_stick_force
		
		velocity.y += gravity * delta * 10
	else:
		velocity.x = speed
	
	if direction == 0 and not is_on_wall:
		velocity.x = speed

func apply_gravity(delta):
	if not is_on_floor() and not is_on_wall:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
		
func handle_jump():
	if(timer==0):
		rebound = 0
	if is_on_wall or is_on_floor():
		double_jump = true
	if Input.is_action_just_pressed("jump"):
		if is_on_wall && direction==-wall_side:
			velocity.x = -wall_side * abs(jump_force) * 3
			speed = 100
			velocity.y = jump_force * 0.8
			is_on_wall = false
			speed=-rebound
			if speed == 0:
				speed = (-wall_side*300)
			if timer>0:
				if Input.is_action_pressed("w"):
					velocity.y -= 300
				if Input.is_action_pressed("s"):
					velocity.y = 300
		elif is_on_wall:
			if(wall_side == 1 && direction==wall_side):
				var tilemap = get_parent().find_child("TileMap")
				var tile_pos = tilemap.local_to_map(position)
				if tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+2, tile_pos.y)) == null or tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+2, tile_pos.y+1)) == null:
					position = tilemap.map_to_local(Vector2i(tile_pos.x+2, tile_pos.y))
					is_on_wall = false
					velocity=Vector2.ZERO
					rotation = 0.0
					wall_side = 0
					speed = speed+rebound
			elif(wall_side == -1 && direction==wall_side):
				var tilemap = get_parent().find_child("TileMap")
				var tile_pos = tilemap.local_to_map(position)
				if tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-2, tile_pos.y)) == null or tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-2, tile_pos.y+1)) == null:
					position = tilemap.map_to_local(Vector2i(tile_pos.x-2, tile_pos.y))
					velocity=Vector2.ZERO
					rotation = 0.0
					wall_side = 0
					speed = speed+rebound
			else:
				velocity.x = -wall_side * abs(jump_force) * 3
				velocity.y = jump_force * 0.8
				is_on_wall = false
				speed = (-wall_side*300)
			#if right_tile_data and right_tile_data.get_custom_data('climbable'):
		elif is_on_floor():
			velocity.y = jump_force
		elif double_jump==true&&!is_on_wall&&stamina.value>0:
			stamina.value-=1
			double_jump = false
			velocity.y = jump_force
			
func handle_sit():
	if Input.is_action_just_pressed("sit") and !is_on_wall:
		is_sitting = true
		scale.y = 0.5
		position.y += 50
	elif !Input.is_action_pressed("sit") or is_on_wall:
		is_sitting = false
	if !is_sitting:
		is_skiing = false
		scale.y = 1
	else:
		var tilemap = get_parent().find_child("TileMap")
		var tile_pos = tilemap.local_to_map(position)
		if(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)).get_custom_data('angle')):
			is_skiing = true
			position.y+=20
			speed+=sign(speed)*5
		elif(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1)).get_custom_data('angle')):
			is_skiing = true
			position.y+=20
			speed+=sign(speed)*5
		elif(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)).get_custom_data('angle')):
			is_skiing = true
			position.y+=20
			speed+=sign(speed)*5
		else:
			is_skiing = false
			
func handle_dash():
	if Input.is_action_just_pressed("dash") && stamina.value>0:
		var f = 0
		if direction !=0:
			f=1
			speed+=direction*300
			position.x+=20*direction
		if Input.is_action_pressed("w"):
			f=1
			velocity.y -= 600
		if Input.is_action_pressed("s"):
			f=1
			velocity.y += 600
		if f:
			stamina.value-=1
