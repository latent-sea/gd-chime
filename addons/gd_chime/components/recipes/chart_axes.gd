extends RefCounted

const Formats := preload("../../formats.gd")
const Text := preload("../primitives/text.gd")

## A chart's two axes: what its data spans, where a point of it lands on
## the canvas, which round numbers are marked along each, and the axes
## drawn with those numbers and the words saying what each axis is.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE GEOMETRY IS PURE - a span, a size and a margin in, a place out - so
## it is checked without a pixel, and every chart drawn over a time axis and
## a value axis shares it (line_chart.gd). The value axis runs UP. A span a
## model gives is kept as given, so a live chart whose values wander inside
## it never rescales under the reader; given none, the span is fitted to the
## points, and a flat series or a single point is padded so it has a middle
## to sit on.
##
## The marked numbers are written as the language on writes them, as the
## painter paints them, and the axes' words are said as a text says them.
## The ink is the canvas's style's: the axes and their ticks in its "link",
## the numbers and words in its "line".

## About how many numbers are marked along an axis.
const TICKS := 4
## How far a flat axis is padded either side of its one value.
const PAD := 0.5
## How long a tick is, in the canvas's pixels.
const TICK := 5.0


## What these series span, both axes, never nothing on either: every point
## of every series, and every point of an area's lower edge ("under").
static func extent(series: Array) -> Rect2:
	var low := Vector2.ZERO
	var high := Vector2.ZERO
	var found := false
	# every series, for the one box that holds all their points
	for one: Dictionary in series:
		# its line and, for an area, its lower edge
		for edge: Variant in [one["points"], one.get("under", [])]:
			# every point of that edge, the box widened to hold it
			for point: Vector2 in edge:
				if not found:
					low = point
					high = point
					found = true
				low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
				high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
	var span := high - low
	var pad := Vector2(PAD if span.x == 0.0 else 0.0, PAD if span.y == 0.0 else 0.0)
	return Rect2(low - pad, span + pad * 2.0)


## The span a chart is drawn over: the one its model gives, else its points'.
static func span_of(chart: Dictionary) -> Rect2:
	return chart["span"] if chart.has("span") else extent(chart["series"])


## Where a point lands on the canvas: across for its time, UP for its
## value, inside the margins the axes and their numbers take - left, top,
## right and bottom - and never past the plot, so a value outside a given
## span is drawn on its edge.
static func to_canvas(point: Vector2, span: Rect2, size: Vector2, margin: Vector4) -> Vector2:
	var plot := size - Vector2(margin.x + margin.z, margin.y + margin.w)
	var share := ((point - span.position) / span.size).clamp(Vector2.ZERO, Vector2.ONE)
	return Vector2(margin.x + share.x * plot.x, margin.y + plot.y - share.y * plot.y)


## The round numbers marked between two values: the 1, 2 or 5 of a power
## of ten that gives about this many, and none outside the range.
static func ticks(low: float, high: float, count: int) -> Array[float]:
	var step := _step((high - low) / float(count))
	var marks: Array[float] = []
	var at := ceilf(low / step) * step
	# up from the first round number at or above the low end
	while at <= high + step * 0.0001:
		marks.append(at)
		at += step
	return marks


## The margins the axes take on a canvas - left, top, right, bottom - by
## the height of the words: at the left the value axis's numbers; at the
## top half a line for the top number, which stands across the plot's edge,
## and over it a line for the words saying what the value axis is, where it
## says anything; at the right half a number, so the last one along the time
## axis is whole; and under the time axis a tick, a line of its numbers and,
## where it says anything, a line of the words saying what it is.
static func margin_of(control: Control, chart: Dictionary) -> Vector4:
	var height := control.get_theme_default_font().get_height()
	var over := height * (1.2 if Text.said(chart["y_words"]) != "" else 0.0)
	var under := height * (1.2 if Text.said(chart["x_words"]) != "" else 0.0)
	return Vector4(height * 2.5, height * 0.6 + over, height * 1.25, TICK + height * 1.2 + under)


## How many numbers an axis this long has room for, a line and a half
## each so none is drawn over the next: at least one, and never more than TICKS.
static func fitting(room: float, line: float) -> int:
	return clampi(floori(room / (line * 1.5)), 1, TICKS)


## The two axes, the marked numbers along each with a tick, and the words
## saying what each axis is.
static func draw(control: Control, chart: Dictionary, span: Rect2, margin: Vector4) -> void:
	var font := control.get_theme_default_font()
	var words_high := font.get_height()
	var ink := control.get_theme_color(&"line")
	var soft := control.get_theme_color(&"link")
	var corner := to_canvas(span.position, span, control.size, margin)
	var far := to_canvas(span.end, span, control.size, margin)
	control.draw_line(Vector2(corner.x, far.y), corner, soft, 1.0)
	control.draw_line(corner, Vector2(far.x, corner.y), soft, 1.0)
	# the value axis: a tick out to the left of each marked number, the number beside it
	for value: float in ticks(span.position.y, span.end.y, fitting(corner.y - far.y, words_high)):
		var at := to_canvas(Vector2(span.position.x, value), span, control.size, margin)
		control.draw_line(at - Vector2(TICK, 0.0), at, soft, 1.0)
		control.draw_string(font, Vector2(at.x - margin.x, at.y + words_high * 0.35), _number(value), HORIZONTAL_ALIGNMENT_RIGHT, margin.x - 9.0, words_high, ink)
	# the time axis: a tick down under each marked number, the number under it
	for value: float in ticks(span.position.x, span.end.x, TICKS):
		var at := to_canvas(Vector2(value, span.position.y), span, control.size, margin)
		control.draw_line(at, at + Vector2(0.0, TICK), soft, 1.0)
		control.draw_string(font, Vector2(at.x - margin.x * 0.5, at.y + TICK + words_high), _number(value), HORIZONTAL_ALIGNMENT_CENTER, margin.x, words_high, ink)
	control.draw_string(font, Vector2(margin.x, control.size.y - words_high * 0.2), Text.said(chart["x_words"]), HORIZONTAL_ALIGNMENT_CENTER, control.size.x - margin.x - margin.z, words_high, ink)
	control.draw_string(font, Vector2(4.0, words_high), Text.said(chart["y_words"]), HORIZONTAL_ALIGNMENT_LEFT, -1, words_high, ink)


## The step between marked numbers: the smallest of 1, 2, 5 or 10 of a
## power of ten that is still at least the step asked for.
static func _step(raw: float) -> float:
	var magnitude := pow(10.0, floorf(log(raw) / log(10.0)))
	# the first of those multiples that covers the step asked for
	for multiple: float in [1.0, 2.0, 5.0]:
		if magnitude * multiple >= raw:
			return magnitude * multiple
	return magnitude * 10.0


## A round number as words, as the language on writes it: to no more places
## than it has, so a whole one has no fraction at all.
static func _number(value: float) -> String:
	var plain := ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".")
	return Formats.written_number(value, plain.get_slice(".", 1).length() if plain.contains(".") else 0)
