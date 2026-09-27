extends SceneTree

## What must be true of the application as a node: two of them in one
## window, side by side, each in its own shape and its own look, each
## answering its own presses; the window untouched by either; the settings
## the framework needs read and reported, and set only on request.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_chime_app.gd
##
## THE WINDOW BELONGS TO THE HOST (ruled 2026-09-20): an app
## node owns exactly its own subtree, so a game hosts one beside its own
## scenes and two in one window have nothing to fight over. Here a narrow
## app stands down the left of a wide window and a broad one across the
## rest: the narrow one is portrait and a phone's, the broad one landscape,
## each on its own easel with its own look, and a press at a point of the
## window lands on the app under that point and on no other. Taken out of
## the tree, an app takes everything it built with it, and the other goes
## on answering.
##
## THE SETTINGS are read from the project and the running input map, so a
## project that lacks one is told which and what value it wants, once
## however many apps enter; apply() sets all three and is the only thing
## here that writes outside a subtree.

const ChimeApp := preload("res://addons/gd_chime/chime_app.gd")
const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const NeededSettings := preload("res://addons/gd_chime/needed_settings.gd")

const PRESSES := &"presses"
## How much of the window the narrow app takes, from the left: a phone's column on a desk's window.
const NARROW := 0.25


## An app of one screen with one press, its model counting what it is told, wearing the look it was made with.
class Counting extends ChimeApp:
	var worn: Theme
	var counter: Fixture.Model

	func _init(look_worn: Theme) -> void:
		super()
		worn = look_worn

	func look() -> Theme:
		return worn

	func declare(register: Actions) -> void:
		register.declare_all({PRESSES: ["press"]})

	func describe() -> Desc:
		counter = Fixture.Model.new(chimes, &"home")
		counter.answering = [PRESSES]
		return ui.app(&"app", [ui.screen(&"home", [ui.pressable(PRESSES, {}, [ui.text("press")]).named(&"press")], counter)])


## An app whose author wrote an _enter_tree of their own, as a Godot node's author does.
class Entering extends Counting:
	var entered: bool = false

	func _enter_tree() -> void:
		entered = true


## An app whose register declares an action nothing in its description performs: a broken tree.
class Broken extends ChimeApp:
	func declare(register: Actions) -> void:
		register.declare_all({&"flies": ["fly"]})

	func describe() -> Desc:
		return ui.app(&"app", [ui.text("nothing flies here")])


## Hears everything said out loud as a warning or an error.
class Hearing extends Logger:
	var warned: Array[String] = []
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			warned.append(code)
		else:
			said.append(code)


var _verdict := Verdict.new()
var _hearing := Hearing.new()
var _narrow: Counting
var _broad: Counting


func _init() -> void:
	OS.add_logger(_hearing)
	await process_frame
	# a desk's window, set once the window stands: set before its first frame, a headless window keeps its own size (measured on 4.6.2)
	root.size = Vector2i(1920, 1080)
	await process_frame
	await _verdict.states(_two_apps_stand_side_by_side_each_in_its_own_shape_and_look_and_the_window_is_untouched)
	await _verdict.states(_a_press_lands_on_the_app_under_it_and_on_no_other)
	await _verdict.states(_an_app_leaving_the_tree_takes_everything_it_built_and_the_other_goes_on)
	await _verdict.states(_the_settings_it_needs_are_reported_once_and_set_only_on_request)
	await _verdict.states(_the_base_is_read_as_the_app_enters_so_a_host_may_apply_the_settings_first)
	await _verdict.states(_an_author_s_own_enter_tree_never_swallows_the_build)
	await _verdict.states(_leaving_waits_out_the_jobs_it_started_and_coming_back_builds_once)
	await _verdict.states(_a_broken_description_is_said_and_the_app_stands_empty_never_quitting)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The two apps under the root: the narrow one down the left, the broad one across the rest.
func _standing() -> void:
	_narrow = Counting.new(Themes.new(Themes.NEUTRAL))
	_narrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_narrow.anchor_right = NARROW
	_broad = Counting.new(Themes.new(Themes.NEUTRAL))
	_broad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_broad.anchor_left = NARROW
	root.add_child(_narrow)
	root.add_child(_broad)
	await _a_frame_passes()
	await _a_frame_passes()


func _done() -> void:
	# whichever of the two still stands is taken down; one may have been freed by the property itself
	for app: Variant in [_narrow, _broad]:
		if is_instance_valid(app):
			(app as Counting).free()


## A point of an app's canvas as a point of the window: the easel's place in the window, then the viewport's stretch.
func _on_window(app: Counting, at: Vector2) -> Vector2:
	return app.get_global_rect().position + app.viewport.get_final_transform() * at


func _pressed_at(where: Vector2) -> void:
	# the button down, then up, at a point of the window
	for down: bool in [true, false]:
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = down
		press.position = where
		root.push_input(press)
		await _a_frame_passes()


