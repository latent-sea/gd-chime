extends "res://demo/gallery/shown.gd"

const Narrowing := preload("res://addons/gd_chime/narrowing.gd")

## The filters over the things.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

const PICKS_PROPERTY := &"picks_a_property"
const NARROWS_PROPERTIES := &"narrows_the_properties"
const PICKS_COMPARISON := &"picks_a_comparison"
const PICKS_VALUE := &"picks_a_value"
const NARROWS_VALUES := &"narrows_the_values"
const SETS_VALUE := &"sets_the_value"
const TOGGLES := &"toggles_a_filter"
const REMOVES := &"removes_a_filter"
## Every action this is told.
const COMMANDS: Array[StringName] = [PICKS_PROPERTY, NARROWS_PROPERTIES, PICKS_COMPARISON, PICKS_VALUE, NARROWS_VALUES, SETS_VALUE, TOGGLES, REMOVES]
var _next_id: int = 1
var _properties: Narrowing
var _by_value: Narrowing

## The filters over things of these names: the list property's values.
func _init(chimes: Chimes, names: Array) -> void:
	super(chimes, {&"properties": [{"name": "won", "type": &"number"}, {"name": "name", "type": &"list", "values": names}, {"name": "retired", "type": &"boolean"}], &"chips": [], &"building": null, &"count": 6})
	_properties = Narrowing.new(chimes, Bound.new(get_property_options))
	_by_value = Narrowing.new(chimes, Bound.new(get_value_options))
	for picker: Narrowing in [_properties, _by_value]:
		add_child(picker)

func get_properties() -> Array:
	return facts[&"properties"]

func get_chips() -> Array:
	return facts[&"chips"]

func get_building() -> Variant:
	return facts[&"building"]

func get_count() -> Variant:
	return facts[&"count"]

## What the property picker types against: every property, by name.
func get_property_options() -> Array:
	return facts[&"properties"].map(func(property: Dictionary) -> Dictionary: return {"value": property["name"], "words": property["name"]})

## What the value picker types against: the values of the property being
## built, and none until one is.
func get_value_options() -> Array:
	var so_far: Variant = facts[&"building"]
	if so_far == null:
		return []
	var named: Array = facts[&"properties"].filter(func(property: Dictionary) -> bool: return property["name"] == so_far["property"] and property.has("values"))
	return [] if named.is_empty() else named[0]["values"].map(func(value: String) -> Dictionary: return {"value": value, "words": value})

func get_property_narrowing() -> Object:
	return _properties

func get_value_narrowing() -> Object:
	return _by_value

func told(action: StringName, payload: Dictionary) -> Phrase:
	# the typing is the picker's own, and rings the picker's bell, not this one
	if action == NARROWS_PROPERTIES or action == NARROWS_VALUES:
		return (_properties if action == NARROWS_PROPERTIES else _by_value).told(action, payload)
	match action:
		PICKS_PROPERTY: facts[&"building"] = {"property": payload["value"]}
		PICKS_COMPARISON:
			facts[&"building"]["comparison"] = payload["comparison"]
			# a boolean needs no value: the filter is built now
			if payload["comparison"].begins_with("is true") or payload["comparison"].begins_with("is false"):
				_built("")
		PICKS_VALUE: _built(payload["value"])
		SETS_VALUE: _built(payload["line"])
		TOGGLES:
			for chip: Dictionary in facts[&"chips"]:
				if chip["id"] == payload["id"]:
					chip["on"] = not chip["on"]
		REMOVES: facts[&"chips"] = facts[&"chips"].filter(func(chip: Dictionary) -> bool: return chip["id"] != payload["id"])
	facts[&"count"] = 6 - facts[&"chips"].filter(func(chip: Dictionary) -> bool: return chip["on"]).size()
	moved()
	return null

## A chip's words: the property and the value, data, about the comparison,
## an English phrase; a boolean's has no value.
func _built(value: String) -> void:
	var so_far: Dictionary = facts[&"building"]
	var words := Phrase.joined([so_far["property"], " ", Phrase.within(so_far["comparison"])] + ([] if value == "" else [" ", value]))
	facts[&"chips"].append({"id": _next_id, "words": words, "on": true})
	_next_id += 1
	facts[&"building"] = null


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
