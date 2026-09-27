extends SceneTree

## What must be true of notifications: they arrive without taking the
## focus and stand ONE AT A TIME in the room the layout leaves them - the
## oldest showing, the rest waiting in order with their count said beside
## it, the next standing only once the one showing is cleared; the one
## showing stays the look's time and leaves, while those waiting keep
## their whole stay; the pad walks to it and, while it is on it, it does
## not leave; it can be dismissed, and its one offer goes through the door
## - refused there as any press is, its reason within the room, and done,
## the notification leaves; the room never changes for any of it; put in a
## look whose notice box is thicker, the room is measured again and holds
## one whole.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_notifications.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const NotificationTray := preload("res://addons/gd_chime/components/recipes/notification_tray.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const TrayStand := preload("res://addons/gd_chime/components/primitives/tray_stand.gd")
const Clipped := preload("res://addons/gd_chime/clipped_text.gd")
const Feedback := preload("res://addons/gd_chime/theme_feedback.gd")

const SELLS := &"sells_a_crate"
const VIEWS := &"views_the_sales"

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Keeps every error pushed, in words.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			said.append(code + " " + rationale)


## The fixture's model, refusing one action as it is told rather than
## before: the door lets the press through and the answer is a refusal.
class Grudging extends Fixture.Model:
	var refuses_when_told: StringName = &""

	func told(action: StringName, payload: Dictionary) -> Phrase:
		super(action, payload)
		return Phrase.of("not today") if action == refuses_when_told else null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(900, 700)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	OS.add_logger(_hearing)
	await _verdict.states(_one_made_with_no_tray_standing_is_reported_out_loud_by_its_words)
	await _verdict.states(_one_arrives_without_the_focus_and_stays_the_look_s_time)
	await _verdict.states(_one_stands_at_a_time_the_rest_wait_in_order_counted_the_room_never_changing)
	await _verdict.states(_the_one_showing_stays_the_look_s_time_and_the_next_stands_only_as_it_is_cleared)
	await _verdict.states(_the_pad_walks_to_one_and_while_it_is_there_none_leaves)
	await _verdict.states(_a_dismissal_sends_one_away_and_the_focus_goes_on_to_another_control)
	await _verdict.states(_its_offer_goes_through_the_door_refused_there_as_any_press_and_done_it_leaves)
	await _verdict.states(_standing_in_the_layout_s_room_nothing_is_drawn_over_at_any_shape)
	await _verdict.states(_put_in_a_look_with_a_thicker_notice_box_the_room_holds_one_whole)
	quit(_verdict.deliver(get_script()))


## Five arriving: the oldest alone shows, beside its presses the words
## saying four more wait, and the tray's room is to the pixel what it was
## with none standing; dismissed one by one, the next in order stands each
## time and the count falls, the room never changing - and gone, none is said.
func _one_stands_at_a_time_the_rest_wait_in_order_counted_the_room_never_changing() -> void:
	var standing := await _stall()
	var notifications: Notifications = standing["notifications"]
	var stand := _stand()
	var room := stand.get_global_rect()
	# five, oldest first
	for fruit: String in ["plums", "pears", "figs", "quinces", "limes"]:
		notifications.notify(Phrase.with("the %s are in", [fruit]))
	await _a_frame_passes()
	var shown := _texts().filter(func(words: String) -> bool: return words.ends_with(" are in"))
	_verdict.check(shown == ["the plums are in"], "five standing, one stands at a time, the oldest: %s" % [shown])
	_verdict.check(_texts().has("4 more"), "and beside it the words say how many wait: %s" % [_texts()])
	var rooms: Array = [stand.get_global_rect()]
	var seen: Array = []
	# each showing sent away in turn, noting what stands next, the count and the room
	for turn: int in 4:
		(standing["made"] as Fixture).commands.dispatch(Chimes.GLOBAL, Notifications.DISMISSES, {"notice": notifications.get_standing()[0]["id"]})
		await _a_frame_passes()
		seen.append([_texts().filter(func(words: String) -> bool: return words.ends_with(" are in")), _texts().filter(func(words: String) -> bool: return words.ends_with(" more"))])
		rooms.append(stand.get_global_rect())
	_verdict.check(seen == [[["the pears are in"], ["3 more"]], [["the figs are in"], ["2 more"]], [["the quinces are in"], ["1 more"]], [["the limes are in"], []]], "dismissed one by one, the next in order stands each time, the count falling: %s" % [seen])
	(standing["made"] as Fixture).commands.dispatch(Chimes.GLOBAL, Notifications.DISMISSES, {"notice": notifications.get_standing()[0]["id"]})
	notifications.notify(Phrase.of("the day's sales are counted, and every crate of plums, pears, figs, quinces and limes on the stall was sold before noon, which has not happened since the spring"), VIEWS)
	await _a_frame_passes()
	rooms.append(stand.get_global_rect())
	_verdict.check(rooms.all(func(rect: Rect2) -> bool: return rect == room), "and the tray's room is to the pixel what it was with none standing, whatever stands or waits - words past the look's lines too: %s against %s" % [rooms, room])
	_done(standing)


