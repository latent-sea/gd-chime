extends Control

## A pop-up's shade across the band round the safe rect: the look's shade
## painted over all of the window that lies outside this piece's own rect,
## so a pop-up laid in the safe rect darkens the whole window, the cutout
## strip and the corners' arcs included.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT STANDS WHERE THE POP-UP STANDS, under everything in it, and paints only
## OUTSIDE ITSELF: what lies inside is the shade's own press (sheet.gd),
## which would be darkened twice. The window is the viewport it is drawn in,
## so on an easel it is the whole canvas (easel_canvas.gd). It is a child of
## the pop-up, so it fades and hides with it.
##
## It takes no press: a press in the band lands on the canvas's bare ground,
## and the shade's own press, inside the safe rect, is the way out.

## The kind it is built as (ui.gd).
const KIND := &"shade_band"

var _style: StringName  # the shade's look: its panel is what is painted


func _init(style: StringName) -> void:
	_style = style
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# told when it moves, as the safe rect does, since what lies outside it moves with it
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


## The rects it paints, in its own coordinates: the window above, below
## and either side of itself, which with its own rect make the whole window.
func painted() -> Array[Rect2]:
	# the viewport's rect brought into this piece's own coordinates
	var whole: Rect2 = get_global_transform().affine_inverse() * get_viewport_rect()
	var above := Rect2(whole.position.x, whole.position.y, whole.size.x, -whole.position.y)
	var below := Rect2(whole.position.x, size.y, whole.size.x, whole.end.y - size.y)
	var left := Rect2(whole.position.x, 0.0, -whole.position.x, size.y)
	var right := Rect2(size.x, 0.0, whole.end.x - size.x, size.y)
	var bands: Array[Rect2] = []
	# each side the window reaches past this, and no other: a side flush with the window's edge has nothing in it
	bands.assign([above, below, left, right].filter(func(band: Rect2) -> bool: return band.has_area()))
	return bands


func _draw() -> void:
	var box := get_theme_stylebox(&"panel", _style)
	# every side of the window outside this, shaded
	for band: Rect2 in painted():
		draw_style_box(box, band)


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(KIND).new(desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
