extends "scroll.gd"

## The body of a table in frozen panes (frozen_panes.gd): a scroll either
## way, whose offset the heads follow across and the labels follow down, so
## a heading always stands over its column and a label beside its row.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS THE ONE THAT MOVES. The heads and the labels never scroll of
## themselves: whatever moves any pane moves this, and each time this is
## placed as it scrolls it places the heads' part at its own content's
## offset across and the labels' part at its offset down. Nothing else is
## kept, so the three cannot disagree.
##
## THE HEADS AND THE LABELS STAND IN PANES ALIGNED WITH IT - the heads' pane
## starts where it starts across, the labels' where it starts down - so the
## offset of what it holds within itself is the offset of their parts within
## theirs, its padding included.
##
## WHAT MOVES IT FROM ANOTHER PANE: a wheel or a pad's pan there, by the
## engine's own step, an eighth of its room a notch, said to have moved it
## only where it did, so a table at its end lets the page holding it go on;
## and the pad or the keys walking onto a heading or a label out of sight,
## by the least move that shows it whole. A finger there is handed to it by
## the table (touch.gd).
##
## Everything else is a scroll's (scroll.gd): the indicator down, the
## finger, the offset kept with the view, the focus inside it shown whole.
## Drawn whole down, it scrolls across alone and is as tall as its rows.

## The engine's wheel: which way a notch moves it, by button.
const NOTCHES := {MOUSE_BUTTON_WHEEL_UP: Vector2.UP, MOUSE_BUTTON_WHEEL_DOWN: Vector2.DOWN, MOUSE_BUTTON_WHEEL_LEFT: Vector2.LEFT, MOUSE_BUTTON_WHEEL_RIGHT: Vector2.RIGHT}
## How much of its room one notch moves it, as the engine's scroll does.
const NOTCH := 1.0 / 8.0

var _heads: Control  # the pane the heads stand in, following across
var _labels: Control  # the pane the labels stand in, following down


func _init(ui: RefCounted, nudged: Variant, heads: Control, labels: Control, whole_down: bool) -> void:
	super(ui, null, EITHER_WAY, nudged, &"Scroll")
	_heads = heads
	_labels = labels
	# drawn whole down, the engine asks what it holds for its height and never scrolls that way
	if whole_down:
		vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		keep_in_step()


## Which ways a pane standing beside this moves what it holds to follow it -
## across, then down: the heads across, the labels down, any other neither.
func follows(pane: Control) -> Array:
	return [pane == _heads, pane == _labels]


## The heads' part placed at the offset across of what this holds, and the
## labels' part at its offset down: run each time this is placed, which it
## is as it scrolls.
func keep_in_step() -> void:
	var at: Vector2 = (get_child(0) as Control).position
	# the one part the heads' pane holds, once it is built
	for held: Node in _heads.get_children():
		(held as Control).position.x = at.x
	# the one part the labels' pane holds, once it is built
	for held: Node in _labels.get_children():
		(held as Control).position.y = at.y


## A wheel or a pad's pan on another pane: this moved by it, and whether it moved.
func moved_by(event: InputEvent) -> bool:
	var page := Vector2(get_h_scroll_bar().page, get_v_scroll_bar().page)
	var by := Vector2.ZERO
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and NOTCHES.has((event as InputEventMouseButton).button_index):
		var wheel := event as InputEventMouseButton
		var way: Vector2 = NOTCHES[wheel.button_index]
		# shift turns a notch down into a notch across, as it does on the engine's scroll
		way = Vector2(way.y, way.x) if wheel.shift_pressed else way
		by = way * page * NOTCH * wheel.factor
	if event is InputEventPanGesture:
		by = (event as InputEventPanGesture).delta * page * NOTCH
	var was := Vector2(scroll_horizontal, scroll_vertical)
	get_h_scroll_bar().value += by.x
	get_v_scroll_bar().value += by.y
	return Vector2(scroll_horizontal, scroll_vertical) != was


## A piece in the heads or the labels brought wholly into the pane it stands
## in, by the least move of this that does it, its start shown where it is
## longer than the pane.
func show_whole(piece: Control, pane: Control) -> void:
	var shown := pane.get_global_rect()
	var wanted := piece.get_global_rect()
	# past the far edge, on by the overhang; then before the near edge, back by the shortfall
	var by := (wanted.end - shown.end).max(Vector2.ZERO)
	by += (wanted.position - by - shown.position).min(Vector2.ZERO)
	get_h_scroll_bar().value += by.x
	get_v_scroll_bar().value += by.y
