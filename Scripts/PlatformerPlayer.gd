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

# Platformer variables
var motion : Vector2
var facing : int = 1
var was_on_floor : bool = true
var coyote_time : float = 0
var jump_buffer : float = 0


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
	
	# Do the movement stuff
	motion = move_and_slide(motion,Vector2.UP)
	was_on_floor = is_grounded()


# Are we on the ground?
func is_grounded() -> bool:
	return ground_check.is_colliding()
	

# Helper to determine if we can jump
func can_jump() -> bool:
	return is_grounded() or coyote_time > 0
