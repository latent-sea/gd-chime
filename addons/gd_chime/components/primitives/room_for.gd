extends "../../presentation.gd"

const Text := preload("text.gd")

## A slot holding the room of the widest of its samples, in a kind of
## words, whatever what it holds shows now: a clock, a balance, a score -
## any figure that changes - so the line it stands in is placed once and
## never again as the figure moves.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ITS LEAST IS ITS WIDEST SAMPLE'S ROOM, each way: every sample is set on
## a label of its own in the kind given, never shown, and the room needed
## is the most any of them needs across and down, the box the kind sets
## its words in with it. What it holds is laid across the whole of that
## room, so what it shows moving within its samples never reaches the line
## it stands in. A sample is the longest the figure may say; where what it
## holds needs more than every sample - samples that left the longest out,
## or none given - the slot is as wide as that needs, so it is never drawn
## over what stands beside it.
##
## SAMPLES ARE SAID AS WORDS ARE (text.gd): a phrase in the language on,
## anything else as it is. Said in another language or dressed in another
## look, they are measured again, and only then: what it holds moving is
## never a reason to.
##
## What it would take given all the room it wants is its least: it never
## wants more. It takes no press; what it holds does. It draws nothing.

var _samples: Array  # the words measured: phrases, or data as it is
var _measures: Array[Label] = []  # a label per sample, in the kind, never shown


func _init(chimes: Chimes, samples: Array, style: StringName, in_region: StringName) -> void:
	super(chimes, [], in_region)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_samples = samples
	# every sample, on a label of its own in the kind, hidden, for its room to be measured by
	for sample: Variant in samples:
		var measure := Label.new()
		measure.theme_type_variation = style
		measure.visible = false
		# the sample arrives said in the language on; the engine translating it again would take data for a word
		measure.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		add_child(measure)
		_measures.append(measure)


## What it holds, laid across the whole of its room.
func place(content: Control, _facts: Dictionary) -> void:
	add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## The most any sample needs, across and down, and never less than what it holds needs.
func _get_minimum_size() -> Vector2:
	var room := Vector2.ZERO if get_child_count() == _measures.size() else (get_child(get_child_count() - 1) as Control).get_combined_minimum_size()
	# every sample's label, for the widest and the tallest
	for measure: Label in _measures:
		room = room.max(measure.get_minimum_size())
	return room


## What it would take given all the room it wants (preferred.gd): its least, since it never wants more.
func preferred_size() -> Vector2:
	return get_combined_minimum_size()


## The samples said in the language on, what that read followed, and the
## room asked again: another language, or another look, measures again.
func refresh() -> void:
	# every sample, said onto its label
	for at: int in _samples.size():
		_measures[at].text = Text.said(_samples[at])
	update_minimum_size()


## The builder's door: a slot of the widest sample's room, what it holds built into it.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"room_for").new(ui.chimes, desc.props["samples"], desc.props["style"], ui.region())
	ui.attach(made, parent, desc.facts)
	return made
