extends RefCounted

## A product's pictures, painted: a studio shot of the piece on its wall and
## floor, the piece in a room, a closer look, and its material - each made at
## the size asked, from the product's own finish, wood and room.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHAT STANDS IN FOR PHOTOGRAPHS: a furniture store's catalogue shots,
## which a real store would load from files. They are data - the product's
## finish is the product's, never the look's - and the look never reads
## them. Each is painted in the unit square from the piece's parts
## (shop_furniture.gd), at half as large again as asked and scaled down, so
## every edge is smoothed; a card's size keeps its smaller copies (mipmaps).
##
## PURE, AND FOR ANOTHER THREAD: painted() reads what it is handed and
## makes a new image, touching nothing shared, so the job pool runs it off
## the frame (jobs.gd).
##
## Deliberately absent: light and shadow worked out from a light, and
## perspective; a piece is flat-shaded, lit from above.

const Furniture := preload("res://demo/apps/shop/shop_furniture.gd")

## The shots, in the order a gallery shows them.
const STUDIO := 0
const ROOM := 1
const CLOSER := 2
const MATERIAL := 3
const SHOTS := 4
## How much larger a picture is painted than asked, to smooth its edges.
const OVER := 1.5
## Where the wall meets the floor, down the square.
const HORIZON := 0.74


## The picture of this product in this shot, this many pixels square:
## product is {kind, material, finish, wood, wall, room_wall, floor}, its
## colours data (shop_data.gd).
static func painted(product: Dictionary, shot: int, size: int, mipmapped: bool) -> Image:
	var side := int(size * OVER)
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	var finish: Color = product["finish"]
	if shot == MATERIAL:
		_material(image, product)
	else:
		var wall: Color = product["wall"] if shot == STUDIO else product["room_wall"]
		_backdrop(image, wall, product["floor"])
		# the closer look: the piece twice as large about its heart; the room: a little smaller, with a window and a plant
		var zoom: float = {STUDIO: 1.0, ROOM: 0.8, CLOSER: 2.0}[shot]
		var heart: Vector2 = Furniture.heart_of(product["kind"]) if shot == CLOSER else Vector2(0.5, HORIZON)
		var at := func(unit: Rect2) -> Rect2: return Rect2((unit.position - heart) * zoom + Vector2(0.5, HORIZON if shot != CLOSER else 0.5), unit.size * zoom)
		if shot == ROOM:
			_room(image, at, product)
		_blob(image, at.call(Furniture.shadow_of(product["kind"])), Color.TRANSPARENT.lerp(Color.BLACK, 0.5))
		# every part of the piece, back to front, in its role's colour
		for part: Array in Furniture.parts_of(product["kind"]):
			_part(image, part, at.call(part[1]), Furniture.colour_of(part[2], finish, product["wood"]))
	image.resize(size, size, Image.INTERPOLATE_LANCZOS)
	if mipmapped:
		image.generate_mipmaps()
	return image


## A swatch of a colour as a round dot, this many pixels square: a facet's colour shown beside its name.
static func swatch(colour: Color, size: int) -> Image:
	var image := Image.create_empty(size * 2, size * 2, false, Image.FORMAT_RGBA8)
	_ellipse(image, Rect2(Vector2.ONE * 2.0, Vector2.ONE * (size * 2 - 4)), colour.lightened(0.12), colour.darkened(0.12))
	image.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return image


## The wall, lighter toward the top, over the floor, darker toward the front.
static func _backdrop(image: Image, wall: Color, floor: Color) -> void:
	var side := image.get_width()
	var horizon := int(side * HORIZON)
	# every row down the square: the wall's shade above the horizon, the floor's below it
	for y: int in side:
		var colour := wall.lightened(0.08 * (1.0 - float(y) / horizon)) if y < horizon else floor.darkened(0.12 * float(y - horizon) / (side - horizon))
		image.fill_rect(Rect2i(0, y, side, 1), colour)
	image.fill_rect(Rect2i(0, horizon, side, maxi(side / 300, 1)), floor.darkened(0.18))


## A room around the piece: a window's light on the wall to the left, a plant in its pot to the right.
static func _room(image: Image, at: Callable, product: Dictionary) -> void:
	var wall: Color = product["room_wall"]
	_part(image, [Furniture.BOX, null, null, 0.01], at.call(Rect2(0.02, 0.08, 0.3, 0.42)), wall.lightened(0.5))
	_part(image, [Furniture.BOX, null, null, 0.0], at.call(Rect2(0.165, 0.08, 0.01, 0.42)), wall.darkened(0.05))
	_blob(image, at.call(Rect2(0.84, 0.715, 0.2, 0.05)), Color.TRANSPARENT.lerp(Color.BLACK, 0.3))
	# the plant's leaves, each a green oval fanned over the pot
	for leaf: Rect2 in [Rect2(0.83, 0.3, 0.1, 0.26), Rect2(0.9, 0.24, 0.1, 0.3), Rect2(0.97, 0.34, 0.1, 0.24), Rect2(0.87, 0.4, 0.14, 0.14)]:
		_part(image, [Furniture.OVAL], at.call(leaf), Color.html(Furniture.FIXED[Furniture.LEAF]))
	_part(image, [Furniture.TAPER, null, null, 0.8], at.call(Rect2(0.87, 0.54, 0.14, 0.19)), Color.html(Furniture.FIXED[Furniture.POT]))


