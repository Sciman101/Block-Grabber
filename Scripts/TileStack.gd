extends Node2D

const MAX_HELD_TILES := 6

const MAX_ADD_TIME := 0.4
const CYCLE_TIME := 0.15

onready var tween : Tween = $Tween
onready var sprite_parent : Node2D = $Sprites

var held_tiles = []
var tileset : TileSet
var collider : CollisionShape2D

# Add a new tile to the stack
func add_tile(id:int,direction:Vector2=Vector2.ZERO) -> void:
	# Create a new sprite
	var spr = Sprite.new()
	sprite_parent.add_child(spr)
	# Configure sprite
	spr.position = direction * 16
	
	spr.texture = tileset.tile_get_texture(id)
	spr.region_enabled = true
	if tileset.tile_get_tile_mode(id) == TileSet.AUTO_TILE:
		spr.region_rect = Rect2(tileset.autotile_get_icon_coordinate(id)*16,Vector2(16,16))
	else:
		spr.region_rect = tileset.tile_get_region(id)
	
	# Animate the sprite
	var count = held_tiles.size()+1
	tween.interpolate_property(spr,'position',spr.position,Vector2(0,-16*count),min(float(count)/10,MAX_ADD_TIME),Tween.TRANS_BACK,Tween.EASE_OUT)
	if not tween.is_active():
		tween.start()
	
	# Add tile to list
	held_tiles.append(id)
	_resize_collider()


# Move the tile at the bottom to the top
func cycle_tiles() -> void:
	
	if held_tiles.size() <= 1: return # No need to cycle a single tile
	if tween.is_active(): return # Don't interrupt the tween
	
	#held_tiles.append(held_tiles.pop_front())
	# Shift all the sprites around
	for sprite in sprite_parent.get_children():
		var target_pos : Vector2
		if sprite.get_index() == 0:
			target_pos = Vector2(0,-16*held_tiles.size())
		else:
			target_pos = Vector2(0,-16*sprite.get_index())
		tween.interpolate_property(sprite,'position',Vector2(0,(sprite.get_index()+1)*-16),target_pos,CYCLE_TIME,Tween.TRANS_QUAD,Tween.EASE_OUT)
	# Rearrange order
	sprite_parent.move_child(sprite_parent.get_child(0),held_tiles.size())
	tween.start()


func offset_tiles(amt:Vector2,delta:float) -> void:
	for sprite in sprite_parent.get_children():
		var i = sprite.get_index()+1
		sprite.offset.x = move_toward(sprite.offset.x,amt.x * i,delta*32)
		sprite.offset.y = lerp(sprite.offset.y,-max(amt.y/50 * i,0),delta*16)


func has_tiles() -> bool:
	return not held_tiles.empty()

func can_hold_more_tiles() -> bool:
	return held_tiles.size() < MAX_HELD_TILES and not get_parent().test_move(get_parent().transform,Vector2.UP)


func _resize_collider() -> void:
	var height = (held_tiles.size()+1) * 8 - 0.5
	var offset = held_tiles.size() * 8 + 0.5
	
	var rect = collider.shape as RectangleShape2D
	rect.extents.y = height
	collider.position.y = -offset
