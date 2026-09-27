extends SceneTree

## What must be true of overlays travelling with their descriptions: a
## drawer described inside a row of a screen is lifted beside the app,
## opened by a button with its parameter - its title and content reading
## it - and closed by its own way out, the press in its head or Escape,
## letting the parameter go; two overlays of one kind never collide, each
## its own place entered as its own one; a moment is raised by the command
## that makes its fact hold and lowered by the one that stops it, through
## the chart; and no application file mentions beside, the old way of
## carrying pop-ups, nor does an application answer it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_overlays.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Drawer := preload("res://addons/gd_chime/components/recipes/drawer.gd")
const Moment := preload("res://addons/gd_chime/components/recipes/moment.gd")
const Verdict := preload("res://tests/verdict.gd")

const SHOWS_ACTIONS := &"shows_the_actions"
const SHOWS_NOTES := &"shows_the_notes"
const STARTS := &"starts_the_act"
const DISMISSES := &"carries_on"
## Every demo, none of which may carry its pop-ups the old way; and the application every one extends.
const DEMOS := "res://demo"
const APPLICATION := "res://addons/gd_chime/application.gd"

var _verdict := Verdict.new()


## An act presented from the moment it is started until it is dismissed: the moment's fact.
class Act extends Fixture.Model:
	func told(action: StringName, payload: Dictionary) -> Phrase:
		set_value(&"flag", action == STARTS)
		return super(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_a_drawer_described_inside_a_row_opens_and_closes_with_its_parameter)
	await _verdict.states(_two_overlays_of_one_kind_never_collide)
	await _verdict.states(_a_moment_is_raised_and_lowered_by_the_commands_that_move_its_fact)
	await _verdict.states(_no_application_file_mentions_beside)
	quit(_verdict.deliver(get_script()))


func _frames(count: int) -> void:
	# so many frames, for a move to be carried out and laid out
	for frame: int in count:
		await process_frame


## Every set of words showing under this node.
func _texts(under: Node) -> Array:
	return under.find_children("*", "Label", true, false).filter(func(label: Label) -> bool: return label.is_visible_in_tree()).map(func(label: Label) -> String: return label.text)


## A drawer whose title and words say which one of its kind it was opened as.
func _drawer(made: Fixture, says: String) -> Desc:
	var ui := made.ui
	var title := func(which: Bound) -> Bound: return which.map(func(id: Variant) -> String: return "" if id == null else "%s %d" % [says, id])
	return Drawer.over(ui, title, func(which: Bound) -> Desc: return ui.text(which.map(func(id: Variant) -> String: return "" if id == null else "acting on %d" % id)))


func _a_drawer_described_inside_a_row_opens_and_closes_with_its_parameter() -> void:
	var made := Fixture.new(root, {SHOWS_ACTIONS: "Actions"})
	var ui := made.ui
	var actions := _drawer(made, "stop")
	var chosen := Bound.constant(9)
	var row := ui.row([ui.text("stop seven"), ui.button(SHOWS_ACTIONS, {opens = actions, with = 7}).named(&"seven"), ui.button(SHOWS_ACTIONS, {opens = actions, with = chosen}).named(&"nine")])
	ui.start(ui.app(&"app", [ui.screen(&"stop", [row])]))
	await _frames(3)
	var place: Node = made.driver.index.place_named(actions.get_place())
	_verdict.check(place != null and place.get_parent() == root and not made.driver.index.app.is_ancestor_of(place), "described inside a row, the drawer stands beside the app, lifted by the builder: %s" % [place.get_parent() if place != null else null])
	var seven: Pressable = ui.node_named(&"seven")
	seven.grab_focus()
	seven.pressed()
	await _frames(3)
	_verdict.check(made.driver.get_top() == [actions.get_place()] and made.driver.get_parameter(actions.get_place()) == 7 and _texts(place).has("stop 7") and _texts(place).has("acting on 7"), "the button opens it with its parameter, and its title and content read it: %s %s" % [made.driver.get_top(), _texts(place)])
	var close: Pressable = place.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.theme_type_variation == Drawer.CLOSE)[0]
	_verdict.check(close.action == ui.CLOSES and place.performs.get(ui.CLOSES) == Driver.BACK, "it closes by its own way out, the press every overlay declares going back: %s %s" % [close.action, place.performs])
	close.pressed()
	await _frames(3)
	_verdict.check(made.driver.get_top() == [&"app", &"stop"] and made.driver.get_parameter(actions.get_place()) == null and root.gui_get_focus_owner() == seven, "pressed, it is lowered, its parameter let go, the focus back on the button: %s" % [made.driver.get_top()])
	(ui.node_named(&"nine") as Pressable).pressed()
	await _frames(3)
	_verdict.check(made.driver.get_parameter(actions.get_place()) == 9 and _texts(place).has("acting on 9"), "a button given a bound value opens it as what that reads as it is pressed: %s" % [_texts(place)])
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await _frames(3)
	_verdict.check(made.driver.get_top() == [&"app", &"stop"], "and Escape, the key its way out is on, lowers it: %s" % [made.driver.get_top()])
	made.done()


