extends RefCounted

const Themes := preload("../../theme.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Feedback := preload("../../theme_feedback.gd")

## A status: a shape, its words and its ink together, so a state is read by
## a reader who sees no colour at all - never a hue alone.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## FIVE STATES, FIVE SHAPES: WELL a filled disc; NOTICE a filled triangle,
## point up; FAULT a square outline crossed through; MENDING a ring half
## filled; STILL two upright bars, a pause. An application says which of
## them each of its own states is - a device's Offline is a fault, a
## connection being made again is mending - and gives the words; the mark
## is the floor's. The ink is the look's for the state (theme_feedback.gd), a
## colour under the mark's type by the state's name.
##
## THE MARK IS ITS LOOK'S SIZE, whatever it says: an empty panel whose
## margins are its room, stacked under a canvas the stack gives the whole of
## it, the shape drawn over all of that, so a state changing
## draws the mark again and moves nothing. The shapes are geometry apart
## from the painting (outline), so they are checked without a pixel.
##
## Deliberately absent: a state beyond these five, and a mark that moves -
## a state changing is told by its shape changing, never by a pulse.
##
## The builder is taken untyped here, as loading.gd takes it: the one way a
## far-side failure is said is loading's, and loading is preloaded by the
## builder's own vocabulary, so a preload of the builder here would be a cycle.

const WELL := &"well"
const NOTICE := &"notice"
const FAULT := &"fault"
const MENDING := &"mending"
const STILL := &"still"
const STATES: Array[StringName] = [WELL, NOTICE, FAULT, MENDING, STILL]
## How thick an outline is, as a share of the mark's size.
const STROKE := 0.14


## The mark of a state - a state's name, or a bound value reading one - at its look's size.
static func mark(ui: RefCounted, state: Variant) -> Desc:
	return ui.stack([ui.surface(Feedback.STATUS_MARK), ui.canvas(_paint, state, Feedback.STATUS_MARK)])


## The mark beside its words, in one line. Its options: kind, the kind the
## words are said in, and wraps - words that wrap take the rest of the line
## and break at its width, so words that change, a count, never change the
## room the line needs.
const OPTIONS: Array[String] = ["kind", "wraps"]

static func make(ui: RefCounted, state: Variant, words: Variant, options: Dictionary = {}) -> Desc:
	Options.checked("a status", options, OPTIONS)
	var wraps: bool = options.get("wraps", false)
	var said: Desc = ui.text(words, options.get("kind", Themes.REASON))
	return ui.row([mark(ui, state), said.wraps().grow() if wraps else said], Feedback.STATUS_LINE)


## A state's shape inside this square: {filled: polygons, lines: polylines}, never outside it.
static func outline(state: StringName, room: Rect2) -> Dictionary:
	var middle := room.get_center()
	var half := minf(room.size.x, room.size.y) / 2.0
	var stroke := half * 2.0 * STROKE
	var inner := half - stroke / 2.0
	match state:
		NOTICE: return {"filled": [PackedVector2Array([middle + Vector2(0.0, -half), middle + Vector2(half, half), middle + Vector2(-half, half)])], "lines": []}
		FAULT:
			var box := PackedVector2Array([middle + Vector2(-inner, -inner), middle + Vector2(inner, -inner), middle + Vector2(inner, inner), middle + Vector2(-inner, inner), middle + Vector2(-inner, -inner)])
			return {"filled": [], "lines": [box, PackedVector2Array([box[0], box[2]]), PackedVector2Array([box[1], box[3]])], "stroke": stroke}
		MENDING:
			var ring := _arc(middle, inner, 0.0, TAU)
			var left := _arc(middle, inner, PI * 0.5, PI * 1.5)
			return {"filled": [left], "lines": [ring], "stroke": stroke}
		STILL:
			var bar := Vector2(half * 0.55, half * 2.0)
			return {"filled": [_box(Rect2(middle - Vector2(half * 0.9, half), bar)), _box(Rect2(middle + Vector2(half * 0.35, -half), bar))], "lines": []}
	return {"filled": [_arc(middle, half, 0.0, TAU)], "lines": []}


## The points of an arc from one angle to another; filled, one less than whole is closed by its chord.
static func _arc(middle: Vector2, radius: float, from: float, to: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	# every step of the way round, twenty-four to the whole circle
	for step: int in range(0, 25):
		var angle := from + (to - from) * step / 24.0
		points.append(middle + Vector2(cos(angle), sin(angle)) * radius)
	return points


static func _box(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


## The mark: the state's shape over the whole of the canvas, in its ink;
## nothing for a template's empty handle, which reads no state.
static func _paint(control: Control, state: Variant) -> void:
	if state == null:
		return
	var ink := control.get_theme_color(state)
	var shape := outline(state, Rect2(Vector2.ZERO, control.size))
	# every filled part of the shape
	for part: PackedVector2Array in shape["filled"]:
		control.draw_colored_polygon(part, ink)
	# every drawn line of the shape, at its stroke
	for line: PackedVector2Array in shape["lines"]:
		control.draw_polyline(line, ink, shape["stroke"], true)
