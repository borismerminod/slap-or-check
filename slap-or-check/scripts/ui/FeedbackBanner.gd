## The short message telling the player what just happened.
##
## - Three kinds of message, each wired to its own signal in the level scene: the
##   verdict of an answer, the bonus of a run of correct answers, and the defeat.
## - Holds its own wording, in French, because a message to the player is
##   content. It reads a verdict and says nothing about how it was reached.
## - Names no number of points: what an event is worth is the business of the
##   balance, and the moral gauge shows the result.
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

## Said when a run of correct answers completes. Takes the length of the run.
const STREAK_BONUS_MESSAGE: String = "Série de %d : bonus de Moral"

## Said when the moral runs out and the level is lost.
const DEFEAT_MESSAGE: String = "Moral à zéro"

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
	_write_message(message, message_color)
	hide_timer.start()


## Announces the bonus of a completed run, over the message the answer itself
## has just written.
##
## - Always arrives after the verdict of the same answer, because the moral
##   reports the bonus at the end of the frame. Nothing here depends on the
##   order the signals are connected in.
func show_streak_bonus(streak_length: int) -> void:
	var message: String = STREAK_BONUS_MESSAGE % streak_length
	_write_message(message, CORRECT_COLOR)
	hide_timer.start()


## Announces the defeat, and stays up.
##
## - Cancels the countdown rather than restarting it: a message about a level
##   that is over has no reason to fade away.
func show_defeat() -> void:
	_write_message(DEFEAT_MESSAGE, MISTAKE_COLOR)
	hide_timer.stop()


## Puts a message on screen in the given colour.
func _write_message(message: String, message_color: Color) -> void:
	message_label.text = message
	message_label.modulate = message_color
	show()


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
