extends RefCounted

const Bound := preload("bound.gd")
const Place := preload("../../place.gd")
const Chimes := preload("../../chimes.gd")
const Driver := preload("../../driver.gd")

## The places' builder: app, screen, tabs and pop_up made as places
## (place.gd), declaring what their pressables perform and registering
## their handler for it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A place is hidden until the driver shows it, across the whole of what
## holds it; it fills and empties through what its description says; and it
## declares from every pressable inside it and from every template asked
## with an empty handle.
##
## A PLACE IS HANDED THE MODELS THAT ANSWER FOR IT - one, or several - and
## each is put in the tree beside the app and told the actions it answers
## (controller.gd) IN THIS PLACE'S REGION. That is the only way a model of a
## place is registered: the region follows the place, and no application
## writes one. The first of them answers for the place itself - asked
## whether it may be left - and the place holds it, with the pop-up a
## screen's description gives to ask before it is left (leave_guard.gd).
## GIVEN ONE MODEL, that model also takes every action the place declares
## that nothing answers yet, since the place is its own; given SEVERAL, each
## answers exactly what it says it does, so an action nobody claimed is
## reported by the startup check rather than swallowed by whichever model
## happened to be first.
##
## EVERY POP-UP MET IS LIFTED (ui.gd): one among what the place holds, one
## a press inside it opens, the question it asks before it is left, and the
## app's context menu where a menu target inside it opens that - each built
## beside the app once this place stands, so it is drawn over the app and
## stands from startup however deep it was described. A pop-up declares its
## way out, CLOSES going back, which no model answers; one PRESENTED - a
## moment, up while its model's fact holds - is raised and lowered by the
## driver as the fact moves (driver.gd), and its way out is its model's.


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made := Place.new(ui.chimes, desc.props["name"], ui.driver)
	made.blocks = desc.props["blocks"]
	made.on_fill = desc.props.get("on_fill", Callable())
	made.on_empty = desc.props.get("on_empty", Callable())
	var answering: Array = models_of(desc.props["handled_by"])
	# the first of them answers for the place itself - asked whether it may be left (leave_guard.gd)
	made.handled_by = answering[0] if not answering.is_empty() else null
	var asks: RefCounted = desc.props.get("overlay")
	made.asks_before_leaving = asks.get_place() if asks != null else &""
	made.set_anchors_preset(Control.PRESET_FULL_RECT)
	# the app is the app from the moment it exists, so what is built into it can ask the driver
	if desc.kind == &"app":
		ui.driver.index.app = made
	# the question it asks before it is left, lifted where it is a pop-up; one that is not is reported by the startup check, never built
	var lifting: Array = [asks] if asks != null and asks.kind == ui.POP_UP else []
	declare(ui, desc, made, lifting)
	# a moment is up while its fact holds, the driver raising and lowering it; every other pop-up declares the way out it owns, going back
	if desc.props.has("presented"):
		ui.driver.present(made.name, desc.props["presented"])
	elif desc.kind == ui.POP_UP:
		made.performs[ui.CLOSES] = Driver.BACK
	# every model handed to this place: told the actions it answers here, and put beside the app where it is a node
	for model: Object in answering:
		if model is Node:
			ui.also(model as Node)
		ui.commands.stand(made.name, model)
	# a place of ONE model: that model answers everything the place declares and nothing else answers yet - a pop-up's way out by nobody
	if answering.size() == 1:
		for action: StringName in made.performs:
			if action != ui.CLOSES and not ui.commands.handles(made.name, action):
				ui.commands.register(made.name, action, made.handled_by)
	ui.attach(made, parent, desc.facts)
	# every pop-up met inside, lifted once this stands, so it is drawn over it
	for overlay: RefCounted in lifting:
		ui.lift(overlay)
	return made


## The models a place was handed: several, one, or none.
static func models_of(given: Variant) -> Array:
	if given == null:
		return []
	return given if given is Array else [given]


## Every pressable, field, grip, menu target, pan_zoom, pinned drawing, virtual list's cursor and description saying what it declares inside this description, not one inside a place within,
## declared on the place: its action, and where it goes. Either side of a
## when is inside it; what a template will build is asked of it once, with
## an empty handle, so a collection empty at startup declares all the same.
## Every pop-up met is put in lifting, for the place to lift once it stands.
static func declare(ui: RefCounted, desc: RefCounted, place: Node, lifting: Array) -> void:
	var inside: Array = desc.children.duplicate()
	if desc.kind == &"when":
		for side: StringName in [&"a", &"b"]:
			if desc.props[side] != null:
				inside.append(desc.props[side])
	if desc.kind == &"each" or desc.kind == &"virtual_list":
		var described: RefCounted = ui.describe_with(desc.props["template"], Bound.new(func() -> Variant: return null))
		if described != null:
			inside.append(described)
	for child: RefCounted in inside:
		if child.kind == ui.POP_UP:
			lifting.append(child)
		if ui.PLACES.has(child.kind):
			continue
		# a pop-up a press opens, carried on the press
		if child.props.get("overlay") != null:
			lifting.append(child.props["overlay"])
		if child.kind == &"pressable":
			place.performs[child.props["action"]] = child.props["goes_to"]
		# a description that says what it declares, {action: where it goes}: where it goes stands over a menu's offer of the same, which goes nowhere of itself
		for action: StringName in child.props.get("declares", {}):
			if place.performs.get(action, &"") == &"":
				place.performs[action] = child.props["declares"][action]
		if [&"field", &"key_capture", &"drop_target", &"slider", &"range_slider", &"area", &"grip", &"nearing"].has(child.kind):
			place.performs[child.props["action"]] = &""
		if child.kind == &"grip" and child.props["folds"] != &"":
			place.performs[child.props["folds"]] = &""
		# a draggable pressed as well as carried: its click's action
		if child.kind == &"draggable" and child.props["presses"] != &"":
			place.performs[child.props["presses"]] = &""
		# a menu's target: its opening going to the app's context menu, lifted while its description is still held, and every action it offers, unless a press declared it already
		if child.kind == &"menu_target":
			place.performs[child.props["opens"]] = ui.menu_place
			if ui.context_menu != null:
				lifting.append(ui.context_menu)
			for offered: StringName in child.props["actions"]:
				if not place.performs.has(offered):
					place.performs[offered] = &""
		if child.kind == &"anchored_at":
			place.performs[child.props["sends_away"]] = Driver.BACK
		# a field's second action and the one its leaving dispatches, where it has them
		for also: StringName in ([child.props["changes"], child.props["leaves"]] if child.kind == &"field" else []):
			if also != &"":
				place.performs[also] = &""
		# a file picked is its action's press, going nowhere (describe_forms.gd)
		if child.kind == &"file_pick":
			place.performs[child.props["action"]] = &""
		if child.kind == &"pan_zoom":
			for action: StringName in child.props["actions"].values():
				place.performs[action] = &""
		# a drawing's pick, unless a part pinned on it declared it already
		if child.kind == &"pinned" and not place.performs.has(child.props["picks"]):
			place.performs[child.props["picks"]] = &""
		# a virtual list's cursor: every command its keys, its presses and its keys heard anywhere dispatch
		if child.kind == &"virtual_list" and not child.props["cursor"].is_empty():
			var cursor: Dictionary = child.props["cursor"]
			for action: StringName in cursor["keys"].map(func(key: Array) -> StringName: return key[2]) + cursor["anywhere"].map(func(key: Array) -> StringName: return key[1]) + [cursor["presses"], cursor["twice"]]:
				place.performs[action] = &""
		declare(ui, child, place, lifting)
