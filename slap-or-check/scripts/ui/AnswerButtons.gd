## The two answer buttons shown at the bottom of the screen.
##
## - Reports what the player asked for and nothing else: it never touches the
##   characters, the score or the rule of the day.
## - Accepts the same two answers from the keyboard, through the input actions,
##   so the hint under each button stays true.
class_name AnswerButtons
extends Control

## Emitted when the player picks an answer, whether by button or by key.
signal answer_submitted(gesture: AnswerGesture.Kind)

## Input action asking for a slap, declared in the project settings.
const SLAP_ACTION := &"answer_slap"

## Input action asking for a check, declared in the project settings.
const CHECK_ACTION := &"answer_check"

## The button on the left, which asks for a slap. Injected from the scene.
@export var slap_button: Button

## The button on the right, which asks for a check. Injected from the scene.
@export var check_button: Button


## Listens to both buttons.
func _ready() -> void:
	slap_button.pressed.connect(_on_slap_button_pressed)
	check_button.pressed.connect(_on_check_button_pressed)


## Routes the keyboard shortcuts to the same answers as the buttons.
func _unhandled_input(event: InputEvent) -> void:
	var asks_for_slap: bool = event.is_action_pressed(SLAP_ACTION)
	if asks_for_slap:
		_submit_answer(AnswerGesture.Kind.SLAP)
		return
	var asks_for_check: bool = event.is_action_pressed(CHECK_ACTION)
	if asks_for_check:
		_submit_answer(AnswerGesture.Kind.CHECK)


## Reports a slap asked for with the left button.
func _on_slap_button_pressed() -> void:
	_submit_answer(AnswerGesture.Kind.SLAP)


## Reports a check asked for with the right button.
func _on_check_button_pressed() -> void:
	_submit_answer(AnswerGesture.Kind.CHECK)


## Announces the chosen answer and leaves its meaning to whoever listens.
func _submit_answer(gesture: AnswerGesture.Kind) -> void:
	answer_submitted.emit(gesture)
