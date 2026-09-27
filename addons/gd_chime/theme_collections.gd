extends RefCounted

const Themes := preload("theme.gd")
const Pressables := preload("theme_pressables.gd")
const Flex := preload("components/primitives/flex.gd")

## COLLECTIONS, as the floor's look draws them until a look says otherwise:
## the many ways a set of things is laid out - a card as a row, a tile or
## dense, an infinite collection of cards, a gallery of pictures, a facet's
## values, a board of lanes and the cards carried between them, a wall of
## tiles, and a row a finger swipes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It holds nothing and draws nothing: theme.gd calls dress() as it is
## built, over the palette it was given, and a look dresses any of these
## again after it. It names a colour only by the palette's name for it. Its
## numbers are PLACEHOLDERS nobody has decided, and theme_placeholders.gd
## holds them with the rest: a collection's least column, a gallery's
## aspect, a swatch's width, a wall's gap.
##
## A RECIPE OWNS ITS STRUCTURAL VARIANTS: every line and every card a
## collection's recipe names is registered here as a variation of its base,
## so a look that sets nothing lays the collection out and draws its cards
## as presses.
##
## NOTHING HERE SAYS A THING BY HUE ALONE. A lane that would take what is
## carried is edged, one that would not is ringed in the soft ink and says
## why in words; a card's hole is the ground, edged; a thumbnail showing is
## ringed; the ground a swipe uncovers is edged thick in the accent when
## letting go would do it, beside the words its reveal says it in.

## An infinite collection's cards, its foot's press, the column of both, and a collection of outcomes.
const CARDS := &"CollectionCards"
const MORE := &"CollectionMore"
const COLLECTION := &"Collection"
const OUTCOMES := &"Outcomes"
## A card, in each way it is laid out, and the two it stands in for: nothing to show, and more to see.
const CARD_LIST := &"CardList"
const CARD_TILE := &"CardTile"
const CARD_DENSE := &"CardDense"
const CARD_EMPTY := &"CardEmpty"
const CARD_MORE := &"CardMore"
## A gallery's column, its large picture, its thumbnails' row, a thumbnail and its picture, and a step (gallery.gd).
const GALLERY := &"Gallery"
const GALLERY_PICTURE := &"GalleryPicture"
const GALLERY_THUMBS := &"GalleryThumbs"
const GALLERY_THUMB := &"GalleryThumb"
const GALLERY_THUMB_PICTURE := &"GalleryThumbPicture"
const GALLERY_STEP := &"GalleryStep"
## A facet's column, its values' row, a value, a value picked and a value's count (facet_list.gd).
const FACET := &"Facet"
const FACET_VALUES := &"FacetValues"
const FACET_VALUE := &"FacetValue"
const FACET_PICKED := &"FacetPicked"
const FACET_COUNT := &"FacetCount"
const FACET_SWATCH := &"FacetSwatch"
const FACET_CELL := &"FacetCell"
const FACET_TITLE := &"FacetTitle"
## A board of lanes, a lane, its column and heading, and a card in one with its column, its lines and its words.
const BOARD := &"Board"
const LANES := &"Lanes"
const LANE := &"Lane"
const LANE_COLUMN := &"LaneColumn"
const LANE_HEADING := &"LaneHeading"
const BOARD_CARD := &"BoardCard"
const BOARD_CARD_COLUMN := &"BoardCardColumn"
const BOARD_CARD_LINE := &"BoardCardLine"
const BOARD_CARD_TITLE := &"BoardCardTitle"
const BOARD_CARD_META := &"BoardCardMeta"
## A wall of tiles, wrapping at its width, and a tile on it.
const WALL := &"Wall"
const WALL_TILE := &"WallTile"
## A row a finger swipes, and the line its reveal's mark and words stand in.
const SWIPE_ROW := &"SwipeRow"
const SWIPE_REVEAL := &"SwipeReveal"
## A lazy picture's box, which a gallery's pictures take (theme_feedback.gd).
const LAZY_IMAGE := &"LazyImage"
## Every state a press is drawn in.
const STATES: Array[StringName] = [&"normal", &"hover", &"inert", &"glowing", &"selected", &"current"]
## Each kind of words a board's card draws, and its size.
const SIZES := {BOARD_CARD_TITLE: 22, BOARD_CARD_META: 18}
## Every line a collection's recipe names, with the base it varies.
const LINES := {CARDS: Themes.TILES, COLLECTION: Themes.COLUMN, OUTCOMES: Themes.COLUMN, BOARD: Themes.COLUMN, LANES: Themes.ROW, LANE_COLUMN: Themes.COLUMN, BOARD_CARD_COLUMN: Themes.COLUMN, LANE_HEADING: Themes.TILES, BOARD_CARD_LINE: Themes.TILES, GALLERY: Themes.COLUMN, GALLERY_THUMBS: Themes.ROW, FACET: Themes.COLUMN, FACET_VALUES: Themes.TILES, WALL: Themes.TILES, SWIPE_REVEAL: Themes.ROW}
## Every press a collection's recipe names, drawn as a pressable until a look says otherwise.
const PRESSES: Array[StringName] = [MORE, CARD_LIST, CARD_TILE, CARD_DENSE, CARD_MORE, GALLERY_STEP, FACET_VALUE, WALL_TILE, SWIPE_ROW]


