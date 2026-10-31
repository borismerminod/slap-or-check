## A character leaving the stage, on their own clock.
##
## - Exists apart from [Encounter] because the next character walks in while the
##   previous one is still in the air. That overlap is what gives the loop its
##   rhythm: remove it and the corridor goes empty between two characters.
## - Three ways out, chosen by the gesture that was performed and not by the
##   verdict: an undeserved slap sends the character flying all the same.
## - Advanced by its owner through [method advance], which never frees anything;
##   the owner drops a finished exit with [method dismiss].
class_name CharacterExit
extends RefCounted

## FLY is a slapped character, LEAVE a checked one, SHOVE_THROUGH one that got
## past the player unanswered.
enum Kind {
	FLY,
	LEAVE,
	SHOVE_THROUGH,
}

## Seconds a leaving character stays on stage. Matches the knocked away clip.
const LIFETIME: float = 1.4

## Speed a slapped character is thrown at: away to the left, up, and back.
const FLY_VELOCITY: Vector3 = Vector3(-5.5, 4.2, -2.5)

## Downward acceleration applied to a slapped character, in metres per second
## squared. Far above real gravity, which is what makes the arc read as a blow.
const FLY_GRAVITY: float = 16.0

## How far a checked character turns before walking off.
const TURN_AWAY_RADIANS: float = 2.3

## How fast that turn is taken, as a share of the remaining angle per second.
const TURN_RATE: float = 8.0

## Speed a checked character walks off at.
const LEAVE_VELOCITY: Vector3 = Vector3(-1.9, 0.0, -1.2)

## Height and tempo of the hop of a checked character walking off pleased.
const LEAVE_HOP_HEIGHT: float = 0.22

## See [constant LEAVE_HOP_HEIGHT].
const LEAVE_HOP_RATE: float = 9.0

## Seconds a character takes to barge past the player and out of frame.
const SHOVE_DURATION: float = 1.1

## How far to the side a character barging past ends up.
const SHOVE_SIDE_X: float = -1.1

## How far behind the camera a character barging past ends up.
const SHOVE_END_Z: float = 8.0

## How much sooner the sideways step is finished than the walk past.
const SHOVE_SIDE_HASTE: float = 2.2

## Playback speed of the walk cycle of a character walking off: mockup speed 10.
const LEAVE_SPEED_SCALE: float = 1.18

## Playback speed of the walk cycle of a character barging past: mockup speed 13.
const SHOVE_SPEED_SCALE: float = 1.53

## The figure walking off. Freed by [method dismiss].
var _figure: Stickman

## Which way out this is.
var _kind: Kind

## Where the figure stood when the encounter ended.
var _start_position: Vector3

## Seconds since the exit started.
var _elapsed: float = 0.0

## Current speed of a thrown figure, which gravity bends frame by frame.
var _velocity: Vector3 = Vector3.ZERO

## Heading a checked figure turns toward before walking off.
var _turn_target_y: float = 0.0


## Takes the figure to walk off and the way it should leave.
func _init(figure: Stickman, kind: Kind) -> void:
	_figure = figure
	_kind = kind
	_start_position = figure.position
	_turn_target_y = figure.rotation.y - TURN_AWAY_RADIANS
	_start_leaving()


## True once the figure has been off stage long enough to be dropped.
func is_finished() -> bool:
	return _elapsed >= LIFETIME


## Takes the figure out of the scene. Called by the owner, once.
func dismiss() -> void:
	_figure.queue_free()


## Moves the leaving figure by one frame.
func advance(delta: float) -> void:
	_elapsed += delta
	match _kind:
		Kind.FLY:
			_advance_flight(delta)
		Kind.LEAVE:
			_advance_walk_off(delta)
		Kind.SHOVE_THROUGH:
			_advance_shove_through()


## Sets up the way out: its starting speed, or the clip it walks off on.
##
## - A slapped figure keeps the knocked away clip the encounter started on
##   impact, so only its path through the air is left to play.
func _start_leaving() -> void:
	match _kind:
		Kind.FLY:
			_velocity = FLY_VELOCITY
		Kind.LEAVE:
			_figure.play_loop(Stickman.WALK, LEAVE_SPEED_SCALE)
		Kind.SHOVE_THROUGH:
			_figure.play_loop(Stickman.WALK, SHOVE_SPEED_SCALE)


## Throws the figure along an arc, stopped by the floor.
func _advance_flight(delta: float) -> void:
	_velocity.y -= FLY_GRAVITY * delta
	var moved_position: Vector3 = _figure.position + _velocity * delta
	moved_position.y = maxf(0.0, moved_position.y)
	_figure.position = moved_position


## Turns the figure away, then walks it off with a pleased little hop.
func _advance_walk_off(delta: float) -> void:
	var turn_amount: float = minf(1.0, delta * TURN_RATE)
	_figure.rotation.y = lerpf(_figure.rotation.y, _turn_target_y, turn_amount)
	var moved_position: Vector3 = _figure.position + LEAVE_VELOCITY * delta
	moved_position.y = _hop_height()
	_figure.position = moved_position


## Walks the figure past the player, sideways first, then out behind the camera.
func _advance_shove_through() -> void:
	var progress: float = minf(1.0, _elapsed / SHOVE_DURATION)
	var side_progress: float = minf(1.0, progress * SHOVE_SIDE_HASTE)
	var reached_x: float = lerpf(_start_position.x, SHOVE_SIDE_X, side_progress)
	var reached_z: float = lerpf(_start_position.z, SHOVE_END_Z, progress)
	_figure.position = Vector3(reached_x, 0.0, reached_z)


## Height of the hop of a figure walking off pleased.
func _hop_height() -> float:
	var hop_phase: float = _elapsed * LEAVE_HOP_RATE
	return absf(sin(hop_phase)) * LEAVE_HOP_HEIGHT
