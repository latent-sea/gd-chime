extends RefCounted

const Themes := preload("res://addons/gd_chime/theme.gd")
const Look := preload("res://addons/gd_chime/look.gd")
const Paint := preload("res://addons/gd_chime/paint.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")
const Navigation := preload("res://addons/gd_chime/theme_navigation.gd")

## SKEUOMORPHISM'S PAPER AND SLATE: the objects a stall and a desk are made
## of - the counter, a pinned ticket, a ledger page, cork, a clipboard, the
## chalkboard - and a paper form filled in on a leather desk: a sheet of card
## ruled at its margin, index-card dividers for its steps, a slip pinned to
## the page for what needs attention, a ledger page for each step reviewed,
## a slip of ledger clipped in for a section, and a calendar of small plates.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## skeuomorphic.gd dresses the plates, the boards and the words and hands
## itself here for the objects; everything is from its palette and its
## numbers - the ticket's card, the ledger's paper, the walnut, the counter's
## leather, the brass - so a form reads as the same stall's paperwork.

## The card a ticket and a form's page are cut from, and its edge; the ledger's paper and its edge.
const CARD := Color("#f5ecd6")
const CARD_EDGE := Color("#b9a67c")
const LEDGER := Color("#efe4c6")
const LEDGER_EDGE := Color("#a99a74")
## The tan of a divider standing out of the counter.
const DIVIDER := Color("#c3ab7f")
## Words written on an object rather than on a page: a note on the cork.
const PINNED := &"Pinned"


## The objects of a physical stall: the counter the dividers stand on, a
## pinned ticket, a ledger page, a cork pinboard, a clipboard and the
## chalkboard along the bottom.
static func stall(look: Theme) -> void:
	# the counter the dividers stand on, holding the day's trade: leather bordered in walnut and stitched just inside
	Look.ground(look, &"TabPanel", Look.layered(look, [Look.flat(look.COUNTER, {radius = 8.0, border = 2.0, border_colour = look.WALNUT}), Paint.bevel(&"sheen", &"hollow", 3.0), look.stitch(&"stitch_deep", 9.0)], 18.0))
	# the dividers stand along its top edge, shoulder to shoulder, with nothing between them and it
	Look.line(look, &"TabStrip", Themes.ROW, 3, Look.START, Look.END)
	Look.line(look, &"TabSet", Themes.COLUMN, 0)
	Look.ground(look, &"Ticket", ticket(look))
	Look.ground(look, &"Ledger", ledger(look))
	# cork, and the board a clipboard is cut from
	Look.ground(look, &"Pinboard", Look.layered(look, [Look.flat(Color("#b78f55"), {radius = 4.0, border = 3.0, border_colour = Color("#7b5c32")}), Paint.bevel(&"hollow", &"sheen", 3.0)], 14.0))
	# a note written on the cork: the page's own ink, since the soft ink a page is read in does not stand out on the board's tan
	Look.words(look, PINNED, 21, Look.font(["Segoe UI", "Verdana", "Arial"]), look.PALETTE[&"ink"])
	Look.ground(look, &"Clipboard", Look.layered(look, [Look.flat(Color("#6b4a2c"), {radius = 6.0, border = 2.0, border_colour = look.WALNUT, shadow = 14.0, shadow_colour = Color(0.0, 0.0, 0.0, 0.45), shadow_offset = Vector2(0.0, 5.0)}), Paint.bevel(&"sheen", &"hollow", 3.0)], 16.0))
	# slate in a walnut frame, the chalk written on it
	Look.ground(look, &"Chalkboard", Look.layered(look, [Look.flat(Color("#2e352f"), {radius = 5.0, border = 6.0, border_colour = Color("#4a3319")}), Paint.bevel(&"hollow", &"slate_sheen", 3.0)], 14.0))


