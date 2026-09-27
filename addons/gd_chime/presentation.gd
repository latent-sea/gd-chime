extends "hearing.gd"

const Themes := preload("theme.gd")

## The key what a draw read is followed under.
const DRAWN := &"drawn"

## A piece that faces a reader: it draws what it reads of the models' values,
## and draws again once a frame however many of them moved.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## On a Control rather than a Node, because a script may only extend one thing
## and only a Control can draw; hearing.gd, which this extends, is what ties it
## to the chimes. What it read as it drew, and the drawing, are this file's.
##
## WHAT IT READ AS IT DREW, IT FOLLOWS: refresh() reads values - a model's, a
## refusal, a bound value however it was worked out - and every draw runs with
## its reads noted (reads.gd), wired to exactly what it read until the next
## draw replaces them (chimes.gd, follow). Whoever moved one of those values,
## a draw is due. So a control lists nothing it shows, and cannot forget one.
##
## A draw due is needs_refresh(), and the drawing then happens once, on the
## next frame: needs_refresh switches processing on, and a frame with nothing
## due switches it off, so the engine holds the list of what has work and an
## idle screen is not on it.
##
## Processing is given up at the START of a frame that finds nothing due, never
## at the end of one that drew: the engine applies a change to its process list
## at the frame boundary and the last write wins, so giving it up while drawing
## undoes a wake that arrived earlier in the same frame. The cost is one idle
## frame after the last change.
##
## HIDDEN, A DRAW DUE WAITS: still due and still wired to what it last read, it
## draws once as it is shown - inside the engine's telling of that, so the room
## it needs is asked before the layout around it. Being hidden draws nothing:
## what hid it may be taking it away. A hidden one's drawing is read by nobody.
## A control whose own draw hides it says so (shows_itself()), and draws
## though hidden, since only its draw can show it again; one that hides
## itself as it draws without saying so is reported out loud as it hides,
## rather than left frozen out of sight.
##
## It must be IN the tree to draw or to refresh. Whoever builds one parents it,
## and freeing that parent frees this with it - so there is no teardown here
## and nothing to remember.
##
## What a person does to it - a press, the wheel, the pointer, focus - arrives
## at the hooks in interaction.gd, which this extends. This answers only its own notifications: resize and the look.
##
## It follows the look without asking to. The look is the engine's Theme on
## the root, and the engine tells every Control when it changes as it does a
## resize, so a change of look brings a redraw here and no bell is involved. A
## screen asks the look for a colour by name, in refresh() and nowhere else: a
## colour taken sooner is painted once and never follows the look. The engine
## carries a look down through Controls and Windows only - measured - so a
## screen is parented under Controls all the way up, or wears the look itself.
##
## A subclass builds its elements once and reads its models in refresh(). It
## never asks where it sits: position is the business of whatever put it there,
## which is what lets a pooled one be moved and reused. What it arranges is its
## own contents, within whatever rect it has, in arrange().
##
## A rect comes from anchors - ratios of the parent, resolved by the engine - so
## a window resize reaches every screen tied to it without anything publishing
## the window or walking the tree. arrange() is called as this enters the tree
## AND whenever the rect changes: the engine sends no resize notification for a
## first placement, only for later ones.
##
## What room it needs, a screen says ITSELF - and it says it for when it is
## FULL rather than for what it happens to hold now. A layout asks every part
## for its smallest size and gives it at least that, so a screen still waiting
## for its content would otherwise be measured at nothing: its room would
## collapse, the arrangement around it would be chosen on an empty screen, and
## everything would move when the content landed.
##
## Two halves, and the engine holds both. Whoever builds a screen sets
## custom_minimum_size to the room it will need when it is full - a fact about
## the content and the font it is read in, which is why it is in pixels and
## comes from where the scale is known. A screen that can measure what it holds
## overrides the engine's own _get_minimum_size() and works the answer out from
## that. Measured on 4.6.2: the engine takes the larger of the two ON EACH AXIS,
## so measuring raises what was projected and never drops below it, and the
## answer travels up through every layout above.
##
## The engine keeps that answer until it is told otherwise, so a screen whose
## own measurement MOVES - different words, a part added - calls
## update_minimum_size(). Measured: without that call the old answer stands and
## nothing is asked again, and setting custom_minimum_size does the telling for
## you. A change of look needs no call either: the engine asks every control
## again by itself.

## How many draws have run, so that coalescing is something a test can read
## rather than something it argues.
var refresh_count: int = 0

var _due: bool = false


func _init(chimes: Chimes, listening: Array = [], in_region: StringName = Chimes.GLOBAL) -> void:
	set_process(false)
	# a container's default lets a press through; a control takes it
	mouse_filter = Control.MOUSE_FILTER_STOP
	super(chimes, listening, in_region)


## Entering the tree switches processing back on by itself for any script that
## defines _process, so what is due has to be asserted again here.
##
## It draws once as it arrives. Everything it shows may already be there before
## it was built, and a screen that waited for a wake would sit blank until
## something moved - which for anything settled is forever.
func _ready() -> void:
	set_process(_due)
	arrange()
	refresh_now()


## Resized, it arranges; the look changed, it draws; shown, a draw that waited runs
## here - never as it enters the tree, whose draw is _ready's; freed, it is cut loose.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED: arrange()
		NOTIFICATION_THEME_CHANGED: needs_refresh()
		NOTIFICATION_PREDELETE: _chimes.stop_all(self)
		NOTIFICATION_VISIBILITY_CHANGED when _due and is_node_ready() and is_visible_in_tree(): refresh_now()


## Whether its own draw shows and hides it, so that its draw never waits: the
## engine tells a control hidden by itself nothing when its holder is shown.
func shows_itself() -> bool:
	return false


## Arrange whatever this holds within its own rect. Overridden by a subclass
## with contents to place; called when it enters the tree and every time its
## rect changes.
func arrange() -> void:
	pass


## Say that a draw is due. Called any number of times by any number of handlers
## within one frame; the draw happens once.
func needs_refresh() -> void:
	_due = true
	set_process(true)


## Draw now rather than on the next frame, for a controller being set up;
## what the draw read followed, a ring there a draw due. A draw that hid
## this, from a control that never said its draw shows it, is said out loud.
func refresh_now() -> void:
	_due = false
	refresh_count += 1
	var seen := visible
	_chimes.follow(self, DRAWN, refresh, read_moved)
	if seen and not visible and not shows_itself():
		push_error("%s hid itself as it drew, and its shows_itself() says its draw never shows it: its next draw would wait hidden for a showing nothing brings - override shows_itself() to answer true" % get_path())


## Something the last draw read moved: a draw is due. Overridden by a
## control that keeps something else only as long as what it read stands.
func read_moved() -> void:
	needs_refresh()


## Overridden by a subclass. Read its models and put what they say on the
## screen.
func refresh() -> void:
	pass


## A colour of the look, by name, for painting with. A name the look does not
## have is refused out loud and painted in a colour nobody would choose,
## because the engine's own answer to it is a quiet default.
func get_colour(name: StringName) -> Color:
	if not has_theme_color(name, Themes.LOOK):
		push_error("the look has no colour called %s" % name)
		return Color.MAGENTA
	return get_theme_color(name, Themes.LOOK)


## Processing is on only while a draw is due and can be seen, so this runs on
## the first frame after something asked and not again until something asks.
func _process(_delta: float) -> void:
	if _due and (is_visible_in_tree() or shows_itself()):
		refresh_now()
		return
	set_process(false)
