extends RefCounted

## A Control the framework did not build, placed inline among ones it did:
## the escape hatch. Whatever the engine draws that no primitive of ours
## wraps - a viewport, a third party's widget, a node a game already has -
## stands in a row or a column beside described pieces, taking its facts
## (grow, basis) as any part does.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT MAKES NOTHING: the Control is the caller's, handed in already built,
## and this only attaches it where the description put it. So it is the one
## description whose answer holds a node rather than what to make - which
## is why a piece that is built again (a when swapping, an each on its
## bell) must hand a fresh Control each time: the same node cannot stand in
## two places, and the second build would take it out of the first.
##
## ui.also is the full-window counterpart and stays what it is: a node put
## under the root, across the whole window, outside any layout. This one is
## inline, among parts, and placed by the line it is in.


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = desc.props["control"]
	ui.attach(made, parent, desc.facts)
	return made
