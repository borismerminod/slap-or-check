## Where an accessory is pinned on a figure.
##
## - Lives on its own, like the other shared vocabularies, so that a character
##   kind can name a place on the body without depending on the figure itself.
## - Covers every accessory the game design calls for: the cap and the shades go
##   on the head, the tie and the flower on the chest, the phone in the hand.
class_name AccessorySlot
extends RefCounted

## The three places a figure carries something.
enum Kind {
	HEAD,
	CHEST,
	HAND,
}
