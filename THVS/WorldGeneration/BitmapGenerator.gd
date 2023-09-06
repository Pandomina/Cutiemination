extends Node

#Bitmapgenerator that generates (quadratic!) bitmaps with all sorts of processing methods  
enum BITMAP_DATA{TILE_TYPE, REGION_INDEX}
var rng = RandomNumberGenerator.new()
################################################################################
#----------------------------------Testing-------------------------------------#
################################################################################
#This Section is only for testing and debugging.
#Comment it out if you aren't doing that here. Thank you :)! 
#
#
#
#func _ready():
#	var test_bitmap = generate_world_regions_bitmap(100,0.47,null,10, 10, 10)
#	$Sprite.set_texture( bitmap_to_rgb_texture(test_bitmap))
#
#
#
#func _process(delta):
#	if Input.is_action_just_pressed("mouse_left_click"):
#		var test_bitmap = generate_world_regions_bitmap(100,0.47,null,10, 10, 10)
#		$Sprite.set_texture( bitmap_to_rgb_texture(test_bitmap))
#
#
#
################################################################################
#------------------------------------Public------------------------------------#
################################################################################



#Generates Main Worldmap regions without the boundaries
func generate_world_regions_bitmap(size, random_fill_percent, seed_value, clearing_radius, smoothing_steps, wall_threshold_size):
	#Set seed
	_set_seed(seed_value)
	
	#Setup random filled  world bitmap
	var world_bitmap = _setup_random_filled_bitmap(size, random_fill_percent,1)
	
	#Add middle clearing spawn region as a circle to world bitmap
	var middle_coord = Vector2(world_bitmap.size() / 2, world_bitmap.size() / 2)
	_add_circle_to_bitmap(world_bitmap, middle_coord, clearing_radius, 0)
	
	#Add outer boundary
	_add_anti_circle_to_bitmap(world_bitmap, Vector2(size/2-0.5, size/2-0.5), size/2-1 , 1)
	
	#Smooth world_bitmap smoothing_steps times  with Cellular Automata Simulation
	world_bitmap = _smooth_bitmap(world_bitmap, smoothing_steps)
	
	#Delete all room_regions that arent connected to the middle
	_process_room_regions(world_bitmap)
	
	#Delete outer boundary
	_add_anti_circle_to_bitmap(world_bitmap, Vector2(size/2-0.5, size/2-0.5), size/2-1 , 0)
	
	#Delete all wall regions under a threshold
	_process_wall_regions(world_bitmap, wall_threshold_size)
	
	#Extra smoothing step that smoothes wall that diagonally connects stuff
	#that isnt connect through direct neighbours
	_clean_up_corner_contacts(world_bitmap)
	
	#Index Regions
	_index_regions(world_bitmap)
	
	return world_bitmap



#Generates the upper half boundary of the main world
func generate_upper_half_boundary_bitmap(size):
	var half_boundary_bitmap = _setup_bitmap(size)
	for x in size:
		for y in size:
			if Toolbox.euclidian_distance(Vector2(x+0.5,y+0.5),Vector2(size/2,size/2)) >= size/2 -1 and y <= size/2:
				if _is_in_bitmap_range(half_boundary_bitmap,x,y):
					half_boundary_bitmap[x][y][BITMAP_DATA.TILE_TYPE] = 1
					#Indexing is done here already for runtime purposes in this case
					half_boundary_bitmap[x][y][BITMAP_DATA.REGION_INDEX] = 0
			else:
				half_boundary_bitmap[x][y][BITMAP_DATA.TILE_TYPE] = 0
	return half_boundary_bitmap 



