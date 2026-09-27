extends "../../presentation.gd"

const Bound := preload("bound.gd")

## A picture: a texture, or a bound value read again whenever its bells
## ring, drawn to fit its room and keeping its shape.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

var _picture := TextureRect.new()
var _content: Variant  # a Texture2D, or a Bound


func _init(chimes: Chimes, content: Variant, in_region: StringName) -> void:
	super(chimes, [], in_region)
	_content = content
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_picture)


## What is drawn now.
func get_texture() -> Texture2D:
	return _picture.texture


func heard(_what: StringName) -> void:
	needs_refresh()


func refresh() -> void:
	_picture.texture = _content.read() if _content is Bound else _content


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"image").new(ui.chimes, desc.props["content"], ui.region())
	ui.attach(made, parent, desc.facts)
	return made