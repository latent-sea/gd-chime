extends "res://addons/gd_chime/application.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const DashboardData := preload("res://demo/apps/dashboard/dashboard_data.gd")
const DashboardView := preload("res://demo/apps/dashboard/dashboard_view.gd")
const DashboardProbe := preload("res://demo/apps/dashboard/dashboard_probe.gd")

## Application 1, the executive analytics dashboard: a national electricity
## network's operations over ninety days of faults - customers who lost
## supply, incidents reported, the average repair, the hours of field work -
## by region, over the days, and on a map; filtered by a stretch of days,
## compared with the stretch before, and by a region pressed anywhere.
##
## EVERY FIGURE IS THE STRETCH'S: taken over the incidents reported or
## restored in the days chosen, so today, 7 days, 30 days and custom days
## each move every card, chart and the map. An alert watches the moment the
## stretch ends - now, for every preset: a region with more customers
## without supply then than the limit.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/apps/dashboard/dashboard.gd
##       [-- --look=<a gallery look; swiss unless asked>] [-- --probe]
##
## EVERYTHING IS THE FLOOR'S: one filters (filters.gd) every card and chart
## reads - the region a column of it, the days its date column, the
## stretches handed in as data; one rollup of every figure off the frame
## (measures.gd); the KPI cards, the bars, the map and the charts of the days
## (kpi_card.gd, bar_chart.gd, region_map.gd, measure_charts.gd), each with
## its loading and empty states; named areas re-flowing between a wide
## window and one on its end (areas.gd); the stretch (date_range.gd); a
## figure pressed - or a bar's context menu - opens the rows behind it in the
## data grid (drills.gd, drill_down.gd); a region's customers passing a limit
## is an alert in the shell's tray (thresholds.gd, shell.gd). This names the
## figures, the stretches and the words, and lays them out.

const BOARD := &"board"
## The column a region is filtered by - pressed on the map, on a bar, or offered by an alert.
const REGION := DashboardView.REGION
## The dashboard's own look, worn unless another is asked for: every application has its own.
const OWN_LOOK := &"swiss"
## Every figure the dashboard shows, each over the stretch, and the splits by region: two over the stretch, and the customers without supply now, for the alerts (rollup.gd).
const SPEC := {
	"figures": {
		&"cut_off": {"how": GdChime.Rollup.SUM, "of": &"customers", "when": &"reported"},
		&"reported": {"how": GdChime.Rollup.COUNT, "when": &"reported"},
		&"repair": {"how": GdChime.Rollup.MEAN, "of": &"repair", "when": &"restored"},
		&"field_hours": {"how": GdChime.Rollup.SUM, "of": &"repair", "when": &"restored"},
		&"repairs": {"how": GdChime.Rollup.SPREAD, "of": &"repair", "when": &"restored"},
	},
	"splits": {&"by_region": {"how": GdChime.Rollup.COUNT, "when": &"reported", "by": &"region"}, &"cut_off_by_region": {"how": GdChime.Rollup.SUM, "of": &"customers", "when": &"reported", "by": &"region"}, &"out_by_region": {"how": GdChime.Rollup.SUM, "of": &"customers", "when": GdChime.Rollup.OPEN, "by": &"region"}},
}
## A region's customers without supply past this is an alert.
const ALERT_OVER := 15000.0
## Wide - the figures along the top, the map at the left, the bars beside it, the days wide at the right - and, on its end, one over another.
const LAYOUTS := {
	&"wide": {"least": &"wide_from", "columns": [0.28, 0.24, 0.24, 0.24], "rows": [0.0, 0.25, 0.25], "areas": ["cut_off reported repair field_hours", "map bars incidents incidents", "map bars repairs repairs"]},
	&"narrow": {"least": 0.0, "columns": [0.5, 0.5], "rows": [0.0, 0.0, 0.5, 0.0, 0.0, 0.0], "areas": ["cut_off reported", "repair field_hours", "map map", "bars bars", "incidents incidents", "repairs repairs"]},
}

var rows: GdChime.PackedRows
var filters: GdChime.Filters
var measures: GdChime.Measures
var drills: GdChime.Drills
## The layout, held because what it holds is read as the dashboard draws: its words for the stretch before, and the comparison.
var view: DashboardView
## The drill-down's grid: its view scoped to the rows behind a figure; its models answer from anywhere, as the drill's pop-up is the app's one.
var behind: GdChime.TableModels
## The drill-down itself, the pop-up every figure opens.
var drill: Desc
var menu: GdChime.OpenMenu


## The look asked for at launch, or the dashboard's own - Swiss.
func look() -> Theme:
	return Looks.make(Looks.asked(OWN_LOOK))


func probe() -> RefCounted:
	return DashboardProbe.new(self)


## Every action of the drill-down's, then the dashboard's own with their words.
func declare(register: Actions) -> void:
	GdChime.DrillDown.declare(register)
	register.declare_all({
		GdChime.OpenMenu.OPENS: ["More", Actions.keys(KEY_MENU), Actions.pad(JOY_BUTTON_BACK)],
		GdChime.OpenMenu.PICKS: ["Pick"],
		GdChime.Filters.picks_of(REGION): ["Show the region"],
		GdChime.Stretch.PICKS: ["Stretch"],
		GdChime.Stretch.SETS_FIRST_DAY: ["First day"],
		GdChime.Stretch.SETS_LAST_DAY: ["Last day"],
		GdChime.Filters.TURNS: ["Turn the filter"],
		GdChime.Filters.REMOVES: ["Remove the filter"],
		Notifications.DISMISSES: ["Dismiss"],
	})


## The models made over the incidents - the filters, the measures, the drill's grid, the alerts, the menu - and the shell described.
func describe() -> Desc:
	rows = DashboardData.made()
	filters = GdChime.Filters.new(chimes, {one_of = REGION, on_a_drawing = REGION, dates = {column = &"reported", now = DashboardData.now(), presets = DashboardView.stretches(), starts = DashboardView.WEEK}})
	measures = model(GdChime.Measures.new(chimes, rows, ui.bound(filters.get_rollup), jobs, SPEC, {"opens": &"reported", "closes": &"restored"}))
	behind = GdChime.TableModels.new(ui, rows, DashboardView.columns(), {}, jobs, 16)
	drills = GdChime.Drills.new(chimes, measures, behind, {&"cut_off": GdChime.Phrase.of("Incidents that cut customers off"), &"reported": GdChime.Phrase.of("Incidents reported"), &"repair": GdChime.Phrase.of("Incidents restored"), &"field_hours": GdChime.Phrase.of("Incidents restored"), &"by_region": GdChime.Phrase.of("Incidents reported")}, &"by_region")
	menu = model(GdChime.OpenMenu.new(chimes, commands, actions))
	model(GdChime.Thresholds.new(chimes, notifications, DashboardView.alerts(measures, ALERT_OVER)))
	# the bars' menu, and the rows behind a figure, which every card opens - the drill's own models answering in its pop-up
	GdChime.ContextMenu.make(ui, menu)
	drill = GdChime.DrillDown.make(ui, drills, behind)
	view = DashboardView.new(ui, filters, measures, drill)
	return ui.app(&"app", [ui.screen(BOARD, [view.shell(notifications, LAYOUTS, rows.count())], [filters, drills])])