func _two_apps_stand_side_by_side_each_in_its_own_shape_and_look_and_the_window_is_untouched() -> void:
	var cleared := RenderingServer.get_default_clear_color()
	await _standing()
	_verdict.check(_narrow.ui.shape.orientation.read() == Shape.PORTRAIT and _narrow.ui.shape.whose_window.read() == Shape.PHONE, "the narrow app, a quarter of a wide window, is portrait and a phone's: %s %s" % [_narrow.ui.shape.orientation.read(), _narrow.ui.shape.whose_window.read()])
	_verdict.check(_broad.ui.shape.orientation.read() == Shape.LANDSCAPE and _broad.ui.shape.whose_window.read() == Shape.DESKTOP, "the broad app beside it is landscape and a desk's: %s" % [_broad.ui.shape.orientation.read()])
	_verdict.check(_narrow.get_base() == Vector2i(1080, 1920) and _broad.get_base() == Vector2i(1920, 1080), "each is drawn at its own base, the narrow one's turned: %s %s" % [_narrow.get_base(), _broad.get_base()])
	_verdict.check(_narrow.viewport.size_2d_override.x == 1080 and _broad.viewport.size_2d_override.x == 1920, "and each canvas is its base grown past along the side its rect has room on, never shrunk: %s %s" % [_narrow.viewport.size_2d_override, _broad.viewport.size_2d_override])
	_verdict.check(_narrow.canvas.theme == _narrow.worn and _broad.canvas.theme == _broad.worn and _narrow.worn != _broad.worn, "each wears the look it answered, on its own canvas")
	_verdict.check(root.theme == null and RenderingServer.get_default_clear_color() == cleared and root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED, "and the window is untouched by either: no look on it, its clear colour as it was: %s" % [root.theme])
	_verdict.check(_narrow.ui.node_named(&"press") != null and _broad.ui.node_named(&"press") != null and _narrow.ui.node_named(&"press") != _broad.ui.node_named(&"press"), "each built its own screen with its own press")
	_done()


func _a_press_lands_on_the_app_under_it_and_on_no_other() -> void:
	await _standing()
	var right: Control = _broad.ui.node_named(&"press")
	await _pressed_at(_on_window(_broad, right.get_global_rect().get_center()))
	_verdict.check(_broad.counter.told_actions == [PRESSES] and _narrow.counter.told_actions.is_empty(), "pressed in the broad app, its model is told and the narrow app's is not: %s %s" % [_broad.counter.told_actions, _narrow.counter.told_actions])
	var left: Control = _narrow.ui.node_named(&"press")
	await _pressed_at(_on_window(_narrow, left.get_global_rect().get_center()))
	_verdict.check(_narrow.counter.told_actions == [PRESSES] and _broad.counter.told_actions == [PRESSES], "pressed in the narrow app, its model is told and the broad app's is left as it was: %s %s" % [_narrow.counter.told_actions, _broad.counter.told_actions])
	_done()


func _an_app_leaving_the_tree_takes_everything_it_built_and_the_other_goes_on() -> void:
	await _standing()
	var clock := _narrow.ui.motion
	var press: Control = _narrow.ui.node_named(&"press")
	var model := _narrow.counter
	root.remove_child(_narrow)
	_narrow.free()
	await _a_frame_passes()
	_verdict.check(not is_instance_valid(clock) and not is_instance_valid(press) and not is_instance_valid(model), "gone from the tree, the app's clock, its screen and its model are gone with it")
	var right: Control = _broad.ui.node_named(&"press")
	await _pressed_at(_on_window(_broad, right.get_global_rect().get_center()))
	_verdict.check(_broad.counter.told_actions == [PRESSES] and _broad.ui.shape.orientation.read() == Shape.LANDSCAPE, "and the other app answers a press as before: %s" % [_broad.counter.told_actions])
	_done()


