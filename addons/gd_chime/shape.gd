extends "presentation.gd"

const Value := preload("components/primitives/value.gd")
const OwnBell := preload("components/primitives/own_bell.gd")
const Bound := preload("components/primitives/bound.gd")

## The window's shape, as two values anything may bind to: which way round
## it is, and how much room it has across.
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
## IT READS THE REAL PIXELS OF THE VIEWPORT IT STANDS IN, not its own rect.
## The canvas is drawn at the base size and stretched to the rect the app
## was given (easel.gd), so this control's own width is the base width
## whenever that rect is the narrow way round - it tells you the shape of
## the canvas, which is a consequence, not the room a person actually has.
## The viewport is the app's own: a game that puts the app in a side
## panel gets a portrait app in a landscape window, which is right.
##
## ORIENTATION is portrait while the window is taller than it is wide.
## THE SIZE CLASS is compact, regular or wide, at the widths the look names
## under the type Shape - compact_below and wide_from, in base pixels. An
## edge alone would flicker while a window is dragged across it, so a class
## holds until the width is dead_band past the edge it came in by.
##
## IT WRITES NOTHING OUTSIDE ITSELF. The base turning with the rect is the
## easel's (easel.gd), which resizes this control again as it turns; the
## viewport's own pixels did not move, so nothing is read differently and
## no value is set twice. The window belongs to the host, and a model that
## wrote its base would make the window the framework's.
##
## Each is a VALUE (value.gd), set once per CHANGE, never per pixel: a
## window dragged wider within its class says nothing.
##
## A PHONE'S WINDOW - compact and on its end - is said on the viewport as
## well, its meta PHONE, for a touch target to measure by (pressable.gd)
## with no bell for each of hundreds; a change measures every target again.
## A narrow window on its side is a desktop's narrowed, not a phone's. It
## is a bound value too, `whose_window`, for anything ARRANGED one way on a
## phone and another on a desktop: a bottom sheet is edge to edge on a
## phone and capped in the middle of a desktop's window (drawer.gd). It is
## not a width a piece can measure for itself - the canvas is drawn at the
## base size and stretched, so a phone's own width is 1080 base pixels,
## past where a look says a window is compact.
##

const PORTRAIT := &"portrait"
const LANDSCAPE := &"landscape"
const ORIENTATIONS: Array[StringName] = [PORTRAIT, LANDSCAPE]

const COMPACT := &"compact"
const REGULAR := &"regular"
const WIDE := &"wide"
const CLASSES: Array[StringName] = [COMPACT, REGULAR, WIDE]

## The look's type holding where the classes change and how far past an edge a change back must go.
const TYPE := &"Shape"
## The viewport's meta saying whether it is a phone's - compact and on its end - for what measures by it without a bell: a touch target.
const PHONE := &"phone"
## The other reading of whose window it is: anything that is not a phone's, a window on a desk.
const DESKTOP := &"desktop"

var _own := OwnBell.new("shape")  # the one bell both values ring, a model's as a controller's would be
## Which way round the window is: portrait or landscape.
var orientation := Value.new(_own, &"")
## How much room it has across: compact, regular or wide.
var size_class := Value.new(_own, &"")
## Whether the window is on its end, ready to bind to: the one thing nearly
## every caller of orientation wanted, written out as a comparison each time.
var portrait: Bound = orientation.map(func(turned: Variant) -> bool: return turned == PORTRAIT)
## Whose window it is: a phone's while it is compact and on its end, else a
## desktop's - the meta as a value to arrange by.
var whose_window: Bound = Bound.all([orientation, size_class], func(turned: Variant, classed: Variant) -> Variant: return PHONE if turned == PORTRAIT and classed == COMPACT else DESKTOP)


func _init(chimes: Chimes, in_region: StringName = Chimes.GLOBAL) -> void:
	super(chimes, [], in_region)
	_own.hang(chimes)
	# it is over the whole window and no part of it is anybody's to press
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The base size the canvas is drawn at now, which turns with the rect.
func get_base() -> Vector2i:
	return Vector2i(get_viewport().get_visible_rect().size)


## The viewport changed: each value worked out again, and each that moved set.
func arrange() -> void:
	var viewport := get_viewport()
	var pixels := Vector2i(viewport.get_visible_rect().size * viewport.get_final_transform().get_scale())
	var turned: StringName = PORTRAIT if pixels.y > pixels.x else LANDSCAPE
	var classed := _class_at(pixels.x)
	var turning: bool = turned != orientation.read()
	var reclassing: bool = classed != size_class.read()
	# both set before anything reads them, because a value set tells its readers at once
	if turning:
		orientation.set_value(turned)
	if reclassing:
		size_class.set_value(classed)
	var phone: bool = whose_window.read() == PHONE
	if phone != viewport.get_meta(PHONE, false):
		# kept on the viewport for whatever measures by it, and every touch target measured again
		viewport.set_meta(PHONE, phone)
		get_tree().call_group(Touch.TARGETS, &"update_minimum_size")


## The class at this width, the class it is in now holding its ground by the
## dead band: the edge a class came in by is that much further out to leave by.
func _class_at(width: int) -> StringName:
	var band := get_theme_constant(&"dead_band", TYPE)
	var narrow := get_theme_constant(&"compact_below", TYPE) + (band if size_class.read() == COMPACT else 0)
	var broad := get_theme_constant(&"wide_from", TYPE) - (band if size_class.read() == WIDE else 0)
	if width < narrow:
		return COMPACT
	return WIDE if width >= broad else REGULAR