## The one showing stays the look's time and leaves, and only then does the
## next stand - with its whole stay before it, however long it waited.
func _the_one_showing_stays_the_look_s_time_and_the_next_stands_only_as_it_is_cleared() -> void:
	var standing := await _stall()
	var notifications: Notifications = standing["notifications"]
	var stays := _stays()
	notifications.notify(Phrase.of("the plums are in"))
	notifications.notify(Phrase.of("the pears are in"))
	await _a_frame_passes()
	notifications.step(stays - 0.01)
	await _a_frame_passes()
	_verdict.check(_texts().has("the plums are in") and not _texts().has("the pears are in"), "just short of the first's stay, it still shows and the second waits: %s" % [_texts()])
	notifications.step(0.02)
	await _a_frame_passes()
	_verdict.check(_words(notifications.get_standing()) == ["the pears are in"] and _texts().has("the pears are in"), "its stay over, it leaves and the next stands: %s" % [_texts()])
	notifications.step(stays - 0.01)
	_verdict.check(notifications.get_standing().size() == 1, "the next has its whole stay before it, however long it waited: %s" % [_words(notifications.get_standing())])
	notifications.step(0.02)
	_verdict.check(notifications.get_standing().is_empty(), "and then it leaves too")
	_done(standing)


## The tray's stand in the window.
func _stand() -> Control:
	return root.find_children("*", "Container", true, false).filter(func(part: Node) -> bool: return part.get_script() == TrayStand)[0]


## Built in the floor's look, then put in one whose notice box is far
## thicker: the room is measured again in the look now worn, so one at its
## fullest - an offer and words of every line - stands whole in it, its
## scroll with nowhere to go and no words cut.
func _put_in_a_look_with_a_thicker_notice_box_the_room_holds_one_whole() -> void:
	var standing := await _stall()
	var notifications: Notifications = standing["notifications"]
	var stand := _stand()
	var thin := stand.size.y
	var thick := Themes.new(Themes.NEUTRAL)
	var box := StyleBoxFlat.new()
	box.set_content_margin_all(80.0)
	thick.set_stylebox(&"panel", Themes.NOTICE, box)
	root.theme = thick
	await _a_frame_passes()
	notifications.notify(Phrase.of("the pears are in, forty crates of them"), VIEWS)
	notifications.notify(Phrase.of("the plums are in"))
	await _a_frame_passes()
	var scroll: ScrollContainer = stand.get_child(1)
	var held: Control = scroll.get_child(0)
	_verdict.check(stand.size.y > thin and held.get_combined_minimum_size().y <= scroll.size.y + 0.5, "in the thicker look the room is measured again, and holds one whole: room %.0f from %.0f, it needs %.0f in %.0f" % [stand.size.y, thin, held.get_combined_minimum_size().y, scroll.size.y])
	var cut := Clipped.clipped(stand, Rect2(Vector2.ZERO, Vector2(root.size)))
	_verdict.check(cut.is_empty(), "and no words in the tray are cut: %s" % [cut])
	root.theme = Themes.new(Themes.NEUTRAL)
	_done(standing)


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The stall - a button to sell - over the tray, with the notifications
## counted by hand and the stall's model answering both actions, as
## {made, model, notifications}.
func _stall() -> Dictionary:
	var made := Fixture.new(root, {SELLS: "sell a crate", VIEWS: "view the sales", Notifications.DISMISSES: "dismiss"})
	var ui := made.ui
	var model := Grudging.new(made.chimes, &"app")
	made.commands.register(&"app", SELLS, model)
	made.commands.register(&"app", VIEWS, model)
	var notifications := Notifications.new(made.chimes, made.commands, root)
	notifications.by_hand = true
	made.commands.register(Chimes.GLOBAL, Notifications.DISMISSES, notifications)
	# under the root before the app, so the fixture - newest first - frees the tray, which tells them it leaves, before them
	root.add_child(notifications)
	ui.start(ui.app(&"app", [ui.column([ui.button(SELLS), NotificationTray.make(ui, notifications, {VIEWS: &""})])]))
	await _a_frame_passes()
	return {"made": made, "model": model, "notifications": notifications}


