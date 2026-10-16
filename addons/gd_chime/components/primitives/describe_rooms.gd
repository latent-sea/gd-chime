extends "describe_shapes.gd"

## The descriptions of pieces that answer to the room they are given rather
## than to what they hold: a page that scrolls down.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's and describe_shapes.gd's,
## which this extends; describe_values.gd extends this, and the builder
## (ui.gd) extends them all. These stand apart because the least each asks
## for never grows with what it holds, so one wide piece inside cannot widen
## what holds it - the page, the app or the window.


## A page that scrolls down (page_scroll.gd): it asks for no room of its
## own, and lays what it holds at exactly its width, so a piece too wide for
## it is cut inside it and said, never passed up. Each screen's one scroll
## that runs down. Given a bound value naming a piece, it brings that piece
## into view as the name moves, and given one to follow, a press at a time
## moves it, as a scroll does.
func page_scroll(content: Desc, reveal: Bound = null, nudged: Bound = null, style: StringName = &"Scroll") -> Desc:
	return Desc.new(&"page_scroll", {"reveal": reveal, "nudged": nudged, "style": style}, [content])
