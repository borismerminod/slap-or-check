## The short message telling the player what their last answer was worth.
##
## - It is the only feedback of this step. The moral gauge and the HUD come next;
##   without this banner a mistake would leave no trace at all on screen.
## - Holds its own wording, in French, because a message to the player is
##   content. It reads a verdict and says nothing about how it was reached.
class_name FeedbackBanner
extends PanelContainer

## Said of a slap the rule of the day called for.
const CORRECT_SLAP_MESSAGE: String = "Claque méritée"

## Said of a check the rule of the day called for.
const CORRECT_CHECK_MESSAGE: String = "Check mérité"

## Said when a check was called for and a slap was given.
const MISSED_CHECK_MESSAGE: String = "Raté : il fallait checker"

## Said when a slap was called for and a check was given.
const MISSED_SLAP_MESSAGE: String = "Raté : il fallait claquer"

## Said of a character who got past without an answer.
const IGNORED_MESSAGE: String = "Il t'a bousculé et il est passé"

## Colour of a message that congratulates.
const CORRECT_COLOR: Color = Color(0.055, 0.384, 0.314)

## Colour of a message that reports a mistake, the red of the slap button.
const MISTAKE_COLOR: Color = Color(0.702, 0.188, 0.122)

## Label the message is written into. Injected from the scene.
@export var message_label: Label

## Counts down how long the message stays up. Injected from the scene.
@export var hide_timer: Timer


## Starts hidden and takes itself down when the timer runs out.
func _ready() -> void:
	hide()
	hide_timer.timeout.connect(hide)


## Shows what the player's last answer was worth.
func show_outcome(outcome: AnswerOutcome) -> void:
	var message: String = _message_for(outcome)
	var message_color: Color = _color_for(outcome.verdict)
	message_label.text = message
	message_label.modulate = message_color
	show()
	hide_timer.start()


## Picks the wording that fits a verdict.
static func _message_for(outcome: AnswerOutcome) -> String:
	var was_ignored: bool = outcome.verdict == AnswerOutcome.Verdict.IGNORED
	if was_ignored:
		return IGNORED_MESSAGE
	var was_correct: bool = outcome.verdict == AnswerOutcome.Verdict.CORRECT
	if was_correct:
		return _correct_message_for(outcome.given_gesture)
	return _missed_message_for(outcome.expected_gesture)


## Congratulates the gesture that was given.
static func _correct_message_for(given_gesture: AnswerGesture.Kind) -> String:
	var was_a_slap: bool = given_gesture == AnswerGesture.Kind.SLAP
	if was_a_slap:
		return CORRECT_SLAP_MESSAGE
	return CORRECT_CHECK_MESSAGE


## Says which gesture the rule of the day called for, so the mistake is learnt.
static func _missed_message_for(expected_gesture: AnswerGesture.Kind) -> String:
	var a_slap_was_due: bool = expected_gesture == AnswerGesture.Kind.SLAP
	if a_slap_was_due:
		return MISSED_SLAP_MESSAGE
	return MISSED_CHECK_MESSAGE


## Greens a success, reds anything else.
static func _color_for(verdict: AnswerOutcome.Verdict) -> Color:
	var was_correct: bool = verdict == AnswerOutcome.Verdict.CORRECT
	if was_correct:
		return CORRECT_COLOR
	return MISTAKE_COLOR