func _the_settings_it_needs_are_reported_once_and_set_only_on_request() -> void:
	var stretched: Variant = ProjectSettings.get_setting(NeededSettings.STRETCH)
	var accepts := InputMap.action_get_events(NeededSettings.ACCEPT)
	_verdict.check(NeededSettings.missing().is_empty(), "this project has every setting the framework needs: %s" % [NeededSettings.missing()])
	ProjectSettings.set_setting(NeededSettings.STRETCH, "canvas_items")
	InputMap.action_erase_events(NeededSettings.ACCEPT)
	var missing := NeededSettings.missing()
	_verdict.check(missing.size() == 2 and missing[0].contains(NeededSettings.STRETCH) and missing[0].contains("\"disabled\"") and missing[1].contains(NeededSettings.ACCEPT) and missing[1].contains("button 0"), "a stretched window and an accept with no pad button are each named with the value wanted: %s" % [missing])
	InputMap.set_meta(NeededSettings.SAID, {})
	var warned := _hearing.warned.size()
	await _standing()
	_done()
	var said: Dictionary = InputMap.get_meta(NeededSettings.SAID)
	_verdict.check(said.size() == 2, "two apps entering said each missing setting once, not twice: %d" % said.size())
	_verdict.check(_hearing.warned.size() == warned + 2 and _hearing.warned.slice(warned).all(func(one: String) -> bool: return one.contains("GdChime.apply_project_settings(get_window())")), "and each says the call that sets it, with its argument: %s" % [_hearing.warned.slice(warned)])
	_verdict.check(ProjectSettings.get_setting(NeededSettings.STRETCH) == "canvas_items" and InputMap.action_get_events(NeededSettings.ACCEPT).is_empty(), "and an app entering set nothing")
	NeededSettings.apply(root)
	_verdict.check(NeededSettings.missing().is_empty() and root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED and InputMap.action_get_events(NeededSettings.ACCEPT).size() == 1, "asked to, apply sets all of them, on the project, the window and the input map: %s" % [NeededSettings.missing()])
	ProjectSettings.set_setting(NeededSettings.STRETCH, stretched)
	InputMap.action_erase_events(NeededSettings.ACCEPT)
	# the accept action's events put back as they were
	for event: InputEvent in accepts:
		InputMap.action_add_event(NeededSettings.ACCEPT, event)


## An app made before the host's settings are applied - as a scene's app is
## made before its host's _ready runs - takes the base the settings say as
## it enters the tree, not the one they said when it was made.
func _the_base_is_read_as_the_app_enters_so_a_host_may_apply_the_settings_first() -> void:
	var app := Counting.new(Themes.new(Themes.NEUTRAL))
	app.set_anchors_preset(Control.PRESET_FULL_RECT)
	ProjectSettings.set_setting(NeededSettings.WIDTH, 1280)
	ProjectSettings.set_setting(NeededSettings.HEIGHT, 720)
	root.add_child(app)
	await _a_frame_passes()
	_verdict.check(app.get_base() == Vector2i(1280, 720) and app.viewport.size_2d_override == Vector2i(1280, 720), "made at the project's 1920 by 1080, then the base set to 1280 by 720 before it entered, the app draws at 1280 by 720: %s %s" % [app.get_base(), app.viewport.size_2d_override])
	app.free()
	ProjectSettings.set_setting(NeededSettings.WIDTH, NeededSettings.BASE.x)
	ProjectSettings.set_setting(NeededSettings.HEIGHT, NeededSettings.BASE.y)


func _an_author_s_own_enter_tree_never_swallows_the_build() -> void:
	var app := Entering.new(Themes.new(Themes.NEUTRAL))
	app.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(app)
	await _a_frame_passes()
	_verdict.check(app.entered and app.ui != null and app.ui.node_named(&"press") != null and app.driver.get_top() == [&"app", &"home"], "an app with an _enter_tree of its author's own is entered and built all the same: %s %s" % [app.entered, app.ui])
	app.free()


## Leaving waits out the tasks its pool has out and takes everything it
## built; coming back, it is built again, once.
func _leaving_waits_out_the_jobs_it_started_and_coming_back_builds_once() -> void:
	await _standing()
	var finished: Array = [false]
	var slow := func() -> bool:
		OS.delay_msec(300)
		finished[0] = true
		return true
	# a task that takes a while and says when it has finished; the answer is never wanted
	_narrow.jobs.submit(slow, func(_landed: bool) -> void: pass)
	var standing := _narrow.canvas.get_child_count()
	root.remove_child(_narrow)
	_verdict.check(finished[0], "gone from the tree, it waited out the task its pool had out before letting go")
	_verdict.check(_narrow.canvas.get_child_count() == 0, "and holds nothing it built: %d" % _narrow.canvas.get_child_count())
	root.add_child(_narrow)
	await _a_frame_passes()
	_verdict.check(_narrow.canvas.get_child_count() == standing and _narrow.driver.get_top() == [&"app", &"home"], "back in the tree, it is built again once and arrives: %d of %d, %s" % [_narrow.canvas.get_child_count(), standing, _narrow.driver.get_top()])
	_done()


## A broken tree is said out loud, the app stands with nothing arrived at,
## and the game goes on: a test still running to say so is the proof.
func _a_broken_description_is_said_and_the_app_stands_empty_never_quitting() -> void:
	var said := _hearing.said.size()
	var app := Broken.new()
	app.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(app)
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(_hearing.said.slice(said).has("nobody performs flies"), "the broken tree is said out loud: %s" % [_hearing.said.slice(said)])
	_verdict.check(app.driver.get_top().is_empty() and not app.driver.index.app.visible, "and the app stands empty, nothing arrived at: %s" % [app.driver.get_top()])
	app.free()
