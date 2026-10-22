## A stickman figure. The player and every character in the queue use this scene.
##
## - Exposes its animation clips by name, so callers never reach into the
##   AnimationPlayer themselves.
## - Separates looping states (idle, walk) from one-shot reactions (slap, check,
##   stagger, knocked away): a reaction always falls back to idle when it ends.
## - Walking faster is a playback speed, not another clip.
class_name Stickman
extends Node3D

## Emitted once a one-shot reaction has finished and the figure is idle again.
signal reaction_finished

## Looping clip played while the figure waits in place.
const IDLE := &"idle"

## Looping walk cycle. Its tempo comes from the caller, not from the clip.
const WALK := &"walk"

## One-shot reaction: the player's arm sweeps across.
const SLAP := &"slap"

## One-shot reaction: a raised hand meeting another.
const CHECK := &"check"

## One-shot reaction: the pose of a character sent flying. The trajectory of the
## root node belongs to whoever plays this clip.
const KNOCKED_AWAY := &"knocked_away"

## One-shot reaction: the damped wobble of a character taking a hit.
const STAGGER := &"stagger"

## Drives every clip of this figure. Injected from the scene.
@export var animation_player: AnimationPlayer

## True while a one-shot reaction is playing, which blocks a second one.
var _is_playing_reaction: bool = false


## Connects to the end of reactions and starts the figure in its idle loop.
func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	play_loop(IDLE)


## Starts a looping clip, such as idle or walk.
##
## - [param speed_scale] multiplies the clip's own tempo: the walk cycle is
##   authored once, then sped up for a hurried character.
## - Cancels any reaction in progress, so walking always wins over a pose.
func play_loop(clip_name: StringName, speed_scale: float = 1.0) -> void:
	_is_playing_reaction = false
	animation_player.speed_scale = speed_scale
	animation_player.play(clip_name)


## Plays a one-shot reaction, after which the figure returns to idle.
##
## - Does nothing while another reaction is still playing, so two taps in a row
##   cannot interrupt a slap halfway through.
## - Emits [signal reaction_finished] when the clip ends.
func play_reaction(clip_name: StringName) -> void:
	if _is_playing_reaction:
		return
	_is_playing_reaction = true
	animation_player.speed_scale = 1.0
	animation_player.play(clip_name)


## Returns to idle when a reaction clip ends, and reports it.
##
## - Looping clips never reach this point, so only reactions are handled here.
func _on_animation_finished(_finished_clip: StringName) -> void:
	if not _is_playing_reaction:
		return
	play_loop(IDLE)
	reaction_finished.emit()