#Converts a bitmap to a sprite texture with rgb colors and returns the texture
#TO DO: Could abstract over Image Format 
#TO DO: Add color paramters
func bitmap_to_rgb_texture(bitmap):
	var size = bitmap[0].size()
	var image = Image.new()
	image.create(size,size,false,4)
	
	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	for x in size:
		for y in size:
			if bitmap[x][y][BITMAP_DATA.TILE_TYPE] == 1:
				image.set_pixel(x, y, Color( 0, 0, 0))
			else:
				image.set_pixel(x, y, Color( 1, 1, 1))
	false # image.unlock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	
	var texture = ImageTexture.new()
	texture.create_from_image(image) #,1
	return texture



#Converts a bitmap to a sprite texture with rgba colors and returns the texture
#TO DO: Could abstract over Image Format 
#TO DO: Add color parameters
func bitmap_to_rgba_texture(bitmap):
	var size = bitmap[0].size()
	var image = Image.new()
	image.create(size,size,false,5)
	
	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	for x in size:
		for y in size:
			if bitmap[x][y][BITMAP_DATA.TILE_TYPE] == 1:
				image.set_pixel(x, y, Color( 0, 0, 0,1))
			else:
				image.set_pixel(x, y, Color( 1, 1, 1,1))
	false # image.unlock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	
	var texture = ImageTexture.new()
	texture.create_from_image(image) #,1
	return texture



#Gets the number of regions of a given tile_type in a given bitmap
func get_region_count(bitmap, tile_type):
	var regions = _get_regions(bitmap, tile_type)
	return regions.size()



################################################################################
#------------------------------------Private-----------------------------------#
################################################################################



#Setups bitmap as 3D-Array [size][size][BITMAP_DATA.size()] and returns bitmap afterwards
func _setup_bitmap(size):
	var bitmap = []
	for x in size:
		bitmap.append([])
		bitmap[x].resize(size)
		for y in size:
			bitmap[x][y] = []
			bitmap[x][y].resize(BITMAP_DATA.size())
	return bitmap



#Setups bitmap as 3D-Array [size][size][BITMAP_DATA.size()] filled at random and returns bitmap afterwards
func _setup_random_filled_bitmap(size, random_fill_percent, tile_type):
	var bitmap = []
	var flipped_tile_type = abs(tile_type - 1)
	for x in size:
		bitmap.append([])
		bitmap[x].resize(size)
		for y in size:
			bitmap[x][y] = []
			bitmap[x][y].resize(BITMAP_DATA.size())
			if rng.randf_range(0.0,1.0) < random_fill_percent:
				bitmap[x][y][BITMAP_DATA.TILE_TYPE] = tile_type
			else:
				bitmap[x][y][BITMAP_DATA.TILE_TYPE] = flipped_tile_type 
	return bitmap



#Loops over bitmap and sets given tile_type in given bitmap randomly with random_fill_percent
#seed is either set or random if seed_value == null
func _random_fill_bitmap(bitmap, random_fill_percent, tile_type):
	var size = bitmap[0].size()
	for x in size:
		for y in size:
			if rng.randf_range(0.0,1.0) < random_fill_percent:
				bitmap[x][y][BITMAP_DATA.TILE_TYPE] = tile_type



#Adds a circle at given coordinate with given radius as given tile_type on given bitmap 
func _add_circle_to_bitmap(bitmap, coord, radius, tile_type):
	for x in range(coord.x - radius, coord.x + radius + 1):
		for y in range(coord.y - radius,coord.y + radius + 1):
			if Toolbox.euclidian_distance(Vector2(x,y),coord) <= radius:
				if _is_in_bitmap_range(bitmap,x,y):
					bitmap[x][y][BITMAP_DATA.TILE_TYPE] = tile_type



#Adds an anti-circle at given coordinate with given radius as given tile_type on given bitmap 
func _add_anti_circle_to_bitmap(bitmap, coord, radius, tile_type):
	var size = bitmap[0].size()
	for x in size:
		for y in size:
			if Toolbox.euclidian_distance(Vector2(x,y),coord) >= radius:
				if _is_in_bitmap_range(bitmap,x,y):
					bitmap[x][y][BITMAP_DATA.TILE_TYPE] = tile_type



