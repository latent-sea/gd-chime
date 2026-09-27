extends "describe_inputs.gd"

## The descriptions a form of many steps needs beyond what the reader types:
## where the focus lands as a place is arrived at, and a file picked.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's and describe_inputs.gd's,
## which this extends; describe_shell.gd extends this, describe_places.gd
## that, and the builder (ui.gd) that in turn. These stand apart because a
## form leans on them - a problem taking the reader to its question - but
## none is a form's alone: any place may send the reader to a piece of it.


## What it holds takes the focus as its place is arrived at, while this
## bound value holds (arrival_focus.gd): a question entered as its key.
func arrival_focus(holds: Bound, content: Array) -> Desc:
	return Desc.new(&"arrival_focus", {"holds": holds}, content)


## A press opening a file dialog offering these kinds - file endings - the
## file picked dispatched as the action with {"value": {name, size, kind}}
## (file_pick.gd), one its place declares.
func file_pick(action: StringName, kinds: Array, content: Array = [], style: Variant = &"BellButton") -> Desc:
	return Desc.new(&"file_pick", {"action": action, "kinds": kinds, "style": style}, content)
