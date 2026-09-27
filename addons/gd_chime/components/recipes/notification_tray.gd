extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Notifications := preload("../../notifications.gd")
const Phrase := preload("../../phrase.gd")
const TrayStand := preload("../primitives/tray_stand.gd")
const Pressables := preload("../../theme_pressables.gd")
const Feedback := preload("../../theme_feedback.gd")

## The notification tray: where the application's notifications stand
## (notifications.gd), ONE AT A TIME - on one line, the press of its offer
## when it has one and a press that dismisses it, then its words, then how
## many more are waiting. The presses lead, at the tray's leading edge, so
## the pad walking down from what stands above reaches them.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ROOM FOR ONE, CLEARED ONE BY ONE, as was ruled (2026-09-19): the oldest
## notification standing shows, and the others wait their turn in the order
## they came - the next stands only when the one showing is cleared, by its
## dismissal, its offer done or its stay run out (notifications.gd, whose
## time passes for the one showing alone). At the end of the same line the
## words say how many are waiting ("2 more"), so a queue never asks for a
## line of its own.
##
## IT HOLDS ITS ROOM, WHETHER ANY STANDS OR NOT, AND IT NEVER GROWS, as was
## ruled: the layout above is locked, and a notification arriving, waiting
## or leaving never shudders it. The room is one notification as tall as a
## SAMPLE is (tray_stand.gd): a notification described as the one showing is
## and never shown, its words as many lines as the look allows one - LINES,
## under the look's Notice, each as wide as LETTERS of the widest letter,
## the least a line of words is given - on one line with the widest offer, the
## dismissal and the waiting count, so the room is as tall as the taller of
## the words and a press. That is all a notice honestly needs: a refused
## offer's reason is not given a line of room it seldom uses, but shows on
## the offer's face within the room, as words past the look's lines do -
## both scroll inside it, the notice standing in a scroll that fills the
## room, and the notifications report such words as they are made, a fault
## of whoever wrote them (tray_stand.gd's fits). It is a piece of the layout
## like any other, so nothing is drawn over it and it is drawn over nothing.
## The next arriving comes in as the look moves an each (each.gd), keyed by
## its id - and the focus, if it was on the one that went, is handed to the
## next control that takes it.
##
## IT TAKES NO FOCUS, and is REACHED like any other part of the screen: the
## keys and the pad walk to its presses by where they stand (interaction.gd),
## and while the focus is on one the notification's time does not pass. The
## offer is a button of its action, carrying the notification's payload and
## going where offers says that action goes, refused by the door as any
## button is, its reason on its face; a notification's offer must be one of
## offers, so the place declares it before any has arrived. The dismissal is
## the notifications' own command, whose words the application declares in
## its register beside its offers'.
##
## IT STANDS ON ITS MARK (tray_stand.gd), which tells the notifications a
## tray stands while it is in the tree: one made while none does is
## reported, and a count of them elsewhere is no tray.

## How many the sample says are waiting: as wide as any count a reader will see.
const MOST_WAITING := 99


## The tray: the notification showing, on the look's NOTICE ground, in the
## room of one, with how many wait; offers maps each action a notification
## may offer to where its press goes - a place, or nothing.
static func make(ui: Ui, notifications: Notifications, offers: Dictionary = {}, style: StringName = Themes.COLUMN) -> Desc:
	var standing: Bound = ui.bound(notifications.get_standing)
	var showing: Bound = standing.map(showing_of)
	var waiting: Bound = standing.map(func(all: Array) -> Variant: return null if all.size() <= 1 else Phrase.counted("%d more", "%d more", all.size() - 1))
	var list := ui.each(showing, func(notice: Bound) -> Desc: return _one(ui, notice, offers, waiting), func(one: Dictionary) -> int: return one["id"], style)
	var room := {"notifications": notifications, "style": Themes.COLUMN, "sample": _sample.bind(ui, offers)}
	return Desc.new(&"tray_stand", room, [ui.scroll(list).grow()])


## The notification that shows of all standing: the oldest alone, the rest
## waiting their turn - or none, while none stands.
static func showing_of(all: Array) -> Array:
	return all.slice(0, 1)


## One notification: its presses, its words broken at the width left them,
## and how many wait after it.
static func _one(ui: Ui, notice: Bound, offers: Dictionary, waiting: Bound) -> Desc:
	var presses: Array = []
	# a press for each action a notification may offer, shown for the one this offers
	for offer: StringName in offers:
		var offered := notice.map(func(one: Variant) -> bool: return one != null and one["offer"] == offer)
		presses.append(ui.when(offered, ui.button(offer, {payload = notice.map(func(one: Variant) -> Dictionary: return one["payload"] if one != null else {}), goes_to = offers[offer]})))
	presses.append(ui.button(Notifications.DISMISSES, {payload = notice.map(func(one: Variant) -> Dictionary: return {"notice": one["id"] if one != null else 0})}))
	return ui.surface(Themes.NOTICE, [ui.row(presses + [ui.text(notice.field("words"), Themes.FACE).wraps().grow(), ui.text(waiting, Themes.REASON).hides_empty().named(&"waiting")])])


## The sample the room is measured by, made as the tray is built
## (tray_stand.gd): words of as many lines as the look allows, each as many
## of the widest letter as the look says a line holds at least, after the
## widest offer and the dismissal, before the most a count says - each press
## drawn as a button is with no reason under it, but a press of a local of
## its own, so no door is asked about a notification that is not there. The
## look is the one the tray is built under, where it stands: a themed
## piece's, or the root's (built_within.gd).
static func _sample(ui: Ui, offers: Dictionary) -> Desc:
	var look: Theme = ui.current_look()
	# a constant of the notice in that look, or, built under none, in the root's
	var notice := func(name: StringName) -> int: return look.get_constant(name, Themes.NOTICE) if look != null else ui.root.get_theme_constant(name, Themes.NOTICE)
	var lines: int = notice.call(Feedback.LINES)
	var line := TrayStand.LETTER.repeat(notice.call(Feedback.LETTERS))
	var actions: Array = []
	if not offers.is_empty():
		actions.append(Array(offers.keys()).reduce(func(wide: StringName, offer: StringName) -> StringName: return offer if str(ui.words(offer)).length() > str(ui.words(wide)).length() else wide))
	actions.append(Notifications.DISMISSES)
	var nowhere := ui.local(null)
	var row: Array = actions.map(func(action: StringName) -> Desc: return ui.press_local(nowhere, null, [ui.column([ui.text(ui.words(action), Themes.FACE)], Themes.COLUMN)], Pressables.BUTTON))
	row.append(ui.text("\n".join(PackedStringArray(range(lines).map(func(_line: int) -> String: return line))), Themes.FACE))
	row.append(ui.text(Phrase.counted("%d more", "%d more", MOST_WAITING), Themes.REASON))
	return ui.surface(Themes.NOTICE, [ui.row(row)])
