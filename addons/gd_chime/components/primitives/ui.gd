extends "built_names.gd"

const Commands := preload("../../commands.gd")
const Prompts := preload("../../prompts.gd")
const Place := preload("../../place.gd")
const StartupCheck := preload("../../startup_check.gd")
const Pressable := preload("pressable.gd")
const View := preload("view.gd")
## The floor's primitives, each a script with build(ui, desc, parent) (floor_kinds.gd).
const FLOOR: Dictionary = preload("floor_kinds.gd").KINDS

## The builder: interface is described, not built by hand. The descriptions
## are describe.gd's, which this extends; this turns one into nodes, by the
## primitive registered for its kind.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Built once, by construction, with the root to build under, the chimes,
## the door, the driver, the prompts and the register. A recipe - any
## component that is not a primitive - is a plain function returning a
## description built from these; it contains no engine code, and a UI
## builder can write one. Looks are Theme names passed as style.
##
## A PRIMITIVE REGISTERS ITSELF: a kind and a script whose static
## build(ui, desc, parent) makes the node, attaches it with ui.attach, and
## builds what it holds with ui.build_into. The floor's are registered as
## this is built; a game adds its own with register(kind, script), editing
## no floor file.
##
## PLACES: app, screen, tabs and pop_up describe places (place.gd). Built,
## a place declares what it performs from the pressables inside it - and
## from what each template inside it describes, asked once with an empty
## handle as the place is built, so a collection that starts empty has its
## actions declared - each action and where it goes, said once, with no
## region strings; its handled_by is registered for those actions in the
## place's own region, but for an action the door already answers from
## anywhere.
##
## POP-UPS ARE LIFTED: a pop-up described anywhere - among what it stands
## over, on the press opening it, as the question a screen asks - is built
## once, under the root beside the app, the first time a place holding it
## is declared or it is met being built (place_builder.gd); met again, it is
## the one already standing. So the app's pop-ups stand from startup
## wherever they were described, and nothing carries them to the root.
##
## start(description) builds top-down, so a place exists before its
## contents, adds everything to the tree, sets the app, and, once the tree
## has entered on the first frame and the index has filled, runs the startup
## check - a broken tree is said out loud, whoever asked is told, and the app
## stands empty; nothing here ever quits the game - and makes the first
## move, into the app. The description is not kept: the nodes are the truth.

var root: Node
var commands: Commands
var prompts: Prompts

var _builders: Dictionary = {}  # kind -> the primitive's script
var _place: Node = null  # the place being built into
var _pressable: Node = null  # the pressable being built into
var _lifted: Dictionary = {}  # a pop-up's name -> its place, built beside the app
var _on_broken: Callable  # told the faults of a broken tree, when given: the app's, or a test's


func _init(under: Node, bells: Chimes, door: Commands, moves: Driver, prompting: Prompts, register: Actions) -> void:
	root = under
	chimes = bells
	commands = door
	driver = moves
	prompts = prompting
	actions = register
	motion = Motion.new(bells, under)
	driver.motion = motion
	carried = Carried.new(bells)
	shape = Shape.new(bells)
	language = Language.new(bells, under)
	frames = Frames.new(bells)
	# the floor's own six, under the root from the moment there is a builder: the clock, the carry, the window's shape, the language, the finger, the frames
	for made: Node in [motion, carried, shape, language, touch, frames]:
		also(made)
	for kind: StringName in FLOOR:
		_builders[kind] = FLOOR[kind]
	# every pop-up's way out, its words and inputs said once, before the map of inputs reads the register
	actions.declare_all({CLOSES: ["Close", Actions.keys(KEY_ESCAPE), Actions.pad(JOY_BUTTON_B)]})


## A primitive of the game's own: this kind is built by this script's
## build(ui, desc, parent) from now on.
func register(kind: StringName, primitive: GDScript) -> void:
	_builders[kind] = primitive


## The script registered for a kind.
func primitive(kind: StringName) -> GDScript:
	return _builders[kind]


## The whole interface built under the root: the app, and every pop-up
## described in it lifted beside it; checked and arrived at once the tree
## has entered.
func start(application: Desc, on_broken: Callable = Callable()) -> void:
	build(application, root)
	_on_broken = on_broken
	_started.call_deferred()


