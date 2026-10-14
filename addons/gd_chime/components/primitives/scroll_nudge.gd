extends RefCounted

const Bound := preload("bound.gd")

## A scroll (scroll.gd) moved a press at a time, for a reader with no wheel
## and no finger on the glass: told a nudge, it goes most of its own height
## up or down, eased, and no further than its ends.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A NUDGE IS A BOUND VALUE, {"by", "count"}: "by" one up (-1) or one down
## (1), and "count" how many nudges there have been, so the same way twice
## running is two nudges. What is first read is where the count stands, not
## a nudge; whoever presses makes the next. The press is a model's, and the
## scroll only follows what it says.
##
## A NUDGE IS SCROLLING BY HAND, as the wheel is: the scroll is told so (its
## mark lit, the focus no longer keeping it), by the call it hands in.

## How much of its own height one nudge moves the scroll, and over how long, in seconds.
const SHARE := 0.85
const TAKES := 0.22

var _scroll: ScrollContainer
var _nudged: Bound
var _by_hand: Callable
var _seen := -1  # the count last read: a nudge is a count that has moved past it


func _init(scroll: ScrollContainer, nudged: Bound, by_hand: Callable) -> void:
	_scroll = scroll
	_nudged = nudged
	_by_hand = by_hand


## The nudge read, so it is followed; moved past the count last read, the scroll goes that way.
func moved() -> void:
	var told: Variant = _nudged.read()
	if told == null:
		return
	var was := _seen
	_seen = told["count"]
	if was < 0 or told["count"] == was or told["by"] == 0 or not _scroll.is_visible_in_tree():
		return
	var bar := _scroll.get_v_scroll_bar()
	var to: float = clampf(_scroll.scroll_vertical + told["by"] * _scroll.size.y * SHARE, 0.0, maxf(bar.max_value - bar.page, 0.0))
	_by_hand.call()
	_scroll.create_tween().tween_property(_scroll, "scroll_vertical", int(to), TAKES).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
