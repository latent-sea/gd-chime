extends SceneTree

## What must be true of A LOOK THAT SETS NOTHING: it still lays every
## recipe out and draws it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_bare_look.gd
##
## A RECIPE OWNS ITS STRUCTURAL VARIANTS. A recipe names a style - the
## instruction bar's row, a card, the tabs' strip - and until this round a
## style nobody had dressed simply was not in the theme: the primitive read
## the look, found nothing under that name and fell back to its base at run
## time (layout.gd, face.gd, surface.gd), so a bar meant to stand its parts
## in the middle of the line stretched them instead, and only a look that
## happened to set it laid it out as the recipe wanted. The floor's look
## registers every style its own components name, so the fallback is for a
## GAME's styles alone and a new look starts from a screen that is already
## right.
##
## The first check is the one that cannot drift: it READS THE COMPONENTS
## THEMSELVES, every Theme name any of them says, and asks the floor's look
## for each. A recipe naming a style no family dresses fails it the day it
## is written, without anyone remembering to list it here.
##
## Five names a component says are not styles at all, and are named below
## with why: the four shapes a chart's markers are drawn in, which are words
## the drawing reads, and the name the shift key is registered under.

const Themes := preload("res://addons/gd_chime/theme.gd")
const Flex := preload("res://addons/gd_chime/components/primitives/flex.gd")
const Fixture := preload("res://tests/fixture.gd")
const InstructionBar := preload("res://addons/gd_chime/components/recipes/instruction_bar.gd")
const AmountField := preload("res://addons/gd_chime/components/recipes/amount_field.gd")
const Tabs := preload("res://addons/gd_chime/components/recipes/tab_bar.gd")
const Layout := preload("res://addons/gd_chime/components/primitives/layout.gd")
const Verdict := preload("res://tests/verdict.gd")

## The folder whose every script is read, and the Theme names it may say that are not styles.
const COMPONENTS := "res://addons/gd_chime/components"
const NOT_STYLES: Array[StringName] = [&"Circle", &"Square", &"Diamond", &"Triangle", &"Shift"]
## The engine's own types, which a style may be a variation of without the floor naming them.
const ENGINE: Array[StringName] = [&"Label", &"Control", &"Container", &"LineEdit", &"TextEdit", &"Scroll"]
## Each line a recipe owns and how its parts stand across it, which a plain row does not do.
const ACROSS := {&"InstructionBar": Flex.CENTER, &"AmountField": Flex.CENTER, &"Controls": Flex.CENTER, &"SettingRow": Flex.CENTER, &"Asked": Flex.CENTER, &"TabStrip": Flex.END}

var _verdict := Verdict.new()


func _init() -> void:
	await process_frame
	await _verdict.states(_every_style_a_component_names_is_one_the_floor_dresses)
	await _verdict.states(_a_look_that_sets_nothing_lays_every_recipe_s_line_out)
	await _verdict.states(_a_bar_built_under_a_bare_look_wears_its_own_style)
	await _verdict.states(_the_tokens_an_application_draws_on_are_the_floor_s)
	quit(_verdict.deliver(get_script()))


## Every Theme name said anywhere under components/, against the floor's
## look: each is a type it knows - a variation of something, or the engine's
## own - since a style no family dresses is one the primitive would fall
## back from, laid out as a bare row and drawn as a bare pressable.
func _every_style_a_component_names_is_one_the_floor_dresses() -> void:
	var look := Themes.new(Themes.NEUTRAL)
	var names := RegEx.new()
	names.compile("&\"([A-Z][A-Za-z0-9]*)\"")
	var undressed := ""
	var counted := 0
	# every script under components/, for every Theme name it says
	for path: String in _scripts(COMPONENTS):
		# every line but a comment, so a header naming a style does not count as naming one
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			for found: RegExMatch in names.search_all(line):
				var said := StringName(found.get_string(1))
				if NOT_STYLES.has(said) or ENGINE.has(said):
					continue
				counted += 1
				if look.get_type_variation_base(said) == &"" and not look.get_type_list().has(said):
					undressed += "%s (%s); " % [said, path.get_file()]
	_verdict.check(counted > 100, "the components were read, and they name this many styles: %d" % counted)
	_verdict.check(undressed == "", "every style a component names is one the floor's look dresses: %s" % ("all of them" if undressed == "" else undressed))


