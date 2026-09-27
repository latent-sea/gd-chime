extends "layout.gd"

const Bound := preload("bound.gd")
const Chimes := preload("../../chimes.gd")
const Reorder := preload("reorder.gd")
const Transition := preload("transition.gd")
const Reads := preload("../../reads.gd")

## One piece per item of a bound array, down a column or along a row: the
## template asked for a description per item, given a handle to the item,
## never the item; the pieces kept by key as the array moves.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A handle is a bound value: the item with that key, on a bell of its own
## this rings as the array moves with that item changed - so what the
## template binds to it re-reads as its item moves, and a piece whose item
## stayed as it was, a card in a lane a search narrowed, reads nothing. The key is
## a function from an item to its identity - an id - given with the
## template: an item added builds one piece, an item gone frees one, an
## item moved is moved, and the rest are left alone, so the focus, a kept
## when side, a typed field and a scroll all survive a sort, a filter and a
## removal. Given no key, the index is the key, and any change to the array
## rebuilds every piece. A KEY GONE TAKES ITS BELL AND ITS NAME WITH IT: the
## handle's bell is taken down and the piece's name let go (built_names.gd),
## so a list whose keys come and go holds only what its keys now are.
##
## THE ARRAY MOVING IS SEEN TO MOVE. A piece built for a new item enters
## and one whose item has gone exits (transition.gd) - the transition
## asked for where this was described, or the look's for an each - and
## pieces entering together enter one after another, the look's stagger
## apart. A piece whose place changed is TAKEN there (reorder.gd) - slid,
## or lifted out and set down, whichever keeps anything from being drawn
## over anything else - so a sort or a filter visibly reorders. What is
## there as this is built is simply there.
##
## Built into a place, the place asks the template once with an empty
## handle as it is built, so the actions its pressables perform are
## declared before any item exists. Nesting is the same thing again: an
## item's own list is handle.field(&"children"), and an each over it.

var _ui: RefCounted
var _items: Bound
var _template: Callable
var _key: Callable
var _in_place: Node  # the place this was built in, for building again later
var _pieces: Dictionary = {}  # key -> the piece built for it
var _prefix: StringName  # pieces named after their key under this, or unnamed
var _asked: StringName  # the transition asked for where this was described, or none
var _begun: bool = false  # whether it has settled once: what is there as it is built is simply there
var _reorder: Reorder
var _changed: bool = false  # whether the set changed since the layout last placed the pieces
var _going: bool = false  # whether a piece has set off going since then
var _arriving: Array = []  # the keys of the pieces built since then, in order
var _indexed: Variant = null  # the items array the lookup by key was made for
var _by_key: Dictionary = {}  # key -> its item in that array
var _region: StringName  # where the bells of its pieces' handles hang, its own
var _was: Dictionary = {}  # key -> a copy of its item as last settled
var _hung: Dictionary = {}  # key -> the bell hung for its piece's handle, while the key stands


func _init(ui: RefCounted, items: Bound, template: Callable, key: Callable, direction: int, style: StringName, prefix: StringName, asked: StringName = &"") -> void:
	super(direction, style)
	_ui = ui
	_items = items
	_template = template
	_key = key
	_prefix = prefix
	_asked = asked
	_in_place = ui.current_place()
	_reorder = Reorder.new(ui.motion)
	_region = StringName("each %d" % get_instance_id())
	# the array followed: settled now, and again as what it read moves
	ui.chimes.follow(self, &"items", _items_moved)
	_begun = true


## The count of pieces built now.
func get_count() -> int:
	return _pieces.size()


## The piece built for this key.
func piece_for(key: Variant) -> Node:
	return _pieces.get(key)


## The engine tells every script in the chain, so the layout's own
## notification runs as well without a call from here.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_ui.chimes.stop_all(self)
		_ui.chimes.drop_region(_region)
	if what == NOTIFICATION_PRE_SORT_CHILDREN:
		_reorder.about_to_place(_pieces)
	if what == NOTIFICATION_SORT_CHILDREN:
		if _changed and is_visible_in_tree():
			_reorder.placed(_pieces, _keys(), _arriving, Transition.named(_asked, &"each", self), _going)
		else:
			_reorder.rested(_pieces, _keys())
		_changed = false
		_going = false
		_arriving = []


## The keys of the items now, in order: the key function's, or the indices.
func _keys() -> Array:
	var items: Variant = _items.read()
	var keys: Array = []
	if items == null:
		return keys
	for index: int in range(items.size()):
		keys.append(_key.call(items[index]) if _key.is_valid() else index)
	return keys


