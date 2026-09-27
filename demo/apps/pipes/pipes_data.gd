extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## A utility's water mains, made up: a hundred thousand pipes, the same
## ones every run, with enough old cast iron at high risk to be worth
## replacing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What stands in for the asset register a real application reads. Every
## pipe has an id, a road, a town, a material, a diameter, the day it was
## laid, a risk of failing (0 to 100, older and more brittle higher), the
## state of its last inspection, the replacement programme it is in, and
## the engineer who looks after it. The draws are seeded, so a probe and a
## screenshot find the same pipes.
##
## Deliberately absent: anything a real register holds besides.

const COLUMNS := {&"asset": GdChime.PackedRows.NUMBER, &"road": GdChime.PackedRows.WORDS, &"town": GdChime.PackedRows.WORDS, &"material": GdChime.PackedRows.WORDS, &"diameter": GdChime.PackedRows.NUMBER, &"laid": GdChime.PackedRows.DATE, &"risk": GdChime.PackedRows.NUMBER, &"inspection": GdChime.PackedRows.WORDS, &"programme": GdChime.PackedRows.WORDS, &"engineer": GdChime.PackedRows.WORDS}
const MATERIALS := ["cast iron", "ductile iron", "PVC", "polyethylene", "asbestos cement", "steel"]
## The years each material was laid in, and how brittle it is, added to its risk.
const LAID := {"cast iron": [1880, 1975, 38.0], "ductile iron": [1965, 2020, 12.0], "PVC": [1970, 2020, 8.0], "polyethylene": [1985, 2023, 4.0], "asbestos cement": [1945, 1985, 30.0], "steel": [1900, 2000, 20.0]}
const TOWNS := ["Ashby", "Bramford", "Castleton", "Dunmore", "Eastwick", "Fenwold", "Glenham", "Harlow Cross", "Ivybridge", "Kettering Vale", "Longmead", "Marston", "Northfleet", "Oakhurst", "Pendle", "Quarrington", "Redbourne", "Saltash", "Thornbury", "Upton Magna"]
const ROAD_NAMES := ["Mill", "Church", "Station", "Victoria", "Park", "Kings", "Queens", "Bridge", "Chapel", "School", "Orchard", "Meadow", "Hill", "Well", "Market", "Water", "Green", "Manor", "Grange", "Forge", "Tannery", "Wharf", "Abbey", "Priory", "Rectory", "Beacon", "Canal", "Foundry", "Gasworks", "Railway"]
const ROAD_KINDS := ["Lane", "Road", "Street", "Avenue", "Close", "Way", "Row", "Terrace", "Hill", "Walk"]
const INSPECTIONS := ["passed", "passed", "due", "overdue", "failed"]
const ENGINEERS := ["A. Okafor", "B. Lindqvist", "C. Ferreira", "D. Nakamura", "E. Walsh", "F. Haddad", "G. Moreau", "H. Kowalski", "I. Mensah", "J. Tanaka", "K. O'Brien", "L. Rossi", "M. Adeyemi", "N. Petrov", "O. Brennan", "P. Sato"]
const PROGRAMMES := ["none", "R-2026 mains renewal", "R-2027 cast iron retirement", "R-2028 trunk main relining", "R-2029 lead and iron sweep"]


## The pipes, as many as asked, the same every time.
static func made(count: int) -> GdChime.PackedRows:
	var rows := GdChime.PackedRows.new(COLUMNS)
	var draws := RandomNumberGenerator.new()
	draws.seed = 1970
	# every pipe, drawn in turn
	for id: int in count:
		var material: String = MATERIALS[draws.randi() % MATERIALS.size()]
		var laid: Array = LAID[material]
		var year := draws.randi_range(laid[0], laid[1])
		# a day within the year laid, counted from 1970 by the average year
		var day := floorf((year - 1970) * 365.2425) + draws.randi_range(0, 364)
		var risk := clampf(laid[2] + (2025 - year) * 0.35 + draws.randfn(0.0, 9.0), 0.0, 100.0)
		var road := "%s %s" % [ROAD_NAMES[draws.randi() % ROAD_NAMES.size()], ROAD_KINDS[draws.randi() % ROAD_KINDS.size()]]
		rows.add([float(id + 1), road, TOWNS[draws.randi() % TOWNS.size()], material, float(75 + 25 * draws.randi_range(0, 20)), day, snappedf(risk, 0.1), INSPECTIONS[draws.randi() % INSPECTIONS.size()], PROGRAMMES[0], ENGINEERS[draws.randi() % ENGINEERS.size()]])
	return rows


## A pipe's id as its asset code.
static func code_of(id: float) -> String:
	return "WM-%06d" % int(id)
