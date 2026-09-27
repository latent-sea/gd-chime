extends "res://addons/gd_chime/application.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const Insurance := preload("res://demo/apps/form/insurance.gd")
const Probe := preload("res://demo/apps/form/probe.gd")

## Application 3, the complex multi-step form: a business insurance
## application of eight steps, built on the floor's form and the
## application shell and nothing of its own.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/apps/form/form.gd
## It opens in its own look, skeuomorphic; another: add -- --look=<name> (the
## floor's neutral one is placeholder); a settings file of
## its own: -- --settings=user://<file>.json; walked and judged: -- --probe.
##
## THE FORM IS THE FLOOR'S: its questions are data (insurance.gd), the form
## holds and checks the answers (form.gd), and its steps, questions, sections,
## summary and review are described from that data (form_steps.gd). This file
## declares the actions and their keys, makes the models, keeps the draft in a
## settings file, and puts the form in the shell - the palette searching its
## steps and questions, the tray saying a draft is saved.

## The look the application opens in unless another is asked for: a paper form on a leather desk.
const SIGNATURE := &"skeuomorphic"
const START := &"start"
const APPLICATION := &"application"
const SENT := &"sent"
const OPENS := &"opens_the_application"
const OPENS_PALETTE := &"opens_the_palette"
## Where the draft is kept: the application's own file, and the probe's, which is begun empty.
const DRAFT := "user://insurance_draft.json"
const PROBED := "user://form_probe.json"

var form: GdChime.Form
var calendar: GdChime.Calendar
var search: GdChime.CommandSearch
var settings: GdChime.SettingsFile
## The pop-ups a probe finds: the question asked before unsaved answers are left, the calendar, the palette.
var leaving: Desc
var calendar_sheet: Desc
var palette: Desc


func look() -> Theme:
	return Looks.make(Looks.asked(SIGNATURE))


func probe() -> RefCounted:
	return Probe.new(self)


## The shell's actions, then the form's and the calendar's, made with them since each declares its own.
func declare(register: Actions) -> void:
	register.declare_all({
		OPENS_PALETTE: ["Search the steps and questions", Actions.keys(KEY_K, KEY_MASK_CTRL), Actions.pad(JOY_BUTTON_BACK)],
		OPENS: ["Open the application"],
		Notifications.DISMISSES: ["Dismiss"],
		GdChime.CommandSearch.TYPES: ["Search"],
		GdChime.CommandSearch.PICKS: ["Pick"],
		GdChime.CommandSearch.RUNS_FIRST: ["Go to the first found"],
	})
	form = GdChime.Form.new(chimes, commands, Insurance.questions(), Insurance.steps(), SENT, notifications)
	form.declare(register, {
		GdChime.FormActions.SAVES_DRAFT: [Actions.keys(KEY_S, KEY_MASK_CTRL), Actions.pad(JOY_BUTTON_Y)],
		GdChime.FormActions.NEXT: [Actions.keys(KEY_PAGEDOWN, KEY_MASK_CTRL)],
		GdChime.FormActions.PREVIOUS: [Actions.keys(KEY_PAGEUP, KEY_MASK_CTRL)],
	})
	calendar = GdChime.Calendar.new(chimes, commands)
	calendar.declare(register)


## The models put beside the app, the draft kept, and the shell described.
func describe() -> Desc:
	# the palette searches the steps and every question, besides the screen's own commands - a question not asked now refused on its entry, so neither list moves as the reader types
	var questions: Array = form.get_questions().map(func(one: Dictionary) -> Dictionary: return {"value": one["key"], "words": str(one["words"])})
	var steps: Array = Insurance.steps().map(func(one: Array) -> Dictionary: return {"value": one[0], "words": str(one[1])})
	search = model(GdChime.CommandSearch.new(chimes, commands, driver, actions, [{"kind": GdChime.Phrase.of("Step"), "entries": GdChime.Bound.new(func() -> Array: return steps), "picks": GdChime.FormActions.SHOWS_STEP}, {"kind": GdChime.Phrase.of("Question"), "entries": GdChime.Bound.new(func() -> Array: return questions), "picks": GdChime.FormActions.SHOWS_QUESTION}]))
	settings = model(GdChime.SettingsFile.new(chimes, settings_path(DRAFT, PROBED)))
	model(form)
	model(calendar)
	settings.keep("draft", form)
	# the question asked before unsaved answers are left, the one calendar every day opens, and the palette
	leaving = GdChime.Confirm.for_leaving(ui, GdChime.FormActions.LEAVES_WITHOUT_SAVING)
	calendar_sheet = GdChime.CalendarSheet.make(ui, calendar)
	palette = GdChime.CommandPalette.make(ui, search)
	var search_press := ui.pressable(OPENS_PALETTE, {}, [ui.row([ui.text(ui.words(OPENS_PALETTE), Themes.FACE).grow(), GdChime.Hint.make(ui, OPENS_PALETTE)])], GdChime.Pressables.BUTTON).opens(palette)
	var body := ui.stack([_start(), GdChime.FormSteps.make(ui, form, APPLICATION, {review = Insurance.REVIEW, asks = leaving, closes_to = START, calendar = calendar_sheet}), _sent()])
	return ui.app(&"insurance", [GdChime.Shell.make(ui, [search_press], body, {status = _status(), notifications = notifications})])


## Where the application starts: what it is, whether a draft is kept, and the way in.
func _start() -> Desc:
	var kept: GdChime.Bound = ui.bound(form.get_drafted).map(func(drafted: bool) -> Variant: return GdChime.Phrase.of("A draft you saved is kept: open the application to carry on where you left it.") if drafted else GdChime.Phrase.of("Your answers are checked as you go, and you can save a draft at any step."))
	var opens := ui.pressable(OPENS, {}, [ui.text(ui.words(OPENS), Themes.FACE)], GdChime.Pressables.BUTTON).goes_to(Insurance.COMPANY)
	var page := ui.column([ui.text(GdChime.Phrase.of("Business insurance application"), GdChime.Fields.HEADING).wraps(), ui.text(GdChime.Phrase.of("Eight short steps: the company, what it does, its people, what it owns, its claims, its papers and the cover wanted, then a review."), Themes.FACE).wraps(), ui.text(kept, Themes.REASON).wraps(), ui.row([opens])])
	return ui.screen(START, [ui.column([ui.surface(GdChime.Fields.PAGE, [page])])])


## Where a sent application goes: what was sent, and a way to start another.
func _sent() -> Desc:
	var again := ui.pressable(GdChime.FormActions.STARTS_AFRESH, {}, [ui.text(GdChime.Phrase.of("Start another application"), Themes.FACE)], GdChime.Pressables.BUTTON).goes_to(Insurance.COMPANY)
	var page := ui.column([ui.text(GdChime.Phrase.of("The application is sent"), GdChime.Fields.HEADING).wraps(), ui.text(GdChime.Phrase.of("The insurer will reply within two working days. This is what was sent."), Themes.FACE).wraps(), GdChime.FormReview.record(ui, form), ui.row([again])])
	return ui.screen(SENT, [ui.scroll(ui.surface(GdChime.Fields.PAGE, [page])).grow()])


## The status line: whether the answers are all in the draft, and where the draft is kept.
func _status() -> GdChime.Bound:
	return ui.bound(form.get_dirty).map(func(dirty: bool) -> Variant: return GdChime.Phrase.with("Changes not yet saved as a draft. Drafts are kept in %s" if dirty else "Every answer is in the draft kept in %s", [settings.get_file_path()]))


