extends KinematicBody2D

const GRAB_DURATION := 0.5
const THROW_SPEED := 250

const GRABBABLE_TILES = [0,1,2,3,4]

const ThrownTile = preload("res://ThrownTile.tscn")

export var gravity : float
export var move_speed : float
export var jump_speed : float
export var acceleration : float
export var air_acceleration : float

onready var sprite = $Sprite
onready var held_sprite = $Held/HoldingSprite
onready var held_shape = $HeldShape
onready var tween = $Held/Tween

onready var tilemap = $"../TileMap"

var motion : Vector2
var facing : int = 1
var was_throwing : bool

var held_tile : int = -1 setget set_held_tile


# Get input
func _physics_process(delta:float) -> void:
	
	var grounded = is_on_floor()
	var grabbing = grounded and Input.is_action_pressed("grab") and held_tile == -1 and not was_throwing
	var throwing = Input.is_action_just_pressed("grab") and held_tile != -1
	
	# Get horizontal input
	var hor = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	var target_speed = hor * move_speed
	
	var acc = acceleration
	if not grounded:
		acc = air_acceleration if hor != 0 else 0
	
	if hor != 0 and not grabbing:
		facing = sign(hor)
		sprite.flip_h = sign(hor) != 1
	
	motion.x = move_toward(motion.x,target_speed,acc * delta)
	
	# Apply gravity and jumping
	if not grabbing:
		if grounded:
			if Input.is_action_pressed("jump"):
				motion.y = -jump_speed
		else:
			if Input.is_action_just_released("jump") and motion.y < 0:
				motion.y *= 0.5
			motion.y += gravity * delta
	
	# If we are grabbing...
	if grabbing:
		# Get target x position
		var target_x = (round((position.x-8) / 16) * 16) + 8
		if abs(position.x - target_x) > .5:
			move_and_collide(Vector2.RIGHT * (target_x-position.x) * delta * 25)
		else:
			# Grab the tile below us
			grab_tile(sign(hor))
	
	elif throwing:
		was_throwing = true
		throw_tile()
	
	if Input.is_action_just_released("grab"):
		was_throwing = false
	
	# Do the movement stuff
	motion = move_and_slide(motion,Vector2.UP)


func throw_tile() -> void:
	
	# Get directional input
	var dir = Vector2(
		(Input.get_action_strength("right") - Input.get_action_strength("left")),
		(Input.get_action_strength("down") - Input.get_action_strength("up")))
	if abs(dir.x) >= abs(dir.y):
		dir = Vector2.RIGHT * sign(dir.x)
	else:
		dir = Vector2.DOWN * sign(dir.y)
	
	if dir == Vector2.ZERO:
		# Throw it
		var inst = ThrownTile.instance()
		
		# Set thrown tile properties
		inst.position = held_sprite.global_position
		inst.tilemap = tilemap
		inst.set_tile(held_tile)
		inst.gravity = gravity
		
		# Calculate throw velocity
		var motion = Vector2(facing*THROW_SPEED,-THROW_SPEED)
		inst.motion = motion
		
		self.held_tile = -1
		
		get_parent().add_child(inst)
	else:
		# Get tilemap pos
		var pos = tilemap.world_to_map(position) + dir
		# We have to stick a tile onto something
		if tilemap.get_cellv(pos+dir) != -1 or tilemap.get_cellv(pos+dir.tangent()) != -1 or tilemap.get_cellv(pos-dir.tangent()) != -1:
			if dir.y > 0:
				position -= dir * 16
			tilemap.set_cellv(pos,held_tile)
			if tilemap.tile_set.tile_get_tile_mode(held_tile) == TileSet.AUTO_TILE:
				tilemap.update_bitmask_area(pos)
			self.held_tile = -1


func grab_tile(dir:int) -> void:
	
	# We can't grab if there's something above us
	if test_move(transform,Vector2.UP * 8):
		return
	
	# Get tilemap position
	var offset = (Vector2.DOWN if dir == 0 else Vector2.RIGHT * dir)
	
	var pos = tilemap.world_to_map(position) + offset
	var tile = tilemap.get_cellv(pos)
	
	var grab = tile in GRABBABLE_TILES
	
	if grab:
		# Grab tile below and store reference
		self.held_tile = tilemap.get_cellv(pos)
		
		tween.seek(1)
		
		# Animate
		tween.interpolate_property(held_sprite,'position',offset * 16,Vector2(0,-16),0.25,Tween.TRANS_BACK,Tween.EASE_OUT)
		tween.start()
		
		# Update tilemap
		tilemap.set_cellv(pos,-1)
		tilemap.update_bitmask_area(pos)
		
		# Reset motion
		motion.y = 0


# Assign the tile to be held
func set_held_tile(tile:int) -> void:
	held_tile = tile
	
	if tile != -1:
		held_sprite.scale = Vector2.ONE
		held_sprite.visible = true
		held_shape.disabled = false
		
		var tileset = tilemap.tile_set
		held_sprite.texture = tileset.tile_get_texture(held_tile)
		if tileset.tile_get_tile_mode(held_tile) == TileSet.AUTO_TILE:
			var size = tileset.autotile_get_size(held_tile)
			held_sprite.region_rect = Rect2(tileset.autotile_get_icon_coordinate(held_tile)*size,size)
		else:
			held_sprite.region_rect = tileset.tile_get_region(held_tile)
	else:
		held_sprite.visible = false
		held_shape.disabled = true
