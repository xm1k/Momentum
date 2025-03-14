extends CharacterBody2D


@export var speed_label: Label
@export var stamina: TextureProgressBar

@export var audio_players: Array[AudioStreamPlayer] = []

# Настройки движения
var max_horizontal_speed = 500.0
var jump_force = -600.0
var gravity = 1000.0
var wall_stick_force = 250.0
var max_fall_speed = 1500.0

# Состояния движения
var is_on_wall = false
var wall_side = 0
var speed = 0
var acceleration = 10.0
var max_speed = 900.0
var friction = 0.98
var air_resistance = 1.0
var timer = 0


var is_sitting = false
var double_jump = false
var rebound = 0
var direction
var is_skiing = 0
var skii_dir = 1

var just_jumped = false
var was_wall_jump = false

var surface_normal := Vector2.UP
var surface_angle := 0.0
var slope_gravity := Vector2.ZERO
var skii_timer = 0

var target_angle = 0

var speed_boost = 1
var jump_boost = 1
var is_started = false

var death_timer = 0

var is_dead = false

var ground_timer=0
var stop_skiing = 0


func _ready():
	# Инициализация пула плееров
	for i in 5:
		var player = AudioStreamPlayer.new()
		add_child(player)
		audio_players.append(player)
		
func play_sound(stream: AudioStream):
	# Находим первый свободный плеер
	for player in audio_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# Если все заняты, можно создать новый плеер (опционально)
	var new_player = AudioStreamPlayer.new()
	add_child(new_player)
	new_player.stream = stream
	new_player.play()
	audio_players.append(new_player)

func _physics_process(delta):
	
	if abs(speed)>100:
		is_started=true
		death_timer=20
	if abs(speed)<100&&is_started:
		if death_timer>0:
			#death_timer-=1
			pass
	if !is_dead && (abs(speed)<100&&is_started&&death_timer==0)||position.y>2000:
		if !$Death.playing:
			$Death.play()
		get_parent().start_fade()
		is_dead = true
		$AnimatedSprite2D.play("death")

	if(!is_dead):
		direction = Input.get_axis("move_left", "move_right")
		check_collisions()
		handle_movement(direction, delta)
		apply_gravity(delta)
		handle_jump()
		handle_dash()
		handle_effects()
		animations()
		handle_sit()
		angle_pos()
		move_and_slide()
		angle_pos()
		
		
		
		
	speed_label.text = str(abs(round(speed)))
	
	if($AnimatedSprite2D.animation=='run' && ($AnimatedSprite2D.frame==3 || $AnimatedSprite2D.frame==22)):
		$Step.play(0.0)
		$AnimatedSprite2D.frame+=1
	
	if($AnimatedSprite2D.animation=='wall_run' && ($AnimatedSprite2D.frame==6 || $AnimatedSprite2D.frame==23)):
		$Step.play(0.0)
		$AnimatedSprite2D.frame+=1
		
	if($AnimatedSprite2D.animation=='air_to_run' && ($AnimatedSprite2D.frame==1||$AnimatedSprite2D.frame==9)):
		$Step.play(0.0)
		$AnimatedSprite2D.frame+=1
	if is_on_floor():
		ground_timer=0
	else:
		ground_timer+=1

func handle_effects():
	var tilemap = get_parent().find_child("TileMap")
	var tile_pos = tilemap.local_to_map(position)
	var tile_data
	if is_on_wall:
		tile_data = tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+wall_side, tile_pos.y))
	else:
		tile_data = tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1))
	if(tile_data):
		var eff=tile_data.get_custom_data('effect')
		if(eff):
			if(eff==1):
				if speed_boost<2:
					play_sound(preload("res://Sounds/Speed_Up_Panel.wav"))
					speed*=1.5
				speed_boost=2
				max_speed=1200
				jump_boost=1
			elif eff==2:
				jump_boost=2.5
				speed_boost = 1
			elif eff==3:
				if speed_boost>0.5:
					speed*=0.75
					play_sound(preload("res://Sounds/Slow_Panel.wav"))
				else:
					speed*=0.985
				speed_boost=0.5
				max_speed=0
				jump_boost=1
			else:
				jump_boost = 1
				max_speed=900
				speed_boost=1
		else:
			jump_boost = 1
			max_speed=900
			speed_boost=1
	else:
		jump_boost = 1
		max_speed=900
		speed_boost=1
	
