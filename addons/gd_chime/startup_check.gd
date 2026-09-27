extends RefCounted

const Actions := preload("actions.gd")
const Chart := preload("chart.gd")
const Chimes := preload("chimes.gd")
const Driver := preload("driver.gd")
const Index := preload("index.gd")
const Places := preload("components/primitives/describe_places.gd")

## Whether the built tree stands: every declared action registered, every
## declared destination a place, every action going nowhere answered by a
## model, every registered action declared somewhere,
## every place named once and never after a reserved region.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE STRUCTURE STANDS AT STARTUP, so the checks are made here, once, over
## what every place declares it performs (place.gd), asked of the index
## (index.gd) after the structure is built and before the first arrival.
## No tree is walked and no button is asked. What is checked:
##
## - A declared action that is not in the register (actions.gd): a prompt
##   raised at it would have no words, a step to it would be refused.
## - A declared goes_to that names no place: the way to a step would find
##   nothing, in silence. BACK is where the reader came from, and always
##   stands; ONWARD is where they were going, carried by the question that
##   stopped them (leave_guard.gd).
## - A declared action going nowhere that no model answers, in the place or
##   from anywhere: a press of it would be refused out loud as it landed. A
##   place's models answer what each says it does (place_builder.gd), so an
##   action one forgot to say is found here rather than at the press.
## - A place asking before it is left whose question is no pop-up, or with
##   no model to say when it asks: the leaving would be stopped and nothing
##   raised, or the guard would ask nobody.
## - An action in the register that no place declares: a prompt raised at
##   it would put words in the bar with nothing to glow, a step to it would
##   withdraw, a reminder of it would never come - each in silence. But the
##   pop-ups' way out, which the builder declares whether or not the
##   application has a pop-up (describe_places.gd: CLOSES).
## - A declared action that is one of the driver's own commands: a press
##   would go back or arrive twice over. A button navigates by where its
##   place says its action goes; the four commands are for code.
## - Two places of one name: the index refused the second as it entered,
##   and kept the refusal for here.
## - A place named after a reserved region (Chimes.RESERVED): its bells and
##   handlers would land in the region everything outliving a screen hangs
##   in, and closing it would take them.
##
## A button built for an action its place does not declare is not this
## file's: the button reports it out loud as it enters the tree, at startup
## or as the place fills. broken() hands back one sentence for each thing
## found, and nothing when the tree stands; whoever starts the application
## refuses to go on with any. It holds nothing and never mends what it finds.

## Every sentence about what the places declare that does not stand.
static func broken(index: Index, actions: Actions) -> Array[String]:
	var found: Array[String] = []
	var declared: Dictionary = {}  # every action some place declares, used as a set
	# every place, its declaration: each action registered and no command, each goes_to a place, each going nowhere answered
	for place: Node in index.places():
		for action: StringName in place.performs:
			declared[action] = true
			if not actions.has(action):
				found.append("%s declares %s, which is no action" % [place.name, action])
			if Driver.COMMANDS.has(action):
				found.append("%s declares %s, the driver's own; a button navigates by where its action goes" % [place.name, action])
			var goes_to: StringName = place.performs[action]
			if goes_to != &"" and goes_to != Driver.BACK and goes_to != Driver.ONWARD and not index.has_place(goes_to):
				found.append("%s sends %s to %s, which is no place" % [place.name, action, goes_to])
			if goes_to == &"" and not place.driver.door.handles(place.name, action):
				found.append("nothing answers %s in %s" % [action, place.name])
	# every place asking before it is left: its question a pop-up, and a model to say when
	for place: Node in index.places():
		if place.asks_before_leaving != &"" and index.chart()["kind"].get(place.asks_before_leaving) != Chart.OVERLAY:
			found.append("%s asks %s before it is left, which is no pop-up" % [place.name, place.asks_before_leaving])
		if place.asks_before_leaving != &"" and place.handled_by == null:
			found.append("%s asks before it is left and has no model to say when" % place.name)
	# every action in the register, for one no place declares, but every pop-up's way out
	for action: StringName in actions.get_all():
		if not declared.has(action) and action != Places.CLOSES:
			found.append("nobody performs %s" % action)
	# every place name refused as a second of one, and every reserved one
	for named: String in index.refused_names():
		found.append("two places are named %s" % named)
	for place: Node in index.places():
		if Chimes.RESERVED.has(place.name):
			found.append("%s is a reserved region, and no place may be named after it" % place.name)
	return found
