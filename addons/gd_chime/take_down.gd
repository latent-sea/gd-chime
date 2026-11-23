extends RefCounted

## An application let go while everything else goes on: what it built freed a
## share of a frame at a time, then the node itself (chime_app.gd, let_go).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## LEAVING THE TREE FREES EVERYTHING AN APP BUILT IN ONE FRAME, and on a slow
## machine a big app's one frame is long: 4491 nodes of one screen took 175 ms
## to free, the whole app about 300 ms (measured on a software-drawn desk, 23
## Nov). Taken down here, nothing freed in one go holds more than BOUND nodes,
## and each frame frees until its share is spent.
##
## EVERY PIECE IS TAKEN OUT OF THE TREE BEFORE ANY OF IT IS FREED, under the
## same share of each frame: a part freed in the tree has its holder lay out
## again, and a screen's plan laid out again with its parts half gone cost
## 850 ms in one frame there, and indexed parts no longer there.
##
## THE ORDER IS LEAVING'S: the pieces built, newest first, so what was built
## over a model goes before the model it tells; within a piece, the deepest
## first, so a node is freed once what stands under it is gone or small. The
## app's pool is stopped first, its running tasks waited out, as leaving does,
## and stays with the app, which stops it again as it leaves.
##
## NOTHING IT BUILT HEARS A BELL AGAIN from the moment it is let go: every
## node's wires are cut at once, in the one walk that orders the freeing. A
## model following where the reader is would otherwise be told of every place
## leaving and read a screen half gone, as a frame's freeing never let it.
##
## The app is expected hidden and stopped by whoever lets it go: it is not
## drawn or laid out the frames it is taken down, so nothing is drawn half gone.

## The most nodes freed in one go: about 10 ms of freeing on that slow machine.
const BOUND := 250


## `app`, with the pieces it built under `canvas`, its pool `jobs` and its `chimes`: cut from its bells now, then taken
## down `budget_msec` of a frame at a time, and freed.
static func over_frames(app: Node, canvas: Node, jobs: Node, chimes: RefCounted, budget_msec: float) -> void:
	jobs.stop()
	var tree := app.get_tree()
	var order: Array[Node] = []
	var built := canvas.get_children().filter(func(piece: Node) -> bool: return piece != jobs)
	built.reverse()
	# each piece built, newest first, cut from its bells and put in the order its parts are freed in
	for piece: Node in built:
		_ordered(piece, order, chimes)
	var out := 0
	# a frame at a time: pieces taken out of the tree, newest first, until the frame's share is spent
	while out < built.size():
		var began := Time.get_ticks_usec()
		# each piece in turn while the share lasts
		while out < built.size() and Time.get_ticks_usec() - began < budget_msec * 1000.0:
			canvas.remove_child(built[out])
			out += 1
		await tree.process_frame
	var at := 0
	# a frame at a time: parts freed in order until the frame's share is spent
	while at < order.size():
		var began := Time.get_ticks_usec()
		# each part in turn while the share lasts; one freed by another part as it went is already gone
		while at < order.size() and Time.get_ticks_usec() - began < budget_msec * 1000.0:
			if is_instance_valid(order[at]):
				order[at].free()
			at += 1
		await tree.process_frame
	app.queue_free()


## `node` cut from `chimes` and put in `order` to be freed in one go where it holds BOUND nodes or fewer, and otherwise
## each part under it first, newest first, then itself: the nodes it holds, itself counted.
static func _ordered(node: Node, order: Array[Node], chimes: RefCounted) -> int:
	chimes.stop_all(node)
	var from := order.size()
	var held := 1
	var under := node.get_children()
	under.reverse()
	# each child, newest first, its own parts cut, put in order and counted
	for child: Node in under:
		held += _ordered(child, order, chimes)
	# small enough to go in one: what was put in order under it is dropped, as freeing it frees them
	if held <= BOUND:
		order.resize(from)
	order.append(node)
	return held
