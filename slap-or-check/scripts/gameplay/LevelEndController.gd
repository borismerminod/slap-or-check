## Ends the level: freezes what is running, says how it went, and starts over.
##
## - The single arbiter of the end of a level. A victory and a defeat reach it the
##   same way, by signal from the scene, and leave it along the same path.
## - Holds the two things to freeze by injection and calls them itself. A defeat
##   and a victory have to stop exactly the same things, and saying so once, here,
##   is what guarantees they do.
## - Restarts by reloading the scene, which leaves no state behind at all.
class_name LevelEndController
extends Node

## Emitted once, naming how the level ended, for whoever shows it.
signal level_ended(outcome: LevelOutcome.Kind)

## The level to stop. Injected from the scene.
@export var level_director: LevelDirector

## The moral to freeze. Injected from the scene. Without it the bar would go on
## draining under a victory, and could even reach zero there.
@export var moral_controller: MoralController

## Counts down to the restart. Injected from the scene.
@export var restart_timer: Timer

## Seconds the player is left looking at the outcome before the level starts over.
@export_range(0.5, 10.0, 0.5) var restart_delay_seconds: float = 3.0

## Guards against ending twice: the moral can run out on the very frame the queue
## clears, and whichever arrives first is the one that counts.
var _is_ended: bool = false


## Listens for the end of the countdown.
func _ready() -> void:
	restart_timer.timeout.connect(_on_restart_timer_timeout)


## Reports a level won: the whole queue was dealt with and the moral held.
##
## - Public because the level is wired to it by signal in the scene.
func report_victory() -> void:
	_end_level(LevelOutcome.Kind.VICTORY)


## Reports a level lost: the moral ran out.
##
## - Public because the moral is wired to it by signal in the scene.
func report_defeat() -> void:
	_end_level(LevelOutcome.Kind.DEFEAT)


## Freezes the level, announces the outcome, and starts the countdown.
##
## - The delay is passed to the timer at the call, so the exported value is the
##   only source and the wait time stored in the scene cannot contradict it.
func _end_level(outcome: LevelOutcome.Kind) -> void:
	if _is_ended:
		return
	_is_ended = true
	level_director.stop()
	moral_controller.stop()
	level_ended.emit(outcome)
	restart_timer.start(restart_delay_seconds)


## Starts the level over from scratch.
##
## - Reloading the scene puts the moral, the queue, the colours and the sentences
##   back to their opening state: nothing has to be reset by hand, and no
##   leftover state is possible.
func _on_restart_timer_timeout() -> void:
	get_tree().reload_current_scene()
