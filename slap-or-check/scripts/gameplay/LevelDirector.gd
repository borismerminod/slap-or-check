## Runs the character loop of one level: the single conductor of the scene.
##
## - Pops the queue, spawns the next figure, drives the current encounter and
##   every character still walking off stage.
## - Filters the player's answers. An answer is only passed on while a character
##   is still walking, which is what keeps a late swipe from landing on the next
##   one.
## - Reports what happened without knowing who listens. The feedback banner is
##   wired to it in the level scene; the moral gauge of the next step and the end
##   screen of the one after plug into the same signals, and this script will not
##   have to change for either.
class_name LevelDirector
extends Node

## Emitted the instant an answer is judged, which is when feedback must fire.
signal answer_judged(outcome: AnswerOutcome)

## Emitted when the player should be seen performing the gesture, once the
## character is within arm's reach.
signal answer_accepted(gesture: AnswerGesture.Kind)

## Emitted when a character the player ignored barges into them on the way past.
signal player_shoved

## Emitted once the last character of the queue has been dealt with.
signal queue_emptied

## Emitted when the number of characters still to come changes, so a counter can
## refresh without interrogating the queue every frame. The one walking up is
## counted: the player is still dealing with them.
signal characters_remaining_changed(remaining: int)

## What this level is made of. Injected from the scene.
@export var config: LevelConfig

## Creates the figures and owns the geometry of the corridor. Injected.
@export var spawner: CharacterSpawner

## Shows the sentence of the walking character. Injected from the scene.
@export var speech_bubble: SpeechBubble

## Seconds between one character being dealt with and the next appearing. Short
## enough that the next one sets off while the previous is still in the air.
@export_range(0.0, 2.0, 0.05) var delay_between_characters: float = 0.35

## Rebuilds the queue when it runs out, so the loop can be played for as long as
## it takes to judge it. The end of the level takes this over in the step that
## adds the end screen.
@export var restarts_when_empty: bool = true

## The characters still to come.
var _queue: CharacterQueue = null

## The character being dealt with, or null between two of them.
var _current_encounter: Encounter = null

## Every character still walking off stage, each on its own clock.
var _active_exits: Array[CharacterExit] = []

## Counts down to the next character while nobody is walking up.
var _seconds_until_next_spawn: float = 0.0

## False once the queue has run out and is not being rebuilt.
var _is_queue_running: bool = false

## True once the level has been stopped, which freezes it where it stands.
var _is_stopped: bool = false


## Fills the first queue and starts the wait for the first character.
func _ready() -> void:
	_restart_queue()
	_seconds_until_next_spawn = delay_between_characters


## Drives the leaving characters, then either the current encounter or the wait
## for the next one.
##
## - The characters on their way out keep moving even once the level is stopped,
##   so a figure caught in mid-air finishes its arc instead of hanging there.
func _process(delta: float) -> void:
	_advance_exits(delta)
	if _is_stopped:
		return
	if _current_encounter != null:
		_current_encounter.advance(delta)
		return
	_count_down_to_next_spawn(delta)


## Ends the level where it stands.
##
## - Public because the defeat is wired to it by signal in the scene: the level
##   never learns what stopped it, which is how the moral gauge can be retuned or
##   removed without touching this script.
## - Stops spawning and takes the bubble away. The character walking up stays
##   frozen where they are, for the end screen to be drawn over.
func stop() -> void:
	_is_stopped = true
	_is_queue_running = false
	speech_bubble.clear()
	_freeze_current_character()


## Puts the character walking up back to a standstill.
##
## - Without this they keep walking on the spot: the animation player runs on its
##   own clock, and stopping the level only stops moving them forward.
func _freeze_current_character() -> void:
	if _current_encounter == null:
		return
	var figure: Stickman = _current_encounter.figure()
	figure.play_loop(Stickman.IDLE)


## Passes an answer on to the character walking up, if there is one.
##
## - Public because the controls are wired to it in the level scene, by signal:
##   the buttons and the swipe area are connected there, and a third control
##   needs one more connection and no change here.
## - The encounter itself decides whether the answer is still welcome, so a
##   swipe during an animation is simply dropped.
## - A stopped level takes nothing: the character frozen in the corridor is a
##   picture, not someone still waiting for an answer.
func submit_answer(gesture: AnswerGesture.Kind) -> void:
	if _is_stopped:
		return
	if _current_encounter == null:
		return
	_current_encounter.submit_answer(gesture)


