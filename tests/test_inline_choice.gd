extends SceneTree

## What must be true of a short choice laid out inline: a radio group is a
## column of options and a segmented control a row of joined ones; the one
## chosen wears the chosen look - a mark, not a hue alone - through a bound
## style, in place; a pick goes through the door, or sets a local where the
## choice is the interface's alone, and looks the same either way; and the
## keys and the pad move along the options.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_inline_choice.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Local := preload("res://addons/gd_chime/components/primitives/local.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const PressLocal := preload("res://addons/gd_chime/components/primitives/press_local.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const InlineChoice := preload("res://addons/gd_chime/components/recipes/inline_choice.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Pressables := preload("res://addons/gd_chime/theme_pressables.gd")

const SIZES := [{"value": "small", "words": "small"}, {"value": "middling", "words": "middling"}, {"value": "large", "words": "large"}]

var _verdict := Verdict.new()


## What is chosen, set by what it is told, refusing what it was set to.
class Chosen extends Fixture.Model:
	var turned_down: Variant = null  # the one value it will not have

	func get_options() -> Variant:
		return of(&"options", []).read()

	func get_chosen() -> Variant:
		return of(&"chosen").read()

	func would(_action: StringName, payload: Dictionary) -> Phrase:
		return Phrase.of("not in that size") if payload.get("value") == turned_down and turned_down != null else null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_actions.append(action)
		set_value(&"chosen", payload["value"])
		return null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_radio_group_is_a_column_whose_pick_goes_through_the_door_and_the_chosen_look_follows_in_place)
	await _verdict.states(_a_segmented_control_is_a_row_of_joined_options_whose_pick_sets_a_local_through_no_door)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _words(option: Node) -> String:
	return (option.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text)[0] as Text).get_text()


func _key(keycode: Key) -> void:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	root.push_input(key)


func _pad(button: JoyButton) -> void:
	var pressed := InputEventJoypadButton.new()
	pressed.button_index = button
	pressed.pressed = true
	root.push_input(pressed)


func _a_radio_group_is_a_column_whose_pick_goes_through_the_door_and_the_chosen_look_follows_in_place() -> void:
	var made := Fixture.new(root, {&"sizes": "size"})
	var ui := made.ui
	var model := Chosen.new(made.chimes, &"app")
	model.set_value(&"options", SIZES)
	model.set_value(&"chosen", "middling")
	model.turned_down = "large"
	made.commands.register(&"app", &"sizes", model)
	ui.start(ui.app(&"app", [InlineChoice.radios(ui, &"sizes", Bound.new(model.get_options), Bound.new(model.get_chosen)).named(&"radios")]))
	await _a_frame_passes()
	var options: Array = ui.node_named(&"radios").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)
	var worn: Array = options.map(func(option: Control) -> StringName: return option.theme_type_variation)
	_verdict.check(options.map(_words) == ["small", "middling", "large"] and worn == [Pressables.RADIO, Pressables.RADIO_CHOSEN, Pressables.RADIO], "every option, in order, the chosen one in the chosen look: %s" % [worn])
	_verdict.check(options[0].position.x == options[1].position.x and options[1].position.y > options[0].position.y, "a column: one under another")
	var marked: StyleBoxFlat = root.theme.get_stylebox(&"normal", Pressables.RADIO_CHOSEN)
	_verdict.check(marked.border_width_left > 0 and marked.border_color == root.theme.get_color(&"ink", Themes.LOOK), "the chosen look carries a mark, not a hue alone")
	(options[0] as Control).grab_focus()
	_pad(JOY_BUTTON_DPAD_DOWN)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == options[1], "the pad moves down along the options: %s" % [root.gui_get_focus_owner()])
	_key(KEY_UP)
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"sizes"] and made.commands.get_last()["payload"] == {"value": "small"}, "accept on the focused option picks it through the door, as {value}: %s" % [made.commands.get_last()["payload"]])
	var now: Array = ui.node_named(&"radios").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)
	_verdict.check(now == options and now.map(func(option: Control) -> StringName: return option.theme_type_variation) == [Pressables.RADIO_CHOSEN, Pressables.RADIO, Pressables.RADIO], "the model moved: the chosen look moved with it, on the same options: %s" % [now.map(func(option: Control) -> StringName: return option.theme_type_variation)])
	_verdict.check((options[2] as Pressable).get_state() == &"inert" and str((options[2] as Pressable).get_reason()) == "not in that size", "an option the door refuses is inert, and says why")
	model.free()
	made.done()


func _a_segmented_control_is_a_row_of_joined_options_whose_pick_sets_a_local_through_no_door() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var shown: Local = ui.local("small")
	var holder := Fixture.Model.new(made.chimes, &"app")
	holder.set_value(&"items", SIZES)
	ui.start(ui.app(&"app", [ui.row([InlineChoice.segments(ui, shown, holder.of(&"items")).named(&"segments")])]))
	await _a_frame_passes()
	var segments: Array = ui.node_named(&"segments").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is PressLocal)
	_verdict.check(segments.map(func(option: Control) -> StringName: return option.theme_type_variation) == [Pressables.SEGMENT_CHOSEN, Pressables.SEGMENT, Pressables.SEGMENT], "the local's value wears the chosen look")
	_verdict.check(segments[1].position.y == segments[0].position.y and is_equal_approx(segments[1].position.x, segments[0].position.x + segments[0].size.x), "a row of joined options: each starts where the one before ends: %s %s" % [segments[0].get_rect(), segments[1].get_rect()])
	# each segment's words, where they are drawn in the window
	var words: Array = segments.map(func(option: Control) -> Rect2: return (option.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text)[0] as Control).get_global_rect())
	# the room between each segment's edges and its words: at its start and at its end
	var room: Array = range(segments.size()).map(func(at: int) -> Vector2: return Vector2(words[at].position.x - segments[at].get_global_rect().position.x, segments[at].get_global_rect().end.x - words[at].end.x))
	_verdict.check(room.all(func(either: Vector2) -> bool: return either.x > 0.0 and either.y > 0.0) and words[0].end.x < words[1].position.x and words[1].end.x < words[2].position.x, "the segments' words stand apart: each inside its own box with room either side, never running into the next: %s" % [room])
	var ran: Dictionary = made.commands.get_last()
	(segments[0] as Control).grab_focus()
	_pad(JOY_BUTTON_DPAD_RIGHT)
	await _a_frame_passes()
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == segments[2], "the pad and the keys move right along the row: %s" % [root.gui_get_focus_owner()])
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(shown.read() == "large" and made.commands.get_last() == ran, "a pick sets the local, and nothing goes through the door: %s" % shown.read())
	_verdict.check(segments.map(func(option: Control) -> StringName: return option.theme_type_variation) == [Pressables.SEGMENT, Pressables.SEGMENT, Pressables.SEGMENT_CHOSEN], "the chosen look moved with it, in place")
	_verdict.check((segments[2] as PressLocal)._box() == root.theme.get_stylebox(&"normal", Pressables.SEGMENT_CHOSEN) and (segments[2] as PressLocal)._box().border_width_bottom > 0, "chosen through a local it is drawn as one chosen through the door is, its mark along its foot")
	holder.free()
	made.done()
