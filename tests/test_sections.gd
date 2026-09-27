extends SceneTree

## What must be true of the sections: a collection under headings, one
## group per division, and fixed content under fixed headings.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_sections.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Each := preload("res://addons/gd_chime/components/primitives/each.gd")
const Sections := preload("res://addons/gd_chime/components/recipes/sections.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const PressLocal := preload("res://addons/gd_chime/components/primitives/press_local.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_every_group_shows_its_heading_its_count_and_its_items_by_the_template)
	await _verdict.states(_an_item_arriving_builds_one_piece_and_leaves_every_other_group_alone)
	await _verdict.states(_a_group_emptied_keeps_its_heading_and_says_it_is_empty)
	await _verdict.states(_static_groups_lay_their_content_out_under_their_headings)
	await _verdict.states(_a_heading_shuts_and_opens_what_is_under_it_and_a_detour_and_back_keep_it)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	# every text under it that shows: what is under a shut heading is hidden, and not said
	for child: Node in node.get_children():
		if child is Control and not (child as Control).visible:
			continue
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


## The pieces-per-item of a group, the each inside its piece.
func _within(group: Node) -> Each:
	return group.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Each)[0]


## The groups themselves, the each under the scroll.
func _groups_of(sections: Node) -> Each:
	return sections.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Each)[0]


## Three groups, one of them empty, held by a model.
func _divided() -> Array:
	return [
		{"id": "a", "heading": "first", "items": [{"id": 1, "name": "pear"}]},
		{"id": "b", "heading": "second", "items": [{"id": 2, "name": "apple"}, {"id": 3, "name": "plum"}]},
		{"id": "c", "heading": "third", "items": []},
	]


## A model, the ui and the sections built into an app, ready to read.
func _standing(made: Fixture, model: Fixture.Model) -> void:
	var ui := made.ui
	var template := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(item.field("name"))])
	var key := func(item: Dictionary) -> int: return item["id"]
	made.commands.register(&"app", &"opens", model)
	ui.start(ui.app(&"app", [Sections.make(ui, model.of(&"items"), template, {key = key}).named(&"sections")]))


func _every_group_shows_its_heading_its_count_and_its_items_by_the_template() -> void:
	var made := Fixture.new(root, {&"opens": "open"})
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", _divided())
	_standing(made, model)
	await _a_frame_passes()
	var sections: Node = made.ui.node_named(&"sections")
	var groups := _groups_of(sections)
	var said := _texts(sections)
	_verdict.check(groups.get_count() == 3, "one piece per group: %d" % groups.get_count())
	_verdict.check(said == ["-", "first", "1 item", "pear", "-", "second", "2 items", "apple", "plum", "-", "third", "No items", Sections.EMPTY], "each heading, its count and its items under it, in the model's order: %s" % [said])
	model.free()
	made.done()


func _an_item_arriving_builds_one_piece_and_leaves_every_other_group_alone() -> void:
	var made := Fixture.new(root, {&"opens": "open"})
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", _divided())
	_standing(made, model)
	await _a_frame_passes()
	var groups := _groups_of(made.ui.node_named(&"sections"))
	var untouched: Node = _within(groups.piece_for("b")).piece_for(2)
	var kept: Node = _within(groups.piece_for("a")).piece_for(1)
	var divided := _divided()
	divided[0]["items"] = [{"id": 1, "name": "pear"}, {"id": 4, "name": "fig"}]
	model.set_value(&"items", divided)
	await _a_frame_passes()
	var arrived := _within(groups.piece_for("a"))
	_verdict.check(arrived.get_count() == 2 and _texts(groups.piece_for("a")) == ["-", "first", "2 items", "pear", "fig"], "the item arrives in its own group, and the count says so: %s" % [_texts(groups.piece_for("a"))])
	_verdict.check(arrived.piece_for(1) == kept, "the piece already in that group is the same piece")
	_verdict.check(_within(groups.piece_for("b")).piece_for(2) == untouched and _texts(groups.piece_for("b")) == ["-", "second", "2 items", "apple", "plum"], "and the other group is left entirely alone")
	model.free()
	made.done()


