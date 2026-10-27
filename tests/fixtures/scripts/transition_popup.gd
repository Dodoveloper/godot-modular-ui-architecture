## Fixture: a popup implementing the close-transition contract used by PopupsUiLayer.
## [method begin_close_transition] records its call; tests emit [signal close_transition_finished]
## themselves to simulate an animation finishing.
extends Control

signal close_transition_finished

var begin_close_count := 0
var last_close_reason := -1


func begin_close_transition(reason: int) -> void:
	begin_close_count += 1
	last_close_reason = reason