## The fixture freed, the notifications with it, after the app they outlive.
func _done(standing: Dictionary) -> void:
	(standing["model"] as Fixture.Model).free()
	(standing["made"] as Fixture).done()


func _texts() -> Array[String]:
	var found: Array[String] = []
	# every text shown in the window, top to bottom, its words
	for part: Node in root.find_children("*", "Control", true, false):
		if part is Text and (part as Text).is_visible_in_tree():
			found.append((part as Text).get_text())
	return found


func _presses(action: StringName) -> Array:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == action and (part as Pressable).is_visible_in_tree())


func _words(of: Array) -> Array:
	return of.map(func(one: Dictionary) -> String: return str(one["words"]))


## Enter pressed and let go on whatever has the focus.
func _accept() -> void:
	# the key going down, which is the press, and then up
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = down
		root.push_input(key)


## The look's stay, in seconds.
func _stays() -> float:
	return root.get_theme_constant(Feedback.STAYS, Motion.TYPE) / 1000.0


## Made while no tray stands in the app - a count of them is none - one is
## reported out loud, naming it and saying no tray stands; made while the
## app's frame holds a tray, nothing is said; the tray gone, it is again.
func _one_made_with_no_tray_standing_is_reported_out_loud_by_its_words() -> void:
	var made := Fixture.new(root, {SELLS: "sell a crate"})
	var model := Grudging.new(made.chimes, &"app")
	made.commands.register(&"app", SELLS, model)
	var notifications := Notifications.new(made.chimes, made.commands, root)
	notifications.by_hand = true
	# a count of the notifications standing, on the button: it reads them, and is no tray
	var count: Bound = Bound.new(notifications.get_standing).map(func(standing: Array) -> String: return str(standing.size()))
	root.add_child(notifications)
	made.ui.start(made.ui.app(&"app", [made.ui.button(SELLS), made.ui.text(count).named(&"count")]))
	await _a_frame_passes()
	_hearing.said.clear()
	notifications.notify(Phrase.of("the plums are in"))
	await _a_frame_passes()
	var trayless := _hearing.said.filter(func(words: String) -> bool: return words.contains("the plums are in") and words.contains("no tray stands"))
	_verdict.check((made.ui.node_named(&"count") as Text).get_text() == "1", "a count of them reads the notifications standing: %s" % (made.ui.node_named(&"count") as Text).get_text())
	_verdict.check(trayless.size() == 1, "and, no tray in the app, the notification made is reported out loud, by its words - the count is no tray: %s" % [_hearing.said])
	model.free()
	made.done()
	var standing := await _stall()
	_hearing.said.clear()
	(standing["notifications"] as Notifications).notify(Phrase.of("the pears are in"))
	_verdict.check(_hearing.said.is_empty(), "the app's frame holding a tray, one made is not reported: %s" % [_hearing.said])
	var stand: Node = root.find_children("*", "Container", true, false).filter(func(part: Node) -> bool: return part.get_script() == TrayStand)[0]
	stand.get_parent().remove_child(stand)
	stand.free()
	(standing["notifications"] as Notifications).notify(Phrase.of("the figs are in"))
	_verdict.check(_hearing.said.size() == 1 and _hearing.said[0].contains("the figs are in"), "the tray taken out of the tree, one made is reported again: %s" % [_hearing.said])
	_done(standing)


