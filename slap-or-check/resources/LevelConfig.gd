## Everything that makes one level different from another.
##
## - The difficulty of a level lives here and nowhere else, and it is exactly the
##   three levers of the game design: how many characters, how fast they walk, and
##   which bricks are in play.
## - A brick's own behaviour is not here: it belongs to the brick, shared by every
##   level that uses it. Only its presence and its count are a level's business.
## - Everything else a level needs it only designates: the sentences it draws
##   from, the prices of the moral. Those are shared, so that tuning the game is
##   editing one file and not eleven.
class_name LevelConfig
extends Resource

## Name of this level in the level list. In French, because it is content.
@export var display_name: String = ""

## How many characters the queue holds.
@export_range(1, 40, 1) var character_count: int = 10

## How fast the characters of this level walk, which is how long the player has
## to read. The single reaction-time lever of the game design.
@export var walk_pace: WalkPace = null

## Which special characters this level holds.
##
## - One entry per character to place, so the same brick listed twice puts two of
##   them in the queue.
## - The third and last difficulty lever of the game design.
@export var bricks: Array[CharacterKind] = []

## What an ordinary character of this level is.
##
## - A real object rather than a null, so that nothing downstream has to ask
##   whether a character carries a brick.
@export var base_character_kind: CharacterKind = null

## Where the sentences of this level are drawn from.
@export var phrase_pool: PhrasePool = null

## What each event costs or earns in points of moral. Shared by every level, so
## that tuning the game is editing one file.
@export var moral_balance: MoralBalance = null
