## How the level ended, shown until it starts over.
##
## - Two lines: a headline naming the outcome, and a detail line saying what ran
##   out on a defeat. A victory has no detail line, because the headline says all
##   of it.
## - Separate from [FeedbackBanner], which writes transient messages about one
##   answer and takes them down after a second. This one stays up until the level
##   restarts: a different lifetime, and a different job.
## - Where the stars, the statistics and the recap of mistakes will be grafted on.
class_name LevelOutcomeBanner
extends Control

## Headline of a level won. Content, in French.
const VICTORY_HEADLINE: String = "Gagné !!!"

## Headline of a level lost.
const DEFEAT_HEADLINE: String = "Essayer encore !!!"

## What ran out on a defeat, written under the headline.
const DEFEAT_DETAIL: String = "Moral à zéro"

## Colour of a victory: the green of the check button.
const VICTORY_COLOR: Color = Color(0.0706, 0.4784, 0.3922)

## Colour of a defeat: the red of the slap button.
const DEFEAT_COLOR: Color = Color(0.8510, 0.2549, 0.1843)

## The big line. Injected from the scene.
@export var headline_label: Label

## The line under it, taken away when there is nothing to add. Injected.
@export var detail_label: Label


## Starts hidden: a level is not over before it has begun.
func _ready() -> void:
	hide()


## Shows how the level ended, and stays up until it restarts.
func show_outcome(outcome: LevelOutcome.Kind) -> void:
	var was_won: bool = outcome == LevelOutcome.Kind.VICTORY
	if was_won:
		_write_lines(VICTORY_HEADLINE, "", VICTORY_COLOR)
		return
	_write_lines(DEFEAT_HEADLINE, DEFEAT_DETAIL, DEFEAT_COLOR)


## Writes both lines, and takes the detail one away when it has nothing to say.
##
## - Colours the glyphs through a theme override rather than [member modulate],
##   which would tint the white outline too and undo the very thing that keeps
##   the text legible over the corridor.
func _write_lines(headline: String, detail: String, line_color: Color) -> void:
	headline_label.text = headline
	headline_label.add_theme_color_override(&"font_color", line_color)
	detail_label.text = detail
	detail_label.add_theme_color_override(&"font_color", line_color)
	detail_label.visible = not detail.is_empty()
	show()
