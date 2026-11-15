class_name PlayerStateMachine
extends Node
## Gerencia os estados do astronauta. Cada filho é um PlayerState.

@onready var idle: PlayerState = $idle
@onready var walk: PlayerState = $walk
@onready var run: PlayerState = $run
@onready var jump: PlayerState = $jump
@onready var fall: PlayerState = $fall
@onready var skid: PlayerState = $skid
@onready var crouch: PlayerState = $crouch
@onready var mine: PlayerState = $mine
@onready var hurt: PlayerState = $hurt
@onready var death: PlayerState = $death

var current_state: PlayerState
var player: Player


func init(p: Player) -> void:
	player = p
	for child in get_children():
		if child is PlayerState:
			child.player = p
			child.state_machine = self
	change_state(idle)


func change_state(new_state: PlayerState) -> void:
	if new_state == null or new_state == current_state:
		return
	# Morto não sai mais do estado de morte
	if current_state == death:
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()


func process_physics(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
