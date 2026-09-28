extends SceneTree

## What must be true of a pressable, and of the bell button recipe over it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_pressable.gd
##
## A pressable is in one of four states - glowing, inert, hover, normal -
## and draws the look's stylebox for it under its style, the focus over it
## while the focus shows; its payload is what it was given, or a bound value
## read as the press lands; its reason is a bound value its content reads,
## re-read as it draws; its words take the state's ink, and a press inside
## a press keeps its own (face_ink.gd); a bell button is a pressable
## holding its action's words and the reason, hidden while empty; and it
## repeats while held when described so.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Outgoing := preload("res://addons/gd_chime/components/primitives/outgoing.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Pressables := preload("res://addons/gd_chime/theme_pressables.gd")
const Navigation := preload("res://addons/gd_chime/theme_navigation.gd")

const CENTRE := Vector2(80, 40)
const OUTSIDE := Vector2(300, 300)

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_it_draws_the_look_s_stylebox_and_ink_for_each_of_its_four_states)
	await _verdict.states(_a_change_of_look_blends_the_old_box_fading_over_the_new_and_the_ink_between)
	await _verdict.states(_a_change_mid_blend_never_jumps_and_reduced_or_with_no_clock_it_is_short_or_at_once)
	await _verdict.states(_a_state_sharing_its_box_with_another_still_takes_its_own_ink)
	await _verdict.states(_its_payload_is_read_as_the_press_lands_and_its_reason_is_read_as_it_draws)
	await _verdict.states(_a_bell_button_holds_the_words_and_the_reason_hidden_while_empty)
	await _verdict.states(_one_described_current_while_a_value_holds_is_current_then_and_only_then_wherever_it_goes)
	await _verdict.states(_one_built_into_a_live_list_later_has_its_words_in_its_state_s_ink)
	await _verdict.states(_a_press_inside_a_press_keeps_its_own_ink)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _point_at(at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	root.push_input(move)


func _click(at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at
	root.push_input(click)


## The app with one pressable of this action in it, arrived at.
func _app(made: Fixture, action: StringName, content: Array = [], payload: Variant = {}) -> Pressable:
	var ui := made.ui
	# the pressable takes two fifths of the width, so there is an outside to point at
	ui.start(ui.app(&"app", [ui.row([ui.pressable(action, payload, content).named(&"it").basis(0.4), ui.surface(Themes.SURFACE).grow()])]))
	return ui.node_named(&"it")


func _texts_under(node: Node) -> Array[Text]:
	var found: Array[Text] = []
	for child: Node in node.get_children():
		if child is Text:
			found.append(child)
		found.append_array(_texts_under(child))
	return found


func _it_draws_the_look_s_stylebox_and_ink_for_each_of_its_four_states() -> void:
	var made := Fixture.new(root, {&"adds": "add one"})
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"adds", model)
	# the builder hands it the prompts: nothing here does, so a builder that forgot would show
	var pressed := _app(made, &"adds", [made.ui.text(made.ui.words(&"adds"))])
	made.ui.motion.by_hand = true
	made.ui.motion.still = false
	await _a_frame_passes()
	pressed.release_focus()
	var seen: Array[StringName] = []
	# normal, then hover, then inert, then glowing, each brought about as it would be in play
	for bring: Array in [[&"normal", func() -> void: pass], [&"hover", func() -> void: _point_at(CENTRE)], [&"inert", func() -> void: model.refuse(&"adds", Phrase.of("not now"))], [&"glowing", func() -> void: model.refuse_nothing(); made.prompts.raise(&"guide", &"adds")]]:
		(bring[1] as Callable).call()
		await _a_frame_passes()
		# a change of look blends: the clock run past the blend, the look is the state's alone
		made.ui.motion.step(1.0)
		await _a_frame_passes()
		var state: StringName = pressed.get_state()
		var ink: Color = root.theme.get_color(StringName("font_color_" + state), Themes.PRESSABLE)
		var label: Label = _texts_under(pressed)[0].get_child(0)
		if state == bring[0] and pressed.get_drawn()[0] == root.theme.get_stylebox(state, Themes.PRESSABLE) and label.get_theme_color(&"font_color") == ink:
			seen.append(state)
	_verdict.check(seen == [&"normal", &"hover", &"inert", &"glowing"], "in each of its four states it draws the look's stylebox for that state under its style, and its words in the state's ink: %s" % [seen])
	pressed.grab_focus()
	await _a_frame_passes()
	_verdict.check(pressed.get_drawn().size() == 2 and pressed.get_drawn()[1] == root.theme.get_stylebox(&"focus", Themes.PRESSABLE), "the focus shown, the focus stylebox is drawn over it")
	_point_at(OUTSIDE)
	model.free()
	made.done()


## The boxes going out over a face, oldest change on top.
func _going(face: Control) -> Array:
	return face.get_children(true).filter(func(child: Node) -> bool: return child is Outgoing and not child.is_queued_for_deletion())


## A pressable made inert, stepped to the middle of the look's restyle - 90ms - and to its end.
func _a_change_of_look_blends_the_old_box_fading_over_the_new_and_the_ink_between() -> void:
	var made := Fixture.new(root, {&"adds": "add one"})
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"adds", model)
	var pressed := _app(made, &"adds", [made.ui.text(made.ui.words(&"adds"))])
	made.ui.motion.by_hand = true
	made.ui.motion.still = false
	await _a_frame_passes()
	pressed.release_focus()
	var label: Label = _texts_under(pressed)[0].get_child(0)
	var normal_ink: Color = root.theme.get_color(&"font_color_normal", Themes.PRESSABLE)
	var inert_ink: Color = root.theme.get_color(&"font_color_inert", Themes.PRESSABLE)
	_verdict.check(_going(pressed).is_empty() and label.get_theme_color(&"font_color") == normal_ink, "first drawn, it is simply there: nothing going out")
	model.refuse(&"adds", Phrase.of("not now"))
	await _a_frame_passes()
	var going := _going(pressed)
	_verdict.check(going.size() == 1 and (going[0] as Outgoing)._box == root.theme.get_stylebox(&"normal", Themes.PRESSABLE) and pressed.get_drawn()[0] == root.theme.get_stylebox(&"inert", Themes.PRESSABLE), "made inert, it is drawn in the new box with the old one laid over it")
	_verdict.check((going[0] as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE and not pressed.get_children().has(going[0]), "the layer takes no press and is not among its content")
	made.ui.motion.step(0.045)
	await _a_frame_passes()
	var between: Color = label.get_theme_color(&"font_color")
	_verdict.check((going[0] as Control).modulate.a > 0.0 and (going[0] as Control).modulate.a < 1.0 and between != normal_ink and between != inert_ink, "mid-blend the old box is part faded and the ink is between the two: %s %s" % [(going[0] as Control).modulate.a, between])
	made.ui.motion.step(0.045)
	await _a_frame_passes()
	_verdict.check(_going(pressed).is_empty() and label.get_theme_color(&"font_color") == inert_ink and made.ui.motion.get_running() == 0, "the blend over, the old box is gone and the ink is the new state's, nothing running")
	model.free()
	made.done()


func _a_change_mid_blend_never_jumps_and_reduced_or_with_no_clock_it_is_short_or_at_once() -> void:
	var made := Fixture.new(root, {&"adds": "add one"})
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"adds", model)
	var pressed := _app(made, &"adds", [made.ui.text(made.ui.words(&"adds"))])
	made.ui.motion.by_hand = true
	made.ui.motion.still = false
	await _a_frame_passes()
	pressed.release_focus()
	var label: Label = _texts_under(pressed)[0].get_child(0)
	model.refuse(&"adds", Phrase.of("not now"))
	await _a_frame_passes()
	made.ui.motion.step(0.045)
	await _a_frame_passes()
	var first: Control = _going(pressed)[0]
	var faded: float = first.modulate.a
	var ink: Color = label.get_theme_color(&"font_color")
	model.refuse_nothing()
	await _a_frame_passes()
	var going := _going(pressed)
	_verdict.check(going.size() == 2 and going[1] == first and first.modulate.a == faded and (going[0] as Control).modulate.a == 1.0, "changed again mid-blend, the box that was going still goes as it was, over the newer one now going under it: %s" % [going.map(func(layer: Control) -> float: return layer.modulate.a)])
	made.ui.motion.step(0.001)
	await _a_frame_passes()
	var next: Color = label.get_theme_color(&"font_color")
	_verdict.check(absf(next.r - ink.r) + absf(next.g - ink.g) + absf(next.b - ink.b) < 0.05, "and a moment on, the ink is beside the colour it had reached: it went on from there: %s then %s" % [ink, next])
	made.ui.motion.step(1.0)
	await _a_frame_passes()
	made.ui.motion.told(Motion.REDUCES, {"on": true})
	model.refuse(&"adds", Phrase.of("not now"))
	await _a_frame_passes()
	_verdict.check(_going(pressed).size() == 1, "reduced, a change of look is still a cross-fade")
	made.ui.motion.step(0.09)
	await _a_frame_passes()
	_verdict.check(_going(pressed).is_empty(), "a short one: done in the quick duration")
	pressed.motion = null
	model.refuse_nothing()
	await _a_frame_passes()
	_verdict.check(_going(pressed).is_empty() and label.get_theme_color(&"font_color") == root.theme.get_color(&"font_color_normal", Themes.PRESSABLE), "with no clock handed to it, a change of look switches")
	model.free()
	made.done()


