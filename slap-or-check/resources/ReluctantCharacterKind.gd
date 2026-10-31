## The Relou: let him through and he puts himself back in the queue.
##
## - The point of the bricks in the game design is that a mistake has a
##   consequence you can **see** in the corridor, and not only a figure that
##   drops. Letting him through costs the usual moral, and then costs again.
## - Only reacts to being ignored. Answered, rightly or wrongly, he leaves like
##   anybody else.
## - Overrides one method and adds one value. Nothing else in the game knows he
##   exists.
class_name ReluctantCharacterKind
extends CharacterKind

## How far down the queue he puts himself back.
##
## - Small enough to be a nuisance, large enough that the player deals with
##   somebody else first and feels him come back rather than never leave.
@export_range(0, 10, 1) var return_rank: int = 2


## Puts him back in the queue, with the same sentence, when he was let through.
func react_in_queue(outcome: AnswerOutcome, queue: CharacterQueue) -> void:
	var was_ignored: bool = outcome.verdict == AnswerOutcome.Verdict.IGNORED
	if not was_ignored:
		return
	var returning_brief: CharacterBrief = outcome.brief.copy()
	queue.insert_at(returning_brief, return_rank)