## A look that sets nothing is the floor's look merged into an empty Theme,
## which is what a look is before it says a word. Each line a recipe owns
## still stands its parts the way the recipe needs, not the way a plain row
## would: the values are the floor's, and a look changes them.
func _a_look_that_sets_nothing_lays_every_recipe_s_line_out() -> void:
	var bare := Theme.new()
	bare.merge_with(Themes.new(Themes.NEUTRAL))
	var wrong := ""
	# every line a recipe owns, for the way its parts stand across it
	for line: StringName in ACROSS:
		var across: int = bare.get_constant(&"align", line) if bare.has_constant(&"align", line) else -1
		if across != ACROSS[line]:
			wrong += "%s: %s, not %s; " % [line, across, ACROSS[line]]
	_verdict.check(wrong == "", "under a look that sets nothing, every line a recipe owns stands its parts as the recipe needs: %s" % ("all of them" if wrong == "" else wrong))
	_verdict.check(bare.get_constant(&"align", Themes.ROW) == Flex.STRETCH, "and a plain row is unchanged, stretching its parts down the line")


## Built under the floor's look alone, an instruction bar and an amount
## field wear the style they were described with - neither falls back - and
## the bar's parts stand in the middle of the line.
func _a_bar_built_under_a_bare_look_wears_its_own_style() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	var made := Fixture.new(root, {&"ticks": "Tick", &"cancels": "Cancel"})
	var ui := made.ui
	var act := Act.new(made.chimes, &"app")
	made.commands.register(&"app", &"cancels", act)
	made.commands.register(&"app", &"ticks", act)
	ui.start(ui.app(&"app", [ui.column([
		InstructionBar.make(ui, act, &"cancels").named(&"bar"),
		AmountField.make(ui, &"ticks", "c").named(&"amount"),
		Tabs.make(ui, [], [ui.text("in the panel")]).named(&"tabs"),
	])]))
	await process_frame
	await process_frame
	var fell_back := ""
	# every line built under the bare look, for one wearing no style at all
	for node: Node in root.find_children("*", "Container", true, false):
		if node is Layout and (node as Layout).theme_type_variation == &"":
			fell_back += "%s; " % node.name
	var bar: Layout = ui.node_named(&"bar")
	var amount: Layout = ui.node_named(&"amount")
	_verdict.check(bar.theme_type_variation == &"InstructionBar" and amount.theme_type_variation == &"AmountField", "under the floor's look alone, the bar and the amount field wear their own styles: %s, %s" % [bar.theme_type_variation, amount.theme_type_variation])
	_verdict.check(bar.align == Flex.CENTER and amount.align == Flex.CENTER, "and stand their parts in the middle of the line: %s, %s" % [bar.align, amount.align])
	_verdict.check(fell_back == "", "and no line is left with no style at all: %s" % ("none is" if fell_back == "" else fell_back))
	act.free()
	made.done()
	root.theme = null


## An application draws its own content on grounds and says it in words
## that no recipe of the framework's names: a raised panel, a card on it, a
## title and a number. They were the demos' and are the floor's, so an
## application built on this has them without writing a look at all.
func _the_tokens_an_application_draws_on_are_the_floor_s() -> void:
	var look := Themes.new(Themes.NEUTRAL)
	# the two grounds: each a surface with a panel of its own, and not the same panel
	var grounds := look.get_stylebox(&"panel", Themes.RAISED) != look.get_stylebox(&"panel", Themes.CARD)
	_verdict.check(grounds and look.get_type_variation_base(Themes.CARD) == Themes.SURFACE, "a raised panel and a card are grounds of the floor's, each with a panel of its own")
	_verdict.check(look.get_font_size(&"font_size", Themes.TITLE) > 0 and look.get_font_size(&"font_size", Themes.NUMBER) > look.get_font_size(&"font_size", Themes.WORDS), "a title is a kind of words, and a number is bigger than the largest the framework draws: %d" % look.get_font_size(&"font_size", Themes.NUMBER))
	_verdict.check(look.get_constant(&"justify", Themes.CENTRED) == Flex.CENTER, "and a centred row packs its parts to the middle: %d" % look.get_constant(&"justify", Themes.CENTRED))


## Every script under this folder and the folders in it.
func _scripts(folder: String) -> Array[String]:
	var found: Array[String] = []
	# every script of the folder, then every folder inside it, walked into
	for entry: String in DirAccess.get_files_at(folder):
		if entry.ends_with(".gd"):
			found.append(folder + "/" + entry)
	for inside: String in DirAccess.get_directories_at(folder):
		found.append_array(_scripts(folder + "/" + inside))
	return found


## The act an instruction bar reads: what it is asking, how far through, and the way out.
class Act extends "res://addons/gd_chime/controller.gd":
	func _init(chimes: Chimes, in_region: StringName) -> void:
		super(chimes, [], in_region)

	func get_words() -> Variant:
		return null

	func get_progress() -> Variant:
		return null

	func get_asking() -> bool:
		return true

	func answers() -> Array[StringName]:
		return [&"cancels"]
