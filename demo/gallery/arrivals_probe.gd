extends RefCounted

const Fetched := preload("res://addons/gd_chime/fetched.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Sounds := preload("res://addons/gd_chime/sounds.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Models := preload("res://demo/gallery/arrivals_models.gd")
const ArrivalsPieces := preload("res://demo/gallery/arrivals_pieces.gd")
const Hands := preload("res://tests/hands.gd")
const Feedback := preload("res://addons/gd_chime/theme_feedback.gd")

## The arrivals screen walked by a reader's hands and reported, beside the
## gallery's other screens' probes (values_probe.gd): run by the gallery
## started with --probe.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Loading: shown, the stock is on its way - the mark and its word, counting
## refused "Still loading" on its face; a click lands it and the content
## stands, counting then pressed by Enter; the pad's A asks again and it is
## loading once more, and a click lands that asking. The note: its long line
## broken across lines, words typed into it, sent by a click and then
## refused "Nothing written yet"; the pad walks up into it and, after typing,
## down out of it to the send, which its A presses. Notifications: one sent
## by a click and one with an offer by Enter, the two standing oldest first
## and the look's sound played for each - the floor's placeholder chime,
## every look's until it sets its own; the pad walks down into the tray,
## and while the focus is there it does not leave, however long; the first
## dismissed by a click, the one with the offer stands next, and its offer
## pressed by the pad does its action and takes it away; and two more, left
## alone, stand one after the other, each for the look's stay and not a
## moment longer.
##
## THE NOTIFICATIONS ARE COUNTED BY HAND from here on, and two are LEFT
## STANDING - one long enough to break, one with its offer - so that the
## tray is looked at full, at every window shape, with everything else.

## Every claim this walks.
const CLAIMS := ["loading_by_mouse_keys_pad", "text_area_by_mouse_keys_pad", "notifications_by_mouse_keys_pad"]

var _stall: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(stall: SceneTree) -> void:
	_stall = stall
	_hands = Hands.new(stall)


## Every claim, walked in turn and handed back by name.
func run() -> Dictionary:
	# every claim false until it is walked, so a walk that stops short fails rather than goes unsaid
	for claim: String in CLAIMS:
		_said[claim] = false
	(_stall.notifications as Notifications).by_hand = true
	await _hands.goes(ArrivalsPieces.ARRIVALS)
	await _loading()
	await _note()
	await _notices()
	return _said


func _place() -> Node:
	return _hands.place(ArrivalsPieces.ARRIVALS)


func _press(action: StringName) -> Pressable:
	return _hands.presses_of(action, {under = _place()})[0]


func _loading() -> void:
	var stock: Models.Stock = _stall.stock
	var count := _press(Models.Stock.COUNTS)
	var waiting: bool = not stock.delivery.data.read() != null and _hands.texts(_place()).has("Loading") and not count.is_usable() and _hands.texts(count).has("Still loading")
	await _hands.click(_press(Models.Stock.LANDS))
	var clicked: bool = stock.delivery.data.read() != null and _hands.texts(_place()).has("Forty crates of plums") and count.is_usable()
	count.grab_focus()
	await _hands.key(KEY_ENTER)
	var keyed: bool = str(stock.get_counted()) == "Counted: sixty-one crates"
	_press(Fetched.ASKS_AGAIN).grab_focus()
	await _hands.pad(JOY_BUTTON_A)
	var padded: bool = not stock.delivery.data.read() != null and _hands.texts(_place()).has("Loading")
	await _hands.click(_press(Models.Stock.LANDS))
	_said["loading_by_mouse_keys_pad"] = waiting and clicked and keyed and padded and stock.delivery.data.read() != null


func _note() -> void:
	var draft: Models.Draft = _stall.draft
	var edit: TextEdit = _place().find_children("*", "TextEdit", true, false)[0]
	var send := _press(Models.Draft.SENDS)
	var broken: bool = edit.get_total_visible_line_count() > edit.get_line_count()
	edit.grab_focus()
	await _hands.types("more ")
	var typed: bool = draft.get_words().begins_with("more Twelve")
	await _hands.click(send)
	var clicked: bool = draft.get_words() == "" and not send.is_usable() and _hands.texts(send).has("Nothing written yet")
	send.grab_focus()
	await _hands.pad(JOY_BUTTON_DPAD_UP)
	var into: bool = _hands.focused() == edit
	await _hands.types("plums")
	await _hands.pad(JOY_BUTTON_DPAD_DOWN)
	var out: bool = _hands.focused() == send and send.is_usable()
	await _hands.pad(JOY_BUTTON_A)
	_said["text_area_by_mouse_keys_pad"] = broken and typed and clicked and into and out and draft.get_words() == "" and str(draft.get_sent()) == "Sent: a note of 1 line"


func _notices() -> void:
	var notices: Notifications = _stall.notifications
	var sounds: Sounds = _stall.sounds
	var tray: Control = _stall.ui.node_named(&"tray")
	var stays: float = _stall.root.get_theme_constant(Feedback.STAYS, Motion.TYPE) / 1000.0
	# how many times the look's sound for a notification has been asked for
	var rung := func() -> int: return sounds.get_played().filter(func(one: Array) -> bool: return one[0] == Sounds.NOTIFIED).size()
	var before: int = rung.call()
	await _hands.click(_press(Models.Sales.NOTIFIES))
	_press(Models.Sales.NOTIFIES_WITH_OFFER).grab_focus()
	await _hands.key(KEY_ENTER)
	var stacked: bool = notices.get_standing().map(func(one: Dictionary) -> StringName: return one["offer"]) == [&"", Models.Sales.VIEWS] and rung.call() == before + 2
	await _hands.pad(JOY_BUTTON_DPAD_DOWN)
	var reached: bool = tray.is_ancestor_of(_hands.focused())
	notices.step(stays * 3.0)
	var held: bool = notices.get_standing().size() == 2
	# the dismissal brought into view first, as a reader scrolls to what they will click: the tray may stand in a room shorter than itself
	var dismissal: Control = _hands.presses_of(Notifications.DISMISSES, {under = tray})[0]
	(tray.get_parent() as ScrollContainer).ensure_control_visible(dismissal)
	await _hands.frames()
	await _hands.click(dismissal)
	var dismissed: bool = notices.get_standing().size() == 1 and _hands.presses_of(Models.Sales.VIEWS, {under = tray}).size() == 1
	_hands.presses_of(Models.Sales.VIEWS, {under = tray})[0].grab_focus()
	await _hands.pad(JOY_BUTTON_A)
	var offered: bool = notices.get_standing().is_empty() and str(_stall.sales.get_viewed()) == "Viewed: the sales of day 1"
	var plain := _press(Models.Sales.NOTIFIES)
	plain.grab_focus()
	await _hands.key(KEY_ENTER)
	await _hands.key(KEY_ENTER)
	notices.step(stays - 0.05)
	var staying: bool = notices.get_standing().size() == 2
	notices.step(0.1)
	var next: bool = notices.get_standing().size() == 1
	notices.step(stays)
	_said["notifications_by_mouse_keys_pad"] = stacked and reached and held and dismissed and offered and staying and next and notices.get_standing().is_empty()
	await _hands.key(KEY_ENTER)
	_press(Models.Sales.NOTIFIES_WITH_OFFER).grab_focus()
	await _hands.key(KEY_ENTER)
