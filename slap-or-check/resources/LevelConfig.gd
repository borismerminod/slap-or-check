## Everything that makes one level different from another.
##
## - The difficulty of a level lives here and nowhere else. Walking duration is
##   the single reaction-time lever of the game design: the time to read is a
##   distance, and the distance is fixed by the corridor.
## - These balance values are exposed on purpose. None of them is tested yet and
##   all of them will move.
class_name LevelConfig
extends Resource

## Name shown on the rule card. In French, because it is content.
@export var display_name: String = ""

## How many characters the queue holds.
@export_range(1, 40, 1) var character_count: int = 10

## Seconds a character takes to walk the whole corridor, which is the time the
## player has to read the sentence and answer.
@export_range(1.0, 8.0, 0.1) var walk_duration_seconds: float = 4.2

## Where the sentences of this level are drawn from.
@export var phrase_pool: PhrasePool = null

## Which gesture each nature of sentence deserves in this level.
@export var daily_rule: DailyRule = null
