extends "layout.gd"

const Bound := preload("bound.gd")
const Transition := preload("transition.gd")

## The same parts arranged differently by the shape of the window: a row
## that becomes a column, a wide layout that stacks.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ONE SET OF NODES. The parts are named and built ONCE, as the contents of
## this, and a shape changes only how they are arranged - which way the line
## runs, in what order, and what share each takes. Nothing is built, freed,
## hidden or taken out of the tree when the window turns, so a half-typed
## line is still half-typed, the focus is still where it was, a scroll is
## where it was left, and a place inside keeps its name and its stay: there
## is only ever one of it.
##
## That is why it is arrangements and not two descriptions. Two descriptions
## of one screen name THE SAME PLACES, and a place indexes itself by name
## (place.gd, index.gd): two built at once is a second of a name, refused
## out loud, and the engine renaming one of them besides. Building the side
## arriving and freeing the side going loses exactly the state the turn was
## meant to keep, and keeping both built and hidden keeps two halves of it,
## each stale by whatever was done to the other.
##
## An ARRANGEMENT is what to do with those parts, under a key the bound
## value reads - portrait and landscape, or compact, regular and wide:
##
##     {"down": true, "style": Themes.COLUMN, "order": [&"list", &"detail"],
##      "facts": {&"list": {"basis": 0.4}, &"detail": {"grow": 1.0}}}
##
## The facts are the line layout's own (flex.gd), one entry per part named
## in the order, so a part's share is a different fact in each shape rather
## than a different node.
##
## THE NEW ARRANGEMENT IS THERE AT ONCE AND IS SEEN TO ARRIVE: the parts are
## placed the instant the shape moves - so what a person is reading, typing
## in or tabbing through is never a frame behind the window - and the whole
## thing then enters (transition.gd), the look's fade unless another is
## asked for. It is not a reorder. A part's SIZE changes with the
## arrangement as well as its place, so a part drawn on its way from the old
## place at its new size would be drawn over its neighbour, which is not
## allowed; one arrangement arriving whole never can be. Asked again
## mid-way it turns round from where it has got to, since the entrance
## drives this node's opacity (motion.gd), and reduced motion leaves a short
## cross-fade over an arrangement that was already right.

var _ui: RefCounted
var _reads: Bound
var _names: Array  # the parts' names, in the order they were described
var _arrangements: Dictionary
var _parts: Dictionary = {}  # name -> the part built for it
var _worn: StringName = &""  # the arrangement in force now
var _asked: StringName  # the transition asked for where this was described, or none
var _gathered: bool = false  # whether the parts described have been taken under their names
var _begun: bool = false  # whether it has been arranged once: the first is simply there


func _init(ui: RefCounted, names: Array, arrangements: Dictionary, reads: Bound, asked: StringName) -> void:
	super(ROW, &"")
	_ui = ui
	_names = names
	_reads = reads
	_arrangements = arrangements
	_asked = asked
	# every fact of every arrangement, refusing one a line layout has no meaning for
	for named: StringName in arrangements:
		for part: StringName in arrangements[named]["facts"]:
			for given: String in arrangements[named]["facts"][part]:
				if not FACTS.has(given):
					push_error("an arrangement gives a part %s; a part has %s" % [given, FACTS])
	ui.chimes.follow(self, &"shape", _shape_moved)


## The part built under this name.
func part_for(named: StringName) -> Control:
	return _parts[named]


## Which arrangement is in force now.
func get_worn() -> StringName:
	return _worn


## The key of the arrangement this should be wearing now: the bound value's
## reading, or, in a container query, its own width (by_width.gd).
func key_now() -> StringName:
	return _reads.read()


## The shape read, so what it read is followed, and taken up; one moving
## before the parts are gathered is not missed: it is read then.
func _shape_moved() -> void:
	var key := key_now()
	if _gathered:
		_take_up(key)


## The engine tells every script in the chain, so the layout's own
## notification runs as well without a call from here.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_ui.chimes.stop_all(self)
	if what == NOTIFICATION_CHILD_ORDER_CHANGED and not _gathered and get_child_count() == _names.size():
		_gather()


## The parts are this thing's contents, built by the builder in the order
## they were described - so a pressable in one is declared on the place like
## any other - and this is told as the last of them is put in. They take the
## names given for them here, once, and the arrangement is taken up then and
## there, so nothing is ever seen in the wrong one.
func _gather() -> void:
	_gathered = true
	# every name given, against the part described under it
	for at: int in _names.size():
		_parts[_names[at]] = get_child(at)
	_take_up(key_now())
	_begun = true


## This arrangement taken up: the line turned, restyled, and every part put
## in its order under the share this shape gives it - and then, unless this
## is the first, the whole of it seen to arrive.
func _take_up(named: StringName) -> void:
	if named == _worn:
		return
	if not _arrangements.has(named):
		push_error("nothing is arranged for %s; there is %s" % [named, _arrangements.keys()])
		return
	_worn = named
	var arrangement: Dictionary = _arrangements[named]
	_direction = COLUMN if arrangement["down"] else ROW
	_style = arrangement["style"]
	_read_look()
	# every part in this shape's order, under this shape's facts
	for at: int in arrangement["order"].size():
		var part: Control = _parts[arrangement["order"][at]]
		_facts[part] = arrangement["facts"][arrangement["order"][at]]
		move_child(part, at)
	queue_sort()
	if _begun and is_visible_in_tree():
		Transition.enter(self, Transition.named(_asked, &"by_shape", self), _ui.motion)


## The builder's door: the parts described are its contents, arranged by
## what the bound value reads.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(desc.kind).new(ui, desc.props["names"], desc.props["arrangements"], desc.props["reads"], desc.props.get("transition", &""))
	ui.attach(made, parent, desc.facts)
	return made
