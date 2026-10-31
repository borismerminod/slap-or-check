## Turns a character brief into a figure standing at the far end of the corridor.
##
## - Instantiates the shared stickman scene, dyes its body, gives it the stature
##   and the accessory of its kind, and turns it to face the player.
## - Holds the geometry of the corridor: where a character appears, where they
##   stop, and which line they walk along. These are properties of the set, not
##   of the level, which is why they are not in [LevelConfig].
class_name CharacterSpawner
extends Node

## Scene instantiated for every character. The player figure uses the same one.
@export var character_scene: PackedScene

## Node the figures are added under, so the level keeps a readable tree.
@export var characters_parent: Node3D

## Depth a character appears at, at the far end of the corridor.
@export var spawn_z: float = -12.0

## Depth a character stops at, within arm's reach of the player.
@export var answer_z: float = 1.75

## Horizontal position of the line characters walk along.
@export var lane_x: float = 0.11


## Creates the figure of a brief, placed at the far end and facing the player.
##
## - The figure is added to the tree before being dyed, because dyeing reads the
##   meshes the scene brings with it.
func spawn(brief: CharacterBrief) -> Stickman:
	var figure := character_scene.instantiate() as Stickman
	characters_parent.add_child(figure)
	figure.position = Vector3(lane_x, 0.0, spawn_z)
	figure.rotation.y = PI
	figure.set_body_color(brief.body_color)
	_dress_as_kind(figure, brief.character_kind)
	return figure


## Gives the figure the look of its kind: its stature and its accessory.
##
## - Asks nothing about what kind it is. An ordinary character carries a scale of
##   one and no accessory, so the same two calls serve everybody.
func _dress_as_kind(figure: Stickman, kind: CharacterKind) -> void:
	figure.set_figure_scale(kind.figure_scale)
	figure.attach_accessory(kind.accessory_scene, kind.accessory_slot)
