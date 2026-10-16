extends "presentation.gd"

const Value := preload("components/primitives/value.gd")
const OwnBell := preload("components/primitives/own_bell.gd")
const Bound := preload("components/primitives/bound.gd")

## The window's shape, as values anything may bind to: which way round it
## is, how much room it has across, the safe room itself, and whether it is
## touched.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It is a model and it draws NOTHING. It is a Control only because that is
## how the engine tells a script the window changed without a signal being
## connected: a Control spread over the root is resized when the window is,
## and presentation.gd turns that into arrange(). A plain Node would have to
## answer NOTIFICATION_WM_SIZE_CHANGED, which the window manager sends and
## a headless run never does, so nothing about shape could be asserted.
##
## IT STANDS IN THE SAFE RECT. On an easel's canvas it is laid where the app
## is (easel_canvas.gd), inside what the system, the corners, the keyboard
## and the gutter leave, so its own rect is the room a screen has: its size
## is `safe_size`, in base pixels, and how far in it stands from each edge of
## the canvas is `insets`, by the engine's Side. Standing on a window with
## no easel, both are the window's. It is arranged again as that rect moves,
## not only as it is resized, since a phone turned moves its cutout to
## another edge and leaves the room the same size.
##
## THE SIZE CLASS is compact, regular or wide, at the widths the look names
## under the type Shape - compact_below and wide_from - measured on the safe
## room in base pixels. An edge alone would flicker while a window is dragged
## across it, so a class holds until the width is dead_band past the edge it
## came in by.
##
## ORIENTATION AND THE REAL SIZE ARE READ ON THE REAL PIXELS of the viewport
## it stands in: the canvas is drawn at the base size and stretched to the
## rect the app was given (easel.gd), so its own rect tells the room, never
## the device. Orientation is portrait while the window is taller than it is
## wide. The real size is whose window it is by how big it is on its screen:
## a desk's, or a phone's held sideways or upright. It is a desk's while its
## shorter side is at least phone_under_mm and it is at least desk_from_mm
## across; of a phone's two it is sideways while it is at least sideways_from
## hundredths as wide as it is tall. Pixels become millimetres by the
## screen's dots to the inch, which `reads_dpi` answers: the engine's own,
## until a host that knows its screen better sets another. It has no dead
## band, so a window dragged along one of its edges changes at the edge both
## ways. The real size is a fact about the device, for choosing what a device
## can show - a picture live or still - and never for laying anything out.
##
## TOUCH is a bound value, `touch`: true while the screen takes touch, which
## `reads_touchscreen` answers, or while the last press came from a finger.
## It is said on the viewport as well, its meta TOUCH, for a touch target to
## measure by with no bell for each of hundreds; a change measures every
## target again.
##
## IT WRITES NOTHING OUTSIDE ITSELF. The base turning with the rect is the
## easel's (easel.gd), which resizes this control again as it turns; the
## viewport's own pixels did not move, so nothing is read differently and
## no value is set twice. The window belongs to the host, and a model that
## wrote its base would make the window the framework's.
##
## Each of orientation, the class, the real size and touch is a VALUE
## (value.gd), set once per CHANGE, never per pixel: a window dragged wider
## within its class says nothing. The safe room and its insets move with
## every pixel, so they ring a bell of their own, and what reads only the
## others never hears them.
##
## A PHONE'S WINDOW - compact and on its end - is a bound value,
## `whose_window`, PHONE or DESKTOP: a device fact, read by nothing in the
## floor that lays anything out, which answers to its room instead.

const PORTRAIT := &"portrait"
const LANDSCAPE := &"landscape"
const ORIENTATIONS: Array[StringName] = [PORTRAIT, LANDSCAPE]

const COMPACT := &"compact"
const REGULAR := &"regular"
const WIDE := &"wide"
const CLASSES: Array[StringName] = [COMPACT, REGULAR, WIDE]

const DESK := &"desk"
const SIDEWAYS := &"sideways"
const UPRIGHT := &"upright"
const REAL_SIZES: Array[StringName] = [DESK, SIDEWAYS, UPRIGHT]

## The look's type holding where the classes change and how far past an edge a change back must go.
const TYPE := &"Shape"
## Whose window it is: a phone's - compact and on its end.
const PHONE := &"phone"
## The other reading of whose window it is: anything that is not a phone's, a window on a desk.
const DESKTOP := &"desktop"
## The viewport's meta saying whether it is touched, for a touch target to measure by without a bell.
const TOUCH := &"touch"

