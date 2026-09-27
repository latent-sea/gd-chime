extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## A national electricity network's faults, made up: ninety days of
## incidents in nine regions up to the dashboard's now, the same every run,
## with a storm in the north-west over the last three days - and the map of
## those regions, as data.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What stands in for the fault records a real operations centre reads.
## Every incident has a reference, a region, a town, a cause, the hour it
## was reported and the hour supply came back - still to come for the ones
## open now - the day it was reported, how many customers lost supply, how
## long the repair took or has taken so far, the field team on it, and
## whether it is open. Times are hours since 1970, so a stretch of days is
## two numbers. The draws are seeded, so a probe and a screenshot find the
## same incidents.
##
## THE MAP is nine regions, each an outline and a pin in a unit square: a
## stylised island, not a survey.
##
## Deliberately absent: anything a real fault record holds besides.

const COLUMNS := {&"reference": GdChime.PackedRows.NUMBER, &"region": GdChime.PackedRows.WORDS, &"town": GdChime.PackedRows.WORDS, &"cause": GdChime.PackedRows.WORDS, &"reported": GdChime.PackedRows.NUMBER, &"restored": GdChime.PackedRows.NUMBER, &"day": GdChime.PackedRows.DATE, &"customers": GdChime.PackedRows.NUMBER, &"repair": GdChime.PackedRows.NUMBER, &"team": GdChime.PackedRows.WORDS, &"status": GdChime.PackedRows.WORDS}
## The dashboard's now: two in the afternoon of the 19th of September 2026.
const TODAY := "2026-09-19"
const HOUR := 14.0
const DAYS := 90
## Each region: its outline and its pin in the unit square, and how many incidents a day it has.
const REGIONS := {
	"Scotland": [[Vector2(0.25, 0.0), Vector2(0.75, 0.0), Vector2(0.8, 0.3), Vector2(0.2, 0.3)], Vector2(0.5, 0.15), 30.0],
	"North West": [[Vector2(0.2, 0.3), Vector2(0.5, 0.3), Vector2(0.5, 0.52), Vector2(0.14, 0.52)], Vector2(0.33, 0.41), 26.0],
	"North East": [[Vector2(0.5, 0.3), Vector2(0.8, 0.3), Vector2(0.88, 0.52), Vector2(0.5, 0.52)], Vector2(0.68, 0.41), 22.0],
	"Wales": [[Vector2(0.02, 0.52), Vector2(0.34, 0.52), Vector2(0.34, 0.74), Vector2(0.0, 0.74)], Vector2(0.17, 0.63), 18.0],
	"Midlands": [[Vector2(0.34, 0.52), Vector2(0.66, 0.52), Vector2(0.66, 0.74), Vector2(0.34, 0.74)], Vector2(0.5, 0.63), 34.0],
	"East": [[Vector2(0.66, 0.52), Vector2(0.88, 0.52), Vector2(1.0, 0.74), Vector2(0.66, 0.74)], Vector2(0.82, 0.63), 24.0],
	"South West": [[Vector2(0.0, 0.74), Vector2(0.34, 0.74), Vector2(0.34, 0.98), Vector2(0.04, 0.94)], Vector2(0.18, 0.86), 25.0],
	"South East": [[Vector2(0.34, 0.74), Vector2(0.66, 0.74), Vector2(0.66, 0.98), Vector2(0.34, 0.98)], Vector2(0.5, 0.86), 36.0],
	"London": [[Vector2(0.66, 0.74), Vector2(1.0, 0.74), Vector2(0.96, 0.96), Vector2(0.66, 0.98)], Vector2(0.82, 0.86), 40.0],
}
const TOWNS := ["Ashby", "Bramford", "Castleton", "Dunmore", "Eastwick", "Fenwold", "Glenham", "Harlow Cross", "Ivybridge", "Longmead", "Marston", "Northfleet"]
## Each cause, and how long a repair of it takes, in hours, and how many customers it cuts off at most.
const CAUSES := {"equipment failure": [5.0, 900], "storm damage": [9.0, 2400], "third-party damage": [4.0, 600], "vegetation": [6.0, 1200], "flooding": [14.0, 1800], "planned work": [3.0, 300]}
const STORM := "North West"
const STORM_DAYS := 3


## The dashboard's now, in hours since 1970.
static func now() -> float:
	return GdChime.PackedRows.day_of(TODAY) * 24.0 + HOUR


## The regions as a map draws them: {key, outline, pin}.
static func regions() -> Array:
	return REGIONS.keys().map(func(named: String) -> Dictionary: return {"key": named, "outline": REGIONS[named][0], "pin": REGIONS[named][1]})


## Ninety days of incidents up to now, the same every run.
static func made() -> GdChime.PackedRows:
	var rows := GdChime.PackedRows.new(COLUMNS)
	var draws := RandomNumberGenerator.new()
	draws.seed = 2026
	var until := now()
	var first := until - DAYS * 24.0
	var causes: Array = CAUSES.keys()
	var reference := 100000
	# every region, its incidents over the ninety days
	for region: String in REGIONS:
		var rate: float = REGIONS[region][2]
		var at := first
		var initials := "".join(PackedStringArray(Array(region.split(" ")).map(func(word: String) -> String: return word[0])))
		# one incident after another, each gap drawn so the day's rate holds - three times as many in the storm
		while true:
			var stormy := region == STORM and at > until - STORM_DAYS * 24.0
			at += -log(1.0 - draws.randf()) * 24.0 / (rate * (3.0 if stormy else 1.0))
			if at >= until:
				break
			var cause: String = "storm damage" if stormy and draws.randf() < 0.7 else causes[draws.randi() % causes.size()]
			var repair := maxf(0.5, draws.randfn(CAUSES[cause][0], CAUSES[cause][0] * 0.4))
			var restored := at + repair
			reference += 1
			rows.add([float(reference), region, TOWNS[draws.randi() % TOWNS.size()], cause, at, restored, floorf(at / 24.0), float(draws.randi_range(20, CAUSES[cause][1])), repair, "%s-%02d" % [initials, draws.randi_range(1, 12)], "open" if restored > until else "restored"])
	return rows


## An incident's reference as its code.
static func code_of(reference: float) -> String:
	return "INC-%06d" % int(reference)