func angle_pos():
	var th = 15
	var th2 = 30
	var tilemap = get_parent().find_child("TileMap")
	var tile_pos = tilemap.local_to_map(position)
	
	if(stop_skiing == 0 && (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1))) && ((tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1)).get_custom_data('angle')))):
		var loc = tilemap.map_to_local(tile_pos)
		if(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y)).get_custom_data('angle')):
			var slope_height=-64
			position.y = loc.y + ((position.x-loc.x) / 64) * slope_height - 64/2 + th2
			if $AnimatedSprite2D.animation!='slide':
				$AnimatedSprite2D.position.y = 34
		elif(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y)).get_custom_data('angle')):
			var slope_height=64
			if $AnimatedSprite2D.animation!='slide':
				$AnimatedSprite2D.position.y = 55
			position.y = loc.y + ((position.x-loc.x) / 64) * slope_height - 64/2 + th
	elif(stop_skiing == 0 && (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+2))) && ((tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+2)).get_custom_data('angle')))):
		var loc = tilemap.map_to_local(tile_pos)
		if(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)).get_custom_data('angle')):
			if $AnimatedSprite2D.animation!='slide':
				$AnimatedSprite2D.position.y = 34
			var slope_height=-64
			position.y = loc.y + ((position.x-loc.x) / 64) * slope_height - 64/2 + 64 + th2
			
		elif(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)).get_custom_data('angle')):
			if $AnimatedSprite2D.animation!='slide':
				$AnimatedSprite2D.position.y = 55
			var slope_height=64
			position.y = loc.y + ((position.x-loc.x) / 64) * slope_height - 64/2 + 64 + th
	#else:
		#if((tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+2))) && ((tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+2)).get_custom_data('angle')))):
			#print(1)
		#else:
			#print(0)

func animations():
	if is_on_wall:
		if wall_side == 1:
			if direction != wall_side && direction!=0 && timer==0:
				$AnimatedSprite2D.flip_h = true
				$AnimatedSprite2D.position.x = 55
				$AnimatedSprite2D.rotation_degrees = -90
				$AnimatedSprite2D.position.y = -30
			else:
				$AnimatedSprite2D.rotation_degrees = 0
				$AnimatedSprite2D.flip_h = false
				$AnimatedSprite2D.position.x = 55
				$AnimatedSprite2D.position.y = 55
			
			
		if wall_side == -1:
			if direction != wall_side && direction!=0 && timer==0:
				$AnimatedSprite2D.flip_h = false
				$AnimatedSprite2D.position.x = -60
				$AnimatedSprite2D.rotation_degrees = 90
				$AnimatedSprite2D.position.y = -30
			else:
				$AnimatedSprite2D.rotation_degrees = 0
				$AnimatedSprite2D.position.y = 55
				$AnimatedSprite2D.flip_h = true
				$AnimatedSprite2D.position.x = -60
	elif direction == 1 && is_on_floor() && is_skiing==0:
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.position.x = -15
	elif direction == -1 && is_on_floor() && is_skiing==0:
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D.position.x = 15
	else:
		$AnimatedSprite2D.position.x = sign($AnimatedSprite2D.position.x)*15
	#if is_on_floor() and jumping and direction!=0:
		##$AnimatedSprite2D.speed_scale = 1
		#$AnimatedSprite2D.play('air_to_run')
	
	#if $AnimatedSprite2D.animation=="air_to_run" && !:
		#$AnimatedSprite2D.play('air')
	
	#if $AnimatedSprite2D.animation=="air_to_run" && !is_on_floor():
		#$Jump.play(0.0)
	
	
	if(!is_sitting&&!is_on_wall):
		$AnimatedSprite2D.position.y=55
	if(is_skiing!=0&&is_sitting):
		if $AnimatedSprite2D.flip_h==true:
			$AnimatedSprite2D.position.y=50
		else:
			$AnimatedSprite2D.position.y=70
		$AnimatedSprite2D.play('slide')
	elif(is_sitting):
		$AnimatedSprite2D.play('slide')
		$AnimatedSprite2D.position.y=23
	#elif(is_skiing!=0):
		#if $AnimatedSprite2D.flip_h == true:
			#$AnimatedSprite2D.position.y=23
	
	elif ($AnimatedSprite2D.animation=="jump" or just_jumped) && !is_on_wall:
		if !just_jumped && !is_on_floor():
			just_jumped = true
		elif just_jumped && is_on_floor() && $AnimatedSprite2D.animation!='air_to_run':
			$AnimatedSprite2D.play("air_to_run")
			$AnimatedSprite2D.speed_scale = 1
		elif just_jumped && $AnimatedSprite2D.animation == 'air_to_run' && ((direction == 0 or !is_on_floor()) or (is_on_wall or is_sitting)):
			just_jumped = false
			$AnimatedSprite2D.play("air")
	
	elif !is_on_floor() && !is_on_wall && $AnimatedSprite2D.animation!='air_dash':
		$AnimatedSprite2D.play("air")
		just_jumped = true
	elif is_on_wall:
		just_jumped=false
		if direction==wall_side || direction==0 || timer>0:
			$AnimatedSprite2D.play("wall_run")
		elif direction!=wall_side:
			$AnimatedSprite2D.play("run")
		#$AnimatedSprite2D.speed_scale = clamp(abs(speed)/900, 0.3, 1)
	elif (direction != 0 or abs(speed)>100):
		if $AnimatedSprite2D.animation!='dash':
			$AnimatedSprite2D.play("run")
			#$AnimatedSprite2D.speed_scale = clamp(abs(speed)/900, 0.3, 1)
	else:
		$AnimatedSprite2D.play("idle")
		
	if $AnimatedSprite2D.animation == 'wall_run' || $AnimatedSprite2D.animation == 'run':
		$AnimatedSprite2D.speed_scale = clamp(abs(speed)/900, 0.3, 1)
	else:
		$AnimatedSprite2D.speed_scale = 1

