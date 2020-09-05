extends KinematicBody2D

onready var sprite = $Sprite

var tile : int
var gravity : float
var tilemap : TileMap
var motion : Vector2

func _physics_process(delta:float) -> void:
	motion.y += gravity * delta
	sprite.rotation_degrees += delta * motion.x * 2
	motion = move_and_slide(motion,Vector2.UP)
	
	if is_on_floor() or (tile == 1 and (is_on_wall() or is_on_ceiling())):
		# Snap back to world
		var target_x = (round((position.x-8) / 16) * 16) + 8
		var target_y = (round((position.y-8) / 16) * 16) + 8
		var pos = tilemap.world_to_map(Vector2(target_x,target_y))
		tilemap.set_cellv(pos,tile)
		if tilemap.tile_set.tile_get_tile_mode(tile) == TileSet.AUTO_TILE:
			tilemap.update_bitmask_area(pos)
		queue_free()

# Set the tile
func set_tile(index:int) -> void:
	
	if not sprite:
		sprite = $Sprite
	
	var tileset = tilemap.tile_set
	tile = index
	sprite.texture = tileset.tile_get_texture(index)
	if tileset.tile_get_tile_mode(index) == TileSet.AUTO_TILE:
		var size = tileset.autotile_get_size(index)
		sprite.region_rect = Rect2(tileset.autotile_get_icon_coordinate(index)*size,size)
	else:
		sprite.region_rect = tileset.tile_get_region(index)