static func dress(theme: Theme, palette: Dictionary) -> void:
	# every line: its base, so a look that sets nothing lays it out
	for line: StringName in LINES:
		theme.set_type_variation(line, LINES[line])
	# every press: the pressable, until a look dresses it
	for press: StringName in PRESSES:
		theme.set_type_variation(press, Themes.PRESSABLE)
	# the card standing where there is nothing to show: a ground, not a press
	theme.set_type_variation(CARD_EMPTY, Themes.SURFACE)
	# every kind of words a board's card draws, a Label sized once
	for kind: StringName in SIZES:
		theme.set_type_variation(kind, &"Label")
		theme.set_font_size(&"font_size", kind, SIZES[kind])
	theme.set_constant(&"gap", LANES, 12)
	theme.set_constant(&"gap", LANE_COLUMN, 8)
	theme.set_constant(&"gap", BOARD_CARD_COLUMN, 4)
	theme.set_constant(&"gap", LANE_HEADING, 8)
	theme.set_constant(&"gap", BOARD_CARD_LINE, 6)
	theme.set_constant(&"align", GALLERY_THUMBS, Flex.CENTER)
	theme.set_constant(&"align", FACET_VALUES, Flex.START)
	theme.set_constant(&"gap", SWIPE_REVEAL, 12)
	theme.set_constant(&"align", SWIPE_REVEAL, Flex.CENTER)
	_board(theme, palette)
	_gallery(theme, palette)
	_facets(theme, palette)
	# a row a finger swipes: the ground it uncovers either way, armed or not
	for side: String in ["right", "left"]:
		theme.set_stylebox(StringName("reveal_" + side), SWIPE_ROW, _box(palette[&"lit"], 12.0))
		theme.set_stylebox(StringName("armed_" + side), SWIPE_ROW, _box(palette[&"lit"], 12.0, palette[&"accent"], 6))


## A board: a lane on the raised ground, edged in the accent while it would
## take what is carried and ringed in the soft ink while it would not; a
## card on the lit ground, and, carried, a hole in the ground where it was.
static func _board(theme: Theme, palette: Dictionary) -> void:
	theme.set_type_variation(LANE, Themes.PRESSABLE)
	var lane := {&"normal": _round(palette[&"raised"], 8.0), &"hover": _round(palette[&"raised"], 8.0), &"accepting": _round(palette[&"raised"], 8.0, palette[&"accent"], 3), &"refusing": _round(palette[&"ground"], 8.0, palette[&"ink_soft"], 3)}
	# every state a lane passes through, its box and its words in the ink
	for state: StringName in lane:
		theme.set_stylebox(state, LANE, lane[state])
		theme.set_color(StringName("font_color_" + state), LANE, palette[&"ink"])
	theme.set_type_variation(BOARD_CARD, Themes.PRESSABLE)
	theme.set_stylebox(&"normal", BOARD_CARD, _round(palette[&"lit"], 10.0))
	theme.set_stylebox(&"hover", BOARD_CARD, _round(palette[&"lit"], 10.0, palette[&"ink_soft"], 2))
	theme.set_stylebox(&"lifted", BOARD_CARD, _round(palette[&"ground"], 10.0, palette[&"ink_soft"], 2))
	# every state a card's words are drawn in: the ink
	for state: StringName in [&"normal", &"hover", &"lifted"]:
		theme.set_color(StringName("font_color_" + state), BOARD_CARD, palette[&"ink"])


## A gallery: its pictures as a lazy picture's box, a thumbnail ringed in
## the accent while it is the one showing.
static func _gallery(theme: Theme, palette: Dictionary) -> void:
	# both of its pictures, a lazy picture's box
	for picture: StringName in [GALLERY_PICTURE, GALLERY_THUMB_PICTURE]:
		theme.set_stylebox(&"panel", picture, theme.get_stylebox(&"panel", LAZY_IMAGE))
	theme.set_type_variation(GALLERY_THUMB, Themes.PRESSABLE)
	var ringed := _box(palette[&"raised"], 4.0, palette[&"accent"], 4)
	theme.set_stylebox(&"selected", GALLERY_THUMB, ringed)
	theme.set_color(&"font_color_selected", GALLERY_THUMB, palette[&"ink"])


## A facet: the value picked marked along its foot as a chosen option is,
## its count in the soft ink, its title in the face's words, on no cell
## until a look gives it one.
static func _facets(theme: Theme, palette: Dictionary) -> void:
	theme.set_type_variation(FACET_PICKED, Themes.PRESSABLE)
	# every state of a picked value, the chosen option's box
	for state: StringName in STATES:
		theme.set_stylebox(state, FACET_PICKED, theme.get_stylebox(state, Pressables.CHOICE_CHOSEN))
	theme.set_type_variation(FACET_COUNT, &"Label")
	theme.set_color(&"font_color", FACET_COUNT, palette[&"ink_soft"])
	theme.set_font_size(&"font_size", FACET_COUNT, theme.get_font_size(&"font_size", Themes.REASON))
	theme.set_type_variation(FACET_CELL, Themes.SURFACE)
	theme.set_stylebox(&"panel", FACET_CELL, StyleBoxEmpty.new())
	theme.set_type_variation(FACET_TITLE, &"Label")
	theme.set_font_size(&"font_size", FACET_TITLE, theme.get_font_size(&"font_size", Themes.FACE))
	# a value's swatch: a lazy picture's box, round
	var disc := StyleBoxFlat.new()
	disc.bg_color = palette[&"lit"]
	disc.set_corner_radius_all(64)
	theme.set_stylebox(&"panel", FACET_SWATCH, disc)


## A flat box of one fill, padded this much every way, edged in a colour this thick if given one.
static func _box(fill: Color, pad: float, edge: Variant = null, thick: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_content_margin_all(pad)
	if edge != null:
		box.border_color = edge
		box.set_border_width_all(thick)
	return box


## The same box with its corners rounded, as a board's pieces are.
static func _round(fill: Color, pad: float, edge: Variant = null, thick: int = 0) -> StyleBoxFlat:
	var box := _box(fill, pad, edge, thick)
	box.set_corner_radius_all(6)
	return box