func check_collisions():
	var save_speed = false
	var tilemap = get_parent().find_child("TileMap")
	var tile_pos = tilemap.local_to_map(position)
	var tile_data = tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1))
	if(is_on_wall && test_move(transform, Vector2(0,-1))):
		speed = 0
	if(is_on_wall && test_move(transform, Vector2(0,1) * 1)):
		is_on_wall = false
		if(wall_side==1):
			position.x-=20
		else:
			position.x+=20
		wall_side = 0
		save_speed = false
	elif test_move(transform, Vector2(1,0)):
		var right_tile_pos = tile_pos + Vector2i(1,0)
		var right_tile_data = tilemap.get_cell_tile_data(0, right_tile_pos)
		if right_tile_data and right_tile_data.get_custom_data('climbable') and !is_sitting:
			if(!is_on_wall && speed>30):
				play_sound(preload("res://Sounds/Land.wav"))
				timer = 25
				if(!is_on_floor()):
					rebound = speed
					speed=0
				if (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y)) and tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y)).get_custom_data('curve')):
					save_speed = true
				position.y-=30
				is_on_wall = true
				wall_side = 1
				#rotation = deg_to_rad(-90 * wall_side)
				if(save_speed):
					speed+=100*speed_boost
				else:
					speed = 0
	elif test_move(transform, Vector2(-1,0)):
		var left_tile_pos = tile_pos + Vector2i(-1,0)
		var left_tile_data = tilemap.get_cell_tile_data(0, left_tile_pos)
		if left_tile_data and left_tile_data.get_custom_data('climbable') and !is_sitting:
			if(!is_on_wall && speed<-30):
				play_sound(preload("res://Sounds/Land.wav"))
				timer = 15
				if(!is_on_floor()):
					rebound = speed
					speed=0
				if (tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y)) and tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y)).get_custom_data('curve')):
					save_speed = true
				position.y-=30
				is_on_wall = true
				wall_side = -1
				#rotation = deg_to_rad(-90 * wall_side)
				if(save_speed):
					speed-=100*speed_boost
				else:
					speed = 0
				save_speed = false
	else:
		wall_side = 0
		is_on_wall = false
		rotation = 0.0

func handle_movement(direction, delta):
	
	if $AnimatedSprite2D.rotation_degrees<target_angle:
		$AnimatedSprite2D.rotation_degrees=target_angle
	elif $AnimatedSprite2D.rotation_degrees>target_angle:
		$AnimatedSprite2D.rotation_degrees=target_angle
	
	if skii_timer>0:
		skii_timer-=1
	if skii_timer == 0:
		target_angle = 0
		$AnimatedSprite2D.rotation_degrees = 0
		is_skiing = 0
	
	#if(is_skiing):
		#$AnimatedSprite2D.rotation=-45
	#else:
		#$AnimatedSprite2D.rotation=0
	
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
				speed -= 1/speed_boost
			elif(speed<-max_speed):
				speed += 1/speed_boost
	else:
		# Замедление при отпущенных клавишах
		if is_on_floor() or is_on_wall:
			if is_sitting:
				if is_skiing==0:
					speed -= sign(speed)*2
			else:
				speed *= friction*friction
		elif is_skiing==0:
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
	
	#elif  is_skiing!=0:
		#velocity.x = clamp(speed,-300,300)
	#else:
		#velocity.x = speed
	else:
		velocity.x = speed
	
	if direction == 0 and not is_on_wall:
		velocity.x = speed

