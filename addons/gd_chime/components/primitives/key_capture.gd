extends "pressable.gd"

const Text := preload("text.gd")
const Language := preload("../../language.gd")

## A binding: a control that, pressed, listens for the next key or button
## and hands it to its action - rebinding - showing what is bound while it
## rests and what it is waiting for while it listens.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A press does not perform the action; it starts the LISTENING state, in
## which the very next key press or pad button - never an echo, never a
## release - is taken whole, before anything else hears it, and dispatched:
## action with {"action": what is being bound, "event": the event, "words": how
## the engine writes it}. WHAT IS BEING BOUND is carried because the action
## dispatched is the one that binds, not the one being put on a key: the input
## map is told BINDS {action, event} and answers for every binding there is, so
## one control cannot stand for one action by being the control it is. It is
## set on the description by whoever describes the binding, and is empty for a
## model that knows already which of its own settings this control changes. AT
## REST the door is asked about that action alone - {"action": what is being
## bound}, or nothing where none is named - since no key has arrived to ask about.
## IT STOPS LISTENING WHEN THE PLAYER MOVES ON, binding nothing: on the
## cancel key, when the focus leaves it, and when the mouse is pressed
## anywhere outside it - so a key pressed later, for something else, is
## never bound behind the player's back. Listening, it holds the focus,
## which is what makes the focus leaving mean the player left. What is bound is the
## model's - this shows the bound value it is given. It draws as a
## pressable, in the state LISTENING while it waits (a look that defines no
## such box draws normal's), and takes the focus like one, so a pad reaches
## it as it reaches any other control. What it asks is a phrase, said in
## the language on as it draws by the text's own saying (text.gd); what is
## bound is the model's, a phrase or data. ITS DRAW READS THE LANGUAGE, so a
## change of it is a draw due, as what is bound moving is - and, being no
## bell it listens to, never clears a refusal it shows (action_control.gd).

const CANCELS := KEY_ESCAPE

## The action the next key or button is bound to, carried with it. Set by
## whoever described this; empty for a model that knows already.
var rebinds: StringName = &""

var _shown: Variant  # a Bound reading what is bound, in words
var _asks: Variant  # the words it listens with: a phrase
var _listening: bool = false
var _elsewhere: bool = false  # a mouse press seen while listening, not yet known to be this control's own
var _words := Label.new()


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, shown: Variant, asks: Variant, style: StringName) -> void:
	super(chimes, commands, place, does, {}, style)
	_shown = shown
	_asks = asks
	_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# its words arrive in the language on, and are never translated a second time
	_words.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(_words)


func is_listening() -> bool:
	return _listening


## What the door is asked about at rest: the action being bound, when one is named.
func payload() -> Dictionary:
	return {} if rebinds == &"" else {"action": rebinds}


## A press starts the listening; the action is the key's, not the press's.
## A press landing here while it listens was not a press elsewhere.
func pressed() -> void:
	_elsewhere = false
	if is_usable():
		_listen(true)


func _listen(on: bool) -> void:
	_listening = on
	if on:
		grab_focus()
	needs_refresh()


## The focus gone elsewhere: the player moved on, and nothing is bound.
func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_EXIT and _listening:
		_listen(false)


func get_state() -> StringName:
	return &"listening" if _listening else super()


func refresh() -> void:
	# a mouse press the engine never handed here was a press elsewhere: the player moved on
	if _elsewhere:
		_elsewhere = false
		_listen(false)
	# the language on read as it draws, so a change of it draws these words again as what is bound moving does
	Language.on().read()
	_words.text = Text.said(_asks if _listening else _shown.read())
	super()


## The next key or button, taken whole: bound, or the cancel key binding
## nothing; a mouse press is noted and left for whatever it was pressed on -
## no rect is compared, since where an event is in a scaled window is the
## engine's to know: if the press was this control's, the engine says so. At
## rest it takes nothing: the engine hands every event to any node with an
## _input once it is ready, whatever was switched off before.
func _input(event: InputEvent) -> void:
	if not _listening:
		return
	# any mouse press may be elsewhere: it is this control's own only if the engine then hands it here, which pressed() hears before the next draw
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_elsewhere = true
		needs_refresh()
		return
	var key := event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo
	var button := event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed
	if not key and not button:
		return
	get_viewport().set_input_as_handled()
	_listen(false)
	if key and (event as InputEventKey).keycode == CANCELS:
		return
	_keep_refusal(_commands.dispatch(region, action, {"action": rebinds, "event": event, "words": event.as_text()}))
	needs_refresh()


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"key_capture").new(ui.chimes, ui.commands, ui.current_place(), desc.props["action"], desc.props["shown"], desc.props["asks"], desc.props["style"])
	made.prompts = ui.prompts
	if desc.props.has("rebinds"):
		made.rebinds = desc.props["rebinds"]
	ui.attach(made, parent, desc.facts)
	return made
