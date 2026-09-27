extends RefCounted

## The pieces of furniture the store sells, as parts in a unit square: what
## a picture of each is painted from (shop_pictures.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PIECE IS ITS PARTS, back to front: each [shape, rect, role, and the
## shape's one number - a box's corner, a taper's top] - the rect in the
## unit square, standing on the floor at y 0.74. A ROLE says which colour a
## part takes: the finish, a shade of it, the wood, or a fixed colour of
## its own - a pillow's cream, a lamp's glow - each as data. Its heart is
## where a closer look is centred, its shadow the soft oval under it.
##
## Deliberately absent: any piece drawn from more than one side.

const BOX := &"box"
const OVAL := &"oval"
const TAPER := &"taper"
const GLOW := &"glow"
## The roles a part's colour comes from.
const BODY := &"body"
const DARK := &"dark"
const LIGHT := &"light"
const WOOD := &"wood"
const CREAM := &"cream"
const BRASS := &"brass"
const WARM := &"warm"
const PAGES := &"pages"
const LEAF := &"leaf"
const POT := &"pot"
## The fixed colours, as data: a pillow, a lamp's metal, its light, a book's spine.
const FIXED := {CREAM: "#f1ebe0", BRASS: "#b8955a", WARM: "#ffe2a899", PAGES: "#7d6b5a", LEAF: "#5f7f4e", POT: "#c9b8a4"}
## How a material's close look is drawn.
const GRAIN := &"grain"
const WEAVE := &"weave"
const VEINS := &"veins"
const GRAINS := {"oak": GRAIN, "walnut": GRAIN, "ash": GRAIN, "rattan": WEAVE, "linen": WEAVE, "velvet": WEAVE, "wool": WEAVE, "boucle": WEAVE, "leather": WEAVE, "marble": VEINS, "travertine": VEINS, "steel": VEINS, "ceramic": VEINS}

