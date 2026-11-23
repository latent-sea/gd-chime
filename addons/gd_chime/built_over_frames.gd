extends RefCounted

## An application built while everything else goes on: what it built joins
## the tree a share of a frame at a time, and the app starts once all of it
## has (chime_app.gd, builds_over_msec).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ENTERING THE TREE IS MOST OF WHAT BUILDING AN APP COSTS: on a slow machine
## a big app's 1,900 nodes took about 300 ms to enter and 400 ms more to be
## laid out the first time, two frames, where describing it and building it
## off the tree took 200 (measured on a software-drawn desk, 23 Nov). Here
## what was built is taken off before it enters, and joins again a part at a
## time: a part of BOUND nodes or fewer joins whole, and a bigger one joins
## first with nothing under it and then each of its own parts, in the order
## they were built, so everything stands where it was built to stand.
##
## THE APP STARTS ONLY ONCE EVERYTHING HAS JOINED: the startup check, the
## first move and the focus it brings come then (ui.gd, begin), so every
## place is in the index, and the reader arrives, as if it had all entered
## at once. What a host does before then it does to an app not yet started.
##
## Finished at once where the app is wanted now (all_now), and let go where
## the app goes first (drop): what had not joined is freed with it.
##
## A PLAN JOINS WHOLE, everything under it with it (planned.gd): a plan lays
## its pieces by where they stand among them and reads the words inside them,
## so it is never planned with any of them, or anything in them, missing.
##
## A part held by a layout that keeps what it was given for each part (a
## flex, a grid) joins it again through place(), with what it was given:
## taken off, the layout forgets it.
##
## Only the pieces it built join late; whatever is not drawn - the models,
## the driver and the rest beside the app - enters with the app.

const Flex := preload("components/primitives/flex.gd")
const Grid := preload("components/primitives/grid.gd")
const Planned := preload("planned.gd")

## The most nodes that join in one go.
const BOUND := 250

var _joins: Array = []  # [the parent, the part, what the parent was given for it or null] in the order they join
var _at := 0  # how many have joined
var _ui: RefCounted
var _dropped := false
var _begun := false


## What `ui` built under `canvas` taken off before it enters, to join it again `budget_msec` of each frame at a time
## from the next frame on, the app then started.
func _init(app: Node, canvas: Node, ui: RefCounted, budget_msec: float) -> void:
	_ui = ui
	var sizes: Dictionary = {}
	_held(canvas, sizes)
	# each piece built on the canvas that is drawn, taken off as a whole or a part at a time
	for piece: Node in canvas.get_children():
		if piece is Control:
			_taken_off(canvas, piece, sizes)
	_over_frames(app, budget_msec)


## Whether it has all joined and the app has been started.
func is_built() -> bool:
	return _begun


## Everything not yet joined joined now, and the app started.
func all_now() -> void:
	# each part not yet joined, joined in order
	while _at < _joins.size():
		_join(_joins[_at])
		_at += 1
	_begin()


## The app let go before it was built: nothing more joins, and every part that had not joined is freed.
func drop() -> void:
	_dropped = true
	# each part not yet joined: it stands on nothing, so it is freed here or never
	for join: Array in _joins.slice(_at):
		(join[1] as Node).free()
	_at = _joins.size()


## The parts joined a frame at a time, from the next frame on, then the app started; nothing more once dropped.
func _over_frames(app: Node, budget_msec: float) -> void:
	var tree := app.get_tree()
	# a frame at a time: parts joined in order until the frame's share is spent
	while _at < _joins.size():
		await tree.process_frame
		var began := Time.get_ticks_usec()
		# each part in turn while the share lasts
		while _at < _joins.size() and Time.get_ticks_usec() - began < budget_msec * 1000.0:
			_join(_joins[_at])
			_at += 1
	if not _dropped:
		_begin()


## The app started, once.
func _begin() -> void:
	if not _begun:
		_begun = true
		_ui.begin()


## One part joined to its parent again: placed with what it was given there, or simply added.
static func _join(join: Array) -> void:
	if join[2] != null:
		join[0].place(join[1], join[2])
	else:
		(join[0] as Node).add_child(join[1])


## `node` taken off `parent` to join it again: whole where it holds BOUND nodes or fewer, and otherwise first with
## nothing under it, each of its own parts taken off after it.
func _taken_off(parent: Node, node: Node, sizes: Dictionary) -> void:
	var given: Variant = parent.get_facts(node) if parent is Flex or parent is Grid else null
	parent.remove_child(node)
	_joins.append([parent, node, given])
	if sizes[node] <= BOUND or node is Planned:
		return
	# each part under it, in the order it was built
	for part: Node in node.get_children():
		_taken_off(node, part, sizes)


## The nodes `node` holds, itself counted, kept in `sizes` for it and for every node under it.
static func _held(node: Node, sizes: Dictionary) -> int:
	var held := 1
	# each child, counted with what it holds
	for child: Node in node.get_children():
		held += _held(child, sizes)
	sizes[node] = held
	return held
