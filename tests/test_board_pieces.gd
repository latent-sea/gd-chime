extends SceneTree

## What must be true of a board's pieces: an avatar, a badge, progress, and
## the lanes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_board_pieces.gd
##
## An avatar is a person's initials and nobody is none, following the name
## as it moves; a badge wears its level's look, in place, beside its words,
## each level's look a different mark; progress says how many of how many
## the moment the counts move while its bar goes there on the clock, and a
## whole of none is none done; lanes stand side by side, each a list target
## for its lane with its heading and count, saying so while empty, saying
## why while refusing what is carried over it, and a drop on one is the
## one move command; nothing of the board is drawn over anything else; and
## in a window too narrow for them the lanes keep their cards whole and the
## board scrolls across; and a lane's cards keep one width whether the lane
## overflows or not.

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Lane := preload("res://addons/gd_chime/lane.gd")
const Avatar := preload("res://addons/gd_chime/components/recipes/avatar.gd")
const Badge := preload("res://addons/gd_chime/components/recipes/badge.gd")
const Progress := preload("res://addons/gd_chime/components/recipes/progress.gd")
const Lanes := preload("res://addons/gd_chime/components/recipes/lanes.gd")
const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const Clipped := preload("res://addons/gd_chime/clipped_text.gd")
const Collections := preload("res://addons/gd_chime/theme_collections.gd")
const Feedback := preload("res://addons/gd_chime/theme_feedback.gd")

const WHY := "the lane is full"

var _verdict := Verdict.new()
var _made: Fixture
var _model: Fixture.Model


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1200, 700)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_an_avatar_is_initials_and_nobody_is_none)
	await _verdict.states(_a_badge_wears_its_levels_look_in_place_beside_its_words)
	await _verdict.states(_progress_says_the_counts_at_once_and_its_bar_goes_there)
	await _verdict.states(_lanes_stand_side_by_side_each_a_list_saying_what_it_holds)
	await _verdict.states(_a_lane_refusing_what_is_carried_says_why_and_a_drop_is_one_command)
	await _verdict.states(_in_a_narrow_window_no_card_is_cut_and_the_board_scrolls_across)
	await _verdict.states(_a_lane_keeps_its_cards_width_whether_it_overflows_or_not)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A fixture declaring these actions, and its model in the app's region.
func _built(declared: Dictionary = {}) -> void:
	_made = Fixture.new(root, declared)
	_model = Fixture.Model.new(_made.chimes, &"app")
	_made.ui.also(_model)
	await _a_frame_passes()


func _start(content: Array) -> void:
	_made.ui.start(_made.ui.app(&"app", content))
	await _a_frame_passes()


## Every word shown under this node, in tree order.
func _words(node: Node) -> Array:
	return node.find_children("*", "Label", true, false).filter(func(label: Label) -> bool: return label.is_visible_in_tree()).map(func(label: Label) -> String: return label.text)


func _an_avatar_is_initials_and_nobody_is_none() -> void:
	_verdict.check(Avatar.initials("Ana Lopez") == "AL" and Avatar.initials("sam") == "S" and Avatar.initials("Ines de la Cruz") == "ID" and Avatar.initials(null) == "", "a person's initials are the first letters of their first two words, as capitals; nobody's are none")
	await _built()
	_model.set_value(&"words", "Ana Lopez")
	await _start([Avatar.make(_made.ui, _model.of(&"words")).named(&"face")])
	var face: Control = _made.ui.node_named(&"face")
	_verdict.check(_words(face) == ["AL"] and face.theme_type_variation == Feedback.AVATAR, "an avatar shows the initials on the avatar's own ground: %s" % [_words(face)])
	_model.set_value(&"words", "Ben Okafor")
	await _a_frame_passes()
	_verdict.check(_words(face) == ["BO"], "the name moving, the initials follow: %s" % [_words(face)])
	_made.done()


func _a_badge_wears_its_levels_look_in_place_beside_its_words() -> void:
	await _built()
	_model.set_value(&"flag", 3)
	await _start([Badge.make(_made.ui, Phrase.of("High"), _model.of(&"flag")).named(&"badge")])
	var badge: Control = _made.ui.node_named(&"badge")
	_verdict.check(badge.theme_type_variation == Feedback.BADGES[3] and _words(badge) == ["High"], "a badge at level 3 wears the level's look, beside its words: %s" % badge.theme_type_variation)
	_model.set_value(&"flag", 9)
	await _a_frame_passes()
	_verdict.check(_made.ui.node_named(&"badge") == badge and badge.theme_type_variation == Feedback.BADGES[Badge.MOST], "the level moving, the same badge wears the new look in place, held to the most there is")
	var marks: Array = Feedback.BADGES.map(func(level: StringName) -> StyleBox: return root.theme.get_stylebox(&"panel", level))
	_verdict.check(marks.all(func(box: StyleBox) -> bool: return box.get_margin(SIDE_LEFT) > box.get_margin(SIDE_RIGHT)), "every level's look keeps room before the words for its mark")
	_made.done()


