## One character, from the moment they leave the queue to the moment they are hit.
##
## - Owns the four phases of a single encounter: WALK, the only one that accepts
##   an answer; DASH, which closes the last of the gap so the blow lands within
##   arm's reach; REACTING, while the two animations play out; and STAGGERING,
##   when a tough character shrugs the blow off and backs away for another round.
## - Reports three distinct moments, and the feel of the game depends on not
##   confusing them:
##     1. [signal answer_judged] fires the instant the player answers, so the
##        feedback is immediate and the game stays nervous;
##     2. [signal player_reaction_requested] fires at the end of the dash, so the
##        player never swings at thin air;
##     3. [signal resolved] fires on impact, when the figure is handed over to
##        whoever walks it off stage.
## - Advanced by its owner through [method advance]. It holds no node of its own
##   and never appears in the scene tree.
## - Knows nothing of the rule: it is given the expected gesture as a plain value,
##   and only compares.
## - Knows nothing of the bricks either. That a character absorbs a hit is read
##   from a number carried by the character, not from what kind they are.
class_name Encounter
extends RefCounted

## Emitted as soon as the answer is known, right or wrong, given or missed.
signal answer_judged(outcome: AnswerOutcome)

## Emitted when the player should be seen performing the gesture.
signal player_reaction_requested(gesture: AnswerGesture.Kind)

## Emitted once, when the encounter is over and the figure can be walked off.
signal resolved(outcome: AnswerOutcome)

## Emitted when a character who absorbed the blow sets off again, so that their
## sentence can be put back on screen.
signal returned_for_another_round

## Seconds the character takes to close the remaining gap once answered.
const DASH_DURATION: float = 0.14

## Seconds from the start of the player's swing to the blow landing.
const SLAP_IMPACT_DELAY: float = 0.25

## Seconds from the start of the swing to the character raising their own hand:
## none, because the two hands go up together to meet.
const CHECK_REACTION_DELAY: float = 0.0

## Seconds from the raised hands to the character turning to leave. A check is
## given time to read, while a slap ends the encounter the moment it lands.
const CHECK_RESOLVE_DELAY: float = 0.45

## Playback speed of the walk cycle at the normal pace. The clip is 0.74 s long,
## which is exactly one cycle of the mockup at its speed of 8.5.
const WALK_SPEED_SCALE: float = 1.0

## Playback speed of the walk cycle during the dash: the mockup's speed of 16.
const DASH_SPEED_SCALE: float = 1.88

## Seconds a character who absorbed the blow takes to back away.
const STAGGER_DURATION: float = 0.35

## Metres they back away by before setting off again.
const STAGGER_RETREAT: float = 2.4

## Share of the first walk a return trip takes. They come back quicker than they
## came, which is what makes a tough character cost time as well as answers.
const RETURN_DURATION_FACTOR: float = 0.55

## Shortest walk the encounter will accept, so a misconfigured pace divides by a
## small number rather than by zero.
const MINIMUM_WALK_DURATION: float = 0.01

## The phases of an encounter. A closed set: the bricks of the game design add
## characters, never phases.
enum Phase {
	WALK,
	DASH,
	REACTING,
	STAGGERING,
}

## What this character has to say, and what colour they are.
var _brief: CharacterBrief

## The figure walking up the corridor. Placed by the spawner, moved from here.
var _figure: Stickman

## The gesture the rule of the day expects, handed over as a plain value.
var _expected_gesture: AnswerGesture.Kind

## Depth at which the character stops, within arm's reach of the player.
var _answer_z: float

## Walking line of the corridor, read once from the figure the spawner placed.
var _lane_x: float

## Which phase the encounter is in.
var _phase: Phase = Phase.WALK

## Seconds spent in the current phase.
var _elapsed: float = 0.0

## Depth the current walk started from, and how long it is meant to take.
var _walk_from_z: float = 0.0

## See [member _walk_from_z].
var _walk_duration: float = 1.0

## Depth the dash started from.
var _dash_from_z: float = 0.0

## Depth the retreat started from.
var _stagger_from_z: float = 0.0

## The walk the character first set off on. Every return is measured from it, and
## not from the last and shorter one, so two absorbed hits do not compound into a
## walk nobody can read.
var _first_walk_duration: float = 1.0

## The verdict, known from the moment the player answers.
var _outcome: AnswerOutcome = null

## Seconds into REACTING at which the character plays its own reaction.
var _reaction_delay: float = 0.0

