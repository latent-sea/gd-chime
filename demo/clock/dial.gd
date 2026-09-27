extends RefCounted

const Ui := preload("res://addons/gd_chime/components/primitives/ui.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")

## One face of the clock: a recipe - its unit's name over its number, the
## number read from the time, a value read every frame.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The time is seconds since the epoch, shifted into local time, so a face
## takes the unit it shows from one number, without a second reading that
## might straddle a boundary and pair a millisecond with a second that has
## already rolled.

enum Unit { HOUR, MINUTE, SECOND, MILLISECOND }

const NAMES := {Unit.HOUR: "HOUR", Unit.MINUTE: "MINUTE", Unit.SECOND: "SECOND", Unit.MILLISECOND: "MILLISECOND"}


## The machine's clock now, in local time: what a face is handed, read every frame (ui.every_frame).
static func now() -> float:
	return Time.get_unix_time_from_system() + float(Time.get_time_zone_from_system()["bias"]) * 60.0


static func make(ui: Ui, time: Bound, unit: Unit) -> Desc:
	var number: Bound = time.map(func(now: float) -> String: return _reading(now, unit))
	return ui.column([ui.text(Phrase.of(NAMES[unit]), Themes.TITLE), ui.text(number, Themes.NUMBER)])


## The unit's reading of this time: milliseconds run to three digits, every
## other unit to two.
static func _reading(now: float, unit: Unit) -> String:
	var whole := int(floor(now))
	var units := Time.get_time_dict_from_unix_time(whole)
	match unit:
		Unit.HOUR: return "%02d" % units["hour"]
		Unit.MINUTE: return "%02d" % units["minute"]
		Unit.SECOND: return "%02d" % units["second"]
	# the fraction of the second the reading fell in, as milliseconds
	return "%03d" % int((now - float(whole)) * 1000.0)
