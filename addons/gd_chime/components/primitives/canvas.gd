extends "../../presentation.gd"

const Bound := preload("bound.gd")

## Custom drawing: a function handed this control to draw on, called again
## whenever the bound value it reads has changed.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The function draws with the control's own draw calls - lines, arcs,
## boxes - reading the value; it is a recipe's, and the one place a recipe
## touches drawing. Its colours it asks of the look under the canvas's
## style, a Theme name, never by a palette name. Given no bound value, it
## draws once and when resized.
##
## It needs no room of its own but the height its style's look gives as
## "least_height", in base pixels - none unless a look says - so a drawing
## laid in a line that takes its parts' least, a trend under a figure, is
## never drawn at no height at all.

var _paint: Callable
var _content: Variant
var _shown: Variant  # the value as last read, which a draw paints


func _init(chimes: Chimes, paint: Callable, content: Variant, in_region: StringName, style: StringName = &"") -> void:
	super(chimes, [], in_region)
	_paint = paint
	_content = content
	if style != &"":
		theme_type_variation = style
	set_anchors_preset(Control.PRESET_FULL_RECT)


func heard(_what: StringName) -> void:
	needs_refresh()


## The value read as this refreshes, so what it read is followed, and drawn
## with; a resize draws the value as last read.
func refresh() -> void:
	_shown = _content.read() if _content is Bound else _content
	queue_redraw()


func _get_minimum_size() -> Vector2:
	return Vector2(0.0, get_theme_constant(&"least_height"))


func _draw() -> void:
	_paint.call(self, _shown)


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"canvas").new(ui.chimes, desc.props["paint"], desc.props["content"], ui.region(), desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made