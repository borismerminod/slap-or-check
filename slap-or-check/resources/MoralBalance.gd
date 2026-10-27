## What each event of a level costs or earns, in points of moral.
##
## - Shared by every level: tuning the game means editing one .tres, because a
##   level differs by its walking speed and the length of its queue, not by its
##   prices.
## - Same shape as [DailyRule], which also answers a question about its own data.
## - Penalties are stored positive and named penalty, so filling in the inspector
##   never asks anyone to remember a sign. [method change_for] puts it back.
## - None of these values is tested, and all of them will move.
class_name MoralBalance
extends Resource

## Moral the player opens a level with.
@export_range(0.0, 100.0, 1.0) var starting_value: float = 70.0

## Points lost every second the level runs: the job hunt wears you down.
@export_range(0.0, 5.0, 0.1) var drain_per_second: float = 0.8

## Points earned by the gesture the rule of the day called for.
@export_range(0.0, 50.0, 1.0) var correct_answer_reward: float = 5.0

## Points lost by answering with the other gesture.
@export_range(0.0, 50.0, 1.0) var wrong_answer_penalty: float = 22.0

## Points lost by letting a character walk through unanswered.
@export_range(0.0, 50.0, 1.0) var ignored_character_penalty: float = 14.0

## How many correct answers in a row earn the bonus.
@export_range(2, 20, 1) var streak_length_for_bonus: int = 5

## Points earned every time that run is completed.
@export_range(0.0, 50.0, 1.0) var streak_bonus: float = 8.0


## Returns the signed change of moral a verdict is worth.
##
## - The match is on a closed set of three verdicts, so it will not grow brick by
##   brick the way a match on characters would.
func change_for(verdict: AnswerOutcome.Verdict) -> float:
	match verdict:
		AnswerOutcome.Verdict.CORRECT:
			return correct_answer_reward
		AnswerOutcome.Verdict.WRONG:
			return -wrong_answer_penalty
		AnswerOutcome.Verdict.IGNORED:
			return -ignored_character_penalty
	return 0.0
