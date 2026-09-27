extends Theme

const Themes := preload("res://addons/gd_chime/theme.gd")
const Look := preload("res://addons/gd_chime/look.gd")
const Paint := preload("res://addons/gd_chime/paint.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const MotionTokens := preload("res://addons/gd_chime/motion_tokens.gd")
const Transition := preload("res://addons/gd_chime/components/primitives/transition.gd")

## The demos' look: the floor's placeholder defaults, and the kinds of words
## and the grounds the demos draw on top of them, from one palette.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The floor's theme holds defaults for the floor's own controls alone; a
## demo, like any application, builds its Theme over those (merge_with) and
## adds the types it draws. The demos share one: a readout line, a table or
## list line, a dial's title and its number, each a variation of Label sized
## once at the base window size the engine scales. A LOOK - a design
## language - extends this with its own palette and then varies what its
## language changes, in the vocabulary of look.gd; the gallery shows ten.
##
## HOW A LOOK MOVES IS PART OF THE LANGUAGE, so a look says it in one call at
## the end of its own _init, over the floor's defaults: moves().

const READOUT := &"Readout"
const LINE := &"Line"
## The demos' grounds: the shade under a pop-up, and a pop-up's sheet. A
## raised panel and a card are the floor's (theme.gd), as are a title, a
## number and a centred row.
const SHADE := &"Shade"
const PANEL := &"Sheet"
const GROUNDS := {SHADE: &"shade", PANEL: &"accent"}
## A column with next to no gap.
const TIGHT := &"Tight"
## A question before a press: its sheet padded.
const CONFIRM := &"Confirm"
## The size of each kind at the base window size.
const SIZES := {READOUT: 22, LINE: 24}

## The palette this was built from, for a look to read its own colours back.
var palette: Dictionary


func _init(colours: Dictionary = Themes.NEUTRAL) -> void:
	palette = colours
	var floor_look := Themes.new(colours)
	merge_with(floor_look)
	# the floor's sounds, which a Theme keeps as metadata and merging leaves behind (look_sounds.gd)
	for key: StringName in floor_look.get_meta_list():
		set_meta(key, floor_look.get_meta(key))
	# every kind of words the demos draw, a Label sized once
	for kind: StringName in SIZES:
		Look.words(self, kind, SIZES[kind])
	# every ground, a surface in one of the palette's colours
	for ground: StringName in GROUNDS:
		Look.ground(self, ground, Look.flat(colours[GROUNDS[ground]]))
	Look.line(self, TIGHT, Themes.COLUMN, {gap = 2})
	Look.ground(self, CONFIRM, Look.flat(colours[&"lit"], {"pad": 24}))


## How this look moves: its three durations and its stagger in milliseconds,
## each easing as [curve, ease, which of the durations it lasts], and the
## transition each thing that swaps arrives and goes by. Said last, so it is
## over the floor's defaults rather than under them.
func moves(durations: Dictionary, easings: Dictionary, swaps: Dictionary) -> void:
	MotionTokens.write(self, durations, easings)
	Transition.defaults(self, swaps)
