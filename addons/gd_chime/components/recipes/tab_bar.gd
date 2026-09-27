extends RefCounted

const Themes := preload("../../theme.gd")
const Chimes := preload("../../chimes.gd")
const Driver := preload("../../driver.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const NavControl := preload("nav_control.gd")
const Scroll := preload("../primitives/scroll.gd")
const Documents := preload("../../documents.gd")

## Tabs: switching between views of the same subject without leaving it.
## A tab is a place, so it is in the history: each tab is a navigation
## control to its place, and Back returns the tab that was open.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A TAB IS A FLAP ON THE PANEL IT REVEALS, not a button above unrelated
## content: the flaps sit on the panel's top edge with nothing between,
## bottom-aligned so the current one - the flap of the place the reader is
## on, drawn in the pressable's CURRENT state - stands taller and merges
## into the panel in the panel's own fill, and the rest sit back on the
## baseline. So the set is one thing: `make(ui, tabs, content)` gives the
## flaps over a panel holding the content, under the styles TabStrip (the
## flaps' row, bottom-aligned, no gap), TabPanel (the ground the current
## flap merges into) and TabSet (the column of the two, no gap). Given no
## content, the flaps alone - a strip - for an arrangement that has the
## panel elsewhere.
##
## FLAPS WIDER THAN THEIR ROOM SCROLL ACROSS, never wrap and never cut: a
## second row of flaps would stand off the panel it opens, and a cut flap
## is a word lost. The strip is a scroll across alone, as tall as its flaps,
## with no bar between them and the panel. It shows whole flaps only
## (strip.gd), moving a flap at a time, and an end with more flaps beyond it
## is covered by the look's mark; a flap the focus moves to comes into
## view, and the strip keeps where it stands as the tabs change.
##
## THE CURRENT FLAP IS ALWAYS IN VIEW: however the reader came to a place -
## a press, the driver, Back - the strip ends the move showing its flap, as
## a scroll brings a piece it is given the name of into view. So each flap
## is named for the place it opens, "flap to <place>", and a place has one
## set of flaps: a second flap to the same place is a second of a name,
## refused out loud (index.gd).
##
## THE TABS OF OPEN DOCUMENTS ARE NOT PLACES: a file open in an editor is a
## model's fact (documents.gd), come and gone as the reader opens and closes
## it, and Back never walks the files. documents() gives one flap per
## document open, in the model's order, each the document's words - pressed,
## it comes to the front - and a mark that closes it; the flap of the one in
## front stands CURRENT by the model's say (pressable.gd's current_while),
## in the look's own current box, and is always brought into view.

## The mark a document's flap is closed by: data, the same in every language.
const CLOSE_MARK := "x"
## What a document's flap is named for, before its value.
const DOCUMENT_FLAP := &"document flap "


## The flaps over the panel: one flap per tab, each {action, goes_to}, and
## the panel holding the content beneath; the strip alone when no content.
static func make(ui: Ui, tabs: Array, content: Array = [], style: StringName = &"TabStrip") -> Desc:
	var flaps: Array = []
	# every tab, a flap growing to share the strip's room, named for its place
	for tab: Dictionary in tabs:
		flaps.append(NavControl.menu(ui, tab["action"], tab["goes_to"], &"Tab").grow().named(_flap_to(tab["goes_to"])))
	# the flap of the place the reader is on, or none while they are on none of these, read again as they move
	var current := Bound.new(func() -> Variant:
		# every tab, for the first whose place the reader is on
		for tab: Dictionary in tabs:
			if ui.driver.get_top().has(tab["goes_to"]):
				return _flap_to(tab["goes_to"])
		return null)
	var strip := ui.scroll(ui.row(flaps, style), current, Scroll.ACROSS)
	if content.is_empty():
		return strip
	return ui.column([strip, ui.surface(&"TabPanel", content).grow()], &"TabSet")


## The flaps of the documents open (documents.gd): one per document in the
## model's order, its words bringing it to the front and a mark closing it,
## the one in front current and kept in view - a strip, for an arrangement
## to stand over the document's own panel.
static func documents(ui: Ui, open: Documents, style: StringName = &"TabStrip") -> Desc:
	var flap := func(document: Bound) -> Desc:
		# the document's value, or none for a flap on its way out, which the model refuses
		var carried: Bound = document.map(func(entry: Variant) -> Dictionary: return {"value": null if entry == null else entry["value"]})
		var front: Bound = open.is_front(document)
		var words := ui.pressable(Documents.OPENS, carried, [ui.text(document.field("words"), Themes.FACE)], &"Tab").current_while(front)
		var close := ui.pressable(Documents.CLOSES, carried, [ui.text(CLOSE_MARK, Themes.FACE)], &"Tab").current_while(front)
		return ui.row([words, close], &"DocumentFlap")
	var identity := func(entry: Dictionary) -> Variant: return entry["value"]
	# the flap of the document in front, read again as the documents move
	var in_front: Bound = ui.bound(open.get_front).map(func(value: Variant) -> Variant: return null if value == null else StringName("%s%s" % [DOCUMENT_FLAP, value]))
	return ui.scroll(ui.each_across(ui.bound(open.get_open), flap, identity, style).pieces_named(DOCUMENT_FLAP), in_front, Scroll.ACROSS)


static func _flap_to(place: StringName) -> StringName:
	return StringName("flap to %s" % place)