func apply_gravity(delta):
	if not is_on_floor() and not is_on_wall and is_skiing==0:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
		
func handle_jump():
	if(timer==0):
		rebound = 0
	if is_on_wall or is_on_floor():
		double_jump = true
	if Input.is_action_just_pressed("jump"):
		if is_on_wall && timer>0:
			just_jumped=true
			$AnimatedSprite2D.play('wall_jump')
			$AnimatedSprite2D.frame = 1
			$AnimatedSprite2D.speed_scale = 1
			#$AnimatedSprite2D.flip_h = !$AnimatedSprite2D.flip_h
			velocity.x = -wall_side * abs(jump_force) * 3
			speed = 100
			velocity.y = jump_force * 0.8 * jump_boost
			is_on_wall = false
			speed=-rebound
			if speed == 0:
				speed = (-wall_side*300)
			if timer>0:
				if direction==-wall_side:
					speed+=sign(speed)*200
					velocity.y -= 300*jump_boost
		elif is_on_wall:
			if(wall_side == 1 && direction==wall_side):
				var tilemap = get_parent().find_child("TileMap")
				var tile_pos = tilemap.local_to_map(position)
				if tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y-3)) == null:
					play_sound(preload("res://Sounds/Land_on_Wall.wav"))
					position = tilemap.map_to_local(Vector2i(tile_pos.x+1, tile_pos.y-1))
					is_on_wall = false
					velocity=Vector2.ZERO
					rotation = 0.0
					wall_side = 0
					speed = speed+rebound
				else:
					$Jump.play(0.0)
					$AnimatedSprite2D.frame = 0
					velocity.x = -wall_side * abs(jump_force) * 3
					velocity.y = jump_force * 0.8 * jump_boost
					is_on_wall = false
					speed = (-wall_side*300)*speed_boost
			elif(wall_side == -1 && direction==wall_side):
				var tilemap = get_parent().find_child("TileMap")
				var tile_pos = tilemap.local_to_map(position)
				if tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y-3)) == null:
					play_sound(preload("res://Sounds/Land_on_Wall.wav"))
					position = tilemap.map_to_local(Vector2i(tile_pos.x-1, tile_pos.y-1))
					velocity=Vector2.ZERO
					rotation = 0.0
					wall_side = 0
					speed = speed+rebound
				else:
					$Jump.play(0.0)
					$AnimatedSprite2D.frame = 0
					velocity.x = -wall_side * abs(jump_force) * 3
					velocity.y = jump_force * 0.8 * jump_boost
					is_on_wall = false
					speed = (-wall_side*300)*speed_boost
			else:
				$Jump.play(0.0)
				$AnimatedSprite2D.frame = 0
				velocity.x = -wall_side * abs(jump_force) * 3
				velocity.y = jump_force * 0.8 * jump_boost
				is_on_wall = false
				speed = (-wall_side*300)*speed_boost
			#if right_tile_data and right_tile_data.get_custom_data('climbable'):
		elif (is_on_floor()||ground_timer<=4||is_skiing):
			stop_skiing = 15
			velocity.y = jump_force * jump_boost
			position.y-=10
			$Jump.play(0.0)
			$AnimatedSprite2D.frame = 0
		elif double_jump==true&&!is_on_wall&&stamina.value>0:
			stamina.value-=1
			double_jump = false
			velocity.y = jump_force * jump_boost
			position.y-=10
			$AnimatedSprite2D.play("jump")
			play_sound(preload("res://Sounds/Second_Jump.wav"))
			$AnimatedSprite2D.frame = 0
			
