extends RefCounted

## Today's route for one driver of a parcel carrier: the stops in the order
## they are driven, each with its address, who it is for, how many parcels,
## the window it is due in and a note - the data the mobile app shows.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Made the same every time, so a probe reads what it knows. again() is the
## route as the depot has it later in the day: a note changed and a stop
## added, what a refresh brings.

const STREETS: Array[String] = ["Harbour Row", "Mill Lane", "Orchard Close", "Station Road", "Kiln Street", "Weaver's Yard", "Church Walk", "Bridge End"]
const NAMES: Array[String] = ["A. Okafor", "B. Lindqvist", "C. Moreau", "D. Haddad", "E. Novak", "F. Brennan", "G. Sato", "H. Ferreira", "I. Kowalski", "J. Mensah"]
const WINDOWS: Array[String] = ["08:00-10:00", "10:00-12:00", "12:00-14:00", "14:00-16:00"]
## How many stops the route has to begin with.
const STOPS := 24


## The route: every stop, in the order it is driven.
static func made() -> Array:
	var stops: Array = []
	# every stop of the route, its facts from its place along it
	for at: int in STOPS:
		stops.append({
			"id": at + 1,
			"address": "%d %s" % [3 + at * 7 % 90, STREETS[at % STREETS.size()]],
			"for": NAMES[at * 3 % NAMES.size()],
			"parcels": 1 + at * 5 % 4,
			"window": WINDOWS[at * 4 / STOPS],
			"note": "leave with a neighbour if out" if at % 5 == 2 else "",
		})
	return stops


## The route as the depot has it later: stop 4's note changed, and a stop added at the end.
static func again() -> Array:
	var stops := made()
	stops[3]["note"] = "side gate code 4412"
	stops.append({"id": STOPS + 1, "address": "12 Quay Street", "for": "K. Adeyemi", "parcels": 2, "window": WINDOWS[3], "note": "added by the depot"})
	return stops
