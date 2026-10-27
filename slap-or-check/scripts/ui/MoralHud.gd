## The moral of the running level, and how many characters are left to come.
##
## - Reads two signals and writes three widgets. It never reaches for the gauge,
##   the queue or the level: it is told, and it shows.
## - Turns the bar red under a threshold, which is the only warning the player
##   gets that the level is nearly lost.
class_name MoralHud
extends Control

## Written before the number of characters still to come. Content, in French.
const REMAINING_PREFIX: String = "Reste "

## Moral below which the bar warns that the level is nearly lost.
@export_range(0.0, 100.0, 1.0) var low_moral_threshold: float = 30.0

## The bar itself. Injected from the scene.
@export var moral_bar: ProgressBar

## Fill of the bar while the moral is comfortable. Injected from the scene.
@export var normal_fill: StyleBoxFlat

## Fill of the bar once the moral is low. Injected from the scene.
@export var low_fill: StyleBoxFlat

## Where the moral is written as a number. Injected from the scene.
@export var moral_label: Label

## Where the rest of the queue is written. Injected from the scene.
@export var remaining_label: Label

## True while the bar is showing its warning colour, so the style is swapped on
## the frame the threshold is crossed and not on every frame of the drain.
var _is_showing_warning: bool = false


## Takes the span of the bar from the gauge itself, so the two cannot drift apart.
func _ready() -> void:
	moral_bar.max_value = MoralGauge.MAX_VALUE


## Shows a new moral: the bar, the number beside it, and the warning colour.
##
## - The bar follows the exact value, so the drain reads as a smooth slide, while
##   the number is rounded: a figure flickering between 69 and 70 is unreadable.
func show_moral(new_value: float) -> void:
	var rounded_moral: int = int(round(new_value))
	var displayed_moral: int = clampi(rounded_moral, 0, int(MoralGauge.MAX_VALUE))
	moral_bar.value = new_value
	moral_label.text = str(displayed_moral)
	_show_warning_if_low(new_value)


## Shows how many characters are still to come, the one walking up included.
func show_remaining(remaining: int) -> void:
	remaining_label.text = REMAINING_PREFIX + str(remaining)


## Reddens the bar once the moral is low, and puts it back if it recovers.
func _show_warning_if_low(new_value: float) -> void:
	var is_low: bool = new_value < low_moral_threshold
	var is_already_right: bool = is_low == _is_showing_warning
	if is_already_right:
		return
	_is_showing_warning = is_low
	var fill: StyleBoxFlat = normal_fill
	if is_low:
		fill = low_fill
	moral_bar.add_theme_stylebox_override(&"fill", fill)
