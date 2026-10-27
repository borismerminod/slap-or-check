## Everything known about one character before they walk up to the player.
##
## - Pure data handed out by the queue: the sentence to read, its nature, and the
##   colour of the figure.
## - Holds no node and no behaviour, so the same brief can be put back in the
##   queue later: that is what the Relou brick does when he is let through.
class_name CharacterBrief
extends RefCounted

## Sentence shown in the speech bubble. In French, because it is content.
var phrase: String = ""

## Whether that sentence is a cliché or a real piece of information.
var phrase_kind: PhraseKind.Kind = PhraseKind.Kind.CLICHE

## Body colour of the figure, so two characters in a row look different.
var body_color: Color = Color.WHITE


## Builds a brief from the three things that make a character.
func _init(sentence: String, kind: PhraseKind.Kind, color: Color) -> void:
	phrase = sentence
	phrase_kind = kind
	body_color = color
