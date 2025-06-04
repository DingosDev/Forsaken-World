extends Node
class_name StateMachine

@export var debug := false

@onready var state := ""
@onready var previous_state := ""
@onready var host := get_owner()
var states = {}

func _ready():
	for i in get_children():
		if i is State:
			states[i.name] = i
			i.state_machine = self
			i.host = host
	
	state = states.keys()[0]
	
	await host.ready
	
	states[state].enter([])

func _physics_process(delta):
	var current_state = states[state]
	
	current_state.step(delta)
	
	if debug: print(state)
	
	var new_state = current_state.conditions()
	if new_state is Array && !new_state.is_empty(): change_state(new_state.pop_front(), new_state)

func change_state(new_state, _parameters=[]):
	if state == new_state: return
	
	var current_state = states[state]
	var next_state = states[new_state]
	
	previous_state = state
	state = new_state
	
	current_state.exit()
	next_state.enter(_parameters)
