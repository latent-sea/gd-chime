extends RefCounted

## Whether a control is near enough to be seen that what it shows should be
## on its way: inside the scroll that holds it, or within the look's reach
## beyond either end of it - so a picture a card down is asked for before
## the reader gets there, and one far behind is let go.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A primitive that loads when near holds one of these and tells it when it
## enters and leaves the tree and when it is shown or hidden; the scroll
## holding it (scroll.gd) tells every one inside it each time it is placed -
## which it is whenever the reader scrolls - by calling near_moved() on the
## group this names for it. Each time, it works out again whether the
## control is near, and says so to whoever holds it only when that changes.
##
## NEAR is: shown, and - in a scroll - its rect meeting the scroll's grown
## by the look's reach beyond each end, a share of the scroll's height in
## thousandths ("reach" under Scroll). Outside any scroll, shown is near.
##
## Deliberately absent: a reach across, for a strip; nothing loads in one yet.

## The type the look holds the reach under.
const SCROLL := &"Scroll"

var _control: Control
var _moved: Callable  # told(near) whenever it changes
var _scroll: ScrollContainer = null
var _near: bool = false


## For this control, telling moved(near) as it changes.
func _init(control: Control, moved: Callable) -> void:
	_control = control
	_moved = moved


## The group a scroll's near things are in: named for that scroll alone.
static func group_of(scroll: ScrollContainer) -> StringName:
	return StringName("near_%d" % scroll.get_instance_id())


func is_near() -> bool:
	return _near


## Where it stands in what its scroll holds, however far that is scrolled - or nowhere, in no scroll.
func get_place() -> Vector2:
	if _scroll == null:
		return Vector2.ZERO
	return _control.global_position - _scroll.global_position + Vector2(_scroll.scroll_horizontal, _scroll.scroll_vertical)


## In the tree: the scroll holding it found, and whether it is near worked out.
func entered() -> void:
	var above := _control.get_parent()
	# up through what holds it to the nearest scroll, or out of the tree with none
	while above != null and not above is ScrollContainer:
		above = above.get_parent()
	_scroll = above
	if _scroll != null:
		_control.add_to_group(group_of(_scroll))
	check()


## Out of the tree: no longer near, and no longer in its scroll's group.
func left() -> void:
	if _scroll != null:
		_control.remove_from_group(group_of(_scroll))
	_scroll = null
	_become(false)


## Worked out again: near or not, said if it changed.
func check() -> void:
	if not _control.is_inside_tree() or not _control.is_visible_in_tree():
		_become(false)
		return
	if _scroll == null:
		_become(true)
		return
	var room := _scroll.get_global_rect()
	var reach := room.size.y * _control.get_theme_constant(&"reach", SCROLL) / 1000.0
	_become(room.grow_individual(0.0, reach, 0.0, reach).intersects(_control.get_global_rect(), true))


func _become(near: bool) -> void:
	if near == _near:
		return
	_near = near
	_moved.call(near)
