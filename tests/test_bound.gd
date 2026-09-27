extends SceneTree

## What must be true of a bound value.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_bound.gd
##
## A model's value reads what the model holds, and a read of it notes the
## model's own bell and no other; a primitive given one re-reads when the
## model's values move, and not when another model's do; all() reads any
## number of them at once and notes the bells of all, each once; map formats
## the same value, and field reads one key of it, noting the same bell; a
## constant reads what it was made with and notes nothing; and a bound value
## a control answers for is re-read as that control draws.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Controller := preload("res://addons/gd_chime/controller.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


## A model with two values, a count and a label, and a person read from both.
class Model extends Controller:
	var count := value(0)
	var label := value("nobody")

	func _init(chimes: Chimes, at: StringName = &"model") -> void:
		super(chimes, [], at)

	func get_person() -> Dictionary:
		return {"label": label.read(), "count": count.read()}

	func counts() -> void:
		count.set_value(count.read() + 1)

	func rename(to: String) -> void:
		label.set_value(to)


func _init() -> void:
	await process_frame
	await _verdict.states(_it_reads_the_model_and_notes_the_model_s_own_bell)
	await _verdict.states(_a_primitive_given_one_re_reads_as_its_model_moves_and_not_another)
	await _verdict.states(_map_formats_and_field_reads_a_key_noting_the_same_bell)
	await _verdict.states(_a_value_of_three_models_re_reads_when_any_moves_and_once_a_move)
	await _verdict.states(_a_constant_reads_its_value_and_notes_nothing)
	await _verdict.states(_a_read_while_its_template_runs_is_reported_and_one_after_is_not)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## What a read of this bound value notes, as [what it read, the addresses].
func _noted(bound: Bound) -> Array:
	Reads.begin()
	var read: Variant = bound.read()
	return [read, Reads.end().keys()]


func _it_reads_the_model_and_notes_the_model_s_own_bell() -> void:
	var chimes := Chimes.new(Belfry.new())
	var model := Model.new(chimes)
	var other := Model.new(chimes, &"other")
	var noted := _noted(model.count)
	_verdict.check(noted[0] == 0 and noted[1] == [Reads.hung(model._values.get_address(), model._values.get_address())], "it reads what the model holds and notes the model's own bell: %s" % [noted])
	model.counts()
	_verdict.check(model.count.read() == 1, "read again, it is what the model holds now")
	_verdict.check(_noted(other.count)[1] != noted[1], "another model's value notes another bell: %s" % [_noted(other.count)])
	model.free()
	other.free()


func _a_primitive_given_one_re_reads_as_its_model_moves_and_not_another() -> void:
	var chimes := Chimes.new(Belfry.new())
	var model := Model.new(chimes)
	var other := Model.new(chimes, &"other")
	root.add_child(model)
	root.add_child(other)
	var text := Text.new(chimes, model.count.map(func(n: int) -> String: return "counted %d" % n), &"", Chimes.GLOBAL, false)
	root.add_child(text)
	await _a_frame_passes()
	var drawn := text.refresh_count
	_verdict.check(text.get_text() == "counted 0", "built, it shows the value: %s" % text.get_text())
	model.counts()
	await _a_frame_passes()
	_verdict.check(text.get_text() == "counted 1" and text.refresh_count == drawn + 1, "the value moved, it re-read once: %s" % text.get_text())
	other.rename("someone")
	await _a_frame_passes()
	_verdict.check(text.refresh_count == drawn + 1, "another model's value moved, not this read's, and it did not: %d" % (text.refresh_count - drawn))
	text.free()
	model.free()
	other.free()


func _map_formats_and_field_reads_a_key_noting_the_same_bell() -> void:
	var chimes := Chimes.new(Belfry.new())
	var model := Model.new(chimes)
	var shouted := _noted(model.label.map(func(named: String) -> String: return named.to_upper()))
	_verdict.check(shouted[0] == "NOBODY" and shouted[1] == [Reads.hung(model._values.get_address(), model._values.get_address())], "map formats the value, noting the same bell: %s" % [shouted])
	var who: Bound = Bound.new(model.get_person).field("label")
	model.rename("ann")
	var named := _noted(who)
	_verdict.check(named[0] == "ann" and named[1] == [Reads.hung(model._values.get_address(), model._values.get_address())], "field reads one key of the value, noting the same bell: %s" % [named])
	model.free()


func _a_value_of_three_models_re_reads_when_any_moves_and_once_a_move() -> void:
	var chimes := Chimes.new(Belfry.new())
	var models: Array = [Model.new(chimes, &"one"), Model.new(chimes, &"two"), Model.new(chimes, &"three")]
	# three models in the tree, the first read twice so one bell is shared
	for model: Model in models:
		root.add_child(model)
	var sources: Array = models.map(func(model: Model) -> Bound: return model.count)
	var summed: Bound = Bound.all(sources + [sources[0]], func(a: int, b: int, c: int, again: int) -> String: return "%d+%d+%d (%d)" % [a, b, c, again])
	var bells: Array = models.map(func(model: Model) -> StringName: return Reads.hung(model._values.get_address(), model._values.get_address()))
	_verdict.check(_noted(summed)[1] == bells, "it notes the bells of all, a shared bell once: %s" % [_noted(summed)[1]])
	var text := Text.new(chimes, summed, &"", Chimes.GLOBAL, false)
	root.add_child(text)
	await _a_frame_passes()
	var drawn := text.refresh_count
	# each model moved in turn: the text re-reads once a move, the values in order
	for at: int in 3:
		(models[at] as Model).counts()
		await _a_frame_passes()
		_verdict.check(text.refresh_count == drawn + at + 1, "model %d moved, it re-read once: %d" % [at, text.refresh_count - drawn])
	_verdict.check(text.get_text() == "1+1+1 (1)", "and the blend was handed their values in order: %s" % text.get_text())
	text.free()
	for model: Model in models:
		model.free()


func _a_constant_reads_its_value_and_notes_nothing() -> void:
	var chimes := Chimes.new(Belfry.new())
	var model := Model.new(chimes)
	var settled := _noted(Bound.constant([{"name": &"group", "share": 1.0}]))
	_verdict.check(settled[0] == [{"name": &"group", "share": 1.0}] and settled[1] == [], "a constant reads the value it was made with and notes nothing: %s" % [settled])
	var shouted := _noted(Bound.constant("nobody").map(func(named: String) -> String: return named.to_upper()))
	_verdict.check(shouted[0] == "NOBODY" and shouted[1] == [], "mapped, it still notes nothing: %s" % [shouted])
	model.counts()
	_verdict.check(Bound.constant(model.count.read()).read() == 1, "made with what a value held, it stays what it was handed")
	model.free()


## Counts the errors pushed while it listens.
class Hearing extends Logger:
	var errors: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			errors += 1


func _a_read_while_its_template_runs_is_reported_and_one_after_is_not() -> void:
	var hearing := Hearing.new()
	OS.add_logger(hearing)
	var handle := Bound.constant("item")
	var shouted: Bound = handle.map(func(word: String) -> String: return word.to_upper())
	handle.set_template_running(true)
	var read: Variant = handle.read()
	var mapped: Variant = shouted.read()
	_verdict.check(hearing.errors == 2 and read == "item" and mapped == "ITEM", "read while its template runs, directly or through a map, it says so and still answers: %d" % hearing.errors)
	handle.set_template_running(false)
	shouted.read()
	_verdict.check(hearing.errors == 2, "read after, it says nothing")
	OS.remove_logger(hearing)
