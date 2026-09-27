extends SceneTree

## What must be true of pictures that load as the reader nears them: the
## image loads model asks for a picture once, the newest wanted first, so
## many at once; a claim let go before its turn asks for nothing, and one
## let go after keeps the picture among so many unclaimed, the longest
## unclaimed freed first; a lazy image claims its key only while near -
## shown outside any scroll, or within its scroll's room and the look's
## reach - at the least size as wide as it is drawn; its box stands in until
## the picture lands; its key moving lets the old one go; scrolling a long
## column claims what comes near and lets what goes far go, so what is held
## stays flat; and a nearing presses once as it comes near, never again as
## the reader scrolls over it, and again once it is pushed on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_lazy_image.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const ImageLoads := preload("res://addons/gd_chime/image_loads.gd")
const LazyImage := preload("res://addons/gd_chime/components/primitives/lazy_image.gd")
const Verdict := preload("res://tests/verdict.gd")

const PATIENCE := 300
const REGION := &"app"
const GROWS := &"grows"

var _verdict := Verdict.new()


## What was made, in the order the pool made it: [key, size] each.
class Maker extends RefCounted:
	var made: Array = []
	## While true, the pool holds every picture back, so what stands in before one lands can be seen.
	var held: bool = false
	var _lock := Mutex.new()

	func make(key: Variant, size: int) -> Image:
		# held back until the test lets it go
		while held:
			OS.delay_msec(1)
		_lock.lock()
		made.append([key, size])
		_lock.unlock()
		return Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)


func _init() -> void:
	var theme := Themes.new(Themes.NEUTRAL)
	theme.set_constant(&"reach", &"Scroll", 500)
	theme.set_constant(&"aspect", &"LazyImage", 1000)
	root.theme = theme
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_picture_is_asked_for_once_the_newest_wanted_first_so_many_at_once)
	await _verdict.states(_a_claim_let_go_before_its_turn_asks_nothing_and_after_keeps_it_a_while)
	await _verdict.states(_shown_outside_a_scroll_it_claims_its_key_at_the_least_size_as_wide_as_it_is_drawn)
	await _verdict.states(_its_box_stands_in_until_the_picture_lands_and_its_key_moving_lets_the_old_go)
	await _verdict.states(_scrolling_a_long_column_claims_what_comes_near_and_lets_what_goes_far_go)
	await _verdict.states(_a_nearing_presses_as_it_comes_near_never_as_the_reader_scrolls_over_it_and_again_pushed_on)
	quit(_verdict.deliver(get_script()))


func _pool(made: Fixture) -> Jobs:
	var budget := FrameBudget.new(made.chimes, 1000.0, 0.9, 3)
	var jobs := Jobs.new(made.chimes, budget, 2, 64, false)
	root.add_child(budget)
	root.add_child(jobs)
	return jobs


func _until(held: Callable) -> void:
	var frames := 0
	# a frame at a time until it holds, or patience runs out
	while not held.call() and frames < PATIENCE:
		await process_frame
		frames += 1


func _a_picture_is_asked_for_once_the_newest_wanted_first_so_many_at_once() -> void:
	var made := Fixture.new(root)
	var jobs := _pool(made)
	var maker := Maker.new()
	var loads := ImageLoads.new(made.chimes, jobs, maker.make, 1, 4)
	root.add_child(loads)
	var one := RefCounted.new()
	var two := RefCounted.new()
	loads.want(&"a", 100, one)
	loads.want(&"b", 100, one)
	loads.want(&"c", 100, one)
	loads.want(&"a", 100, two)
	var busy := loads.get_busy()
	await _until(func() -> bool: return loads.get_held() == 3)
	_verdict.check(maker.made == [[&"a", 100], [&"c", 100], [&"b", 100]], "one at a time, the first asked at once and then the newest wanted first, and a picture wanted twice made once: %s" % [maker.made])
	_verdict.check(loads.texture_of(&"c", 100) != null and loads.texture_of(&"c", 200) == null and loads.get_waits().size() == 3 and busy and not loads.get_busy(), "landed, each is a texture at its own size, how long each waited is kept, and nothing is on its way any more")
	jobs.stop()
	made.done()