#Smoothes bitmap with cellular automata simulation and returns bitmap afterwards
func _smooth_bitmap(bitmap,smoothing_steps):
	for i in smoothing_steps:
		bitmap = _simulate_cellular_automata_on_bitmap(bitmap)
	return bitmap



#TO DO: Abstracting Cellular Automata rules could provide more flexibilty
#TO DO: Let it simulate all steps wanted and use double buffering for optimization
#Simulates one step of a Cellular Automata on a given bitmap with hard coded ruleset and returns it
func _simulate_cellular_automata_on_bitmap(bitmap):
	#Setup new Array
	var size = bitmap[0].size()
	var new_map = _setup_bitmap(size)
	#Cellular Automata Simulation Step
	for x in size:
		for y in size:
			var neighbour_wall_tiles = _get_surrounding_wall_count(bitmap,x, y)
			# Smoothing Rules
			if (neighbour_wall_tiles > 4):
				new_map[x][y][BITMAP_DATA.TILE_TYPE] = 1
			elif (neighbour_wall_tiles < 4):
				new_map[x][y][BITMAP_DATA.TILE_TYPE] = 0
			else:
				new_map[x][y][BITMAP_DATA.TILE_TYPE] = bitmap[x][y][BITMAP_DATA.TILE_TYPE]
	return new_map



#This fills all the room_regions that aren't connected to the middle with walls
func _process_room_regions(bitmap):
	var size = bitmap[0].size()
	var room_regions = _get_regions(bitmap, 0)
	for room_region in room_regions:
		if !room_region.has(Vector2(ceil(size/2),ceil(size/2))):
			_fill_region(bitmap, room_region, 1)



#This deletes wallclumps under a given wall_threshold_size
func _process_wall_regions(bitmap, wall_threshold_size):
	var wall_regions = _get_regions(bitmap, 1)
	for wall_region in wall_regions:
		if wall_region.size() < wall_threshold_size:
			for tile in wall_region:
				bitmap[tile.x][tile.y][BITMAP_DATA.TILE_TYPE] = 0



#Cleans up walls that are diagonal to walls while not beeing connected through direct neighbours
func _clean_up_corner_contacts(bitmap):
	var size = bitmap[0].size()
	for x in size:
		for y in size:
			if bitmap[x][y][BITMAP_DATA.TILE_TYPE] == 1:
				#Topleft
				if _is_in_bitmap_range(bitmap,x-1,y-1):
					if (bitmap[x-1][y-1][BITMAP_DATA.TILE_TYPE] == 1) and (bitmap[x-1][y][BITMAP_DATA.TILE_TYPE] == 0) and (bitmap[x][y-1][BITMAP_DATA.TILE_TYPE] == 0):
						bitmap[x][y][BITMAP_DATA.TILE_TYPE] = 0
						break
				#Topright
				if _is_in_bitmap_range(bitmap,x+1,y-1):
					if (bitmap[x+1][y-1][BITMAP_DATA.TILE_TYPE] == 1) and (bitmap[x+1][y][BITMAP_DATA.TILE_TYPE] == 0) and (bitmap[x][y-1][BITMAP_DATA.TILE_TYPE] == 0):
						bitmap[x][y][BITMAP_DATA.TILE_TYPE] = 0
						break
				#Bottomleft
				if _is_in_bitmap_range(bitmap,x-1,y+1):
					if (bitmap[x-1][y+1][BITMAP_DATA.TILE_TYPE] == 1) and (bitmap[x-1][y][BITMAP_DATA.TILE_TYPE] == 0) and (bitmap[x][y+1][BITMAP_DATA.TILE_TYPE] == 0):
						bitmap[x][y][BITMAP_DATA.TILE_TYPE] = 0
						break
				#Bottomright
				if _is_in_bitmap_range(bitmap,x+1,y-1):
					if (bitmap[x+1][y-1][BITMAP_DATA.TILE_TYPE] == 1) and (bitmap[x+1][y][BITMAP_DATA.TILE_TYPE] == 0) and (bitmap[x][y-1][BITMAP_DATA.TILE_TYPE] == 0):
						bitmap[x][y][BITMAP_DATA.TILE_TYPE] = 0
						break



