extends KinematicBody2D

const ACCELERATION = 10000
const MAXSPEED = 600
const FRICTION = 0.4
const ATTRACT_PADDING = 10
export var stick_response = 0.5
var velocity = Vector2.ZERO

func _physics_process(delta):
	update() # for draw
	var input_vector = get_movement_input()
	apply_movement(input_vector, delta)

func get_movement_input():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	return input_vector

func apply_movement(input_vector,delta):
	if input_vector != Vector2.ZERO:
		input_vector = input_vector* pow(input_vector.length(),stick_response)
		velocity += input_vector * ACCELERATION * delta
		velocity = velocity.clamped(MAXSPEED)
	else:
		velocity = velocity.linear_interpolate(Vector2.ZERO, FRICTION)
		
	velocity = move_and_slide(velocity)

func _draw():
	var input_vector = get_movement_input()
	draw_line(Vector2.ZERO, input_vector *100 ,Color.red,5)
