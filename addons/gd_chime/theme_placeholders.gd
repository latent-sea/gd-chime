extends RefCounted

const Motion := preload("motion.gd")
const Themes := preload("theme.gd")
const LookSounds := preload("look_sounds.gd")
const Sounds := preload("sounds.gd")
const Pressables := preload("theme_pressables.gd")
const Fields := preload("theme_fields.gd")
const Feedback := preload("theme_feedback.gd")

## PLACEHOLDERS, ALL IN ONE PLACE. Numbers somebody had to pick so the floor
## could be built, that NOBODY HAS DECIDED: a look sets its own over any of
## them, and when the looks are decided this is the list to go through.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The floor's look (theme.gd) puts these on first, before anything else it
## dresses, so every one of them is there for a look to set over. Thousandths
## where the thing is a share or a scale, since a Theme's constants are whole
## numbers. Never a colour: a colour is the palette's, never a placeholder
## number. Kept apart from theme.gd so the list stays one list however many
## styles the floor's look dresses.
##
## ONE SOUND IS A PLACEHOLDER TOO, as was ruled (2026-09-19): a notification
## arriving chimes - a short soft tone made here in numbers, no file, which
## every look carries until it sets its own (look_sounds.gd). Undecided, like
## the rest: its pitch, its length and how soft it is.

## The placeholder chime's numbers: the tone in hertz, how long it sounds in seconds, how loud at its peak out of one, and the rate it is made at.
const CHIME_PITCH := 880.0
const CHIME_LASTS := 0.18
const CHIME_LOUD := 0.12
const CHIME_RATE := 22050


