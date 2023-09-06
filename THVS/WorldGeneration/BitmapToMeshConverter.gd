extends Node

class_name MeshGenerator
enum BITMAP_DATA{TILE_TYPE, REGION_INDEX}
var square_grid
var region_triangles

#Inner Classes
class SquareGrid:
	var squares
	
	func _init(map):
		var vertex_count = map.size()
		var map_size = vertex_count
		var control_vertices = Toolbox.setup_2d_array(map_size, map_size,null)
		for x in map_size:
			for y in map_size:
				var pos = Vector2(-map_size/2 + x  + 1/2, -map_size/2 + y  + 1/2)
				control_vertices[x][map_size- (y+1)] = ControlVertex.new(pos, map[x][y][BITMAP_DATA.TILE_TYPE] == 1, map[x][y][BITMAP_DATA.REGION_INDEX])
		
		squares = Toolbox.setup_2d_array(map_size-1, map_size-1,null)
		for x in map_size-1:
			for y in map_size-1:
				squares[x][y] = Square.new(control_vertices[x][y+1],control_vertices[x+1][y+1],control_vertices[x+1][y],control_vertices[x][y])

class Square:
	#Control Vertices
	var top_left
	var top_right
	var bottom_right
	var bottom_left
	#Vertices
	var centre_top
	var centre_right
	var centre_bottom
	var centre_left
	#
	var configuration = 0
	
	func _init(_top_left, _top_right, _bottom_right, _bottom_left):
		#Control Vertices
		top_left = _top_left
		top_right = _top_right
		bottom_right = _bottom_right
		bottom_left =_bottom_left
		#Vertices
		centre_top = top_left.right
		centre_right = bottom_right.above
		centre_bottom = bottom_left.right
		centre_left = bottom_left.above
		#
		if (top_left.active):
			configuration += 8
		if (top_right.active):
			configuration += 4
		if (bottom_right.active):
			configuration += 2
		if (bottom_left.active):
			configuration += 1

class Vertex:
	var position #Vector2
	var index = -1
	
	func _init(_position):
		position = _position

class ControlVertex:
	extends Vertex
	var active
	var above
	var right
	var region_index
	
	func _init(_position, _active, _region_index).(_position):
		active = _active
		region_index = _region_index
		above = Vertex.new(position + Vector2.UP  / 2.0 ) 
		right = Vertex.new(position + Vector2.RIGHT  / 2.0)

# -------------------------------------------------------------------------------

func marching_squares(bitmap,number_of_regions):
	square_grid = SquareGrid.new(bitmap)
	#triangles is a 3d array regions->triangles->positions
	region_triangles = []
	for region in number_of_regions:
		region_triangles.append([])
		
	for x in square_grid.squares.size():
			for y in square_grid.squares.size():
				triangulate_square(square_grid.squares[x][y])
	return region_triangles

func convert_triangles_to_polygon_data(triangles, number_of_regions, specific_region = -1, debug = false):

	if specific_region >=0 and specific_region < number_of_regions:
		return tri_to_poly(triangles[specific_region], debug)
		
	else:
		var polygons = []
		for region in triangles.size():
			polygons.append(tri_to_poly(region_triangles[region], debug))	
		return polygons

func triangulate_square(square):
	match square.configuration:
		0:
			pass
		# 1 points
		1:
			mesh_from_points([square.centre_bottom, square.bottom_left, square.centre_left])
		2:
			mesh_from_points([square.centre_right, square.bottom_right, square.centre_bottom])
		4:
			mesh_from_points([square.centre_top, square.top_right, square.centre_right])
		8:
			mesh_from_points([square.top_left, square.centre_top, square.centre_left])
		# 2 points
		3:
			mesh_from_points([square.centre_right, square.bottom_right, square.bottom_left, square.centre_left])
		6:
			mesh_from_points([square.centre_top, square.top_right, square.bottom_right, square.centre_bottom])
		9:
			mesh_from_points([square.top_left, square.centre_top, square.centre_bottom, square.bottom_left])
		12:
			mesh_from_points([square.top_left, square.top_right, square.centre_right, square.centre_left])
		5:
			mesh_from_points([square.centre_top, square.top_right, square.centre_right, square.centre_bottom, square.bottom_left, square.centre_left])
		10:
			mesh_from_points([square.top_left, square.centre_top, square.centre_right, square.bottom_right, square.centre_bottom, square.centre_left])
		# 3 points
		7:
			mesh_from_points([square.centre_top, square.top_right, square.bottom_right, square.bottom_left,square.centre_left])
		11:
			mesh_from_points([square.top_left, square.centre_top, square.centre_right, square.bottom_right,square.bottom_left])
		13:
			mesh_from_points([square.top_left, square.top_right, square.centre_right, square.centre_bottom ,square.bottom_left])
		14:
			mesh_from_points([square.top_left, square.top_right, square.bottom_right, square.centre_bottom,square.centre_left])
		# 4 points
		15:
			mesh_from_points([square.top_left, square.top_right, square.bottom_right, square.bottom_left])

