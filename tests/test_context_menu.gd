extends SceneTree
const Actions := preload("res://addons/gd_chime/actions.gd")

## What must be true of a context menu: a right press over a row opens the
## row's menu at the pointer, over the rest of the list the list's own - the
## nearest target; its items are the actions offered, each carrying what the
## target's press is about, a refused one saying why before it is picked; a
## pick lowers the menu and makes the press; the menu key and a pad button
## open it over the control with the focus, set down under it; a press past
## it or Escape sends it away; near the window's corner it stays inside the
## window; and the menu key with the focus on no target opens nothing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_context_menu.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const OpenMenu := preload("res://addons/gd_chime/open_menu.gd")
const ContextMenu := preload("res://addons/gd_chime/components/recipes/context_menu.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")

const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const WORDS := {OpenMenu.OPENS: "more", OpenMenu.PICKS: "pick", &"renames": "rename", &"deletes": "delete", &"selects": "select", &"adds": "add a row", &"elsewhere": "elsewhere"}

var _verdict := Verdict.new()


## The rows: what is renamed and deleted, the second never deletable.
class Rows extends Fixture.Model:
	var payloads: Array = []

	func would(action: StringName, payload: Dictionary) -> Phrase:
		return Phrase.of("the second row is kept") if action == &"deletes" and payload.get("row") == 2 else null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		payloads.append(payload)
		return super(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_right_press_opens_the_nearest_target_s_menu_and_a_pick_is_its_press)
	await _verdict.states(_the_menu_key_and_a_pad_button_open_it_over_the_focus_and_it_goes_away_as_asked)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A list of two rows, each its own menu of rename and delete, in a list
## whose own menu adds a row; a press elsewhere at the foot; and the menu.
func _built() -> Dictionary:
	var made := Fixture.new(root, {})
	var table: Dictionary = {}
	# every action, the menu opened on the menu key and a pad's view button, closed on Escape
	for action: StringName in WORDS:
		table[action] = [WORDS[action], Actions.keys(KEY_MENU), Actions.pad(JOY_BUTTON_BACK)] if action == OpenMenu.OPENS else [WORDS[action]]
	made.actions.declare_all(table)
	made.inputs.restore_defaults()
	var rows := Rows.new(made.chimes, Chimes.GLOBAL)
	var menu := OpenMenu.new(made.chimes, made.commands, made.actions)
	for action: StringName in [&"renames", &"deletes", &"selects", &"adds", &"elsewhere"]:
		made.commands.register(Chimes.GLOBAL, action, rows)
	made.commands.register(Chimes.GLOBAL, OpenMenu.OPENS, menu)
	root.add_child(rows)
	root.add_child(menu)
	var ui := made.ui
	var row := func(which: int) -> Desc: return ui.menu_target([&"renames", &"deletes"], {"row": which}, [ui.pressable(&"selects", {"row": which}, [ui.text("row %d" % which)]).named(StringName("row %d" % which))])
	var list := ui.menu_target([&"adds"], {}, [ui.column([row.call(1), row.call(2), ui.surface(Themes.SURFACE).grow()])])
	ContextMenu.make(ui, menu)
	ui.start(ui.app(&"app", [ui.column([list.grow(), ui.pressable(&"elsewhere", {}, [ui.text("elsewhere")]).named(&"elsewhere")])]))
	return {"made": made, "rows": rows, "menu": menu}


func _done(built: Dictionary) -> void:
	for model: Node in [built["rows"], built["menu"]]:
		model.free()
	(built["made"] as Fixture).done()


func _right_press(at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	root.push_input(move)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	click.position = at
	root.push_input(click)
	await _released(click)


func _press(event: InputEvent) -> void:
	event.pressed = true
	root.push_input(event)
	await _released(event)


## The press let go, as a hand lets go: a button held down keeps the pointer's hover where it pressed.
func _released(event: InputEvent) -> void:
	var up: InputEvent = event.duplicate()
	up.pressed = false
	root.push_input(up)
	await _a_frame_passes()


## The items shown in the menu now, in order.
func _items(made: Fixture) -> Array:
	var menu: Node = made.driver.index.place_named(_menu(made))
	return menu.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.visible and not part.is_in_group(&"going"))


## The application's one context menu, named by the builder.
func _menu(made: Fixture) -> StringName:
	return made.ui.menu_place


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text and (child as Text).visible:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _the_menu_box(made: Fixture) -> Control:
	return made.driver.index.place_named(_menu(made)).find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Surface)[0]


