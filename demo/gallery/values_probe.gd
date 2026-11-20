extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const PressLocal := preload("res://addons/gd_chime/components/primitives/press_local.gd")
const Outline := preload("res://addons/gd_chime/components/primitives/outline.gd")
const Values := preload("res://demo/gallery/values_models.gd")
const ValuesPieces := preload("res://demo/gallery/values_pieces.gd")
const Hands := preload("res://tests/hands.gd")

## The values screen walked by a reader's hands and reported, as the stall's
## probe (probe.gd) walks what every stall does: run by the gallery started
## with --probe, beside the gallery's other screens (extra_probe.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every control is worked by the mouse, the keys and the pad, each press
## pushed at the window (tests/hands.gd), and each claim holds only if all three
## moved the order: the slider dragged, stepped by an arrow and by the d-pad,
## and refused past eight tenths with the reason under its track; the
## stepper's minus clicked, its plus pressed by Enter until thirteen stops
## it, its minus by the pad's A, and a number typed; each combo opened and
## picked from by each hand, large refused in the short one's overlay and
## the long one narrowed by typing; a radio clicked, walked to and picked by
## the pad and by Enter, large inert; a segment clicked, walked to by the
## pad and by the keys, the view below following.
##
## The order's press is clicked, and pressed by Enter and the pad's A while
## its answer is awaited: sent once, pending meanwhile and in the room it
## had, until the stall's answer; and a size's block clicked is ringed, it
## alone, with no block moved.
##
## THE ORDER IS PUT BACK AS IT WAS, through the door, and the fruit's typing
## cleared, since every place is looked at after this.

## Every claim this walks.
const CLAIMS := ["slider_by_mouse_keys_pad", "stepper_by_mouse_keys_pad", "combo_short_by_mouse_keys_pad", "combo_long_by_mouse_keys_pad", "radios_by_mouse_keys_pad", "segments_by_mouse_keys_pad", "pending_press_asks_once", "outline_rings_the_chosen_and_moves_nothing"]

var _stall: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(stall: SceneTree) -> void:
	_stall = stall
	_hands = Hands.new(stall)


## Every claim, walked in turn and handed back by name.
func run() -> Dictionary:
	# every claim false until it is walked, so a walk that stops short fails rather than goes unsaid
	for claim: String in CLAIMS:
		_said[claim] = false
	await _hands.goes(ValuesPieces.VALUES)
	await _slider()
	await _stepper()
	await _short()
	await _long()
	await _radios()
	await _segments()
	await _pending()
	await _outlined()
	# every fact of the order as it was to begin with, set through the door
	for action: StringName in Values.Order.FIRST:
		_stall.commands.dispatch(Chimes.GLOBAL, action, {"value": Values.Order.FIRST[action]})
	_stall.commands.dispatch(Chimes.GLOBAL, Values.Order.TYPES_FRUIT, {"line": ""})
	return _said


func order() -> Values.Order:
	return _stall.order


func _slider() -> void:
	var slider: Control = _stall.ui.node_named(&"fill")
	await _hands.drag(slider.point_at(0.2), slider.point_at(0.6))
	var dragged := is_equal_approx(order().get_fill(), 0.6)
	slider.grab_focus()
	await _hands.key(KEY_RIGHT)
	var keyed := is_equal_approx(order().get_fill(), 0.7)
	await _hands.pad(JOY_BUTTON_DPAD_RIGHT)
	var padded := is_equal_approx(order().get_fill(), 0.8)
	await _hands.pad(JOY_BUTTON_DPAD_RIGHT)
	var refused: bool = is_equal_approx(order().get_fill(), 0.8) and _hands.texts(slider).has("Filled past eight tenths, a crate splits")
	_said["slider_by_mouse_keys_pad"] = dragged and keyed and padded and refused