## One arriving takes the focus from nothing, is shown, and stands for the
## look's stay: set half a second, half a second.
func _one_arrives_without_the_focus_and_stays_the_look_s_time() -> void:
	var standing := await _stall()
	var notifications: Notifications = standing["notifications"]
	var sell: Pressable = _presses(SELLS)[0]
	sell.grab_focus()
	await _a_frame_passes()
	_verdict.check(_stays() > 0.0, "the look gives a notification a time to stay: %f" % _stays())
	notifications.notify(Phrase.of("the plums are in"))
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == sell and _texts().has("the plums are in"), "one arriving is shown and leaves the focus where the reader had it: %s" % [root.gui_get_focus_owner()])
	notifications.step(_stays())
	await _a_frame_passes()
	_verdict.check(notifications.get_standing().is_empty() and root.gui_get_focus_owner() == sell, "it leaves as its stay ends, and the focus never moved")
	var brisk := Themes.new(Themes.NEUTRAL)
	brisk.set_constant(Feedback.STAYS, Motion.TYPE, 500)
	root.theme = brisk
	await _a_frame_passes()
	notifications.notify(Phrase.of("the quinces are in"))
	notifications.step(0.49)
	var before := notifications.get_standing().size()
	notifications.step(0.02)
	_verdict.check(before == 1 and notifications.get_standing().is_empty(), "the stay is the look's: set half a second, it stays half a second")
	root.theme = Themes.new(Themes.NEUTRAL)
	_done(standing)


## The tray is part of the layout, so the pad's direction walks from the
## work to a notification's press; while the focus is there, no
## notification's time passes; walked away, it passes again.
func _the_pad_walks_to_one_and_while_it_is_there_none_leaves() -> void:
	var standing := await _stall()
	var notifications: Notifications = standing["notifications"]
	_presses(SELLS)[0].grab_focus()
	notifications.notify(Phrase.of("the plums are in"))
	await _a_frame_passes()
	# the pad's direction down, pressed and let go
	for down: bool in [true, false]:
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_DPAD_DOWN
		pad.pressed = down
		root.push_input(pad)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == _presses(Notifications.DISMISSES)[0], "the pad walked down from the work to the notification's press: %s" % [root.gui_get_focus_owner()])
	notifications.step(_stays() * 3.0)
	_verdict.check(notifications.get_standing().size() == 1, "while the focus is on it, it does not leave, however long")
	_presses(SELLS)[0].grab_focus()
	notifications.step(_stays())
	_verdict.check(notifications.get_standing().is_empty(), "walked away from, its time passes again and it leaves")
	_done(standing)


## Its dismissal is a press like any other: walked to and pressed, the
## notification goes, and the focus goes on to a control still standing.
func _a_dismissal_sends_one_away_and_the_focus_goes_on_to_another_control() -> void:
	var standing := await _stall()
	var notifications: Notifications = standing["notifications"]
	notifications.notify(Phrase.of("the plums are in"))
	notifications.notify(Phrase.of("the pears are in"))
	await _a_frame_passes()
	var first: Pressable = _presses(Notifications.DISMISSES)[0]
	first.grab_focus()
	await _a_frame_passes()
	_accept()
	await _a_frame_passes()
	_verdict.check(_words(notifications.get_standing()) == ["the pears are in"] and not _texts().has("the plums are in") and _texts().has("the pears are in"), "pressed, the dismissal sends that one away and no other, and the next stands: %s" % [_texts()])
	var now := root.gui_get_focus_owner()
	_verdict.check(now != null and now.is_visible_in_tree() and now != first, "and the focus goes on to a control still standing: %s" % [now])
	_verdict.check(notifications.would(Notifications.DISMISSES, {"notice": 1}) != null, "a notification already gone cannot be dismissed again")
	_done(standing)


