extends SceneTree

## What must be true of filters over a queried view: a filter built by
## property, comparison and value is a chip, on, and the view keeps only
## what it keeps; three chips keep what all three keep; a chip turned off
## lets its rows back and removed is gone; a list property's values are
## its column's words; a line not of the property's kind is refused.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_row_filters.gd

const Fixture := preload("res://tests/fixture.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const RowFilters := preload("res://addons/gd_chime/row_filters.gd")
const FilterSet := preload("res://addons/gd_chime/components/recipes/filter_set.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"pipes"
const MATERIALS := ["cast iron", "PVC", "steel", "ductile iron"]

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_three_filters_keep_the_high_risk_cast_iron_laid_before_1970)
	await _verdict.states(_a_chip_turned_off_lets_its_rows_back_and_removed_is_gone)
	quit(_verdict.deliver(get_script()))


## Two hundred pipes, a view, and filters by material, risk and the day laid.
func _made(made: Fixture) -> RowFilters:
	var rows := PackedRows.new({&"material": PackedRows.WORDS, &"risk": PackedRows.NUMBER, &"laid": PackedRows.DATE})
	# every pipe, its material, risk and year spread
	for row: int in 200:
		rows.add([MATERIALS[row % MATERIALS.size()], float((row * 37) % 100), PackedRows.day_of(str(1900 + (row * 7) % 120))])
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 1, 4, true)
	var view := QueriedRows.new(made.chimes, rows, pool)
	made.commands.stand(REGION, view)
	var properties := [{"name": &"material", "type": FilterSet.A_LIST}, {"name": &"risk", "type": FilterSet.A_NUMBER}, {"name": &"laid", "type": FilterSet.A_DATE}]
	var filters := RowFilters.new(made.chimes, view, properties, made.ui.motion)
	made.commands.stand(REGION, filters)
	for node: Node in [budget, pool, view, filters]:
		root.add_child(node)
	return filters


func _do(made: Fixture, action: StringName, payload: Dictionary = {}) -> Phrase:
	return made.commands.dispatch(REGION, action, payload)


## Frames until the view has landed.
func _landed(filters: RowFilters) -> void:
	# a frame at a time until nothing is out
	while filters._view.get_busy():
		await process_frame


## One filter built through the filter-set's actions: the property, the comparison, then a value picked or typed.
func _build(made: Fixture, property: StringName, comparison: String, value: String, typed: bool) -> Phrase:
	_do(made, RowFilters.PICKS_PROPERTY, {"value": property})
	_do(made, RowFilters.PICKS_COMPARISON, {"comparison": comparison})
	return _do(made, RowFilters.SETS_VALUE if typed else RowFilters.PICKS_VALUE, {"line": value} if typed else {"value": value})


func _three_filters_keep_the_high_risk_cast_iron_laid_before_1970() -> void:
	var made := Fixture.new(root)
	var filters := _made(made)
	_do(made, RowFilters.PICKS_PROPERTY, {"value": &"material"})
	var offered: Array = filters.get_value_options().map(func(option: Dictionary) -> String: return option["value"])
	_do(made, RowFilters.PICKS_COMPARISON, {"comparison": "is"})
	_do(made, RowFilters.PICKS_VALUE, {"value": "cast iron"})
	await _landed(filters)
	_verdict.check(offered == MATERIALS and filters.get_count() == 50 and filters.get_chips().size() == 1 and filters.get_chips()[0]["on"], "material's values are its column's words, and 'is cast iron' keeps its 50 rows as a chip, on: %s, %d" % [offered, filters.get_count()])
	var wrong := _build(made, &"risk", "is over", "high", true)
	_verdict.check(str(wrong) == "high is not a number" and filters.get_chips().size() == 1, "a risk typed as words is refused, and no chip is made: %s" % wrong)
	_do(made, RowFilters.SETS_VALUE, {"line": "70"})
	_build(made, &"laid", "is before", "1970", true)
	await _landed(filters)
	var view: QueriedRows = filters._view
	var rows := view.get_rows()
	var kept: Array = Array(view.get_order())
	var by_hand: Array = range(200).filter(func(row: int) -> bool: return rows.value_at(row, &"material") == "cast iron" and rows.value_at(row, &"risk") > 70.0 and rows.value_at(row, &"laid") < PackedRows.day_of("1970"))
	_verdict.check(kept == by_hand and not by_hand.is_empty() and filters.get_count() == by_hand.size(), "three chips keep the high-risk cast iron laid before 1970, and only those: %s" % [kept])
	var said: Array = filters.get_chips().map(func(chip: Dictionary) -> String: return str(chip["words"]))
	_verdict.check(said == ["material is cast iron", "risk is over 70", "laid is before 1970"], "each chip says its rule: %s" % [said])
	made.done()


func _a_chip_turned_off_lets_its_rows_back_and_removed_is_gone() -> void:
	var made := Fixture.new(root)
	var filters := _made(made)
	_build(made, &"material", "is not", "PVC", false)
	_build(made, &"risk", "is under", "50", true)
	await _landed(filters)
	var both: int = filters.get_count()
	var first: int = filters.get_chips()[0]["id"]
	_do(made, RowFilters.TOGGLES, {"id": first})
	await _landed(filters)
	var one: int = filters.get_count()
	_do(made, RowFilters.REMOVES, {"id": filters.get_chips()[1]["id"]})
	await _landed(filters)
	_verdict.check(both < one and one < 200 and filters.get_count() == 200 and filters.get_chips().size() == 1 and not filters.get_chips()[0]["on"], "turning off 'is not PVC' lets PVC back (%d to %d); removing the other leaves every row, and the one chip off (%d)" % [both, one, filters.get_count()])
	made.done()
