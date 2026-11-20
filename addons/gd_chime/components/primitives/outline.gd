extends Control

const Styled := preload("styled.gd")
const Bound := preload("bound.gd")

## An outline: a look's box drawn OVER whatever stands under it - the frame
## round the one chosen - taking no room and no press.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHAT IS CHOSEN IS MARKED WITHOUT MOVING ANYTHING. A ground drawn under
## what it holds (surface.gd) loses its edge wherever a picture or a strip
## is laid to that edge, and a chosen box with a thicker border than the
## one at rest moves what it holds. This is laid LAST among what it frames,
## across the whole of it, so its edge is drawn over them on all four
## sides; it asks for no room, so chosen or not everything under it stands
## where it stood; and it takes no pointer, so what is under it is pressed
## as ever.
##
## Its look is the panel of its style, a variation of Outline: a ring, a
## box with no middle (look_boxes.gd's ring). The style may be bound, and
## SHOWN, a bound value, has it drawn only while that holds - the one
## chosen framed, the others not. Not shown it draws nothing and stays
## where it is: whether it is visible is its holder's to say, as a plan
## says it of every piece it lays (planned.gd), and is never set here.
##
## It must never draw a middle over what it frames: a style whose panel
## fills is reported out loud as it is drawn.

## The theme type its look is set under, and the base of every outline's style.
const TYPE := &"Outline"

var _style: Variant  # the style described - a name, or a Bound reading one
var _shown: Variant  # a Bound it is drawn while, or null for always
var _chimes: RefCounted


func _init(style: Variant, shown: Variant, chimes: RefCounted) -> void:
	_style = style
	_shown = shown
	_chimes = chimes
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	chimes.follow(self, &"outline", _read)


## Whether it is drawn now.
func is_shown() -> bool:
	return _shown == null or _shown.read() == true


## Its style and whether it shows read, so both are followed, and drawn again.
func _read() -> void:
	theme_type_variation = Styled.name_of(_style)
	is_shown()
	queue_redraw()


func _draw() -> void:
	if not is_shown():
		return
	var panel := get_theme_stylebox(&"panel")
	if panel is StyleBoxFlat and (panel as StyleBoxFlat).draw_center:
		push_error("the outline style %s fills its middle, which would cover what it frames" % theme_type_variation)
		return
	draw_style_box(panel, Rect2(Vector2.ZERO, size))


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _chimes != null:
		_chimes.stop_all(self)


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"outline").new(desc.props["style"], desc.props["shown"], ui.chimes)
	ui.attach(made, parent, desc.facts)
	return made