const LEG := 0.004
const PIECES := {
	&"sofa": [[BOX, Rect2(0.13, 0.4, 0.74, 0.22), DARK, 0.05], [BOX, Rect2(0.12, 0.56, 0.76, 0.14), BODY, 0.03], [BOX, Rect2(0.2, 0.52, 0.295, 0.07), LIGHT, 0.025], [BOX, Rect2(0.505, 0.52, 0.295, 0.07), LIGHT, 0.025], [BOX, Rect2(0.09, 0.48, 0.1, 0.22), BODY, 0.045], [BOX, Rect2(0.81, 0.48, 0.1, 0.22), BODY, 0.045], [BOX, Rect2(0.15, 0.7, 0.018, 0.04), WOOD, LEG], [BOX, Rect2(0.832, 0.7, 0.018, 0.04), WOOD, LEG]],
	&"armchair": [[BOX, Rect2(0.29, 0.34, 0.42, 0.28), DARK, 0.06], [BOX, Rect2(0.27, 0.56, 0.46, 0.14), BODY, 0.03], [BOX, Rect2(0.33, 0.52, 0.34, 0.07), LIGHT, 0.03], [BOX, Rect2(0.24, 0.46, 0.09, 0.24), BODY, 0.04], [BOX, Rect2(0.67, 0.46, 0.09, 0.24), BODY, 0.04], [BOX, Rect2(0.3, 0.7, 0.016, 0.04), WOOD, LEG], [BOX, Rect2(0.684, 0.7, 0.016, 0.04), WOOD, LEG]],
	&"chair": [[BOX, Rect2(0.39, 0.26, 0.22, 0.3), BODY, 0.03], [BOX, Rect2(0.37, 0.54, 0.26, 0.05), LIGHT, 0.02], [BOX, Rect2(0.385, 0.59, 0.016, 0.15), WOOD, LEG], [BOX, Rect2(0.599, 0.59, 0.016, 0.15), WOOD, LEG], [BOX, Rect2(0.45, 0.59, 0.012, 0.13), DARK, LEG], [BOX, Rect2(0.538, 0.59, 0.012, 0.13), DARK, LEG]],
	&"dining_table": [[BOX, Rect2(0.2, 0.5, 0.012, 0.22), DARK, LEG], [BOX, Rect2(0.788, 0.5, 0.012, 0.22), DARK, LEG], [BOX, Rect2(0.08, 0.44, 0.84, 0.045), BODY, 0.008], [BOX, Rect2(0.13, 0.485, 0.74, 0.03), DARK, 0.0], [BOX, Rect2(0.12, 0.485, 0.025, 0.255), BODY, LEG], [BOX, Rect2(0.855, 0.485, 0.025, 0.255), BODY, LEG]],
	&"coffee_table": [[BOX, Rect2(0.16, 0.58, 0.68, 0.05), BODY, 0.02], [BOX, Rect2(0.2, 0.63, 0.6, 0.02), DARK, 0.0], [BOX, Rect2(0.2, 0.65, 0.022, 0.09), BODY, LEG], [BOX, Rect2(0.778, 0.65, 0.022, 0.09), BODY, LEG], [OVAL, Rect2(0.3, 0.535, 0.1, 0.05), CREAM, 0.0]],
	&"floor_lamp": [[GLOW, Rect2(0.2, 0.0, 0.6, 0.5), WARM, 0.0], [BOX, Rect2(0.494, 0.3, 0.012, 0.42), BRASS, LEG], [OVAL, Rect2(0.42, 0.715, 0.16, 0.03), BRASS, 0.0], [TAPER, Rect2(0.36, 0.14, 0.28, 0.18), BODY, 0.62]],
	&"table_lamp": [[GLOW, Rect2(0.25, 0.12, 0.5, 0.46), WARM, 0.0], [BOX, Rect2(0.3, 0.64, 0.4, 0.1), WOOD, 0.01], [OVAL, Rect2(0.42, 0.46, 0.16, 0.19), BODY, 0.0], [BOX, Rect2(0.494, 0.38, 0.012, 0.1), BRASS, LEG], [TAPER, Rect2(0.37, 0.25, 0.26, 0.15), CREAM, 0.6]],
	&"bed": [[BOX, Rect2(0.12, 0.32, 0.76, 0.34), BODY, 0.04], [BOX, Rect2(0.1, 0.56, 0.8, 0.1), CREAM, 0.02], [BOX, Rect2(0.2, 0.49, 0.26, 0.08), CREAM, 0.035], [BOX, Rect2(0.54, 0.49, 0.26, 0.08), CREAM, 0.035], [BOX, Rect2(0.1, 0.6, 0.8, 0.1), LIGHT, 0.025], [BOX, Rect2(0.13, 0.7, 0.02, 0.04), WOOD, LEG], [BOX, Rect2(0.85, 0.7, 0.02, 0.04), WOOD, LEG]],
	&"bookcase": [[BOX, Rect2(0.28, 0.1, 0.44, 0.64), BODY, 0.006], [BOX, Rect2(0.3, 0.12, 0.4, 0.6), DARK, 0.0], [BOX, Rect2(0.33, 0.17, 0.03, 0.12), PAGES, 0.0], [BOX, Rect2(0.365, 0.19, 0.025, 0.1), CREAM, 0.0], [BOX, Rect2(0.5, 0.36, 0.03, 0.13), CREAM, 0.0], [BOX, Rect2(0.535, 0.37, 0.028, 0.12), PAGES, 0.0], [BOX, Rect2(0.36, 0.56, 0.05, 0.13), BRASS, 0.0], [BOX, Rect2(0.3, 0.29, 0.4, 0.012), BODY, 0.0], [BOX, Rect2(0.3, 0.49, 0.4, 0.012), BODY, 0.0], [BOX, Rect2(0.3, 0.69, 0.4, 0.012), BODY, 0.0]],
	&"sideboard": [[BOX, Rect2(0.1, 0.44, 0.8, 0.25), BODY, 0.012], [BOX, Rect2(0.297, 0.46, 0.006, 0.21), DARK, 0.0], [BOX, Rect2(0.497, 0.46, 0.006, 0.21), DARK, 0.0], [BOX, Rect2(0.697, 0.46, 0.006, 0.21), DARK, 0.0], [BOX, Rect2(0.14, 0.69, 0.018, 0.05), WOOD, LEG], [BOX, Rect2(0.842, 0.69, 0.018, 0.05), WOOD, LEG], [OVAL, Rect2(0.62, 0.32, 0.08, 0.13), CREAM, 0.0]],
	&"rug": [[TAPER, Rect2(0.06, 0.66, 0.88, 0.14), BODY, 0.72], [TAPER, Rect2(0.13, 0.68, 0.74, 0.1), LIGHT, 0.72], [TAPER, Rect2(0.2, 0.7, 0.6, 0.06), DARK, 0.72]],
	&"stool": [[BOX, Rect2(0.4, 0.5, 0.016, 0.24), WOOD, LEG], [BOX, Rect2(0.584, 0.5, 0.016, 0.24), WOOD, LEG], [BOX, Rect2(0.43, 0.62, 0.14, 0.012), WOOD, 0.0], [OVAL, Rect2(0.36, 0.45, 0.28, 0.08), BODY, 0.0]],
}
## Where a closer look of each is centred.
const HEARTS := {&"sofa": Vector2(0.5, 0.55), &"armchair": Vector2(0.5, 0.52), &"chair": Vector2(0.5, 0.46), &"dining_table": Vector2(0.5, 0.5), &"coffee_table": Vector2(0.5, 0.62), &"floor_lamp": Vector2(0.5, 0.3), &"table_lamp": Vector2(0.5, 0.45), &"bed": Vector2(0.5, 0.55), &"bookcase": Vector2(0.5, 0.4), &"sideboard": Vector2(0.5, 0.55), &"rug": Vector2(0.5, 0.72), &"stool": Vector2(0.5, 0.55)}


static func parts_of(kind: StringName) -> Array:
	return PIECES[kind]


static func heart_of(kind: StringName) -> Vector2:
	return HEARTS[kind]


static func grain_of(material: String) -> StringName:
	return GRAINS[material]


## The soft oval under a piece: as wide as its widest part, on the floor.
static func shadow_of(kind: StringName) -> Rect2:
	var left := 1.0
	var right := 0.0
	# every part, for how far the piece reaches either way
	for part: Array in PIECES[kind]:
		if part[0] != GLOW:
			left = minf(left, part[1].position.x)
			right = maxf(right, part[1].end.x)
	return Rect2(left - 0.02, 0.705, right - left + 0.04, 0.07)


## A role's colour, from the piece's finish and its wood.
static func colour_of(role: StringName, finish: Color, wood: Color) -> Color:
	match role:
		BODY: return finish
		DARK: return finish.darkened(0.2)
		LIGHT: return finish.lightened(0.12)
		WOOD: return wood
	return Color.html(FIXED[role])
