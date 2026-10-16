extends "layout.gd"

const Local := preload("local.gd")
const Desc := preload("desc.gd")

## A part that stays on the line however short the room.
const KEEP := &"keep"
## A part that goes behind the line's menu press when the room runs short.
const MENU := &"menu"
## A part that goes to the page's first line when the room runs short.
const PAGE := &"page"
## A part that goes, and is not shown anywhere, when the room runs short.
const GONE := &"gone"

## A held line whose parts stand in rank order, the first the most needed:
## where the room runs short its parts take their short forms, the least
## needed first, and then fold, the least needed first - behind a menu
## press, to the page, or gone - each as its rank says. It never wraps.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHAT FOLDS IS A PURE FUNCTION OF THE ROOM (fold_at): every measure is a
## part's least width, never what it shows now, so a part whose words
## change stands in a slot holding its widest sample (room_for.gd) and
## what folds at one room is the same whatever the words. Two passes over
## the parts, the least needed first: the first puts each into its short
## form while the line is too long; the second folds each that may fold
## while it still is. A wider room needs fewer of either, so what folds
## never grows as the room widens.
##
## THE MENU PRESS is shown, and counted, while any part folding behind it
## is folded; it is KEEP. What a folded part becomes elsewhere - a line in
## the menu's sheet, a line at the head of the page - is whoever reads the
## folded names' (app_bar.gd): this writes them, in rank order, to a local
## each time they change, and shows none of it.
##
## ITS LEAST IS ITS KEEP PARTS IN THEIR SHORT FORMS, with the menu press
## where any part folds behind it, and the gaps between them: every other
## part may fold. Down, the tallest of every form of every part, shown or
## not, so the line keeps one height whatever folds. What it would take
## given all the room it wants is every part in its full form.
##
## EVERY FORM IS ONE OF WHAT IT HOLDS (described): each part's full form,
## its short form after it where it has one, and the menu press last, so
## the place it stands in declares what every form performs, folded or not.
##
## It is laid out as the row it is (layout.gd), its parts placed in rank
## order. It decides once it holds every form and its width is given, and
## again each time it is laid out: a part's least moving - another
## language - is a reason to.

var _ranked: Array = []  # in rank order: {name, folds, full, short}, short a Control or none
var _menu: Control = null  # the press the MENU parts fold behind, or none
var _folded: Local  # where the folded names are written, in rank order
var _awaited: Array = []  # what each form still to be built is: [rank, "full" or "short"], or the menu press, [-1, "menu"]


func _init(style: StringName, folded: Local, ranks: Array, menu: bool) -> void:
	super(ROW, style)
	_folded = folded
	# every part in rank order: held with its forms to come, which arrive in this order as they are built
	for rank: Dictionary in ranks:
		_ranked.append({"name": rank["name"], "folds": rank["folds"], "full": null, "short": null})
		_awaited.append([_ranked.size() - 1, "full"])
		if rank["short"]:
			_awaited.append([_ranked.size() - 1, "short"])
	if menu:
		_awaited.append([-1, "menu"])


## A form put in, as the builder builds them in order: each the next awaited.
func place(part: Control, facts: Dictionary = {}) -> void:
	var form: Array = _awaited.pop_front()
	if form[1] == "menu":
		_menu = part
	else:
		_ranked[form[0]][form[1]] = part
	super(part, facts)


## What this row does at a room this wide: which parts stand in their short
## forms and which are folded, each named in rank order - worked out from
## the parts' least widths alone, so the same room always answers the same.
func fold_at(room: float) -> Dictionary:
	var short: Array[StringName] = []
	var folded: Array[StringName] = []
	# the least needed first, each with a short form put into it while the line is longer than the room
	for at: int in range(_ranked.size() - 1, -1, -1):
		if _length(short, folded) <= room + 0.01:
			break
		if _ranked[at]["short"] != null:
			short.append(_ranked[at]["name"])
	# the least needed first, each that may fold folded while the line is still longer than the room
	for at: int in range(_ranked.size() - 1, -1, -1):
		if _length(short, folded) <= room + 0.01:
			break
		if _ranked[at]["folds"] != KEEP:
			folded.append(_ranked[at]["name"])
	# a part folded after it was made short stands in neither form
	var still_short: Array[StringName] = short.filter(func(named: StringName) -> bool: return not folded.has(named))
	return {"short": _in_rank(still_short), "folded": _in_rank(folded)}


