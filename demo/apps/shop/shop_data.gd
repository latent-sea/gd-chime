extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## A furniture store's catalogue, made up: a hundred pieces - sofas,
## chairs, tables, lamps, beds, shelves, rugs - each with its room, its
## material, its colour, its price, whether it can be had, and when it came
## in; the same every run.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What stands in for the store's own records. A piece's COLOUR and its
## WOOD are data - the finish it is sold in, named and as the paint of its
## pictures (shop_pictures.gd) - never the look's. Its name and "about" - the
## words a search reads: its name, kind, material, colour and room - are
## data too, shown as they are. The draws are seeded, so a probe and a
## screenshot find the same pieces.
##
## Deliberately absent: sizes, reviews, and more than one finish a piece.

const COLUMNS := {&"name": GdChime.PackedRows.WORDS, &"about": GdChime.PackedRows.WORDS, &"kind": GdChime.PackedRows.WORDS, &"room": GdChime.PackedRows.WORDS, &"material": GdChime.PackedRows.WORDS, &"colour": GdChime.PackedRows.WORDS, &"price": GdChime.PackedRows.NUMBER, &"stock": GdChime.PackedRows.WORDS, &"added": GdChime.PackedRows.DATE, &"rating": GdChime.PackedRows.NUMBER}
const COUNT := 100
## Each kind: what it is called, the rooms it stands in, what it is made of, and its price between two ends.
const KINDS := {
	&"sofa": ["three-seat sofa", ["living room"], ["linen", "velvet", "boucle", "leather"], [1100, 3200]],
	&"armchair": ["armchair", ["living room", "bedroom", "study"], ["linen", "velvet", "boucle", "leather"], [420, 1400]],
	&"chair": ["dining chair", ["dining room", "study"], ["oak", "walnut", "ash", "rattan"], [120, 420]],
	&"dining_table": ["dining table", ["dining room"], ["oak", "walnut", "ash", "marble"], [650, 2600]],
	&"coffee_table": ["coffee table", ["living room"], ["oak", "walnut", "marble", "travertine"], [240, 1100]],
	&"floor_lamp": ["floor lamp", ["living room", "study", "hallway"], ["steel", "ceramic", "rattan"], [140, 520]],
	&"table_lamp": ["table lamp", ["bedroom", "study", "living room"], ["ceramic", "steel", "travertine"], [60, 260]],
	&"bed": ["double bed", ["bedroom"], ["linen", "velvet", "oak", "boucle"], [780, 2400]],
	&"bookcase": ["bookcase", ["study", "living room"], ["oak", "walnut", "ash"], [320, 1250]],
	&"sideboard": ["sideboard", ["dining room", "hallway", "living room"], ["oak", "walnut", "ash"], [540, 1900]],
	&"rug": ["rug", ["living room", "bedroom", "hallway"], ["wool", "linen"], [150, 980]],
	&"stool": ["stool", ["dining room", "hallway", "study"], ["oak", "ash", "rattan"], [70, 240]],
}
## Each colour a piece is sold in, as the paint of its pictures.
const COLOURS := {"sage": "#8a9a7b", "terracotta": "#c46a4a", "charcoal": "#3d3f45", "ivory": "#e6dccb", "ocean": "#2f4f6f", "ochre": "#c99a3b", "blush": "#d4a5a0", "forest": "#3e5a44", "sand": "#c8b89a", "plum": "#6d4c6e", "stone": "#9a948a", "clay": "#a86f55"}
## The wood a piece stands on, by its material where it is a wood, else by draw.
const WOODS := {"oak": "#c49a6c", "walnut": "#6b4a33", "ash": "#d8c3a0"}
## The walls and floor its pictures stand on: the studio's, and each room's.
const STUDIO := {"wall": "#efe9df", "floor": "#cdb89c"}
const ROOMS := {"living room": "#e2dccf", "dining room": "#dde2da", "bedroom": "#e7dcdc", "study": "#dbe0e5", "hallway": "#e5dfd2"}
const STOCK := ["in stock", "in stock", "in stock", "in stock", "in stock", "low stock", "made to order", "made to order", "sold out"]
const NAMES := ["Aldo", "Brisa", "Calder", "Dune", "Elm", "Fenn", "Greta", "Harlow", "Ines", "Juno", "Kasa", "Lior", "Mora", "Nell", "Oslo", "Pia", "Rhea", "Sola", "Tove", "Una", "Vale", "Wren", "Ada", "Bram", "Cleo", "Dara", "Esme", "Finn", "Gio", "Hana", "Ilse", "Joss", "Kit", "Lark", "Milo", "Nico", "Otto", "Pax", "Quill", "Rune"]
## The day the newest piece came in.
const NEWEST := "2026-09-15"


## The hundred pieces, the same every run.
static func made() -> GdChime.PackedRows:
	var rows := GdChime.PackedRows.new(COLUMNS)
	var draws := RandomNumberGenerator.new()
	draws.seed = 1906
	var kinds: Array = KINDS.keys()
	var newest := GdChime.PackedRows.day_of(NEWEST)
	# every piece: its kind in turn, the rest drawn
	for at: int in COUNT:
		var kind: StringName = kinds[at % kinds.size()]
		var spec: Array = KINDS[kind]
		var room: String = spec[1][draws.randi() % spec[1].size()]
		var material: String = spec[2][draws.randi() % spec[2].size()]
		var colour: String = COLOURS.keys()[draws.randi() % COLOURS.size()]
		var name := "%s %s" % [NAMES[(at * 7) % NAMES.size()], spec[0]]
		var price := snappedf(draws.randf_range(spec[3][0], spec[3][1]), 5.0) - 1.0
		var about := " ".join([name, material, colour, room])
		rows.add([name, about, String(kind), room, material, colour, price, STOCK[draws.randi() % STOCK.size()], newest - float(draws.randi_range(0, 400)), snappedf(draws.randf_range(3.6, 5.0), 0.1)])
	return rows


## What a piece's pictures are painted from, by its row: {kind, finish, wood, wall, room_wall, floor, material}.
static func pictures_of(rows: GdChime.PackedRows) -> Array:
	var draws := RandomNumberGenerator.new()
	draws.seed = 612
	return range(rows.count()).map(func(row: int) -> Dictionary:
		var material: String = rows.value_at(row, &"material")
		return {"kind": StringName(rows.value_at(row, &"kind")), "material": material, "finish": Color.html(COLOURS[rows.value_at(row, &"colour")]), "wood": Color.html(WOODS[material] if WOODS.has(material) else WOODS.values()[draws.randi() % WOODS.size()]), "wall": Color.html(STUDIO["wall"]), "room_wall": Color.html(ROOMS[rows.value_at(row, &"room")]), "floor": Color.html(STUDIO["floor"])})
