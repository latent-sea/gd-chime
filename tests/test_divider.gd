extends SceneTree

## What must be true of a divider (divider.gd) and of its look (theme.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_divider.gd
##
## A divider across a column lies between the part above it and the part
## below, as wide as the column and as tall as the air either side of its
## rule; one down a row lies between the parts before and after it, as tall
## as the row and as wide as its air; neither is drawn over anything nor
## draws over anything; each draws the look's rule - a line across or down,
## the placeholders' thickness, in the soft ink - and a look that draws the
## rule otherwise is worn at once.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Divider := preload("res://addons/gd_chime/components/recipes/divider.gd")
const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const Verdict := preload("res://tests/verdict.gd")

const WINDOW := Vector2i(600, 400)

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = WINDOW
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_divider_lies_between_the_parts_it_divides_across_a_column_and_down_a_row)
	await _verdict.states(_it_draws_the_look_s_rule_and_a_look_that_draws_it_otherwise_is_worn)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The app: a column of words, a rule across, more words, and a row of
## words either side of a rule down.
func _built() -> Dictionary:
	var made := Fixture.new(root)
	var ui := made.ui
	var row := ui.row([ui.text("apples").named(&"before"), Divider.down(ui).named(&"down"), ui.text("pears").named(&"after")])
	ui.start(ui.app(&"app", [ui.column([ui.text("crates in").named(&"above"), Divider.across(ui).named(&"across"), ui.text("crates out").named(&"below"), row.named(&"row")])]))
	await _a_frame_passes()
	return {"made": made, "ui": ui}


func _a_divider_lies_between_the_parts_it_divides_across_a_column_and_down_a_row() -> void:
	var built := await _built()
	var ui: Fixture.Ui = built["ui"]
	var air: float = root.theme.get_constant(&"air", Themes.DIVIDER)
	var across: Control = ui.node_named(&"across")
	var down: Control = ui.node_named(&"down")
	var above: Rect2 = (ui.node_named(&"above") as Control).get_global_rect()
	var below: Rect2 = (ui.node_named(&"below") as Control).get_global_rect()
	var rule: Rect2 = across.get_global_rect()
	_verdict.check(rule.size == Vector2(float(WINDOW.x), air * 2.0) and above.end.y <= rule.position.y and rule.end.y <= below.position.y, "across a column, it lies between the words above and below, the column's width and its air's height: %s between %s and %s" % [rule, above, below])
	var before: Rect2 = (ui.node_named(&"before") as Control).get_global_rect()
	var after: Rect2 = (ui.node_named(&"after") as Control).get_global_rect()
	var upright: Rect2 = down.get_global_rect()
	_verdict.check(upright.size == Vector2(air * 2.0, (ui.node_named(&"row") as Control).size.y) and before.end.x <= upright.position.x and upright.end.x <= after.position.x, "down a row, it lies between the words before and after, its air's width and the row's height: %s between %s and %s" % [upright, before, after])
	_verdict.check(DrawnOver.covered(root, Rect2(Vector2.ZERO, Vector2(WINDOW))).is_empty(), "nothing is drawn over anything: %s" % [DrawnOver.covered(root, Rect2(Vector2.ZERO, Vector2(WINDOW)))])
	(built["made"] as Fixture).done()


func _it_draws_the_look_s_rule_and_a_look_that_draws_it_otherwise_is_worn() -> void:
	var built := await _built()
	var ui: Fixture.Ui = built["ui"]
	var across: Control = ui.node_named(&"across")
	var down: Control = ui.node_named(&"down")
	var lines: Array = [across.get_theme_stylebox(&"panel"), down.get_theme_stylebox(&"panel")]
	var drawn: Array = lines.map(func(line: StyleBox) -> Array: return [line is StyleBoxLine and (line as StyleBoxLine).vertical, line is StyleBoxLine and (line as StyleBoxLine).thickness == root.theme.get_constant(&"rule", Themes.DIVIDER) and (line as StyleBoxLine).color == Themes.NEUTRAL[&"ink_soft"]])
	_verdict.check(drawn == [[false, true], [true, true]], "across draws a line across and down a line down, each the placeholders' thickness in the soft ink: %s" % [drawn])
	var worn: Theme = root.theme
	var look := Themes.new(Themes.NEUTRAL)
	var heavier := StyleBoxLine.new()
	heavier.thickness = 6
	heavier.set_content_margin_all(12.0)
	look.set_stylebox(&"panel", Themes.DIVIDER_ACROSS, heavier)
	root.theme = look
	await _a_frame_passes()
	_verdict.check(across.get_theme_stylebox(&"panel") == heavier and across.size.y == 24.0, "a look drawing the rule otherwise is worn at once, and its air taken: %s" % [across.size])
	root.theme = worn
	(built["made"] as Fixture).done()
