extends RefCounted

## A piece in a scroll that is not a strip shown whole (scroll.gd): moved
## by the least that shows it, to the fraction of a pixel.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The engine's own reveal moves by whole pixels, and in a room of a
## fractional width leaves the far edge of a piece a sliver out of sight.
## A piece longer than the room cannot be whole: its start is shown, the
## same answer however it stood, so placing it again moves nothing -
## weighed from where it stood, the two edges pulled it back and forth a
## placing at a time, for ever. THE ROOM IS INSIDE THE SCROLL'S PADDING,
## its look's panel, less any bar that shows.


## This piece, one of what the scroll holds, shown whole, from the offset
## the scroll stands at.
static func show(scroll: ScrollContainer, at: Vector2, piece: Control) -> void:
	# the look's panel keeps its padding off the room, and a bar that is shown its thickness
	var room := scroll.size - scroll.get_theme_stylebox(&"panel").get_minimum_size() - Vector2(0.0, scroll.get_h_scroll_bar().size.y if scroll.get_h_scroll_bar().visible else 0.0)
	# where the piece stands in what the scroll holds, whatever offset that was last placed at
	var within := (scroll.get_child(0) as Control).get_global_transform().affine_inverse() * piece.get_global_transform()
	var shown := Rect2(within.origin, piece.size)
	# past the far edge, on by the overhang; then before the near edge, back by the shortfall - so a piece longer than the room shows its start, and stays so
	var to := at + (shown.end - (at + room)).max(Vector2.ZERO)
	to += (shown.position - to).min(Vector2.ZERO)
	scroll.get_h_scroll_bar().value = to.x
	scroll.get_v_scroll_bar().value = to.y