## A part of a piece drawn at this rect: a box, an oval, a taper or a glow.
static func _part(image: Image, part: Array, rect: Rect2, colour: Color) -> void:
	var side := float(image.get_width())
	var pixels := Rect2(rect.position * side, rect.size * side)
	match part[0]:
		Furniture.BOX: _box(image, pixels, part[3] * side, colour)
		Furniture.OVAL: _ellipse(image, pixels, colour.lightened(0.1), colour.darkened(0.1))
		Furniture.TAPER: _taper(image, pixels, part[3], colour)
		Furniture.GLOW: _blob(image, rect, colour)


## A box with rounded corners, lighter at its top edge and shading down.
static func _box(image: Image, rect: Rect2, radius: float, colour: Color) -> void:
	var top := colour.lightened(0.12)
	var bottom := colour.darkened(0.1)
	var r := minf(radius, minf(rect.size.x, rect.size.y) / 2.0)
	# every row of the box, cut in at a rounded corner
	for y: int in range(int(rect.position.y), int(rect.end.y)):
		var from_edge := minf(y - rect.position.y, rect.end.y - 1 - y)
		var cut := r - sqrt(maxf(r * r - pow(r - from_edge, 2.0), 0.0)) if from_edge < r else 0.0
		var shade := top.lerp(bottom, (y - rect.position.y) / rect.size.y)
		image.fill_rect(Rect2i(int(rect.position.x + cut), y, int(rect.size.x - cut * 2.0), 1), shade.lightened(0.25) if y - int(rect.position.y) < maxi(int(rect.size.y / 40.0), 1) else shade)


## A filled oval, one colour at its top shading to another at its foot.
static func _ellipse(image: Image, rect: Rect2, top: Color, bottom: Color) -> void:
	var centre := rect.get_center()
	var half := rect.size / 2.0
	# every row of the oval, as wide as the oval is there
	for y: int in range(int(rect.position.y), int(rect.end.y)):
		var across := half.x * sqrt(maxf(1.0 - pow((y + 0.5 - centre.y) / half.y, 2.0), 0.0))
		image.fill_rect(Rect2i(int(centre.x - across), y, int(across * 2.0), 1), top.lerp(bottom, (y - rect.position.y) / rect.size.y))


## A shade or a pot: narrower at the top by this share, shading down.
static func _taper(image: Image, rect: Rect2, top_share: float, colour: Color) -> void:
	# every row, the width going from the top's share to the whole
	for y: int in range(int(rect.position.y), int(rect.end.y)):
		var along := (y - rect.position.y) / rect.size.y
		var wide := rect.size.x * lerpf(top_share, 1.0, along)
		image.fill_rect(Rect2i(int(rect.get_center().x - wide / 2.0), y, int(wide), 1), colour.lightened(0.14).lerp(colour.darkened(0.12), along))


## A soft oval of this colour fading to nothing at its edge, laid over what is there: a shadow, a lamp's glow.
static func _blob(image: Image, unit: Rect2, colour: Color) -> void:
	var side := float(image.get_width())
	var soft := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	# every pixel of a small soft disc, its alpha falling away from the middle
	for y: int in 64:
		# every pixel across the row
		for x: int in 64:
			var far := minf(Vector2(x - 31.5, y - 31.5).length() / 32.0, 1.0)
			var faded := colour
			faded.a = colour.a * pow(1.0 - far, 1.6)
			soft.set_pixel(x, y, faded)
	var wide := Vector2i(maxi(int(unit.size.x * side), 1), maxi(int(unit.size.y * side), 1))
	soft.resize(wide.x, wide.y, Image.INTERPOLATE_BILINEAR)
	image.blend_rect(soft, Rect2i(Vector2i.ZERO, wide), Vector2i(unit.position * side))


## The material close to: wood's grain, a fabric's weave, or a stone's veins, filling the square.
static func _material(image: Image, product: Dictionary) -> void:
	var side := image.get_width()
	var finish: Color = product["finish"]
	var draws := RandomNumberGenerator.new()
	draws.seed = hash(product["kind"]) ^ finish.to_rgba32()
	match Furniture.grain_of(product["material"]):
		Furniture.GRAIN:
			var wood: Color = product["wood"]
			# every column across: a grain line's shade, waving slowly
			for x: int in side:
				image.fill_rect(Rect2i(x, 0, 1, side), wood.lerp(wood.darkened(0.25), 0.5 + 0.5 * sin(x * 0.045 + sin(x * 0.011) * 3.0)))
		Furniture.WEAVE:
			var cell := maxi(side / 90, 2)
			# every cell of the weave, alternate threads a little lighter and darker
			for y: int in range(0, side, cell):
				# every cell across the row
				for x: int in range(0, side, cell):
					image.fill_rect(Rect2i(x, y, cell, cell), finish.lightened(0.07) if (x / cell + y / cell) % 2 == 0 else finish.darkened(0.07 + draws.randf() * 0.04))
		Furniture.VEINS:
			image.fill_rect(Rect2i(0, 0, side, side), finish.lightened(0.05))
			# every vein, a thin line wandering down across the stone
			for vein: int in 7:
				var x := draws.randf() * side
				# every row down the stone, the vein wandering a little across it
				for y: int in side:
					x += sin(y * 0.02 + vein) * 1.6 + draws.randf_range(-1.0, 1.0)
					image.fill_rect(Rect2i(int(x), y, maxi(side / 400, 1), 1), finish.darkened(0.35))
