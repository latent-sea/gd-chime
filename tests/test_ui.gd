extends SceneTree

## What must be true of the builder: a screen declares and registers, and
## start refuses a broken tree.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_ui.gd
##
## ui.screen builds a place declaring, from the pressables inside it and
## not inside a place within - and from what each template inside it
## describes, asked with an empty handle, so a collection empty at startup
## declares all the same - each action and where it goes, and registers
## its handled_by for those actions in its own region - but for one the door
## answers from anywhere already; a pop-up that blocks nothing is a panel;
## start builds everything under the root, sets the app, checks the tree
## once it has entered and makes the first move; a broken tree is said and
## the application quits.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts the errors pushed while it listens.
class Hearing extends Logger:
	var errors: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			errors += 1


## A root that records a quit instead of quitting.
class Quitting extends Control:
	var quit_code: int = -1


func _init() -> void:
	await process_frame
	OS.add_logger(_hearing)
	await _verdict.states(_a_screen_declares_what_its_pressables_perform_and_registers_its_handler_in_its_region)
	await _verdict.states(_start_builds_sets_the_app_checks_and_moves)
	await _verdict.states(_start_refuses_a_broken_tree)
	await _verdict.states(_a_collection_empty_at_startup_declares_and_registers_what_its_template_performs)
	await _verdict.states(_a_primitive_of_the_game_s_own_builds_by_its_kind)
	await _verdict.states(_a_control_the_framework_did_not_build_stands_inline_among_parts)
	await _verdict.states(_a_themed_subtree_keeps_its_own_look_while_the_root_s_changes)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _a_screen_declares_what_its_pressables_perform_and_registers_its_handler_in_its_region() -> void:
	var made := Fixture.new(root, {&"saves": "save", &"opens": "open", &"counts": "count"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	var inner := ui.screen(&"coins", [ui.pressable(&"counts")])
	# a tree the check would refuse - a link to no ledger, the driver's own command drawn - built to be read, its faults ignored here
	ui.start(ui.app(&"app", [ui.screen(&"home", [ui.column([ui.pressable(&"saves"), ui.pressable(&"opens", {}, [], &"Pressable").goes_to(&"ledger"), ui.pressable(Driver.GOES_BACK, {}, [], &"Pressable").goes_to(Driver.BACK), inner])], model)]), func(_wrong: Array) -> void: pass)
	var home: Place = made.driver.index.place_named(&"home")
	_verdict.check(home.performs == {&"saves": &"", &"opens": &"ledger", Driver.GOES_BACK: Driver.BACK}, "the screen declares each pressable's action and where it goes, not the inner screen's: %s" % [home.performs])
	_verdict.check(made.commands.handles(&"home", &"saves") and made.commands.handles(&"home", &"opens"), "and registers its handler for them in its region")
	_verdict.check(not made.commands._handlers.get(&"home", {}).has(Driver.GOES_BACK), "but not for the driver's own command, which the door answers from anywhere")
	_verdict.check((made.driver.index.place_named(&"coins") as Place).performs == {&"counts": &""}, "the inner screen declares its own: %s" % [(made.driver.index.place_named(&"coins") as Place).performs])
	var pressed: Pressable = home.find_children("*", "Control", true, false).filter(func(node: Node) -> bool: return node is Pressable and node.action == &"saves")[0]
	_verdict.check(pressed.region == &"home" and pressed.get_goes_to() == &"", "a pressable is in its place's region and reads where it goes from the place")
	await _a_frame_passes()
	model.free()
	made.done()


func _start_builds_sets_the_app_checks_and_moves() -> void:
	var made := Fixture.new(root, {&"saves": "save", &"opens": "open"})
	var ui := made.ui
	var zoom: Desc = ui.pop_up(&"zoom", func(_which: Bound) -> Desc: return ui.pressable(ui.CLOSES, {}, [], &"Pressable").goes_to(Driver.BACK))
	var console: Desc = ui.pop_up(&"console", func(_which: Bound) -> Desc: return ui.text("the console"), null).blocks_nothing()
	ui.start(ui.app(&"app", [ui.pressable(&"saves").named(&"save"), ui.pressable(&"opens").opens(zoom), console]))
	var app: Node = made.driver.index.app
	_verdict.check(app != null and app.name == &"app" and app.get_parent() == root, "the app is built under the root and set on the driver")
	_verdict.check(made.driver.index.has_place(zoom.get_place()) and made.driver.index.has_place(console.get_place()) and not (made.driver.index.place_named(console.get_place()) as Place).blocks, "the pop-ups are lifted beside it, the panel blocking nothing")
	await _a_frame_passes()
	_verdict.check(made.driver.get_top() == [&"app"] and (ui.node_named(&"save") as Control).is_visible_in_tree(), "the tree entered, checked, and the first move made into the app: %s" % [made.driver.get_top()])
	made.done()


func _start_refuses_a_broken_tree() -> void:
	var made := Fixture.new(root, {&"saves": "save", &"flies": "fly"})
	var ui := made.ui
	var before := _hearing.errors
	# a pressable for an action the register does not have, and a registered action nothing performs
	var told: Dictionary = {}
	ui.start(ui.app(&"app", [ui.pressable(&"saves"), ui.pressable(&"jumps")]), func(wrong: Array) -> void: told["wrong"] = wrong)
	await _a_frame_passes()
	var said: Array = told.get("wrong", [])
	_verdict.check(_hearing.errors >= before + 2 and said.size() == 2, "the broken tree is said, one sentence a fault, and the application told to quit: %s" % [said])
	_verdict.check(made.driver.get_top().is_empty(), "and no move is made: %s" % [made.driver.get_top()])
	made.done()


## Blinks: a primitive of the game's own, registered by kind, built by its
## own script with no floor file edited.
class Blink extends RefCounted:
	static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
		var made := Control.new()
		made.name = "blink"
		made.set_meta("rate", desc.props["rate"])
		ui.attach(made, parent, desc.facts)
		return made


func _a_collection_empty_at_startup_declares_and_registers_what_its_template_performs() -> void:
	var made := Fixture.new(root, {&"flips": "flip", &"opens": "open"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", [])
	var template := func(thing: Bound) -> Desc: return ui.row([ui.text(thing.field("name")), ui.pressable(&"flips", thing.map(func(item: Variant) -> Dictionary: return {"id": item["id"] if item != null else -1})), ui.pressable(&"opens", {}, [], &"Pressable").goes_to(&"detail")])
	var told: Dictionary = {}
	ui.start(ui.app(&"app", [ui.screen(&"list", [ui.each(model.of(&"items"), template, func(thing: Dictionary) -> int: return thing["id"])], model), ui.screen(&"detail", [])]), func(wrong: Array) -> void: told["wrong"] = wrong)

	var list: Place = made.driver.index.place_named(&"list")
	_verdict.check(list.performs == {&"flips": &"", &"opens": &"detail"}, "the list, empty, declares what its template's pressables perform: %s" % [list.performs])
	_verdict.check(made.commands.handles(&"list", &"flips"), "and its handler is registered for them")
	await _a_frame_passes()
	_verdict.check(not told.has("wrong") and made.driver.get_top() == [&"app", &"list"], "the check passes and the app starts: %s" % [told.get("wrong", [])])
	model.set_value(&"items", [{"id": 7, "name": "one"}])
	await _a_frame_passes()
	var pressed: Pressable = list.find_children("*", "Control", true, false).filter(func(node: Node) -> bool: return node is Pressable and node.action == &"flips")[0]
	_verdict.check(pressed.is_usable() and pressed.payload() == {"id": 7}, "an item come, its row's button is usable and carries the item's id")
	model.free()
	made.done()


## The escape hatch: a Control nobody described is placed by the line it is
## in, beside described parts, and takes its facts as any part does - where
## ui.also would have put it across the whole window.
func _a_control_the_framework_did_not_build_stands_inline_among_parts() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var outsider := ColorRect.new()
	outsider.custom_minimum_size = Vector2(40.0, 10.0)
	var line: Control = ui.build(ui.row([ui.text("beside it"), ui.embed(outsider).grow()]), ui.root)
	await _a_frame_passes()
	_verdict.check(outsider.get_parent() == line and line.get_child_count() == 2, "the Control stands in the line, as one of its parts: %s" % [outsider.get_parent()])
	_verdict.check(outsider.size.x > 40.0 and outsider.global_position.x > line.get_child(0).get_global_rect().end.x - 1.0, "placed by the line and grown as its facts say: %.0f wide at %.0f" % [outsider.size.x, outsider.global_position.x])
	line.free()
	made.done()


## A subtree given a look of its own keeps it: the engine carries a theme
## down from the node holding it, so a look put on the root afterwards
## re-dresses what is outside and nothing in.
func _a_themed_subtree_keeps_its_own_look_while_the_root_s_changes() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var own := Themes.new(Themes.NEUTRAL)
	own.set_font_size(&"font_size", Themes.FACE, 77)
	root.theme = Themes.new(Themes.NEUTRAL)
	var line: Control = ui.build(ui.row([ui.text("outside", Themes.FACE).named(&"outside"), ui.themed(own, [ui.text("inside", Themes.FACE).named(&"inside")])]), root)
	await _a_frame_passes()
	var inside := _words_of(ui.node_named(&"inside"))
	var outside := _words_of(ui.node_named(&"outside"))
	_verdict.check(inside.get_theme_font_size(&"font_size") == 77 and outside.get_theme_font_size(&"font_size") == Themes.SIZES[Themes.FACE], "inside the themed piece the look is its own, outside it the root's: %d against %d" % [inside.get_theme_font_size(&"font_size"), outside.get_theme_font_size(&"font_size")])
	var swapped := Themes.new(Themes.NEUTRAL)
	swapped.set_font_size(&"font_size", Themes.FACE, 11)
	root.theme = swapped
	await _a_frame_passes()
	_verdict.check(inside.get_theme_font_size(&"font_size") == 77 and outside.get_theme_font_size(&"font_size") == 11, "and a look put on the root moves what is outside alone: %d against %d" % [inside.get_theme_font_size(&"font_size"), outside.get_theme_font_size(&"font_size")])
	line.free()
	made.done()
	root.theme = null


## The Label a text draws its words in, which is what reads the look.
func _words_of(text: Control) -> Label:
	return text.find_children("*", "Label", true, false)[0]


func _a_primitive_of_the_game_s_own_builds_by_its_kind() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	ui.register(&"blink", Blink)
	var made_node: Control = ui.build(ui.column([Desc.new(&"blink", {"rate": 3})]), root)
	_verdict.check(made_node.get_child_count() == 1 and made_node.get_child(0).name == "blink" and made_node.get_child(0).get_meta("rate") == 3, "a kind registered by the game is built by the game's script, inside a floor layout")
	made_node.free()
	made.done()
