## Builds the queue of a level from its configuration and its phrase pool.
##
## - Draws one sentence per character, as likely to be a cliché as a real piece
##   of information, so that the player reads instead of memorising.
## - Plants exactly one cult sentence in a long enough queue, never on the first
##   characters: it is a comic reward and it has to stay rare.
## - Turns some of the ordinary characters into the bricks the level asks for,
##   also never on the first ones: the player meets plain characters and learns
##   the rule before a special one shows up.
## - Gives each character a colour spread far from its neighbours', so two in a
##   row never look alike.
## - Pure: it touches no node and keeps nothing between calls.
class_name QueueBuilder
extends RefCounted

## Below this many characters, no cult sentence is planted at all.
const MINIMUM_SIZE_FOR_A_CULT_PHRASE: int = 10

## The cult sentence never lands before this rank, where the player is still
## getting used to the rule.
const FIRST_RANK_FOR_A_CULT_PHRASE: int = 3

## No brick lands before this rank, so the first characters of a level are always
## ordinary ones.
const FIRST_RANK_FOR_A_BRICK: int = 2

## Chance that a drawn sentence is a cliché rather than a real piece of
## information. Deliberately even: any bias would become guessable, and guessing
## is exactly what reading the bubble is supposed to replace.
const CLICHE_PROBABILITY: float = 0.5

## Degrees of hue between one character and the next. Close to the golden angle,
## so a run of characters never repeats a colour.
const HUE_STEP_DEGREES: float = 137.0

## Saturation and value of the bodies: the HSL(0.45, 0.5) of the mockup
## converted to the HSV that Godot expects.
const BODY_SATURATION: float = 0.62

## See [constant BODY_SATURATION].
const BODY_VALUE: float = 0.725


## Builds the whole queue of a level.
static func build(config: LevelConfig) -> CharacterQueue:
	var pool: PhrasePool = config.phrase_pool
	var ordinary_kind: CharacterKind = config.base_character_kind
	var briefs: Array[CharacterBrief] = []
	for rank in config.character_count:
		var drawn_brief: CharacterBrief = _draw_brief(pool, rank, ordinary_kind)
		briefs.append(drawn_brief)
	_plant_cult_phrase(briefs, pool)
	_plant_bricks(briefs, config.bricks)
	return CharacterQueue.new(briefs)


## Draws one ordinary character: a sentence, its nature, and a colour.
static func _draw_brief(
	pool: PhrasePool,
	rank: int,
	ordinary_kind: CharacterKind
) -> CharacterBrief:
	var is_a_cliche: bool = randf() < CLICHE_PROBABILITY
	var kind: PhraseKind.Kind = PhraseKind.Kind.REAL_INFORMATION
	if is_a_cliche:
		kind = PhraseKind.Kind.CLICHE
	var sentence: String = pool.draw_phrase(kind)
	var color: Color = _body_color_for_rank(rank)
	return CharacterBrief.new(sentence, kind, color, ordinary_kind)


## Turns some of the drawn characters into the bricks the level asks for.
##
## - One entry per character to place, so the same brick listed twice puts two of
##   them in the queue.
## - Picks ranks at random among those a brick is allowed to take, and never the
##   same rank twice.
## - Keeps the sentence and the colour that were drawn; only the kind changes.
static func _plant_bricks(briefs: Array[CharacterBrief], bricks: Array[CharacterKind]) -> void:
	var free_ranks: Array[int] = _ranks_open_to_bricks(briefs.size())
	free_ranks.shuffle()
	for brick in bricks:
		if free_ranks.is_empty():
			return
		var rank: int = free_ranks.pop_back()
		var replaced_brief: CharacterBrief = briefs[rank]
		briefs[rank] = CharacterBrief.new(
			replaced_brief.phrase,
			replaced_brief.phrase_kind,
			replaced_brief.body_color,
			brick
		)


## The ranks a brick is allowed to take in a queue of this length.
static func _ranks_open_to_bricks(queue_size: int) -> Array[int]:
	var ranks: Array[int] = []
	for rank in range(FIRST_RANK_FOR_A_BRICK, queue_size):
		ranks.append(rank)
	return ranks


## Replaces one character's sentence with a cult one, keeping their colour.
##
## - Does nothing on a short queue, or on a pool with no cult sentence.
static func _plant_cult_phrase(briefs: Array[CharacterBrief], pool: PhrasePool) -> void:
	var is_queue_long_enough: bool = briefs.size() >= MINIMUM_SIZE_FOR_A_CULT_PHRASE
	if not is_queue_long_enough:
		return
	if not pool.has_cult_phrases():
		return
	var last_rank: int = briefs.size() - 1
	var planted_rank: int = randi_range(FIRST_RANK_FOR_A_CULT_PHRASE, last_rank)
	var replaced_brief: CharacterBrief = briefs[planted_rank]
	var cult_sentence: String = pool.draw_cult_phrase()
	var cult_brief := CharacterBrief.new(
		cult_sentence,
		PhraseKind.Kind.CLICHE,
		replaced_brief.body_color,
		replaced_brief.character_kind
	)
	briefs[planted_rank] = cult_brief


## Returns the body colour of the character at this rank in the queue.
static func _body_color_for_rank(rank: int) -> Color:
	var hue_degrees: float = fmod(rank * HUE_STEP_DEGREES, 360.0)
	var hue: float = hue_degrees / 360.0
	return Color.from_hsv(hue, BODY_SATURATION, BODY_VALUE)
