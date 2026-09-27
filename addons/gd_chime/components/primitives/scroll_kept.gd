extends RefCounted

const Driver := preload("../../driver.gd")
const Applier := preload("../../applier.gd")

## Where a scroll (scroll.gd) stands, kept with the view it stands in, and
## put back when the reader comes back to that view.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHERE IT STANDS IS KEPT WITH THE VIEW: the history entry the reader is on
## (driver.keep), so a detour and Back land where they left, and the same
## screen entered as another view keeps its own. It is written down every
## time the engine places the content - which it does whenever the offset
## moves - so the view left keeps where it stood BEFORE the move, whatever
## the move then did; and it is put back as the driver's bell rings, which is
## after the applier has given the focus back. Focus follows the pad and the
## keys into view (the engine's follow_focus), but focus GIVEN BACK on
## arrival is given with this holding still (applier.gd), so it never
## scrolls away from where the reader stood. Content not yet tall enough to
## reach that far is waited for, never clamped short; the reader scrolling
## meanwhile has it back. A view nothing was kept for is a fresh visit: when
## the place this sits in was entered afresh by the move - a new stay, its
## token new - it stands at its top; when that place stayed where it was, as
## the frame round every screen does, a strip in it is left as it stands.
##
## THE FOCUS SHOWN WHOLE COMES FIRST (scroll.gd): put back where the reader
## stood, the scroll then moves as far as makes the focused row whole, and
## no further - where the two differ, the focus wins.
##
## It holds the scroll it keeps for, and nothing of the look; the offset is
## kept to the fraction, as the bars hold it.

## Where a scroll stood on one view, kept with that view's history entry: the driver keeps a RefCounted.
class Left extends RefCounted:
	var offset: Vector2 = Vector2.ZERO


var _scroll: ScrollContainer
var _ui: RefCounted  # whose driver keeps the offsets
var _place: Node  # the place the scroll was built in, or none
var _left: Left = null  # where it stands on the view shown now, or none while no view shows it
var _putting_back: Variant = null  # an offset waiting for the content to reach that far, or none
var _stay: RefCounted = null  # the token of that place's stay it last stood in


func _init(scroll: ScrollContainer, ui: RefCounted, place: Node) -> void:
	_scroll = scroll
	_ui = ui
	_place = place


## The reader moved: the view they are on now puts back where the scroll
## stood there, if it ever stood there; the view they left keeps what it
## last wrote.
func moved() -> void:
	var driver: Driver = _ui.driver
	_left = null
	_putting_back = null
	if not Applier.shows(driver.get_state(), _scroll, driver.index):
		return
	var kept_as := StringName("scroll at %s" % _scroll.get_path())
	var afresh: bool = _place != null and _place.token != _stay
	_stay = _place.token if _place != null else null
	_left = driver.kept(kept_as) as Left
	if _left == null:
		_left = Left.new()
		_left.offset = Vector2.ZERO if afresh else get_offset()
		driver.keep(kept_as, _left)
		if not afresh:
			return
	_putting_back = _left.offset
	# put back as the content is placed, when how far it reaches is known: the scroll bars say the last content's until then
	_scroll.queue_sort()


## The content placed, as it is whenever the offset moves: an offset
## waiting is put back if the content reaches that far, else where the
## scroll stands is written down. Whether it was put back just now.
func placed() -> bool:
	if _left == null:
		return false
	var put_back := false
	if _putting_back != null:
		var to: Vector2 = _putting_back
		var reaches := Vector2(_scroll.get_h_scroll_bar().max_value - _scroll.get_h_scroll_bar().page, _scroll.get_v_scroll_bar().max_value - _scroll.get_v_scroll_bar().page)
		if (to.x > 0 and reaches.x < to.x) or (to.y > 0 and reaches.y < to.y):
			return false
		_scroll.get_h_scroll_bar().value = to.x
		_scroll.get_v_scroll_bar().value = to.y
		_putting_back = null
		put_back = true
	_left.offset = get_offset()
	return put_back


## The reader scrolling by hand: an offset still waiting to be put back is given up to them.
func given_up() -> void:
	_putting_back = null


## Where the scroll stands, to the fraction: the offset its bars hold.
func get_offset() -> Vector2:
	return Vector2(_scroll.get_h_scroll_bar().value, _scroll.get_v_scroll_bar().value)
