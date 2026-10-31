## The swipe gesture, read across the whole screen.
##
## - Reports the same two answers as the buttons, through the same signal, so
##   that no gameplay script ever learns which control was used.
## - Lights the edge of the screen as the finger travels, so the player sees the
##   answer building up before letting go.
## - Its thresholds are fractions of the screen width, not pixels: the 50 px of
##   the mockup on a 390 px screen has to mean the same thing on a 720 px one.
class_name AnswerSwipeArea
extends Control

## Emitted when the player swipes far enough for an answer to count.
signal answer_submitted(gesture: AnswerGesture.Kind)

## Smallest width the thresholds are measured against, so a gesture read before
## the first layout pass cannot divide by a screen of zero pixels.
const MINIMUM_SCREEN_WIDTH: float = 1.0

## Share of the screen width the finger must travel for an answer to count.
@export_range(0.05, 0.5, 0.01) var trigger_ratio: float = 0.13

## Share of the screen width at which the edge glow is fully lit.
@export_range(0.05, 0.5, 0.01) var full_glow_ratio: float = 0.2

## Glow on the left, lit while a slap is being swiped. Injected from the scene.
@export var slap_glow: Control

## Glow on the right, lit while a check is being swiped. Injected from the scene.
@export var check_glow: Control

## Where the finger first touched down.
var _drag_start_x: float = 0.0

## True between touching down and letting go.
var _is_dragging: bool = false


## Starts with both edges dark.
func _ready() -> void:
	_light_edges(0.0)


## Reads the gesture from the pointer.
##
## - Only mouse events are handled: Godot turns touches into them by default, so
##   one path serves the finger on a phone and the mouse in the editor.
func _gui_input(event: InputEvent) -> void:
	var pointer_press := event as InputEventMouseButton
	if pointer_press != null:
		_handle_pointer_press(pointer_press)
		return
	var pointer_motion := event as InputEventMouseMotion
	if pointer_motion != null:
		_handle_pointer_motion(pointer_motion)


## Begins a swipe on touch down, and settles it on letting go.
func _handle_pointer_press(press: InputEventMouseButton) -> void:
	var is_main_button: bool = press.button_index == MOUSE_BUTTON_LEFT
	if not is_main_button:
		return
	if press.pressed:
		_start_drag(press.position.x)
		return
	_end_drag(press.position.x)


## Lights the edges as the finger travels.
func _handle_pointer_motion(motion: InputEventMouseMotion) -> void:
	if not _is_dragging:
		return
	var travelled: float = motion.position.x - _drag_start_x
	_light_edges(travelled)


## Remembers where the swipe started.
func _start_drag(pointer_x: float) -> void:
	_drag_start_x = pointer_x
	_is_dragging = true
	_light_edges(0.0)


## Settles the swipe: an answer if it went far enough, nothing otherwise.
func _end_drag(pointer_x: float) -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	_light_edges(0.0)
	var travelled: float = pointer_x - _drag_start_x
	_submit_if_far_enough(travelled)


## Reports an answer when the finger travelled past the threshold.
func _submit_if_far_enough(travelled_pixels: float) -> void:
	var screen_width: float = maxf(MINIMUM_SCREEN_WIDTH, size.x)
	var trigger_distance: float = screen_width * trigger_ratio
	var asks_for_slap: bool = travelled_pixels <= -trigger_distance
	if asks_for_slap:
		answer_submitted.emit(AnswerGesture.Kind.SLAP)
		return
	var asks_for_check: bool = travelled_pixels >= trigger_distance
	if asks_for_check:
		answer_submitted.emit(AnswerGesture.Kind.CHECK)


## Fades each edge in proportion to how far the finger went its way.
func _light_edges(travelled_pixels: float) -> void:
	var screen_width: float = maxf(MINIMUM_SCREEN_WIDTH, size.x)
	var full_glow_distance: float = screen_width * full_glow_ratio
	var slap_amount: float = clampf(-travelled_pixels / full_glow_distance, 0.0, 1.0)
	var check_amount: float = clampf(travelled_pixels / full_glow_distance, 0.0, 1.0)
	slap_glow.modulate.a = slap_amount
	check_glow.modulate.a = check_amount
