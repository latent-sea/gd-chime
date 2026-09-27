extends SceneTree

## What must be true of a region map and the drawing it pins its presses
## on: a point of the unit square lies in the region whose outline holds
## it; each region is shaded by its share of the most; the square is fitted,
## never stretched, and a part stands on its point inside the drawing; every
## region's press stands on its region, carries its key, and the keys walk
## to every one of them; a press on a region's ground picks it and one on
## empty ground picks nothing; the one picked is current; and it shows
## loading until its values land, then stands with nothing to shade.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_region_map.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Pinned := preload("res://addons/gd_chime/components/primitives/pinned.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const RegionMap := preload("res://addons/gd_chime/components/recipes/region_map.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const PICKS := &"picks_a_region"
## Three regions: the west half, the north-east quarter, and a south-east triangle, leaving the far corner empty ground.
const REGIONS := [
	{"key": "West", "outline": [Vector2(0.0, 0.0), Vector2(0.5, 0.0), Vector2(0.5, 1.0), Vector2(0.0, 1.0)], "pin": Vector2(0.25, 0.5)},
	{"key": "North East", "outline": [Vector2(0.5, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 0.5), Vector2(0.5, 0.5)], "pin": Vector2(0.75, 0.25)},
	{"key": "South East", "outline": [Vector2(0.5, 0.5), Vector2(1.0, 0.5), Vector2(0.5, 1.0)], "pin": Vector2(0.65, 0.65)},
]
const VALUES := [{"key": "North East", "now": 40.0}, {"key": "South East", "now": 10.0}, {"key": "West", "now": 20.0}]

var _verdict := Verdict.new()


## A dashboard's reads, for one map.
class Board extends Fixture.Model:
	func get_shaded() -> Variant:
		return of(&"shaded").read()

	func get_picked() -> Variant:
		return of(&"picked").read()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(900, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_point_lies_in_the_region_whose_outline_holds_it)
	await _verdict.states(_each_region_is_shaded_by_its_share_of_the_most)
	await _verdict.states(_the_square_is_fitted_never_stretched_and_a_part_stands_on_its_point_inside)
	await _verdict.states(_every_regions_press_stands_on_it_carries_its_key_and_the_keys_reach_every_one)
	await _verdict.states(_a_press_on_a_regions_ground_picks_it_and_on_empty_ground_nothing)
	await _verdict.states(_it_shows_loading_until_its_values_land_and_then_stands_with_nothing_to_shade)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A map over a board, built and started: [the fixture, the board, the map's drawing].
func _map(values: Variant) -> Array:
	var made := Fixture.new(root, {PICKS: "pick the region"})
	var ui := made.ui
	var board := Board.new(made.chimes, &"app")
	board.set_value(&"shaded", values)
	board.set_value(&"picked", &"")
	var map := RegionMap.make(ui, PICKS, REGIONS, Bound.new(board.get_shaded), {picked = Bound.new(board.get_picked), says = Phrase.of("darker: more customers without service"), says_empty = Phrase.of("nobody is without service")})
	made.commands.register(&"app", PICKS, board)
	ui.start(ui.app(&"app", [ui.column([map.grow()]).named(&"map")]))
	await _a_frame_passes()
	return [made, board, ui.node_named(&"map")]


func _done(both: Array) -> void:
	(both[1] as Node).free()
	(both[0] as Fixture).done()


func _drawing(both: Array) -> Pinned:
	var found: Array = (both[2] as Node).find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pinned)
	return found[0] if not found.is_empty() else null


func _pins(both: Array) -> Array:
	return (both[2] as Node).find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)


func _shown(node: Node) -> Array[String]:
	var found: Array[String] = []
	# every text under it that is drawn
	for text: Node in node.find_children("*", "Control", true, false):
		if text is Text and (text as Text).is_visible_in_tree() and (text as Text).get_text() != "":
			found.append((text as Text).get_text())
	return found


func _a_point_lies_in_the_region_whose_outline_holds_it() -> void:
	var found: Array = [Vector2(0.1, 0.9), Vector2(0.9, 0.1), Vector2(0.6, 0.6), Vector2(0.95, 0.95)].map(func(at: Vector2) -> Variant: return RegionMap.region_at(REGIONS, at))
	_verdict.check(found == ["West", "North East", "South East", null], "each point is in the region that holds it, and the far corner in none: %s" % [found])


func _each_region_is_shaded_by_its_share_of_the_most() -> void:
	var shades: Dictionary = RegionMap.shading(VALUES, "West")
	_verdict.check(shades["shares"] == {"North East": 1.0, "South East": 0.25, "West": 0.5} and shades["picked"] == "West" and not shades["empty"], "the most affected is the whole shade, the rest their share of it: %s" % [shades])
	var none: Dictionary = RegionMap.shading(VALUES.map(func(one: Dictionary) -> Dictionary: return {"key": one["key"], "now": 0.0}), "")
	_verdict.check(none["empty"] and none["shares"].values().all(func(share: float) -> bool: return share == 0.0), "with nothing anywhere, every share is none and it says it is empty")
	_verdict.check(RegionMap.shading(null, "") == null, "and nothing is shaded before the values land")


