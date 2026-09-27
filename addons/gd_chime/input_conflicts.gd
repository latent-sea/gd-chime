extends RefCounted

const Paths := preload("paths.gd")

## Two actions on one input that the player could be offered at the same
## moment: found over the chart, and said out loud.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Bound that way, one of the two can never be pressed by that input and
## nothing would say why - the map answers with the action declared first
## (input_map.gd) and the other is simply dead. It is a mistake in how the
## application was composed, so it is reported and never mended here: which of
## the two should keep the input is nobody's guess but the author's.
##
## CAN BE REACHED AT ONCE IS A QUESTION OVER THE CHART, NOT A GUESS. A
## shortcut is looked for on the path of the layer that takes input, which
## runs from a layer root straight down, so two actions can be offered
## together exactly when a place declaring the one and a place declaring the
## other lie on a single such path - one within the other. Two tabs of one
## stack are siblings, never both on top, and are therefore no conflict
## however alike their inputs; a screen and a tab inside it are.
##
## Pure: the bindings, the chart, what each place declares and a way to say an
## input in words, in; sentences pushed as errors, out. No tree, no state, no
## driver. The words come in as a function because the map that knows them
## reads this, and nothing may read back the other way.


## Every pair of actions on one input that can be reached at once, one
## sentence each, the input in words.
static func report(bound: Dictionary, chart: Dictionary, performs: Dictionary, names: Callable) -> void:
	var on: Dictionary = {}  # input -> the actions on it, in the order declared
	# every action with an input, gathered under the input it is on
	for action: StringName in bound:
		for input: Dictionary in bound[action]:
			on[input] = (on[input] if on.has(input) else []) + [action]
	# every input, each pair of actions on it that could be offered at one moment
	for input: Dictionary in on:
		var actions: Array = on[input]
		for first: int in range(actions.size()):
			for second: int in range(first + 1, actions.size()):
				if together(chart, performs, actions[first], actions[second]):
					push_error("%s and %s are both on %s and can be reached at once" % [actions[first], actions[second], names.call(input)])


## Whether a place declaring the one action and a place declaring the other
## can be on one path from a layer root down.
static func together(chart: Dictionary, performs: Dictionary, first: StringName, second: StringName) -> bool:
	# every place declaring the first, against every place declaring the second
	for here: StringName in performs:
		if not (performs[here] as Dictionary).has(first):
			continue
		for there: StringName in performs:
			if (performs[there] as Dictionary).has(second) and _one_path(chart, here, there):
				return true
	return false


static func _one_path(chart: Dictionary, here: StringName, there: StringName) -> bool:
	return Paths.path_to(chart, here).has(there) or Paths.path_to(chart, there).has(here)
