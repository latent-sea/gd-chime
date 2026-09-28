extends RefCounted

## Words in a gradient: a kind of words the look gives two colours,
## gradient_from and gradient_to, is drawn from the one to the other left
## to right across the words themselves - not across the label, which may
## be far wider than what it says.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE LOOK NAMES IT, ON THE KIND: Title, or any variation of Label. A kind
## with neither colour, or one alone, is drawn in its font colour as ever.
## The gradient spans the leftmost to the rightmost character as the label
## has laid them out, so words centred in a wide title are graded across
## their own width, and graded again as they change, move or wrap.
##
## A PRESS'S INK WINS: words a press inks (face_ink.gd) are in its state's
## one colour, never a gradient, since they stand on the press's own ground.
##
## It is a shader on the label: everything the label draws takes the
## gradient, so a kind given an outline has its outline graded too. It
## holds nothing but the one shader every graded label shares.

## The two colours a kind of words is graded between, under its own type.
const FROM := &"gradient_from"
const TO := &"gradient_to"

const CODE := """
shader_type canvas_item;
uniform vec4 from_colour : source_color;
uniform vec4 to_colour : source_color;
uniform float start;
uniform float width;
varying float across;

void vertex() {
	across = clamp((VERTEX.x - start) / max(width, 1.0), 0.0, 1.0);
}

void fragment() {
	vec4 drawn = texture(TEXTURE, UV) * COLOR;
	vec4 graded = mix(from_colour, to_colour, across);
	COLOR = vec4(graded.rgb, graded.a * drawn.a);
}
"""

static var _shader: Shader = null  # the one every graded label draws with, made the first time one is


## This label graded as its kind says, across its words as it has laid them
## out now - or drawn plainly, if its kind names no gradient or a press inks it.
static func dress(label: Label) -> void:
	if label.has_theme_color_override(&"font_color") or not (label.has_theme_color(FROM) and label.has_theme_color(TO)):
		label.material = null
		return
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	if label.material == null:
		label.material = ShaderMaterial.new()
		(label.material as ShaderMaterial).shader = _shader
	var words := spanned(label)
	var graded := label.material as ShaderMaterial
	graded.set_shader_parameter(&"from_colour", label.get_theme_color(FROM))
	graded.set_shader_parameter(&"to_colour", label.get_theme_color(TO))
	graded.set_shader_parameter(&"start", words.x)
	graded.set_shader_parameter(&"width", words.y - words.x)


## Where a label's words start and end across it, in its own pixels, as it
## has laid them out: nothing, for no words. PUBLIC because it is what the
## gradient is measured against, and a test reads it.
static func spanned(label: Label) -> Vector2:
	var left := INF
	var right := -INF
	# every character, for the leftmost start and the rightmost end: a break takes no room and is passed over
	for at: int in label.text.length():
		var box := label.get_character_bounds(at)
		if box.size.x > 0.0:
			left = minf(left, box.position.x)
			right = maxf(right, box.end.x)
	return Vector2(left, right) if left < right else Vector2.ZERO
