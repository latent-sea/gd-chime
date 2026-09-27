extends SceneTree

## What must be true of keyed items: one item changed rings its own bell,
## once at the frame's end however often it moved, and draws again only what
## shows that item; a read straight after a change sees it; a field set to
## what it holds rings nothing; the tallies are the counts over the set,
## heard at the look's cadence.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_keyed_items.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Throttle := preload("res://addons/gd_chime/throttle.gd")
const KeyedItems := preload("res://addons/gd_chime/keyed_items.gd")
const Verdict := preload("res://tests/verdict.gd")

const COUNT := 50
const STATES := ["well", "slow", "down"]

var _verdict := Verdict.new()


func _init() -> void:
	var look := Themes.new(Themes.NEUTRAL)
	look.set_constant(Throttle.CADENCE, Motion.TYPE, 100000)
	root.theme = look
	await process_frame
	await _verdict.states(_one_item_changed_rings_its_own_bell_once_and_draws_only_what_shows_it)
	await _verdict.states(_the_tallies_are_the_counts_over_the_set_heard_at_the_cadence)
	quit(_verdict.deliver(get_script()))


func _items() -> Array:
	return range(COUNT).map(func(at: int) -> Dictionary: return {"id": at, "state": STATES[at % 3], "words": "unit %d" % at})


func _one_item_changed_rings_its_own_bell_once_and_draws_only_what_shows_it() -> void:
	var made := Fixture.new(root)
	var items := KeyedItems.new(made.chimes, _items(), &"id", [&"state"])
	root.add_child(items)
	var seventh := Fixture.Heard.new(made.chimes, items.item(7).read)
	var eighth := Fixture.Heard.new(made.chimes, items.item(8).read)
	root.add_child(seventh)
	root.add_child(eighth)
	var ui := made.ui
	var texts: Array = items.get_keys().map(func(key: int) -> RefCounted: return ui.text(items.item(key).field("state")).named(StringName("unit %d" % key)))
	ui.start(ui.app(&"app", [ui.column(texts)]))
	await process_frame
	await process_frame
	var drawn: Array = items.get_keys().map(func(key: int) -> int: return ui.node_named(StringName("unit %d" % key)).refresh_count)
	# the one item moved many times in the frame, ending on down
	for turn: int in 30:
		items.set_field(7, &"state", STATES[turn % 3])
	_verdict.check(items.get_item(7)["state"] == "down" and seventh.rung == 0, "a read straight after sees the change, and nothing has rung yet: %s, %d" % [items.get_item(7)["state"], seventh.rung])
	await process_frame
	_verdict.check(seventh.rung == 1 and eighth.rung == 0, "thirty changes in a frame ring that item's own bell once, and no other's: %d, %d" % [seventh.rung, eighth.rung])
	await process_frame
	var again: Array = items.get_keys().map(func(key: int) -> int: return ui.node_named(StringName("unit %d" % key)).refresh_count)
	var moved: Array = range(COUNT).filter(func(at: int) -> bool: return again[at] != drawn[at])
	_verdict.check(moved == [7] and ui.node_named(&"unit 7").get_text() == "down", "only what shows the item changed is drawn again: %s" % [moved])
	items.set_field(8, &"state", items.get_item(8)["state"])
	await process_frame
	_verdict.check(seventh.rung == 1 and eighth.rung == 0, "a field set to what it holds rings nothing: %d" % eighth.rung)
	made.done()


func _the_tallies_are_the_counts_over_the_set_heard_at_the_cadence() -> void:
	var made := Fixture.new(root)
	var items := KeyedItems.new(made.chimes, _items(), &"id", [&"state"])
	root.add_child(items)
	var tallied: RefCounted = items.tallied(&"state")
	var ears := Fixture.Heard.new(made.chimes, tallied.read)
	root.add_child(ears)
	# a hundred changes spread over the items and the states
	for turn: int in 100:
		items.set_field((turn * 7) % COUNT, &"state", STATES[(turn * 5) % 3])
	var counted: Dictionary = {}
	# every item, counted by hand
	for key: int in items.get_keys():
		counted[items.get_item(key)["state"]] = counted.get(items.get_item(key)["state"], 0) + 1
	_verdict.check(tallied.read() == counted, "the tallies are the counts over the set: %s against %s" % [tallied.read(), counted])
	await process_frame
	await process_frame
	items.set_field(0, &"state", "down" if items.get_item(0)["state"] != "down" else "well")
	await process_frame
	await process_frame
	_verdict.check(ears.rung == 1, "changes in two frames inside the cadence ring the tallies once: %d" % ears.rung)
	made.done()