## A look may draw two states in one box and tell them apart by ink alone -
## a link faded while inert. A press built refused, then made usable, is
## drawn in the same box throughout, and its words still end in normal's ink.
func _a_state_sharing_its_box_with_another_still_takes_its_own_ink() -> void:
	var was: StyleBox = root.theme.get_stylebox(&"inert", Themes.PRESSABLE)
	var shared: StyleBox = root.theme.get_stylebox(&"normal", Themes.PRESSABLE)
	root.theme.set_stylebox(&"inert", Themes.PRESSABLE, shared)
	var made := Fixture.new(root, {&"adds": "add one"})
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"adds", model)
	model.refuse(&"adds", Phrase.of("not yet"))
	var pressed := _app(made, &"adds", [made.ui.text(made.ui.words(&"adds"))])
	made.ui.motion.by_hand = true
	made.ui.motion.still = false
	await _a_frame_passes()
	pressed.release_focus()
	var label: Label = _texts_under(pressed)[0].get_child(0)
	var normal_ink: Color = root.theme.get_color(&"font_color_normal", Themes.PRESSABLE)
	var inert_ink: Color = root.theme.get_color(&"font_color_inert", Themes.PRESSABLE)
	_verdict.check(pressed.get_state() == &"inert" and label.get_theme_color(&"font_color") == inert_ink and inert_ink != normal_ink, "built refused, its words are in inert's ink, which is not normal's: %s" % label.get_theme_color(&"font_color").to_html(false))
	model.refuse_nothing()
	await _a_frame_passes()
	made.ui.motion.step(1.0)
	await _a_frame_passes()
	_verdict.check(pressed.get_state() == &"normal" and pressed.get_drawn()[0] == shared and _going(pressed).is_empty(), "made usable, it is drawn in the one shared box, with no box going out over it")
	_verdict.check(label.get_theme_color(&"font_color") == normal_ink, "and its words have gone to normal's ink though the box never changed: %s, wanted %s" % [label.get_theme_color(&"font_color").to_html(false), normal_ink.to_html(false)])
	root.theme.set_stylebox(&"inert", Themes.PRESSABLE, was)
	model.free()
	made.done()