## Seconds into REACTING at which the encounter ends.
var _resolve_delay: float = 0.0

## Guards against the character playing its reaction twice.
var _has_reacted: bool = false

## Guards against emitting [signal resolved] more than once.
var _is_resolved: bool = false


## Takes the character, their figure, and what the rule expects of them.
func _init(
	brief: CharacterBrief,
	figure: Stickman,
	expected_gesture: AnswerGesture.Kind,
	answer_z: float
) -> void:
	_brief = brief
	_figure = figure
	_expected_gesture = expected_gesture
	_answer_z = answer_z
	_lane_x = figure.position.x


## The figure of this encounter, for whoever walks it off stage afterwards.
func figure() -> Stickman:
	return _figure


## The character of this encounter, for whoever shows what they have to say.
func brief() -> CharacterBrief:
	return _brief


## Starts the walk toward the player, at the pace the level asked for.
##
## - Called once by the level, when the character appears. A character who
##   absorbs a hit sets off again on their own, through the retreat.
func start_walk(from_z: float, duration_seconds: float) -> void:
	_first_walk_duration = maxf(duration_seconds, MINIMUM_WALK_DURATION)
	_walk_from(from_z, _first_walk_duration)


## True only while the character is walking and still here.
##
## - An answer thrown at a character already flying away is dropped, never
##   queued for the next one.
## - The resolved check matters on the frame a character arrives: the walk is
##   over but the phase has not changed, and the answer is already too late.
func can_accept_answer() -> bool:
	if _is_resolved:
		return false
	return _phase == Phase.WALK


## Takes the answer the player just gave, if it is still welcome.
##
## - Judges it straight away, so the feedback does not wait for the animation.
## - Then dashes: the gesture itself only starts once the character is in range.
func submit_answer(gesture: AnswerGesture.Kind) -> void:
	if not can_accept_answer():
		return
	_outcome = _judge(gesture)
	answer_judged.emit(_outcome)
	_start_dash()


## Judges the answer, telling a decisive hit from one that will be absorbed.
##
## - Reads how much the character can still take, and spends one of it. What kind
##   of character they are never comes into it: a boss with three lives and a
##   tough recruiter with one go down the same code.
func _judge(gesture: AnswerGesture.Kind) -> AnswerOutcome:
	var is_the_expected_gesture: bool = gesture == _expected_gesture
	var is_absorbed: bool = is_the_expected_gesture and _brief.remaining_resilience > 0
	if not is_absorbed:
		return AnswerOutcome.from_answer(_brief, gesture, _expected_gesture)
	_brief.remaining_resilience -= 1
	return AnswerOutcome.from_absorbed(_brief, gesture, _expected_gesture)


## Advances the encounter by one frame. Progress is reported through the signals.
func advance(delta: float) -> void:
	if _is_resolved:
		return
	_elapsed += delta
	match _phase:
		Phase.WALK:
			_advance_walk()
		Phase.DASH:
			_advance_dash()
		Phase.REACTING:
			_advance_reacting()
		Phase.STAGGERING:
			_advance_staggering()


## Walks the character down the corridor, and gives up when they arrive.
func _advance_walk() -> void:
	var progress: float = minf(1.0, _elapsed / _walk_duration)
	var reached_z: float = lerpf(_walk_from_z, _answer_z, progress)
	_move_figure_to(reached_z)
	var has_reached_the_player: bool = progress >= 1.0
	if has_reached_the_player:
		_judge_ignored()


## Closes the last of the gap, then asks the player to swing.
func _advance_dash() -> void:
	var progress: float = minf(1.0, _elapsed / DASH_DURATION)
	var eased_progress: float = _ease_in_out(progress)
	var reached_z: float = lerpf(_dash_from_z, _answer_z, eased_progress)
	_move_figure_to(reached_z)
	var is_within_reach: bool = progress >= 1.0
	if is_within_reach:
		_start_reacting()


## Lets the blow land, then either ends the encounter or sends the character back.
func _advance_reacting() -> void:
	var has_landed: bool = _elapsed >= _reaction_delay
	if has_landed and not _has_reacted:
		_has_reacted = true
		_play_character_reaction()
	var is_over: bool = _elapsed >= _resolve_delay
	if not is_over:
		return
	var was_absorbed: bool = _outcome.verdict == AnswerOutcome.Verdict.ABSORBED
	if was_absorbed:
		_start_staggering()
		return
	_resolve()


