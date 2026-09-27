extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Shown := preload("res://demo/gallery/shown.gd")
const Fetched := preload("res://addons/gd_chime/fetched.gd")
const Token := preload("res://addons/gd_chime/token.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")

## The gallery's models for what arrives (arrivals_pieces.gd): a note being
## written to the grower, the stock on its way, and the day's sales that the
## application's notifications tell of.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Nothing here waits on a clock. The stock is asked for as its screen fills
## and lands when the reader says it does - a press standing in for the
## delivery - so every state is seen and reached by a hand; and a
## notification is the application's (notifications.gd), sent by a press.


## A note to the grower: the words as they are typed, held here, and sent by
## a press of their own - refused while there are none.
class Draft extends Shown:
	const WRITES := &"writes_the_note"
	const SENDS := &"sends_the_note"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [WRITES, SENDS]
	## The note as it stands when the gallery opens, one line long enough to break: the reader's words, data.
	const FIRST := "Twelve crates of figs, please.\nThe plums were perfect: every one of them sold before the market bell rang at noon, so send twice as many next time if the growers up the hill can spare them before the rains come.\nThank you."

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"words": FIRST, &"sent": Phrase.of("Nothing sent yet")})

	func get_words() -> String:
		return facts[&"words"]

	func get_sent() -> Phrase:
		return facts[&"sent"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		if action == SENDS and facts[&"words"].strip_edges() == "":
			return Phrase.of("Nothing written yet")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		if action == WRITES:
			facts[&"words"] = payload["text"]
		else:
			facts[&"sent"] = Phrase.counted("Sent: a note of %d line", "Sent: a note of %d lines", facts[&"words"].split("\n").size())
			facts[&"words"] = ""
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## The stock on its way: asked for as its screen fills (fetched.gd), and
## landed by a press - the press IS the far side answering, which is what
## makes this a demo of waiting. Counting it is refused until it has landed,
## by the fetched stock this answers through; asking again is the fetched
## stock's own action, answered by it.
class Stock extends Shown:
	const COUNTS := &"counts_the_stock"
	const LANDS := &"lands_the_delivery"
	## Every action this is told; asking again is the fetched stock's (Fetched.ASKS_AGAIN).
	const COMMANDS: Array[StringName] = [COUNTS, LANDS]
	## What the screen fills with: its .data is the delivery, nothing until a press lands it.
	var delivery: Fetched
	var _answer: Callable  # the asking's answer, held until the press that lands it

	func _init(chimes: Chimes, notifications: Notifications) -> void:
		super(chimes, {&"counted": Phrase.of("Not counted yet")})
		delivery = Fetched.new(chimes, _asks, notifications, Phrase.of("The delivery"))
		add_child(delivery)

	func get_counted() -> Phrase:
		return facts[&"counted"]

	## Asked: what it had is let go, so the shapes stand in again while the
	## next delivery is on its way, and the answer is held for the press.
	func _asks(answer: Callable) -> void:
		delivery.data.set_value(null)
		_answer = answer

	## Counting waits for the delivery; landing waits for something on its way.
	func would(action: StringName, payload: Dictionary) -> Phrase:
		match action:
			COUNTS: return delivery.would(action, payload)
			LANDS when not delivery.loading.read(): return Phrase.of("The delivery is in")
		return null

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		if action == COUNTS:
			facts[&"counted"] = Phrase.of("Counted: sixty-one crates")
			moved()
		else:
			_answer.call(Phrase.of("Forty crates of plums"), null)
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## The day's sales, which the application's notifications tell of: one sent
## with nothing to offer, one offering to view a day's sales, and the sales
## viewed.
class Sales extends Shown:
	const NOTIFIES := &"notifies"
	const NOTIFIES_WITH_OFFER := &"notifies_with_an_offer"
	const VIEWS := &"views_the_sales"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [NOTIFIES, NOTIFIES_WITH_OFFER, VIEWS]
	var _notifications: Notifications
	var _day: int = 0  # the last day whose sales were counted

	func _init(chimes: Chimes, notifications: Notifications) -> void:
		super(chimes, {&"viewed": Phrase.of("No sales viewed yet")})
		_notifications = notifications

	func get_viewed() -> Phrase:
		return facts[&"viewed"]

	func told(action: StringName, payload: Dictionary) -> Phrase:
		match action:
			NOTIFIES: _notifications.notify(Phrase.of("The plums are in, and every crate of them was sold before the market bell rang at noon"))
			NOTIFIES_WITH_OFFER:
				_day += 1
				_notifications.notify(Phrase.with("Day %d's sales are counted", [_day]), VIEWS, {"day": _day})
			VIEWS:
				facts[&"viewed"] = Phrase.with("Viewed: the sales of day %d", [payload["day"]])
				moved()
		return null

	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS
