## The rule of the game: which gesture each nature of sentence deserves.
##
## - Fixed, and the same in every level: a cliché deserves a slap, a real piece
##   of information deserves a check.
## - Was a resource for a while, so that a level could invert it. The inverted
##   mode has been dropped, and with it the only reason for the rule to vary, so
##   the rule is a constant of the game again.
## - A table rather than a chain of conditions, like the one [PlayerAnswerController]
##   keeps: adding a third nature of sentence would be an entry, not a branch.
class_name AnswerRule
extends RefCounted

## The gesture each nature of sentence deserves.
const EXPECTED_GESTURE_BY_PHRASE_KIND: Dictionary = {
	PhraseKind.Kind.CLICHE: AnswerGesture.Kind.SLAP,
	PhraseKind.Kind.REAL_INFORMATION: AnswerGesture.Kind.CHECK,
}


## Returns the gesture a sentence of this nature deserves.
static func expected_gesture_for(kind: PhraseKind.Kind) -> AnswerGesture.Kind:
	return EXPECTED_GESTURE_BY_PHRASE_KIND[kind]