## Every undecided number, put on the look.
static func put(theme: Theme) -> void:
	# an idle breathe: how far it fades and swells at the middle of a breath
	theme.set_constant(&"breathe_opacity", Motion.TYPE, 900)
	theme.set_constant(&"breathe_scale", Motion.TYPE, 1040)
	# a countdown's beat: a second passing in milliseconds, how far the readout dips and swells, and how many last seconds beat
	theme.set_constant(Motion.BEAT, Motion.TYPE, 1000)
	theme.set_constant(&"beat_opacity", Motion.TYPE, 500)
	theme.set_constant(&"beat_scale", Motion.TYPE, 1080)
	theme.set_constant(Motion.BEAT_FOR, Motion.TYPE, 10)
	# a moment's sheet: how small it starts before it settles
	theme.set_constant(&"settle_scale", Motion.TYPE, 920)
	# how many things may start arriving or going in one frame and still move: past it, a filter's or a search's are at rest at once
	theme.set_constant(Motion.BULK, Motion.TYPE, 12)
	# the window's shape: where the size class changes, in base pixels, and how far past an edge it must go to change back
	theme.set_type_variation(&"Shape", &"Control")
	theme.set_constant(&"compact_below", &"Shape", 900)
	theme.set_constant(&"wide_from", &"Shape", 1600)
	theme.set_constant(&"dead_band", &"Shape", 80)
	# how wide a strip's cover of more beyond an end is, in base pixels
	theme.set_constant(&"more_room", &"Scroll", 28)
	# how far beyond a scroll's either end something is near enough to load (nearness.gd), in thousandths of the scroll's height
	theme.set_constant(&"reach", &"Scroll", 750)
	# a slider, in base pixels: its handle's width, its track's thickness, the least its track is long, and the gap before its value's words
	theme.set_constant(&"handle_width", Fields.SLIDER, 20)
	theme.set_constant(&"track_thickness", Fields.SLIDER, 8)
	theme.set_constant(&"least_track", Fields.SLIDER, 160)
	theme.set_constant(&"gap", Fields.SLIDER, 12)
	# an inline option - a radio's, a segment's - in base pixels: the room either side of its words, so joined segments' words stand apart
	theme.set_constant(Pressables.PAD, Pressables.SEGMENT, 12)
	# a long combo's overlay, in thousandths of the window's height: how tall its sheet is, so the options it scrolls have room
	theme.set_constant(Fields.TALL, Fields.COMBO, 600)
	# the marks (theme.gd): how thick a rule is - a divider's, a link's - and the air either side of a divider, twice a link's padding
	theme.set_constant(&"rule", Themes.DIVIDER, 2)
	theme.set_constant(&"air", Themes.DIVIDER, 8)
	# a text area's least and most lines (theme_fields.gd); loading's turn and how long a notification stays, in milliseconds; how far loading's mark fades, in thousandths (theme_feedback.gd)
	theme.set_constant(&"least_lines", Fields.TEXT_AREA, 3)
	theme.set_constant(&"most_lines", Fields.TEXT_AREA, 8)
	theme.set_constant(&"period", Themes.LOADING, 900)
	theme.set_constant(Feedback.STAYS, Motion.TYPE, 6000)
	theme.set_constant(&"loading_opacity", Motion.TYPE, 350)
	# a picture loading as the reader nears it: how tall it is, in thousandths of its width
	theme.set_constant(&"aspect", Feedback.LAZY_IMAGE, 1000)
	# the shell (theme_navigation.gd): a grip's thickness in base pixels, and how far a key or the pad steps it, in thousandths of what it resizes
	theme.set_constant(&"thickness", &"Grip", 8)
	theme.set_constant(&"step", &"Grip", 25)
	# a table's lines (theme_tables.gd), in base pixels: the gap between columns - a resize grip's width - the pad either side of a cell's words, their size, and a rule's thickness
	theme.set_constant(&"gap", &"Cells", 8)
	theme.set_constant(&"pad", &"Cells", 8)
	theme.set_constant(&"words_size", &"Cells", 20)
	theme.set_constant(&"rule", &"Cells", 2)
	# what is live (theme_feedback.gd, throttle.gd, paced_notices.gd): a status mark's half-size and the wall's gap in base pixels; how often a paced count is told, and how soon another notification may stand, in milliseconds
	theme.set_constant(&"mark", &"StatusMark", 9)
	theme.set_constant(&"gap", &"Wall", 6)
	theme.set_constant(&"live_cadence", Motion.TYPE, 250)
	theme.set_constant(&"notice_pace", Motion.TYPE, 6000)
	# how many lines of words a notification may run to, and how many of the widest letter a line holds at least, which the tray's room of one is measured by (notification_tray.gd)
	theme.set_constant(Feedback.LINES, Themes.NOTICE, 2)
	theme.set_constant(Feedback.LETTERS, Themes.NOTICE, 14)
	# a chart (line_chart.gd), in base pixels: how thick its line is and how big a point's marker; and how faint an area under it is, in thousandths
	theme.set_constant(&"line_width", &"LineChart", 2)
	theme.set_constant(&"marker_radius", &"LineChart", 4)
	theme.set_constant(&"fill_alpha", &"LineChart", 220)
	# a dashboard's figures and charts (theme_charts.gd), in base pixels: a KPI card's pad and the sizes of its words - what it is, the figure, its change
	theme.set_constant(&"pad", &"KpiCard", 16)
	theme.set_constant(&"says_size", &"KpiCard", 20)
	theme.set_constant(&"figure_size", &"KpiCard", 44)
	theme.set_constant(&"change_size", &"KpiCard", 18)
	# the least height a drawing is given (canvas.gd), in base pixels: a figure's trend, a line chart's plot, a map
	theme.set_constant(&"least_height", &"KpiTrend", 48)
	theme.set_constant(&"least_height", &"LineChart", 120)
	theme.set_constant(&"least_height", &"RegionMap", 320)
	# a bar chart's bars: the rule down a current bar's side and the gap between bars, in base pixels; a bar's thickness, in thousandths of its track, and the stretch before's tick, in base pixels
	theme.set_constant(&"rule", &"BarChartBar", 4)
	theme.set_constant(&"gap", &"BarChartBar", 4)
	theme.set_constant(&"thickness", &"BarChartTrack", 600)
	theme.set_constant(&"tick_width", &"BarChartTrack", 3)
	# a region map, in base pixels: a region's outline, the picked one's, and the gap between its hatching; and how far the most affected is shaded toward the line's ink, in thousandths
	theme.set_constant(&"outline_width", &"RegionMap", 2)
	theme.set_constant(&"picked_width", &"RegionMap", 5)
	theme.set_constant(&"hatch_gap", &"RegionMap", 10)
	theme.set_constant(&"deepest", &"RegionMap", 850)
	# a collection's least card column (theme_browsing.gd), in base pixels; a drawer's (theme_overlays.gd) share of the window's width, on a window on its side and on its end, in thousandths
	theme.set_constant(&"least_column", &"CollectionCards", 300)
	theme.set_constant(&"wide", &"Drawer", 360)
	theme.set_constant(&"narrow", &"Drawer", 900)
	theme.set_constant(&"tall", &"Drawer", 600)
	theme.set_constant(&"most_wide", &"Drawer", 600)
	# a gallery's pictures: how tall, in thousandths of their width, and a thumbnail's least width, in base pixels
	theme.set_constant(&"aspect", &"GalleryPicture", 1000)
	theme.set_constant(&"aspect", &"GalleryThumbPicture", 1000)
	theme.set_constant(&"least_width", &"GalleryThumbPicture", 72)
	# a facet value's swatch, in base pixels wide, and square
	theme.set_constant(&"least_width", &"FacetSwatch", 24)
	theme.set_constant(&"aspect", &"FacetSwatch", 1000)
	# a quick view's sheet (quick_view.gd), in thousandths of the window: how wide and how tall
	theme.set_constant(&"wide", &"QuickView", 820)
	theme.set_constant(&"high", &"QuickView", 820)
	# a drill-down's sheet (drill_down.gd), in thousandths of the window: how wide and how tall
	theme.set_constant(&"wide", &"DrillDown", 920)
	theme.set_constant(&"high", &"DrillDown", 860)
	# a form's looks (theme_fields.gd), in base pixels: the gap between a question's words, its line and its message; between a calendar's days; the room inside a summary, a section and a step of the review
	theme.set_constant(&"gap", Fields.QUESTION, 4)
	theme.set_constant(&"gap", Fields.WEEK, 4)
	theme.set_constant(&"pad", Fields.SUMMARY, 12)
	# how long typing into a filter rests before its query goes, in milliseconds (query_pacing.gd)
	theme.set_constant(&"typing_settles", Motion.TYPE, 250)
	# a notification arriving: the placeholder chime, every look's until it sets its own
	LookSounds.set_sound(theme, Sounds.NOTIFIED, chime())
	# a finger (touch.gd), in base pixels: how far it moves before it is a gesture, not a tap, and the least a pressable is each way on a phone's window - none until a look sets one, since a table's cells and a board's lanes are laid out for the room they need
	theme.set_type_variation(&"Touch", &"Control")
	theme.set_constant(&"slop", &"Touch", 16)
	theme.set_constant(&"least", &"Touch", 0)
	# how far a row is swiped before letting go does its side's action, in thousandths of its width (swipe.gd)
	theme.set_constant(&"swipe_commit", &"Touch", 400)
	# how far a scroll let go moving glides on: as far as the finger's speed carries it in this many milliseconds (scroll_finger.gd)
	theme.set_constant(&"glide", Motion.TYPE, 350)


## The placeholder chime: a soft sine at its pitch, rising in over the
## first tenth of it and dying away over the rest, in sixteen-bit samples.
static func chime() -> AudioStreamWAV:
	var count := int(CHIME_LASTS * CHIME_RATE)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	# every sample: the tone, under an envelope that rises fast and falls slowly
	for at: int in count:
		var through := float(at) / count
		var envelope := minf(through * 10.0, 1.0) * pow(1.0 - through, 2.0)
		samples.encode_s16(at * 2, int(sin(TAU * CHIME_PITCH * at / CHIME_RATE) * envelope * CHIME_LOUD * 32767.0))
	var made := AudioStreamWAV.new()
	made.format = AudioStreamWAV.FORMAT_16_BITS
	made.mix_rate = CHIME_RATE
	made.data = samples
	return made
