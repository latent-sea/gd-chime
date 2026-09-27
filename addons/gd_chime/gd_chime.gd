extends "gd_chime_floor.gd"
class_name GdChime

## gd-chime, in one name: every script an application needs, re-exported, so
## an app file names THIS and its own files and nothing else. The one global
## name the addon declares, beside ChimeApp (chime_app.gd), the node an
## application extends.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## GdChime.Ui, GdChime.Bound, GdChime.Card, GdChime.Themes.FACE - no preload,
## since the name is global once the addon is in a project. A name here is a
## PROMISE (CONSTITUTION.md): what an application may use is exactly what
## these three files re-export, plus ChimeApp; removing one or pointing it
## somewhere else is a break, written in the CHANGELOG. Adding one is not.
## Everything else in the addon is internal and may change without a word.
##
## THE INDEX, by family - each name's own file says what it is:
## - The application: ChimeApp (chime_app.gd), which an app script extends,
##   answering look(), sources(), declare(), describe() and probe(); its
##   easel (easel.gd); apply_project_settings(window), the one way the
##   framework sets what it needs (needed_settings.gd).
## - The vocabulary: Ui, the builder, whose descriptions are the kinds
##   (floor_kinds.gd - text, image, surface, pressable, field, row, column,
##   grid, stack, scroll, virtual_list, cells, view, when, each, and the
##   places: app, screen, pop_up); Desc, a description; Bound, Local,
##   PressLocal, the values a description reads; Places; Text, Pressable,
##   Draggable, Grip, MenuTarget, Layout, Transition, SimulatedSight.
## - The look: Themes, the Theme itself; Look and PaintedBox, Paint, which
##   dress one; and its families of types - Pressables, Fields, Tables,
##   Overlays, Charts, Feedback, Collections, Navigation; MotionTokens.
## - The floor: Chimes, Belfry, Commands, Driver, Controller, Actions,
##   Inputs, Prompts, Language, Phrase, Formats, Dates, Motion, Shape,
##   Sounds, Notifications, Reads, Question, Guide, Console, DevCommands,
##   DebugLog, Touch, Token, Stretch.
## - The models an application is made of: Form, FormActions, Calendar,
##   CommandSearch, Narrowing, Filters, RowQuery, RowFilters, RowSelection,
##   RowEdits, EditingCell, TableColumns, TableModels, PackedRows,
##   QueriedRows, QueryPacing, Feed, GrowingList, LongList, KeyedItems,
##   Lane, Orders, Outbox, Fetched, Connection, Documents, Drills,
##   ImageLoads, Measures, OpenMenu, PacedNotices, Provisional, Reminders,
##   RollingSeries, Rollup, SettingsFile, SaveShape, Stream, Taken,
##   Thresholds, Throttle, ViewBehind.
## - The recipes (gd_chime_recipes.gd): what a screen is made of - Shell,
##   Panes, Tabs, AdaptiveNav, NavControl, Sheet, Drawer, QuickView,
##   DrillDown, ContextMenu, CommandPalette, Confirm, Hint, Moment,
##   Attention, Loading, Progress, Status, NotificationTray, PromptBar,
##   InstructionBar, Divider, Badge, Avatar, Chip, Card, Wall, Gallery,
##   Collection, InfiniteCollection, Board, Lanes, Table, LongTable,
##   DataGrid, Matrix, Sections, Setting, Stepper, SwipeRow,
##   PullToRefresh, FacetList, FilterSet, TypeAhead, Combo, InlineChoice,
##   TextField, TextArea, AmountField, DateRange, CalendarSheet, FormField,
##   FormSteps, FormReview, BarChart, LineChart, MeasureCharts, KpiCard,
##   CellReadout, Countdown, ConnectionStatus, LiveFeed, RegionMap, Graph,
##   Disposition, Bracket.
##
## IT IS A LIST AND ONE CALL. It holds no value and is never made: a facade
## that did more would be a second place where the framework happens, and
## every reader would have to check which of the two they were looking at.
## The one function, apply_project_settings, names nothing of its own - it
## is needed_settings.gd's, put here because a project calls it by the one
## name it knows before it knows any other. Nothing inside gd-chime preloads
## this either - a file of the floor names what it uses - so it can never
## stand between two parts of the framework, only between an application
## and all of it.
##
## THE LIST IS THREE FILES, AND THIS IS THE ONE NAME. The other two hold the
## names that are fetched on their first read - gd_chime_recipes.gd and
## gd_chime_floor.gd, over gd_chime_on_first_use.gd, which this extends. A
## static var is inherited, so `GdChime.Card` reads the same whichever file
## the name is written in, and no call site knows or cares. Three files
## because 163 names cannot live under the 250-line cap, and the cap is what
## made the split honest: the eager names are one kind of thing and the lazy
## names another.
##
## WHAT IS EAGER IS EXACTLY WHAT MUST BE. A `const X := preload(...)` compiles
## that script, and everything it names, when this file loads. Naming all 163
## that way compiled the whole framework before any application's _init, and
## cost every application about a second and a half of its start. So a name is
## a constant here for ONE reason: an application names it somewhere the parser
## must resolve before anything runs - as a TYPE (a variable's, an argument's,
## a return's, an `is`, an element's), or inside a `const` of its own, where the
## value has to be a constant expression. That is the core the framework cannot
## start without (the builder, Bound, Desc, Phrase, Themes) plus the models
## applications annotate with. A name that stops being named so moves to a lazy
## list; a name that starts being named so moves here.
##
## Deliberately absent: the test support, which a test and a probe preload
## by its own path, since it is not what an application is built of; and
## the application node, ChimeApp, which an app script extends - a class
## cannot extend a name it reads through a facade, so that one is global.

