## Turns what the level accepted into the player's visible reaction.
##
## - Listens to the level rather than to the controls: an answer only becomes a
##   gesture once a character is within arm's reach, so the player never swings
##   at thin air.
## - Deliberately knows nothing of rules or score. Whether the answer was the
##   right one is settled elsewhere; here it only decides which clip to play.
## - Owns the mapping from an answer to a clip, which is why the level never has
##   to name an animation.
class_name PlayerAnswerController
extends Node

## The clip the player figure plays for each answer.
const REACTION_BY_GESTURE: Dictionary = {
	AnswerGesture.Kind.SLAP: Stickman.SLAP,
	AnswerGesture.Kind.CHECK: Stickman.CHECK,
}

## The level that accepts answers and reports shoves. Injected from the scene.
@export var level_director: LevelDirector

## The figure that reacts. Injected from the scene.
@export var player: Stickman


## Listens to the two things that happen to the player.
func _ready() -> void:
	level_director.answer_accepted.connect(_on_answer_accepted)
	level_director.player_shoved.connect(_on_player_shoved)


## Plays the gesture that matches the answer the level accepted.
func _on_answer_accepted(gesture: AnswerGesture.Kind) -> void:
	var reaction_clip: StringName = REACTION_BY_GESTURE[gesture]
	player.play_reaction(reaction_clip)


## Rocks the player when a character they ignored barges past.
func _on_player_shoved() -> void:
	player.play_reaction(Stickman.STAGGER)
