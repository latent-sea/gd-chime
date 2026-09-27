extends RefCounted

## A software team's board, made up: three hundred issues across the six
## lanes of its flow, the same ones every run.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What stands in for the tracker a real application reads. Every card has
## its issue number, a title, the person it is assigned to - or nobody - a
## priority from 0 (low) to 3 (urgent), an estimate in points, labels, a day
## it is due on - counted from today, before it overdue - or none, and a few
## words about it. A card labelled blocked is one the server will not let
## past In progress. The draws are seeded, so a probe and a screenshot find
## the same cards.
##
## Deliberately absent: anything a real tracker holds besides.

## The lanes of the flow, in order, and how many cards each starts with.
const LANE_WORDS: Array[String] = ["Backlog", "Ready", "In progress", "Review", "Testing", "Done"]
const STARTS := {"Backlog": 110, "Ready": 45, "In progress": 35, "Review": 25, "Testing": 25, "Done": 60}
const PEOPLE: Array[String] = ["Ana Lopez", "Ben Okafor", "Chen Wei", "Dara Walsh", "Emil Haddad", "Farah Mensah", "Goran Petrov", "Hana Sato"]
const LABELS: Array[String] = ["bug", "feature", "api", "ui", "docs", "chore", "blocked"]
const ESTIMATES: Array[int] = [1, 2, 3, 5, 8, 13]
const VERBS: Array[String] = ["Fix", "Add", "Speed up", "Refactor", "Document", "Remove", "Rename", "Test", "Localise", "Cache", "Validate", "Paginate", "Log", "Retry", "Secure"]
const THINGS: Array[String] = ["login redirect", "CSV export", "search index", "billing webhook", "password reset", "invoice PDF", "audit log", "dark theme", "sign-up form", "rate limiter", "session timeout", "file upload", "email digest", "user avatars", "settings page", "API tokens", "report filters", "onboarding tour", "notification centre", "data import", "team invites", "keyboard shortcuts", "error pages", "mobile layout", "sync conflicts"]
const WHERE: Array[String] = ["", " on the dashboard", " for admins", " in the API", " on mobile", " for new teams", " in reports"]


## The cards, each {id, title, lane, person, priority, estimate, labels, due, about}, in the order of their lanes.
static func made() -> Array:
	var draws := RandomNumberGenerator.new()
	draws.seed = 4242
	var cards: Array = []
	var id := 100
	# every lane, and as many cards in it as it starts with
	for lane: String in LANE_WORDS:
		for at: int in STARTS[lane]:
			id += 1
			var title := "%s %s%s" % [VERBS[draws.randi() % VERBS.size()], THINGS[draws.randi() % THINGS.size()], WHERE[draws.randi() % WHERE.size()]]
			var labels: Array = []
			# one or two labels, never the same twice, blocked the rarest
			for pick: int in draws.randi_range(1, 2):
				var label: String = LABELS[draws.randi() % (LABELS.size() if draws.randf() < 0.3 else LABELS.size() - 1)]
				if not labels.has(label):
					labels.append(label)
			var person: Variant = null if draws.randf() < 0.12 else PEOPLE[draws.randi() % PEOPLE.size()]
			var due: Variant = null if draws.randf() < 0.45 else draws.randi_range(-6, 28)
			cards.append({"id": id, "title": title, "lane": lane, "person": person, "priority": [0, 1, 1, 2, 2, 3][draws.randi() % 6], "estimate": ESTIMATES[draws.randi() % ESTIMATES.size()], "labels": labels, "due": due, "about": "%s. Raised by %s." % [title, PEOPLE[draws.randi() % PEOPLE.size()]]})
	return cards
