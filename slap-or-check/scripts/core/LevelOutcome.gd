## How a level ended.
##
## - Lives on its own, like [AnswerGesture] and [PhraseKind], so that the layer
##   deciding the end of a level and the layer showing it share one word without
##   depending on each other.
class_name LevelOutcome
extends RefCounted

## VICTORY is the whole queue dealt with, DEFEAT is the moral run out.
enum Kind {
	VICTORY,
	DEFEAT,
}
