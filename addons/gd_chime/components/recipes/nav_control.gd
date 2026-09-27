extends RefCounted

const Themes := preload("../../theme.gd")
const Driver := preload("../../driver.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Pressables := preload("../../theme_pressables.gd")

## A navigation control: a control that takes the reader somewhere - a
## MENU ITEM to a named place, an INLINE one on any named thing wherever it
## appears, a BACK that retraces, a PLAY that opens a recording wherever
## the thing recorded is shown.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every one is a pressable whose place declares where it goes; the driver
## does the going, and Back is the driver's retrace, never a route. An
## inline one carries the thing it names as the parameter of the move -
## which one of the place's kind - read through its handle as the press
## lands, so a name in a row always opens that row's thing. A play is
## present only where there is a recording, and absent, not inert, where
## there is none yet.


## A menu item: the register's words, to a named place.
static func menu(ui: Ui, action: StringName, goes_to: StringName, style: StringName = Pressables.BUTTON) -> Desc:
	return ui.button(action, {goes_to = goes_to, style = style})


## A named thing, wherever it appears: its name as the words, opening its
## place with it as the parameter. The thing is a bound value; its name and
## its identity are the two keys given.
## Its options: goes_to, the place it opens; name_key and id_key, which
## keys of the thing are its name and its identity; and style.
const INLINE_OPTIONS: Array[String] = [Options.GOES_TO, "name_key", Options.ID_KEY, Options.STYLE]

static func inline(ui: Ui, action: StringName, thing: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("an inline link", options, INLINE_OPTIONS)
	var goes_to: StringName = options[Options.GOES_TO]
	var name_key: Variant = options.get("name_key", "name")
	var id_key: Variant = options.get(Options.ID_KEY, "id")
	var style: StringName = options.get(Options.STYLE, &"NavInline")
	var parameter: Bound = thing.map(func(item: Variant) -> Dictionary: return {"parameter": item[id_key] if item != null else null})
	return ui.pressable(action, parameter, [ui.text(thing.field(name_key), Themes.FACE)], style).goes_to(goes_to)


## Back: to where the reader came from, as far as they came.
static func back(ui: Ui, action: StringName, style: StringName = Pressables.BUTTON) -> Desc:
	return ui.button(action, {goes_to = Driver.BACK, style = style})


## Play: opens the recording of the thing shown, wherever it is shown, and
## is absent where there is no recording yet - the door refuses it then.
static func play(ui: Ui, action: StringName, recording: Bound, goes_to: StringName) -> Desc:
	var style := &"NavPlay"
	var parameter: Bound = recording.map(func(item: Variant) -> Dictionary: return {"parameter": item})
	return ui.pressable(action, parameter, [ui.text(ui.words(action), Themes.FACE)], style).goes_to(goes_to).absent_when_refused()
