extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Local := preload("../primitives/local.gd")
const Phrase := preload("../../phrase.gd")

## Sections: one collection grouped under headings - a list shown the way it
## divides, and a settings page whose rows stand in groups. The heading, how
## many are under it and what is under it are one piece per group.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The grouping is the MODEL's: it answers an array of groups, each with its
## identity, its heading and its own items, already in the order and the
## division it wants, so moving an item between groups, renaming a heading
## and sorting within one are all a read of the model moving. The recipe
## holds no grouping at all. The groups are kept by their id and the items
## within a group by the template's key, so an item arriving builds one
## piece and every other group is left untouched - a focus, a typed line and
## a scroll all survive a regrouping. A group with nothing in it still shows
## its heading, and says it is empty, so a division the reader is looking
## for never simply vanishes. static_groups is the same shape with no model
## behind it: fixed content under fixed headings.
##
## A HEADING SHUTS AND OPENS WHAT IS UNDER IT. Which sections are open is
## the interface's own and no fact of the game, so it is a local (local.gd)
## and the heading a local press: no command, nothing recorded. The local
## is KEPT with the view, so a detour and Back find the same sections open;
## what is under a shut heading is hidden, not freed, so a half-typed line
## in it survives. The heading wears a mark in words, never a hue alone.
##
## The count, the empty group's words and a fixed heading go to the text in
## English, said in the language on as it draws; a heading the model
## answers is its data, shown as it is.

const SECTION := &"Section"
const EMPTY := "This group is empty"
const HEADING := &"SectionHeading"
## The mark a heading wears: open, and shut.
const OPEN := "-"
const SHUT := "+"


## The sections: a scroll over one piece per group, each its heading, how
## many it holds, and its items from the template by their key.
## Its options: key, what an item is kept by; style; and heading_kind, the
## kind a section's heading is said in.
const OPTIONS: Array[String] = ["key", Options.STYLE, "heading_kind"]

static func make(ui: Ui, groups: Bound, template: Callable, options: Dictionary = {}) -> Desc:
	Options.checked("sections", options, OPTIONS)
	var key: Callable = options["key"]
	var style: StringName = options.get(Options.STYLE, &"Sections")
	var heading_kind: StringName = options.get("heading_kind", Themes.FACE)
	var group_template := func(group: Bound) -> Desc:
		var items: Bound = group.field("items")
		var under := ui.when(items.map(_any), ui.each(items, template, key), ui.text(Phrase.of(EMPTY), Themes.REASON))
		return _section(ui, [ui.text(group.field("heading"), heading_kind), ui.text(items.map(_counted), Themes.REASON).hides_empty()], [under])
	var identity := func(group: Dictionary) -> Variant: return group["id"]
	return ui.scroll(ui.each(groups, group_template, identity, style))


## Fixed content under fixed headings - the settings rows of a page: one
## column per group, its heading over what it was given, and no model.
static func static_groups(ui: Ui, groups: Array, options: Dictionary = {}) -> Desc:
	Options.checked("static sections", options, OPTIONS)
	var style: StringName = options.get(Options.STYLE, &"Sections")
	var heading_kind: StringName = options.get("heading_kind", Themes.FACE)
	var sections: Array = []
	# every group given, its heading over its content, in the order written
	for group: Dictionary in groups:
		sections.append(_section(ui, [ui.text(group["heading"], heading_kind)], group["content"]))
	return ui.scroll(ui.column(sections, style))


## One section: its heading - a mark and these words, pressed to shut and
## open it - over what is under it, open to begin with and kept with the view.
static func _section(ui: Ui, heading: Array, under: Array) -> Desc:
	var open: Local = ui.local(true).kept()
	var mark := ui.text(open.map(func(is_open: bool) -> String: return OPEN if is_open else SHUT), Themes.FACE)
	var pressed := ui.press_local(open, func(is_open: bool) -> bool: return not is_open, [ui.row([mark] + heading)], HEADING)
	return ui.column([pressed, ui.when(open, ui.column(under), null).keeps()], SECTION)


## How many a group holds, as a phrase the text says as it draws - "no
## items" for none, else the catalogue's plural for the count; nothing at
## all for the empty handle a place describes with.
static func _counted(items: Variant) -> Variant:
	if items == null:
		return ""
	return Phrase.counted("%d item", "%d items", items.size(), "No items")


## Whether a group holds anything.
static func _any(items: Variant) -> bool:
	return items != null and not items.is_empty()