#This assigns bitmap[x][y][BITMAP_DATA.REGION_INDEX] with indices
func _index_regions(bitmap):
	var wall_regions = _get_regions(bitmap,1)
	var region_index = 0
	for wall_region in wall_regions:
		for tile in wall_region:
			bitmap[tile.x][tile.y][BITMAP_DATA.REGION_INDEX] = region_index
		region_index += 1



################################################################################
#-------------------------------Helperfunctions--------------------------------#
################################################################################



#if seed_value is not null _set_seed sets seed equal to seed_value. seed is random otherwise
func _set_seed(seed_value):
	if seed_value == null:
		rng.randomize()
	else:
		rng.seed = seed_value



#Returns false if bitmap[x][y] is out of bounds. true otherwise
func _is_in_bitmap_range(bitmap,x,y):
	return (x >= 0) && (x < bitmap.size()) && (y >= 0) && (y < bitmap.size())



#counts the surrounding wall of a given coord in a given bitmap
#TO DO Abstract a function to count given tile_type
func _get_surrounding_wall_count(bitmap, grid_x, grid_y):
	var wallCount = 0
	for neighbour_x in range(grid_x-1, grid_x+2):
		for neighbour_y in range(grid_y-1, grid_y+2):
			# If were looking inside of the map
			if (_is_in_bitmap_range(bitmap, neighbour_x, neighbour_y)):
				# If were not looking at the current tile
				if (neighbour_x != grid_x || neighbour_y != grid_y):
					# Increase wallCount if there is a wall
					wallCount += bitmap[neighbour_x][neighbour_y][BITMAP_DATA.TILE_TYPE]
			# If were looking out of bound
			else:
				wallCount += 1
	return wallCount



#This returns all tiles that belong to the region at start_x start_y
func _get_region_tiles(bitmap, start_x, start_y):
	#Flood Flow Algorithm
	var size = bitmap[0].size()
	var tiles = []
	var map_flags = Toolbox.setup_2d_array(size,size,0)
	var tile_type = bitmap[start_x][start_y][BITMAP_DATA.TILE_TYPE]
	var queue = []
	queue.append(Vector2(start_x,start_y))
	map_flags[start_x][start_y]= 1
	while(!queue.is_empty()):
		var tile = queue.pop_back()
		tiles.append(tile)

		for x in range(tile.x - 1, tile.x + 2):
			for y in range(tile.y - 1, tile.y + 2):
				if(_is_in_bitmap_range(bitmap,x,y) && ((y == tile.y) || x == tile.x)):
					if((map_flags[x][y] == 0) && (bitmap[x][y][BITMAP_DATA.TILE_TYPE] == tile_type)):
						map_flags[x][y] = 1
						queue.append(Vector2(x,y))
	return tiles



#Gets all regions of a given bitmap that are of type tile_type 
func _get_regions(bitmap, tile_type):
	var size = bitmap[0].size()
	var regions = []
	var map_flags = Toolbox.setup_2d_array(size,size,0)
	for x in size:
		for y in size:
			if((map_flags[x][y] == 0) && (bitmap[x][y][BITMAP_DATA.TILE_TYPE] == tile_type)):
				var new_region = _get_region_tiles(bitmap,x,y)
				regions.append(new_region)
				for tile in new_region:
					map_flags[tile.x][tile.y] = 1
	return regions



#Fills a given region with given tile_type on a given bitmap
func _fill_region(bitmap, region, tile_type):
	for tile in region:
		bitmap[tile.x][tile.y][BITMAP_DATA.TILE_TYPE] = tile_type
