extends Node

#Toolbox
#Used for Helperfunctions you will use globally

func setup_2d_array(width,height,start_value):
	# setup 2d_array
	var array = []
	for x in width:
		array.append([]) # Add an empty array
		array[x].resize(height) # Change the size of the array to height
		for y in height:
			array[x][y] = start_value
	return array


func manhatten_distance(coord1, coord2):
	return abs(coord1.x - coord2.x) + abs(coord1.y - coord2.y)

func euclidian_distance(coord1, coord2):
	return (coord2 - coord1).length() 



# prints the content of an array with indices
# optionally allows for highlighting values at specific indices
func print_array(a, highlights=[]):
	
	for i in range(a.size()):
		
		var highlight = " "
		if highlights.has(i):
			highlight = ">"
		
		print("%s %d: %s" % [highlight, i, a[i]])


# returns a PoolVector2Array for a polygon shape that is a "circle" with n corners
func generate_circle_points(radius, n = 24):
	var v = Vector2(0, radius)
	var circle = []
	
	for i in range(n):
		circle.append(v.rotated((2*PI*i)/n))
	
	return PackedVector2Array(circle)

# returns a Vector2 with random direction
func random_vector(length = 1, min_angle = 0, max_angle = 2*PI):
	
	var v = Vector2(0, length)
	var random_angle = min_angle + randf() * (max_angle - min_angle)
	
	return v.rotated(random_angle)
