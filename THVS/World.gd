extends Node


export var scale_factor = 50.0
export var region_color = Color(1,0,0,0.8)

#World Regions Bitmap settings
export var size = 100
export var random_fill_percent = 0.47
export var seed_value = 55555
export var clearing_radius = 10
export var smoothing_steps = 10
export var wall_threshold_size = 10

var region_map
var region_count
var region_triangles
var region_polygons

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	_generate_map()
	pass

func _generate_map():
	# generate bitmap
	region_map = $BitmapGenerator.generate_world_regions_bitmap(size, random_fill_percent, seed_value, clearing_radius, smoothing_steps, wall_threshold_size)
	region_count = $BitmapGenerator.get_region_count(region_map,1)
	region_triangles = $BitmapToPolygonConverter.marching_squares(region_map,region_count)
	region_polygons = $BitmapToPolygonConverter.convert_triangles_to_polygon_data(region_triangles,region_count)

	# show bitmap as image
	#$BitmapGenerator.Sprite.set_texture($BitmapGenerator.bitmap_to_rgba_texture(region_map, Color(0,0,0,1), scale_factor))
	# create wall nodes
	generate_region_polygons(region_polygons)

	var boundary_map = $BitmapGenerator.generate_upper_half_boundary_bitmap(size)
	var boundary_triangles = $BitmapToPolygonConverter.marching_squares(boundary_map,1)
	#$BitmapGenerator.dynamic_bitmap_to_sprite(boundary_map, Color(0,1,0,0.5), scale_factor)

	var boundary_data = $BitmapToPolygonConverter.convert_triangles_to_polygon_data(boundary_triangles,1)
	generate_region_polygons(boundary_data)


	# Add flipped Boundary (hard coded)
	var polygon = Polygon2D.new()
	polygon.set_polygon(boundary_data[0])
	polygon.position = Vector2(0.5 * scale_factor,0.5 *scale_factor)
	polygon.color = region_color
	polygon.scale.x = scale_factor
	polygon.scale.y = -scale_factor
	polygon.position.y -= scale_factor
	add_child(polygon)
	#
	var static_body2d = StaticBody2D.new()
	var collision_polygon = CollisionPolygon2D.new()
	collision_polygon.set_polygon(boundary_data[0])
	collision_polygon.position = Vector2(0.5 * scale_factor,0.5 *scale_factor)
	collision_polygon.scale.x = scale_factor
	collision_polygon.scale.y = -scale_factor
	collision_polygon.position.y -= scale_factor
	static_body2d.add_child(collision_polygon)
	add_child(static_body2d)



func _process(delta):
	pass


func debug_create_polygon(region_index):
	pass

func generate_region_polygons(polygon_data):
	#this generates the  the wallregions as polygons
	for polygon_index in polygon_data.size():
		var static_body2d = StaticBody2D.new()
		static_body2d.add_child(generate_polygon2d_from_data(polygon_data[polygon_index],region_color))
		static_body2d.add_child(generate_collision_polygon_from_data(polygon_data[polygon_index]))
		add_child(static_body2d)

func generate_collision_polygon_from_data(polygon_data):
	var collision_polygon = CollisionPolygon2D.new()
	collision_polygon.set_polygon(polygon_data)
	collision_polygon.position = Vector2(0.5 * scale_factor, 0.5 * scale_factor)
	collision_polygon.scale.x = scale_factor
	collision_polygon.scale.y = scale_factor
	return collision_polygon

func generate_polygon2d_from_data(list_of_points, color):
	var polygon = Polygon2D.new()
	polygon.set_polygon(list_of_points)
	polygon.color = color
	polygon.position = Vector2(0.5 * scale_factor, 0.5 * scale_factor)
	polygon.scale.x = scale_factor
	polygon.scale.y = scale_factor
	return polygon
