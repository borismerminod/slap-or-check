## The run of correct answers in a row.
##
## - Its own object rather than a counter inside [MoralGauge], which holds the
##   moral and nothing else.
## - Any mistake breaks the run, and so does letting a character through: the
##   bonus rewards sustained attention, not luck.
class_name AnswerStreak
extends RefCounted

## How many correct answers in a row, back to zero after anything else.
var _length: int = 0


## The current run, for a message that names it.
func length() -> int:
	return _length


## Takes one verdict into account.
##
## - A correct answer lengthens the run; a mistake and an ignored character both
##   break it.
func record(verdict: AnswerOutcome.Verdict) -> void:
	var was_correct: bool = verdict == AnswerOutcome.Verdict.CORRECT
	if not was_correct:
		_length = 0
		return
	_length += 1


## True when the run has just completed a multiple of the bonus length.
##
## - [param streak_length_for_bonus] arrives as a parameter, the same way the
##   drain per second arrives at [MoralGauge]: the number is balance, not a
##   property of a counter.
## - False on an empty run, so a reset never pays.
func is_bonus_due(streak_length_for_bonus: int) -> bool:
	if _length == 0:
		return false
	if streak_length_for_bonus <= 0:
		return false
	var remainder: int = _length % streak_length_for_bonus
	return remainder == 0
