extends Container

const Themes := preload("theme.gd")
const Shift := preload("components/primitives/shift.gd")

## The surface every application stands on: the look's ground painted across
## the whole of the easel's rect, and every piece standing on it - the app,
## each pop-up lifted beside it, the window's shape - laid exactly in the
## safe rect.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE GROUND IS THE WHOLE RECT; WHAT STANDS ON IT IS THE SAFE RECT. The
## easel (easel.gd) says how far in from each edge is safe (safe_area.gd),
## and this lays each Control standing on it in what is left - again whenever
## that moves, its own size does, or a piece's needs do - as every holder
## places a piece (shift.gd), so one scaling or sliding in keeps the motion
## it has reached. So the band round the edge - a cutout, a corner's arc, the
## gutter - shows the ground and nothing else. The ground is drawn again
## whenever the look changes.
##
## IT ASKS FOR NOTHING: its least is zero whatever stands on it, so nothing
## on it can make the canvas, the viewport or the window larger. A piece that
## needs more than the safe rect is grown past it by the engine, which no
## container can refuse; that is said out loud, once for each piece, naming
## it, since what it draws past the rect is cut off at the window's edge.
##
## IT SAYS WHAT IT DRAWS as a face does (get_drawn), so whatever judges words
## against the ground they stand on (faint_words.gd) reads the canvas's
## ground and never the window's clear colour, which is the host's and says
## nothing of the app.
##
## Deliberately absent: a shade in the band. A pop-up is laid in the safe rect
## with its shade, so while one is up the band round it stays the ground.

var _ground := StyleBoxFlat.new()  # the one box drawn across the whole canvas, the look's ground
var _insets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])  # how far in from each edge is safe, in base pixels, by Side
var _said: Dictionary = {}  # instance id -> true, for each piece already said to need more than the safe rect


func _init() -> void:
	# a press on bare ground is the app's and goes no further, as on any control
	mouse_filter = Control.MOUSE_FILTER_STOP


## How far in from each edge is safe, in base pixels by Side: every piece laid again in what is left.
func set_insets(insets: PackedFloat32Array) -> void:
	_insets = insets
	queue_sort()


## The safe rect, on this canvas: its whole rect less the insets.
func get_safe() -> Rect2:
	return Rect2(_insets[SIDE_LEFT], _insets[SIDE_TOP], size.x - _insets[SIDE_LEFT] - _insets[SIDE_RIGHT], size.y - _insets[SIDE_TOP] - _insets[SIDE_BOTTOM])


func _draw() -> void:
	if has_theme_color(&"ground", Themes.LOOK):
		_ground.bg_color = get_theme_color(&"ground", Themes.LOOK)
		draw_style_box(_ground, Rect2(Vector2.ZERO, size))


## The boxes drawn across the whole of this: the ground, where the look gives one.
func get_drawn() -> Array[StyleBox]:
	var drawn: Array[StyleBox] = []
	if has_theme_color(&"ground", Themes.LOOK):
		_ground.bg_color = get_theme_color(&"ground", Themes.LOOK)
		drawn.append(_ground)
	return drawn


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()
	elif what == NOTIFICATION_SORT_CHILDREN:
		var safe := get_safe()
		# every Control standing on the canvas, laid in the safe rect; the models beside them draw nothing and are left
		for piece: Node in get_children():
			if not piece is Control or (piece as Control).top_level:
				continue
			Shift.fit(self, piece as Control, safe)
			var least := (piece as Control).get_combined_minimum_size()
			# needing more than the safe rect either way, and not said before
			if (least.x > safe.size.x or least.y > safe.size.y) and not _said.has(piece.get_instance_id()):
				_said[piece.get_instance_id()] = true
				push_error("%s needs %s, more than the safe room of %s, and is drawn past its edge: something inside it asks for more room than the window has" % [piece.get_path(), least, safe.size])
