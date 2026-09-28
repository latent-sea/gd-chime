extends SceneTree

## What must be true of the content, layout and special primitives, each
## on its own: text - graded where its kind names a gradient - image,
## surface - its ground moving on the clock where its style says - field, row, column, grid, stack,
## scroll, view, canvas and anchored.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_primitives.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Picture := preload("res://addons/gd_chime/components/primitives/image.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Field := preload("res://addons/gd_chime/components/primitives/field.gd")
const Layout := preload("res://addons/gd_chime/components/primitives/layout.gd")
const GridLayout := preload("res://addons/gd_chime/components/primitives/grid_layout.gd")
const Stack := preload("res://addons/gd_chime/components/primitives/stack.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const View := preload("res://addons/gd_chime/components/primitives/view.gd")
const Canvas := preload("res://addons/gd_chime/components/primitives/canvas.gd")
const Anchored := preload("res://addons/gd_chime/components/primitives/anchored.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Look := preload("res://addons/gd_chime/look.gd")
const GradedWords := preload("res://addons/gd_chime/components/primitives/graded_words.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_text_shows_a_string_or_a_bound_value_in_its_style_and_hides_while_empty_if_asked)
	await _verdict.states(_words_of_a_kind_named_a_gradient_are_graded_across_themselves_but_never_on_a_press)
	await _verdict.states(_image_shows_a_texture_or_a_bound_one)
	await _verdict.states(_surface_draws_its_style_s_panel_under_its_content)
	await _verdict.states(_a_ground_that_moves_is_drawn_again_as_the_clock_moves_and_only_then)
	await _verdict.states(_field_dispatches_the_line_typed_and_clears_it_when_done)
	await _verdict.states(_a_text_works_its_reach_out_once_and_again_only_as_its_look_or_kind_of_words_changes)
	await _verdict.states(_a_field_shows_why_a_line_was_refused_under_it_until_one_is_not)
	await _verdict.states(_a_field_given_carries_dispatches_it_on_every_change_and_one_given_a_local_keeps_its_refusal_there)
	await _verdict.states(_row_column_and_grid_lay_their_parts_out_with_the_look_s_gaps)
	await _verdict.states(_stack_scroll_view_canvas_and_anchored_hold_and_place_their_content)
	await _verdict.states(_a_line_takes_no_press_so_one_laid_over_a_pressable_lets_the_press_through)
	await _verdict.states(_words_that_wrap_in_a_screen_not_yet_shown_need_the_lines_they_will_take)
	await _verdict.states(_every_holder_places_a_piece_as_its_motion_has_left_it)
	await _verdict.states(_a_stack_needs_the_room_of_its_largest_piece_whichever_is_shown)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A plain control of this size under the root, for a primitive to fill.
func _host(of: Vector2) -> Control:
	var host := Control.new()
	host.size = of
	root.add_child(host)
	return host


func _text_shows_a_string_or_a_bound_value_in_its_style_and_hides_while_empty_if_asked() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "")
	var plain: Text = ui.build(ui.text("hello", Themes.WORDS), root)
	var bound: Text = ui.build(ui.text(model.of(&"words"), &"").hides_empty(), root)
	await _a_frame_passes()
	_verdict.check(plain.get_text() == "hello" and (plain.get_child(0) as Label).theme_type_variation == Themes.WORDS, "a string is shown in its style: %s" % plain.get_text())
	_verdict.check(not bound.visible, "a bound value that is empty, asked to hide, is hidden")
	model.set_value(&"words", "now")
	await _a_frame_passes()
	_verdict.check(bound.visible and bound.get_text() == "now", "the bell rung, it re-reads and shows: %s" % bound.get_text())
	plain.free()
	bound.free()
	model.free()
	made.done()


## Title given two colours by the look: a title's words graded between
## them across the words' own width, well short of its line's, and graded
## again as the words change; words of a kind with none drawn plainly; and a
## title on a press in the press's one ink.
func _words_of_a_kind_named_a_gradient_are_graded_across_themselves_but_never_on_a_press() -> void:
	root.theme.set_color(GradedWords.FROM, Themes.TITLE, Color.CYAN)
	root.theme.set_color(GradedWords.TO, Themes.TITLE, Color.VIOLET)
	var made := Fixture.new(root, {&"opens": "open"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	root.add_child(model)
	made.commands.register(Chimes.GLOBAL, &"opens", model)
	model.set_value(&"words", "short")
	var title := ui.text(model.of(&"words"), Themes.TITLE).named(&"title")
	var plain := ui.text("plain words", Themes.WORDS).named(&"plain")
	var pressed := ui.pressable(&"opens", {}, [ui.text("a titled press", Themes.TITLE).named(&"on a press")])
	ui.start(ui.app(&"app", [ui.column([title, plain, pressed])]))
	await _a_frame_passes()
	var label: Label = ui.node_named(&"title").get_child(0)
	var graded := label.material as ShaderMaterial
	var span := GradedWords.spanned(label)
	_verdict.check(graded != null and graded.get_shader_parameter(&"from_colour") == Color.CYAN and graded.get_shader_parameter(&"to_colour") == Color.VIOLET, "a title's words are graded between the two colours its kind is given: %s" % [graded])
	_verdict.check(span.y - span.x > 0.0 and span.y - span.x < label.size.x / 2.0 and graded.get_shader_parameter(&"start") == span.x and graded.get_shader_parameter(&"width") == span.y - span.x, "across the words' own width, well short of the line's: %s of %s" % [span, label.size.x])
	model.set_value(&"words", "a good deal longer than it was")
	await _a_frame_passes()
	var longer := GradedWords.spanned(label)
	_verdict.check(longer.y - longer.x > span.y - span.x and graded.get_shader_parameter(&"width") == longer.y - longer.x, "the words changed, the gradient spans them as they are now: %s" % [longer])
	_verdict.check((ui.node_named(&"plain").get_child(0) as Label).material == null, "words of a kind with no gradient are drawn plainly")
	var on_press: Label = ui.node_named(&"on a press").get_child(0)
	_verdict.check(on_press.material == null and on_press.has_theme_color_override(&"font_color"), "and a title on a press is in the press's own ink, never graded")
	root.theme.clear_color(GradedWords.FROM, Themes.TITLE)
	root.theme.clear_color(GradedWords.TO, Themes.TITLE)
	model.free()
	made.done()


func _image_shows_a_texture_or_a_bound_one() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	var one := PlaceholderTexture2D.new()
	var two := PlaceholderTexture2D.new()
	model.set_value(&"words", one)
	var picture: Picture = ui.build(ui.image(model.of(&"words")), root)
	await _a_frame_passes()
	_verdict.check(picture.get_texture() == one, "a bound texture is shown")
	model.set_value(&"words", two)
	await _a_frame_passes()
	_verdict.check(picture.get_texture() == two, "and re-read on its bell")
	picture.free()
	model.free()
	made.done()


func _surface_draws_its_style_s_panel_under_its_content() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var surface: Surface = ui.build(ui.surface(Themes.SURFACE, [ui.text("on it")]), root)
	await _a_frame_passes()
	_verdict.check(surface.get_theme_stylebox(&"panel") == root.theme.get_stylebox(&"panel", Themes.SURFACE) and surface.get_child(0) is Text, "it asks the look for its style's panel and holds its content")
	_verdict.check(surface.mouse_filter == Control.MOUSE_FILTER_IGNORE, "and takes no press")
	_verdict.check(not surface.is_processing(), "its ground never moving, it never looks at the clock")
	surface.free()
	made.done()


## A panel that draws drifting light, as a look's would: the clock's time
## it was handed each time it was drawn.
class Drifting extends StyleBox:
	var time: float = -1.0
	var drawn: Array[float] = []

	func _draw(_to: RID, _rect: Rect2) -> void:
		drawn.append(time)


## A budget over whatever the frame took, standing in for a slow machine.
class Overrun extends FrameBudget:
	func is_over() -> bool:
		return true


## A ground whose style moves, the clock stepped by hand: drawn again at
## each step's time and never while the clock stands still; not while
## motion is reduced, while the frame is over budget, or while it is hidden.
func _a_ground_that_moves_is_drawn_again_as_the_clock_moves_and_only_then() -> void:
	var drifting := Drifting.new()
	root.theme.set_type_variation(&"Drifting", Themes.SURFACE)
	root.theme.set_stylebox(&"panel", &"Drifting", drifting)
	root.theme.set_constant(&"moves", &"Drifting", 1)
	var made := Fixture.new(root)
	var ui := made.ui
	ui.start(ui.app(&"app", [ui.column([ui.surface(&"Drifting").named(&"ground").grow(), ui.surface(Themes.SURFACE).named(&"still")])]))
	ui.motion.by_hand = true
	await _a_frame_passes()
	_verdict.check(not (ui.node_named(&"still") as Node).is_processing() and (ui.node_named(&"ground") as Node).is_processing(), "a ground that never moves never looks at the clock; one that moves does")
	var standing := drifting.drawn.size()
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(standing > 0 and drifting.drawn.size() == standing, "the clock standing still, it is not drawn again frame by frame: %d then %d" % [standing, drifting.drawn.size()])
	var from := ui.motion.time
	ui.motion.step(0.25)
	await _a_frame_passes()
	ui.motion.step(0.25)
	await _a_frame_passes()
	_verdict.check(drifting.drawn.slice(standing) == [from + 0.25, from + 0.5], "stepped twice, it is drawn at each step's time: %s" % [drifting.drawn.slice(standing)])
	var held := drifting.drawn.size()
	ui.motion.told(&"reduces_motion", {"on": true})
	ui.motion.step(0.25)
	await _a_frame_passes()
	ui.motion.told(&"reduces_motion", {"on": false})
	var overrun := Overrun.new(made.chimes, 16.0, 0.5, 3)
	root.add_child(overrun)
	ui.motion.budget = overrun
	ui.motion.step(0.25)
	await _a_frame_passes()
	ui.motion.budget = null
	overrun.free()
	(ui.node_named(&"ground") as Control).visible = false
	ui.motion.step(0.25)
	await _a_frame_passes()
	_verdict.check(drifting.drawn.size() == held, "reduced, over budget, or hidden, the clock moving draws it no more: %s" % [drifting.drawn.slice(held)])
	made.done()
	root.theme.clear_type_variation(&"Drifting")
	root.theme.clear_stylebox(&"panel", &"Drifting")
	root.theme.clear_constant(&"moves", &"Drifting")


func _field_dispatches_the_line_typed_and_clears_it_when_done() -> void:
	var made := Fixture.new(root, {&"runs": "run"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	made.commands.register(Chimes.GLOBAL, &"runs", model)
	var field: Field = ui.build(ui.field(&"runs").takes_focus(), root)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == field.get_child(0), "built to take the focus, its line has it")
	(field.get_child(0) as LineEdit).text = "give 5"
	(field.get_child(0) as LineEdit).text_submitted.emit("give 5")
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"runs"] and made.commands.get_last()["payload"] == {"line": "give 5"} and field.get_line() == "", "Enter dispatches the action with the line, and the line is cleared once done")
	model.refuse(&"runs", Phrase.of("no"))
	(field.get_child(0) as LineEdit).text = "again"
	(field.get_child(0) as LineEdit).text_submitted.emit("again")
	_verdict.check(field.get_line() == "again", "a refused line is kept")
	field.free()
	model.free()
	made.done()


## A look whose Boxed words are set in a box casting this far, moved 4 up,
## whose Bare words are set in none, and which has a font for one script.
func _boxed_words(cast: int) -> Theme:
	var look := Theme.new()
	var box := StyleBoxFlat.new()
	box.shadow_size = cast
	box.shadow_offset = Vector2(0.0, -4.0)
	box.shadow_color = Color.WHITE
	look.set_type_variation(&"Boxed", &"Label")
	look.set_stylebox(&"normal", &"Boxed", box)
	look.set_type_variation(&"Bare", &"Label")
	look.set_stylebox(&"normal", &"Bare", StyleBoxEmpty.new())
	look.set_font(&"Cyrl", Look.FONTS, FontVariation.new())
	return look


## Words in a box casting its light 12 up, under other words in a column:
## the line leaves them the 12, from the reach the text worked out once.
## Its words changing, nothing is worked out again; another look on the
## root, another kind of words, and the look dressed for another script's
## font each have it worked out again, and the line follows the first two.
func _a_text_works_its_reach_out_once_and_again_only_as_its_look_or_kind_of_words_changes() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "first words")
	model.set_value(&"flag", &"Boxed")
	var before: Theme = root.theme
	root.theme = _boxed_words(8)
	var host := _host(Vector2(300, 300))
	var column: Layout = ui.build(ui.column([ui.text("over them"), ui.text(model.of(&"words"), model.of(&"flag"))]), host)
	var over: Text = column.get_child(0)
	var text: Text = column.get_child(1)
	await _a_frame_passes()
	var room := func() -> float: return text.position.y - over.get_rect().end.y
	var worked := text.reach_count
	_verdict.check(is_equal_approx(text.get_reach(SIDE_TOP), 12.0) and is_equal_approx(room.call(), 12.0) and worked >= 1, "words in a box casting 12 up answer that reach, and the line leaves it over them: %s, %s" % [text.get_reach(SIDE_TOP), room.call()])
	model.set_value(&"words", "other words altogether")
	await _a_frame_passes()
	_verdict.check(text.get_text() == "other words altogether" and text.reach_count == worked, "its words changing, the reach is kept and nothing is worked out again: %d more" % (text.reach_count - worked))
	root.theme = _boxed_words(16)
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(text.reach_count == worked + 1 and is_equal_approx(room.call(), 20.0), "another look on the root, it is worked out again and the line leaves the 20 it casts now: %s" % room.call())
	model.set_value(&"flag", &"Bare")
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(text.reach_count == worked + 2 and is_equal_approx(room.call(), 0.0), "words of another kind, in no box, it is worked out again and the line takes the room back: %s" % room.call())
	Look.dress(root.theme, "Cyrl")
	await _a_frame_passes()
	text.get_reach(SIDE_TOP)
	_verdict.check(text.reach_count == worked + 3, "the look dressed in another script's font, it is worked out again: %d" % (text.reach_count - worked))
	root.theme = before
	host.free()
	model.free()
	made.done()


## A model holding the line it is told, as a form's answer does.
class Holder extends Fixture.Model:
	var payloads: Array = []

	func told(action: StringName, payload: Dictionary) -> Phrase:
		payloads.append(payload)
		if payload.has("line"):
			set_value(&"words", payload["line"])
		return super.told(action, payload)


func _a_field_shows_why_a_line_was_refused_under_it_until_one_is_not() -> void:
	var made := Fixture.new(root, {&"runs": "run", &"types": "type", &"leaves": "leave"})
	var ui := made.ui
	var model := Holder.new(made.chimes)
	model.set_value(&"words", "")
	# the field's three actions, answered by the one model
	for action: StringName in [&"runs", &"types", &"leaves"]:
		made.commands.register(Chimes.GLOBAL, action, model)
	var host := _host(Vector2(300, 200))
	var field: Field = ui.build(ui.column([ui.field(&"runs", &"", {"changes": &"types", "shows": model.of(&"words"), "leaves": &"leaves"})]), host).get_child(0)
	var line: LineEdit = field.get_child(0)
	var said: Text = field.get_child(1)
	await _a_frame_passes()
	var rest := field.size.y
	_verdict.check(not said.visible and is_equal_approx(line.size.y, rest), "nothing refused, its reason takes no room and the line is the whole field: %s of %s" % [line.size.y, rest])
	model.refuse(&"runs", Phrase.of("no crate is called that"))
	line.text_submitted.emit("figs")
	await _a_frame_passes()
	_verdict.check(said.visible and said.get_text() == "no crate is called that" and said.position.y >= line.position.y + line.size.y and field.size.y > rest, "a refused Enter says why under the line, and the field grows to hold it: %s at %s under a line ending at %s" % [said.get_text(), said.position.y, line.position.y + line.size.y])
	model.refuse(&"runs", null)
	model.refuse(&"types", Phrase.of("only letters"))
	line.text_changed.emit("fig5")
	await _a_frame_passes()
	_verdict.check(said.get_text() == "only letters", "a refused change says why too: %s" % said.get_text())
	model.refuse(&"types", null)
	line.text_changed.emit("figs")
	await _a_frame_passes()
	_verdict.check(not said.visible and is_equal_approx(field.size.y, rest), "the next dispatch done, the reason goes and so does its room: %s" % field.size.y)
	# a model holding every keystroke: the line it holds already is not written back over the caret
	line.text = "plums"
	line.caret_column = 2
	line.text_changed.emit("plums")
	await _a_frame_passes()
	_verdict.check(model.of(&"words").read() == "plums" and line.caret_column == 2, "the model holding the line as typed, the line is left alone and the caret stays: at %d" % line.caret_column)
	line.grab_focus()
	line.release_focus()
	_verdict.check(model.told_actions.has(&"leaves") and model.payloads[-1] == {"line": "plums"}, "the focus leaving the line dispatches the leaving action with the line: %s" % [model.payloads[-1]])
	host.free()
	model.free()
	made.done()


func _a_field_given_carries_dispatches_it_on_every_change_and_one_given_a_local_keeps_its_refusal_there() -> void:
	var made := Fixture.new(root, {&"runs": "run", &"types": "type"})
	var ui := made.ui
	var model := Holder.new(made.chimes)
	made.commands.register(Chimes.GLOBAL, &"runs", model)
	made.commands.register(Chimes.GLOBAL, &"types", model)
	var refused := ui.local(null)
	var carries := func(line: String) -> Dictionary: return {"value": line.to_int(), "words": line}
	var field: Field = ui.build(ui.field(&"runs", &"", {"changes": &"types", "carries": carries, "refused": refused}), root)
	await _a_frame_passes()
	(field.get_child(0) as LineEdit).text_changed.emit("12")
	_verdict.check(model.payloads[-1] == {"value": 12, "words": "12"}, "a change carries what Enter would: %s" % [model.payloads[-1]])
	model.refuse(&"runs", Phrase.of("too many"))
	(field.get_child(0) as LineEdit).text_submitted.emit("12")
	_verdict.check(field.get_child_count() == 1 and str(refused.read()) == "too many", "given a local, the refusal is kept in it and nothing stands under the line: %s" % [refused.read()])
	field.free()
	_verdict.check(refused.read() == null, "the field gone, its refusal goes from the local with it")
	model.free()
	made.done()


func _row_column_and_grid_lay_their_parts_out_with_the_look_s_gaps() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var row: Layout = ui.build(ui.row([ui.surface(Themes.SURFACE).grow(), ui.surface(Themes.SURFACE).grow()]), _host(Vector2(400, 100)))
	var column: Layout = ui.build(ui.column([ui.surface(Themes.SURFACE).basis(0.25), ui.surface(Themes.SURFACE).grow()]), _host(Vector2(100, 400)))
	var grid: GridLayout = ui.build(ui.grid([ui.surface(Themes.SURFACE), ui.surface(Themes.SURFACE), ui.surface(Themes.SURFACE).span(2)], [0.5, 0.5]), _host(Vector2(400, 200)))
	await _a_frame_passes()
	var gap: float = root.theme.get_constant(&"gap", Themes.ROW)
	var a: Control = row.get_child(0)
	var b: Control = row.get_child(1)
	_verdict.check(a.size.x == (400.0 - gap) / 2.0 and b.position.x == a.size.x + gap, "a row shares its width between two parts growing alike, the look's gap between them: %s %s" % [a.size, b.position])
	var top: Control = column.get_child(0)
	_verdict.check(top.size.y == 100.0 and (column.get_child(1) as Control).position.y == 100.0 + gap, "a column gives a part its basis, a share of the height, and the rest to the one that grows: %s" % [top.size])
	var cells := grid.get_children()
	_verdict.check((cells[0] as Control).size.x == (cells[1] as Control).size.x and (cells[2] as Control).size.x == 400.0 and (cells[2] as Control).position.y > 0.0, "a grid of two shares lays two parts on a row and one spanning both beneath: %s" % [(cells[2] as Control).size])
	row.get_parent().free()
	column.get_parent().free()
	grid.get_parent().free()
	made.done()


func _stack_scroll_view_canvas_and_anchored_hold_and_place_their_content() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var painted: Array = []
	var stack: Stack = ui.build(ui.stack([ui.surface(Themes.SURFACE).named(&"under"), ui.canvas(func(_control: Control, value: Variant) -> void: painted.append(value), 7)]), _host(Vector2(200, 200)))
	var scroll: Scroll = ui.build(ui.scroll(ui.column([ui.text("a"), ui.text("b")])), root)
	var view: View = ui.build(ui.view([ui.text("inside")]), root)
	var over: Anchored = ui.build(ui.anchored(&"under", [ui.text("bubble")]), root)
	await _a_frame_passes()
	_verdict.check(stack.get_child_count() == 2 and (stack.get_child(0) as Control).size == stack.size and (stack.get_child(1) as Control).size == stack.size, "a stack holds its pieces each across the whole of it")
	_verdict.check(painted == [7], "a canvas painted once with its value: %s" % [painted])
	_verdict.check(scroll.get_child(0) is Layout, "a scroll holds its one piece")
	_verdict.check(view.viewport.get_child(0) is Text, "a view holds its content inside its viewport")
	var under: Control = ui.node_named(&"under")
	_verdict.check(is_equal_approx(over.get_global_rect().end.y, under.global_position.y) and over.size.x == under.size.x, "an anchored piece sits just above the control it is attached to, as wide as it: %s %s" % [over.get_global_rect(), under.get_global_rect()])
	stack.get_parent().free()
	scroll.free()
	view.free()
	over.free()
	made.done()


## A row or a column takes no press - what it holds does - so a column and
## its row laid over a pressable, in a stack, let a press through to it.
func _a_line_takes_no_press_so_one_laid_over_a_pressable_lets_the_press_through() -> void:
	var made := Fixture.new(root, {&"ticks": "tick"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"ticks", model)
	ui.start(ui.app(&"app", [ui.stack([ui.pressable(&"ticks", {}, [ui.text("beneath")]), ui.column([ui.row([ui.text("")]).grow()])])]))
	await _a_frame_passes()
	_click(Vector2(200, 200))
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"ticks"], "a press where a column and its row lie over the pressable reaches the pressable: %s" % [model.told_actions])
	model.free()
	made.done()


## Words that wrap, on a screen not yet shown, need the lines they take at
## the width they are given - never what they needed at no width, a letter
## to a line, which the stack of screens counts and a page outgrows its
## window by.
func _words_that_wrap_in_a_screen_not_yet_shown_need_the_lines_they_will_take() -> void:
	root.size = Vector2i(286, 800)
	var made := Fixture.new(root)
	var ui := made.ui
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"one", [ui.column([ui.text("shown")])]), ui.screen(&"two", [ui.column([ui.text("not in the market phase", &"").wraps().named(&"wrapped")])])])]))
	await _a_frame_passes()
	var two: Control = made.driver.index.place_named(&"two")
	# read before anything asks the label: asking it anything measures it again, which is the very thing looked for
	var hidden: float = (two.get_parent() as Control).get_combined_minimum_size().y
	var line: float = ((ui.node_named(&"wrapped") as Text).get_child(0) as Label).get_line_height()
	_verdict.check(not two.is_visible_in_tree() and hidden < 2.0 * line, "the second screen never shown, the stack of screens needs the one line its words take at 286 across, not a letter to a line: %s for a line of %s" % [hidden, line])
	made.done()
	root.size = Vector2i(400, 400)
	var tall := Fixture.new(root)
	var words: Text = tall.ui.build(tall.ui.stack([tall.ui.text("pear").wraps()]), _host(Vector2(200, 120))).get_child(0)
	await _a_frame_passes()
	var label: Label = words.get_child(0)
	_verdict.check(label.position == Vector2.ZERO and label.size == words.size, "and words given more room than they need are drawn across the whole of it, from its top - never moved to its middle: %s %s" % [label.position, label.size])
	words.get_parent().get_parent().free()
	tall.done()


