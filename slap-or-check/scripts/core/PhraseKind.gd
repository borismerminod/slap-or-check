## The two natures a sentence shown to the player can have.
##
## - Lives on its own, like [AnswerGesture], so that the content layer and the
##   rule layer share one vocabulary without depending on each other.
## - Says nothing about the gesture a sentence deserves: that mapping belongs to
##   the rule of the day, which is allowed to invert it.
class_name PhraseKind
extends RefCounted

## CLICHE is recruitment doublespeak, REAL_INFORMATION is an actual fact.
enum Kind {
	CLICHE,
	REAL_INFORMATION,
}
