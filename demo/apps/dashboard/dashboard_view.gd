extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const DashboardData := preload("res://demo/apps/dashboard/dashboard_data.gd")

## The dashboard laid out: in the shell's bar, what it is, the stretch, the
## comparison and the filters' chips; in its work, the four figures, the
## map, the bars and the two charts of the days, in named areas; in its
## foot, how many incidents are held and how long the figures took.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every piece is a floor recipe over the one filters and the one set of
## measures; this says what each figure is called, its unit, and its words
## for nothing - the stretches offered and what the one before each is
## called - and the columns of the rows behind a figure.
##
## THE COMPARISON IS THE INTERFACE'S OWN (local.gd): whether each figure is
## set beside the stretch before changes nothing a model holds, so it is a
## local the toggle presses and every card, bar and chart reads - no action,
## no model, no chip.
##
## THE DAYS SET BY HAND stand in for the form's date field (date_field.gd,
## on the form's branch), which date_range.gd takes in their place: a day
## earlier, the day written, a day later - each a press of the filters'
## action with {"value": a day}, the payload the date field carries.

## The column a region is filtered by: pressed on the map, on a bar, or offered by an alert.
const REGION := &"region"
## Every region's customers without supply at the stretch's end, for the alerts; and every region's customers cut off in the stretch, for the map.
const OUT_BY_REGION := &"out_by_region"
const CUT_OFF_BY_REGION := &"cut_off_by_region"
## The stretches offered, by the value each is picked as.
const TODAY := &"today"
const WEEK := &"week"
const MONTH := &"month"
const BY_HAND := &"by_hand"
## What the stretch before is called, on its own - a chart's key for it -
## and within a figure's change; the days set by hand of one day, and of more.
const ONE_DAY := &"one_day"
const DAYS_BEFORE := &"days_before"
const BEFORE_WORDS := {TODAY: "Yesterday", WEEK: "The 7 days before", MONTH: "The 30 days before", ONE_DAY: "The day before", DAYS_BEFORE: "The %d days before"}
const BEFORE_WITHIN := {TODAY: "yesterday", WEEK: "the 7 days before", MONTH: "the 30 days before", ONE_DAY: "the day before", DAYS_BEFORE: "the %d days before"}
## The mark before the comparison's words while it is on.
const ON_MARK := "✓ "
const OFF_MARK := ""

var _ui: GdChime.Ui
var _filters: GdChime.Filters
var _measures: GdChime.Measures
var _drill: GdChime.Desc  # the rows behind a figure, which every card opens
var _comparing: GdChime.Local  # whether every figure is set beside the stretch before


func _init(ui: GdChime.Ui, filters: GdChime.Filters, measures: GdChime.Measures, drill: GdChime.Desc) -> void:
	_ui = ui
	_filters = filters
	_measures = measures
	_drill = drill
	_comparing = ui.local(false)


## The stretches the reader picks from, handed to the filters as data: the
## last of them sets no length, so its days are the reader's own.
static func stretches() -> Array:
	return [{"value": TODAY, "words": GdChime.Phrase.of("Today"), "days": 1}, {"value": WEEK, "words": GdChime.Phrase.of("7 days"), "days": 7}, {"value": MONTH, "words": GdChime.Phrase.of("30 days"), "days": 30}, {"value": BY_HAND, "words": GdChime.Phrase.of("Custom")}]


## What the stretch before is called, shown on its own: a chart's key for it.
func before_words() -> GdChime.Phrase:
	return _before(BEFORE_WORDS)


## What it is called inside a figure's change: "Up 4% on the 7 days before".
func before_within() -> GdChime.Phrase:
	return _before(BEFORE_WITHIN)


## The stretch before in one of its two ways of being said: the days set by hand by how many they run.
func _before(words: Dictionary) -> GdChime.Phrase:
	var days: int = _filters.stretch.get_stretches()["now"]["days"]
	var which: StringName = _filters.stretch.get_picked() if not _filters.stretch.get_by_hand() else (ONE_DAY if days == 1 else DAYS_BEFORE)
	return GdChime.Phrase.with(words[which], [days]) if which == DAYS_BEFORE else GdChime.Phrase.of(words[which])


