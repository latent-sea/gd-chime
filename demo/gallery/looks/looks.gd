extends "res://addons/gd_chime/controller.gd"

const Palettes := preload("res://demo/gallery/looks/palettes.gd")
const Sight := preload("res://demo/gallery/looks/sight.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Look := preload("res://addons/gd_chime/look.gd")
const Language := preload("res://addons/gd_chime/language.gd")

## The gallery's looks: every design language it can be seen in, by name,
## and the one on the root now - a model answering the pick from the
## start-here tab, or the --look=<name> switch at launch.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A look is a Theme (demo_theme.gd extended) under demo/gallery/looks/;
## putting one on the root re-dresses every control at once - the engine
## tells each it was re-themed - so a pick is one assignment, no rebuild.
##
## THE THEME IS BUILT FROM THE PAIR, the look and the sight: the look is made
## as it was written and then turned for the eye the sight names
## (palettes.gd). So the sight moving is the same one assignment as a look
## being picked, and this follows the sight (reads.gd) and dresses again.
## A look put on is dressed for the script of the language on (look.gd), so
## a look picked in a language of another script wears that script's font;
## a look giving no font by script - none of the demos' does yet - leaves
## the engine's own.

const PICKS := &"picks_a_look"
## The one action this is told.
const COMMANDS: Array[StringName] = [PICKS]
const SWITCH := "--look="
## Every look, in the order shown, by the name on its button.
const NAMES: Array[StringName] = [&"placeholder", &"flat", &"material", &"glass", &"neumorphic", &"neo_brutalist", &"swiss", &"bento", &"skeuomorphic", &"data_dense", &"hud"]
const FOLDER := "res://demo/gallery/looks/"

var _root: Window
var _current := value(&"placeholder")  # the look worn, set again each time one is put on
var _sight: Sight
var _begun: bool = false  # whether the sight is followed: the first read only follows it
var _dressed_for: StringName = &""  # the sight as last followed


## Over the sight model, whose sight this follows.
func _init(chimes: Chimes, root: Window, sight: Sight) -> void:
	super(chimes)
	_root = root
	_sight = sight
	follow(&"sight", _sight_moved)
	_begun = true


## The sight read, so it is followed; another eye, the same look dressed for it.
func _sight_moved() -> void:
	var sight := _sight.get_sight()
	if _begun and sight != _dressed_for:
		wear(_current.read())
	_dressed_for = sight


## The look asked for at launch, or, asked for none, the one given - an
## app's own - else the placeholder.
static func asked(own: StringName = &"placeholder") -> StringName:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(SWITCH):
			return StringName(arg.trim_prefix(SWITCH))
	return own


## The Theme of this name, turned for this eye: the placeholder is the demos'
## own; every other is its file under the looks folder.
static func make(named: StringName, sight: StringName = Palettes.PLAIN) -> DemoTheme:
	var made: DemoTheme = load("res://demo/demo_theme.gd").new() if named == &"placeholder" else load(FOLDER + String(named) + ".gd").new()
	Palettes.rewear(made, sight)
	return made


func get_current() -> StringName:
	return _current.read()


func would(_action: StringName, payload: Dictionary) -> Phrase:
	return Phrase.of("Already in that look") if payload.get("look") == _current.read() else null


func told(_action: StringName, payload: Dictionary) -> Phrase:
	wear(payload["look"])
	return null


## The look of this name, dressed for the sight now set, put on.
func wear(named: StringName) -> void:
	_current.set_value(named)
	put_on(make(named, _sight.get_sight()))


## A look put on the root, dressed for the script of the language on, the
## window cleared to its ground, and said: the look worn set again, so
## whatever reads it reads the look anew.
func put_on(theme: DemoTheme) -> void:
	Look.dress(theme, Language.written_in())
	_root.theme = theme
	RenderingServer.set_default_clear_color(theme.palette[&"ground"])
	_current.set_value(_current.read())


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