## A form on a leather desk: its page a sheet of card ruled at its margin,
## its steps index-card dividers, its words printed on the card.
static func form(look: Theme) -> void:
	var ink: Color = look.PALETTE[&"ink"]
	# the desk: the shell's frame in the counter's leather, bordered in walnut
	Look.ground(look, &"Pane", Look.layered(look, [Look.flat(look.COUNTER, {radius = 8.0, border = 2.0, border_colour = look.WALNUT}), Paint.bevel(&"sheen", &"hollow", 3.0)], 18.0))
	# the foot of the desk: the same leather, its edge stitched, so what is written on it is written on the counter and not on a pale slab laid over it
	Look.ground(look, Navigation.SHELL_FOOT, Look.layered(look, [Look.flat(look.COUNTER, {radius = 6.0}), look.stitch(&"stitch_deep", 6.0)], 12.0))
	# what the application says of itself, written on that leather in the light tan a title on it is
	look.set_color(&"font_color", Navigation.STATUS, look.PALETTE[&"lit"])
	# a page: the ticket's card, lifted off the leather, ruled at its margin in the amber a printed line is
	Look.ground(look, Fields.PAGE, Look.layered(look, [Look.flat(CARD, {radius = 3.0, border = 1.0, border_colour = CARD_EDGE, shadow = 16.0, shadow_colour = Color(0.0, 0.0, 0.0, 0.45), shadow_offset = Vector2(0.0, 6.0)}), Paint.rule(&"amber_deep", 2.0, SIDE_LEFT, 18.0)], 36.0))
	# printed on the card: the step's name in the look's serif, walnut; a message in the deep amber, never the pale one
	Look.words(look, Fields.HEADING, 34, Look.font(["Georgia", "Cambria", "Times New Roman"]), look.WALNUT)
	look.set_color(&"font_color", Fields.MESSAGE, look.PALETTE[&"amber_deep"])
	# a section: a slip of ledger clipped into the page; what needs attention, a ticket pinned to it, a brass bar down its edge; a step reviewed, a ledger page
	Look.ground(look, Fields.SECTION, ledger(look))
	Look.ground(look, Fields.SUMMARY, Look.layered(look, [ticket(look), Paint.left_bar(&"accent", 6.0)], 16.0))
	Look.ground(look, Fields.REVIEW_STEP, ledger(look))
	# the steps: index-card dividers standing along the desk's top edge
	Look.line(look, Fields.STEPS, Themes.TILES, 3, Look.START, Look.END)
	# each look a step may wear, its own card: done in the plate's light face, needing attention in brass; the one you are on in the page's own card
	for step: Array in [[Fields.STEP, DIVIDER], [Fields.STEP_DONE, look.PALETTE[&"face_top"]], [Fields.STEP_NEEDS, look.PALETTE[&"brass_top"]]]:
		Look.pressable(look, step[0], {&"normal": look.divider(step[1], 10.0), &"hover": look.divider(look.PALETTE[&"face_top"], 10.0), &"inert": look.divider(step[1], 10.0), &"glowing": look.divider(look.PALETTE[&"brass_top"], 10.0), &"current": Look.flap(CARD, {radius = 9.0, pad_top = 14.0, pad = 12.0})}, {&"normal": ink, &"hover": ink, &"inert": ink, &"glowing": look.WALNUT, &"current": ink}, look.focus_ring(4.0))
	# a link printed on the card: underlined in the deep amber, as the look's inline words are
	Look.pressable(look, &"Link", {
		&"normal": Look.layered(look, [Paint.underline(&"amber_deep", 2.0, 2.0)], 8.0),
		&"hover": Look.layered(look, [Paint.underline(&"accent", 3.0, 2.0)], 8.0),
		&"inert": Look.layered(look, [], 8.0),
		&"glowing": Look.layered(look, [Paint.underline(&"accent", 3.0, 2.0)], 8.0),
	}, {&"normal": Color("#7a4f10"), &"hover": Color("#8a5a14"), &"inert": look.DEAD_INK, &"glowing": Color("#7a4f10")}, look.focus_ring(4.0))
	# a calendar's days: small plates close together; the day held in brass, today ringed, another month's in the soft ink
	Look.line(look, Fields.WEEK, Themes.ROW, 4)
	var day := {&"normal": look.plate(&"face_top", &"face_bottom", 5.0, 6.0), &"hover": look.plate(&"pressed_top", &"pressed_bottom", 5.0, 6.0, true), &"inert": look.dead(5.0, 6.0), &"glowing": look.plate(&"brass_top", &"brass_bottom", 5.0, 6.0, false, 3.0)}
	var inks := {&"normal": ink, &"hover": ink, &"inert": look.DEAD_INK, &"glowing": look.WALNUT}
	Look.pressable(look, Fields.DAY, day, inks, look.focus_ring(5.0))
	# a day of another month: the soft ink taken part way to the page's own, so it is quieter than a day of this month and still stands out from the plate it is printed on
	Look.pressable(look, Fields.DAY_OUTSIDE, day, inks.merged({&"normal": look.PALETTE[&"ink_soft"].lerp(ink, 0.3)}, true), look.focus_ring(5.0))
	Look.pressable(look, Fields.DAY_CHOSEN, day.merged({&"normal": day[&"glowing"]}, true), inks.merged({&"normal": look.WALNUT}, true), look.focus_ring(5.0))
	Look.pressable(look, Fields.DAY_TODAY, day.merged({&"normal": Look.layered(look, [day[&"normal"], Look.ring(look.PALETTE[&"accent"], {width = 3.0, radius = 5.0})], 6.0)}, true), inks, look.focus_ring(5.0))


## A ticket: pale card, squarely cut, casting a small shadow as if pinned.
static func ticket(look: Theme) -> StyleBox:
	return Look.layered(look, [Look.flat(CARD, {radius = 3.0, border = 1.0, border_colour = CARD_EDGE, shadow = 10.0, shadow_colour = Color(0.0, 0.0, 0.0, 0.40), shadow_offset = Vector2(0.0, 4.0)}), Paint.bevel(&"sheen", &"hollow", 1.0)], 14.0)


## A ledger page: unbevelled paper, ruled at its edge.
static func ledger(look: Theme) -> StyleBox:
	return Look.layered(look, [Look.flat(LEDGER, {radius = 2.0, border = 1.0, border_colour = LEDGER_EDGE}), look.stitch(&"stitch_pale", 6.0)], 14.0)
