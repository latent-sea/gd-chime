extends Container

const Motion := preload("../../motion.gd")
const Outgoing := preload("outgoing.gd")
const Themes := preload("../../theme.gd")
const Inset := preload("inset.gd")
const Styled := preload("styled.gd")
const Bound := preload("bound.gd")

## A ground: a stylebox drawn under whatever it holds, by a Theme name.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The style is a variation of Control holding the stylebox panel. It takes
## no press: what it holds does, or whatever is under it. Its content sits
## across it, and it needs as much room as its content does. A style the
## look does not know is drawn as a surface. A style with a blur constant
## blurs what is behind it by that much before the panel is drawn over -
## frosted glass - through one shader on a rect under everything.

const FROST := "shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 2.0;
void fragment() { COLOR = textureLod(screen, SCREEN_UV, amount); }"

## The one clock, handed in by the builder; none, and a bound style moving switches.
var motion: Motion = null
var _style: Variant  # the style described - a name, or a Bound reading one - tried again on every look
var _chimes: RefCounted  # the chimes a bound style is heard through, or none
var _reading: bool = false  # while the look is being read, so a fallback set here is not heard as another look
var _frost: ColorRect  # the blurring rect under the content, or none


func _init(style: Variant, chimes: RefCounted = null) -> void:
	_style = style
	_chimes = chimes
	theme_type_variation = Styled.name_of(style)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# a bound style followed: read now, and read again as what it read moves
	if style is Bound:
		chimes.follow(self, &"style", _restyle)


## The style it was described with, now - whatever the look wears for it,
## the base where the look does not know it.
func get_style() -> StringName:
	return Styled.name_of(_style)


## A bound style read - and, once this is in the tree, the look read again
## in place, the panel it had left fading over the one it has now
## (outgoing.gd).
func _restyle() -> void:
	Styled.name_of(_style)
	if not is_inside_tree():
		return
	var before := get_theme_stylebox(&"panel")
	_read_look()
	if motion != null and is_visible_in_tree() and get_theme_stylebox(&"panel") != before:
		Outgoing.leave(self, before, motion)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		Inset.fit(self, get_theme_stylebox(&"panel"))
	if (what == NOTIFICATION_ENTER_TREE or what == NOTIFICATION_THEME_CHANGED) and not _reading:
		_read_look()
	if what == NOTIFICATION_PREDELETE and _chimes != null:
		_chimes.stop_all(self)


## The style it says now, worn; the base where the look does not know it.
func _read_look() -> void:
	_reading = true
	_wear(Styled.name_of(_style))
	if not has_theme_stylebox(&"panel"):
		_wear(Themes.SURFACE)
	_frosted(get_theme_constant(&"blur") if has_theme_constant(&"blur") else 0)
	_reading = false
	queue_redraw()
	queue_sort()


## The blur behind this set: a rect shading the screen under it, kept
## first so everything held draws over it; none for no blur.
func _frosted(blur: int) -> void:
	if blur <= 0:
		if _frost != null:
			_frost.free()
			_frost = null
		return
	if _frost == null:
		_frost = ColorRect.new()
		_frost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frost.set_anchors_preset(Control.PRESET_FULL_RECT)
		var shader := Shader.new()
		shader.code = FROST
		_frost.material = ShaderMaterial.new()
		(_frost.material as ShaderMaterial).shader = shader
		add_child(_frost)
		move_child(_frost, 0)
	(_frost.material as ShaderMaterial).set_shader_parameter(&"amount", float(blur))


func _draw() -> void:
	draw_style_box(get_theme_stylebox(&"panel"), Rect2(Vector2.ZERO, size))


## Its content sits inside the panel's padding: as much room as any part needs, plus the padding.
func _get_minimum_size() -> Vector2:
	return Inset.least(self, get_theme_stylebox(&"panel"))

## The variation set only when it changes, and never while a look is
## being read: setting it tells this the theme changed, and that is where
## this is asked from.
func _wear(variation: StringName) -> void:
	if theme_type_variation != variation:
		theme_type_variation = variation


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"surface").new(desc.props["style"], ui.chimes)
	ui.attach(made, parent, desc.facts)
	return made