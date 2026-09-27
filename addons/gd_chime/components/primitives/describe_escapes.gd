extends "describe.gd"

## The two ways out of the described world: a subtree wearing a look of its
## own, and a Control the framework did not build, standing inline among
## ones it did.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Everything else in the vocabulary says WHAT a piece is and lets the look
## on the root say how it is drawn. These two are for the cases that rule
## cannot cover: a part of a screen in another design language - a preview
## of a look, a game's own panel inside a tool - and a node the engine draws
## that no primitive of ours wraps.
##
## THEY ARE THE EXCEPTION AND SHOULD STAY RARE. A screen reaching for embed
## rather than a description is one whose piece the framework is missing,
## and a look wanted on the whole window is the root's theme, not a themed
## subtree around everything.


## A subtree drawn in this Theme rather than the root's: the theme is set on
## the piece holding the content, and the engine carries it down to
## everything inside, so a look put on the root afterwards re-dresses what
## is outside and nothing in.
func themed(look: Theme, content: Array) -> Desc:
	return Desc.new(&"themed", {"theme": look}, content)


## A Control built by hand, placed here as a part: it takes its facts -
## grow, basis - as any part does. The node is the caller's, so a piece
## that is built again hands a fresh one each time.
func embed(control: Control) -> Desc:
	return Desc.new(&"embed", {"control": control})