func mesh_from_points(points):
	var region_index 
	for point in points:
		if ("region_index" in point) and (point.region_index != null):
			region_index = point.region_index
			break
		

	if(points.size() >= 3):
		create_triangle(points[0],points[1],points[2],region_index)
	if(points.size() >= 4):
		create_triangle(points[0],points[2],points[3],region_index)
	if(points.size() >= 5):
		create_triangle(points[0],points[3],points[4],region_index)
	if(points.size() >= 6):
		create_triangle(points[0],points[4],points[5],region_index)
	


func create_triangle(a,b,c,region_index):
	region_triangles[region_index].append([a.position,b.position,c.position])


# IN: array[n][3]  n arrays with length 3 (three Vector2 each)
# OUT: PoolVector2Array[m]  List of points (Vector2) that defines a polygon
func tri_to_poly(list_of_triangles, debug):
	
	# take the last triangle to start our new polygon
	# we go backwards through the array so hopefully removing triangles doesn't hurt as much
	var new_polygon = list_of_triangles.pop_back()
	var current_triangle = list_of_triangles.size()-1
	var last_match = -1
	
	if debug:
		print()
		print("Begin generating new polygon.")
		print("Starting triangle:")
		Toolbox.print_array(new_polygon)
		print()
	
	# check all triangles in the list
	while list_of_triangles.size() > 0:
		
#		if current_triangle == last_match:
#			# uh oh, we went around the list without finding a match
#			# this should never actually happen, but we still need to catch that case to prevent an endless loop
#			print("WARNING! No more matches found, but there are still triangles left in the list:")
#			Toolbox.print_array(list_of_triangles)
#			break
		
		var triangle = list_of_triangles[current_triangle]
		if debug: print("Checking triangle %d..." % current_triangle)

		if add_triangle(new_polygon, triangle, debug) != -1:
			# since we found a match and added it to new_polygon, remove this triangle from the list
			last_match = current_triangle
			list_of_triangles.remove(current_triangle)
			
		current_triangle -= 1
		if current_triangle < 0:
			# back to the start (or end, in this case)
			current_triangle = list_of_triangles.size()-1
			
			
	return PoolVector2Array(new_polygon)


func add_triangle(new_polygon, triangle, debug):
	var point_to_insert = Vector2()
	var index = [-1,-1,-1]
	var changed_index = -1
	var matches = []
	
	# check each point of the triangle
	for i in 3:
		# find the index of this point in new_polygon (-1 if not found)
		index[i] = new_polygon.find(triangle[i])
			
		if index[i] == -1:
			# this point is not in new_polygon yet, so it is a candidate for insertion
			point_to_insert = triangle[i]
		else:
			# this point is already in new_polygon, note the match
			matches.append(i)
		
	
	if (matches.size() > 1) and debug:
		print("Match: %s" % [triangle])
		
	if matches.size() == 3:
		if debug: print(" All points match at indices %d, %d, %d" % [index[0], index[1], index[2]])
		index.sort()
		
		if index[0] == 0 and index[1] == new_polygon.size()-2:
			changed_index = index[2]
		elif index[0] == 0 and index[2] == new_polygon.size() - 1:
			changed_index = index[0]
		else:
			changed_index = index[1]
			
		if debug: print(" Removing point %s at index %d" % [new_polygon[changed_index], changed_index])
		new_polygon.remove(changed_index)
		
	# if two of the triangle's points were already in new_polygon, add the new point between them
	elif matches.size() == 2:
		index.sort()
		# index[0] is now -1, we want to insert the new point between index[1] and index[2]
		
		if debug: print(" Two points match: %s and %s at indices %d and %d" % [new_polygon[index[1]], new_polygon[index[2]],  index[1], index[2]])
		if index[1] == 0 and index[2] == new_polygon.size()-1:
			# new point is beween the first and last point of new_polygon, insert at the end of the list
			changed_index = new_polygon.size()
		else:
			# index[1] and index[2] SHOULD always be consecutive, so this adds the new point between the two...
			changed_index = index[2]
			
			# ...however, just in case:
			if index[2] - index[1] != 1:
				if debug: print(" WARNING! Indices were NOT consecutive while adding new point: %d, %d" % [index[1], index[2]])
				
		if debug: print(" Adding remaining point %s at index %d" % [point_to_insert, changed_index])
		new_polygon.insert(changed_index, point_to_insert)
	
	if changed_index != -1 and debug:
		# we changed something
		print()
		print("Updated Polygon:")
		Toolbox.print_array(new_polygon, [changed_index])
		print()
	return changed_index

