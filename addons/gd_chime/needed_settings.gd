extends RefCounted

## The project settings the framework relies on: which of them a project
## lacks, said in words, and setting them for a project that asks.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THREE SETTINGS, and why each: the base size, `display/window/size`, which
## is what an easel draws its canvas at (easel.gd) - a project that never
## set it gets the engine's own, and every share of the canvas is a share
## of that; the window NOT stretched, `display/window/stretch/mode` left
## disabled, since the easel scales the application itself at real pixels
## and a stretched window would scale it twice, blurring every word; and a
## pad button on `ui_accept`, since the engine's own accept holds none, so
## a pad could move the focus and never press (project.godot says which).
##
## AN APPLICATION READS AND REPORTS, NEVER WRITES. The window and the input
## map belong to the host: an app node entering the tree asks what is
## missing and says so once, naming the setting and the value it wants.
## Only apply() writes - the one explicit way, called by a project that
## wants the whole window run the framework's way, which is what the demos'
## main loop does (application.gd). It writes the settings AND puts them on the
## running window and input map, so a call at start takes effect at start;
## it never saves project.godot, which is the editor's to write.
##
## Deliberately absent: a check of the renderer or the audio buses, which
## the framework does without; and the input map's other actions, which
## the map of inputs (input_map.gd) declares as an application's own.

const WIDTH := "display/window/size/viewport_width"
const HEIGHT := "display/window/size/viewport_height"
const STRETCH := "display/window/stretch/mode"
const ACCEPT := "ui_accept"
## The base the floor's looks are written for, and the pad button that accepts.
const BASE := Vector2i(1920, 1080)
const NOT_STRETCHED := "disabled"
const ACCEPTS := JOY_BUTTON_A
## Where each finding is remembered so it is said once: on the engine's
## input map, beside the actions - a script of static functions holding it
## would be kept past the end.
const SAID := &"needed_settings_said"


## Every setting the project lacks, each a sentence naming it and the value wanted.
static func missing() -> Array[String]:
	var found: Array[String] = []
	var base := Vector2i(ProjectSettings.get_setting(WIDTH), ProjectSettings.get_setting(HEIGHT))
	if base != BASE:
		found.append("%s and %s are %d by %d, and the floor's looks are written for %d by %d" % [WIDTH, HEIGHT, base.x, base.y, BASE.x, BASE.y])
	if ProjectSettings.get_setting(STRETCH) != NOT_STRETCHED:
		found.append("%s is \"%s\", and an application scales itself at real pixels, so a stretched window scales it twice; it wants \"%s\"" % [STRETCH, ProjectSettings.get_setting(STRETCH), NOT_STRETCHED])
	if not _accepts_a_pad():
		found.append("the action %s has no pad button, so a pad could move the focus and never press; it wants button %d" % [ACCEPT, ACCEPTS])
	return found


## What is missing said out loud, once each however many applications enter.
static func report() -> void:
	var said: Dictionary = InputMap.get_meta(SAID, {})
	# every setting found missing, for the ones not yet said
	for sentence: String in missing():
		if not said.has(sentence):
			said[sentence] = true
			push_warning("gd-chime: %s; GdChime.apply_project_settings() sets it" % sentence)
	InputMap.set_meta(SAID, said)


## Every needed setting set: in the project settings, and on this window and
## the input map, so it holds from this frame. The window is handed in
## because a main loop's own _init runs before the engine will say which
## loop is running (measured on 4.6.2: Engine.get_main_loop() is null there).
static func apply(window: Window) -> void:
	ProjectSettings.set_setting(WIDTH, BASE.x)
	ProjectSettings.set_setting(HEIGHT, BASE.y)
	ProjectSettings.set_setting(STRETCH, NOT_STRETCHED)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	if not _accepts_a_pad():
		var button := InputEventJoypadButton.new()
		button.button_index = ACCEPTS
		InputMap.action_add_event(ACCEPT, button)


## Whether the accept action holds any pad button now, as the input map runs it.
static func _accepts_a_pad() -> bool:
	# every event on the action, for a pad button among them
	for event: InputEvent in InputMap.action_get_events(ACCEPT):
		if event is InputEventJoypadButton:
			return true
	return false