## Its one offer is a button of the offer's action, carrying its payload:
## the door's refusal shows on its face, within the room, and keeps it
## standing; done, the model was told it with the payload and the
## notification leaves, the next in order standing.
func _its_offer_goes_through_the_door_refused_there_as_any_press_and_done_it_leaves() -> void:
	var standing := await _stall()
	var notifications: Notifications = standing["notifications"]
	var model: Grudging = standing["model"]
	var room := _stand().get_global_rect()
	notifications.notify(Phrase.of("the plums are in"))
	await _a_frame_passes()
	_verdict.check(_presses(VIEWS).is_empty(), "a notification offering nothing draws no offer's press: %s" % [_texts()])
	(standing["made"] as Fixture).commands.dispatch(Chimes.GLOBAL, Notifications.DISMISSES, {"notice": notifications.get_standing()[0]["id"]})
	notifications.notify(Phrase.of("the day's sales are counted"), VIEWS, {"day": 3})
	notifications.notify(Phrase.of("the figs are in"))
	notifications.notify(Phrase.of("the day before's sales are counted"), VIEWS, {"day": 2})
	await _a_frame_passes()
	_verdict.check(_presses(VIEWS).size() == 1 and _texts().has("view the sales"), "the one offering it draws the offer's press, in the register's words: %s" % [_texts()])
	model.refuse(VIEWS, Phrase.of("the ledger is shut"))
	model.set_value(&"flag", true)
	await _a_frame_passes()
	var view: Pressable = _presses(VIEWS)[0]
	_verdict.check(not view.is_usable() and _texts().has("the ledger is shut"), "the door refuses the offer, and its button says why on its face: %s" % [_texts()])
	var reason: Control = root.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return (label as Label).text == "the ledger is shut")[0]
	_verdict.check(_stand().get_global_rect() == room and _stand().is_ancestor_of(reason), "the reason stands within the tray's room, which does not change: %s against %s" % [_stand().get_global_rect(), room])
	view.grab_focus()
	await _a_frame_passes()
	_accept()
	await _a_frame_passes()
	_verdict.check(model.told_actions.is_empty() and notifications.get_standing().size() == 3, "a refused offer is told to nobody, and the notification stays")
	model.refuse(VIEWS, null)
	model.refuses_when_told = VIEWS
	model.set_value(&"flag", false)
	await _a_frame_passes()
	_accept()
	await _a_frame_passes()
	_verdict.check(model.told_actions == [VIEWS] and notifications.get_standing().size() == 3, "an offer the model refuses as it is told is not done, and the notification stays: %s" % [_words(notifications.get_standing())])
	model.refuses_when_told = &""
	_accept()
	await _a_frame_passes()
	_verdict.check(model.told_actions == [VIEWS, VIEWS] and (standing["made"] as Fixture).commands.get_last()["payload"] == {"day": 3}, "done, the offer's model was told its action with the payload: %s" % [(standing["made"] as Fixture).commands.get_last()])
	await _a_frame_passes()
	_verdict.check(_words(notifications.get_standing()) == ["the figs are in", "the day before's sales are counted"] and _texts().has("the figs are in"), "and the notification that offered it has left - not the one offering the same action for another day - and the next stands: %s" % [_words(notifications.get_standing())])
	_done(standing)


## Standing in the room the layout leaves it with two waiting, the one
## showing - long words, an offer, the count - is drawn over nothing and
## draws over nothing, landscape and portrait alike.
func _standing_in_the_layout_s_room_nothing_is_drawn_over_at_any_shape() -> void:
	var standing := await _stall()
	var notifications: Notifications = standing["notifications"]
	notifications.notify(Phrase.of("the day's sales are counted, and every crate of plums on the stall was sold before noon"), VIEWS, {"day": 3})
	notifications.notify(Phrase.of("the plums are in"))
	notifications.notify(Phrase.of("the figs are in"))
	# a landscape window and a portrait one
	for shape: Vector2i in [Vector2i(900, 700), Vector2i(420, 900)]:
		root.size = shape
		await _a_frame_passes()
		var covered := DrawnOver.covered(root, Rect2(Vector2.ZERO, root.size))
		_verdict.check(covered.is_empty(), "at %s nothing is drawn over anything: %s" % [shape, covered])
	root.size = Vector2i(900, 700)
	_done(standing)
