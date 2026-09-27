extends RefCounted

const Motion := preload("../../motion.gd")
const Shift := preload("shift.gd")
const Transition := preload("transition.gd")

## A reorder: the pieces of a keyed set taken from the places they had to
## the places they have, WITH NOTHING EVER DRAWN OVER ANYTHING ELSE.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Carrying every piece straight to its new place makes them cross, and two
## rows crossing are words over words. So a reorder is planned. The pieces
## that keep their order among themselves - the most of them that can,
## every piece that has not moved among them, since a piece left standing
## is in the way of anything that would cross it - and move along one axis
## alone SLIDE: each stays between
## the same neighbours the whole way, all by one easing over one time, so
## no two of them can meet. Every other piece that moved is LIFTED: it
## fades out where it stood, and fades in where it belongs. And it is done
## in three beats, each waiting for the one before: what is going and what
## is lifted fade out, over the look's exit; then the sliders slide, over
## its move, through room nothing is drawn in; then what was lifted and
## what is arriving enter, one after another by the look's stagger. A beat
## with nothing in it takes no time.
##
## A reorder that comes while one is under way is planned from where the
## pieces are DRAWN, so a slider goes on from there; a piece part faded is
## lifted again, from the opacity it has. Every run drives what it writes
## (motion.gd) - a piece's carry, its opacity - so the new plan's runs take
## over from the old plan's, and from an entrance still under way. Reduced motion has no beats at
## all: everything is in its place at once, and what arrives fades in.
##
## plan() is the choice alone, with no nodes in it, so it can be asserted.

const WHAT_CARRY := &"carry"

var _motion: Motion
var _drawn: Dictionary = {}  # key -> where its piece was drawn as the last sort began
var _order: Array = []  # the keys in the order they had after the last sort
var _lifted: Dictionary = {}  # key -> true while its piece is lifted out and not yet set down


func _init(motion: Motion) -> void:
	_motion = motion


## Which of the pieces that moved slide, and which are lifted: was and now
## are key -> where the piece is drawn and where it belongs, before and
## order the keys as they were and as they are.
static func plan(was: Dictionary, now: Dictionary, before: Array, order: Array) -> Dictionary:
	var staying: Array = order.filter(func(key: Variant) -> bool: return before.has(key))
	# a piece that has not moved outweighs any number that have: it is never the one left out
	var weights: Array = staying.map(func(key: Variant) -> int: return staying.size() + 1 if now[key] == was[key] else 1)
	var in_step: Array = heaviest_in_order(staying.map(func(key: Variant) -> int: return before.find(key)), weights)
	var slides: Array = []
	var lifts: Array = []
	# every piece that was there and is somewhere else now
	for index: int in staying.size():
		var key: Variant = staying[index]
		var by: Vector2 = now[key] - was[key]
		if by == Vector2.ZERO:
			continue
		if in_step.has(index) and (by.x == 0.0 or by.y == 0.0):
			slides.append(key)
		else:
			lifts.append(key)
	return {"slides": slides, "lifts": lifts}


## The places in this line of numbers of its heaviest rising run: the
## pieces left in step with each other, by what each is worth keeping.
static func heaviest_in_order(line: Array, weights: Array) -> Array:
	var best: Array = []  # at each place, the heaviest rising run ending there: [its weight, its places]
	for at: int in line.size():
		var run: Array = [0, []]
		for earlier: int in at:
			if line[earlier] < line[at] and best[earlier][0] > run[0]:
				run = best[earlier]
		best.append([run[0] + weights[at], run[1] + [at]])
	var heaviest: Array = [0, []]
	for run: Array in best:
		if run[0] > heaviest[0]:
			heaviest = run
	return heaviest[1]


## The holder is about to place its pieces: where each is drawn now is kept.
func about_to_place(pieces: Dictionary) -> void:
	_drawn = {}
	for key: Variant in pieces:
		_drawn[key] = (pieces[key] as Control).position


## The holder has placed its pieces, in this order: the three beats set
## off, for what moved, and for what is arriving by this transition while
## something is going.
func placed(pieces: Dictionary, order: Array, arriving: Array, kind: StringName, going: bool) -> void:
	var now: Dictionary = {}
	for key: Variant in pieces:
		now[key] = (pieces[key] as Control).position
	var choice := plan(_drawn, now, _order, order) if not _motion.get_reduced() else {"slides": [], "lifts": []}
	# a piece lifted by the reorder before this one and not yet set down is lifted again, wherever it belongs
	for key: Variant in _lifted.keys():
		if pieces.has(key) and not choice["lifts"].has(key):
			choice["slides"].erase(key)
			choice["lifts"].append(key)
	var out: float = _motion.lasts(Motion.EXIT) if going or not choice["lifts"].is_empty() else 0.0
	var across: float = _motion.lasts(Motion.MOVE) if not choice["slides"].is_empty() else 0.0
	for key: Variant in choice["slides"] + choice["lifts"]:
		var piece: Control = pieces[key]
		var shift: Shift = Shift.of(piece)
		var from: Vector2 = _drawn[key] - now[key]
		shift.owe(from)
		# a slider is seen to travel in the second beat; a lifted piece travels then too, unseen
		_motion.drive(piece, WHAT_CARRY, from, Vector2.ZERO, Motion.MOVE, shift.carry).wait(out)
		if choice["lifts"].has(key):
			_lifted[key] = true
			_motion.drive(piece, Transition.WHAT_OPACITY, piece.modulate, Transition.CLEAR, Motion.EXIT, piece.set_modulate, true, _set_down.bind(key, piece, across))
	# every arriving piece, entered in the third beat, one after another
	for index: int in arriving.size():
		Transition.enter(pieces[arriving[index]], kind, _motion, out + across + index * _motion.stagger())
	for key: Variant in _lifted.keys():
		if not pieces.has(key):
			_lifted.erase(key)
	rested(pieces, order)


## A lifted piece has faded out: it fades in where it belongs once the sliders have crossed.
func _set_down(key: Variant, piece: Control, across: float) -> void:
	_lifted.erase(key)
	_motion.drive(piece, Transition.WHAT_OPACITY, Transition.CLEAR, Color.WHITE, Motion.ENTER, piece.set_modulate, true).wait(across)


## The holder has placed its pieces and nothing of the set changed - a
## window resized: every shift riding on a piece is told (shift.gd), and
## nothing is set off. The order they stand in is the one the next change is planned from.
func rested(pieces: Dictionary, order: Array) -> void:
	_order = order.duplicate()
	for key: Variant in pieces:
		if (pieces[key] as Node).has_node(^"Shift"):
			((pieces[key] as Node).get_node(^"Shift") as Shift).placed()