## --- the vocabulary: the builder, a description and the values a description reads ---
const Areas := preload("components/primitives/areas.gd")
const Bound := preload("components/primitives/bound.gd")
const Desc := preload("components/primitives/desc.gd")
const LazyImage := preload("components/primitives/lazy_image.gd")
const Local := preload("components/primitives/local.gd")
const PressLocal := preload("components/primitives/press_local.gd")
const Pressable := preload("components/primitives/pressable.gd")
const Ui := preload("components/primitives/ui.gd")

## --- the one recipe an application reads inside a constant of its own ---
const Status := preload("components/recipes/status.gd")

## --- the look: the Theme itself ---
const Themes := preload("theme.gd")

## --- the floor: the models an application annotates with, and the two every model and every app names in a signature ---
const Actions := preload("actions.gd")
const Controller := preload("controller.gd")
const Calendar := preload("calendar.gd")
const Chimes := preload("chimes.gd")
const CommandSearch := preload("command_search.gd")
const Connection := preload("connection.gd")
const Documents := preload("documents.gd")
const Drills := preload("drills.gd")
const Driver := preload("driver.gd")
const Feed := preload("feed.gd")
const Fetched := preload("fetched.gd")
const Filters := preload("filters.gd")
const Form := preload("form.gd")
const GrowingList := preload("growing_list.gd")
const ImageLoads := preload("image_loads.gd")
const KeyedItems := preload("keyed_items.gd")
const Lane := preload("lane.gd")
const Measures := preload("measures.gd")
const Narrowing := preload("narrowing.gd")
const Notifications := preload("notifications.gd")
const OpenMenu := preload("open_menu.gd")
const Orders := preload("orders.gd")
const Outbox := preload("outbox.gd")
const PacedNotices := preload("paced_notices.gd")
const PackedRows := preload("packed_rows.gd")
const Panels := preload("panels.gd")
const Phrase := preload("phrase.gd")
const Provisional := preload("provisional.gd")
const QueriedRows := preload("queried_rows.gd")
const QueryPacing := preload("query_pacing.gd")
const RollingSeries := preload("rolling_series.gd")
const Rollup := preload("rollup.gd")
const SettingsFile := preload("settings_file.gd")
const Stream := preload("stream.gd")
const TableModels := preload("table_models.gd")
const Throttle := preload("throttle.gd")

## --- the one call: what the framework needs of a project, set on request ---
const _NeededSettings := preload("needed_settings.gd")


## The project settings the framework needs, set on the project, this window
## and the input map (needed_settings.gd): the one way the framework writes
## outside an app's own subtree, called by a project that wants the whole
## window run its way - the demos' main loop does (application.gd).
static func apply_project_settings(window: Window) -> void:
	_NeededSettings.apply(window)
