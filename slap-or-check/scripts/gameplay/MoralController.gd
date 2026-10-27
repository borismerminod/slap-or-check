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

## Emitted once, when the moral runs out and the level is lost.
signal depleted

## The level being played, which designates the balance to apply. Injected from
## the scene. Taken whole rather than as a bare balance, so the prices follow the
## level instead of being wired a second time next to it.
@export var config: LevelConfig

## What each event costs or earns, read from the level once.
var _balance: MoralBalance = null

## The moral itself.
var _gauge: MoralGauge = null

## The run of correct answers in a row.
var _streak: AnswerStreak = AnswerStreak.new()


## Opens the gauge and announces its value once, so the HUD shows the right
## number before the first character sets off.
func _ready() -> void:
	_balance = config.moral_balance
	_gauge = MoralGauge.new(_balance.starting_value)
	_gauge.value_changed.connect(_on_value_changed)
	_gauge.depleted.connect(_on_depleted)
	moral_changed.emit(_gauge.value())


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
	moral_changed.emit(new_value)


## Stops the drain for good and reports the defeat.
func _on_depleted() -> void:
	set_process(false)
	depleted.emit()
