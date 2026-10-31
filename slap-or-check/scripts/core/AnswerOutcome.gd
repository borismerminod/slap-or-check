## The verdict of one encounter, built the instant the player answers, or fails to.
##
## - States what was expected, what was given, and whether the two match.
## - Carries no score on purpose: how much a mistake costs belongs to the moral
##   gauge, which reads this and decides. Keeping the two apart is what lets the
##   balance values move without touching the loop.
class_name AnswerOutcome
extends RefCounted

## CORRECT and WRONG follow a gesture, IGNORED means the character walked
## through, and ABSORBED is a correct answer a tough character shrugged off.
enum Verdict {
	CORRECT,
	WRONG,
	IGNORED,
	ABSORBED,
}

## Which of the three cases this outcome is.
var verdict: Verdict = Verdict.IGNORED

## The character this verdict is about, for the error recap of the end screen.
var brief: CharacterBrief = null

## The gesture the rule of the day expected for this sentence.
var expected_gesture: AnswerGesture.Kind = AnswerGesture.Kind.SLAP

## The gesture the player performed. Meaningless when the verdict is IGNORED.
var given_gesture: AnswerGesture.Kind = AnswerGesture.Kind.SLAP


## Builds the verdict of an answer the player gave in time.
static func from_answer(
	character: CharacterBrief,
	given: AnswerGesture.Kind,
	expected: AnswerGesture.Kind
) -> AnswerOutcome:
	var outcome := AnswerOutcome.new()
	outcome.brief = character
	outcome.given_gesture = given
	outcome.expected_gesture = expected
	var is_the_expected_gesture: bool = given == expected
	if is_the_expected_gesture:
		outcome.verdict = Verdict.CORRECT
	else:
		outcome.verdict = Verdict.WRONG
	return outcome


## Builds the verdict of a correct answer the character absorbed instead of
## going down.
##
## - Right gesture, so it is no mistake; but the encounter is not over, so it is
##   no victory either. It pays little and it does not feed the run of correct
##   answers.
static func from_absorbed(
	character: CharacterBrief,
	given: AnswerGesture.Kind,
	expected: AnswerGesture.Kind
) -> AnswerOutcome:
	var outcome := AnswerOutcome.new()
	outcome.brief = character
	outcome.given_gesture = given
	outcome.expected_gesture = expected
	outcome.verdict = Verdict.ABSORBED
	return outcome


## Builds the verdict of a character who reached the player unanswered.
static func from_ignored(character: CharacterBrief, expected: AnswerGesture.Kind) -> AnswerOutcome:
	var outcome := AnswerOutcome.new()
	outcome.brief = character
	outcome.expected_gesture = expected
	outcome.verdict = Verdict.IGNORED
	return outcome
