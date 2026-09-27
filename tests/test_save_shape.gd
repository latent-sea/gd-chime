extends SceneTree

## What must be true of a save's shape: plain data of the shape fits, and
## anything else is refused with where and why - a piece of words, a number,
## a fraction, one of some values, maybe, a list, a map, a record of exactly
## its fields, either of some shapes, a rule asked only of what fits; and
## refused() says so out loud and answers whether it refused.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_save_shape.gd

const SaveShape := preload("res://addons/gd_chime/save_shape.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_each_piece_takes_its_plain_data_and_refuses_anything_else)
	await _verdict.states(_a_record_holds_exactly_its_fields_and_says_where_one_is_wrong)
	await _verdict.states(_a_rule_is_asked_only_of_what_fits_and_refused_says_so_out_loud)
	quit(_verdict.deliver(get_script()))


## Whether the shape takes each of the first values and refuses each of the second.
func _takes(shape: Callable, fits: Array, not_fits: Array) -> bool:
	return fits.all(func(value: Variant) -> bool: return shape.call(value) == "") and not_fits.all(func(value: Variant) -> bool: return shape.call(value) != "")


func _each_piece_takes_its_plain_data_and_refuses_anything_else() -> void:
	_verdict.check(_takes(SaveShape.words(), ["", "pear"], [1, null, ["pear"]]), "words are a string, and nothing else")
	_verdict.check(_takes(SaveShape.number(), [3, 2.5], ["3", null]), "a number is whole or a fraction, as text gives either back, and never words")
	_verdict.check(_takes(SaveShape.fraction(), [0, 0.4, 1.0], [-0.1, 1.5, "0.5"]), "a fraction is a number from nothing to all")
	_verdict.check(_takes(SaveShape.one_of(["first", "second", ""]), ["first", ""], ["third", 1]), "one of some values is one of them")
	_verdict.check(_takes(SaveShape.maybe(SaveShape.words()), [null, "pear"], [4]), "maybe is null or the shape")
	_verdict.check(_takes(SaveShape.list_of(SaveShape.number()), [[], [1, 2.5]], [[1, "two"], {"a": 1}, "list"]), "a list is a list of its shape throughout")
	_verdict.check(_takes(SaveShape.keyed(SaveShape.words(), SaveShape.number()), [{}, {"a": 1, "b": 2.0}], [{"a": "one"}, [1]]), "a map has every key of the one shape and every value of the other")
	_verdict.check(_takes(SaveShape.either([SaveShape.record({"key": SaveShape.number()}), SaveShape.record({"pad": SaveShape.number()})]), [{"key": 81}, {"pad": 3.0}], [{"key": 81, "pad": 3}, {"mouse": 1}]), "either is one of its shapes: a key or a pad button, not both")
	var why: String = SaveShape.list_of(SaveShape.keyed(SaveShape.words(), SaveShape.fraction())).call([{"a": 0.5}, {"b": 3}])
	_verdict.check(why.contains("item 1") and why.contains("b") and why.contains("3 is no fraction"), "the words say where in the save it went wrong: %s" % why)


func _a_record_holds_exactly_its_fields_and_says_where_one_is_wrong() -> void:
	var split := SaveShape.record({"share": SaveShape.fraction(), "folded": SaveShape.one_of(["first", "second", ""])})
	_verdict.check(split.call({"share": 0.3, "folded": ""}) == "", "a record with its fields, each of its shape, fits")
	_verdict.check(split.call({"share": 0.3}) != "" and split.call({"share": 0.3, "folded": "", "extra": 1}) != "", "one missing a field, or holding one more, does not")
	_verdict.check(split.call({"share": 0.3, "folded": "sideways"}).begins_with("folded:"), "a field of the wrong shape is named: %s" % split.call({"share": 0.3, "folded": "sideways"}))
	_verdict.check(split.call("a split") != "", "and what is not a record at all is not one")


func _a_rule_is_asked_only_of_what_fits_and_refused_says_so_out_loud() -> void:
	var asked: Array = []
	var open := SaveShape.such_that(SaveShape.record({"open": SaveShape.list_of(SaveShape.words()), "front": SaveShape.maybe(SaveShape.words())}), func(save: Dictionary) -> bool:
		asked.append(save)
		return save["front"] == null or save["open"].has(save["front"]), "the one in front is not open")
	_verdict.check(open.call({"open": ["a"], "front": "a"}) == "" and open.call({"open": ["a"], "front": "b"}) == "the one in front is not open", "a rule over the whole is asked of what fits, in its own words")
	asked.clear()
	open.call({"open": "a", "front": "a"})
	_verdict.check(asked.is_empty(), "and never of what does not fit")
	_verdict.check(SaveShape.refused(open, {"open": ["a"], "front": "b"}, "the documents open") and not SaveShape.refused(open, {"open": ["a"], "front": null}, "the documents open"), "refused() answers whether it refused: a torn save is, a whole one is not")
