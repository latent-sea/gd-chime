extends RefCounted

const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The gallery's own screens as it lays them out: every piece in a box with
## its name and what to try, and the boxes in two columns on a wide window
## and in one on a window on its end (by_shape.gd). The screens only the
## gallery shows extend this - MOTION, OPTIONS and CARRYING (extra_pieces.gd),
## the controls that set a value (values_pieces.gd), running words and marks
## (marks_pieces.gd), and what arrives (arrivals_pieces.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It holds the stall and nothing else, and builds nothing until asked. What
## to try is said as the stall's pieces say it (pieces.gd's prose): one line
## on a wide window, broken onto more on one on its end. No words here say
## where anything stands: a layout that turns would make them wrong.

var _stall: SceneTree


func _init(stall: SceneTree) -> void:
	_stall = stall


## One piece shown: its name, what to try, and the thing itself on a ground.
func _shown(title: Phrase, hint: Phrase, content: Desc) -> Desc:
	var ui: RefCounted = _stall.ui
	return ui.surface(Themes.RAISED, [ui.column([ui.text(title, Themes.TITLE), _stall.pieces.prose(hint, DemoTheme.READOUT), content], DemoTheme.TIGHT)])


## A screen of boxes in two columns on a wide window and in one on a window
## on its end, scrolling where they are more than its room, answered by this
## model and doing this as it fills, if either.
func _columns(named: StringName, first: Array, second: Array, handled_by: Object = null, on_fill: Callable = Callable()) -> Desc:
	var ui: RefCounted = _stall.ui
	var parts := {&"first": ui.column(first), &"second": ui.column(second)}
	var halves := {&"first": {"grow": 1.0}, &"second": {"grow": 1.0}}
	var arranged: Desc = ui.by_shape(parts, {Shape.LANDSCAPE: ui.row_of(parts.keys(), halves), Shape.PORTRAIT: ui.column_of(parts.keys())})
	# taller than its room in a roomy look on a window on its end: it scrolls rather than pushing the bar at the foot off the window
	return ui.screen(named, [ui.scroll(arranged)], handled_by, {on_fill = on_fill})
