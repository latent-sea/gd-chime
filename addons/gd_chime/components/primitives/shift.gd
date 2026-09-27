extends Node

## A shift: how far a control is drawn from where its layout put it, while
## it slides in or out or travels from its old place to its new one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A layout owns its children's positions and sets them whenever it sorts,
## so a thing that must be seen somewhere else for a while cannot simply
## be moved: the next sort would put it back. This rides on the control as
## an INTERNAL child - no layout and no walk of its content sees it - and
## holds where the layout last put its host, the REST; the host is drawn
## at the rest plus the shift. THE REST IS NEVER TAKEN ON TRUST. Whatever
## places the host - a layout sorting, anchors following a holder resized -
## writes its position outright, so a position that is not the one this
## last wrote is a new rest, and is taken as one before anything is drawn:
## a slide that ends after the layout moved ends where the layout put it.
## A holder that arranges its children tells the shifts on them as its sort
## ends - placed() - so the shift is back on within the frame and the host
## is never seen at its bare rest mid-way; an each does, and a when. It
## connects nothing.
##
## EVERY HOLDER PLACES A PIECE THROUGH fit(), which keeps what the piece's
## own motion has reached: the engine's fitting sets a control's scale and
## turn back to none, so a sheet scaling in, or a track turning, placed
## again mid-way would be drawn whole for a frame and then jump back.
## The shift is two parts, each a value a run on the one clock hands in: a
## SLIDE, in the host's own sizes - one across is its whole width, so a
## slide from a side needs no size known in advance - and a CARRY, in
## pixels, the way left to travel from an old place. Both at nothing, the
## host is exactly where its layout put it, and stays there.

var _rest: Vector2
var _slide: Vector2 = Vector2.ZERO
var _carry: Vector2 = Vector2.ZERO
var _wrote: Vector2  # the position this last gave its host: any other is something else's, and a new rest


## A piece put in its rect by the holder that places it, at the scale and
## turn its motion has reached, and the shift on it, if it has one, told -
## unless the holder tells its shifts itself once its sort is done, as an
## each does after working out how far each part has to travel.
static func fit(holder: Container, piece: Control, rect: Rect2, tells: bool = true) -> void:
	var scaled := piece.scale
	var turned := piece.rotation
	holder.fit_child_in_rect(piece, rect)
	piece.scale = scaled
	piece.rotation = turned
	if tells and piece.has_node(^"Shift"):
		piece.get_node(^"Shift").placed()


## The shift riding on this control, made the first time it is asked for.
static func of(host: Control) -> Node:
	var found: Node = host.get_node_or_null(^"Shift")
	if found == null:
		found = new()
		found.name = &"Shift"
		host.add_child(found, false, Node.INTERNAL_MODE_BACK)
	return found


func _enter_tree() -> void:
	_rest = (get_parent() as Control).position
	_wrote = _rest


## How far it is slid, in its own sizes.
func slide(by: Vector2) -> void:
	_slide = by
	_draw_there()


## How far it has yet to travel, in pixels.
func carry(by: Vector2) -> void:
	_carry = by
	_draw_there()


## The way it has to travel, said while its holder is placing it: drawn as the placing ends.
func owe(by: Vector2) -> void:
	_carry = by


## The way it still has to travel now.
func get_carry() -> Vector2:
	return _carry


## The holder has arranged: whatever it wrote is the rest, and the shift is put back on it.
func placed() -> void:
	_draw_there()


func _draw_there() -> void:
	var host: Control = get_parent()
	if host.position != _wrote:
		_rest = host.position
	_wrote = _rest + _slide * host.size + _carry
	host.position = _wrote
