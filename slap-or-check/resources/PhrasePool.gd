## The sentences a level draws from. Content, so it lives in a .tres.
##
## - Three lists in French: the clichés that deserve a slap, the real pieces of
##   information that deserve a check, and the rare cult sentences.
## - A cult sentence is always a cliché. It is kept in its own list only so that
##   it stays rare: it is planted once per queue instead of being drawn like the
##   others.
## - Adding sentences means editing a .tres, never a script.
class_name PhrasePool
extends Resource

## Shown when a list is empty, so a half-filled .tres is visible on screen
## instead of breaking the loop silently.
const MISSING_PHRASE: String = "(phrase manquante)"

## Recruitment doublespeak. Each of these deserves a slap under the standard rule.
@export var cliche_phrases: PackedStringArray = []

## Actual facts: pay, deadlines, hours. These deserve a check.
@export var real_information_phrases: PackedStringArray = []

## Rare comic rewards, always clichés. One per queue at most.
@export var cult_phrases: PackedStringArray = []


## Draws a random sentence of the asked nature.
func draw_phrase(kind: PhraseKind.Kind) -> String:
	var candidates: PackedStringArray = _phrases_of(kind)
	return _draw_from(candidates)


## Draws a random cult sentence.
func draw_cult_phrase() -> String:
	return _draw_from(cult_phrases)


## True when this pool can provide a cult sentence at all.
func has_cult_phrases() -> bool:
	return not cult_phrases.is_empty()


## Returns the list matching a nature of sentence.
##
## - The match is on a closed set of two values, which is why it is allowed to
##   live in a central function: unlike the characters, the natures of a sentence
##   will not grow brick by brick.
func _phrases_of(kind: PhraseKind.Kind) -> PackedStringArray:
	match kind:
		PhraseKind.Kind.CLICHE:
			return cliche_phrases
		PhraseKind.Kind.REAL_INFORMATION:
			return real_information_phrases
	return PackedStringArray()


## Picks one sentence at random, or a visible placeholder if there are none.
func _draw_from(candidates: PackedStringArray) -> String:
	if candidates.is_empty():
		return MISSING_PHRASE
	var drawn_index: int = randi() % candidates.size()
	return candidates[drawn_index]