func _a_claim_let_go_before_its_turn_asks_nothing_and_after_keeps_it_a_while() -> void:
	var made := Fixture.new(root)
	var jobs := _pool(made)
	var maker := Maker.new()
	var loads := ImageLoads.new(made.chimes, jobs, maker.make, 1, 2)
	root.add_child(loads)
	var by := RefCounted.new()
	loads.want(&"a", 100, by)
	loads.want(&"b", 100, by)
	loads.let_go(&"b", 100, by)
	await _until(func() -> bool: return loads.get_held() == 1)
	await process_frame
	_verdict.check(maker.made == [[&"a", 100]], "a claim let go before its turn asks for nothing: %s" % [maker.made])
	# three more wanted and landed, then all four let go: only the two let go last are kept
	for key: StringName in [&"c", &"d", &"e"]:
		loads.want(key, 100, by)
	await _until(func() -> bool: return loads.get_held() == 4)
	for key: StringName in [&"a", &"c", &"d", &"e"]:
		loads.let_go(key, 100, by)
	_verdict.check(loads.get_held() == 2 and loads.texture_of(&"e", 100) != null and loads.texture_of(&"a", 100) == null, "let go after landing, a picture is kept among the unclaimed, the one let go longest ago freed first: %d held" % [loads.get_held()])
	loads.want(&"e", 100, by)
	_verdict.check(maker.made.size() == 4 and loads.get_claimed() == 1, "claimed again, a kept picture is there at once and never made again")
	jobs.stop()
	made.done()


## A column of lazy images in the given width, or one shown alone: [fixture, loads, jobs, maker].
func _images(keys: Array, in_scroll: bool, held: bool = false) -> Array:
	var made := Fixture.new(root)
	var ui := made.ui
	var jobs := _pool(made)
	var maker := Maker.new()
	maker.held = held
	var loads := ImageLoads.new(made.chimes, jobs, maker.make, 4, 3)
	root.add_child(loads)
	var holder := Fixture.Model.new(made.chimes, REGION)
	holder.set_value(&"items", keys)
	root.add_child(holder)
	var pictures: Array = []
	# one picture per key, each reading its key from the model, so a key can move
	for at: int in keys.size():
		pictures.append(ui.lazy_image(loads, holder.of(&"items").map(func(all: Variant) -> Variant: return all[at]), [100, 300, 900]).named(StringName("picture_%d" % at)))
	var column := ui.column(pictures)
	ui.start(ui.app(REGION, [ui.scroll(column).named(&"scroll") if in_scroll else column]))
	await process_frame
	await process_frame
	await process_frame
	return [made, loads, jobs, maker, holder]


func _shown_outside_a_scroll_it_claims_its_key_at_the_least_size_as_wide_as_it_is_drawn() -> void:
	var both: Array = await _images([&"sofa"], false)
	var picture: LazyImage = (both[0] as Fixture).ui.node_named(&"picture_0")
	_verdict.check(picture.get_claimed() == [&"sofa", 900], "400 wide, it claims the 900 picture, the least as wide as it is drawn: %s" % [picture.get_claimed()])
	root.size = Vector2i(250, 400)
	await process_frame
	await process_frame
	_verdict.check(picture.get_claimed() == [&"sofa", 300] and (both[1] as ImageLoads).get_claimed() == 1, "narrowed to 250, it claims the 300 and lets the 900 go: %s" % [picture.get_claimed()])
	root.size = Vector2i(400, 400)
	picture.visible = false
	await process_frame
	_verdict.check(picture.get_claimed().is_empty() and (both[1] as ImageLoads).get_claimed() == 0, "hidden, it claims nothing")
	_done(both)