## The item with this key now, or null: looked up in the items by key, the
## lookup made once for each array the source reads - a handle is read by
## everything a piece shows, and a search through the items for each read
## made a list of fifty cards cost fifty times a card to draw.
func _item_for(key: Variant) -> Variant:
	var items: Variant = _items.read()
	if items == null:
		return null
	if not is_same(items, _indexed):
		_indexed = items
		_by_key = {}
		# every item, under its key
		for index: int in range(items.size()):
			_by_key[_key.call(items[index]) if _key.is_valid() else index] = items[index]
	return _by_key.get(key)


## The array read, so it is followed; moved, the pieces brought to it -
## apart from what is followed, so what the pieces read as they are built is
## theirs to follow, never this (reads.gd).
func _items_moved() -> void:
	_items.read()
	Reads.apart(_settle)


## The pieces brought to the array: keyed, one freed per item gone, one
## built per item new, each moved to its item's place; unkeyed, all rebuilt
## on any change.
func _settle() -> void:
	# the array may have moved in place: the lookup by key is made again as it is next read
	_indexed = null
	var keys := _keys()
	if not _key.is_valid() and keys.size() != _pieces.size():
		for piece: Node in _pieces.values():
			piece.free()
		_pieces.clear()
	# every piece whose item is gone, freed - its focus handed on first - and its handle's bell taken down and its name let go with it
	for key: Variant in _pieces.keys():
		if not keys.has(key):
			_let_go(_pieces[key])
			_pieces.erase(key)
			# built and gone again before the layout placed it: nothing is left to arrive
			_arriving.erase(key)
			_changed = true
			_going = true
			_ui.chimes.drop_bell(_region, _hung[key])
			_hung.erase(key)
			if _prefix != &"":
				_ui.forget_named(StringName(_prefix + str(key)))
	# every item, its piece built if new, and moved to the item's place in the order
	for index: int in range(keys.size()):
		var key: Variant = keys[index]
		if not _pieces.has(key):
			var handle := Bound.on_bell(func() -> Variant: return _item_for(key), _region, _bell_for(key))
			var desc: RefCounted = _ui.describe_with(_template, handle)
			if _prefix != &"":
				desc.props["id"] = StringName(_prefix + str(key))
			_pieces[key] = _ui.build(desc, self, _in_place)
			_changed = true
			if _begun:
				_arriving.append(key)
		if _pieces[key].get_index() != index:
			_changed = true
			move_child(_pieces[key], index)
	_ring_changed(keys)


## Every piece whose item is not as it was when last settled, its handle's
## bell rung: its readers read it again, and a piece whose item is the same
## reads nothing.
func _ring_changed(keys: Array) -> void:
	var now: Dictionary = {}
	# every item now, against a copy of it as it last was
	for key: Variant in keys:
		now[key] = _item_for(key)
		if _was.has(key) and _was[key] != now[key]:
			_ui.chimes.strike(_region, _bell_for(key))
		now[key] = now[key].duplicate(true) if now[key] is Dictionary or now[key] is Array else now[key]
	_was = now


## The bell of one piece's handle, hung the first time it is asked for.
func _bell_for(key: Variant) -> StringName:
	if not _hung.has(key):
		_hung[key] = StringName("%s %s" % [_region, key])
		_ui.chimes.register(_region, _hung[key])
	return _hung[key]


## A piece freed, the focus it holds handed to the next control that takes it.
func _let_go(piece: Node) -> void:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focused != null and (focused == piece or piece.is_ancestor_of(focused)):
		var next := focused.find_next_valid_focus()
		if next != null and next != piece and not piece.is_ancestor_of(next):
			next.grab_focus()
	Transition.exit(piece as Control, Transition.named(_asked, &"each", self) if _begun and is_visible_in_tree() else Transition.NONE, _ui.motion)


## The builder's door for this kind: the piece per item, keyed.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = get_script_of(ui).new(ui, desc.props["items"], desc.props["template"], desc.props["key"], desc.props["direction"], desc.props["style"], desc.props.get("pieces_named", &""), desc.props.get("transition", &""))
	ui.attach(made, parent, desc.facts)
	return made


## This script, for a static function to make one: a script has no name to
## call new on from inside itself.
static func get_script_of(ui: RefCounted) -> GDScript:
	return ui.primitive(&"each")
