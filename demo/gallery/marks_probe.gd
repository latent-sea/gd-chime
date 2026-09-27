extends RefCounted

const Marks := preload("res://demo/gallery/marks_models.gd")
const MarksPieces := preload("res://demo/gallery/marks_pieces.gd")
const Hands := preload("res://tests/hands.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")

## The marks screen walked by a reader's hands and reported, beside the
## gallery's other screens' probes (values_probe.gd): run by the gallery
## started with --probe.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The paragraph's two links stand on different lines, and the pad walks
## right from the first to the second all the same; each opens its own
## crate - clicked, pressed by Enter and by the pad's A. A chip is turned off
## by a click and says so in brackets, another turned on by the pad, one
## taken off by its x with Enter; the one with no x has none; and the labels
## put back by a click, after which putting them back is refused. The
## divider across stands between the two boxes, and the one down between
## the chips it divides.
##
## THE LABELS ARE PUT BACK AS THEY WERE, and the reader left on the screen,
## since every place is looked at after this.

## Every claim this walks.
const CLAIMS := ["paragraph_links_by_mouse_keys_pad", "chips_by_mouse_keys_pad", "dividers_between"]

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
	await _hands.goes(MarksPieces.MARKS)
	await _links()
	await _chips()
	var ui: RefCounted = _stall.ui
	var across: Rect2 = ui.node_named(&"between boxes").get_global_rect()
	var down: Rect2 = ui.node_named(&"between chips").get_global_rect()
	var over: bool = across.has_area() and across.position.y >= ui.node_named(&"paragraph box").get_global_rect().end.y and across.end.y <= ui.node_named(&"chips box").get_global_rect().position.y
	_said["dividers_between"] = over and down.has_area() and down.position.x >= ui.node_named(&"labels").get_global_rect().end.x and down.end.x <= ui.node_named(&"fresh").get_global_rect().position.x
	return _said


func _links() -> void:
	var first: Control = _stall.ui.node_named(&"first link")
	var second: Control = _stall.ui.node_named(&"second link")
	# the crate the detail was entered as, or none while the reader is elsewhere
	var opened := func() -> Variant: return _stall.driver.get_parameter(_stall.DETAIL) if _stall.driver.get_top().has(_stall.DETAIL) else null
	first.grab_focus()
	await _hands.pad(JOY_BUTTON_DPAD_RIGHT)
	var walked: bool = _hands.focused() == second and second.get_global_rect().position.y >= first.get_global_rect().end.y
	await _hands.click(first)
	var clicked: Variant = opened.call()
	await _hands.goes(MarksPieces.MARKS)
	second.grab_focus()
	await _hands.key(KEY_ENTER)
	var keyed: Variant = opened.call()
	await _hands.goes(MarksPieces.MARKS)
	first.grab_focus()
	await _hands.pad(JOY_BUTTON_A)
	var padded: Variant = opened.call()
	await _hands.goes(MarksPieces.MARKS)
	_said["paragraph_links_by_mouse_keys_pad"] = walked and [clicked, keyed, padded] == [1, 3, 1]


func _chips() -> void:
	var labels: Marks.Labels = _stall.labels
	var place: Node = _hands.place(MarksPieces.MARKS)
	var toggles: Array = _hands.presses_of(Marks.Labels.TOGGLES, {under = place})
	var removes: Array = _hands.presses_of(Marks.Labels.REMOVES, {under = place})
	var bare: bool = toggles.size() == 3 and removes.size() == 2
	await _hands.click(toggles[0])
	var clicked: bool = not labels.get_labels()[0]["on"] and _hands.texts(place).has("(Ripe)")
	(toggles[1] as Control).grab_focus()
	await _hands.pad(JOY_BUTTON_A)
	var padded: bool = labels.get_labels()[1]["on"] and _hands.texts(place).has("Bruised")
	(removes[0] as Control).grab_focus()
	await _hands.key(KEY_ENTER)
	var keyed: bool = labels.get_labels().map(func(one: Dictionary) -> String: return str(one["words"])) == ["Bruised"]
	var restore: Pressable = _hands.presses_of(Marks.Labels.PUTS_LABELS_BACK, {under = place})[0]
	await _hands.click(restore)
	_said["chips_by_mouse_keys_pad"] = bare and clicked and padded and keyed and labels.get_labels().size() == 2 and not restore.is_usable()
