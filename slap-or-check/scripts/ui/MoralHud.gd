## The moral of the running level, and how many characters are left to come.
##
## - Reads three signals and writes three widgets. It never reaches for the gauge,
##   the queue or the level: it is told, and it shows.
## - Owns no rule of the game. It does not know at which moral the level becomes
##   dangerous; it is told to warn, and it warns. The threshold is balance, and it
##   lives with the rest of the balance.
class_name MoralHud
extends Control

## Written before the number of characters still to come. Content, in French.
const REMAINING_PREFIX: String = "Reste "

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


## Takes the span of the bar from the gauge itself, so the two cannot drift apart.
func _ready() -> void:
	moral_bar.max_value = MoralGauge.MAX_VALUE


## Shows a new moral: the bar, and the number beside it.
##
## - The bar follows the exact value, so the drain reads as a smooth slide, while
##   the number is rounded: a figure flickering between 69 and 70 is unreadable.
func show_moral(new_value: float) -> void:
	var rounded_moral: int = int(round(new_value))
	var displayed_moral: int = clampi(rounded_moral, 0, int(MoralGauge.MAX_VALUE))
	moral_bar.value = new_value
	moral_label.text = str(displayed_moral)


## Shows how many characters are still to come, the one walking up included.
func show_remaining(remaining: int) -> void:
	remaining_label.text = REMAINING_PREFIX + str(remaining)


## Reddens the bar while the moral is low, and puts it back when it recovers.
##
## - Called only when the warning changes, so the style is swapped on the frame
##   the threshold is crossed and not on every frame of the drain.
func show_low_moral(is_low: bool) -> void:
	var fill: StyleBoxFlat = normal_fill
	if is_low:
		fill = low_fill
	moral_bar.add_theme_stylebox_override(&"fill", fill)