## The shell: the bar over the areas, scrolled where they are taller than the window, over the foot; the tray offering a region.
func shell(notifications: GdChime.Notifications, layouts: Dictionary, held: int) -> GdChime.Desc:
	var bar := [_ui.text(GdChime.Phrase.of("Network operations"), GdChime.Themes.WORDS), GdChime.DateRange.make(_ui, _filters.stretch, _days_stepped), _comparison(), GdChime.FilterSet.chips(_ui, _filters, {"toggles": GdChime.Filters.TURNS, "removes": GdChime.Filters.REMOVES})]
	return GdChime.Shell.make(_ui, bar, _ui.scroll(_areas(layouts)), {status = _status(held), notifications = notifications, offers = {GdChime.Filters.picks_of(REGION): &""}})


## The comparison's toggle: it says it is on by a mark before its words and
## the look's marked style (Pressables.TOGGLE_ON), never a hue alone.
func _comparison() -> GdChime.Desc:
	var said: GdChime.Bound = _comparing.map(func(on: bool) -> GdChime.Phrase: return GdChime.Phrase.joined([ON_MARK if on else OFF_MARK, GdChime.Phrase.of("Compare with the stretch before")]))
	return _ui.press_local(_comparing, func(on: bool) -> bool: return not on, [_ui.text(said, GdChime.Themes.FACE)], _comparing.map(func(on: bool) -> StringName: return GdChime.Pressables.TOGGLE_ON if on else GdChime.Pressables.TOGGLE_OFF))


## The rows behind a figure, as the drill's grid shows them (table_models.gd).
static func columns() -> Array:
	return [
		{"name": &"reference", "words": GdChime.Phrase.of("Incident"), "share": 0.11, "writes": DashboardData.code_of},
		{"name": &"region", "words": GdChime.Phrase.of("Region"), "share": 0.12, "filters": GdChime.FilterSet.A_LIST},
		{"name": &"town", "words": GdChime.Phrase.of("Town"), "share": 0.12, "filters": GdChime.FilterSet.A_LIST},
		{"name": &"cause", "words": GdChime.Phrase.of("Cause"), "share": 0.15, "filters": GdChime.FilterSet.A_LIST},
		{"name": &"day", "words": GdChime.Phrase.of("Reported"), "share": 0.13, "filters": GdChime.FilterSet.A_DATE},
		{"name": &"customers", "words": GdChime.Phrase.of("Customers"), "share": 0.09, "filters": GdChime.FilterSet.A_NUMBER},
		{"name": &"repair", "words": GdChime.Phrase.of("Repair, hours"), "share": 0.1, "places": 1, "filters": GdChime.FilterSet.A_NUMBER},
		{"name": &"team", "words": GdChime.Phrase.of("Team"), "share": 0.08, "filters": GdChime.FilterSet.A_LIST},
		{"name": &"status", "words": GdChime.Phrase.of("Status"), "share": 0.1, "filters": GdChime.FilterSet.A_LIST},
	]


## An alert for each region as its customers without supply pass the limit, offering to show the region.
static func alerts(measures: GdChime.Measures, over: float) -> Array:
	return DashboardData.REGIONS.keys().map(func(region: String) -> Dictionary: return {"reads": GdChime.Bound.new(measures.get_splits).map(func(splits: Variant) -> Variant: return null if splits == null else splits[OUT_BY_REGION].filter(func(one: Dictionary) -> bool: return one["key"] == region)[0]["now"]), "over": over, "says": func(customers: float) -> GdChime.Phrase: return GdChime.Phrase.with("%s: %s customers without service", [region, GdChime.Phrase.written(func() -> String: return GdChime.Formats.written_number(customers))]), "offer": GdChime.Filters.picks_of(REGION), "payload": {"picked": region}})


