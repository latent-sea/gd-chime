extends SubViewportContainer

const Themes := preload("theme.gd")

## The easel: the rect a host gives an application, with the application's
## canvas drawn at the base size on it and stretched to fit - the window's
## canvas_items stretch, scoped to one node's rect.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE WINDOW BELONGS TO THE HOST. An easel never writes the window's stretch
## mode or base size, its clear colour or the input map: it owns exactly its
## own subtree, and nothing outside it can notice it is there. So a game
## hosts one beside its own scenes, in a side panel or over the whole
## window, and two of them in one window have nothing to fight over.
##
## HOW IT SCALES. Its viewport renders at the real pixels of its rect, so
## words stay crisp, and draws its canvas at the BASE SIZE - the project's
## `display/window/size` - stretched to fit, the way the window's
## canvas_items stretch with aspect expand does: the canvas is scaled by the
## same factor each way, covers the whole rect, and grows past the base
## along whichever side has the room. A layout in shares of the canvas is
## therefore a layout in shares of the rect, and a size written once in the
## theme is a size on every screen. The container forwards input, so
## nothing about pressing changes.
##
## TURNING SWAPS THE BASE. A rect on its end drawn at a landscape base would
## be fitted by the width, every word shrunk to a stamp; so the base turns
## with the rect - the project's base, or its transpose - and a line of
## words keeps the same share of the short side either way round. A frame
## after a turn, everything on the canvas is asked what it needs again: the
## turn re-arranges screens not shown as well as the one that is, and the
## engine says nothing of a hidden thing's needs moving.
##
## THE GROUND IS ITS OWN. The canvas paints the look's ground across the
## whole rect, so a light look is light to the edge where nothing draws; the
## window's clear colour is never touched. The look is the canvas's Theme -
## a Theme reaches nothing through a viewport, so it is worn inside it.
##
## Chosen against: reading the window's size and writing its base, which
## was shape.gd's way and made the window the framework's; a host that has
## stretched its window scales this twice, which is why the settings the
## framework needs say the window is not stretched (needed_settings.gd).

## The project's base: what `display/window/size` says, read once.
const WIDTH := "display/window/size/viewport_width"
const HEIGHT := "display/window/size/viewport_height"

## The viewport the canvas is drawn in, at the rect's real pixels.
var viewport := SubViewport.new()
## The canvas everything is built on, spread over the viewport, wearing the look.
var canvas := Canvas.new()
var _base: Vector2i  # the project's base, landscape
var _turned: bool = false  # whether the base stands transposed now


## The surface every application stands on: the ground painted from the
## look it wears, again whenever the look changes. It says what it draws
## as a face does (get_drawn), so whatever judges words against the ground
## they stand on (faint_words.gd) reads the canvas's ground and never the
## window's clear colour, which is the host's and says nothing of the app.
class Canvas extends Control:
	var _ground := StyleBoxFlat.new()  # the one box drawn across the whole canvas, the look's ground

	func _draw() -> void:
		if has_theme_color(&"ground", Themes.LOOK):
			_ground.bg_color = get_theme_color(&"ground", Themes.LOOK)
			draw_style_box(_ground, Rect2(Vector2.ZERO, size))

	## The boxes drawn across the whole of this: the ground, where the look gives one.
	func get_drawn() -> Array[StyleBox]:
		var drawn: Array[StyleBox] = []
		if has_theme_color(&"ground", Themes.LOOK):
			_ground.bg_color = get_theme_color(&"ground", Themes.LOOK)
			drawn.append(_ground)
		return drawn

	func _notification(what: int) -> void:
		if what == NOTIFICATION_THEME_CHANGED:
			queue_redraw()


func _init() -> void:
	_base = Vector2i(ProjectSettings.get_setting(WIDTH), ProjectSettings.get_setting(HEIGHT))
	stretch = true
	viewport.size_2d_override_stretch = true
	viewport.size_2d_override = _base
	add_child(viewport)
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(canvas)


## The base the canvas is drawn at now: the project's, or its transpose while the rect is on its end.
func get_base() -> Vector2i:
	return Vector2i(_base.y, _base.x) if _turned else _base


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit()


## The canvas fitted to the rect: the base turned with it, and the override
## grown past the base along the side with room, so one scale covers the rect.
func _fit() -> void:
	var turning: bool = (size.y > size.x) != _turned
	_turned = size.y > size.x
	var base := Vector2(get_base())
	# the one scale that fits the base inside the rect; the canvas grows past the base along the other side
	var scale: float = minf(size.x / base.x, size.y / base.y)
	viewport.size_2d_override = Vector2i((size / scale).round())
	if turning:
		_measure_again.call_deferred()


## Once the turn has been laid out, everything on the canvas asked what it
## needs again - and so re-placed by it, a page as tall as it now needs.
## DEFERRED, NEVER AWAITED: the deferred call is dropped if this is freed
## before the end of the frame.
func _measure_again() -> void:
	# every piece standing on the canvas
	for piece: Node in canvas.get_children():
		if piece is Control:
			(piece as Control).update_minimum_size()