## Whatever holds a piece places it at the scale and the turn its motion
## has reached: a sheet scaling in, placed again mid-way, is never drawn
## whole for a frame and then small again.
func _every_holder_places_a_piece_as_its_motion_has_left_it() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"flag", true)
	var holders: Dictionary = {
		&"in_row": ui.row([ui.surface(Themes.SURFACE).named(&"in_row")]),
		&"in_column": ui.column([ui.surface(Themes.SURFACE).named(&"in_column")]),
		&"in_stack": ui.stack([ui.surface(Themes.SURFACE).named(&"in_stack")]),
		&"in_surface": ui.surface(Themes.SURFACE, [ui.surface(Themes.SURFACE).named(&"in_surface")]),
		&"in_when": ui.when(model.of(&"flag"), ui.surface(Themes.SURFACE).named(&"in_when")),
	}
	var built: Array[Control] = []
	# every holder built in a room of its own
	for piece: StringName in holders:
		built.append(ui.build(holders[piece], _host(Vector2(200, 200))))
	await _a_frame_passes()
	# every piece part way through its motion, and its holder placing it again
	for at: int in built.size():
		var piece: Control = ui.node_named(holders.keys()[at])
		piece.scale = Vector2(0.5, 0.5)
		piece.rotation = 0.25
		built[at].queue_sort()
	await _a_frame_passes()
	# every piece, for the scale and turn it was left at
	for piece: StringName in holders:
		var held: Control = ui.node_named(piece)
		_verdict.check(held.scale == Vector2(0.5, 0.5) and is_equal_approx(held.rotation, 0.25), "%s: placed again, the piece keeps the scale and turn it had reached: %s %s" % [piece, held.scale, held.rotation])
	# every holder's room freed
	for holder: Control in built:
		holder.get_parent().free()
	model.free()
	made.done()


