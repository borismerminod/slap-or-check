## The rule of the day: which gesture each nature of sentence deserves.
##
## - Makes the judgement verifiable rather than subjective. The player is told
##   the rule before the level starts, so a mistake feels fair.
## - [member is_inverted] is the whole of the "inverted mode" brick of the game
##   design: nothing else in the code has to know that the rule can flip.
class_name DailyRule
extends Resource

## Sentence shown on the rule card. In French, because it is content.
@export var statement: String = ""

## When true, clichés deserve a check and real information deserves a slap.
@export var is_inverted: bool = false


## Returns the gesture expected for a sentence of this nature.
func expected_gesture_for(kind: PhraseKind.Kind) -> AnswerGesture.Kind:
	var is_a_cliche: bool = kind == PhraseKind.Kind.CLICHE
	var deserves_a_slap: bool = is_a_cliche
	if is_inverted:
		deserves_a_slap = not is_a_cliche
	if deserves_a_slap:
		return AnswerGesture.Kind.SLAP
	return AnswerGesture.Kind.CHECK