func _the_square_is_fitted_never_stretched_and_a_part_stands_on_its_point_inside() -> void:
	_verdict.check(Pinned.fitted(Vector2(800, 400)) == Rect2(200, 0, 400, 400) and Pinned.fitted(Vector2(300, 500)) == Rect2(0, 100, 300, 300), "the unit square is the largest square the drawing holds, in its middle, however wide or tall")
	var middle := Pinned.standing(Vector2(0.5, 0.5), Vector2(40, 20), Vector2(400, 400))
	var corner := Pinned.standing(Vector2(1.0, 1.0), Vector2(40, 20), Vector2(400, 400))
	_verdict.check(middle == Rect2(180, 190, 40, 20) and corner == Rect2(360, 380, 40, 20), "a part stands with its middle on its point, moved in where it would cross the edge: %s, %s" % [middle, corner])


func _every_regions_press_stands_on_it_carries_its_key_and_the_keys_reach_every_one() -> void:
	var both: Array = await _map(VALUES)
	var drawing := _drawing(both)
	var pins := _pins(both)
	var square := Pinned.fitted(drawing.size)
	var on_own: Array = pins.map(func(pin: Pressable) -> Variant: return RegionMap.region_at(REGIONS, (pin.get_global_rect().get_center() - drawing.get_global_rect().position - square.position) / square.size))
	_verdict.check(pins.size() == 3 and on_own == ["West", "North East", "South East"] and pins.map(func(pin: Pressable) -> Dictionary: return pin.payload()) == [{"picked": "West"}, {"picked": "North East"}, {"picked": "South East"}], "each region's press stands on its own region and carries its key: %s" % [on_own])
	_verdict.check(DrawnOver.covered(root, root.get_visible_rect()).is_empty(), "and nothing is drawn over anything: %s" % [DrawnOver.covered(root, root.get_visible_rect())])
	var reached: Dictionary = {pins[0]: true}
	var waiting: Array = [pins[0]]
	# from every press reached, each way the keys go, until nothing new is reached
	while not waiting.is_empty():
		var from: Control = waiting.pop_back()
		# every side, the press the keys would walk to
		for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var to: Control = from.find_valid_focus_neighbor(side)
			if to != null and pins.has(to) and not reached.has(to):
				reached[to] = true
				waiting.append(to)
	_verdict.check(reached.size() == 3, "the keys walk from the first press to every region's: %d of 3" % reached.size())
	(both[1] as Board).set_value(&"picked", "South East")
	await _a_frame_passes()
	_verdict.check(pins.map(func(pin: Pressable) -> bool: return pin.is_current()) == [false, false, true], "the region picked has its press current, the rest not")
	_done(both)


func _a_press_on_a_regions_ground_picks_it_and_on_empty_ground_nothing() -> void:
	var both: Array = await _map(VALUES)
	var drawing := _drawing(both)
	var square := Pinned.fitted(drawing.size)
	var press := func(at: Vector2) -> void:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = square.position + at * square.size
		drawing._gui_input(click)
	press.call(Vector2(0.9, 0.1))
	_verdict.check((both[1] as Board).told_actions == [PICKS] and (both[0] as Fixture).commands.get_last()["payload"] == {"picked": "North East"}, "a press on the north-east's ground picks it, as its own press would: %s" % [(both[0] as Fixture).commands.get_last()["payload"]])
	press.call(Vector2(0.95, 0.95))
	_verdict.check((both[1] as Board).told_actions.size() == 1, "a press on empty ground picks nothing")
	_done(both)


func _it_shows_loading_until_its_values_land_and_then_stands_with_nothing_to_shade() -> void:
	var both: Array = await _map(null)
	_verdict.check(_shown(both[2]) == ["Loading"] and _drawing(both) == null, "before its values land it says loading and no map stands: %s" % [_shown(both[2])])
	(both[1] as Board).set_value(&"shaded", VALUES.map(func(one: Dictionary) -> Dictionary: return {"key": one["key"], "now": 0.0}))
	await _a_frame_passes()
	_verdict.check(_drawing(both) != null and _pins(both).size() == 3 and _shown(both[2]).has("nobody is without service"), "landed with nothing to shade, the map still stands to be pressed, and says so: %s" % [_shown(both[2])])
	(both[1] as Board).set_value(&"shaded", VALUES)
	await _a_frame_passes()
	_verdict.check(_shown(both[2]).has("darker: more customers without service"), "with something to shade, it says what the shade means")
	_done(both)