var _own := OwnBell.new("shape")  # the one bell the values set once per change ring, a model's as a controller's would be
var _room := OwnBell.new("shape room")  # the bell the safe room and its insets ring, moving with every pixel
## Which way round the window is: portrait or landscape.
var orientation := Value.new(_own, &"")
## How much room it has across: compact, regular or wide.
var size_class := Value.new(_own, &"")
## How big it really is on its screen: a desk's window, or a phone's held sideways or upright.
var real_size := Value.new(_own, &"")
## The safe room, in base pixels: what a screen has to stand in.
var safe_size := Value.new(_room, Vector2.ZERO)
## How far in from each edge of the canvas the safe room stands, in base pixels, by Side.
var insets := Value.new(_room, PackedFloat32Array([0.0, 0.0, 0.0, 0.0]))
## The dots to the inch of the screen the window is on, asked each time the window changes.
var reads_dpi: Callable = DisplayServer.screen_get_dpi
## Whether the screen takes touch, asked each time the window changes.
var reads_touchscreen: Callable = DisplayServer.is_touchscreen_available
var _touchscreen := Value.new(_own, false)  # whether the screen takes touch, as last asked
var _finger := Value.new(_own, false)  # whether the last press came from a finger
## Whether the window is on its end, ready to bind to: the one thing nearly
## every caller of orientation wanted, written out as a comparison each time.
var portrait: Bound = orientation.map(func(turned: Variant) -> bool: return turned == PORTRAIT)
## Whose window it is: a phone's while it is compact and on its end, else a
## desktop's - the meta as a value to arrange by.
var whose_window: Bound = Bound.all([orientation, size_class], func(turned: Variant, classed: Variant) -> Variant: return PHONE if turned == PORTRAIT and classed == COMPACT else DESKTOP)
## Whether it is touched: the screen takes touch, or the last press came from a finger.
var touch: Bound = Bound.all([_touchscreen, _finger], func(takes: Variant, fingered: Variant) -> bool: return takes or fingered)


func _init(chimes: Chimes, in_region: StringName = Chimes.GLOBAL) -> void:
	super(chimes, [], in_region)
	_own.hang(chimes)
	_room.hang(chimes)
	# it is over the whole window and no part of it is anybody's to press
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# moved without being resized - a cutout gone to the other edge - it is arranged again
	set_notify_local_transform(true)


## The base size the canvas is drawn at now, which turns with the rect.
func get_base() -> Vector2i:
	return Vector2i(get_viewport().get_visible_rect().size)


## The viewport or the safe rect changed: each value worked out again, and each that moved set.
func arrange() -> void:
	var viewport := get_viewport()
	var pixels := Vector2i(viewport.get_visible_rect().size * viewport.get_final_transform().get_scale())
	var turned: StringName = PORTRAIT if pixels.y > pixels.x else LANDSCAPE
	var classed := _class_at(size.x)
	# the window in millimetres on its screen: 25.4 of them to the inch
	var real := Vector2(pixels) * 25.4 / float(reads_dpi.call())
	var sized: StringName = SIDEWAYS if real.x * 100.0 >= real.y * get_theme_constant(&"sideways_from", TYPE) else UPRIGHT
	if minf(real.x, real.y) >= get_theme_constant(&"phone_under_mm", TYPE) and real.x >= get_theme_constant(&"desk_from_mm", TYPE):
		sized = DESK
	var area := get_parent_area_size()
	# how far in from each edge of what holds it this stands, by Side
	var inset := PackedFloat32Array([position.x, position.y, area.x - position.x - size.x, area.y - position.y - size.y])
	var turning: bool = turned != orientation.read()
	var reclassing: bool = classed != size_class.read()
	var resizing: bool = sized != real_size.read()
	var taking: bool = reads_touchscreen.call()
	# all set before anything reads them, because a value set tells its readers at once
	if turning:
		orientation.set_value(turned)
	if reclassing:
		size_class.set_value(classed)
	if resizing:
		real_size.set_value(sized)
	if size != safe_size.read():
		safe_size.set_value(size)
	if inset != insets.read():
		insets.set_value(inset)
	if taking != _touchscreen.read():
		_touchscreen.set_value(taking)
	_touch_said()


## Whether it is touched, said on the viewport where it moved, and every touch target measured again.
func _touch_said() -> void:
	var touched: bool = touch.read()
	if touched != get_viewport().get_meta(TOUCH, false):
		get_viewport().set_meta(TOUCH, touched)
		get_tree().call_group(Touch.TARGETS, &"update_minimum_size")


## A press says which pointer is in use: a finger's, or a mouse's.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Touch.from_finger(event) != _finger.read():
		_finger.set_value(Touch.from_finger(event))
		_touch_said()


## Moved without being resized: arranged again, for the insets - once it is
## ready, since it is arranged as it arrives and placed before it does.
func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED and is_node_ready():
		arrange()


## The class at this width, the class it is in now holding its ground by the
## dead band: the edge a class came in by is that much further out to leave by.
func _class_at(width: float) -> StringName:
	var band := get_theme_constant(&"dead_band", TYPE)
	var narrow := get_theme_constant(&"compact_below", TYPE) + (band if size_class.read() == COMPACT else 0)
	var broad := get_theme_constant(&"wide_from", TYPE) - (band if size_class.read() == WIDE else 0)
	if width < narrow:
		return COMPACT
	return WIDE if width >= broad else REGULAR
