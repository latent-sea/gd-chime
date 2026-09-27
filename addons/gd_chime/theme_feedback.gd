extends RefCounted

const Themes := preload("theme.gd")
const Flex := preload("components/primitives/flex.gd")

## FEEDBACK, as the floor's look draws it until a look says otherwise:
## everything that tells the reader how something stands - loading's mark
## and the shape standing in for what has not landed, a picture loading as
## they near it, a notification, a status's mark and its line, a progress
## bar, a badge of how pressing something is, a person's initials, a
## countdown, the bubble pointing at what to look at, and what stands over a
## list pulled to refresh.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It holds nothing and draws nothing: theme.gd calls dress() as it is
## built, over the palette it was given, and a look dresses any of these
## again after it. It names a colour only by the palette's name for it. Its
## numbers are PLACEHOLDERS nobody has decided, and theme_placeholders.gd
## holds them with the rest: loading's turn and fade, how long a
## notification stays, how big a status's mark is.
##
## NOTHING HERE SAYS A THING BY HUE ALONE. A status's mark says its state by
## its shape (status.gd) and by its words, its ink only beside them; a
## badge's level is a mark of bars, filled as many as it is pressing, beside
## its words; a progress bar's share is its length, and its words say it; an
## avatar is initials on the raised ground.

## How long a notification stays before it leaves, in milliseconds: a Motion token, read from the window's look.
const STAYS := &"notice_stays"
## How many lines of words a notification may run to, and how many letters
## its line holds at least beside its presses: constants under Notice. The
## tray's room holds one notification, as was ruled.
const LINES := &"lines"
const LETTERS := &"letters"
## A picture loading as the reader nears it: its box, and its shape.
const LAZY_IMAGE := &"LazyImage"
## A status's mark - its size its panel's margins, its states' inks its colours - and a mark beside its words, in one line.
const STATUS_MARK := &"StatusMark"
const STATUS_LINE := &"StatusLine"
## A person's initials, on a ground of their own.
const AVATAR := &"Avatar"
const AVATAR_INITIALS := &"AvatarInitials"
## A badge at each level, from nothing pressing to the most, and its words.
const BADGES: Array[StringName] = [&"Badge0", &"Badge1", &"Badge2", &"Badge3", &"Badge4"]
const BADGE_LABEL := &"BadgeLabel"
## How far through something is: the line it stands in and the bar drawn in it.
const PROGRESS := &"Progress"
const PROGRESS_BAR := &"ProgressLine"
## How long is left, the bubble pointing at what to look at, and what stands over a list pulled to refresh.
const COUNTDOWN := &"Countdown"
const BUBBLE := &"Bubble"
const PULL := &"PullIndicator"
## Each state a status's mark is drawn in, and the palette's ink it takes until a look says otherwise.
const INKS := {&"well": &"ink_soft", &"notice": &"accent", &"fault": &"ink", &"mending": &"accent", &"still": &"ink_soft"}
## Each kind of words a mark draws, and its size.
const SIZES := {AVATAR_INITIALS: 16, BADGE_LABEL: 16}
## A badge's mark: how many bars, each how wide and how far apart, and how tall the tallest.
const BARS := 4
const BAR_WIDTH := 4.0
const BAR_GAP := 2.0
const BAR_TALL := 14.0


static func dress(theme: Theme, palette: Dictionary) -> void:
	# every kind of words a mark draws, a Label sized once
	for kind: StringName in SIZES:
		theme.set_type_variation(kind, &"Label")
		theme.set_font_size(&"font_size", kind, SIZES[kind])
	# every ground that says how something stands: a surface, until a look draws it otherwise
	for ground: StringName in [Themes.LOADING, Themes.PLACEHOLDER, Themes.NOTICE, STATUS_MARK, AVATAR, COUNTDOWN, BUBBLE]:
		theme.set_type_variation(ground, Themes.SURFACE)
	_waiting(theme, palette)
	_status(theme, palette)
	_marks(theme, palette)
	# the pull's words and mark, in the middle of the room it opens; progress in a line of its own
	for line: StringName in [PULL, PROGRESS]:
		theme.set_type_variation(line, Themes.ROW)
		theme.set_constant(&"gap", line, 12)
	theme.set_constant(&"justify", PULL, Flex.CENTER)
	theme.set_constant(&"align", PULL, Flex.CENTER)
	theme.set_type_variation(PROGRESS_BAR, &"Control")
	theme.set_color(&"track", PROGRESS_BAR, palette[&"lit"])
	theme.set_color(&"line", PROGRESS_BAR, palette[&"accent"])
	theme.set_constant(&"thick", PROGRESS_BAR, 10)