func handle_sit():
	
	if stop_skiing > 0:
		stop_skiing-=1
	
	if !$Slide.playing && (is_on_floor()||is_skiing) && is_sitting:
		$Slide.play()
	elif (!is_on_floor()&&!is_skiing)||!is_sitting||is_on_wall:
		$Slide.stop()
	
	###
	
	var tilemap = get_parent().find_child("TileMap")
	var tile_pos = tilemap.local_to_map(position)
				#if tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y-2)) == null or tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y-3)) == null:
	
	if (Input.is_action_pressed("sit")) and !is_on_wall:
		is_sitting = true
	elif !Input.is_action_pressed("sit") or is_on_wall:
		if is_sitting&&tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y-1))==null:
			is_sitting = false
		
	###
		
	if !is_sitting || stop_skiing>0:
		is_skiing = 0
		$CollisionShape2D.scale.y = 1
	else:
		$CollisionShape2D.scale.y=0.5
		var th = 30
		if((tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1))) && ((tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+1)).get_custom_data('angle')))):
			skii_timer = 5
			#$CollisionShape2D.disabled = true
			var loc = tilemap.map_to_local(tile_pos)
			
			if(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y)).get_custom_data('angle')):
				if speed>0:
					speed=0
				speed-=5*speed_boost
				
				if(stop_skiing==0):
					is_skiing=-1
				else:
					is_skiing=0
				
				skii_timer = 5
				
				var slope_height=-64
				position.y = loc.y + ((position.x-loc.x) / 64) * slope_height - 64/2 + th
				
				target_angle = -45
				
				$AnimatedSprite2D.flip_h = true
				$AnimatedSprite2D.position.x = abs($AnimatedSprite2D.position.x)
				
			elif(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y)).get_custom_data('angle')):
				if speed<0:
					speed=0
				speed+=10*speed_boost
				
				if(stop_skiing==0):
					is_skiing=-1
				else:
					is_skiing=0
				
				skii_timer = 5
				
				$AnimatedSprite2D.flip_h = false
				$AnimatedSprite2D.position.x = -abs($AnimatedSprite2D.position.x)
				
				var slope_height=64
				position.y = loc.y + ((position.x-loc.x) / 64) * slope_height - 64/2 + th
				
				target_angle = 45
		
		if((tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+2))) && ((tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x, tile_pos.y+2)).get_custom_data('angle')))):
			skii_timer = 5
			#$CollisionShape2D.disabled = true
			var loc = tilemap.map_to_local(tile_pos)
			
			if(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x+1, tile_pos.y+1)).get_custom_data('angle')):
				if speed>0:
					speed=0
				speed-=10*speed_boost
				
				if(stop_skiing==0):
					is_skiing=-1
				else:
					is_skiing=0
				
				skii_timer = 5
				
				var slope_height=-64
				position.y = loc.y + ((position.x-loc.x) / 64) * slope_height - 64/2 + th + 64
				
				target_angle = -45
				
				$AnimatedSprite2D.flip_h = true
				$AnimatedSprite2D.position.x = abs($AnimatedSprite2D.position.x)
				
			elif(tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)) && tilemap.get_cell_tile_data(0,Vector2i(tile_pos.x-1, tile_pos.y+1)).get_custom_data('angle')):
				if speed<0:
					speed=0
				speed+=10*speed_boost
				
				if(stop_skiing==0):
					is_skiing=1
				else:
					is_skiing=0
				
				skii_timer = 5
				
				$AnimatedSprite2D.flip_h = false
				$AnimatedSprite2D.position.x = -abs($AnimatedSprite2D.position.x)
				
				var slope_height=64
				position.y = loc.y + ((position.x-loc.x) / 64) * slope_height - 64/2 + th + 64
				
				target_angle = 45
		else:
			$CollisionShape2D.disabled=false
			
func handle_dash():
	if Input.is_action_just_pressed("dash") && stamina.value>0:
		var f = 0
		if direction !=0:
			f=1
			speed+=direction*300*speed_boost
			position.x+=20*direction
		if Input.is_action_pressed("w"):
			f=1
			velocity.y -= 600 * jump_boost
		if Input.is_action_pressed("s"):
			f=1
			velocity.y += 600 * jump_boost
		if f:
			if(is_on_floor()):
				play_sound(preload("res://Sounds/Dash.wav"))
				$AnimatedSprite2D.play('dash')
			elif(!is_on_floor() && !is_on_wall):
				play_sound(preload("res://Sounds/Dash.wav"))
				$AnimatedSprite2D.play("air_dash")
			
			if direction==-1:
				$AnimatedSprite2D.flip_h=1
			elif direction==1:
				$AnimatedSprite2D.flip_h=0
				
			stamina.value-=1

func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == 'air_to_run':
		just_jumped = false
	elif $AnimatedSprite2D.animation == 'dash':
		$AnimatedSprite2D.play('run')
	#elif $AnimatedSprite2D.animation == ('wall_jump'):
		#$AnimatedSprite2D.play('air')
		#$AnimatedSprite2D.flip_h=!$AnimatedSprite2D.flip_h
	pass # Replace with function body.

func _on_animated_sprite_2d_animation_changed():
	var an = $AnimatedSprite2D.animation
	if(an=='wall_jump'):
		play_sound(preload("res://Sounds/Jumppad.wav"))
	if($AnimatedSprite2D.animation=='wall_jump'):
		was_wall_jump = true
	else:
		if(was_wall_jump):
			$AnimatedSprite2D.flip_h=!$AnimatedSprite2D.flip_h
		was_wall_jump = false
	pass # Replace with function body.
