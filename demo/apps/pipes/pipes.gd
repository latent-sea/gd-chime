extends "res://addons/gd_chime/application.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const PipesData := preload("res://demo/apps/pipes/pipes_data.gd")
const PipesWork := preload("res://demo/apps/pipes/pipes_work.gd")
const PipesProbe := preload("res://demo/apps/pipes/pipes_probe.gd")

## A utility's asset register: a hundred thousand water mains in the
## floor's data grid (data_grid.gd), filtered to the high-risk cast iron
## laid before 1970, three hundred of them picked and assigned to a
## replacement programme.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/apps/pipes/pipes.gd
##       [-- --look=<a gallery look>] [-- --probe]
##
## Everything the grid does is the floor's: this names the columns, the
## rules a value typed into one must keep, the two things done to pipes
## (pipes_work.gd) and the look, and puts the grid on a screen. Add a filter
## (material is cast iron, risk is over 70, laid is before 1970), move with
## the arrows and pick a run with shift and the arrows or a page, press
## "Assign to a programme" - or P, or the pad's Y - and choose one; U takes
## it back. Enter changes the cell the cursor is on, where its column
## allows. A right press on a row, the menu key or the pad's view button
## opens the row's menu (context_menu.gd): mark it inspected, or assign it.
## With no look asked for, it wears its own, data dense; --look=placeholder
## is the floor's neutral one.

const APP := &"app"
## The screen, and the region every model of the grid answers in.
const PIPES := &"pipes"
const COUNT := 100000
## Rows shown at once.
const SHOWING := 24

## The grid's models, for the probe.
var models: GdChime.TableModels
var work: PipesWork
var menu: GdChime.OpenMenu


## The look asked for at launch, or the pipes' own: data dense.
func look() -> Theme:
	return Looks.make(Looks.asked(&"data_dense"))


func probe() -> RefCounted:
	return PipesProbe.new(self)


## Every action of the grid's, then the pipes' own with their words and inputs.
func declare(register: Actions) -> void:
	GdChime.DataGrid.declare(register)
	register.declare_all({
		PipesWork.OPENS_PROGRAMMES: ["Assign to a programme", Actions.keys(KEY_P), Actions.pad(JOY_BUTTON_Y)],
		PipesWork.ASSIGNS: ["Assign"],
		PipesWork.MARKS_INSPECTED: ["Mark inspected", Actions.keys(KEY_I), Actions.pad(JOY_BUTTON_X)],
		GdChime.OpenMenu.OPENS: ["More", Actions.keys(KEY_MENU), Actions.pad(JOY_BUTTON_BACK)],
		GdChime.OpenMenu.PICKS: ["Pick"],
	})


func describe() -> Desc:
	models = GdChime.TableModels.new(ui, PipesData.made(COUNT), _columns(), _checks(), jobs, SHOWING, [PipesWork.MARKS_INSPECTED, PipesWork.OPENS_PROGRAMMES])
	work = PipesWork.new(chimes, models)
	# a menu opens from anywhere over the target it is pressed on
	menu = model(GdChime.OpenMenu.new(chimes, commands, actions))
	# the rows' menu, which every row opens
	GdChime.ContextMenu.make(ui, menu)
	var grid: GdChime.Desc = GdChime.DataGrid.grid(ui, models, [ui.button(PipesWork.OPENS_PROGRAMMES, {opens = _assigning()}), ui.button(PipesWork.MARKS_INSPECTED)])
	var title := ui.text(GdChime.Phrase.with("Water mains - %s pipes", [GdChime.Phrase.written(func() -> String: return GdChime.Formats.written_number(COUNT))]), Themes.WORDS)
	# the grid's models and the work over them answer on the pipes' screen, where they are described
	return ui.app(APP, [ui.screen(PIPES, [ui.column([title, grid.grow()])], models.all() + [work], {on_fill = models.long.look, on_empty = models.long.drop})])


## The columns: what each is called, its share, how it is written, whether it edits and how it is filtered.
func _columns() -> Array:
	return [
		{"name": &"asset", "words": GdChime.Phrase.of("Asset"), "share": 0.08, "writes": PipesData.code_of},
		{"name": &"road", "words": GdChime.Phrase.of("Road"), "share": 0.12, "filters": GdChime.FilterSet.A_FIND},
		{"name": &"town", "words": GdChime.Phrase.of("Town"), "share": 0.1, "filters": GdChime.FilterSet.A_LIST},
		{"name": &"material", "words": GdChime.Phrase.of("Material"), "share": 0.1, "filters": GdChime.FilterSet.A_LIST},
		{"name": &"diameter", "words": GdChime.Phrase.of("Diameter, mm"), "share": 0.07, "edits": true, "filters": GdChime.FilterSet.A_NUMBER},
		{"name": &"laid", "words": GdChime.Phrase.of("Laid"), "share": 0.09, "edits": true, "filters": GdChime.FilterSet.A_DATE},
		{"name": &"risk", "words": GdChime.Phrase.of("Risk"), "share": 0.05, "places": 1, "filters": GdChime.FilterSet.A_NUMBER},
		{"name": &"inspection", "words": GdChime.Phrase.of("Inspection"), "share": 0.08, "filters": GdChime.FilterSet.A_LIST},
		{"name": &"programme", "words": GdChime.Phrase.of("Programme"), "share": 0.17, "filters": GdChime.FilterSet.A_LIST},
		{"name": &"engineer", "words": GdChime.Phrase.of("Engineer"), "share": 0.1, "edits": true, "filters": GdChime.FilterSet.A_LIST},
	]


## The rules a value typed into a column must keep.
func _checks() -> Dictionary:
	var sized := func(size: float) -> GdChime.Phrase: return GdChime.Phrase.of("A main is between 50 and 2,000 mm across") if size < 50.0 or size > 2000.0 else null
	var known := func(name: String) -> GdChime.Phrase: return null if PipesData.ENGINEERS.has(name) else GdChime.Phrase.with("%s is not one of the engineers", [name])
	return {&"diameter": sized, &"engineer": known}


## The programmes to assign to, in a pop-up answered by the pipes' work: a press each, going back.
func _assigning() -> Desc:
	var options: Array = work.get_programmes().map(func(option: Dictionary) -> Desc: return ui.pressable(PipesWork.ASSIGNS, {"value": option["value"]}, [ui.text(option["words"], Themes.FACE)], GdChime.Setting.OPTION).goes_to(Driver.BACK))
	var content := [ui.text(GdChime.Phrase.of("Assign the pipes to"), Themes.FACE)] + options + [GdChime.Sheet.close(ui)]
	return ui.pop_up(&"assigning", func(_which: GdChime.Bound) -> Desc: return GdChime.Sheet.over(ui, content, GdChime.Setting.SHEET), work)
