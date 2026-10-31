## Keeps the moral of the running level up to date.
##
## - Owns the gauge and the run of correct answers, wears the gauge down every
##   frame, and applies what each answer is worth.
## - Wired to the level by signal in the scene, both ways: it is handed the
##   verdicts and it reports the defeat, and neither script names the other. The
##   moral can be retuned, or taken out, without touching the character loop.
## - Relays the gauge's signals rather than handing the gauge out, so nothing
##   that only needs to read the moral is able to change it.
class_name MoralController
extends Node

## Emitted on every change of the moral, for whoever shows it.
signal moral_changed(new_value: float)

## Emitted when a run of correct answers completes and earns its bonus.
signal streak_bonus_earned(streak_length: int)

## Emitted when the moral crosses the warning threshold, in either direction.
##
## - The threshold is a balance figure, so whoever holds the balance decides.
##   The HUD is told to warn; it never owns the number.
signal low_moral_changed(is_low: bool)

## Emitted once, when the moral runs out and the level is lost.
signal depleted

## The level in play, read through the director. Injected from the scene.
##
## - Taken from the director rather than designated here, so the scene names the
##   level in exactly one place: naming it twice would let a level be played with
##   somebody else's prices.
## - Reading a property of an injected collaborator, which is not the same thing
##   as reaching through the tree for it.
@export var level_director: LevelDirector

## What each event costs or earns, read from the level once.
var _balance: MoralBalance = null

## The moral itself.
var _gauge: MoralGauge = null

## The run of correct answers in a row.
var _streak: AnswerStreak = AnswerStreak.new()

## True while the moral sits under the warning threshold, so the crossing is
## reported once and not on every frame of the drain.
var _is_moral_low: bool = false


## Opens the gauge and announces its value once, so the HUD shows the right
## number before the first character sets off.
func _ready() -> void:
	var config: LevelConfig = level_director.config
	_balance = config.moral_balance
	_gauge = MoralGauge.new(_balance.starting_value)
	_gauge.value_changed.connect(_on_value_changed)
	_gauge.depleted.connect(_on_depleted)
	_report_moral(_gauge.value())


## Wears the moral down with the time that passes.
func _process(delta: float) -> void:
	_gauge.drain(delta, _balance.drain_per_second)


## Applies what the player's last answer was worth.
##
## - Public because the level is wired to it by signal in the scene.
## - The run is recorded after the answer has been paid for, so the fifth correct
##   answer earns both its reward and its bonus.
func apply_outcome(outcome: AnswerOutcome) -> void:
	var change: float = _balance.change_for(outcome.verdict)
	_gauge.apply_change(change)
	_streak.record(outcome.verdict)
	_grant_streak_bonus_if_due()


## Pays the bonus of a completed run, and says how long that run was.
##
## - Reports at the end of the frame rather than straight away. The message about
##   the bonus has to land after the one the answer itself wrote, and deferring is
##   what makes that true whatever order the two are connected in. Relying on the
##   order in the scene file would not hold: the editor rewrites it.
func _grant_streak_bonus_if_due() -> void:
	var is_bonus_due: bool = _streak.is_bonus_due(_balance.streak_length_for_bonus)
	if not is_bonus_due:
		return
	_gauge.apply_change(_balance.streak_bonus)
	streak_bonus_earned.emit.call_deferred(_streak.length())


## Passes every change of the moral on to whoever shows it.
func _on_value_changed(new_value: float) -> void:
	_report_moral(new_value)


## Announces a moral, and the warning along with it when it has just changed.
func _report_moral(new_value: float) -> void:
	moral_changed.emit(new_value)
	_report_low_moral_if_crossed(new_value)


## Announces the warning only on the frame the threshold is crossed.
func _report_low_moral_if_crossed(new_value: float) -> void:
	var is_low: bool = new_value < _balance.low_moral_threshold
	var is_already_reported: bool = is_low == _is_moral_low
	if is_already_reported:
		return
	_is_moral_low = is_low
	low_moral_changed.emit(is_low)


## Freezes the moral where it stands, for good.
##
## - Called when the level ends, on a victory as much as on a defeat. Without it
##   the bar would go on draining under a win, and could even reach zero there.
## - Public because the arbiter of the end of the level calls it.
func stop() -> void:
	set_process(false)


## Freezes the moral and reports the defeat.
func _on_depleted() -> void:
	stop()
	depleted.emit()