func _progress_says_the_counts_at_once_and_its_bar_goes_there() -> void:
	_verdict.check(Progress.shared(0, 0) == 0.0 and Progress.shared(3, 4) == 0.75, "a whole of none is none done; three of four is three quarters")
	await _built()
	_model.set_value(&"items", 42)
	_model.set_value(&"flag", 300)
	await _start([Progress.make(_made.ui, Phrase.of("Done"), _model.of(&"items"), _model.of(&"flag")).named(&"progress")])
	var progress: Control = _made.ui.node_named(&"progress")
	_verdict.check(_words(progress) == ["Done", "42 of 300, 14%"], "progress says its title and how many of how many: %s" % [_words(progress)])
	var bar: Control = progress.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part.theme_type_variation == Feedback.PROGRESS_BAR)[0]
	_made.ui.motion.still = false
	_made.ui.motion.by_hand = true
	_model.set_value(&"items", 150)
	await process_frame
	_verdict.check(_words(progress)[1] == "150 of 300, 50%", "the count moving, its words say so on the next frame: %s" % _words(progress)[1])
	_made.ui.motion.step(0.01)
	var going: float = bar._content.read()
	_made.ui.motion.step(10.0)
	var there: float = bar._content.read()
	_verdict.check(going > 0.14 and going < 0.5 and is_equal_approx(there, 0.5), "while its bar goes there on the clock, rather than jumping: %s, then %s" % [going, there])
	_made.done()


## A board of two lanes over the fixture model's items and words, each a list of draggables.
func _two_lanes() -> Array:
	await _built({&"moves_it": "move it"})
	_model.set_value(&"items", [{"id": 1, "words": "one"}, {"id": 3, "words": "three"}, {"id": 2, "words": "two"}])
	_model.set_value(&"words", [])
	# the lanes' test of what is shown turns three away, as a search would
	_model.set_value(&"flag", func(one: Dictionary) -> bool: return one["id"] != 3)
	var ui := _made.ui
	var key := func(one: Dictionary) -> int: return one["id"]
	var lanes: Array = [["a", &"items"], ["b", &"words"]].map(func(one: Array) -> Lane: return Lane.new(_made.chimes, ui.carried, _model.of(one[1]), _model.of(&"flag"), one[0], key))
	# every lane beside the app, freed with the fixture
	for lane: Lane in lanes:
		ui.also(lane)
	var card := func(item: Bound) -> Desc: return ui.draggable(item, [ui.text(item.field("words"))], Collections.BOARD_CARD)
	var headings: Array = lanes.map(func(lane: Lane) -> Desc: return Lanes.heading(ui, Phrase.with("lane %s", [lane.get_into()]), lane))
	_made.commands.register(&"app", &"moves_it", _model)
	await _start([Lanes.make(ui, lanes, headings, {template = card, key = key, moves = &"moves_it", empty = Phrase.of("nothing here")}).named(&"board")])
	await _a_frame_passes()
	return lanes


func _lanes_stand_side_by_side_each_a_list_saying_what_it_holds() -> void:
	await _two_lanes()
	var targets: Array = get_nodes_in_group(&"drop target")
	targets.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x)
	_verdict.check(targets.size() == 2 and targets.map(func(target: Control) -> Variant: return target.get_into()) == ["a", "b"] and targets[1].global_position.x >= targets[0].get_global_rect().end.x, "two list targets side by side, one for each lane, in order")
	_verdict.check(_words(targets[0]) == ["lane a", "2", "one", "two"] and _words(targets[1]) == ["lane b", "0", "nothing here"], "each under its heading and count, holding its pieces - and one holding none says so: %s, %s" % [_words(targets[0]), _words(targets[1])])
	var drawn: Array[String] = DrawnOver.covered(root, root.get_visible_rect())
	var cut: Array[String] = Clipped.clipped(root, root.get_visible_rect())
	_verdict.check(drawn.is_empty() and cut.is_empty(), "nothing is drawn over anything else and no words are cut: %s %s" % [drawn, cut])
	var pieces: Array = targets[0].find_children("*", "Label", true, false)
	_model.set_value(&"flag", func(_one: Dictionary) -> bool: return true)
	await _a_frame_passes()
	_verdict.check(_words(targets[0]) == ["lane a", "3", "one", "three", "two"] and targets[0].find_children("*", "Label", true, false) == pieces, "the test letting three through, its card shows where it stands and the count follows - the same pieces, none built again: %s" % [_words(targets[0])])
	_made.done()


