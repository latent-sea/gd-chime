extends SceneTree

## What must be true of the colour-blind palettes: that a look turned for an
## eye keeps the structure it was built with, that it really does separate
## what that eye could not tell apart, that switching re-colours the controls
## that are already there, that a conditional format carries a mark, and that
## the developer's simulator goes over everything and touches nothing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_palettes.gd

const Palettes := preload("res://demo/gallery/looks/palettes.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const Sight := preload("res://demo/gallery/looks/sight.gd")
const SimulatedSight := preload("res://addons/gd_chime/components/primitives/simulated_sight.gd")
const FormatMarks := preload("res://addons/gd_chime/components/recipes/format_marks.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Fixture := preload("res://tests/fixture.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Verdict := preload("res://tests/verdict.gd")
const Look := preload("res://addons/gd_chime/look.gd")
const Paint := preload("res://addons/gd_chime/paint.gd")


## Counts what is pushed as an error, which is how a look is told it is wrong.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1

## The three eyes a palette is turned for, the plain one being no turn at all.
const DEFICIENCIES: Array[StringName] = [SimulatedSight.DEUTERANOPIA, SimulatedSight.PROTANOPIA, SimulatedSight.TRITANOPIA]
## How much contrast a variant may lose to the rounding of the hue search.
const SLACK := 0.25

var _verdict := Verdict.new()
var _hearing := Hearing.new()


func _init() -> void:
	await process_frame
	await _verdict.states(_a_turned_colour_keeps_the_luminance_it_had)
	await _verdict.states(_every_look_has_all_three_variants_and_keeps_its_contrast)
	await _verdict.states(_a_variant_sets_the_accent_further_from_the_ground_for_that_eye)
	await _verdict.states(_the_near_greys_a_looks_structure_is_made_of_never_turn)
	await _verdict.states(_switching_the_sight_re_colours_the_controls_already_built)
	await _verdict.states(_the_sight_is_a_setting_and_the_looks_dress_again_when_it_moves)
	await _verdict.states(_a_format_that_singles_a_value_out_without_marking_it_is_reported)
	await _verdict.states(_the_simulator_goes_over_everything_and_takes_no_press)
	await _verdict.states(_an_underline_a_hatch_and_a_ring_wear_the_sight_s_own_palette)
	await _verdict.states(_an_ordinary_change_of_look_reaches_what_is_painted)
	await _verdict.states(_the_light_falling_on_a_bevel_never_turns_with_the_palette)
	await _verdict.states(_a_box_merged_in_from_another_theme_reads_the_one_that_holds_it)
	await _verdict.states(_a_painter_naming_a_colour_the_look_does_not_hold_is_reported)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The whole point of turning by luminance rather than by value: a hue moved
## right round the circle still reads as bright as it did, so every contrast
## the look was built on is the contrast it still has.
func _a_turned_colour_keeps_the_luminance_it_had() -> void:
	var worst := 0.0
	var unmoved := true
	# every eighth of the circle, over a red, a blue and a pale tint
	for step: int in range(8):
		for colour: Color in [Color("#e30613"), Color("#2b5bff"), Color("#eaddff")]:
			var moved := Palettes.turned(colour, float(step) / 8.0)
			worst = maxf(worst, absf(Palettes.luminance(moved) - Palettes.luminance(colour)))
			if step == 0 and moved.to_html() != colour.to_html():
				unmoved = false
	_verdict.check(worst < 0.01, "a hue turned anywhere round the circle keeps its luminance: worst drift %s" % worst)
	_verdict.check(unmoved, "and no turn at all leaves the colour exactly as it was")
	_verdict.check(is_equal_approx(Palettes.contrast(Color.BLACK, Color.WHITE), 21.0) and is_equal_approx(Palettes.contrast(Color.RED, Color.RED), 1.0), "contrast is the standard's own ratio: 21 for black on white, 1 for a colour on itself")


## Each of the eleven looks has a palette for each eye, and in none of them
## has the accent or the ink lost the contrast it had against the ground.
func _every_look_has_all_three_variants_and_keeps_its_contrast() -> void:
	var worst := ""
	var lost := 0.0
	# every look, in every eye, against the palette it was built with
	for named: StringName in Looks.NAMES:
		var base: DemoTheme = Looks.make(named)
		for sight: StringName in DEFICIENCIES:
			var variant: DemoTheme = Looks.make(named, sight)
			for pair: Array in [[&"accent", &"ground"], [&"ink", &"ground"]]:
				var was := Palettes.contrast(base.palette[pair[0]], base.palette[pair[1]])
				var now := Palettes.contrast(variant.palette[pair[0]], variant.palette[pair[1]])
				if was - now > lost:
					lost = was - now
					worst = "%s in %s: %s against %s fell from %s to %s" % [named, sight, pair[0], pair[1], was, now]
	_verdict.check(lost < SLACK, "every look has all three variants and no variant loses contrast: worst was %s" % ("none" if worst == "" else worst))


## The point of a variant, said as a number: the accent and the ground, as
## that eye receives them, differ in colour by more than they did. Where a
## look already picked an accent that eye can separate, the search finds no
## turn that beats it and the variant is the palette itself - so the claim is
## that it is never worse, and better wherever there was anything to gain.
func _a_variant_sets_the_accent_further_from_the_ground_for_that_eye() -> void:
	var worse := ""
	var better := 0
	# every look in every eye: the accent against the ground it sits on, as that eye receives them
	for named: StringName in Looks.NAMES:
		var base: DemoTheme = Looks.make(named)
		for sight: StringName in DEFICIENCIES:
			var variant: DemoTheme = Looks.make(named, sight)
			var was := Palettes.apart(base.palette[&"accent"], base.palette[&"ground"], sight)
			var now := Palettes.apart(variant.palette[&"accent"], variant.palette[&"ground"], sight)
			if now < was - 0.000001:
				worse += "%s in %s: %s then %s; " % [named, sight, was, now]
			elif now > was + 0.000001:
				better += 1
	_verdict.check(worse == "", "no variant of any look puts the accent closer to its ground for that eye: %s" % ("none does" if worse == "" else worse))
	_verdict.check(better >= 24, "and most of the thirty-three put it further: %s of them" % better)
	# a palette built to be confused: a red accent on a green ground, which an eye without the middle cone receives as one colour
	var confusable := {&"ground": Color("#2e7d32"), &"raised": Color("#2e7d32"), &"lit": Color("#3c8f40"), &"ink": Color.BLACK, &"ink_soft": Color("#555555"), &"accent": Color("#c0392b"), &"shade": Color(0.0, 0.0, 0.0, 0.5)}
	var blind: DemoTheme = DemoTheme.new(confusable)
	Palettes.rewear(blind, SimulatedSight.DEUTERANOPIA)
	var was_apart := Palettes.apart(confusable[&"accent"], confusable[&"ground"], SimulatedSight.DEUTERANOPIA)
	var now_apart := Palettes.apart(blind.palette[&"accent"], blind.palette[&"ground"], SimulatedSight.DEUTERANOPIA)
	_verdict.check(now_apart > was_apart * 2.0, "a red accent on a green ground, which that eye receives as one colour, is set more than twice as far apart: %s then %s" % [was_apart, now_apart])
	_verdict.check(absf(Palettes.contrast(blind.palette[&"accent"], blind.palette[&"ground"]) - Palettes.contrast(confusable[&"accent"], confusable[&"ground"])) < SLACK, "and it still stands at the contrast it stood at")


## A variant moves hue and nothing else: the greys and near-greys the look's
## depth is built out of are exactly the colours they were.
func _the_near_greys_a_looks_structure_is_made_of_never_turn() -> void:
	var moved := ""
	# every look: the ground and the ink, which carry no hue worth the name
	for named: StringName in Looks.NAMES:
		var base: DemoTheme = Looks.make(named)
		for sight: StringName in DEFICIENCIES:
			var variant: DemoTheme = Looks.make(named, sight)
			for grey: StringName in [&"ground", &"ink"]:
				# a tenth of the accent, not the threshold the code uses: a test measuring by the number it is checking cannot fail
				var grey_enough: float = Palettes.chroma(base.palette[&"accent"]) * 0.1
				if Palettes.chroma(base.palette[grey]) < grey_enough and variant.palette[grey] != base.palette[grey]:
					moved += "%s in %s: %s; " % [named, sight, grey]
	_verdict.check(moved == "", "a colour carrying less hue than the accent asks is left exactly as it was: %s" % ("every one" if moved == "" else moved))


## Switching the sight is one assignment on the root: the pressable and the
## surface that were already built are the same nodes afterwards, wearing
## colours they read back out of the theme.
func _switching_the_sight_re_colours_the_controls_already_built() -> void:
	var made := Fixture.new(root, {&"ticks": "tick"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"ticks", model)
	root.theme = Looks.make(&"placeholder")
	ui.start(ui.app(&"app", [ui.row([ui.pressable(&"ticks", {}, [ui.text("a")]).named(&"press"), ui.surface(DemoTheme.PANEL, [ui.text("b")]).named(&"sheet")])]))
	await _a_frame_passes()
	var press: Pressable = ui.node_named(&"press")
	var sheet: Surface = ui.node_named(&"sheet")
	var was_press: Color = press.get_theme_stylebox(&"glowing").bg_color
	var was_sheet: Color = sheet.get_theme_stylebox(&"panel").bg_color
	var press_id := press.get_instance_id()
	var sheet_id := sheet.get_instance_id()
	root.theme = Looks.make(&"placeholder", SimulatedSight.DEUTERANOPIA)
	await _a_frame_passes()
	_verdict.check(press.get_instance_id() == press_id and sheet.get_instance_id() == sheet_id, "the same two nodes are still there")
	_verdict.check(press.get_theme_stylebox(&"glowing").bg_color != was_press and sheet.get_theme_stylebox(&"panel").bg_color != was_sheet, "and both read a different colour out of the theme: %s then %s" % [was_press, press.get_theme_stylebox(&"glowing").bg_color])
	root.theme = Looks.make(&"placeholder")
	await _a_frame_passes()
	_verdict.check(press.get_theme_stylebox(&"glowing").bg_color == was_press, "the plain sight back, the pressable is the colour it started as")
	model.free()
	made.done()
	root.theme = null


## The sight is an ordinary setting: a command sets it, a bell says it moved,
## and the looks hear that and dress the window again, in the same look.
func _the_sight_is_a_setting_and_the_looks_dress_again_when_it_moves() -> void:
	var made := Fixture.new(root)
	var sight := Sight.new(made.chimes)
	var looks := Looks.new(made.chimes, root, sight)
	made.commands.stand(&"app", sight)
	made.commands.stand(&"app", looks)
	for node: Node in [sight, looks]:
		root.add_child(node)
	made.commands.register(&"app", Sight.PICKS, sight)
	looks.wear(&"flat")
	var plain: Color = root.theme.palette[&"accent"]
	var refused := made.commands.dispatch(&"app", Sight.PICKS, {"sight": SimulatedSight.DEUTERANOPIA})
	_verdict.check(refused == null and sight.get_sight() == SimulatedSight.DEUTERANOPIA, "the sight is set through the door like any other setting")
	# the sight rings at the frame's end, and the looks follow it there
	await process_frame
	_verdict.check(looks.get_current() == &"flat" and root.theme.palette[&"accent"] != plain, "the look is the one that was picked, dressed for the other eye: %s then %s" % [plain, root.theme.palette[&"accent"]])
	_verdict.check(made.commands.refusal(&"app", Sight.PICKS, {"sight": SimulatedSight.DEUTERANOPIA}) != null, "and the sight already set is refused")
	for node: Node in [sight, looks]:
		root.remove_child(node)
		node.free()
	made.done()
	root.theme = null


## The rule that meaning never rests on hue alone, as a thing that runs: a
## format that gives one value a different kind or a different ground and no
## mark is telling them apart by colour, and is reported.
func _a_format_that_singles_a_value_out_without_marking_it_is_reported() -> void:
	var plain := {"words": "4", "kind": &"Line", "style": &"TableCell", "mark": ""}
	var by_ground := {"words": "9", "kind": &"Line", "style": &"Warned", "mark": ""}
	var by_kind := {"words": "9", "kind": &"Number", "style": &"TableCell", "mark": ""}
	var marked := {"words": "9 !", "kind": &"Number", "style": &"Warned", "mark": " !"}
	_verdict.check(FormatMarks.alike_but_for_hue(by_ground, plain) and FormatMarks.alike_but_for_hue(by_kind, plain), "a different ground, or a different kind of words, under the same mark is two things told apart by hue alone")
	_verdict.check(FormatMarks.alike_but_for_hue(plain, by_ground), "and it has no sides: whichever a table happens to show first")
	_verdict.check(not FormatMarks.alike_but_for_hue(marked, plain) and not FormatMarks.alike_but_for_hue(plain.duplicate(), plain), "the same change carrying a mark is not, nor two dressed alike")
	_verdict.check(not FormatMarks.clashes(1, marked) and not FormatMarks.clashes(1, plain), "a format that marks what it singles out is never reported - even when the marked value is the first it shows")
	_verdict.check(not FormatMarks.clashes(2, plain) and FormatMarks.clashes(2, by_ground) and not FormatMarks.clashes(2, by_ground), "one that does not is reported as the second look is first given, and once")


## The simulator is a developer's instrument: a rect over every place,
## ignoring the mouse, taken away again when the sight is plain.
func _the_simulator_goes_over_everything_and_takes_no_press() -> void:
	var said := SimulatedSight.simulate("deuteranopia", root)
	var laid := SimulatedSight.over(root)
	_verdict.check(laid != null and said.contains("deuteranopia"), "the command lays a rect over the window and says so: %s" % said)
	_verdict.check(laid.mouse_filter == Control.MOUSE_FILTER_IGNORE, "it takes no press: an eye presses nothing")
	_verdict.check(root.get_child(root.get_child_count() - 1) == laid and laid.material is ShaderMaterial and (laid.material as ShaderMaterial).get_shader_parameter(&"red_row") == SimulatedSight.MATRICES[SimulatedSight.DEUTERANOPIA][0], "it is the last child, so it is over every place, carrying that eye's own matrix")
	SimulatedSight.simulate("protanopia", root)
	var one := 0
	# every child of the window, counting the overlays: laying a second one would double the matrix
	for child: Node in root.get_children():
		if child.name == SimulatedSight.OVER:
			one += 1
	_verdict.check(one == 1, "asking for another eye swaps the one rect rather than stacking a second: %s" % one)
	_verdict.check(SimulatedSight.simulate("plain", root) == "seeing plainly" and SimulatedSight.over(root) == null, "the plain sight takes it away again")
	_verdict.check(SimulatedSight.simulate("nonsense", root).begins_with("no such sight"), "a sight nobody has is refused by name")
	await _a_frame_passes()


## The colours a box's painters resolve as it is DRAWN, through the real draw
## path: nothing can be read back out of a canvas item, and a headless run has
## no pixels to look at, so the painters say what they used on the way past.
func _painted(box: StyleBox) -> Array:
	Paint.watched.clear()
	Paint.watching = true
	var canvas := RenderingServer.canvas_item_create()
	box.draw(canvas, Rect2(Vector2.ZERO, Vector2(100.0, 40.0)))
	RenderingServer.free_rid(canvas)
	Paint.watching = false
	return Paint.watched.duplicate()


## The ruling, as a property: what is PAINTED follows the palette the sight
## asks for, because a painter is given a name and reads it as it draws. A
## ring is a flat box with a border rather than a painter, so it is asserted
## where its colour actually lives - in the box, which the sweep turns.
func _an_underline_a_hatch_and_a_ring_wear_the_sight_s_own_palette() -> void:
	var plain: DemoTheme = Looks.make(&"swiss")
	var turned: DemoTheme = Looks.make(&"swiss", SimulatedSight.DEUTERANOPIA)
	var was: Color = plain.palette[&"accent"]
	var now: Color = turned.palette[&"accent"]
	_verdict.check(was != now, "swiss's red is turned at all for an eye without the middle cone: %s then %s" % [was, now])
	var marks: Array = []
	# the same two painters built into each of the two, and drawn
	for look: DemoTheme in [plain, turned]:
		marks.append(_painted(Look.layered(look, [Paint.underline(&"accent", 2.0), Paint.hatch(&"accent")])))
	_verdict.check(marks[0] == [was, was], "an underline and a hatch draw in the palette they were built into: %s" % [marks[0]])
	_verdict.check(marks[1] == [now, now], "and under the turned palette they draw in the turned colour: %s" % [marks[1]])
	# the look's own painter, not one the test built: swiss says which word is live with a red rule
	var live := _painted(turned.get_stylebox(&"current", &"Tab"))
	_verdict.check(live.has(now) and not live.has(was), "swiss's own rule under the current word is drawn in the turned red: %s" % [live])
	var ring := Look.ring(was, {width = 2.0})
	Look.ground(plain, &"Ringed", ring)
	Palettes.rewear(plain, SimulatedSight.DEUTERANOPIA)
	_verdict.check(ring.border_color == now, "and a ring, a flat box with a border, is turned in the box itself: %s" % ring.border_color)


## An ordinary change of look reaches a painter as readily as a palette does:
## the box a control wears comes from whichever theme is on the root, and its
## painters read that theme.
func _an_ordinary_change_of_look_reaches_what_is_painted() -> void:
	root.theme = Looks.make(&"swiss")
	var swiss := _painted(root.get_theme_stylebox(&"current", &"Tab"))
	var was_swiss: Color = (root.theme as DemoTheme).palette[&"accent"]
	root.theme = Looks.make(&"hud")
	var hud := _painted(root.get_theme_stylebox(&"current", &"Tab"))
	var was_hud: Color = (root.theme as DemoTheme).palette[&"accent"]
	_verdict.check(swiss.has(was_swiss) and not swiss.has(was_hud), "under swiss the current word is painted in swiss's accent: %s" % [swiss])
	_verdict.check(hud.has(was_hud) and not hud.has(was_swiss), "and under the HUD in the HUD's: %s" % [hud])
	root.theme = null


## A look is a theme merged from the floor's, so a painted box can arrive in
## one theme having been built into another. Whatever re-colours a theme
## points every box it sweeps at the theme that now holds it, or a painter
## would go on reading the palette it came from.
func _a_box_merged_in_from_another_theme_reads_the_one_that_holds_it() -> void:
	var floor_look := Themes.new(Themes.NEUTRAL)
	var box := Look.layered(floor_look, [Paint.underline(&"accent", 2.0)])
	floor_look.set_stylebox(&"panel", &"Merged", box)
	var look: DemoTheme = Looks.make(&"swiss")
	look.merge_with(floor_look)
	_verdict.check(_painted(look.get_stylebox(&"panel", &"Merged")) == [Themes.NEUTRAL[&"accent"]], "merged in and untouched, the box still reads the theme it was built into")
	Palettes.rewear(look, SimulatedSight.PROTANOPIA)
	var holds: Color = look.get_color(&"accent", Themes.LOOK)
	_verdict.check(_painted(look.get_stylebox(&"panel", &"Merged")) == [holds] and holds != Themes.NEUTRAL[&"accent"], "re-coloured, it reads the theme that holds it now, which no longer says what the floor said: %s" % holds)


## A painter naming a colour its look does not hold would draw in nothing at
## all, which is a silently wrong look: it is said out loud, and drawn in
## magenta so that it shows - once for that name, not on every frame.
func _a_painter_naming_a_colour_the_look_does_not_hold_is_reported() -> void:
	OS.add_logger(_hearing)
	var look: DemoTheme = Looks.make(&"flat")
	var box := Look.layered(look, [Paint.underline(&"marmalade", 2.0)])
	var before := _hearing.refusals
	var drew := _painted(box)
	_verdict.check(_hearing.refusals == before + 1 and drew == [Color.MAGENTA], "a name the look does not hold is reported and drawn in magenta: %s" % [drew])
	_painted(box)
	_verdict.check(_hearing.refusals == before + 1, "and said once, not sixty times a second")
	OS.remove_logger(_hearing)


## The light falling on a surface is not a colour an eye is asked to tell
## apart. Skeuomorphism lights and hollows its bevels in warm tints carrying
## too little hue for any eye's palette to turn, so in every sight they keep
## their exact values - in the palette, and as a bevel draws them. The HUD's
## focus is pure white, which has no hue to turn at all.
func _the_light_falling_on_a_bevel_never_turns_with_the_palette() -> void:
	var plain: DemoTheme = Looks.make(&"skeuomorphic")
	var moved := ""
	var drawn := ""
	# every eye, the plain one among them: each tint as the palette holds it, and a bevel as it is drawn
	for sight: StringName in [Palettes.PLAIN] + DEFICIENCIES:
		var look: DemoTheme = Looks.make(&"skeuomorphic", sight)
		for tint: StringName in [&"sheen", &"hollow", &"sheet_sheen", &"sheet_hollow", &"slate_sheen"]:
			if look.palette[tint] != plain.palette[tint] or look.get_color(tint, Themes.LOOK) != plain.palette[tint]:
				moved += "%s in %s; " % [tint, sight]
		var bevel := _painted(look.get_stylebox(&"panel", Themes.SURFACE))
		if bevel != [plain.palette[&"sheen"], plain.palette[&"hollow"]]:
			drawn += "%s: %s; " % [sight, bevel]
	_verdict.check(moved == "", "every warm tint a bevel is lit or hollowed with keeps its exact value in every sight: %s" % ("all of them" if moved == "" else moved))
	_verdict.check(drawn == "", "and the plain surface's bevel draws in exactly those, whatever the eye: %s" % ("so it does" if drawn == "" else drawn))
	var focus := ""
	# every eye: the HUD's focus brackets on a pressable, and its field's focus underline
	for sight: StringName in [Palettes.PLAIN] + DEFICIENCIES:
		var hud: DemoTheme = Looks.make(&"hud", sight)
		var seen := [_painted(hud.get_stylebox(&"focus", Themes.PRESSABLE)), _painted(hud.get_stylebox(&"focus", &"Field"))]
		if seen != [[Color.WHITE], [Color.WHITE]]:
			focus += "%s: %s; " % [sight, seen]
	_verdict.check(focus == "", "the HUD's focus, brackets and underline alike, is painted pure white in every sight: %s" % ("so it is" if focus == "" else focus))