## How long the line is with these parts short and these folded: the forms
## standing, the menu press where a MENU part is folded, and the gaps the
## line keeps between them, as it would place them.
func _length(short: Array[StringName], folded: Array[StringName]) -> float:
	var standing := _standing(short, folded)
	var length := 0.0
	# every form standing, end to end
	for part: Control in standing:
		length += part.get_combined_minimum_size().x
	# every gap between two standing, as wide as the shadows either side need
	for gap: float in DrawnReach.gaps(standing, DrawnReach.of_each(standing), _gap, true):
		length += gap
	return length


## The forms that stand with these parts short and these folded, in rank
## order, the menu press last where a MENU part is folded.
func _standing(short: Array[StringName], folded: Array[StringName]) -> Array[Control]:
	var standing: Array[Control] = []
	var menu_needed := false
	# every part in rank order: its form, unless folded, and whether a folded one goes behind the menu
	for part: Dictionary in _ranked:
		if folded.has(part["name"]):
			menu_needed = menu_needed or part["folds"] == MENU
			continue
		standing.append(part["short"] if short.has(part["name"]) else part["full"])
	if menu_needed:
		standing.append(_menu)
	return standing


## These names in the order of the parts' ranks.
func _in_rank(names: Array[StringName]) -> Array[StringName]:
	var ranked: Array[StringName] = []
	# every part in rank order, kept where it is named
	for part: Dictionary in _ranked:
		if names.has(part["name"]):
			ranked.append(part["name"])
	return ranked


## Its KEEP parts short with the menu press where any part folds behind it,
## across; down, the tallest form of every part, shown or not.
func _get_minimum_size() -> Vector2:
	# asked as its forms are built into it, before the last arrives: nothing, until then
	if not _awaited.is_empty():
		return Vector2.ZERO
	var everything_short: Array[StringName] = []
	var all_that_fold: Array[StringName] = []
	var tallest := 0.0
	# every part: short wherever it can be, folded wherever it may, and its forms' heights
	for part: Dictionary in _ranked:
		if part["short"] != null:
			everything_short.append(part["name"])
			tallest = maxf(tallest, (part["short"] as Control).get_combined_minimum_size().y)
		if part["folds"] != KEEP:
			all_that_fold.append(part["name"])
		tallest = maxf(tallest, (part["full"] as Control).get_combined_minimum_size().y)
	if _menu != null:
		tallest = maxf(tallest, _menu.get_combined_minimum_size().y)
	return Vector2(_length(everything_short, all_that_fold), tallest)


## What it would take given all the room it wants: every part in its full form.
func preferred_size() -> Vector2:
	return Vector2(_length([], []), get_combined_minimum_size().y) if _awaited.is_empty() else Vector2.ZERO


## A line that never wraps, whatever its style says.
func _read_look() -> void:
	super()
	set_wrap(false)
	_least_column = 0.0


## Before its parts are placed, once it holds them all and has a width: the forms for that
## width shown and the rest hidden, and the folded names written where they moved.
func _notification(what: int) -> void:
	if what != NOTIFICATION_PRE_SORT_CHILDREN or size.x <= 0.0 or not _awaited.is_empty():
		return
	var now := fold_at(size.x)
	var menu_shown := false
	# every part: its full form, its short form, or neither, as the room says
	for part: Dictionary in _ranked:
		var folded: bool = now["folded"].has(part["name"])
		var short: bool = now["short"].has(part["name"])
		menu_shown = menu_shown or (folded and part["folds"] == MENU)
		_show(part["full"], not folded and not short)
		if part["short"] != null:
			_show(part["short"], short)
	if _menu != null:
		_show(_menu, menu_shown)
	if now["folded"] != _folded.read():
		_folded.set_value(now["folded"])


## A form shown or hidden, touched only where that changes, since a change
## tells the line to place its parts again.
func _show(form: Control, shown: bool) -> void:
	if form.visible != shown:
		form.visible = shown


## A row of these parts in rank order, each {name, part, short, folds} -
## its short form left out where it has one form - writing what folds to
## this local, the menu press, or none, last: every form one of what the
## row holds, so the place it stands in declares what each performs.
static func described(parts: Array, folded: Local, menu: RefCounted, style: StringName) -> RefCounted:
	var forms: Array = []
	var ranks: Array = []
	# every part in rank order: its forms, and what the row must know of it
	for part: Dictionary in parts:
		forms.append(part["part"])
		if part.has("short"):
			forms.append(part["short"])
		ranks.append({"name": part["name"], "folds": part["folds"], "short": part.has("short")})
	if menu != null:
		forms.append(menu)
	return Desc.new(&"priority_row", {"ranks": ranks, "folded": folded, "menu": menu != null, "style": style}, forms)


## The builder's door: the row, its forms built into it in order after.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"priority_row").new(desc.props["style"], desc.props["folded"], desc.props["ranks"], desc.props["menu"])
	ui.attach(made, parent, desc.facts)
	return made