## A node made by hand rather than described - a model, or the console -
## put under the root; a control among them across the whole window, as a
## place described would be. One that is a model's own child already - a
## route's refresh, a table's long list - is left where it is: it is in the
## tree with its holder, and stood up here only to be told its actions.
func also(node: Node) -> void:
	if node.get_parent() != null:
		return
	if node is Control:
		(node as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(node)


## The place being built into now, for a piece that will build again later.
func current_place() -> Node:
	return _place


## The pressable being built into now, whose answers its content may read.
func current_pressable() -> Node:
	return _pressable


## The region what is built now belongs to: the place's name.
func region() -> StringName:
	return _place.name if _place != null else Chimes.GLOBAL


## This description as nodes under this parent, top-down: the node made by
## its kind's primitive, then its contents built into it. A piece rebuilding
## later - a when swapping, an each on its bell - says the place it was
## built in; a place built into by hand, as the console is, is the place
## itself.
func build(desc: Desc, parent: Node, in_place: Node = null) -> Control:
	if desc.kind == POP_UP:
		return lift(desc)
	var place_before := _place
	var pressable_before := _pressable
	if in_place != null:
		_place = in_place
	elif _place == null and parent is Place:
		_place = parent
	var made: Control = (_builders[desc.kind] as GDScript).build(self, desc, parent)
	if desc.props.has("id"):
		name_piece(desc.props["id"], made)
	if desc.props.has("arrives"):
		_place.arriving.append([made, desc.props["arrives"]])
	# a place or a pressable made is the one being built into, for what it holds
	if made is Place:
		_place = made
	if made is Pressable:
		_pressable = made
	build_into(desc, (made as View).viewport if made is View else made)
	_place = place_before
	_pressable = pressable_before
	return made


## A pop-up standing beside the app: built under the root the first time,
## in no place and no pressable, and the one standing every time after.
func lift(overlay: Desc) -> Control:
	var named := overlay.get_place()
	if _lifted.has(named):
		return _lifted[named]
	var place_before := _place
	var pressable_before := _pressable
	_place = null
	_pressable = null
	# said lifted before it is built, so a press inside it opening it again finds it standing
	_lifted[named] = null
	_lifted[named] = (_builders[POP_UP] as GDScript).build(self, overlay, root)
	if overlay.props.has("id"):
		_named[overlay.props["id"]] = _lifted[named]
	_place = _lifted[named]
	build_into(overlay, _lifted[named])
	_place = place_before
	_pressable = pressable_before
	return _lifted[named]


## The description's contents built into this node.
func build_into(desc: Desc, into: Node) -> void:
	for child: Desc in desc.children:
		build(child, into)


## A node attached to its parent: placed with its facts by a layout, added
## by anything else.
func attach(made: Control, parent: Node, facts: Dictionary) -> void:
	if "motion" in made:
		made.motion = motion
	if parent.has_method("place"):
		parent.place(made, facts)
	else:
		parent.add_child(made)


## A template's description for this handle, built under this parent, in
## the place of this node. The handle reports a read while the template
## runs - the item copied into the description - and not one made after, by
## what was described.
func build_template(template: Callable, handle: Bound, parent: Node, in_place: Node = null) -> Control:
	return build(describe_with(template, handle), parent, in_place)


## What a template describes for a handle, the handle guarded meanwhile.
func describe_with(template: Callable, handle: Bound) -> Desc:
	handle.set_template_running(true)
	_templates_running += 1
	var desc: Desc = template.call(handle)
	_templates_running -= 1
	handle.set_template_running(false)
	if desc == null:
		push_error("a template described nothing for %s; a template must cope with an empty handle" % [handle.read()])
	return desc


## The tree has entered: the context menu's description let go - the tree is
## the truth from here, and a description the builder holds while it holds
## the builder would keep both for ever - then checked, and a sound one
## arrived at.
func _started() -> void:
	context_menu = null
	var wrong := StartupCheck.broken(driver.index, actions)
	for sentence: String in wrong:
		push_error(sentence)
	# a broken tree said, whoever asked told, and no first move made: every place stays hidden, and the app stands empty
	if not wrong.is_empty():
		if _on_broken.is_valid():
			_on_broken.call(wrong)
		return
	# the default inputs asked about now the places stand: two actions on one input, reachable at once, are said out loud
	if inputs != null:
		inputs.report_conflicts()
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": driver.index.app.name})