func _its_box_stands_in_until_the_picture_lands_and_its_key_moving_lets_the_old_go() -> void:
	var both: Array = await _images([&"sofa"], false, true)
	var picture: LazyImage = (both[0] as Fixture).ui.node_named(&"picture_0")
	var maker: Maker = both[3]
	_verdict.check(picture.get_texture() == null and picture.size.y == picture.size.x, "before its picture lands only its box shows, as tall as it is wide by the look's aspect: %s" % [picture.size])
	maker.held = false
	await _until(func() -> bool: return picture.get_texture() != null)
	_verdict.check(picture.get_texture() == (both[1] as ImageLoads).texture_of(&"sofa", 900), "landed, the picture shows")
	maker.held = true
	(both[4] as Fixture.Model).set_value(&"items", [&"lamp"])
	await process_frame
	await process_frame
	_verdict.check(picture.get_claimed() == [&"lamp", 900] and (both[1] as ImageLoads).get_claimed() == 1 and picture.get_texture() == null, "its key moving, the new picture is claimed, the old let go, and the box stands in again")
	maker.held = false
	_done(both)


func _scrolling_a_long_column_claims_what_comes_near_and_lets_what_goes_far_go() -> void:
	var keys: Array = range(30).map(func(at: int) -> StringName: return StringName("piece_%d" % at))
	var both: Array = await _images(keys, true)
	var ui: RefCounted = (both[0] as Fixture).ui
	var loads: ImageLoads = both[1]
	var claimed := func() -> Array: return range(30).filter(func(at: int) -> bool: return not ui.node_named(StringName("picture_%d" % at)).get_claimed().is_empty())
	_verdict.check(claimed.call() == [0, 1], "at the top, the picture in the room and the one within the reach below are claimed, and no other: %s" % [claimed.call()])
	var scroll: ScrollContainer = ui.node_named(&"scroll")
	var most := 0
	# down the column a picture at a time, the most ever held kept
	for step: int in 30:
		scroll.scroll_vertical += 400
		await process_frame
		await process_frame
		most = maxi(most, loads.get_held())
	await _until(func() -> bool: return loads.get_held() >= 2 and not claimed.call().is_empty())
	_verdict.check(claimed.call() == [28, 29], "at the end, the last two are claimed and the first let go: %s" % [claimed.call()])
	_verdict.check(most <= 2 + 3 + 4, "what is held stays flat: at most the near, the kept unclaimed and those on their way - %d at most" % [most])
	_done(both)


func _a_nearing_presses_as_it_comes_near_never_as_the_reader_scrolls_over_it_and_again_pushed_on() -> void:
	var made := Fixture.new(root, {GROWS: "show more"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, REGION)
	made.commands.register(REGION, GROWS, model)
	root.add_child(model)
	var filler := ui.surface(&"Surface").named(&"filler")
	var foot := ui.nearing(GROWS, {}, [ui.text("more")])
	ui.start(ui.app(REGION, [ui.scroll(ui.column([filler, foot])).named(&"scroll")]))
	var tall: Control = ui.node_named(&"filler")
	tall.custom_minimum_size = Vector2(10, 1200)
	for wait: int in 3:
		await process_frame
	_verdict.check(model.told_actions.is_empty(), "far below the reach, it presses nothing")
	var scroll: ScrollContainer = ui.node_named(&"scroll")
	scroll.scroll_vertical = 800
	await process_frame
	await process_frame
	_verdict.check(model.told_actions.size() == 1, "come within the reach, it presses once: %s" % [model.told_actions])
	scroll.scroll_vertical = 760
	await process_frame
	scroll.scroll_vertical = 820
	await process_frame
	await process_frame
	_verdict.check(model.told_actions.size() == 1, "the reader scrolling to and fro over it presses nothing more")
	tall.custom_minimum_size = Vector2(10, 1300)
	await process_frame
	await process_frame
	await process_frame
	_verdict.check(model.told_actions.size() == 2, "pushed on while still near, it presses again: %s" % [model.told_actions])
	made.done()


func _done(both: Array) -> void:
	(both[2] as Jobs).stop()
	(both[0] as Fixture).done()