func _stepper() -> void:
	var row: Control = _stall.ui.node_named(&"crates")
	var ends: Array = _hands.presses_of(Values.Order.SETS_CRATES, {under = row})
	await _hands.click(ends[0])
	var clicked := order().get_crates() == 11.0
	(ends[1] as Control).grab_focus()
	await _hands.key(KEY_ENTER)
	var keyed: bool = order().get_crates() == 12.0 and not ends[1].is_usable()
	(ends[0] as Control).grab_focus()
	await _hands.pad(JOY_BUTTON_A)
	var padded := order().get_crates() == 11.0
	var line: LineEdit = row.find_children("*", "LineEdit", true, false)[0]
	line.grab_focus()
	line.select_all()
	await _hands.types("7")
	await _hands.key(KEY_ENTER)
	_said["stepper_by_mouse_keys_pad"] = clicked and keyed and padded and order().get_crates() == 7.0


## The sizes in their overlay, raised: small, middling, large.
func _sizes() -> Array:
	return _hands.presses_of(Values.Order.PICKS_SIZE, {under = _hands.place(_stall.driver.goes_to(ValuesPieces.VALUES, ValuesPieces.OPENS_SIZES))})


func _short() -> void:
	var combo: Control = _stall.ui.node_named(&"size combo")
	await _hands.click(combo)
	var raised: bool = _stall.driver.get_top().has(_stall.driver.goes_to(ValuesPieces.VALUES, ValuesPieces.OPENS_SIZES))
	await _hands.click(_sizes()[1])
	var clicked: bool = order().get_size() == &"middling" and not _stall.driver.is_raised() and _hands.texts(combo) == ["Middling"]
	combo.grab_focus()
	await _hands.key(KEY_ENTER)
	var refused: bool = not _sizes()[2].is_usable()
	(_sizes()[1] as Control).grab_focus()
	await _hands.key(KEY_UP)
	await _hands.key(KEY_ENTER)
	var keyed: bool = order().get_size() == &"small" and not _stall.driver.is_raised()
	combo.grab_focus()
	await _hands.pad(JOY_BUTTON_A)
	var inside: bool = _hands.place(_stall.driver.goes_to(ValuesPieces.VALUES, ValuesPieces.OPENS_SIZES)).is_ancestor_of(_hands.focused())
	(_sizes()[0] as Control).grab_focus()
	await _hands.pad(JOY_BUTTON_DPAD_DOWN)
	await _hands.pad(JOY_BUTTON_A)
	var padded: bool = inside and order().get_size() == &"middling" and _hands.texts(combo) == ["Middling"]
	_said["combo_short_by_mouse_keys_pad"] = raised and clicked and refused and keyed and padded


func _long() -> void:
	var combo: Control = _stall.ui.node_named(&"fruit combo")
	var overlay: Control = _hands.place(_stall.driver.goes_to(ValuesPieces.VALUES, ValuesPieces.OPENS_FRUIT))
	combo.grab_focus()
	await _hands.key(KEY_ENTER)
	var typing: bool = _hands.focused() is LineEdit and overlay.is_ancestor_of(_hands.focused())
	await _hands.types("m")
	var narrowed: bool = _hands.presses_of(Values.Order.PICKS_FRUIT, {under = overlay}).map(func(option: Control) -> String: return _hands.texts(option)[0]) == ["plum", "lime", "melon", "lemon"]
	await _hands.pad(JOY_BUTTON_DPAD_DOWN)
	var walked: Variant = (_hands.focused() as Pressable).payload()["value"] if _hands.presses_of(Values.Order.PICKS_FRUIT, {under = overlay}).has(_hands.focused()) else null
	await _hands.pad(JOY_BUTTON_A)
	var padded: bool = walked != null and order().get_fruit() == walked and not _stall.driver.is_raised() and _hands.texts(combo) == [walked]
	await _hands.click(combo)
	# the melon among the options still narrowed, by its words
	var melon: Control = _hands.presses_of(Values.Order.PICKS_FRUIT, {under = overlay}).filter(func(option: Control) -> bool: return _hands.texts(option) == ["melon"])[0]
	await _hands.click(melon)
	_said["combo_long_by_mouse_keys_pad"] = typing and narrowed and padded and order().get_fruit() == "melon" and _hands.texts(combo) == ["melon"]


