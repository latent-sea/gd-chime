extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Phrase := preload("../../phrase.gd")
const Feedback := preload("../../theme_feedback.gd")

## Progress: how much of a whole is done - a title, a bar whose filled
## length is the share done, and the words saying how many of how many.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE COUNTS ARE THE MODEL'S, two bound values, and the words follow them
## the moment they move: a card let go in Done is counted as it lands. The
## bar GOES to its new length rather than jumping there, on the one clock
## (eased.gd), so the eye sees which way it went; the words are there at
## once. The share is said as well as drawn - "42 of 300, 14%" - so it is
## read without the bar, and in grey. A whole of none is none done.
##
## The bar is drawn in the look's ink under its style: the track, and the
## line over it, as thick as the look says.


## Progress of this title over the counts two bound values read.
static func make(ui: Ui, title: Variant, done: Bound, whole: Bound) -> Desc:
	var style := Feedback.PROGRESS
	var share: Bound = Bound.both(done, whole, shared)
	var said: Bound = Bound.both(done, whole, func(of: Variant, out_of: Variant) -> Phrase: return Phrase.with("%d of %d, %d%%", [of, out_of, roundi(100.0 * shared(of, out_of))]))
	return ui.row([ui.text(title, Themes.FACE), ui.canvas(_paint, ui.eased(share), Feedback.PROGRESS_BAR).grow(), ui.text(said, Themes.REASON)], style)


## The share of a whole this many is: none of a whole of none.
static func shared(of: Variant, out_of: Variant) -> float:
	return 0.0 if int(out_of) == 0 else float(of) / float(out_of)


## The track across the middle of the room, as thick as the look says, and
## the line over it as far along as the share.
static func _paint(control: Control, share: Variant) -> void:
	var thick := float(control.get_theme_constant(&"thick"))
	var track := Rect2(0.0, (control.size.y - thick) / 2.0, control.size.x, thick)
	control.draw_rect(track, control.get_theme_color(&"track"))
	control.draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(float(share), 0.0, 1.0), thick)), control.get_theme_color(&"line"))
