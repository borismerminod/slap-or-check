## One pace a character can walk the corridor at.
##
## - Shared by every level that walks at this pace, rather than each level
##   carrying its own number: retuning "fast" corrects every fast level at once,
##   and the three paces cannot drift apart.
## - A duration and not a speed. The time to read is what the player fights, and
##   expressing it in seconds keeps it the same should a décor ever lengthen the
##   corridor.
## - The single reaction-time lever of the game design.
class_name WalkPace
extends Resource

## Name of this pace in the level list. In French, because it is content.
@export var display_name: String = ""

## Seconds a character takes to walk the whole corridor, which is the time the
## player has to read the sentence and answer.
@export_range(1.0, 8.0, 0.1) var duration_seconds: float = 4.2
