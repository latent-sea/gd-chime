extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const LongList := preload("../../long_list.gd")
const GrowingList := preload("../../growing_list.gd")

## An infinite collection: a card a row, in equal columns as many as fit,
## the next page asked for as the reader nears the foot - a card standing
## in, the shape of what will land, for every row still on its way.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ITS MODEL IS A GROWING LIST (growing_list.gd): the items are its rows
## showing, keyed by their place, so a card is built once for its place and
## re-reads its row as it lands - the stand-in becomes the card in place,
## and nothing is built again when a page lands below it. THE CARD is the
## caller's template, handed a bound value of the row or null, and draws
## the null as the shape of a card: the skeleton.
##
## THE FOOT asks for more as the reader nears it (nearing.gd) and is a press
## of the same action, so a reader on the keys or the pad reaches the next
## page too, and the door's refusal - still loading, or everything showing -
## is on its face. Once everything shows it says so in the caller's words; a
## page that could not come says so beside a press asking again; a source
## holding nothing says the caller's words for nothing, never a blank.
##
## It is the content of a scroll, which the caller gives it: a collection
## is laid out and grows; where the reader stands is the scroll's.
##
## Deliberately absent: pages let go above the reader, and cards of more
## than one column.

## The line the cards are laid in: a wrapping row naming least_column.
const CARDS := &"CollectionCards"
## The foot's press, asking for more.
const MORE := &"CollectionMore"
## The collection's column, the cards over the foot.
const COLUMN := &"Collection"


## The cards over the foot: the card template, handed a bound value of a
## row or null; the words - {more, everything, failed, again, empty} -
## phrases, the caller's.
static func make(ui: Ui, list: GrowingList, card: Callable, says: Dictionary) -> Desc:
	var cards := ui.each_across(ui.bound(list.get_items), func(slot: Bound) -> Desc: return card.call(slot.field("item")), func(slot: Dictionary) -> int: return slot["at"], CARDS)
	var more := ui.nearing(GrowingList.GROWS, {}, [ui.pressable(GrowingList.GROWS, {}, [ui.text(says["more"], Themes.FACE), ui.reason(Themes.REASON)], MORE)])
	var foot := ui.when(ui.bound(list.get_more), more, ui.text(says["everything"], Themes.REASON))
	var failed := ui.when(ui.bound(list.get_failed), ui.row([ui.text(says["failed"], Themes.REASON), ui.pressable(LongList.ASK_AGAIN, {}, [ui.text(says["again"], Themes.FACE)], MORE)]))
	# the cards kept while the words for nothing show, so filling again builds nothing
	return ui.when(ui.bound(list.get_empty), ui.text(says["empty"], Themes.WORDS).wraps(), ui.column([cards, failed, foot], COLUMN)).keeps()
