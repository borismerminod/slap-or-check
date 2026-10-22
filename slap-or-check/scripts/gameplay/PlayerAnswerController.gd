## Turns an answer given by the player into the player's visible reaction.
##
## - Listens to the answer input and plays the matching clip on the player.
## - Deliberately knows nothing about rules or score: whether the answer was the
##   right one is someone else's job, wired to the same signal later.
class_name PlayerAnswerController
extends Node

## The clip the player figure plays for each answer.
const REACTION_BY_GESTURE: Dictionary = {
	AnswerGesture.Kind.SLAP: Stickman.SLAP,
	AnswerGesture.Kind.CHECK: Stickman.CHECK,
}

## Where answers come from. Injected from the scene.
@export var answer_input: AnswerButtons

## The figure that reacts. Injected from the scene.
@export var player: Stickman


## Listens to the answers the player gives.
func _ready() -> void:
	answer_input.answer_submitted.connect(_on_answer_submitted)


## Plays the reaction that matches the answer just given.
func _on_answer_submitted(gesture: AnswerGesture.Kind) -> void:
	var reaction_clip: StringName = REACTION_BY_GESTURE[gesture]
	player.play_reaction(reaction_clip)