func _a_right_press_opens_the_nearest_target_s_menu_and_a_pick_is_its_press() -> void:
	var built := _built()
	var made: Fixture = built["made"]
	var rows: Rows = built["rows"]
	await _a_frame_passes()
	var second: Control = made.ui.node_named(&"row 2")
	var at := second.get_global_rect().get_center()
	await _right_press(at)
	var items := _items(made)
	_verdict.check(made.driver.get_top() == [_menu(made)] and items.map(func(item: Pressable) -> String: return _texts(item)[0]) == ["rename", "delete"], "a right press over a row opens the row's menu, its two actions: %s %s" % [made.driver.get_top(), items.map(func(item: Pressable) -> Array: return _texts(item))])
	_verdict.check(not (items[1] as Pressable).is_usable() and _texts(items[1]).has("the second row is kept") and (items[0] as Pressable).is_usable(), "the one the door would refuse for this row says why, before it is picked: %s" % [_texts(items[1])])
	_verdict.check(_the_menu_box(made).get_global_rect().position.distance_to(at) < 1.0, "it is set down at the pointer: %s at %s" % [_the_menu_box(made).get_global_rect().position, at])
	(items[0] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(rows.told_actions == [&"renames"] and rows.payloads[0] == {"row": 2} and not made.driver.is_raised(), "a pick lowers the menu and makes the press, about the row it was opened over: %s %s" % [rows.told_actions, rows.payloads])
	await _right_press(Vector2(300, made.ui.node_named(&"row 2").get_global_rect().end.y + 40))
	_verdict.check(_items(made).map(func(item: Pressable) -> String: return _texts(item)[0]) == ["add a row"], "over the rest of the list, the list's own menu: %s" % [_items(made).map(func(item: Pressable) -> Array: return _texts(item))])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = Vector2(590, 390)
	await _press(click)
	_verdict.check(not made.driver.is_raised() and rows.told_actions == [&"renames"], "a press past it sends it away, pressing nothing beneath: %s" % [made.driver.get_top()])
	# the list's corner nearest the window's: its right edge, over the gap above the press at the foot
	var list_corner: Vector2 = (made.ui.node_named(&"row 1").get_parent().get_parent().get_parent() as Control).get_global_rect().end - Vector2(3, 3)
	await _right_press(list_corner)
	var box := _the_menu_box(made)
	_verdict.check(made.driver.is_raised() and box.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(600, 400)).encloses(box.get_global_rect()), "opened at the window's corner, it stays inside the window: %s opened at %s" % [box.get_global_rect(), list_corner])
	_done(built)


func _the_menu_key_and_a_pad_button_open_it_over_the_focus_and_it_goes_away_as_asked() -> void:
	var built := _built()
	var made: Fixture = built["made"]
	await _a_frame_passes()
	var first: Control = made.ui.node_named(&"row 1")
	first.grab_focus()
	await _a_frame_passes()
	var menu_key := InputEventKey.new()
	menu_key.keycode = KEY_MENU
	await _press(menu_key)
	_verdict.check(made.driver.get_top() == [_menu(made)] and (built["menu"] as OpenMenu).items_of(made.driver.get_parameter(_menu(made)))[0]["payload"] == {"row": 1}, "the menu key opens the menu of the row with the focus: %s" % [made.driver.get_parameter(_menu(made))])
	_verdict.check(is_equal_approx(_the_menu_box(made).get_global_rect().position.y, first.get_global_rect().end.y), "set down under it: %s under %s" % [_the_menu_box(made).get_global_rect().position, first.get_global_rect()])
	_verdict.check(root.gui_get_focus_owner() == _items(made)[0], "the first item takes the focus: %s" % root.gui_get_focus_owner())
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	await _press(escape)
	_verdict.check(not made.driver.is_raised(), "Escape sends it away: %s" % [made.driver.get_top()])
	first.grab_focus()
	var view := InputEventJoypadButton.new()
	view.button_index = JOY_BUTTON_BACK
	await _press(view)
	_verdict.check(made.driver.get_top() == [_menu(made)], "and the pad's button opens it too: %s" % [made.driver.get_top()])
	escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	await _press(escape)
	(made.ui.node_named(&"elsewhere") as Control).grab_focus()
	menu_key = InputEventKey.new()
	menu_key.keycode = KEY_MENU
	await _press(menu_key)
	_verdict.check(not made.driver.is_raised(), "with the focus on no target, the menu key opens nothing: %s" % [made.driver.get_top()])
	_done(built)
