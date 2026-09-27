extends SceneTree

## What must be true of the shell's frame and its panes: a notification
## arriving stands in the frame's own tray, in the foot under the work and
## never over it, and its offer is pressed there; the tray holds its room,
## so the work stands to the pixel where it stood before any, with one, two
## and five standing and after they leave, and nothing outside the tray is
## placed again as one arrives; one stands at a time, the words beside it
## saying how many wait; a pane's toggle wears the look's toggle on while the pane
## shows and off while it is folded, in place.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_shell.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Panels := preload("res://addons/gd_chime/panels.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Shell := preload("res://addons/gd_chime/components/recipes/shell.gd")
const Panes := preload("res://addons/gd_chime/components/recipes/panes.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Verdict := preload("res://tests/verdict.gd")

const FOLDS := &"folds_the_list"
const SHOWS := &"shows_the_list"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(900, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_notification_stands_in_the_shell_s_tray_under_the_work_and_a_toggle_follows_its_pane)
	await _verdict.states(_a_status_described_is_placed_as_it_is_given_in_the_foot)
	OS.add_logger(_hearing)
	await _verdict.states(_a_long_notification_and_a_refused_offer_move_nothing_and_the_long_one_is_reported)
	quit(_verdict.deliver(get_script()))


## Keeps every error pushed, in words.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			said.append(code + " " + rationale)


var _hearing := Hearing.new()


## Words running far past the look's lines, and an offer the door refuses
## with its reason on its face: the work stands to the pixel where it stood
## through both, the long words are reported as they are made, and the
## short ones are not.
func _a_long_notification_and_a_refused_offer_move_nothing_and_the_long_one_is_reported() -> void:
	var made := Fixture.new(root, {SHOWS: "show the list", Notifications.DISMISSES: "dismiss"})
	var notifications := Notifications.new(made.chimes, made.commands, root)
	notifications.by_hand = true
	var refusing := Fixture.Model.new(made.chimes)
	refusing.refuse(SHOWS, Phrase.of("the list is shut for the night"))
	for node: Node in [notifications, refusing]:
		root.add_child(node)
	made.commands.register(Chimes.GLOBAL, Notifications.DISMISSES, notifications)
	made.commands.register(Chimes.GLOBAL, SHOWS, refusing)
	var ui := made.ui
	ui.start(ui.app(&"app", [Shell.make(ui, [], ui.surface(Themes.SURFACE, [ui.text("work")]).named(&"work"), {status = "all is well", notifications = notifications, offers = {SHOWS: &""}})]))
	await _a_frame_passes()
	var work: Control = ui.node_named(&"work")
	var bare := work.get_global_rect()
	_hearing.said.clear()
	notifications.notify(Phrase.of("short news"), SHOWS)
	await _a_frame_passes()
	var short_heard := _hearing.said.duplicate()
	_verdict.check(work.get_global_rect() == bare and _labelled(root, "the list is shut for the night") != null, "an offer refused, its reason on its face, moves nothing: %s against %s" % [work.get_global_rect(), bare])
	var long := "the list has a great deal of news today, about every one of the crates that came in this morning, which of them were sold, which were set aside, and which are still waiting on the stall for someone to come for them"
	notifications.notify(Phrase.of(long))
	# the short one cleared, so the long one stands
	made.commands.dispatch(Chimes.GLOBAL, Notifications.DISMISSES, {"notice": notifications.get_standing()[0]["id"]})
	await _a_frame_passes()
	_verdict.check(work.get_global_rect() == bare, "words running far past the look's lines move nothing: %s against %s" % [work.get_global_rect(), bare])
	var shown: Node = _labelled(root, long)
	# up from the long words to what scrolls them
	while shown != null and not shown is ScrollContainer:
		shown = shown.get_parent()
	var stand := _stand(root)
	_verdict.check(shown != null and stand.is_ancestor_of(shown) and stand.get_global_rect().encloses((shown as Control).get_global_rect()), "the long words scroll within the tray's room, which holds them: %s in %s" % [(shown as Control).get_global_rect() if shown != null else null, stand.get_global_rect()])
	_verdict.check(short_heard.is_empty() and _hearing.said.any(func(words: String) -> bool: return words.contains("too long for the tray")), "the long words are reported as they are made, and the short ones are not: %s" % [_hearing.said])
	refusing.free()
	made.done()


## A status given as a description - a mark beside its words - stands in the
## foot as it was described, under the work, and its words are its own.
func _a_status_described_is_placed_as_it_is_given_in_the_foot() -> void:
	var made := Fixture.new(root, {Notifications.DISMISSES: "dismiss"})
	var notifications := Notifications.new(made.chimes, made.commands, root)
	root.add_child(notifications)
	made.commands.register(Chimes.GLOBAL, Notifications.DISMISSES, notifications)
	var ui := made.ui
	var status := ui.row([ui.surface(Themes.SURFACE, []).named(&"mark"), ui.text("linked", Themes.REASON)]).named(&"status")
	ui.start(ui.app(&"app", [Shell.make(ui, [], ui.surface(Themes.SURFACE, [ui.text("work")]).named(&"work"), {status = status, notifications = notifications})]))
	await _a_frame_passes()
	var said: Control = ui.node_named(&"status")
	var work: Control = ui.node_named(&"work")
	_verdict.check(said != null and said.is_visible_in_tree() and ui.node_named(&"mark") != null and said.is_ancestor_of(_labelled(root, "linked")), "the status described is built as it was described, its mark beside its words")
	_verdict.check(said != null and said.get_global_rect().position.y >= work.get_global_rect().end.y, "the status stands in the foot, under the work: %s under %s" % [said.get_global_rect() if said != null else null, work.get_global_rect()])
	made.done()


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _a_notification_stands_in_the_shell_s_tray_under_the_work_and_a_toggle_follows_its_pane() -> void:
	var made := Fixture.new(root, {Panels.RESIZES: "resize", FOLDS: "the list", SHOWS: "show the list", Notifications.DISMISSES: "dismiss"})
	var panels := Panels.new(made.chimes, {&"main": 0.3}, {&"list": [&"main", Panels.FIRST], &"page": [&"main", Panels.SECOND]}, {FOLDS: &"list"}, {}, {SHOWS: &"list"})
	var notifications := Notifications.new(made.chimes, made.commands, root)
	notifications.by_hand = true
	for node: Node in [panels, notifications]:
		root.add_child(node)
	for action: StringName in [Panels.RESIZES, FOLDS, SHOWS]:
		made.commands.register(Chimes.GLOBAL, action, panels)
	made.commands.register(Chimes.GLOBAL, Notifications.DISMISSES, notifications)
	var ui := made.ui
	var listed: Desc = ui.surface(Themes.SURFACE, [ui.text("list")]).named(&"list")
	var work := Panes.split(ui, listed, ui.surface(Themes.SURFACE, [ui.text("page")]), {panels = panels, named = &"main", folds = FOLDS}).named(&"work")
	var bar := [Panes.toggle(ui, FOLDS, panels.shown(&"list")).named(&"toggle")]
	ui.start(ui.app(&"app", [Shell.make(ui, bar, work, {status = "all is well", notifications = notifications, offers = {SHOWS: &""}})]))
	await _a_frame_passes()
	var the_work: Control = ui.node_named(&"work")
	var bare := the_work.get_global_rect()
	var stand: Control = _stand(root)
	var placed := _placings(root, stand)
	notifications.notify(Phrase.of("the list has news"), SHOWS)
	await _a_frame_passes()
	var notice := _labelled(root, "the list has news")
	_verdict.check(notice != null and notice.get_global_rect().position.y >= the_work.get_global_rect().end.y and not notice.get_global_rect().intersects(the_work.get_global_rect()), "a notification stands in the foot, under the work and never over it: %s under %s" % [notice.get_global_rect() if notice != null else null, the_work.get_global_rect()])
	_verdict.check(_placings(root, stand) == placed, "in the frames a notification arrives, nothing outside the tray is placed again")
	var rects: Array = [the_work.get_global_rect()]
	notifications.notify(Phrase.of("the page has news"))
	await _a_frame_passes()
	rects.append(the_work.get_global_rect())
	# three more, five standing: four waiting
	for more: int in 3:
		notifications.notify(Phrase.with("news %d", [more]))
	await _a_frame_passes()
	rects.append(the_work.get_global_rect())
	_verdict.check(rects.all(func(rect: Rect2) -> bool: return rect == bare), "the work stands to the pixel where it stood, one, two and five notifications standing: %s against %s" % [rects, bare])
	_verdict.check(_labelled(root, "4 more") != null and _labelled(root, "the list has news") != null and _labelled(root, "news 2") == null, "five standing, the oldest alone shows, the words beside it saying how many wait, in the same room")
	# every one but the first sent away, the one showing last
	for one: Dictionary in notifications.get_standing().slice(1):
		made.commands.dispatch(Chimes.GLOBAL, Notifications.DISMISSES, {"notice": one["id"]})
	await _a_frame_passes()
	var toggle: Pressable = ui.node_named(&"toggle")
	_verdict.check(toggle.theme_type_variation == Panes.SHOWN, "the list shown, its toggle wears the toggle on: %s" % toggle.theme_type_variation)
	toggle.pressed()
	await _a_frame_passes()
	_verdict.check(not (ui.node_named(&"list") as Control).visible and toggle.theme_type_variation == Panes.FOLDED, "pressed, the list folds and the same toggle wears the toggle off: %s" % toggle.theme_type_variation)
	var press: Node = _labelled(root, "show the list")
	# up from the offer's words to the press they are on
	while not press is Pressable:
		press = press.get_parent()
	press.pressed()
	await _a_frame_passes()
	_verdict.check((ui.node_named(&"list") as Control).visible and notifications.get_standing().is_empty(), "the offer pressed in the tray shows the list, and the notice goes")
	await _a_frame_passes()
	_verdict.check(the_work.get_global_rect() == bare and _stand(root).get_global_rect().size.y > 0.0, "none standing, the tray keeps its room and the work stands where it stood: %s" % the_work.get_global_rect())
	made.done()


## The tray's stand under this node.
static func _stand(node: Node) -> Control:
	# every child, itself the stand or searched within
	for child: Node in node.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("tray_stand.gd"):
			return child
		var within := _stand(child)
		if within != null:
			return within
	return null


## How many times every layout outside the tray has been placed, by its path.
static func _placings(node: Node, tray: Node) -> Dictionary:
	var counted: Dictionary = {}
	# every child outside the tray, its count kept and searched within
	for child: Node in node.get_children():
		if child == tray:
			continue
		if &"arrange_count" in child:
			counted[child.get_path()] = child.arrange_count
		counted.merge(_placings(child, tray))
	return counted


## The first shown label saying exactly these words, under this node.
static func _labelled(node: Node, words: String) -> Control:
	# every child, itself or searched within
	for child: Node in node.get_children():
		if child is Label and (child as Label).text == words and (child as Label).is_visible_in_tree():
			return child
		var within := _labelled(child, words)
		if within != null:
			return within
	return null
