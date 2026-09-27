extends SceneTree

## What must be true of a combo: a closed field wearing the current choice,
## which opens the choosing in an overlay - never a dropdown - where the
## focus lands for the keys and the pad; picking dispatches the value,
## closes the overlay, and the field shows the new choice; a short list is
## a choice's, a long one a type-ahead's.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_combo.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Setting := preload("res://addons/gd_chime/components/recipes/setting.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")
const Flex := preload("res://addons/gd_chime/components/primitives/flex.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")
const Combo := preload("res://addons/gd_chime/components/recipes/combo.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")

const FRUIT := ["pear", "apple", "fig", "date", "plum", "lime", "kiwi", "yuzu", "grape", "melon"]

var _verdict := Verdict.new()


## What is chosen: the options, the chosen value and its words, each set by what it is told.
class Chosen extends Fixture.Model:
	func get_options() -> Variant:
		return of(&"options", []).read()

	func get_chosen() -> Variant:
		return of(&"chosen").read()

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_actions.append(action)
		set_value(&"chosen", payload["value"])
		set_value(&"words", str(payload["value"]).to_lower())
		return null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_over_a_short_list_it_opens_the_choice_s_overlay_and_picking_closes_it_showing_the_new_value)
	await _verdict.states(_over_a_long_list_it_opens_a_type_ahead_and_picking_closes_it_showing_the_new_value)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The pad's button pressed and let go.
func _pad(button: JoyButton) -> void:
	# the button going down, then up
	for down: bool in [true, false]:
		var press := InputEventJoypadButton.new()
		press.button_index = button
		press.pressed = down
		root.push_input(press)


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _pressables(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.theme_type_variation != Sheet.SHADE)


func _over_a_short_list_it_opens_the_choice_s_overlay_and_picking_closes_it_showing_the_new_value() -> void:
	var made := Fixture.new(root, {&"picks": "pick", &"opens": "open"})
	var ui := made.ui
	var model := Chosen.new(made.chimes, &"app")
	model.set_value(&"options", [{"value": "small", "words": "small"}, {"value": "large", "words": "large"}])
	model.set_value(&"chosen", "small")
	var control := Combo.short(ui, &"picks", &"opens", {offers = Bound.new(model.get_options), chosen = Bound.new(model.get_chosen), title = Phrase.of("how big?")})
	var chooser: StringName = (control.props["overlay"] as Desc).named(&"overlay").get_place()
	made.commands.register(chooser, &"picks", model)
	ui.start(ui.app(&"app", [control.named(&"combo")]))
	await _a_frame_passes()
	var combo: Pressable = ui.node_named(&"combo")
	_verdict.check(_texts(combo) == ["small"] and combo.theme_type_variation == Fields.COMBO, "closed, it is a field wearing the chosen option's words, in the combo's look: %s %s" % [_texts(combo), combo.theme_type_variation])
	combo.pressed()
	await _a_frame_passes()
	var overlay: Node = ui.node_named(&"overlay")
	_verdict.check(made.driver.get_top().has(chooser) and overlay.is_ancestor_of(root.gui_get_focus_owner()), "pressed, the options stand in an overlay that takes the input, the focus in it for the keys and the pad: %s %s" % [made.driver.get_top(), root.gui_get_focus_owner()])
	_verdict.check(_texts(overlay) == ["how big?", "small", "large"], "the overlay holds the title and every option: %s" % [_texts(overlay)])
	(_pressables(overlay)[1] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"picks"] and made.commands.get_last()["payload"] == {"value": "large"}, "picking dispatches the option's value through the door: %s" % [made.commands.get_last()["payload"]])
	_verdict.check(not made.driver.get_top().has(chooser) and _texts(combo) == ["large"], "and closes the overlay, the field showing the new choice: %s %s" % [made.driver.get_top(), _texts(combo)])
	model.free()
	made.done()