## Reports the verdict and clears the bubble, the moment the answer is known.
func _on_answer_judged(outcome: AnswerOutcome) -> void:
	speech_bubble.clear()
	answer_judged.emit(outcome)
	var was_ignored: bool = outcome.verdict == AnswerOutcome.Verdict.IGNORED
	if was_ignored:
		player_shoved.emit()


## Asks for the player's gesture to be seen, now that the character is in range.
func _on_player_reaction_requested(gesture: AnswerGesture.Kind) -> void:
	answer_accepted.emit(gesture)


## Hands the figure over to its exit and starts the wait for the next character.
func _on_encounter_resolved(outcome: AnswerOutcome) -> void:
	var figure: Stickman = _current_encounter.figure()
	var exit_kind: CharacterExit.Kind = _exit_kind_for(outcome)
	var exit := CharacterExit.new(figure, exit_kind)
	_active_exits.append(exit)
	_current_encounter = null
	_seconds_until_next_spawn = delay_between_characters


## Moves every leaving character, then drops those that are done.
func _advance_exits(delta: float) -> void:
	for exit in _active_exits:
		exit.advance(delta)
	_drop_finished_exits()


## Frees the figures that have been off stage long enough.
func _drop_finished_exits() -> void:
	var still_leaving: Array[CharacterExit] = []
	for exit in _active_exits:
		if exit.is_finished():
			exit.dismiss()
			continue
		still_leaving.append(exit)
	_active_exits = still_leaving


## Waits out the gap between two characters.
func _count_down_to_next_spawn(delta: float) -> void:
	if not _is_queue_running:
		return
	_seconds_until_next_spawn -= delta
	var is_time_to_spawn: bool = _seconds_until_next_spawn <= 0.0
	if not is_time_to_spawn:
		return
	_start_next_encounter()


## Sends the next character up the corridor, or ends the queue.
func _start_next_encounter() -> void:
	if _queue.is_empty():
		_on_queue_emptied()
		return
	var brief: CharacterBrief = _queue.pop_next()
	var figure: Stickman = spawner.spawn(brief)
	var daily_rule: DailyRule = config.daily_rule
	var expected_gesture: AnswerGesture.Kind = daily_rule.expected_gesture_for(brief.phrase_kind)
	_current_encounter = Encounter.new(brief, figure, expected_gesture, spawner.answer_z)
	_listen_to_current_encounter()
	_current_encounter.start_walk(spawner.spawn_z, config.walk_duration_seconds)
	speech_bubble.show_phrase(brief.phrase, figure.bubble_anchor)
	_report_characters_remaining()


## Listens to the three moments of the encounter just started.
func _listen_to_current_encounter() -> void:
	_current_encounter.answer_judged.connect(_on_answer_judged)
	_current_encounter.player_reaction_requested.connect(_on_player_reaction_requested)
	_current_encounter.resolved.connect(_on_encounter_resolved)


## Reports the end of the queue, and starts over when asked to.
func _on_queue_emptied() -> void:
	queue_emptied.emit()
	if not restarts_when_empty:
		_is_queue_running = false
		return
	_restart_queue()
	_seconds_until_next_spawn = delay_between_characters


## Draws a fresh queue from the configuration of the level.
func _restart_queue() -> void:
	_queue = QueueBuilder.build(config)
	_is_queue_running = true
	_report_characters_remaining()


## Announces how many characters are still to come, the one walking up included.
func _report_characters_remaining() -> void:
	var waiting_count: int = _queue.count()
	var walking_count: int = 0
	if _current_encounter != null:
		walking_count = 1
	var remaining: int = waiting_count + walking_count
	characters_remaining_changed.emit(remaining)


## Chooses how a character leaves, from the gesture they were given.
static func _exit_kind_for(outcome: AnswerOutcome) -> CharacterExit.Kind:
	var was_ignored: bool = outcome.verdict == AnswerOutcome.Verdict.IGNORED
	if was_ignored:
		return CharacterExit.Kind.SHOVE_THROUGH
	var was_slapped: bool = outcome.given_gesture == AnswerGesture.Kind.SLAP
	if was_slapped:
		return CharacterExit.Kind.FLY
	return CharacterExit.Kind.LEAVE