func _radios() -> void:
	var options: Array = _hands.presses_of(Values.Order.PICKS_SIZE, {under = _stall.ui.node_named(&"radios")})
	await _hands.click(options[0])
	var clicked := order().get_size() == &"small"
	(options[0] as Control).grab_focus()
	await _hands.pad(JOY_BUTTON_DPAD_DOWN)
	var walked: bool = _hands.focused() == options[1]
	await _hands.pad(JOY_BUTTON_A)
	var padded := order().get_size() == &"middling"
	(options[0] as Control).grab_focus()
	await _hands.key(KEY_ENTER)
	_said["radios_by_mouse_keys_pad"] = clicked and walked and padded and order().get_size() == &"small" and not options[2].is_usable()


func _segments() -> void:
	var segments: Array = _stall.ui.node_named(&"segments").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is PressLocal)
	segments.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x)
	var place: Node = _hands.place(ValuesPieces.VALUES)
	# whether the view below shows the price, by its words
	var priced := func() -> bool: return _hands.texts(place).any(func(words: String) -> bool: return words.contains(" coins: "))
	await _hands.click(segments[1])
	var clicked: bool = priced.call()
	(segments[1] as Control).grab_focus()
	await _hands.pad(JOY_BUTTON_DPAD_LEFT)
	var walked: bool = _hands.focused() == segments[0]
	await _hands.pad(JOY_BUTTON_A)
	var padded: bool = walked and not priced.call()
	await _hands.key(KEY_RIGHT)
	await _hands.key(KEY_ENTER)
	_said["segments_by_mouse_keys_pad"] = clicked and padded and _hands.focused() == segments[1] and priced.call()


func _pending() -> void:
	var sends: Pressable = _stall.ui.node_named(&"sends")
	var answers: Pressable = _stall.ui.node_named(&"answers")
	var before := order().get_sent()
	sends.grab_focus()
	var at_rest := sends.get_global_rect()
	var refused: bool = not answers.is_usable()
	await _hands.click(sends)
	var asked: bool = order().get_sent() == before + 1 and sends.get_state() == &"pending" and _hands.texts(sends) == ["Sending…"] and sends.get_global_rect().size == at_rest.size
	sends.grab_focus()
	await _hands.key(KEY_ENTER)
	await _hands.pad(JOY_BUTTON_A)
	await _hands.click(sends)
	var once: bool = order().get_sent() == before + 1 and sends.is_pending()
	answers.grab_focus()
	await _hands.click(answers)
	_said["pending_press_asks_once"] = refused and asked and once and not sends.is_pending() and _hands.texts(sends) == ["Send the order"]


func _outlined() -> void:
	var row: Control = _stall.ui.node_named(&"outlined")
	var blocks: Array = _hands.presses_of(Values.Order.PICKS_SIZE, {under = row})
	var rings: Array = row.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Outline)
	var stand := func() -> Array: return blocks.map(func(block: Control) -> Rect2: return block.get_global_rect())
	# the focus on a block first, so a page that scrolls has brought the row into the window before it is clicked
	(blocks[0] as Control).grab_focus()
	await _hands.click(blocks[0])
	var first: Array = stand.call()
	var shown_first: Array = rings.map(func(ring: Outline) -> bool: return ring.is_shown())
	(blocks[1] as Control).grab_focus()
	await _hands.click(blocks[1])
	var shown_second: Array = rings.map(func(ring: Outline) -> bool: return ring.is_shown())
	# each ring laid across the whole of its block
	var across: bool = range(rings.size()).all(func(at: int) -> bool: return (rings[at] as Control).get_global_rect().size == (blocks[at] as Control).get_global_rect().size)
	_said["outline_rings_the_chosen_and_moves_nothing"] = shown_first == [true, false, false] and shown_second == [false, true, false] and stand.call() == first and across and order().get_size() == &"middling"
