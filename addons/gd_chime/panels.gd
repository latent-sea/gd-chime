extends "controller.gd"

const SaveShape := preload("save_shape.gd")

## The panels of an application shell: how the room of each split is shared
## between its two panes, which panes are folded away, and which one is
## expanded over the rest - one model, saved as plain data between runs.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A SPLIT IS A NAME AND A SHARE: the share of its room its FIRST pane takes,
## from nothing to all of it, and which side, if either, is FOLDED away -
## FIRST or SECOND. A PANE IS A NAME AND WHERE IT STANDS: [its split, its
## side]. A pane that is itself a split is named as that split, so the panes
## are a tree and the way down to any pane is known here: which is what
## EXPANDING needs - the pane is made whole by folding, in every split on the
## way down to it, the side it is not on; expanded again, the folds it had
## before come back. Where the room goes is the split's (split.gd), which
## reads the share and the fold and holds neither.
##
## Every change is a command through the door: RESIZES {split, by, to} from
## a split's grip (grip.gd), dragged or stepped - the share set to where the
## grip is being taken - which opens a folded side, since a grip dragged out
## of its edge is the reader asking for the pane back - and, on
## no payload, each ACTION the application names for folding and unfolding a
## pane or expanding one, so a key or a pad button presses it (shortcuts.gd),
## and each action it names for bringing a pane into view - a notification's
## offer to show what a run answered - which unfolds only what hides it.
## Anything that changes the folds ends an expansion: the reader has taken
## the panes into their own hands.
##
## SAVING IS PLAIN DATA: saved() is a Dictionary of strings and numbers that
## survives any text, and restore() takes one back only whole - a split it
## does not know, a share that is no fraction, a fold that is no side, and
## all of it is refused out loud and what stands kept (settings_file.gd),
## the shape it must have declared once (save_shape.gd).
##
## Deliberately absent: more than two panes to a split, and moving a pane to
## another split, which is docking.

## The one command a split's grip dispatches: {split, by, to}.
const RESIZES := &"resizes_a_panel"
## The two sides a split may fold, and neither.
const FIRST := &"first"
const SECOND := &"second"
const NEITHER := &""

var _splits := value({})  # split -> {"share": its first pane's share, "folded": FIRST, SECOND or NEITHER}
var _panes: Dictionary  # pane -> [its split, its side]
var _folds: Dictionary  # action -> the pane it folds and unfolds
var _expands: Dictionary  # action -> the pane it expands and brings back
var _shows: Dictionary  # action -> the pane it brings into view, wherever it was folded
var _expanded := value(&"")  # the pane expanded over the rest now, or none
var _before: Dictionary = {}  # split -> its fold before the expansion, to be put back


## The splits and the share each first pane starts at; the panes, each
## [split, side]; and the actions that fold a pane, that expand one, and
## that bring one into view.
func _init(chimes: Chimes, splits: Dictionary, panes: Dictionary, folds: Dictionary = {}, expands: Dictionary = {}, shows: Dictionary = {}) -> void:
	super(chimes, [], Chimes.GLOBAL)
	# every split, at the share it starts at and folded on neither side
	for split: StringName in splits:
		_splits.read()[split] = {"share": float(splits[split]), "folded": NEITHER}
	_panes = panes
	_folds = folds
	_expands = expands
	_shows = shows


## --- reads ---

## A split's first pane's share of its room, bound.
func share(split: StringName) -> Bound:
	return Bound.new(func() -> float: return _splits.read()[split]["share"])


## Which side of a split is folded away - FIRST, SECOND or NEITHER - bound.
func folded(split: StringName) -> Bound:
	return Bound.new(func() -> StringName: return _splits.read()[split]["folded"])


## Whether a pane is shown: no split on the way down to it folds its side.
func is_shown(pane: StringName) -> bool:
	return _way_to(pane).all(func(step: Array) -> bool: return _splits.read()[step[0]]["folded"] != step[1])


## Whether a pane is shown, bound: what a press folding it reads to say so.
func shown(pane: StringName) -> Bound:
	return Bound.new(func() -> bool: return is_shown(pane))


## The pane expanded over the rest now, or none.
func get_expanded() -> StringName:
	return _expanded.read()


## --- the commands ---

## A resize of a split there is none of is refused.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action == RESIZES and not _splits.read().has(StringName(payload["split"])):
		return Phrase.with("There is no split called %s", [payload["split"]])
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	if action == RESIZES:
		var split: Dictionary = _splits.read()[StringName(payload["split"])]
		# where the grip is being taken, or, from a grip whose split said no share, this far on from here
		split["share"] = clampf(float(payload["to"]) if payload.has("to") else split["share"] + float(payload["by"]), 0.0, 1.0)
		split["folded"] = NEITHER
		_expanded.set_value(&"")
	elif _folds.has(action):
		fold(_folds[action])
	elif _shows.has(action):
		bring_into_view(_shows[action])
	else:
		_expand(_expands[action])
	# the splits were changed in place: set again, for whatever reads them
	_splits.set_value(_splits.read())
	return null


