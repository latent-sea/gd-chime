extends SceneTree

## What must be true of the facets drawn over the one filter model: every
## column's title over its values, each saying how many it would keep once
## the counts land; a value pressed is picked and drawn so, and pressed
## again let go; a value that would keep nothing is inert with the reason on
## its face; a mark the caller gives stands before a value's words; the
## stretch is a range slider over the filters' bounds; and the chips say
## what narrows it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_facet_list.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const Filters := preload("res://addons/gd_chime/filters.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const RangeSlider := preload("res://addons/gd_chime/components/primitives/range_slider.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const FacetList := preload("res://addons/gd_chime/components/recipes/facet_list.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"shop"
const PATIENCE := 300
const WORDS := {Filters.TOGGLES: "pick", Filters.SETS_RANGE: "set the price", Filters.TURNS: "turn the filter", Filters.REMOVES: "remove the filter"}
const PIECES := [["sofa", "oak", 900.0], ["chair", "oak", 150.0], ["table", "walnut", 1200.0], ["bed", "brass", 1500.0]]

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(800, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_every_facet_is_titled_over_its_values_each_counted)
	await _verdict.states(_a_value_pressed_is_picked_and_drawn_so_and_a_value_keeping_nothing_is_inert)
	await _verdict.states(_the_range_is_a_range_slider_and_the_chips_say_what_narrows_it)
	quit(_verdict.deliver(get_script()))


## The facets drawn over four pieces: [fixture, filters, jobs, view].
func _drawn() -> Array:
	var made := Fixture.new(root, WORDS)
	var ui := made.ui
	var budget := FrameBudget.new(made.chimes, 1000.0, 0.9, 3)
	var jobs := Jobs.new(made.chimes, budget, 2, 64, false)
	var rows := PackedRows.new({&"kind": PackedRows.WORDS, &"material": PackedRows.WORDS, &"price": PackedRows.NUMBER})
	# every piece, a row
	for piece: Array in PIECES:
		rows.add(piece)
	var view := QueriedRows.new(made.chimes, rows, jobs)
	made.commands.stand(REGION, view)
	var worded := func(stretch: Vector2) -> Phrase: return Phrase.with("%d to %d", [stretch.x, stretch.y])
	var spec := {search = &"kind", any_of = [&"kind", &"material"], between = {column = &"price", bounds = Vector2(150.0, 1500.0), words = worded}}
	var filters := Filters.new(made.chimes, spec, {over = rows, on = jobs, asks = view.ask})
	made.commands.stand(REGION, filters)
	for model: Node in [budget, jobs, view, filters]:
		root.add_child(model)
	var mark := func(_value: Bound) -> Desc: return ui.text("◆").named(&"mark")
	var parts := FacetList.make(ui, filters, {&"material": Phrase.of("material"), &"kind": Phrase.of("kind")}, {&"material": mark})
	var range_part := FacetList.range_of(ui, filters, Phrase.of("price"), {step = 50.0, words = worded})
	ui.start(ui.app(&"app", [ui.screen(REGION, [ui.column(parts + [range_part, FacetList.chips(ui, filters)])])]))
	await _settled(filters, view)
	return [made, filters, jobs, view]


func _settled(filters: Filters, view: QueriedRows) -> void:
	var frames := 0
	# a frame at a time, at least three, until nothing is out
	while frames < PATIENCE and (frames < 3 or filters.facets.get_busy() or view.get_busy()):
		await process_frame
		frames += 1


func _value(words: String) -> Pressable:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.action == Filters.TOGGLES and part.payload().get("value") == words)[0]


func _said(under: Node) -> Array:
	return under.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and part.is_visible_in_tree() and part.get_text() != "").map(func(part: Text) -> String: return part.get_text())


func _done(both: Array) -> void:
	(both[2] as Jobs).stop()
	(both[0] as Fixture).done()


func _every_facet_is_titled_over_its_values_each_counted() -> void:
	var both: Array = await _drawn()
	var said := _said(root)
	_verdict.check(said.find("material") < said.find("kind") and said.find("material") >= 0, "every column titled, in the order given: %s" % [said])
	_verdict.check(_said(_value("oak")) == ["◆", "oak", "2"] and _said(_value("sofa")) == ["sofa", "1"], "each value its words and how many it would keep, a mark before it where one is given: %s %s" % [_said(_value("oak")), _said(_value("sofa"))])
	_done(both)


func _a_value_pressed_is_picked_and_drawn_so_and_a_value_keeping_nothing_is_inert() -> void:
	var both: Array = await _drawn()
	_value("oak").pressed()
	await _settled(both[1], both[3])
	_verdict.check(_value("oak").theme_type_variation == FacetList.PICKED and _value("walnut").theme_type_variation == FacetList.VALUE and _names(both[3]) == ["sofa", "chair"], "pressed, oak is picked, drawn so, and the collection narrowed to it")
	_verdict.check(not _value("table").is_usable() and _said(_value("table")).has("Nothing would match"), "among the oak pieces, a table would keep nothing: inert, saying why: %s" % [_said(_value("table"))])
	_value("oak").pressed()
	await _settled(both[1], both[3])
	_verdict.check(_value("oak").theme_type_variation == FacetList.VALUE and _names(both[3]).size() == 4 and _value("table").is_usable(), "pressed again, oak is let go and the table can be had again")
	_done(both)


func _the_range_is_a_range_slider_and_the_chips_say_what_narrows_it() -> void:
	var both: Array = await _drawn()
	var slider: RangeSlider = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is RangeSlider)[0]
	_verdict.check(slider.get_value() == Vector2(150, 1500) and _said(slider)[0] == "150 to 1500", "the stretch is a slider over the filters' bounds, in the caller's words: %s" % [_said(slider)])
	slider.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.physical_keycode = KEY_RIGHT
	key.pressed = true
	root.push_input(key)
	await _settled(both[1], both[3])
	_verdict.check((both[1] as Filters).get_range() == Vector2(200, 1500) and _said(root).has("200 to 1500"), "stepped, the filters' stretch moves and a chip says so: %s" % [(both[1] as Filters).get_range()])
	_done(both)


func _names(view: QueriedRows) -> Array:
	return Array(view.get_order()).map(func(row: int) -> String: return PIECES[row][0])