## A stack of two screens, a short one showing and a tall one not: the
## stack needs the tall one's room, shown or not, and the same again once
## the tall one is shown - so the frame around a stack of screens never
## jumps as they swap.
func _a_stack_needs_the_room_of_its_largest_piece_whichever_is_shown() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var lines: Array = []
	# twenty lines of words, for a screen taller than the other
	for line: int in 20:
		lines.append(ui.text("line %d" % line))
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"short", [ui.column([ui.text("one line")])]), ui.screen(&"tall", [ui.column(lines)])])]))
	await _a_frame_passes()
	var short: Control = made.driver.index.place_named(&"short")
	var tall: Control = made.driver.index.place_named(&"tall")
	var stack: Control = short.get_parent()
	var needs: Vector2 = stack.get_combined_minimum_size()
	_verdict.check(short.visible and not tall.visible and is_equal_approx(needs.y, tall.get_combined_minimum_size().y) and needs.y > 5.0 * short.get_combined_minimum_size().y, "the tall screen hidden, the stack still needs its room: %s, the short %s, the tall %s" % [needs.y, short.get_combined_minimum_size().y, tall.get_combined_minimum_size().y])
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"tall"})
	await _a_frame_passes()
	made.ui.motion.step(10.0)
	await _a_frame_passes()
	_verdict.check(tall.visible and not short.visible and stack.get_combined_minimum_size() == needs, "the screens swapped, the stack needs exactly what it did: %s, before %s" % [stack.get_combined_minimum_size(), needs])
	made.done()


func _click(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		root.push_input(click)
