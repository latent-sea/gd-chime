extends RefCounted

## A simulation of colour-blind sight laid over the whole screen, so a look
## can be checked by eye rather than by argument.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE MATRICES ARE THE ONE COPY. Machado, Oliveira and Fernandes' matrices
## at full severity, in LINEAR light: a row each for what the eye that lacks
## the long, the middle or the short cone still passes through to the brain.
## Whatever needs to know how a colour is seen - the screen shader here, and
## the palettes that are derived by searching for a hue that survives them -
## reads them from here, so there is never a second set to drift from this one.
##
## The overlay is a rect over everything, last child of the window so it is
## drawn over every place, and IGNORING THE MOUSE so that the interface under
## it works exactly as it did: this simulates an eye, and an eye presses
## nothing. It reads what is already on the screen through the screen texture,
## takes it back to linear light, passes it through the matrix and returns it,
## so what it shows is the whole application as that eye would receive it.
##
## It is a DEVELOPER'S instrument, not the setting: the setting rebuilds the
## theme from a palette that eye can read (the looks' palettes), and this says
## whether that worked. Running both at once is the point - a palette built
## for deuteranopia, seen as deuteranopia.

## The sight that is no simulation at all, and the three that are.
const PLAIN := &"plain"
const DEUTERANOPIA := &"deuteranopia"
const PROTANOPIA := &"protanopia"
const TRITANOPIA := &"tritanopia"
const SIGHTS: Array[StringName] = [PLAIN, DEUTERANOPIA, PROTANOPIA, TRITANOPIA]

## What each eye passes through, in linear light: the red, green and blue rows.
const MATRICES := {
	DEUTERANOPIA: [
		Vector3(0.367322, 0.860646, -0.227968),
		Vector3(0.280085, 0.672501, 0.047413),
		Vector3(-0.011820, 0.042940, 0.968881),
	],
	PROTANOPIA: [
		Vector3(0.152286, 1.052583, -0.204868),
		Vector3(0.114503, 0.786281, 0.099216),
		Vector3(-0.003882, -0.048116, 1.051998),
	],
	TRITANOPIA: [
		Vector3(1.255528, -0.076749, -0.178779),
		Vector3(-0.078411, 0.930809, 0.147602),
		Vector3(0.004733, 0.691367, 0.303900),
	],
}

## The overlay's name, so the one already there is found again and never doubled.
const OVER := "SimulatedSight"

## The matrix is three separate rows rather than a mat3, because which way
## round the engine hands a Basis to a shader is not worth being wrong about.
const SHADER := """
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform vec3 red_row;
uniform vec3 green_row;
uniform vec3 blue_row;

void fragment() {
	vec3 was = texture(screen, SCREEN_UV).rgb;
	vec3 light = mix(was / 12.92, pow((was + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), was));
	vec3 seen = clamp(vec3(dot(red_row, light), dot(green_row, light), dot(blue_row, light)), 0.0, 1.0);
	vec3 back = mix(seen * 12.92, 1.055 * pow(seen, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), seen));
	COLOR = vec4(back, 1.0);
}
"""


## The overlay over this canvas now, or nothing.
static func over(canvas: Node) -> ColorRect:
	return canvas.get_node_or_null(NodePath(OVER)) as ColorRect


## The screen shown as this eye receives it: the overlay put on, or taken away
## again for the plain sight. Whatever was there is taken away first, so the
## matrix is never stale and the overlay is never doubled.
static func simulate(sight: String, canvas: Node) -> String:
	var named := StringName(sight)
	if not SIGHTS.has(named):
		return "no such sight; they are %s" % ", ".join(PackedStringArray(SIGHTS))
	var already := over(canvas)
	if already != null:
		canvas.remove_child(already)
		already.queue_free()
	if named == PLAIN:
		return "seeing plainly"
	var rows: Array = MATRICES[named]
	var shader := Shader.new()
	shader.code = SHADER
	var paint := ShaderMaterial.new()
	paint.shader = shader
	for row: int in range(3):
		paint.set_shader_parameter([&"red_row", &"green_row", &"blue_row"][row], rows[row])
	var laid := ColorRect.new()
	laid.name = OVER
	laid.material = paint
	laid.set_anchors_preset(Control.PRESET_FULL_RECT)
	# an eye presses nothing: every press goes to the interface under it
	laid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(laid)
	return "seeing as %s" % sight
