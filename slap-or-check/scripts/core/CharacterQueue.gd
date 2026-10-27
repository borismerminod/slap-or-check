## The characters still to come in the current level, in order.
##
## - Hands out the next brief and nothing else: it never builds them and never
##   judges them.
## - Exists instead of a plain array because the bricks of the game design change
##   the queue as the consequence of a mistake: the Relou puts himself back a few
##   places down, the Influencer slips two followers in right behind him. That is
##   what [method insert_at] is for.
class_name CharacterQueue
extends RefCounted

## The briefs still waiting, head of the queue first.
var _briefs: Array[CharacterBrief] = []


## Takes the briefs to come, in the order they will walk up.
func _init(initial_briefs: Array[CharacterBrief]) -> void:
	_briefs = initial_briefs.duplicate()


## How many characters are still waiting.
func count() -> int:
	return _briefs.size()


## True once nobody is left to come.
func is_empty() -> bool:
	return _briefs.is_empty()


## Removes and returns the character at the head of the queue.
##
## - Returns null on an empty queue, which callers check with [method is_empty].
func pop_next() -> CharacterBrief:
	if _briefs.is_empty():
		return null
	return _briefs.pop_front()


## Slips a character in at the given rank, clamped to the length of the queue.
##
## - Rank 0 puts them next; a larger rank leaves the player some respite before
##   having to deal with them again.
func insert_at(brief: CharacterBrief, rank: int) -> void:
	var safe_rank: int = clampi(rank, 0, _briefs.size())
	_briefs.insert(safe_rank, brief)
