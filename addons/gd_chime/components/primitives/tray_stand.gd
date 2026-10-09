extends "layout.gd"

const Notifications := preload("../../notifications.gd")
const Feedback := preload("../../theme_feedback.gd")

## What a sample's words are made of: the widest letter, never shown.
const LETTER := "M"

## Where a notification tray stands (notification_tray.gd): a column holding
## the tray's list, which tells the notifications (notifications.gd) a tray
## stands as it enters the tree, and that it no longer does as it leaves -
## and which holds the tray's room, whether any stands or not.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS THE TRAY'S MARK, AND NOTHING ELSE'S. Whatever else reads the
## notifications standing - a count on a button - shows none of them, so
## reading them never counts as a tray; only this does. A tray in a place
## that is not on the screen still stands: the tray lives in the app's
## frame, and a place showing none is not a notification shown nowhere.
##
## ITS ROOM IS HELD, AND NEVER GROWS: it needs one notification, as tall
## and as wide as a SAMPLE - a notification described as the tray describes
## one at its fullest, built here first and never shown, so it is measured
## in the look worn now, again as the look changes, and walked to by
## nothing - and never what the notification showing needs: what is more
## scrolls within the room (notification_tray.gd). So the room it needs
## does not move as notifications arrive, wait and leave, and nothing above
## it is placed again for them. It says whether words fit a notification's
## lines at the width left them beside its presses (fits), so words that do
## not are reported as they are made (notifications.gd).
##
## A TRAY IN THE INSTRUCTION'S PLACE HOLDS NO ROOM (notification_tray.gd,
## in_line): it stands in a line that is there already, is given no sample,
## needs only what that line needs, and says any words fit.
##
## It lays out as the column it is, and draws nothing of its own.

var _notifications: Notifications
var _sample: Control = null  # the notification measured for the room, hidden
var _holds_room: bool = true  # whether it holds a room of its own; one stood in a line that is there does not


func _init(notifications: Notifications, style: StringName) -> void:
	super(COLUMN, style)
	_notifications = notifications


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_notifications.add_tray(self)
	if what == NOTIFICATION_EXIT_TREE:
		_notifications.remove_tray(self)


## The room of one notification, the sample's size, and never what the one
## showing needs: what is more scrolls within it.
func _get_minimum_size() -> Vector2:
	# holding no room, it needs what the line it holds needs, as the column it is
	if not _holds_room:
		return super()
	# asked as it is attached, before its sample is built into it: nothing, until then
	if _sample == null:
		return Vector2.ZERO
	return _sample.get_combined_minimum_size()


## Whether these words fit a notification's lines at the width they get
## where this stands - its width less the notice's box and the presses
## beside the words, as the sample has them - in the words' own kind: a
## wider tray fits more. Not yet placed, it cannot say, and says they fit;
## and one holding no room has no lines to fit, and says so of any words.
func fits(words: String) -> bool:
	if size.x <= 0.0 or not _holds_room:
		return true
	var font := get_theme_font(&"font", Themes.FACE)
	var font_size := get_theme_font_size(&"font_size", Themes.FACE)
	# all of the sample's least width but its line of words is the box and the presses
	var inside := size.x - _sample.get_combined_minimum_size().x + font.get_string_size(sample_line(self), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var tall := font.get_multiline_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, inside, font_size).y
	return tall <= font.get_height(font_size) * get_theme_constant(Feedback.LINES, Themes.NOTICE) + 0.5


## A line of a sample's words in the look worn where this control or window
## stands: as many of the widest letter as the look says a line holds at least.
static func sample_line(at: Object) -> String:
	return LETTER.repeat(at.get_theme_constant(Feedback.LETTERS, Themes.NOTICE))


## The sample to measure by: built, hidden, and the room needed asked again as it is.
func hold(sample: Control) -> void:
	_sample = sample
	_sample.visible = false
	update_minimum_size()


## The builder's door: a stand for these notifications' tray, its sample
## made now, in the look it is built under, built first and hidden, the list
## built into it after.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"tray_stand").new(desc.props["notifications"], desc.props["style"])
	made._holds_room = desc.props.has("sample")
	ui.attach(made, parent, desc.facts)
	# a tray standing in a line that is there already holds no room, and is given no sample to measure one by
	if desc.props.has("sample"):
		made.hold(ui.build(desc.props["sample"].call(), made))
	return made
