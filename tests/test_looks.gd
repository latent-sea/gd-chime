extends SceneTree

## What must be true of a look: the vocabulary a design language is
## written in (look.gd), the layered box it draws with (painted_box.gd),
## and the primitives following a look put on the root while they show.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_looks.gd

const Themes := preload("res://addons/gd_chime/theme.gd")
const Look := preload("res://addons/gd_chime/look.gd")
const Paint := preload("res://addons/gd_chime/paint.gd")
const PaintedBox := preload("res://addons/gd_chime/painted_box.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Fixture := preload("res://tests/fixture.gd")
const Layout := preload("res://addons/gd_chime/components/primitives/layout.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Verdict := preload("res://tests/verdict.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Transition := preload("res://addons/gd_chime/components/primitives/transition.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const Sight := preload("res://demo/gallery/looks/sight.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const PressLocal := preload("res://addons/gd_chime/components/primitives/press_local.gd")
const InlineChoice := preload("res://addons/gd_chime/components/recipes/inline_choice.gd")
const Pressables := preload("res://addons/gd_chime/theme_pressables.gd")

## Every easing a look must name, and the one look whose school asks for a
## duration of nothing: neo-brutalism refuses easing, so its quick is zero
## and what lasts a quick - going, and a change of style - is instant.
const EASINGS: Array[StringName] = [Motion.ENTER, Motion.EXIT, Motion.MOVE, Motion.EMPHASIS, Motion.RESTYLE]
const INSTANT := {&"neo_brutalist": [Motion.EXIT, Motion.RESTYLE]}

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how the vocabulary says no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


func _init() -> void:
	await process_frame
	await _verdict.states(_a_layered_box_draws_its_layers_in_order_at_their_offsets)
	await _verdict.states(_a_type_is_never_made_a_variation_of_itself)
	await _verdict.states(_a_box_takes_named_options_and_reports_one_it_does_not_know)
	await _verdict.states(_rounded_paint_follows_the_corners_and_square_paint_over_a_rounded_box_is_reported)
	await _verdict.states(_a_look_put_on_the_root_re_dresses_what_shows)
	await _verdict.states(_a_ground_with_a_blur_frosts_what_is_behind_it)
	await _verdict.states(_every_look_names_every_duration_and_every_easing)
	await _verdict.states(_reduced_motion_snaps_a_move_under_every_look)
	await _verdict.states(_a_school_that_moves_slowly_really_takes_longer_than_one_that_does_not)
	await _verdict.states(_a_look_put_on_in_a_language_of_another_script_wears_that_script_s_font)
	await _verdict.states(_in_every_look_no_segment_s_box_is_drawn_onto_its_neighbour)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A layered box: the boxes and painters it was given, drawn in order, each
## box at its offset - read back by drawing onto a canvas item and counting
## what each layer did.
func _a_layered_box_draws_its_layers_in_order_at_their_offsets() -> void:
	var drawn: Array = []
	var look := DemoTheme.new()
	var painter := func(_canvas: RID, rect: Rect2, theme: Theme) -> void: drawn.append(["painted", rect.position, theme])
	var box := Look.layered(look, [Look.flat(Color.RED), [Look.flat(Color.BLUE), Vector2(6.0, 6.0)], painter], 4.0)
	var canvas := RenderingServer.canvas_item_create()
	box.draw(canvas, Rect2(Vector2(10.0, 10.0), Vector2(100.0, 40.0)))
	RenderingServer.free_rid(canvas)
	_verdict.check(box is PaintedBox and box.get_content_margin(SIDE_LEFT) == 4.0, "layered gives a painted box with the padding asked")
	_verdict.check(drawn == [["painted", Vector2(10.0, 10.0), look]], "the painter was given the rect and the theme the box was built into: %s" % [drawn])
	var soft := Look.soft(look, Color.WHITE, {light = Color.WHITE, dark = Color.BLACK, radius = 12.0, sunken = true})
	_verdict.check(soft is PaintedBox, "a soft box is layered from the engine's own boxes")


## The helpers guard the one cycle the engine walks forever: a type made
## its own base.
func _a_type_is_never_made_a_variation_of_itself() -> void:
	var theme := Theme.new()
	Look.ground(theme, Themes.SURFACE, Look.flat(Color.RED))
	Look.pressable(theme, Themes.PRESSABLE, {&"normal": Look.flat(Color.RED)}, {&"normal": Color.WHITE}, Look.nothing())
	Look.line(theme, Themes.ROW, Themes.ROW, 8)
	_verdict.check(theme.get_type_variation_base(Themes.SURFACE) == &"" and theme.get_type_variation_base(Themes.PRESSABLE) == &"" and theme.get_type_variation_base(Themes.ROW) == &"", "a surface, a pressable and a row styled as themselves are no variation of themselves")
	Look.ground(theme, &"Raised", Look.flat(Color.RED))
	_verdict.check(theme.get_type_variation_base(&"Raised") == Themes.SURFACE, "and another type is a variation of the base")


## A look put on the root while a screen shows: a row re-reads its gap and
## align, a pressable in a style the new look defines takes it, one in a
## style it does not falls back to the base again, and a surface's frost
## follows the constant - and none of it loops.
func _a_look_put_on_the_root_re_dresses_what_shows() -> void:
	var made := Fixture.new(root, {&"ticks": "tick"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"ticks", model)
	ui.start(ui.app(&"app", [ui.row([ui.pressable(&"ticks", {}, [ui.text("a")], &"Special").named(&"press"), ui.surface(&"Raised", [ui.text("b")]).named(&"ground")], &"Wide").named(&"row")]))
	await _a_frame_passes()
	var row: Layout = ui.node_named(&"row")
	var press: Pressable = ui.node_named(&"press")
	_verdict.check(row.theme_type_variation == Themes.ROW and press.theme_type_variation == Themes.PRESSABLE, "under the placeholder, unknown styles fell back to their bases")
	var look := DemoTheme.new()
	Look.line(look, &"Wide", Themes.ROW, 40)
	Look.pressable(look, &"Special", {&"normal": Look.flat(Color.RED), &"hover": Look.flat(Color.RED), &"inert": Look.flat(Color.RED), &"glowing": Look.flat(Color.RED)}, {&"normal": Color.WHITE, &"hover": Color.WHITE, &"inert": Color.WHITE, &"glowing": Color.WHITE}, Look.nothing())
	root.theme = look
	await _a_frame_passes()
	_verdict.check(row.theme_type_variation == &"Wide" and is_equal_approx(row._gap, 40.0), "a look defining the row's style is read live: gap %s" % [row._gap])
	_verdict.check(press.theme_type_variation == &"Special" and press.get_theme_stylebox(&"normal").bg_color == Color.RED, "and the pressable takes the style the look now defines")
	root.theme = DemoTheme.new()
	await _a_frame_passes()
	_verdict.check(row.theme_type_variation == Themes.ROW and press.theme_type_variation == Themes.PRESSABLE and is_equal_approx(row._gap, 12.0), "the placeholder back, both fall back again")
	model.free()
	made.done()


func _a_ground_with_a_blur_frosts_what_is_behind_it() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var look := DemoTheme.new()
	Look.ground(look, &"Pane", Look.flat(Color(1, 1, 1, 0.2)), 3)
	root.theme = look
	var ground: Surface = ui.build(ui.surface(&"Pane", [ui.text("c")]), root)
	await _a_frame_passes()
	var first: Node = ground.get_child(0)
	_verdict.check(first is ColorRect and (first as ColorRect).material is ShaderMaterial and ((first as ColorRect).material as ShaderMaterial).get_shader_parameter(&"amount") == 3.0, "a blur constant puts a frosting rect first under the content, at that amount")
	root.theme = DemoTheme.new()
	await _a_frame_passes()
	_verdict.check(not (ground.get_child(0) is ColorRect), "no blur in the next look, and the frost is gone")
	ground.free()
	made.done()


## A box is its fill and named options; a name it does not know is said
## out loud, since a misspelt option would be a silently wrong look. A
## line takes the flex layout's own constants.
func _a_box_takes_named_options_and_reports_one_it_does_not_know() -> void:
	OS.add_logger(_hearing)
	var box := Look.flat(Color.RED, {radius = 8, border = 2, border_colour = Color.BLUE, pad = 12})
	_verdict.check(box.corner_radius_top_left == 8 and box.border_width_left == 2 and box.border_color == Color.BLUE and box.get_content_margin(SIDE_TOP) == 12.0 and _hearing.refusals == 0, "a flat box by named options, nothing said")
	var flap := Look.flap(Color.RED, {radius = 6, pad_top = 20})
	_verdict.check(flap.corner_radius_top_left == 6 and flap.corner_radius_bottom_left == 0 and flap.content_margin_top == 20.0, "a flap is rounded at the top alone, padded taller")
	var before := _hearing.refusals
	Look.flat(Color.RED, {raduis = 8})
	Look.ring(Color.RED, {thickness = 3})
	_verdict.check(_hearing.refusals == before + 2, "an option a box does not know is reported out loud, each time")
	var theme := Theme.new()
	Look.line(theme, &"Foot", Themes.ROW, 4, Look.END, Look.CENTER)
	_verdict.check(theme.get_constant(&"justify", &"Foot") == Layout.END and theme.get_constant(&"align", &"Foot") == Layout.CENTER and Look.STRETCH == Layout.STRETCH, "a line takes the flex layout's own constants")
	OS.remove_logger(_hearing)


## A rounded outline reaches into the corners and never past them; the
## gradient and the dashes are drawn over it. Brackets and a hatch draw to
## the square edges, so over a rounded box layered reports them.
func _rounded_paint_follows_the_corners_and_square_paint_over_a_rounded_box_is_reported() -> void:
	OS.add_logger(_hearing)
	var rect := Rect2(Vector2.ZERO, Vector2(100.0, 40.0))
	var round := Paint.outline(rect, 10.0)
	_verdict.check(Paint.outline(rect, 0.0).size() == 4 and round.size() > 4, "no radius is the four corners, a radius an arc at each")
	var inside := true
	for point: Vector2 in round:
		if not rect.grow(0.01).has_point(point) or point.distance_to(Vector2.ZERO) < 2.0:
			inside = false
	_verdict.check(inside, "every point of a rounded outline is inside the rect and off its square corner")
	var before := _hearing.refusals
	var into := DemoTheme.new()
	Look.layered(into, [Look.flat(Color.RED, {radius = 10}), Paint.gradient(&"ink", &"ground", 10.0), Paint.dashed(&"ink", 1.0, 8.0, 6.0, 0.0, 10.0)])
	_verdict.check(_hearing.refusals == before, "a rounded gradient and rounded dashes over a rounded box are what was asked")
	Look.layered(into, [Look.flat(Color.RED, {radius = 10}), Paint.brackets(&"ink", 1.0)])
	Look.layered(into, [Look.flat(Color.RED, {radius = 10}), Paint.hatch(&"ink")])
	_verdict.check(_hearing.refusals == before + 2, "brackets and a hatch over a rounded box are reported")
	Look.layered(into, [Look.flat(Color.RED), Paint.brackets(&"ink", 1.0)])
	_verdict.check(_hearing.refusals == before + 2, "and over a square box they are not")
	OS.remove_logger(_hearing)


## A look says how it moves as well as how it draws, and says all of it: the
## three durations, the stagger, an easing named for each of the five things
## that move, and the transition a swap arrives and goes by. Nothing lasts no
## time at all unless the school it is written in asks for that, and the one
## that does is named here.
func _every_look_names_every_duration_and_every_easing() -> void:
	var missing := ""
	var instant := ""
	# every look the gallery has, the placeholder among them
	for named: StringName in Looks.NAMES:
		var look: Theme = Looks.make(named)
		for duration: StringName in Motion.DURATIONS + [Motion.STAGGER]:
			if not look.has_constant(duration, Motion.TYPE):
				missing += "%s: %s; " % [named, duration]
		# every easing: its curve, its ease, and which of the durations it lasts
		for easing: StringName in EASINGS:
			for part: String in ["_curve", "_ease", "_lasts"]:
				if not look.has_constant(StringName(easing + part), Motion.TYPE):
					missing += "%s: %s%s; " % [named, easing, part]
			var which: int = look.get_constant(StringName(easing + "_lasts"), Motion.TYPE)
			var lasts: int = look.get_constant(Motion.DURATIONS[which], Motion.TYPE)
			var allowed: Array = INSTANT.get(named, [])
			if lasts <= 0 and not allowed.has(easing):
				instant += "%s: %s; " % [named, easing]
			if lasts > 0 and allowed.has(easing):
				instant += "%s: %s lasts %s and was meant to be instant; " % [named, easing, lasts]
		for swaps: StringName in [&"when", &"each"]:
			if not look.has_constant(swaps, Motion.TYPE):
				missing += "%s: %s; " % [named, swaps]
	_verdict.check(missing == "", "every look names every duration, every easing and what a swap does: %s" % ("all of them" if missing == "" else missing))
	_verdict.check(instant == "", "and nothing lasts no time at all but what its school asks to be instant: %s" % ("nothing else" if instant == "" else instant))


## Reduced motion is the floor's, not the look's: however slow and however
## curved a school says a move is, while it is on the move is over at once.
func _reduced_motion_snaps_a_move_under_every_look() -> void:
	var made := Fixture.new(root)
	var motion := made.ui.motion
	motion.still = false
	motion.by_hand = true
	motion.told(Motion.REDUCES, {"on": true})
	var moved := Control.new()
	root.add_child(moved)
	var still_going := ""
	# every look, a move begun under it and asked whether it is already over
	for named: StringName in Looks.NAMES:
		root.theme = Looks.make(named)
		var run: Motion.Run = motion.drive(moved, &"turn", 0.0, 1.0, Motion.MOVE, moved.set_rotation)
		if not run.is_over() or not is_equal_approx(moved.rotation, 1.0):
			still_going += "%s; " % named
		moved.rotation = 0.0
	_verdict.check(still_going == "", "a move snaps to its end under every look while motion is reduced: %s" % ("every one" if still_going == "" else still_going))
	motion.told(Motion.REDUCES, {"on": false})
	moved.free()
	made.done()
	root.theme = null


## Two schools that say different things about motion really do move
## differently: material lets a thing settle over a quarter of a second, and
## the dense table is done in a thirtieth, so a tenth of a second finds one
## still going and the other long since arrived.
func _a_school_that_moves_slowly_really_takes_longer_than_one_that_does_not() -> void:
	var made := Fixture.new(root)
	var motion := made.ui.motion
	motion.still = false
	motion.by_hand = true
	var slow := Control.new()
	var quick := Control.new()
	for node: Control in [slow, quick]:
		root.add_child(node)
	root.theme = Looks.make(&"material")
	var settling: Motion.Run = motion.drive(slow, &"turn", 0.0, 1.0, Motion.ENTER, slow.set_rotation)
	root.theme = Looks.make(&"data_dense")
	var snapping: Motion.Run = motion.drive(quick, &"turn", 0.0, 1.0, Motion.ENTER, quick.set_rotation)
	_verdict.check(settling.lasts > snapping.lasts, "an arrival under material lasts longer than one under the dense table: %s against %s" % [settling.lasts, snapping.lasts])
	motion.step(0.1)
	_verdict.check(not settling.is_over() and slow.rotation < 1.0, "a tenth of a second in, the material one is still settling: %s" % slow.rotation)
	_verdict.check(snapping.is_over() and is_equal_approx(quick.rotation, 1.0), "and the dense one arrived")
	for node: Control in [slow, quick]:
		node.free()
	made.done()
	root.theme = null


## The gallery's looks put a look on dressed for the language on: in a
## language written in another script, the look put on wears the font it
## gives that script, not the one it gives Latin.
func _a_look_put_on_in_a_language_of_another_script_wears_that_script_s_font() -> void:
	var made := Fixture.new(root)
	var sight := Sight.new(made.chimes)
	var looks := Looks.new(made.chimes, root, sight)
	made.commands.stand(&"app", sight)
	made.commands.stand(&"app", looks)
	var latin := SystemFont.new()
	latin.font_names = PackedStringArray(["Arial"])
	var japanese := SystemFont.new()
	japanese.font_names = PackedStringArray(["Yu Gothic"])
	var look := DemoTheme.new()
	Look.fonts(look, {Look.LATIN: latin, "Jpan": japanese})
	var ja := Translation.new()
	ja.locale = "ja"
	ja.add_message(Look.LATIN, "Jpan", Language.SCRIPT)
	TranslationServer.add_translation(ja)
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": &"ja"})
	looks.put_on(look)
	_verdict.check(root.theme == look and look.default_font == japanese, "in Japanese, the look put on wears its font for Japanese: %s" % [look.default_font.get_font_name() if look.default_font != null else null])
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	TranslationServer.remove_translation(ja)
	for model: Node in [looks, sight]:
		model.free()
	made.done()
	root.theme = null


## A segmented control - a row of joined options - in every look: between
## two segments as they stand there is at least what the one before draws
## past its right side and the one after past its left, in whichever state
## the look dresses a segment, plain or chosen - so no segment's shadow lies
## under its neighbour, which would be one thing drawn over another. A look
## whose segments draw nothing past their sides keeps them joined.
func _in_every_look_no_segment_s_box_is_drawn_onto_its_neighbour() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var shown := ui.local(2)
	var holder := Fixture.Model.new(made.chimes, &"app")
	holder.set_value(&"items", [{"value": 1, "words": "small"}, {"value": 2, "words": "medium"}, {"value": 3, "words": "large"}])
	ui.start(ui.app(&"app", [ui.row([InlineChoice.segments(ui, shown, holder.of(&"items")).named(&"segments")])]))
	var onto := ""
	var joined := ""
	# every look the gallery has, the segments placed under it and measured against what their boxes draw past their sides
	for named: StringName in Looks.NAMES:
		root.theme = Looks.make(named)
		await _a_frame_passes()
		var look: Theme = root.theme
		var reach := [0.0, 0.0]
		# every box a segment is dressed in, plain or chosen, in every state, for the furthest it draws past its left and its right
		for type: StringName in [Pressables.SEGMENT, Pressables.SEGMENT_CHOSEN]:
			for state: String in look.get_stylebox_list(type):
				reach = [maxf(reach[0], PaintedBox.reach_of(look.get_stylebox(state, type), SIDE_LEFT)), maxf(reach[1], PaintedBox.reach_of(look.get_stylebox(state, type), SIDE_RIGHT))]
		var segments: Array = ui.node_named(&"segments").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is PressLocal)
		# every segment after the first, against the one before it
		for at: int in range(1, segments.size()):
			var between: float = segments[at].get_global_rect().position.x - segments[at - 1].get_global_rect().end.x
			if between < reach[0] + reach[1] - 0.5:
				onto += "%s: %s apart, drawing %s right and %s left; " % [named, between, reach[1], reach[0]]
			if reach[0] + reach[1] == 0.0 and absf(between) > 0.5:
				joined += "%s: %s apart; " % [named, between]
	_verdict.check(onto == "", "in every look no segment's box is drawn onto its neighbour: %s" % ("none is" if onto == "" else onto))
	_verdict.check(joined == "", "and a look whose segments draw nothing past their sides keeps them joined: %s" % ("every one" if joined == "" else joined))
	holder.free()
	made.done()
	root.theme = null
