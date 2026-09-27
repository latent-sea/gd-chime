extends SceneTree

## What must be true of a local, and of the press that sets one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_local.gd
##
## A local is read and set, and what reads it is drawn again in place; a
## local press sets it - to a value, or to a function's answer - through no
## door, so nothing is dispatched, and is selected while they agree; it is
## freed with what was built from it, its bell with it; and kept, each view
## has its own, found again after a detour and Back.

const Fixture := preload("res://tests/fixture.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Local := preload("res://addons/gd_chime/components/primitives/local.gd")
const PressLocal := preload("res://addons/gd_chime/components/primitives/press_local.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await process_frame
	await _verdict.states(_set_and_read_and_its_reader_is_drawn_again_in_place)
	await _verdict.states(_a_local_press_sets_it_through_no_door_and_is_selected_while_they_agree)
	await _verdict.states(_it_is_freed_with_what_was_built_from_it_and_its_bell_with_it)
	await _verdict.states(_kept_it_is_found_again_after_a_detour_and_back)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _set_and_read_and_its_reader_is_drawn_again_in_place() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var open: Local = ui.local("shut")
	ui.start(ui.app(&"app", [ui.text(open).named(&"says")]))
	await _a_frame_passes()
	var says: Text = ui.node_named(&"says")
	_verdict.check(open.read() == "shut" and says.get_text() == "shut", "it starts as its first value, and is read: %s" % says.get_text())
	open.set_value("open")
	await _a_frame_passes()
	_verdict.check(open.read() == "open" and says.get_text() == "open" and ui.node_named(&"says") == says, "set, it rings its own bell and the same node reads it again: %s" % says.get_text())
	made.done()


func _a_local_press_sets_it_through_no_door_and_is_selected_while_they_agree() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	root.theme = Themes.new(Themes.NEUTRAL)
	var pace: Local = ui.local("slow")
	var out: Local = ui.local(false)
	ui.start(ui.app(&"app", [
		ui.press_local(pace, "slow", [ui.text("slow")]).named(&"slow"),
		ui.press_local(pace, Bound.constant("fast"), [ui.text("fast")]).named(&"fast"),
		ui.press_local(out, func(now: bool) -> bool: return not now, [ui.text("more")]).named(&"more"),
	]))
	await _a_frame_passes()
	var slow: PressLocal = ui.node_named(&"slow")
	var fast: PressLocal = ui.node_named(&"fast")
	var more: PressLocal = ui.node_named(&"more")
	_verdict.check(slow.is_selected() and slow.get_state() == &"selected" and not fast.is_selected() and fast.get_state() == &"normal", "the one whose value is the local's is selected, the other is not")
	_verdict.check(slow.has_theme_stylebox(&"selected") and slow._box() == slow.get_theme_stylebox(&"selected") and fast._box() == fast.get_theme_stylebox(&"normal"), "and is drawn in the look's selected box, the other in its normal one")
	var ran: Dictionary = made.commands.get_last()
	fast.pressed()
	await _a_frame_passes()
	_verdict.check(pace.read() == "fast" and fast.is_selected() and not slow.is_selected(), "pressed, the other's value - a bound one, read as the press lands - is the local's and the selection moved: %s" % pace.read())
	_verdict.check(made.commands.get_last() == ran and made.driver.index.performs() == {&"app": {}}, "and nothing was dispatched or declared: a local press is not a command: %s %s" % [made.commands.get_last(), made.driver.index.performs()])
	more.pressed()
	_verdict.check(out.read() == true and more.is_selected(), "given a function, a press sets its answer to the value as it is: turned on, it is selected")
	more.pressed()
	_verdict.check(out.read() == false and not more.is_selected(), "and the next press turns it off")
	root.theme = null
	made.done()


func _it_is_freed_with_what_was_built_from_it_and_its_bell_with_it() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", [{"id": 1}, {"id": 2}])
	var locals: Array = []  # weak references alone: holding one would be what keeps it
	var row := func(item: Bound) -> Desc:
		var out: Local = ui.local(false)
		locals.append(weakref(out))
		return ui.press_local(out, func(now: bool) -> bool: return not now, [ui.text(out.map(func(now: bool) -> String: return "out" if now else "in"))])
	ui.start(ui.app(&"app", [ui.each(model.of(&"items"), row, func(item: Dictionary) -> int: return item["id"])]))
	await _a_frame_passes()
	var alive := locals.filter(func(one: WeakRef) -> bool: return one.get_ref() != null)
	_verdict.check(alive.size() == 2, "a local for each row built, held by the row alone: %d" % alive.size())
	var address: StringName = (alive[0].get_ref() as Local)._bell.get_address()
	model.set_value(&"items", [{"id": 2}])
	await _a_frame_passes()
	alive = locals.filter(func(one: WeakRef) -> bool: return one.get_ref() != null)
	_verdict.check(alive.size() == 1 and not made.chimes._belfry.has(address, address), "the row gone, its local is freed and its bell is no longer hung: %d" % alive.size())
	model.free()
	made.done()


func _kept_it_is_found_again_after_a_detour_and_back() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var kept: Local = ui.local("first").kept()
	var passing: Local = ui.local("first")
	ui.start(ui.app(&"app", [ui.screen(&"here", [ui.text(kept).named(&"says")]), ui.screen(&"there", [ui.text("elsewhere")])]))
	await _a_frame_passes()
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"here"})
	await _a_frame_passes()
	kept.set_value("changed")
	passing.set_value("changed")
	await _a_frame_passes()
	_verdict.check((ui.node_named(&"says") as Text).get_text() == "changed", "set on a view, it is that view's")
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"there"})
	await _a_frame_passes()
	_verdict.check(kept.read() == "first" and passing.read() == "changed", "another view has its own, the first value; one not kept is the same everywhere")
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _a_frame_passes()
	_verdict.check(kept.read() == "changed" and (ui.node_named(&"says") as Text).get_text() == "changed", "Back, it is as it was left, and its reader says so: %s" % kept.read())
	made.done()
