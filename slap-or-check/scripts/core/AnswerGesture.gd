## The two answers the player can give to a character.
##
## - Lives on its own so that the input layer and the gameplay layer share one
##   vocabulary without either depending on the other.
## - The rule of the day may invert which gesture is expected for a given
##   sentence; the gesture itself never changes meaning.
class_name AnswerGesture
extends RefCounted

## SLAP answers a cliché, CHECK answers a real piece of information.
enum Kind {
	SLAP,
	CHECK,
}