## The four figures, the map, the bars and the days, in their areas.
func _areas(layouts: Dictionary) -> GdChime.Desc:
	var before: GdChime.Bound = _ui.bound(before_words)
	var splits: GdChime.Bound = GdChime.Bound.new(_measures.get_splits)
	var picked: GdChime.Bound = _ui.bound(_filters.get_chosen.bind(REGION))
	var card := func(name: StringName, says: GdChime.Phrase, unit: Callable, places: int, empty: GdChime.Phrase) -> GdChime.Desc: return GdChime.KpiCard.make(_ui, GdChime.Drills.SHOWS_ROWS_BEHIND, GdChime.Bound.new(_measures.get_figures).field(name), {payload = {"figure": name}, says = says, unit = unit, comparing = _comparing, before_words = _ui.bound(before_within), says_empty = empty, places = places}).opens(_drill)
	var by_region: GdChime.Desc = GdChime.BarChart.make(_ui, GdChime.Filters.picks_of(REGION), splits.map(func(all: Variant) -> Variant: return null if all == null else all[&"by_region"]), {picked = picked, comparing = _comparing, before_words = before, unit = func(amount: Variant) -> GdChime.Phrase: return GdChime.Phrase.with("%s incidents", [amount]), says_empty = GdChime.Phrase.of("No incidents in this stretch"), offers = [GdChime.Drills.SHOWS_ROWS_BEHIND]})
	var map: GdChime.Desc = GdChime.RegionMap.make(_ui, GdChime.Filters.picks_of(REGION), DashboardData.regions(), splits.map(func(all: Variant) -> Variant: return null if all == null else all[CUT_OFF_BY_REGION]), {picked = picked, says = GdChime.Phrase.of("The more customers cut off, the heavier the shade"), says_empty = GdChime.Phrase.of("Nobody was cut off in this stretch")})
	var days := GdChime.Phrase.of("Days before the last")
	return _ui.areas({
		&"cut_off": card.call(&"cut_off", GdChime.Phrase.of("Customers who lost supply"), func(amount: Variant) -> GdChime.Phrase: return GdChime.Phrase.with("%s customers", [amount]), 0, GdChime.Phrase.of("Nobody lost supply")),
		&"reported": card.call(&"reported", GdChime.Phrase.of("Incidents reported"), func(amount: Variant) -> GdChime.Phrase: return GdChime.Phrase.with("%s incidents", [amount]), 0, GdChime.Phrase.of("No incidents")),
		&"repair": card.call(&"repair", GdChime.Phrase.of("Average repair"), func(amount: Variant) -> GdChime.Phrase: return GdChime.Phrase.with("%s hours", [amount]), 1, GdChime.Phrase.of("Nothing was repaired")),
		&"field_hours": card.call(&"field_hours", GdChime.Phrase.of("Hours of field work"), func(amount: Variant) -> GdChime.Phrase: return GdChime.Phrase.with("%s hours", [amount]), 0, GdChime.Phrase.of("No field work")),
		&"map": _panel(GdChime.Phrase.of("Where customers lost supply"), map),
		&"bars": _panel(GdChime.Phrase.of("Incidents by region"), by_region),
		&"incidents": _panel(GdChime.Phrase.of("Incidents a day"), GdChime.MeasureCharts.trend(_ui, _measures, &"reported", {says = GdChime.Phrase.of("Incidents"), x_words = days, y_words = "", says_empty = GdChime.Phrase.of("No incidents in this stretch"), comparing = _comparing, before_words = before})),
		&"repairs": _panel(GdChime.Phrase.of("Repair times, in hours"), GdChime.MeasureCharts.band(_ui, _measures, &"repairs", {says_middle = GdChime.Phrase.of("The middle repair"), says_half = GdChime.Phrase.of("The middle half of repairs"), x_words = "", y_words = "", says_empty = GdChime.Phrase.of("Nothing was repaired in this stretch")})),
	}, layouts)


## A chart on its ground, under what it shows.
func _panel(heading: GdChime.Phrase, content: GdChime.Desc) -> GdChime.Desc:
	return _ui.surface(GdChime.Themes.RAISED, [_ui.column([_ui.text(heading, GdChime.Themes.FACE).wraps(), content.grow()])])


## The foot: how many incidents are held, and how long the figures took or that they are being worked out.
func _status(held: int) -> GdChime.Bound:
	var written := GdChime.Phrase.written(func() -> String: return GdChime.Formats.written_number(held))
	return GdChime.Bound.both(GdChime.Bound.new(_measures.get_busy), GdChime.Bound.new(_measures.get_took_ms), func(busy: bool, took: float) -> GdChime.Phrase: return GdChime.Phrase.with("%s incidents held. %s", [written, GdChime.Phrase.of("Working out the figures") if busy else GdChime.Phrase.with("The figures took %s ms", [roundi(took)])]))


## The custom days' stand-in: a day earlier, the day, a day later, each through the filter.
static func _days_stepped(ui: GdChime.Ui, action: StringName, shows: GdChime.Bound) -> GdChime.Desc:
	var day := shows.map(func(at: Variant) -> Variant: return null if at == null else GdChime.Phrase.written(func() -> String: return GdChime.Formats.written_date(int(at) * GdChime.PackedRows.DAY_SECONDS)))
	var away := func(by: float) -> GdChime.Bound: return shows.map(func(at: Variant) -> Dictionary: return {"value": int(at) + int(by)})
	return GdChime.Stepper.steps(ui, action, {shows = ui.text(day, GdChime.Themes.REASON), carries = away})
