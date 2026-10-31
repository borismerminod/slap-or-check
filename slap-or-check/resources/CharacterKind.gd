## What kind of character walks up the corridor: an ordinary one, or a brick.
##
## - The ordinary character is an instance of **this very class**, never a null.
##   Having a real object that does nothing removes every "is there a brick here?"
##   check from the rest of the code.
## - A brick either fills in different values, or subclasses this and overrides
##   what it needs. Adding one is a new file and a new .tres — never a branch in
##   a function that already exists.
## - Behaviour values live here, shared by every level that uses the brick. Only
##   a brick's presence and its count belong to a level.
class_name CharacterKind
extends Resource

## Name announced above the sentence, so a brick is never a surprise the first
## time. Empty for an ordinary character, who has nothing to announce. In French,
## because it is content.
@export var display_name: String = ""

## How many correct answers this character absorbs before going down.
##
## - Zero for everyone but the tough ones.
## - The boss of the game design is the same figure, larger: « chaque bonne
##   réponse lui retire un point de vie ».
@export_range(0, 10, 1) var resilience: int = 0

## Multiplies the walking pace of the level.
##
## - Above 1 for a character who takes their time, which is a favour to the
##   player; below 1 for one who rushes.
@export_range(0.25, 3.0, 0.05) var walk_duration_factor: float = 1.0

## Scales the figure, for someone who should look imposing.
@export_range(0.5, 2.0, 0.01) var figure_scale: float = 1.0

## Pinned on the figure to make this kind recognisable at a glance. Null for an
## ordinary character.
@export var accessory_scene: PackedScene = null

## Where [member accessory_scene] is pinned.
@export var accessory_slot: AccessorySlot.Kind = AccessorySlot.Kind.HEAD


## Lets this kind change what is still to come, as a consequence of an answer.
##
## - Called for every character and every verdict. An ordinary character changes
##   nothing, which is why this does nothing here.
## - This is the extension point for the bricks whose consequence is visible in
##   the queue rather than in a number: the Relou who puts himself back, the
##   Influencer who brings his followers along.
func react_in_queue(_outcome: AnswerOutcome, _queue: CharacterQueue) -> void:
	pass