## What stands where something has not landed: loading's mark, the shape
## standing in for a line of words, a picture on its way, and a
## notification arriving.
static func _waiting(theme: Theme, palette: Dictionary) -> void:
	# loading's mark: a small square in the accent, its corners eased, which the track turns a quarter at a time
	var mark := _flat(palette[&"accent"], 3)
	mark.set_content_margin_all(9.0)
	theme.set_stylebox(&"panel", Themes.LOADING, mark)
	# the shape standing in for what has not landed: a bar the height of a line of words, on the lit ground
	var shape := _flat(palette[&"lit"], 4)
	shape.content_margin_left = 90.0
	shape.content_margin_right = 90.0
	shape.content_margin_top = 14.0
	shape.content_margin_bottom = 14.0
	theme.set_stylebox(&"panel", Themes.PLACEHOLDER, shape)
	# a picture loading as the reader nears it (lazy_image.gd): the lit ground standing in, cornered as a placeholder is
	theme.set_stylebox(&"panel", LAZY_IMAGE, _flat(palette[&"lit"], 4))
	# a notification: the raised ground, padded, a bar of the accent along its leading edge
	var notice := _flat(palette[&"raised"], 0)
	notice.border_color = palette[&"accent"]
	notice.border_width_left = 6
	notice.set_content_margin_all(12.0)
	theme.set_stylebox(&"panel", Themes.NOTICE, notice)


## A status: a mark whose margins are its size, the shape drawn over the
## whole of it, and the line it stands in beside its words.
static func _status(theme: Theme, palette: Dictionary) -> void:
	var half := float(theme.get_constant(&"mark", STATUS_MARK))
	var room := StyleBoxEmpty.new()
	room.set_content_margin_all(half)
	theme.set_stylebox(&"panel", STATUS_MARK, room)
	# every state, its ink
	for state: StringName in INKS:
		theme.set_color(state, STATUS_MARK, palette[INKS[state]])
	# a mark beside its words, close, both in the middle of the line, so the mark keeps its size
	theme.set_type_variation(STATUS_LINE, Themes.ROW)
	theme.set_constant(&"gap", STATUS_LINE, int(half))
	theme.set_constant(&"align", STATUS_LINE, Flex.CENTER)


## The marks a thing carries about itself: initials on a round ground, and
## a badge at each level - an outline, and the mark of bars before its
## words, the most pressing two in the accent.
static func _marks(theme: Theme, palette: Dictionary) -> void:
	var round := _flat(palette[&"raised"], 6)
	round.border_color = palette[&"ink_soft"]
	round.set_border_width_all(2)
	round.set_content_margin_all(4.0)
	round.set_corner_radius_all(99)
	round.content_margin_left = 8.0
	round.content_margin_right = 8.0
	theme.set_stylebox(&"panel", AVATAR, round)
	# every level of a badge: its outline, and its bars filled up to the level
	for level: int in BADGES.size():
		theme.set_type_variation(BADGES[level], Themes.SURFACE)
		var outline := _flat(palette[&"ground"], 6)
		outline.draw_center = false
		outline.border_color = palette[&"accent"] if level >= 3 else palette[&"ink_soft"]
		outline.set_border_width_all(2)
		var badge := Marked.new(outline, level, palette[&"accent"] if level >= 3 else palette[&"ink"], (palette[&"ink_soft"] as Color).lerp(palette[&"lit"], 0.6))
		badge.set_content_margin_all(4.0)
		badge.content_margin_left = 8.0 + BARS * (BAR_WIDTH + BAR_GAP) + 4.0
		badge.content_margin_right = 8.0
		theme.set_stylebox(&"panel", BADGES[level], badge)


## A flat box of one fill, its corners rounded this much.
static func _flat(fill: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	return box


## A badge's box: its outline, and the mark of its level - BARS bars rising
## left to right at its start, as many filled as the level and the rest
## faint. Its colours are its own, taken from the palette as it is dressed,
## so it draws the same wherever the theme holding it is merged.
class Marked extends StyleBox:
	var outline: StyleBox
	var filled: int
	var ink: Color
	var faint: Color

	func _init(edge: StyleBox, level: int, full: Color, empty: Color) -> void:
		outline = edge
		filled = level
		ink = full
		faint = empty

	func _draw(canvas: RID, rect: Rect2) -> void:
		outline.draw(canvas, rect)
		var middle := rect.position.y + rect.size.y / 2.0
		# every bar of the mark, rising, filled up to the level
		for bar: int in BARS:
			var tall := BAR_TALL * float(bar + 1) / float(BARS)
			RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.position.x + 8.0 + bar * (BAR_WIDTH + BAR_GAP), middle + BAR_TALL / 2.0 - tall, BAR_WIDTH, tall), ink if bar < filled else faint)