func _a_group_emptied_keeps_its_heading_and_says_it_is_empty() -> void:
	var made := Fixture.new(root, {&"opens": "open"})
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", _divided())
	_standing(made, model)
	await _a_frame_passes()
	var groups := _groups_of(made.ui.node_named(&"sections"))
	var divided := _divided()
	divided[1]["items"] = []
	model.set_value(&"items", divided)
	await _a_frame_passes()
	_verdict.check(_texts(groups.piece_for("b")) == ["-", "second", "No items", Sections.EMPTY], "emptied, the group still stands under its heading and says it is empty: %s" % [_texts(groups.piece_for("b"))])
	_verdict.check(_texts(groups.piece_for("a")) == ["-", "first", "1 item", "pear"], "and a group of one is counted as one")
	model.free()
	made.done()


func _static_groups_lay_their_content_out_under_their_headings() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var fixed := Sections.static_groups(ui, [
		{"heading": "sound", "content": [ui.text("how loud"), ui.text("which voice")]},
		{"heading": "sight", "content": [ui.text("how large")]},
	])
	var built := ui.build(fixed, root)
	await _a_frame_passes()
	var said := _texts(built)
	_verdict.check(said == ["-", "sound", "how loud", "which voice", "-", "sight", "how large"], "fixed rows stand under the heading they were given, in order: %s" % [said])
	built.free()
	made.done()


## A press on a heading hides what is under it, the pieces kept; no command
## runs; which are open is the view's own, so the same screen entered as
## another begins open, and Back finds the first as it was left.
func _a_heading_shuts_and_opens_what_is_under_it_and_a_detour_and_back_keep_it() -> void:
	var made := Fixture.new(root, {&"opens": "open"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"here")
	model.set_value(&"items", _divided())
	var template := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(item.field("name"))])
	var key := func(item: Dictionary) -> int: return item["id"]
	made.commands.register(&"here", &"opens", model)
	ui.start(ui.app(&"app", [ui.screen(&"here", [Sections.make(ui, model.of(&"items"), template, {key = key}).named(&"sections")]), ui.screen(&"there", [ui.text("elsewhere")])]))
	await _a_frame_passes()
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"here", "parameter": 1})
	await _a_frame_passes()
	var groups := _groups_of(ui.node_named(&"sections"))
	var second: Node = groups.piece_for("b")
	var apple: Node = _within(second).piece_for(2)
	var heading: PressLocal = second.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is PressLocal)[0]
	var ran: Dictionary = made.commands.get_last()
	heading.pressed()
	await _a_frame_passes()
	_verdict.check(_texts(second) == [Sections.SHUT, "second", "2 items"] and _texts(groups.piece_for("a")) == ["-", "first", "1 item", "pear"], "pressed, the heading says shut and what was under it no longer shows; another section is as it was: %s" % [_texts(second)])
	_verdict.check(_within(second).piece_for(2) == apple and made.commands.get_last() == ran, "what was under it is hidden, not freed, and no command ran")
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"here", "parameter": 2})
	await _a_frame_passes()
	_verdict.check(_texts(second) == [Sections.OPEN, "second", "2 items", "apple", "plum"], "the same screen entered as another is another view, with its own: open, as a view begins: %s" % [_texts(second)])
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"there"})
	await _a_frame_passes()
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _a_frame_passes()
	_verdict.check(made.driver.get_parameter(&"here") == 1 and _texts(second) == [Sections.SHUT, "second", "2 items"], "a detour and Back to the first view, and the section shut there is still shut: %s" % [_texts(second)])
	heading.pressed()
	await _a_frame_passes()
	_verdict.check(_texts(second) == [Sections.OPEN, "second", "2 items", "apple", "plum"], "pressed again, it opens: %s" % [_texts(second)])
	model.free()
	made.done()