func _its_payload_is_read_as_the_press_lands_and_its_reason_is_read_as_it_draws() -> void:
	var made := Fixture.new(root, {&"adds": "add one"})
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"words", "first")
	made.commands.register(&"app", &"adds", model)
	var pressed := _app(made, &"adds", [made.ui.reason()], model.of(&"words").map(func(words: String) -> Dictionary: return {"which": words}))
	await _a_frame_passes()
	model.set_value(&"words", "second")
	_click(CENTRE)
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"adds"] and pressed.payload() == {"which": "second"}, "the payload is the bound value as the press lands: %s %s" % [pressed.payload(), model.told_actions])
	var reason: Text = _texts_under(pressed)[0]
	_verdict.check(not reason.visible and reason.get_text() == "", "nothing to say, the reason is hidden")
	model.refuse(&"adds", Phrase.of("not in this phase"))
	await _a_frame_passes()
	_verdict.check(reason.visible and reason.get_text() == "not in this phase", "the door refusing, the reason is re-read as the pressable draws, and shown: %s" % reason.get_text())
	_point_at(OUTSIDE)
	model.free()
	made.done()


func _a_bell_button_holds_the_words_and_the_reason_hidden_while_empty() -> void:
	var made := Fixture.new(root, {&"adds": "add one"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"adds", model)
	ui.start(ui.app(&"app", [ui.row([ui.button(&"adds", {content = [ui.text("icon")]}).named(&"it").repeats(0.01, 0.01).basis(0.4), ui.surface(Themes.SURFACE).grow()])]))
	var pressed: Pressable = ui.node_named(&"it")
	await _a_frame_passes()
	var texts := _texts_under(pressed)
	_verdict.check(texts.size() == 3 and texts[0].get_text() == "icon" and texts[1].get_text() == "add one" and not texts[2].visible, "the content first, then the register's words, then the reason hidden: %s" % [texts.map(func(t: Text) -> String: return t.get_text())])
	_verdict.check(pressed.theme_type_variation == Pressables.BUTTON and pressed.get_drawn()[0] == root.theme.get_stylebox(&"normal", Themes.PRESSABLE), "drawn as a BellButton, the variation of Pressable the look holds")
	_click(CENTRE)
	for frame: int in range(8):
		await process_frame
	_verdict.check(model.told_actions.size() >= 2, "held, described to repeat, it was pressed again: %d" % model.told_actions.size())
	_point_at(OUTSIDE)
	model.free()
	made.done()


## Two pressables current while a model's flag holds: one going nowhere,
## and one going to the very place the reader is on, which would be current
## by navigation - each current exactly while the flag holds, drawn so in
## place as it moves.
func _one_described_current_while_a_value_holds_is_current_then_and_only_then_wherever_it_goes() -> void:
	var made := Fixture.new(root, {&"fronts": "bring to the front", &"stays": "stay here"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"flag", false)
	made.commands.register(&"here", &"fronts", model)
	ui.start(ui.app(&"app", [ui.screen(&"here", [ui.row([
		ui.pressable(&"fronts", {}, [ui.text("front")], Navigation.TAB).current_while(model.of(&"flag")).named(&"nowhere").basis(0.4),
		ui.pressable(&"stays", {}, [ui.text("here")], &"Pressable").goes_to(&"here").current_while(model.of(&"flag")).named(&"here_too").basis(0.4),
	])])]))
	await _a_frame_passes()
	var nowhere: Pressable = ui.node_named(&"nowhere")
	var here_too: Pressable = ui.node_named(&"here_too")
	_verdict.check(made.driver.get_top().has(&"here") and nowhere.get_state() == &"normal" and not here_too.is_current(), "while the value does not hold, neither is current - not even the one going where the reader is: %s %s" % [nowhere.get_state(), here_too.get_state()])
	model.set_value(&"flag", true)
	await _a_frame_passes()
	var current_box: StyleBox = root.theme.get_stylebox(&"current", Navigation.TAB)
	_verdict.check(nowhere.is_current() and nowhere._last_box == current_box and here_too.get_state() == &"current", "the value holding, both are current, the flap drawn in the look's current box in place: %s %s" % [nowhere.get_state(), here_too.get_state()])
	model.set_value(&"flag", false)
	await _a_frame_passes()
	_verdict.check(not nowhere.is_current() and nowhere._last_box == root.theme.get_stylebox(&"normal", Navigation.TAB) and not here_too.is_current(), "and drawn at rest again as it stops holding: %s %s" % [nowhere.get_state(), here_too.get_state()])
	model.free()
	made.done()


## A list of presses, one item added once the app stands: the press built
## for it then - its words put in after it was first drawn - has them in its
## state's ink, as the first one's are.
func _one_built_into_a_live_list_later_has_its_words_in_its_state_s_ink() -> void:
	var made := Fixture.new(root, {&"opens": "open"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	root.add_child(model)
	made.commands.register(Chimes.GLOBAL, &"opens", model)
	model.set_value(&"items", [{"id": 1, "name": "pear"}])
	var row := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.column([ui.text(item.field("name"))])])
	ui.start(ui.app(&"app", [ui.each(model.of(&"items"), row, func(item: Dictionary) -> Variant: return item["id"]).named(&"list")]))
	await _a_frame_passes()
	model.set_value(&"items", [{"id": 1, "name": "pear"}, {"id": 2, "name": "fig"}])
	await _a_frame_passes()
	await _a_frame_passes()
	var inks: Array = ui.node_named(&"list").find_children("*", "Label", true, false).map(func(label: Label) -> bool: return label.has_theme_color_override(&"font_color") and label.get_theme_color(&"font_color") == (label.get_parent().get_parent().get_parent() as Pressable)._colour())
	_verdict.check(inks == [true, true], "the press built later has its words in its state's ink, as the first's are: %s" % [inks])
	model.free()
	made.done()


## A press stands inside a press often - a button on a card - and each
## draws its own box: the words of the inner one are in ITS state's ink,
## never the outer's, or a card's ink would be read on a button's own
## ground. The outer inks the words it holds itself, as it always did.
func _a_press_inside_a_press_keeps_its_own_ink() -> void:
	var made := Fixture.new(root, {&"opens": "open", &"enters": "put it on the stall"})
	var ui := made.ui
	var was: Color = root.theme.get_color(&"font_color_normal", Pressables.BUTTON)
	# an ink no other press has, so words in it can only have come from the button
	root.theme.set_color(&"font_color_normal", Pressables.BUTTON, Color.RED)
	var inner := ui.pressable(&"enters", {}, [ui.text(Phrase.of("put it on the stall"))], Pressables.BUTTON).named(&"inner")
	var outer := ui.pressable(&"opens", {}, [ui.column([ui.text(Phrase.of("a crate of pears")).named(&"its own"), inner])], Themes.PRESSABLE).named(&"outer")
	made.answer([&"opens", &"enters"])
	ui.start(ui.app(&"app", [outer]))
	await _a_frame_passes()
	var held: Label = (ui.node_named(&"inner") as Pressable).find_children("*", "Label", true, false)[0]
	var mine: Label = (ui.node_named(&"its own") as Text).find_children("*", "Label", true, false)[0]
	var outer_ink: Color = (ui.node_named(&"outer") as Pressable)._colour()
	_verdict.check(held.get_theme_color(&"font_color") == Color.RED and Color.RED != outer_ink, "the words of a press inside a press are in the inner press's own ink, which is not the outer's: %s on the inner, %s on the outer" % [held.get_theme_color(&"font_color").to_html(false), outer_ink.to_html(false)])
	_verdict.check(mine.get_theme_color(&"font_color") == outer_ink, "and the words the outer press holds itself are still in the outer's: %s against %s" % [mine.get_theme_color(&"font_color").to_html(false), outer_ink.to_html(false)])
	# the outer press made to draw itself again, which is when it inks: a card pointed at, prompted, refused
	made.prompts.raise(&"guide", &"opens")
	await _a_frame_passes()
	var glowing: Color = (ui.node_named(&"outer") as Pressable)._colour()
	_verdict.check(mine.get_theme_color(&"font_color") == glowing and glowing != outer_ink, "the outer press drawn again inks the words it holds itself: %s" % mine.get_theme_color(&"font_color").to_html(false))
	_verdict.check(held.get_theme_color(&"font_color") == Color.RED, "and it does not reach through the press inside it, whose words stand on that press's own box: %s" % held.get_theme_color(&"font_color").to_html(false))
	root.theme.set_color(&"font_color_normal", Pressables.BUTTON, was)
	made.done()
