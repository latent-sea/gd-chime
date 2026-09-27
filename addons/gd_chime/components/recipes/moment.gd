extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Sheet := preload("sheet.gd")
const Motion := preload("../../motion.gd")
const Keyframes := preload("../primitives/keyframes.gd")

## A moment: something presented at a boundary and handed on from - not a
## place the reader goes. It has no row and no way in: it arrives while its
## model says so, is read, and is dismissed by one press, which is a command
## to the model. It never enters the history.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT GOES THROUGH THE CHART like everything standing over the screen: a
## pop-up PRESENTED while the model's fact holds (place_builder.gd), raised
## by the driver at the end of the frame the fact came to hold in and
## lowered at the end of the one it stopped in, whoever moved it - a press,
## the game's tick, a job landing (driver.gd) - so it blocks what is
## beneath, takes the focus and gives it back as any pop-up does. ITS WAY OUT IS ITS MODEL'S: the dismissing press. It declares no
## other and its shade is ground, not a press, since going back alone would
## leave the fact holding and the moment raised again at once.
##
## It is a sheet over everything (sheet.gd) showing what the boundary is
## about - composed of existing pieces, nothing of its own.
##
## ITS ENTRANCE IS CHOREOGRAPHED, three keyframe tracks deep
## (keyframes.gd), run again each time the pop-up is shown: the shade comes
## up over the app, what stands on it settles into place by the look's
## emphasis, and its lines arrive one after another, each a stagger behind
## the one above. The lines only ever FADE in - a line that slid or grew
## would be drawn over the line under it on the way, and nothing may ever be
## drawn over anything else.

## The shade coming up, and each line after it.
const ARRIVES := [{&"at": 0.0, Keyframes.OPACITY: 0.0}, {&"at": 1.0, Keyframes.OPACITY: 1.0}]
## What stands on the shade, settling in from a little small.
const SETTLES := [{&"at": 0.0, Keyframes.OPACITY: 0.0, Keyframes.SCALE: &"settle_scale"}, {&"at": 1.0, Keyframes.OPACITY: 1.0, Keyframes.SCALE: 1.0}]
## What a moment's pop-up is of, in its name.
const KIND := &"moment"


## The moment's pop-up, up while the model's fact holds: what it shows, and
## the model's action dismissing it.
static func make(ui: Ui, presented: Bound, content: Array, dismisses: StringName) -> Desc:
	var style := &"Moment"
	var lines: Array = []
	# every line it shows and then the way on, each one a stagger further behind than the last
	for place: int in content.size() + 1:
		var line: Desc = content[place] if place < content.size() else ui.button(dismisses)
		lines.append(ui.keyframes([line], ARRIVES, &"normal", {easing = Motion.ENTER, timed_by = Motion.TYPE, loops = 1, held = null, after = place + 1}))
	var standing: Desc = ui.keyframes([ui.column(lines)], SETTLES, &"slow", {easing = Motion.EMPHASIS})
	var over: Desc = ui.keyframes([Sheet.over(ui, [standing], style, ui.surface(Sheet.SHADE))], ARRIVES, &"normal", {easing = Motion.ENTER})
	var made := ui.pop_up(KIND, func(_which: Bound) -> Desc: return over)
	# up while the fact holds, raised and lowered by the driver as the fact moves
	made.props["presented"] = presented
	return made
