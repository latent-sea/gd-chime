extends SceneTree

## What must be true of a long session: nothing the framework keeps grows
## with how long it has run, only with what stands now.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_nothing_grows.gd
##
## Proved here: a keyed list whose keys come and go holds a bell and a name
## for the keys it shows and no others; the builder's names let go of pieces
## freed, and a name read after its piece is freed is nothing, never the
## freed piece; a model with a region of its own takes the region with it
## when freed; and taking a region's wires down costs the wires it cuts,
## however many others are held.
##
## The counts are read from the private records they are about - the
## belfry's, the builder's, the reads' - since how much is held is the
## property, and nothing public answers it.

const Fixture := preload("res://tests/fixture.gd")
const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Controller := preload("res://addons/gd_chime/controller.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Each := preload("res://addons/gd_chime/components/primitives/each.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


## A listener that belongs to no region and does nothing with what it hears.
class Ear extends RefCounted:
	var region: StringName = &""

	func heard(_what: StringName) -> void:
		pass


## Keeps what the engine was told to say, so a complaint is something a test can read.
class Complaints extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _traces: Array[ScriptBacktrace]) -> void:
		said.append(code if rationale.is_empty() else rationale)


## A model with a region of its own and a bell hung there, as a long list has.
class Lister extends Controller:
	const LANDED := &"landed"

	func _init(chimes: Chimes) -> void:
		super(chimes, [], own_region("lister"))
		register_bell(LANDED)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_keyed_list_holds_a_bell_and_a_name_only_for_the_keys_it_shows)
	await _verdict.states(_the_builders_names_let_go_of_pieces_freed)
	await _verdict.states(_a_model_with_a_region_of_its_own_takes_it_when_freed)
	await _verdict.states(_taking_a_regions_wires_down_costs_the_wires_it_cuts)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## Twenty crates a round, every round new ones: after each of five rounds the
## list holds a bell, an address and a name for the twenty it shows.
func _a_keyed_list_holds_a_bell_and_a_name_only_for_the_keys_it_shows() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var stock := Fixture.Model.new(made.chimes)
	ui.also(stock)
	stock.set_value(&"items", [])
	var crates: Each = ui.build(ui.each(stock.of(&"items"), func(crate: Bound) -> Desc: return ui.text(crate.field("name")), func(crate: Dictionary) -> int: return crate["id"]).pieces_named(&"crate "), root)
	var held: Array = []
	# five rounds of twenty crates, none of them seen before
	for round: int in 5:
		var round_of: Array = []
		# twenty crates numbered for this round
		for one: int in 20:
			round_of.append({"id": round * 100 + one, "name": "crate %d" % (round * 100 + one)})
		stock.set_value(&"items", round_of)
		await _a_frame_passes()
		var region: StringName = crates._region
		var names: int = ui._named.keys().filter(func(id: StringName) -> bool: return String(id).begins_with("crate ")).size()
		held.append([made.chimes._belfry._held.get(region, {}).size(), crates._hung.size(), Reads._addresses.get(region, {}).size(), names])
	_verdict.check(held.all(func(counts: Array) -> bool: return counts == [20, 20, 20, 20]), "each round it holds a bell, a hung name, an address and a piece's name for the twenty crates it shows, and none for those gone: %s" % [held])
	_verdict.check(typeof(ui.node_named(&"crate 3")) == TYPE_NIL and ui.node_named(&"crate 403") != null, "a crate gone has no name, and one shown has: %s" % [type_string(typeof(ui.node_named(&"crate 3")))])
	crates.free()
	made.done()


## Five hundred pieces built under names of their own and freed: the names
## held stay near what stands, and a freed piece's name reads as nothing.
func _the_builders_names_let_go_of_pieces_freed() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var standing: Array = []
	# five hundred pieces, each named once and freed while the next stands
	for one: int in 500:
		var piece: Control = ui.build(ui.text("a crate").named(StringName("piece %d" % one)), root)
		standing.append(piece)
		if standing.size() > 3:
			standing.pop_front().free()
	# the newest piece freed just now, before any sweep could reach its name
	standing.pop_back().free()
	var complaints := Complaints.new()
	OS.add_logger(complaints)
	var found: Variant = ui.node_named(&"piece 499")
	OS.remove_logger(complaints)
	_verdict.check(typeof(found) == TYPE_NIL and complaints.said.is_empty(), "a piece's name read the moment it is freed reads as nothing, never the freed piece, and nothing complains: %s" % [complaints.said])
	_verdict.check(ui._named.size() < 200, "and the names held stay near the four that stand, not the five hundred made: %d" % ui._named.size())
	# the pieces still standing, freed with the test
	for piece: Control in standing:
		piece.free()
	made.done()


## A model hanging a bell in a region of its own, freed: the region goes too.
func _a_model_with_a_region_of_its_own_takes_it_when_freed() -> void:
	var made := Fixture.new(root)
	var lister := Lister.new(made.chimes)
	var region := lister.region
	var standing: bool = made.chimes._belfry.has(region, Lister.LANDED)
	lister.free()
	_verdict.check(standing and not made.chimes._belfry.has(region, Lister.LANDED) and not Reads._addresses.has(region), "its bell stood while it did, and its region went as it was freed: %s" % [Reads._addresses.get(region)])
	made.done()


## Twenty thousand wires held at one bell and one at another: taking the
## second's region down costs its one wire, not a walk of the twenty
## thousand - a small share of what taking the first's down does.
func _taking_a_regions_wires_down_costs_the_wires_it_cuts() -> void:
	var chimes := Chimes.new(Belfry.new())
	chimes.register(&"busy", &"ring")
	chimes.register(&"quiet", &"ring")
	var ears: Array = []
	# twenty thousand listeners on the busy bell
	for one: int in 20000:
		var ear := Ear.new()
		ears.append(ear)
		chimes.listen(ear, &"busy", &"ring")
	chimes.listen(Ear.new(), &"quiet", &"ring")
	var started := Time.get_ticks_usec()
	chimes.drop_region(&"quiet")
	var quiet := Time.get_ticks_usec() - started
	started = Time.get_ticks_usec()
	chimes.drop_region(&"busy")
	var busy := Time.get_ticks_usec() - started
	_verdict.check(chimes.count() == 0, "both taken down, nothing is held: %d" % chimes.count())
	_verdict.check(quiet * 50 < busy, "taking the one wire down took under a fiftieth of taking the twenty thousand: %d us against %d us" % [quiet, busy])
