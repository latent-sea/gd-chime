extends "components/primitives/text.gd"

## Words drawn in their own kind where they fit, and stepped down toward
## the size of a smaller kind, the floor kind, until they do: a name in a
## narrow block, written as large as its room allows and never cut.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## FITTED IN SO MANY LINES: at the width it has, its words are drawn at the
## largest size, from its own kind's down to the floor kind's, at which
## they take no more than its lines, none wider than that width - one line
## unless more are allowed, in which case they wrap. At the floor kind's
## size they stand however they must: its least is what they need there,
## so they fit by construction, and they are never cut (clipped_text.gd).
## Only the size steps; the colour and the font stay its own kind's.
##
## ITS LEAST IS ITS WIDTH AT THE FLOOR KIND'S SIZE: all its words on one
## line there, or, where it may wrap, its widest word there - so its least
## never moves with the room it is given, only with its words and the look.
## What it would take given all the room it wants is its words on one line
## in its own kind (preferred.gd).
##
## IT STANDS WITH THE FLOOR'S OWN MACHINERY, not among the components: it
## sets the size its words are drawn at, which a component never does
## (convention_lint.py), and every size it sets lies between two the look
## names. It fits its words again whenever its width, its words or the look
## move.

var _floor_kind: StringName  # the kind whose size is the least its words step down to
var _lines: int  # the most lines its words may take before they step down
var _at_floor := WordMeasure.new()  # its words measured at the floor kind's size, for its least
## The size its words are drawn at now, from its own kind's down to the floor kind's.
var fitted_at: int = 0


func _init(chimes: Chimes, content: Variant, style: Variant, in_region: StringName, hides_empty: bool, floor_kind: StringName, lines: int) -> void:
	super(chimes, content, style, in_region, hides_empty, lines > 1)
	_floor_kind = floor_kind
	_lines = lines


## What the label needs down at the size it is drawn, and across what its
## words need at the floor kind's size: one line of them, or, where they
## may wrap, the widest word - with the box they are set in.
func _get_minimum_size() -> Vector2:
	var least := _label.get_minimum_size()
	var floor_size := get_theme_font_size(&"font_size", _floor_kind)
	var across := _at_floor.one_line(_label, floor_size) if _lines == 1 else _at_floor.widest(_label, floor_size)
	least.x = across + _label.get_theme_stylebox(&"normal").get_minimum_size().x
	return least


## What it would take given all the room it wants (preferred.gd): its words
## on one line in its own kind's size; never under its least.
func preferred_size() -> Vector2:
	var least := get_combined_minimum_size()
	var own := get_theme_font_size(&"font_size", _label.theme_type_variation)
	return Vector2(maxf(least.x, _measure.one_line(_label, own) + _label.get_theme_stylebox(&"normal").get_minimum_size().x), least.y)


## Said again: what it needs asked again, as its words may need another
## least at the floor's size, and its words fitted to its width.
func refresh() -> void:
	var before := _label.text
	super()
	if _label.text != before:
		update_minimum_size()
		Preferred.moved(self)
	_fit()


## Resized or dressed again, its words fitted again; dressed again, the
## measure at the floor's size let go, since the look names its sizes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_at_floor.forget()
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		_fit()


## Its words drawn at the largest size, from its own kind's down to the
## floor kind's, at which they take no more than its lines, none wider
## than the width it has. Not yet given a width, they are left as they are.
func _fit() -> void:
	var room: float = size.x - _label.get_theme_stylebox(&"normal").get_minimum_size().x
	if room <= 0.0:
		return
	var font := _label.get_theme_font(&"font")
	var paragraph := TextParagraph.new()
	# broken only where a line may break between words or must, as the label breaks them
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | _label.autowrap_trim_flags
	var fits := func(at: int) -> bool:
		paragraph.clear()
		paragraph.add_string(_label.text, font, at, _label.language)
		paragraph.width = room
		# no more lines than allowed, and none of them wider than the room
		return paragraph.get_line_count() <= _lines and range(paragraph.get_line_count()).all(func(line: int) -> bool: return paragraph.get_line_width(line) <= room + 0.5)
	var low := get_theme_font_size(&"font_size", _floor_kind)
	var high := get_theme_font_size(&"font_size", _label.theme_type_variation)
	# halving the sizes between the floor's, which always stands, and its own, for the largest at which the words fit
	while low < high:
		var middle := (low + high + 1) / 2
		if fits.call(middle):
			low = middle
		else:
			high = middle - 1
	if low != fitted_at:
		fitted_at = low
		_label.add_theme_font_size_override(&"font_size", low)


## The builder's door for words fitted by their size (desc.gd, fits_by_size).
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	# hidden while empty where described so, unless described to hold its line then
	var hides: bool = desc.props["hides_empty"] and not desc.props.has("holds_room")
	var made: Control = ui.primitive(&"fitted_text").new(ui.chimes, desc.props["content"], desc.props["style"], ui.region(), hides, desc.props["floor_kind"], desc.props["lines"])
	ui.attach(made, parent, desc.facts)
	return made
