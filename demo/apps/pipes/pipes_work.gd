extends "res://addons/gd_chime/controller.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const PipesData := preload("res://demo/apps/pipes/pipes_data.gd")

## What is done to pipes: assigned to a replacement programme, or marked
## inspected - each to the pipes picked, or, with none picked, the pipe
## the cursor is on; or to the one pipe a menu was opened on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The grid's row actions (data_grid.gd), and the application's own: the
## rule is here, the writing is the edits' (row_edits.gd), so each change
## can be taken back whole. ASSIGNS {value} puts every pipe acted on into
## that programme; MARKS_INSPECTED marks them passed. A payload carrying "id" - a
## menu opened on one row - acts on that pipe, or on every pipe picked if
## it is one of them. With nothing to act on, each is refused in words.
## OPENS_PROGRAMMES raises the programmes to choose from, refused the same;
## raised from a row's menu, the programme chosen is assigned to what that
## row acts on, so the pipe the menu was opened on is kept until one is.
##
## Deliberately absent: a programme's own record, and who assigned what.

const OPENS_PROGRAMMES := &"opens_the_programmes"
const ASSIGNS := &"assigns_to_a_programme"
const MARKS_INSPECTED := &"marks_inspected"
## Every action this is told.
const COMMANDS: Array[StringName] = [OPENS_PROGRAMMES, ASSIGNS, MARKS_INSPECTED]

var _models: GdChime.TableModels
var _opened_on: Variant = null  # the pipe a menu raised the programmes over, or none: raised from the bar


func _init(chimes: Chimes, models: GdChime.TableModels) -> void:
	super(chimes)
	_models = models


## Nothing to act on is refused; the way back from the programmes, which it also answers, never is.
func would(action: StringName, payload: Dictionary) -> Phrase:
	return Phrase.of("Pick some pipes first") if action in [OPENS_PROGRAMMES, ASSIGNS, MARKS_INSPECTED] and _acted_on(_about(action, payload)).is_empty() else null


func told(action: StringName, payload: Dictionary) -> Phrase:
	var pipes := _acted_on(_about(action, payload))
	match action:
		OPENS_PROGRAMMES: _opened_on = payload.get("id")
		ASSIGNS: _models.edits.write_many(pipes, &"programme", payload["value"], Phrase.with("%s pipes assigned to %s", [pipes.size(), payload["value"]]))
		MARKS_INSPECTED: _models.edits.write_many(pipes, &"inspection", "passed", Phrase.with("%s pipes marked inspected", [pipes.size()]))
	return null


## What a press is about: a programme chosen is about the pipe its choice was raised over, if one was.
func _about(action: StringName, payload: Dictionary) -> Dictionary:
	return {"id": _opened_on} if action == ASSIGNS else payload


## The programmes to choose from, as a choice's options.
func get_programmes() -> Array:
	return PipesData.PROGRAMMES.map(func(programme: String) -> Dictionary: return {"value": programme, "words": programme})


## The pipes acted on: the one a menu was opened on - or every pipe picked,
## if it is one of them - else the picks, else the cursor's pipe.
func _acted_on(payload: Dictionary) -> PackedInt32Array:
	var one: Variant = payload.get("id")
	if one == null or _models.picks.is_picked(one):
		return _models.picks.get_acted_on()
	return PackedInt32Array([one])


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