func _two_overlays_of_one_kind_never_collide() -> void:
	var made := Fixture.new(root, {SHOWS_ACTIONS: "Actions", SHOWS_NOTES: "Notes"})
	var ui := made.ui
	var first := _drawer(made, "first")
	var second := _drawer(made, "second")
	var told := {"wrong": []}
	ui.start(ui.app(&"app", [ui.screen(&"stop", [ui.row([ui.button(SHOWS_ACTIONS, {opens = first, with = 1}).named(&"first"), ui.button(SHOWS_NOTES, {opens = second, with = 2}).named(&"second")])])]), func(wrong: Array) -> void: told["wrong"] = wrong)
	await _frames(3)
	var places: Array = [first.get_place(), second.get_place()].map(func(named: StringName) -> Node: return made.driver.index.place_named(named) if made.driver.index.has_place(named) else null)
	_verdict.check(first.get_place() != second.get_place() and not places.has(null) and places[0] != places[1] and told["wrong"].is_empty() and made.driver.index.refused_names().is_empty(), "two drawers are two places, each named its own, and nothing is refused or found wrong: %s %s" % [[first.get_place(), second.get_place()], told["wrong"]])
	(ui.node_named(&"first") as Pressable).pressed()
	await _frames(3)
	var up_first: Array = [made.driver.get_top(), _texts(places[0])]
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	(ui.node_named(&"second") as Pressable).pressed()
	await _frames(3)
	_verdict.check(up_first == [[first.get_place()], ["first 1", "✕", "acting on 1"]] and made.driver.get_top() == [second.get_place()] and _texts(places[1]) == ["second 2", "✕", "acting on 2"] and not places[0].is_visible_in_tree(), "each opens as its own one, and the other stays down: %s %s" % [up_first, _texts(places[1])])
	made.done()


func _a_moment_is_raised_and_lowered_by_the_commands_that_move_its_fact() -> void:
	var made := Fixture.new(root, {STARTS: "Start", DISMISSES: "Carry on"})
	var ui := made.ui
	var act := Act.new(made.chimes)
	made.commands.register(Chimes.GLOBAL, STARTS, act)
	made.commands.register(Chimes.GLOBAL, DISMISSES, act)
	var moment := Moment.make(ui, act.of(&"flag", false), [ui.text("the act is done")], DISMISSES)
	ui.start(ui.app(&"app", [ui.stack([ui.pressable(STARTS, {}, [ui.text("start")]), moment])]))
	await _frames(3)
	_verdict.check(made.driver.get_top() == [&"app"] and not made.driver.is_raised(), "while its fact does not hold, it is down: %s" % [made.driver.get_top()])
	made.commands.dispatch(&"app", STARTS, {})
	await _frames(3)
	var place: Node = made.driver.index.place_named(moment.get_place())
	_verdict.check(made.driver.get_top() == [moment.get_place()] and place.is_visible_in_tree() and _texts(place).has("the act is done"), "the command making its fact hold raises it over the app, through the chart: %s" % [made.driver.get_top()])
	made.commands.dispatch(moment.get_place(), DISMISSES, {})
	await _frames(3)
	_verdict.check(made.driver.get_top() == [&"app"] and not place.is_visible_in_tree(), "the one stopping it lowers it: %s" % [made.driver.get_top()])
	act.free()
	made.done()


func _no_application_file_mentions_beside() -> void:
	# beside as code: a call of it or a function of that name
	var code := RegEx.create_from_string("\\bbeside\\s*\\(")
	var mentions: Array = _mentions(DEMOS, func(text: String) -> bool: return code.search(text) != null)
	var answered: Array = (load(APPLICATION) as Script).get_script_method_list().filter(func(method: Dictionary) -> bool: return method["name"] == "beside")
	_verdict.check(mentions.is_empty() and answered.is_empty(), "no application file mentions beside, and an application has no beside to answer: %s %s" % [mentions, answered])


## Every script under this folder, at any depth, whose text says so.
func _mentions(folder: String, says: Callable) -> Array:
	var found: Array = []
	# every file here, a script read and every folder searched
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".gd") and says.call(FileAccess.get_file_as_string(folder.path_join(file))):
			found.append(folder.path_join(file))
	# every folder here, searched in turn
	for inner: String in DirAccess.get_directories_at(folder):
		found.append_array(_mentions(folder.path_join(inner), says))
	return found