## A pane folded away, or unfolded where it was folded: the one thing a
## reader's toggle does, said in words for whoever sets a layout up.
func fold(pane: StringName) -> void:
	var at: Array = _panes[pane]
	_splits.read()[at[0]]["folded"] = NEITHER if _splits.read()[at[0]]["folded"] == at[1] else at[1]
	_expanded.set_value(&"")
	_splits.set_value(_splits.read())


## A pane brought into view: every split on the way down that folds its side
## unfolded, and nothing else moved.
func bring_into_view(pane: StringName) -> void:
	# every split on the way down to the pane, unfolded where it folds the pane's side
	for step: Array in _way_to(pane):
		if _splits.read()[step[0]]["folded"] == step[1]:
			_splits.read()[step[0]]["folded"] = NEITHER
			_expanded.set_value(&"")
	_splits.set_value(_splits.read())


## A pane expanded - every split on the way down to it folding the side it is
## not on - or, expanded already, the folds it had before brought back.
func _expand(pane: StringName) -> void:
	if _expanded.read() == pane:
		# every split, its fold as it was before
		for split: StringName in _before:
			_splits.read()[split]["folded"] = _before[split]
		_expanded.set_value(&"")
		return
	if _expanded.read() == &"":
		_before = {}
		# every split, its fold now, to be put back
		for split: StringName in _splits.read():
			_before[split] = _splits.read()[split]["folded"]
	# every split on the way down, the other side folded
	for step: Array in _way_to(pane):
		_splits.read()[step[0]]["folded"] = SECOND if step[1] == FIRST else FIRST
	_expanded.set_value(pane)


## The way down to a pane, outermost last: [split, side] for every split it stands in.
func _way_to(pane: StringName) -> Array:
	var way: Array = []
	var at := pane
	# up from the pane, through each split that is itself a pane of another
	while _panes.has(at):
		way.append(_panes[at])
		at = _panes[at][0]
	return way


## --- saving, which is plain data ---

## Every split's share and fold, and the expansion, as strings and numbers.
func saved() -> Dictionary:
	var splits: Dictionary = {}
	# every split, as plain data
	for split: StringName in _splits.read():
		splits[String(split)] = {"share": _splits.read()[split]["share"], "folded": String(_splits.read()[split]["folded"])}
	var before: Dictionary = {}
	# every fold to be put back after an expansion, as plain data
	for split: StringName in _before:
		before[String(split)] = String(_before[split])
	return {"splits": splits, "expanded": String(_expanded.read()), "before": before}


## The panels read back from a save, whole; what is not a save of these
## panels is said out loud, and the panels as they stand are kept.
func restore(save: Dictionary) -> void:
	if SaveShape.refused(_save_shape(), save, "these panels"):
		return
	# every split the save holds, its share and its fold
	for split: String in save["splits"]:
		_splits.read()[StringName(split)] = {"share": float(save["splits"][split]["share"]), "folded": StringName(save["splits"][split]["folded"])}
	_expanded.set_value(StringName(save["expanded"]))
	_before = {}
	# every fold to be put back, as the save kept it
	for split: String in save["before"]:
		_before[StringName(split)] = StringName(save["before"][split])
	# the splits were changed in place: set again, for whatever reads them
	_splits.set_value(_splits.read())


## The shape a save of these panels has (save_shape.gd): every split one
## there is, its share a fraction and its fold a side; the pane expanded,
## none or one of the panes; every fold to be put back, a split's side.
func _save_shape() -> Callable:
	var sides := SaveShape.one_of([String(FIRST), String(SECOND), String(NEITHER)])
	var splits := SaveShape.one_of(_splits.read().keys().map(func(split: StringName) -> String: return String(split)))
	return SaveShape.record({
		"splits": SaveShape.keyed(splits, SaveShape.record({"share": SaveShape.fraction(), "folded": sides})),
		"expanded": SaveShape.one_of([""] + _panes.keys().map(func(pane: StringName) -> String: return String(pane))),
		"before": SaveShape.keyed(splits, sides),
	})


## Every action this model is told: resizing, and the one each pane it was
## given folds, expands or is brought into view by.
func answers() -> Array[StringName]:
	var told: Array[StringName] = [RESIZES]
	told.assign(told + _folds.keys() + _expands.keys() + _shows.keys())
	return told
