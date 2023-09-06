extends Area2D

export (bool) var debug = true
export (float) var reaction_time = 1
export (float) var friction = 0.5

export (float) var repel_range = 500
export (float) var repel_response = 1
export (float) var repel_force = 100

export (float) var attract_range = 500
export (float) var attract_response = 1
export (float) var attract_force = 100

export (float) var random_force = 25
export (float) var random_min_interval = 4
export (float) var random_max_interval = 8
export (float) var random_multiplier_strength = 1

export (bool) var random_movement = true

var move_direction = Vector2.ZERO

var random_target = Vector2.ZERO
var random_distance = 0
var random_direction = Vector2.ZERO
var random_timer = 0
var random_interval = 0
var random_multiplier = 1

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	$AttractRange.shape.radius = attract_range 
	if debug: $RepelRange.polygon = Toolbox.generate_circle_points(repel_range/2)
	rng.randomize()
	
	move_direction = Vector2.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var attract = _attract()
	var repel = _repel()
	var random = _random(delta) * random_multiplier
	
	
	
	
	var move_target = move_direction*(1-friction) + attract + repel + random
	var target_distance = (move_target - move_direction).length()
	move_direction = move_direction.move_toward(move_target, target_distance*(delta/reaction_time))
	
	position += move_direction * delta
	
	if debug:
		$Attract.points = PoolVector2Array([Vector2(), attract])
		$Repel.points = PoolVector2Array([Vector2.ZERO, repel])
		$Random.points = PoolVector2Array([Vector2.ZERO, random])
		$Target.points = PoolVector2Array([Vector2.ZERO, move_target])
		$Movement.points = PoolVector2Array([Vector2.ZERO, move_direction])

func _attract():
	# I'm assuming the only body in the motes' collision mask is the player
	var bodies = get_overlapping_bodies()
	var attract_direction = Vector2.ZERO
	
	if not bodies.empty():
		var player = bodies[0]
		var direction = position.direction_to(player.position)
		var distance = position.distance_to(player.position)
		var padding = player.ATTRACT_PADDING
		
		random_multiplier = 1 + (random_multiplier_strength * distance/attract_range)
		
		if distance > padding:
			attract_direction = direction * pow((distance-padding)/(attract_range-padding), attract_response) * attract_force
	else:
		random_multiplier = 1
		
	
	return attract_direction

func _repel():
	
	var repel_direction = Vector2.ZERO
	var motes = get_overlapping_areas()
	
	for mote in motes:
		var direction = mote.position.direction_to(position)
		var distance = mote.position.distance_to(position)
		
		if distance < repel_range:
			repel_direction += direction * (1 - pow(distance/repel_range, repel_response)) * repel_force
	

	return repel_direction
	
func _random(delta):

	if not random_movement:
		return Vector2.ZERO

	random_timer += delta
	
	# check if enough time has passed for a random direction change
	if random_timer > random_interval:
		# set new interval
		random_interval = rng.randf_range(random_min_interval, random_max_interval)
		
		# set new random_direction
		random_target = Toolbox.random_vector(random_force)
		random_distance = random_direction.distance_to(random_target)
		random_timer = 0
	
	
	random_direction = random_direction.move_toward(random_target, random_distance*(delta/random_interval))
	
	
	return random_direction