func _in_a_narrow_window_no_card_is_cut_and_the_board_scrolls_across() -> void:
	root.size = Vector2i(520, 700)
	await _two_lanes()
	_model.set_value(&"items", [{"id": 1, "words": "a card whose words run on"}, {"id": 2, "words": "and on, never wrapping"}])
	_model.set_value(&"words", [{"id": 4, "words": "a card in the other lane"}])
	await _a_frame_passes()
	var targets: Array = get_nodes_in_group(&"drop target")
	targets.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x)
	var cards: Array = targets[0].find_children("*", "Control", true, false).filter(func(piece: Node) -> bool: return piece.has_method(&"is_lifted"))
	# each card's whole width inside its lane: a lane is never narrower than what it holds
	_verdict.check(cards.all(func(card: Control) -> bool: return targets[0].get_global_rect().grow(0.5).encloses(card.get_global_rect())), "however narrow the window, each card lies whole within its lane: %s in %s" % [cards.map(func(card: Control) -> Rect2: return card.get_global_rect()), targets[0].get_global_rect()])
	var board: Control = _made.ui.node_named(&"board")
	_verdict.check(board is ScrollContainer and board.get_h_scroll_bar().max_value > board.size.x, "and the lanes past the window are reached by scrolling the board across: %s" % board)
	var cut: Array[String] = Clipped.clipped(root, root.get_visible_rect())
	_verdict.check(cut.is_empty(), "resting on whole lanes, so no words are cut at its edge: lanes %s at least %s, %s" % [targets.map(func(target: Control) -> Rect2: return target.get_global_rect()), targets.map(func(target: Control) -> float: return target.get_combined_minimum_size().x), cut])
	_made.done()
	root.size = Vector2i(1200, 700)


func _a_lane_refusing_what_is_carried_says_why_and_a_drop_is_one_command() -> void:
	await _two_lanes()
	var targets: Array = get_nodes_in_group(&"drop target")
	targets.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x)
	var one: Control = targets[0].find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part.has_method(&"is_lifted"))[0]
	_model.refuse(&"moves_it", Phrase.of(WHY))
	var data: Variant = one._get_drag_data(Vector2.ZERO)
	var two: Control = targets[0].find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part.has_method(&"is_lifted") and not part.is_lifted() and part.is_visible_in_tree())[0]
	two._can_drop_data(Vector2(two.size.x / 2.0, two.size.y * 0.9), data)
	_verdict.check(_made.ui.carried.get_over() == {"into": "a", "at": 1}, "over the last card shown in its own lane, below its middle, it would land after it - the hidden card taking no place: %s" % [_made.ui.carried.get_over()])
	var takes: bool = targets[1]._can_drop_data(targets[1].size / 2.0, data)
	await _a_frame_passes()
	_verdict.check(not takes and targets[1].get_state() == &"refusing" and _words(targets[1]).has(WHY), "over a lane that would refuse it, the lane draws refusing and says why above its pieces: %s" % [_words(targets[1])])
	_model.refuse(&"moves_it", null)
	targets[1]._can_drop_data(targets[1].size / 2.0, data)
	targets[1]._drop_data(Vector2.ZERO, data)
	await _a_frame_passes()
	_verdict.check(_model.told_actions == [&"moves_it"] and _made.commands.get_last()["payload"] == {"id": 1, "words": "one", "into": "b", "at": 0}, "no longer refused, a drop on it is the one move, carrying the card and where it landed: %s" % [_made.commands.get_last()["payload"]])
	_made.done()


func _a_lane_keeps_its_cards_width_whether_it_overflows_or_not() -> void:
	await _two_lanes()
	var targets: Array = get_nodes_in_group(&"drop target")
	targets.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x)
	var first := func() -> Control: return targets[0].find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part.has_method(&"is_lifted") and part.is_visible_in_tree())[0]
	var fitting: float = first.call().size.x
	# enough cards that the lane runs past the window, and its bar is wanted
	_model.set_value(&"items", range(1, 60).map(func(id: int) -> Dictionary: return {"id": id, "words": "card %d" % id}))
	await _a_frame_passes()
	var overflowing: float = first.call().size.x
	_verdict.check(is_equal_approx(fitting, overflowing), "a lane's cards are as wide once it runs past its room as while it fits, so a filter never re-lays them at a new width: %s then %s" % [fitting, overflowing])
	_made.done()
