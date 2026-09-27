extends "gd_chime_on_first_use.gd"

## The facade's recipes: every piece of interface assembled from the
## vocabulary, each named here and fetched the first time its name is read.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Read through the one name, as `GdChime.Card`, `GdChime.Shell.make(...)`,
## `GdChime.FilterSet.A_LIST`: a static var is inherited, so where in the
## facade's chain a name is written is not something a call site knows.
##
## Every recipe but one is here, because no application names a recipe where
## GDScript demands a constant - never as a type, and only the console's
## `const STATES` reads one (Status) inside a constant of its own, which puts
## that one in gd_chime.gd. That is what makes the recipes worth having lazily:
## they are the fat of the framework, 66 of the facade's 163 names, and an
## application draws a handful of them.
##
## A name here is a PROMISE (CONSTITUTION.md): removing one or pointing it
## somewhere else is a break, written in the CHANGELOG. Adding one is not.
## IT IS A LIST AND NOTHING ELSE: no function, no value, never made.
##
## What it costs: a name written here can no longer be used as a TYPE. Moving
## one back to a constant, if an application ever needs to annotate with it,
## is a one-line change to gd_chime.gd - and pays the compile of that recipe's
## whole subtree at every application's start, whether it draws one or not.

## --- the recipes, each fetched on its first use ---
static var AdaptiveNav: GDScript:
	get: return _at("components/recipes/adaptive_nav.gd")
static var AmountField: GDScript:
	get: return _at("components/recipes/amount_field.gd")
static var Attention: GDScript:
	get: return _at("components/recipes/attention.gd")
static var Avatar: GDScript:
	get: return _at("components/recipes/avatar.gd")
static var Badge: GDScript:
	get: return _at("components/recipes/badge.gd")
static var BarChart: GDScript:
	get: return _at("components/recipes/bar_chart.gd")
static var Board: GDScript:
	get: return _at("components/recipes/board.gd")
static var Bracket: GDScript:
	get: return _at("components/recipes/bracket.gd")
static var CalendarSheet: GDScript:
	get: return _at("components/recipes/calendar_sheet.gd")
static var Card: GDScript:
	get: return _at("components/recipes/card.gd")
static var CellReadout: GDScript:
	get: return _at("components/recipes/cell_readout.gd")
static var Chip: GDScript:
	get: return _at("components/recipes/chip.gd")
static var Collection: GDScript:
	get: return _at("components/recipes/collection.gd")
static var Combo: GDScript:
	get: return _at("components/recipes/combo.gd")
static var CommandPalette: GDScript:
	get: return _at("components/recipes/command_palette.gd")
static var Confirm: GDScript:
	get: return _at("components/recipes/confirm.gd")
static var ConnectionStatus: GDScript:
	get: return _at("components/recipes/connection_status.gd")
static var ContextMenu: GDScript:
	get: return _at("components/recipes/context_menu.gd")
static var Countdown: GDScript:
	get: return _at("components/recipes/countdown.gd")
static var DataGrid: GDScript:
	get: return _at("components/recipes/data_grid.gd")
static var DateRange: GDScript:
	get: return _at("components/recipes/date_range.gd")
static var Disposition: GDScript:
	get: return _at("components/recipes/disposition.gd")
static var Divider: GDScript:
	get: return _at("components/recipes/divider.gd")
static var Drawer: GDScript:
	get: return _at("components/recipes/drawer.gd")
static var DrillDown: GDScript:
	get: return _at("components/recipes/drill_down.gd")
static var FacetList: GDScript:
	get: return _at("components/recipes/facet_list.gd")
static var FilterSet: GDScript:
	get: return _at("components/recipes/filter_set.gd")
static var FormField: GDScript:
	get: return _at("components/recipes/form_field.gd")
static var FormReview: GDScript:
	get: return _at("components/recipes/form_review.gd")
static var FormSteps: GDScript:
	get: return _at("components/recipes/form_steps.gd")
static var Gallery: GDScript:
	get: return _at("components/recipes/gallery.gd")
static var Graph: GDScript:
	get: return _at("components/recipes/relationship_graph.gd")
static var Hint: GDScript:
	get: return _at("components/recipes/hint.gd")
static var InfiniteCollection: GDScript:
	get: return _at("components/recipes/infinite_collection.gd")
static var InlineChoice: GDScript:
	get: return _at("components/recipes/inline_choice.gd")
static var InstructionBar: GDScript:
	get: return _at("components/recipes/instruction_bar.gd")
static var KpiCard: GDScript:
	get: return _at("components/recipes/kpi_card.gd")
static var Lanes: GDScript:
	get: return _at("components/recipes/lanes.gd")
static var LineChart: GDScript:
	get: return _at("components/recipes/line_chart.gd")
static var LiveFeed: GDScript:
	get: return _at("components/recipes/live_feed.gd")
static var Loading: GDScript:
	get: return _at("components/recipes/loading.gd")
static var LongTable: GDScript:
	get: return _at("components/recipes/long_table.gd")
static var Matrix: GDScript:
	get: return _at("components/recipes/matrix.gd")
static var MeasureCharts: GDScript:
	get: return _at("components/recipes/measure_charts.gd")
static var Moment: GDScript:
	get: return _at("components/recipes/moment.gd")
static var NavControl: GDScript:
	get: return _at("components/recipes/nav_control.gd")
static var NotificationTray: GDScript:
	get: return _at("components/recipes/notification_tray.gd")
static var Panes: GDScript:
	get: return _at("components/recipes/panes.gd")
static var Progress: GDScript:
	get: return _at("components/recipes/progress.gd")
static var PromptBar: GDScript:
	get: return _at("components/recipes/prompt_bar.gd")
static var PullToRefresh: GDScript:
	get: return _at("components/recipes/pull_to_refresh.gd")
static var QuickView: GDScript:
	get: return _at("components/recipes/quick_view.gd")
static var RegionMap: GDScript:
	get: return _at("components/recipes/region_map.gd")
static var Sections: GDScript:
	get: return _at("components/recipes/sections.gd")
static var Setting: GDScript:
	get: return _at("components/recipes/setting.gd")
static var Sheet: GDScript:
	get: return _at("components/recipes/sheet.gd")
static var Shell: GDScript:
	get: return _at("components/recipes/shell.gd")
static var Stepper: GDScript:
	get: return _at("components/recipes/stepper.gd")
static var SwipeRow: GDScript:
	get: return _at("components/recipes/swipe_row.gd")
static var Table: GDScript:
	get: return _at("components/recipes/table.gd")
static var Tabs: GDScript:
	get: return _at("components/recipes/tab_bar.gd")
static var TextArea: GDScript:
	get: return _at("components/recipes/text_area.gd")
static var TextField: GDScript:
	get: return _at("components/recipes/text_field.gd")
static var TypeAhead: GDScript:
	get: return _at("components/recipes/type_ahead.gd")
static var Wall: GDScript:
	get: return _at("components/recipes/wall.gd")
