## The speech bubble of the character currently walking up to the player.
##
## - Follows a 3D anchor by projecting it onto the screen every frame, rather
##   than living in the 3D scene: the text stays crisp at any distance and the
##   depth fog of the corridor never eats it.
## - Knows nothing of encounters, of the queue or of the rule of the day. It is
##   shown a sentence and an anchor, and hidden again.
class_name SpeechBubble
extends PanelContainer

## Camera the anchor is projected through. Injected from the scene. Taking it by
## reference rather than from the viewport means the bubble follows the camera
## shake for free, once there is one.
@export var camera: Camera3D

## Label the sentence is written into. Injected from the scene.
@export var phrase_label: Label

## Label naming a special character above their sentence, so a brick is never a
## surprise the first time it walks up. Injected from the scene.
@export var speaker_label: Label

## The point the bubble is pinned above, or null while it is hidden.
var _anchor: Node3D = null


## Starts hidden: there is nobody to speak until the first character sets off.
func _ready() -> void:
	hide()


## Writes a sentence into the bubble and pins it above the given anchor.
##
## - [param speaker] names a special character. Empty for an ordinary one, whose
##   line then disappears rather than leaving a gap.
func show_phrase(sentence: String, speaker: String, anchor: Node3D) -> void:
	phrase_label.text = sentence
	speaker_label.text = speaker
	speaker_label.visible = not speaker.is_empty()
	_anchor = anchor
	reset_size()
	_follow_anchor()
	show()


## Takes the bubble off screen, once its character has been answered.
func clear() -> void:
	_anchor = null
	hide()


## Keeps the bubble pinned while it has an anchor.
func _process(_delta: float) -> void:
	if _anchor == null:
		return
	_follow_anchor()


## Places the bubble just above the projection of its anchor.
##
## - Centres it on the anchor and rests its bottom edge there.
## - Leaves it where it was while the anchor is behind the camera, so it never
##   jumps across the screen as a character walks past the player.
func _follow_anchor() -> void:
	var anchor_position: Vector3 = _anchor.global_position
	var is_behind_camera: bool = camera.is_position_behind(anchor_position)
	if is_behind_camera:
		return
	var screen_position: Vector2 = camera.unproject_position(anchor_position)
	var offset_to_bottom_centre := Vector2(size.x * 0.5, size.y)
	position = screen_position - offset_to_bottom_centre
