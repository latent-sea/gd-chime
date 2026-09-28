extends RefCounted

const Going := preload("going.gd")
const Shift := preload("shift.gd")
const FlexLine := preload("flex_line.gd")

## A holder's content placed inside its box's padding: the room the box
## says to keep around what it holds, read from the stylebox's content
## margins, so a look's padding reaches the words.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A pressable draws its state's box and a surface its panel; each box
## carries margins the look set (Look.flat's pad). The engine's Container
## asks its holder to place its parts on every sort; these two functions
## are that placing and the room it needs, shared by every holder that
## draws a box under its content.


## Every part fitted to the holder's rect inside the box's margins, as its
## motion has left it (shift.gd): stretched down the whole of that room, or,
## told where it stands down it, as tall as it needs and standing there.
static func fit(holder: Container, box: StyleBox, down: int = FlexLine.STRETCH) -> void:
	var inside := Rect2(Vector2(box.get_margin(SIDE_LEFT), box.get_margin(SIDE_TOP)), holder.size - Vector2(box.get_margin(SIDE_LEFT) + box.get_margin(SIDE_RIGHT), box.get_margin(SIDE_TOP) + box.get_margin(SIDE_BOTTOM)))
	for child: Node in holder.get_children():
		if child is Control and not child.top_level and not Going.is_going(child):
			var rect := inside
			if down != FlexLine.STRETCH:
				rect.size.y = minf((child as Control).get_combined_minimum_size().y, inside.size.y)
				rect.position.y += FlexLine.aligned(down, inside.size.y, rect.size.y)
			Shift.fit(holder, child, rect)


## As much room as any part needs, plus the box's margins.
static func least(holder: Container, box: StyleBox) -> Vector2:
	var most := Vector2.ZERO
	for child: Node in holder.get_children():
		if child is Control and (child as Control).visible and not Going.is_going(child):
			most = most.max((child as Control).get_combined_minimum_size())
	return most + box.get_minimum_size()