## Backs the character away from the player, then sends them in again.
func _advance_staggering() -> void:
	var progress: float = minf(1.0, _elapsed / STAGGER_DURATION)
	var eased_progress: float = _ease_in_out(progress)
	var retreat_z: float = _answer_z - STAGGER_RETREAT
	var reached_z: float = lerpf(_stagger_from_z, retreat_z, eased_progress)
	_move_figure_to(reached_z)
	var has_backed_away: bool = progress >= 1.0
	if has_backed_away:
		_return_for_another_round()


## Starts the retreat of a character who shrugged the blow off.
func _start_staggering() -> void:
	_phase = Phase.STAGGERING
	_elapsed = 0.0
	_stagger_from_z = _figure.position.z


## Starts the dash from wherever the character had got to.
func _start_dash() -> void:
	_phase = Phase.DASH
	_elapsed = 0.0
	_dash_from_z = _figure.position.z
	_figure.play_loop(Stickman.WALK, DASH_SPEED_SCALE)


## Sends the character in again, quicker than the first time, and asks for their
## sentence to be shown once more.
func _return_for_another_round() -> void:
	var return_duration: float = _first_walk_duration * RETURN_DURATION_FACTOR
	_walk_from(_figure.position.z, return_duration)
	returned_for_another_round.emit()


## Puts the encounter into its walking phase, from wherever the character stands.
##
## - Clears the verdict and the reaction of the previous round, so a character
##   coming back is judged and reacts afresh.
func _walk_from(from_z: float, duration_seconds: float) -> void:
	_phase = Phase.WALK
	_elapsed = 0.0
	_walk_from_z = from_z
	_walk_duration = maxf(duration_seconds, MINIMUM_WALK_DURATION)
	_has_reacted = false
	_figure.play_loop(Stickman.WALK, WALK_SPEED_SCALE)


## Puts the character within reach and asks the player to perform the gesture.
func _start_reacting() -> void:
	_phase = Phase.REACTING
	_elapsed = 0.0
	_move_figure_to(_answer_z)
	_figure.play_loop(Stickman.IDLE)
	_read_reaction_timing()
	player_reaction_requested.emit(_outcome.given_gesture)


## Reads, from the gesture given, when the blow lands and when it is all over.
func _read_reaction_timing() -> void:
	var was_slapped: bool = _outcome.given_gesture == AnswerGesture.Kind.SLAP
	if was_slapped:
		_reaction_delay = SLAP_IMPACT_DELAY
		_resolve_delay = SLAP_IMPACT_DELAY
		return
	_reaction_delay = CHECK_REACTION_DELAY
	_resolve_delay = CHECK_RESOLVE_DELAY


## Plays what the blow does to the character.
##
## - The knocked away clip only holds the pose and the tumble of the body; the
##   arc through the air belongs to whoever walks the figure off stage.
## - A slap that gets absorbed only rocks them: the clip is the damped wobble,
##   not the tumble, because they are about to walk back in.
func _play_character_reaction() -> void:
	var was_slapped: bool = _outcome.given_gesture == AnswerGesture.Kind.SLAP
	if not was_slapped:
		_figure.play_reaction(Stickman.CHECK)
		return
	var was_absorbed: bool = _outcome.verdict == AnswerOutcome.Verdict.ABSORBED
	if was_absorbed:
		_figure.play_reaction(Stickman.STAGGER)
		return
	_figure.play_reaction(Stickman.KNOCKED_AWAY)


## Records that the character got through unanswered, and ends the encounter.
##
## - Judged and resolved at the same instant: there is no gesture to play out.
func _judge_ignored() -> void:
	_outcome = AnswerOutcome.from_ignored(_brief, _expected_gesture)
	answer_judged.emit(_outcome)
	_resolve()


## Announces the end of the encounter, once.
func _resolve() -> void:
	if _is_resolved:
		return
	_is_resolved = true
	resolved.emit(_outcome)


## Keeps the figure on the walking line at the given depth.
func _move_figure_to(depth: float) -> void:
	_figure.position = Vector3(_lane_x, 0.0, depth)


## Eases in and out, so the dash starts and lands softly.
static func _ease_in_out(progress: float) -> float:
	var is_first_half: bool = progress < 0.5
	if is_first_half:
		return 2.0 * progress * progress
	var remaining: float = -2.0 * progress + 2.0
	return 1.0 - remaining * remaining / 2.0
