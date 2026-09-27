extends StyleBox

## A stylebox drawn by layers: each a stylebox of the engine's drawn at an
## offset, or a painter given the canvas, the rect and the theme, in order, so
## a look that needs two shadows, a bracketed corner, a dashed edge or a bevel
## is made of the engine's own boxes and a few lines, never a texture.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The engine's flat box draws one fill, one border and one shadow. A
## design language that wants more - neumorphism's paired light and dark
## shadows, a HUD's corner brackets, neo-brutalism's hard offset shadow
## under a plain border - layers those, and every layer is one of the
## engine's boxes or one painter. A painter is a function of (canvas item
## RID, rect, theme) that draws with the RenderingServer; the painters the
## floor knows are paint.gd's.
##
## IT CARRIES THE THEME TO THE PAINTERS. A painter is given an ink - a name -
## and reads the colour on every draw, and a StyleBox is handed no Control to
## ask. So this is told which theme it was built into (look.gd's `layered`),
## and told again by anything that re-colours a theme in place. It holds it
## WEAKLY: the theme holds this box, and holding the theme back would leave
## neither of them ever freed.

var _layers: Array = []  # each [StyleBox, Vector2 offset] or a Callable painter
var _look: WeakRef


func _init(layers: Array, theme: Theme) -> void:
	_layers = layers
	_look = weakref(theme)


## The theme its painters read their colours from: the one it was built into,
## or the one that re-coloured it last.
func set_look(theme: Theme) -> void:
	_look = weakref(theme)


func get_look() -> Theme:
	return _look.get_ref() as Theme


## How far any box draws past the rect it is given on this side (SIDE_LEFT,
## SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM): a flat box its expand margin and its
## shadow, moved by the shadow's offset; one of these, its layers'; a
## painter or any other box, nothing past it.
static func reach_of(box: StyleBox, side: int) -> float:
	if box.has_method(&"get_reach"):
		return box.get_reach(side)
	if not box is StyleBoxFlat:
		return 0.0
	var flat := box as StyleBoxFlat
	# how far the shadow is moved toward this side: its offset, turned to face the side
	var toward: float = [-flat.shadow_offset.x, -flat.shadow_offset.y, flat.shadow_offset.x, flat.shadow_offset.y][side]
	var shadow := flat.shadow_size + toward if flat.shadow_size > 0 and flat.shadow_color.a > 0.0 else 0.0
	return flat.get_expand_margin(side) + maxf(0.0, shadow)


## How far this draws past its rect on this side: the most of its layers,
## each moved by its own offset toward the side or away from it.
func get_reach(side: int) -> float:
	var reach := 0.0
	# every layer that is a box, for the furthest any of them reaches
	for layer: Variant in _layers:
		if layer is Array:
			var moved: Vector2 = layer[1]
			reach = maxf(reach, reach_of(layer[0], side) + [-moved.x, -moved.y, moved.x, moved.y][side])
	return reach


## The colour this lays under whatever stands on it: each layer that fills,
## laid over the one before. A painter draws a bevel, a rule or a hatch and
## fills nothing, so it lays no ground - what is behind this shows through
## it, and that is what a reader's words are read against (faint_words.gd).
func get_fill() -> Color:
	var under := Color.TRANSPARENT
	# every layer that is a box, its own fill over what is under it - one of these among them, which fills by this same rule: a look layers a bar or a rule over a box it already made
	for layer: Variant in _layers:
		if layer is Array and layer[0] is StyleBoxFlat:
			under = under.blend((layer[0] as StyleBoxFlat).bg_color)
		elif layer is Array and layer[0].has_method(&"get_fill"):
			under = under.blend((layer[0] as StyleBox).get_fill())
	return under


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var look := get_look()
	# every layer in order, the later over the earlier
	for layer: Variant in _layers:
		if layer is Callable:
			(layer as Callable).call(to_canvas_item, rect, look)
		else:
			(layer[0] as StyleBox).draw(to_canvas_item, Rect2(rect.position + (layer[1] as Vector2), rect.size))