func _over_a_long_list_it_opens_a_type_ahead_and_picking_closes_it_showing_the_new_value() -> void:
	var made := Fixture.new(root, {&"picks": "pick", &"opens": "open", &"types": "type"})
	var ui := made.ui
	var model := Chosen.new(made.chimes, &"app")
	model.set_value(&"items", FRUIT.map(func(word: String) -> Dictionary: return {"value": word.to_upper(), "words": word}))
	model.set_value(&"words", "pear")
	# a look that centres the line a sheet stands in, as a gallery look does: the long combo's sheet is its share of the window all the same
	root.theme.set_type_variation(Sheet.ASKED, Themes.ROW)
	root.theme.set_constant(&"align", Sheet.ASKED, Flex.CENTER)
	var narrowing := Narrowing.new(made.chimes, model.of(&"items"), 4)
	var control := Combo.long(ui, &"picks", &"opens", model.of(&"words"), {narrowing = narrowing, types = &"types", title = Phrase.of("which fruit?")})
	var chooser: StringName = (control.props["overlay"] as Desc).named(&"overlay").get_place()
	made.commands.register(chooser, &"types", narrowing)
	made.commands.register(chooser, &"picks", model)
	ui.start(ui.app(&"app", [control.named(&"combo")]))
	await _a_frame_passes()
	var combo: Pressable = ui.node_named(&"combo")
	_verdict.check(_texts(combo) == ["pear"] and combo.theme_type_variation == Fields.COMBO, "closed, it is a field wearing the chosen words, in the combo's look: %s" % [_texts(combo)])
	combo.pressed()
	await _a_frame_passes()
	var overlay: Node = ui.node_named(&"overlay")
	var line: LineEdit = overlay.find_children("*", "LineEdit", true, false)[0]
	_verdict.check(made.driver.get_top().has(chooser) and overlay.is_ancestor_of(root.gui_get_focus_owner()) and _texts(overlay).has("which fruit?") and _texts(overlay).has("10 matches"), "pressed, a type-ahead stands in an overlay with the title, the focus in it: %s %s" % [_texts(overlay), root.gui_get_focus_owner()])
	var sheet: Control = overlay.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Surface and (part as Surface).get_style() == Setting.SHEET)[0]
	var window := Rect2(Vector2.ZERO, Vector2(root.size))
	var shown := _pressables(overlay).map(func(option: Control) -> Rect2: return option.get_global_rect())
	_verdict.check(shown.size() == 4 and shown.all(func(rect: Rect2) -> bool: return rect.has_area() and window.encloses(rect) and sheet.get_global_rect().encloses(rect)), "every option shown has room: a rect of its own inside the window and inside the overlay's sheet: %s in %s" % [shown, sheet.get_global_rect()])
	line.grab_focus()
	_pad(JOY_BUTTON_DPAD_DOWN)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == _pressables(overlay)[0], "the pad walks from the typing line down to the first option: %s" % [root.gui_get_focus_owner()])
	root.size = Vector2i(400, 800)
	await _a_frame_passes()
	var standing := sheet.get_global_rect()
	_verdict.check(standing.has_area() and standing.position.y > 0.0 and standing.end.y < root.size.y and standing.position.x >= 0.0 and standing.end.x <= root.size.x, "on a window on its end the sheet still stands inside the window, the shade showing above and below it: %s" % [standing])
	root.size = Vector2i(600, 600)
	await _a_frame_passes()
	line.grab_focus()
	line.text = "m"
	line.text_changed.emit("m")
	await _a_frame_passes()
	var options := _pressables(overlay)
	_verdict.check(options.map(func(option: Pressable) -> String: return _texts(option)[0]) == ["plum", "lime", "melon"], "typing narrows the long list: %s" % [_texts(overlay)])
	(options[2] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"picks"] and made.commands.get_last()["payload"] == {"value": "MELON"}, "picking dispatches the option's value through the door: %s" % [made.commands.get_last()["payload"]])
	_verdict.check(not made.driver.get_top().has(chooser) and _texts(combo) == ["melon"], "and closes the overlay, the field showing the new choice: %s %s" % [made.driver.get_top(), _texts(combo)])
	narrowing.free()
	model.free()
	made.done()
