extends "controller.gd"

## A rolling window of a line chart's points (line_chart.gd): values taken
## as they come, gathered into buckets of time, and the last whole buckets
## given as the chart the line chart reads - so a live chart is the floor's
## one chart, fed.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## TIME IS THE VALUES' OWN, never the clock's: a value is taken at the time
## it says it happened, so a stream paused holds the chart where it stood
## and one caught up on lays each value in the bucket it belongs to. A
## bucket is so many seconds; the window is the last so many whole buckets,
## the one filling now left out, so a point once drawn never moves and the
## line grows only at its end. A value older than the window is let go, and
## nothing is drawn from before the first value.
##
## A SERIES IS ONE OF THREE KINDS: MEAN, the average of what fell in a
## bucket, a bucket nothing fell in left as a gap; SUM, their total, an
## empty bucket nought; PER_MINUTE, their total scaled to a minute - how
## many a minute, whatever the bucket.
##
## THE NEWEST WHOLE BUCKET IS A VALUE (value.gd), set as a bucket is filled -
## ringing once a frame at most, however many were filled in it - and never
## for a value landing in the bucket still filling, so a chart over it is
## drawn again once a bucket: once a second, for a window of seconds.
##
## THE AXES STAND STILL: the chart carries its SPAN - across, the window's
## seconds up to nought, the newest whole bucket; up, from nought to the
## smallest round ceiling over the values - so the axes move only as the
## values cross a round number, never at every point.
##
## Deliberately absent: a series added after it is built, and a window
## that follows the clock through a silence.

## The kinds of series.
const MEAN := &"mean"
const SUM := &"sum"
const PER_MINUTE := &"per_minute"

var _series: Array  # each {name: its words, kind}, in the order drawn
var _bucket: float
var _points: int
var _words: Array  # [the time axis's words, the value axis's words]
var _totals: Array[PackedFloat64Array] = []  # by series, the total of each bucket, a bucket at its index modulo the points and one
var _counts: Array[PackedInt32Array] = []  # by series, how many values fell in each bucket
var _filling: int = -1  # the bucket filling now, or -1 before any value
var _whole := value(-1)  # the newest whole bucket, the one before the filling, or -1 before one is filled
var _began: int = -1  # the first bucket any value fell in: nothing before it is drawn


## These series - each {name, kind} - in buckets this many seconds long, the
## last so many whole ones kept, drawn over these axes' words.
func _init(chimes: Chimes, series: Array, bucket: float, points: int, x_words: Variant, y_words: Variant) -> void:
	super(chimes)
	_series = series
	_bucket = bucket
	_points = points
	_words = [x_words, y_words]
	# every series, its buckets begun empty, one more than the window for the one filling
	for one: Dictionary in series:
		var totals := PackedFloat64Array()
		totals.resize(points + 1)
		_totals.append(totals)
		var counts := PackedInt32Array()
		counts.resize(points + 1)
		_counts.append(counts)


## A value of the series at this place, at the time it happened, in seconds.
func take(series: int, at: float, value: float) -> void:
	var bucket := floori(at / _bucket)
	if bucket > _filling:
		_roll_to(bucket)
	if bucket <= _filling - _points:
		return
	var slot := bucket % (_points + 1)
	_totals[series][slot] += value
	_counts[series][slot] += 1


## The chart as the line chart reads it: {series: [{name, points}], x_words,
## y_words, span}, a point across in seconds before the newest whole bucket.
func get_chart() -> Dictionary:
	# the bucket after the newest whole one; before any is whole, nothing before the first value is drawn either way
	var filling: int = _whole.read() + 1 if _whole.read() >= 0 else _filling
	var drawn: Array = []
	var highest := 0.0
	# every series, its whole buckets in the window as points, oldest first
	for index: int in _series.size():
		var points := PackedVector2Array()
		for back: int in range(_points, 0, -1):
			var bucket := filling - back
			var value: Variant = _value_of(index, bucket) if bucket >= _began else null
			if value != null:
				points.append(Vector2((1 - back) * _bucket, value))
				highest = maxf(highest, value)
		drawn.append({"name": _series[index]["name"], "points": points})
	var across := (_points - 1) * _bucket
	return {"series": drawn, "x_words": _words[0], "y_words": _words[1], "span": Rect2(-across, 0.0, across, ceiling(highest))}


## The value of one series in one bucket, as its kind gives it, or null for a gap.
func _value_of(series: int, bucket: int) -> Variant:
	var slot := posmod(bucket, _points + 1)
	var total: float = _totals[series][slot]
	var many: int = _counts[series][slot]
	match _series[series]["kind"]:
		MEAN: return null if many == 0 else total / many
		PER_MINUTE: return total * 60.0 / _bucket
	return total


## The bucket filling moved on: every bucket passed over emptied for reuse,
## and - one having been filled, unless this is the first value - the
## newest whole bucket set.
func _roll_to(bucket: int) -> void:
	# every bucket from the one after the last filling to the new one, emptied, at most the whole ring
	for passed: int in range(maxi(_filling + 1, bucket - _points), bucket + 1):
		var slot := passed % (_points + 1)
		for series: int in _series.size():
			_totals[series][slot] = 0.0
			_counts[series][slot] = 0
	if _filling < 0:
		_began = bucket
	else:
		_whole.set_value(bucket - 1)
	_filling = bucket


## The smallest round number - 1, 2 or 5 of a power of ten - at or over this, and never nought.
static func ceiling(value: float) -> float:
	if value <= 0.0:
		return 1.0
	var magnitude := pow(10.0, floorf(log(value) / log(10.0)))
	# the first of those multiples at or over the value
	for multiple: float in [1.0, 2.0, 5.0]:
		if magnitude * multiple >= value:
			return magnitude * multiple
	return magnitude * 10.0
