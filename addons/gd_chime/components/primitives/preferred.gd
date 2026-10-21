extends RefCounted

## What a part would take given all the room it wants - CSS's max-content
## size - beside its least, the narrowest it can lawfully be: words that
## wrap, every one on one line; a row, its parts each at that, with its
## gaps; anything that says nothing of it, its least.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PART SAYS ITS OWN, through preferred_size(): every piece that draws
## has one (presentation.gd), which is its least until it knows better -
## words that wrap (text.gd), a line (layout.gd), the same parts in the
## arrangement they would most like (by_room.gd), a page (page_scroll.gd),
## one of two pieces (when.gd), any other piece that draws round what it
## holds (presentation.gd: over). A scroll that runs across and never down - a strip
## of tabs - would take what it holds would take across, with its padding,
## and its least down. Any other container that answers none - a surface, a
## stack - holds what it holds laid over one another, and would take its
## least and as much more as the one of them wanting the most more would
## (over). A control holding none is its least, since nothing more is known
## of it.
##
## IT IS WHERE A PART STARTS (flex_line.gd): a part given no basis starts
## along a row at its preferred width, and shrinks from there only to its
## least, so a row of words starts at their natural length and narrows
## evenly - CSS's flex-basis auto. Down a column a part starts at its least
## height, which is its height at the width it has: a part's preferred
## height is never more than that.
##
## IT NEVER MOVES ON ITS OWN. A part whose preferred size moves while its
## least did not - words that wrap, said again at the same widest word -
## tells the lines holding it (moved()), since the engine tells a holder
## only of a least that moved.
##
## It holds nothing and draws nothing.


## What this part would take given all the room it wants: its own answer,
## or its least where it gives none.
static func of(part: Control) -> Vector2:
	if part.has_method(&"preferred_size"):
		return part.preferred_size()
	var strip := part as ScrollContainer
	if strip != null and strip.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and strip.get_child_count() > 0:
		return Vector2(of(strip.get_child(0)).x + strip.get_theme_stylebox(&"panel").get_minimum_size().x, strip.get_combined_minimum_size().y)
	return over(part) if part is Container else part.get_combined_minimum_size()


## What a piece holding these controls laid over one another would take - a
## surface round its words, a stack, a press round its face: its least, and
## as much more as the shown one wanting the most more than its own least.
static func over(part: Control) -> Vector2:
	var more := Vector2.ZERO
	# every shown control it holds, for the most any wants beyond its least
	for held: Node in part.get_children():
		if held is Control and (held as Control).visible:
			more = more.max(of(held) - (held as Control).get_combined_minimum_size())
	return part.get_combined_minimum_size() + more


## Where each part of a line starts along it when it is given no basis,
## its least size given beside it: along a row its preferred width, down a
## column its least height.
static func along(parts: Array[Control], least: Array, row: bool) -> Array:
	if not row:
		return least.map(func(needs: Vector2) -> float: return needs.y)
	return parts.map(func(part: Control) -> float: return of(part).x)


## How wide a line of these parts would be given all the room it wants:
## along a row, each at its preferred width, but never under `each_least`,
## with the gap between each two; down a column, the widest of them.
static func line(parts: Array[Control], down: bool, gap: float, each_least: float = 0.0) -> float:
	var widths: Array = parts.map(func(part: Control) -> float: return maxf(of(part).x, each_least))
	if widths.is_empty():
		return 0.0
	if down:
		return widths.max()
	# the widths end to end, with the gap between each two
	return widths.reduce(func(sum: float, wide: float) -> float: return sum + wide, 0.0) + gap * (widths.size() - 1)


## A part's preferred size moved while its least did not: every line
## holding it, one inside another, places its parts again - up to the first
## holder that is not a line (flex.gd), whose own preferred size is not made
## of its parts' and so has not moved.
static func moved(part: Control) -> void:
	var holder := part.get_parent()
	# up through every line holding it, each told to place its parts again
	while holder != null and holder.has_method(&"get_facts"):
		(holder as Container).queue_sort()
		holder = holder.get_parent()
