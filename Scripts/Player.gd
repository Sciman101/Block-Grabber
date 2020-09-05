extends KinematicBody2D

const COYOTE_TIME := 0.2 # Time we can jump after leaving a platform
const JUMP_BUFER_TIME := 0.1 # Time we can buffer a jump

# Movement properties
export var gravity : float
export var move_speed : float
export var jump_speed : float
export var acceleration : float
export var air_acceleration : float

onready var sprite = $Sprite
onready var ground_check = $GroundChecker
onready var tile_stack = $TileStack


# Platformer variables
var motion : Vector2
var facing : int = 1
var was_on_floor : bool = true
var coyote_time : float = 0
var jump_buffer : float = 0

# Tile handling
var tilemap : TileMap = null


# Setup variables
func _ready() -> void:
	tilemap = get_node_or_null("../TileMap")
	if tilemap:
		tile_stack.tileset = tilemap.tile_set
		tile_stack.collider = $CollisionShape2D


# Get input
func _physics_process(delta:float) -> void:
	
	# When we leave the floor, start the coyote timer
	if was_on_floor and not is_grounded():
		coyote_time = COYOTE_TIME
	# Decrement coyote timer and jump buffer timer
	elif coyote_time != 0:
		coyote_time -= delta
	if jump_buffer > 0:
		jump_buffer -= delta
	
	# Get horizontal input and determine target speed
	var hor = Input.get_action_strength("right") - Input.get_action_strength("left")
	var target_speed = hor * move_speed
	
	# Calculate acceleration
	var acc = acceleration # By default, regular acc
	if not is_grounded(): # If we aren't grounded...
		if hor != 0: # Trying to move?
			acc = air_acceleration # Air acceleration
		else: # Otherwise
			acc = 0 # Don't accelerate
	
	# Flip the character sprite
	if hor != 0:
		facing = sign(hor)
		sprite.flip_h = sign(hor) != 1
	
	# Accelerate
	motion.x = move_toward(motion.x,target_speed,acc * delta)
	
	# Apply gravity and jumping
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFER_TIME
	
	if can_jump():
		if jump_buffer > 0:
			motion.y = -jump_speed
			# Cancel coyote time
			coyote_time = 0
	# When we let go of the button, start slowing down to give us more jump control
	if Input.is_action_just_released("jump") and motion.y < 0:
		motion.y *= 0.5
	# Add gravity
	motion.y += gravity * delta
	
	handle_grabbing(delta)
	
	# Do the movement stuff
	motion = move_and_slide(motion,Vector2.UP)
	was_on_floor = is_grounded()
	
	tile_stack.offset_tiles(Vector2(-motion.x/move_speed * 2,motion.y),delta)


# Handle tile grabbing
func handle_grabbing(delta:float) -> void:
	
	if Input.is_action_just_pressed("cycle"):
		tile_stack.cycle_tiles()
		return
	
	if tilemap == null: return
	if not tile_stack.can_hold_more_tiles(): return
	
	# Check if grabbing
	var grabbing = Input.is_action_pressed('grab') and is_on_floor()
	if grabbing:
		# Move to nearest tile
#		var target_x = round((position.x-8)/16)*16+8
#		print(position.x)
#		if position.x != target_x:
#			position.x = move_toward(position.x,target_x,delta*150)
#		else:
		# Figure out what we want to grab
		var dir = get_dir_vector()
		print(dir)
		# By default, grab down
		if dir == Vector2.ZERO: dir = Vector2.DOWN
		var tile_pos = tilemap.world_to_map(position) + dir
		var tile = tilemap.get_cellv(tile_pos)
		# If it's something we can actually grab...
		if tile != -1:
			tile_stack.add_tile(tile,dir)
			tilemap.set_cellv(tile_pos,-1)
			tilemap.update_bitmask_area(tile_pos)


# Are we on the ground?
func is_grounded() -> bool:
	return ground_check.is_colliding()
	

# Helper to determine if we can jump
func can_jump() -> bool:
	return is_grounded() or coyote_time > 0


func get_dir_vector() -> Vector2:
	var dir = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"),\
					Input.get_action_strength("down") - Input.get_action_strength("up"))
	if dir != Vector2.ZERO:
		if abs(dir.x) > abs(dir.y):
			dir = Vector2.RIGHT * sign(dir.x)
		else:
			dir = Vector2.DOWN * sign(dir.y)
	return dir
