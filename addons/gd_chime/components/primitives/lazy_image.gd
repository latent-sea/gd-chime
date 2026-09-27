extends "../../presentation.gd"

const Bound := preload("bound.gd")
const Motion := preload("../../motion.gd")
const Transition := preload("transition.gd")
const ImageLoads := preload("../../image_loads.gd")
const Nearness := preload("nearness.gd")

## A picture that loads as the reader nears it: the look's box standing in
## until it lands, then the picture filling the box - cut to its shape,
## never stretched - fading in over it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHAT IT SHOWS is a key, a bound value - a card's product - of pictures
## an image loads model makes (image_loads.gd); which SIZE is the smallest
## of the sizes it is given that is as wide as it is drawn on the screen,
## the largest where none is, so a card asks for a card's picture and a
## quick view for a large one. It claims the picture only while it is NEAR
## the reader (nearness.gd) and lets it go as it moves away, as its key
## moves, or as its size does - so what is far from the reader is never
## held for it.
##
## ITS SHAPE is its style's: as tall as its "aspect" - in thousandths of
## its width - makes it, so a card's picture keeps its shape at any width;
## or, with none, its "least_height"; and never narrower than its
## "least_width", which a thumbnail in a row needs, given no width by it.
##
## ITS BOX is its style's panel, drawn under the picture and cutting it to
## its shape: the rounded corners of a card are the picture's too. While
## nothing has landed the box is all there is - the skeleton of the
## picture to come.
##
## Deliberately absent: a picture that could not be made - a maker answers one.

var motion: Motion = null
var _loads: ImageLoads
var _key: Bound
var _sizes: Array  # the sizes it may ask for, in pixels square, least first
var _style: StringName
var _picture := TextureRect.new()
var _near: Nearness
var _claimed: Array = []  # [key, size] claimed now, or empty


func _init(chimes: Chimes, loads: ImageLoads, key: Bound, sizes: Array, style: StringName, in_region: StringName) -> void:
	super(chimes, [[loads.region, ImageLoads.LANDED]], in_region)
	_loads = loads
	_key = key
	_sizes = sizes.duplicate()
	_sizes.sort()
	_style = style
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_picture)
	_near = Nearness.new(self, func(_near_now: bool) -> void: _claim())
	# the key followed: claimed again as what it read moves
	_chimes.follow(self, &"key", _claim)


## What is drawn now: the picture, or null while its box stands in.
func get_texture() -> Texture2D:
	return _picture.texture


## The picture it claims now, [key, size], or empty while it claims none.
func get_claimed() -> Array:
	return _claimed


## Its scroll moved: near again or not.
func near_moved() -> void:
	_near.check()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE: _near.entered.call_deferred()
		NOTIFICATION_EXIT_TREE:
			_near.left()
			_claim()
		NOTIFICATION_VISIBILITY_CHANGED: _near.check()
		NOTIFICATION_RESIZED:
			update_minimum_size()
			_near.check()
			_claim()


## As tall as its style's aspect makes its width - thousandths of it - or, with none, the style's least height.
func _get_minimum_size() -> Vector2:
	var aspect := get_theme_constant(&"aspect", _style) / 1000.0
	var wide := maxf(size.x, float(get_theme_constant(&"least_width", _style)))
	return Vector2(float(get_theme_constant(&"least_width", _style)), wide * aspect if aspect > 0.0 else float(get_theme_constant(&"least_height", _style)))


## A picture landed: claimed again, and drawn.
func heard(_what: StringName) -> void:
	_claim()
	needs_refresh()


## The picture this should claim now - its key's, at its size, while near - claimed, and the one before let go.
func _claim() -> void:
	var key: Variant = _key.read()
	var wanted: Array = [key, _size()] if _near.is_near() and key != null else []
	if wanted == _claimed:
		return
	if not _claimed.is_empty():
		_loads.let_go(_claimed[0], _claimed[1], self)
	_claimed = wanted
	if not wanted.is_empty():
		_loads.want(wanted[0], wanted[1], self)
	needs_refresh()


## The least size as wide as this is drawn on the screen, or the largest.
func _size() -> int:
	var drawn := size.x * (get_viewport().get_final_transform() * get_global_transform_with_canvas()).get_scale().x
	var fits: Array = _sizes.filter(func(one: int) -> bool: return one >= drawn)
	return fits[0] if not fits.is_empty() else _sizes[-1]


## The picture claimed, if it has landed; faded in as it first shows.
func refresh() -> void:
	var landed: Texture2D = null if _claimed.is_empty() else _loads.texture_of(_claimed[0], _claimed[1])
	if landed == _picture.texture:
		return
	_picture.texture = landed
	if landed != null and motion != null:
		Transition.enter(_picture, Transition.FADE, motion)


func _draw() -> void:
	draw_style_box(get_theme_stylebox(&"panel", _style), Rect2(Vector2.ZERO, size))


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"lazy_image").new(ui.chimes, desc.props["loads"], desc.props["key"], desc.props["sizes"], desc.props["style"], ui.region())
	ui.attach(made, parent, desc.facts)
	return made
