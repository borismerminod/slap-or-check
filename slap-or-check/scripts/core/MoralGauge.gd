## Moral gauge of the current level: the player's single resource.
##
## - Starts at a configured value and drains continuously while the level runs.
## - Rewards correct answers, punishes mistakes and ignored characters.
## - Emits [signal depleted] once, as soon as the value reaches zero.
class_name MoralGauge
extends RefCounted

## Emitted when the moral reaches zero, which ends the level as a defeat.
signal depleted

## Emitted on every change, so the HUD can refresh without polling.
signal value_changed(new_value: float)

## Highest reachable moral; also the width of a full gauge.
const MAX_VALUE: float = 100.0

## Current moral, always within [0, MAX_VALUE].
var _value: float = 0.0

## Guards against emitting [signal depleted] more than once per level.
var _is_depleted: bool = false


## Opens the gauge at the moral the level starts with.
##
## - Reports nothing: nobody is listening yet. Whoever owns the gauge announces
##   the opening value once it has connected.
func _init(initial_value: float) -> void:
	_value = clampf(initial_value, 0.0, MAX_VALUE)


## The current moral, for whoever may read it without being able to change it.
func value() -> float:
	return _value


## Applies the continuous drain of time, then reports the new value.
##
## - [param delta_seconds] is the frame time already scaled by the coffee slowdown.
## - Does nothing once the gauge is depleted, so a defeat stays final.
func drain(delta_seconds: float, drain_per_second: float) -> void:
	if _is_depleted:
		return
	var drained_amount: float = drain_per_second * delta_seconds
	_set_value(_value - drained_amount)


## Adds a signed amount of moral, then reports the new value.
##
## - [param amount] is positive for a reward and negative for a penalty. The
##   gauge never learns what an event is worth, only what it changes: that is
##   what keeps the balance of the game out of here.
## - Does nothing once the gauge is depleted, so a defeat stays final.
func apply_change(amount: float) -> void:
	if _is_depleted:
		return
	_set_value(_value + amount)


## Stores a moral within bounds, reports it, and calls the defeat once.
func _set_value(new_value: float) -> void:
	_value = clampf(new_value, 0.0, MAX_VALUE)
	value_changed.emit(_value)
	var has_run_out: bool = _value <= 0.0
	if not has_run_out:
		return
	_is_depleted = true
	depleted.emit()
