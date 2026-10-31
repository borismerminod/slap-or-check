## Everything known about one character before they walk up to the player.
##
## - Pure data handed out by the queue: the sentence to read, its nature, the
##   colour of the figure, and what kind of character it is.
## - Holds no node, so the same character can be put back in the queue later:
##   that is what the Relou does when he is let through.
## - Carries the one piece of state a character has of their own, how much they
##   can still absorb. It lives here and not on the kind, because the kind is
##   shared: two tough recruiters in one queue each take their own beating.
class_name CharacterBrief
extends RefCounted

## Sentence shown in the speech bubble. In French, because it is content.
var phrase: String = ""

## Whether that sentence is a cliché or a real piece of information.
var phrase_kind: PhraseKind.Kind = PhraseKind.Kind.CLICHE

## Body colour of the figure, so two characters in a row look different.
var body_color: Color = Color.WHITE

## Ordinary character, or one of the bricks. Never null.
var character_kind: CharacterKind = null

## How many correct answers this character still absorbs before going down.
var remaining_resilience: int = 0


## Builds a brief from what makes a character.
func _init(
	sentence: String,
	sentence_nature: PhraseKind.Kind,
	color: Color,
	kind: CharacterKind
) -> void:
	phrase = sentence
	phrase_kind = sentence_nature
	body_color = color
	character_kind = kind
	remaining_resilience = kind.resilience


## Builds another character with the same sentence, colour and kind.
##
## - For a brick that puts itself back in the queue. The copy starts fresh, so a
##   Relou who had already taken a beating comes back whole.
func copy() -> CharacterBrief:
	return CharacterBrief.new(phrase, phrase_kind, body_color, character_kind)
