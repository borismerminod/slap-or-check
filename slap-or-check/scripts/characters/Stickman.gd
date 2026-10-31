## A stickman figure. The player and every character in the queue use this scene.
##
## - Exposes its animation clips by name, so callers never reach into the
##   AnimationPlayer themselves.
## - Separates looping states (idle, walk) from one-shot reactions (slap, check,
##   stagger, knocked away): a reaction always falls back to idle when it ends.
## - Walking faster is a playback speed, not another clip.
## - Can be dyed and dressed at birth, which is how a queue of characters avoids
##   looking like one person repeated, and how a brick becomes recognisable at a
##   glance.
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

## Everything the animations own. The root node above it is left to gameplay, so
## a walk cycle and a path down the corridor never fight over the same transform.
@export var body: Node3D

## Material shared by every mesh of the body. Dyeing duplicates it rather than
## writing to it, so one character's colour never leaks into the others.
@export var body_material: StandardMaterial3D

## Point a speech bubble is pinned above. On the root rather than under [member
## body], so the bounce of the walk cycle does not shake the bubble.
@export var bubble_anchor: Node3D

## Where a hat or a pair of shades goes. Under [member body], unlike the bubble:
## an accessory is part of the figure and follows its animation.
@export var head_anchor: Node3D

## Where a tie or a flower goes.
@export var chest_anchor: Node3D

## Where something held goes, such as the Influencer's phone.
@export var hand_anchor: Node3D

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


## Dyes every mesh of the body, leaving the eyes alone.
##
## - Overrides the material of the meshes that share [member body_material], and
##   recognises them by that very material: adding a hat or a tie later cannot
##   be dyed by accident, and cannot be missed either if it is meant to be.
func set_body_color(color: Color) -> void:
	var dyed_material := body_material.duplicate() as StandardMaterial3D
	dyed_material.albedo_color = color
	var meshes: Array[Node] = body.find_children("*", "MeshInstance3D")
	for mesh in meshes:
		var mesh_instance := mesh as MeshInstance3D
		var wears_the_body_material: bool = mesh_instance.material_override == body_material
		if not wears_the_body_material:
			continue
		mesh_instance.material_override = dyed_material


## Scales the whole figure, for a character who should look imposing.
##
## - The figure is built upwards from its feet, so scaling the root keeps them on
##   the floor. The bubble anchor rises with it, which is what we want: a taller
##   character speaks higher.
func set_figure_scale(factor: float) -> void:
	scale = Vector3.ONE * factor


## Pins an accessory on the figure, at the given slot.
##
## - Does nothing without a scene, which is the case for an ordinary character.
##   That is why no caller has to ask whether this one has an accessory.
func attach_accessory(accessory_scene: PackedScene, slot: AccessorySlot.Kind) -> void:
	if accessory_scene == null:
		return
	var anchor: Node3D = _anchor_for(slot)
	var accessory: Node3D = accessory_scene.instantiate()
	anchor.add_child(accessory)


## Returns the anchor of a slot.
##
## - The match is on a closed set of three places on a body, which will not grow
##   brick by brick the way the characters do.
func _anchor_for(slot: AccessorySlot.Kind) -> Node3D:
	match slot:
		AccessorySlot.Kind.HEAD:
			return head_anchor
		AccessorySlot.Kind.CHEST:
			return chest_anchor
		AccessorySlot.Kind.HAND:
			return hand_anchor
	return chest_anchor


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
