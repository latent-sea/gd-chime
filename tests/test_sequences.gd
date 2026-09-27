extends SceneTree

## Hundreds of random moves through the driver on a real tree, and after
## every one what must always be true - the state holding no node among them: exactly one active child per active
## state with children; every shown place filled once and holding a live
## token, every hidden one emptied and holding none; of the layers up, only
## the one on top live; the focus inside the layer on top; a refused move
## changing nothing; one bell per move that went through; a move stopped to
## ask first raising the question and changing nothing else; and NO MOVE
## EVER EMPTYING THE NOTES WHILE THEY ASK FIRST, but the question answered
## onward.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_sequences.gd
##
## Hand-picked sequences miss the move nobody thought of; a seeded random
## walk over GO, Back and lower - within pop-ups, onto stacked ones, where
## the reader already is - checks the results, never the inputs,
## which is what the fixed effect order and reconciling exist for. The notes
## ask before they are left while their model says so, which the walk turns
## on and off, and the question every leaving asks stands beside the app; a
## reader's press of its confirm is one of the moves. The seed is fixed, so
## a failure is the same failure every run.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const ActionControl := preload("res://addons/gd_chime/action_control.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Taken := preload("res://addons/gd_chime/taken.gd")
const Guide := preload("res://addons/gd_chime/guide.gd")
const Reminders := preload("res://addons/gd_chime/reminders.gd")
const Index := preload("res://addons/gd_chime/index.gd")
const Queries := preload("res://addons/gd_chime/queries.gd")
const Paths := preload("res://addons/gd_chime/paths.gd")
const Chart := preload("res://addons/gd_chime/chart.gd")
const Token := preload("res://addons/gd_chime/token.gd")
const Ui := preload("res://addons/gd_chime/components/primitives/ui.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Confirm := preload("res://addons/gd_chime/components/recipes/confirm.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")

const SEED := 2026
const MOVES := 400
## The two pop-ups' places, named by the builder: its kind, and how many of that kind were described before it.
const CONSOLE := &"console 1"
const LEAVING := &"confirm 1"
const PLACES: Array[StringName] = [&"app", &"content", &"home", &"ledger", &"coins", &"notes", &"zoom", &"confirm", &"card", &"front", &"rear", CONSOLE, LEAVING]
const ROOTS: Array[StringName] = [&"zoom", &"confirm", &"card", CONSOLE, LEAVING]
## What the notes ask before they are left, while they ask.
const WORDS := "leave the note half written?"
## Every place a move might ask for, in the app or within a root, and nonsense.
const GOES := [&"app", &"home", &"ledger", &"coins", &"notes", &"front", &"rear", &"zoom", &"confirm", CONSOLE, &"attic"]

var _verdict := Verdict.new()


## Counts the times a bell rang.
class Ear extends RefCounted:
	var rings: int = 0

	func heard(_what: StringName) -> void:
		rings += 1


## The model answering for the notes: while on, it refuses their leaving - a
## note half written - and it refuses nothing else.
class Guard extends RefCounted:
	var on: bool = true

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		Reads.note(Chimes.GLOBAL, &"chaos")
		return Phrase.of(WORDS) if on and action == Driver.LEAVES else null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		return null

	func answers() -> Array[StringName]:
		return []


func _init() -> void:
	# the tree starts on the first frame, and until it has nothing is in it
	await process_frame
	await _verdict.states(_after_every_random_move_what_must_hold_holds)
	await _verdict.states(_after_every_random_move_the_guidance_names_only_what_can_be_pressed)
	await _verdict.states(_with_the_game_refusing_and_allowing_and_controls_freed_and_built_between_moves_the_guidance_still_names_only_what_can_be_pressed)
	quit(_verdict.deliver(get_script()))


## The driver test's tree, described and built: an app with a strip of two
## buttons and a content place holding a home and a ledger with two tabs,
## the notes asking before they are left while the guard is on; a zoom, a
## confirm and a card with two tabs beside it, a console that blocks
## nothing, and the question every leaving asks; a button in every leaf.
## Every place counts its filling and emptying as it is told to. As
## {chimes, commands, driver, places, buttons, counts, ui, guard}.
func _made() -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	root.add_child(driver)
	var actions := Actions.new()
	actions.declare_all({&"leaves_anyway": ["leave anyway"]})

	var prompts := Prompts.new(chimes, actions, [&"guide", &"reminder"])
	root.add_child(prompts)
	var ui := Ui.new(root, chimes, commands, driver, prompts, actions)
	var counts: Dictionary = {}
	# every place, counting its filling and emptying
	for named: StringName in PLACES:
		counts[named] = {"filled": 0, "emptied": 0}
	var leaf := func(named: StringName, content: Array) -> Desc:
		return ui.screen(named, content, null, {on_fill = func(_token: Token) -> void: counts[named]["filled"] += 1, on_empty = func() -> void: counts[named]["emptied"] += 1})
	# a button in every leaf, and two on the strip: a field takes the focus as a button does, and needs no action declared
	var strip := ui.row([ui.field(&"back").named(&"back"), ui.field(&"link").named(&"link")])
	var home: Desc = leaf.call(&"home", [ui.field(&"home").named(&"home")])
	var coins: Desc = leaf.call(&"coins", [ui.field(&"coins").named(&"coins")])
	var guard := Guard.new()
	var question := Confirm.for_leaving(ui, &"leaves_anyway")
	question.props["on_fill"] = func(_token: Token) -> void: counts[LEAVING]["filled"] += 1
	question.props["on_empty"] = func() -> void: counts[LEAVING]["emptied"] += 1
	var notes := ui.screen(&"notes", [ui.field(&"notes").named(&"notes")], guard, {on_fill = func(_token: Token) -> void: counts[&"notes"]["filled"] += 1, on_empty = func() -> void: counts[&"notes"]["emptied"] += 1, asks_before_leaving = question})
	var ledger: Desc = leaf.call(&"ledger", [ui.stack([coins, notes])])
	var content: Desc = leaf.call(&"content", [ui.stack([home, ledger])])
	# the app, which is the app from the moment it is built, so what is lifted while it is built can ask the chart
	var app := ui.app(&"app", [ui.column([strip, content])])
	app.props["on_fill"] = func(_token: Token) -> void: counts[&"app"]["filled"] += 1
	app.props["on_empty"] = func() -> void: counts[&"app"]["emptied"] += 1

	var zoom: Desc = leaf.call(&"zoom", [ui.field(&"zoom").named(&"zoom")])
	var confirm: Desc = leaf.call(&"confirm", [ui.field(&"confirm").named(&"confirm")])
	var card: Desc = leaf.call(&"card", [ui.stack([leaf.call(&"front", [ui.field(&"front").named(&"front")]), leaf.call(&"rear", [ui.field(&"rear").named(&"rear")])])])
	var console := ui.pop_up(&"console", func(_which: Bound) -> Desc: return ui.field(&"console").named(&"console"), null).blocks_nothing()
	console.props["on_fill"] = func(_token: Token) -> void: counts[CONSOLE]["filled"] += 1
	console.props["on_empty"] = func() -> void: counts[CONSOLE]["emptied"] += 1
	# every root under the tree, the app first, without the builder's start: no check and no first move, the walk makes its own
	driver.index.app = ui.build(app, root)
	for description: Desc in [zoom, confirm, card, console]:
		ui.build(description, root)
	var places: Dictionary = {}
	var buttons: Dictionary = {}
	for named: StringName in PLACES:
		places[named] = driver.index.place_named(named)
	for named: StringName in [&"back", &"link", &"home", &"coins", &"notes", &"zoom", &"confirm", &"front", &"rear", &"console"]:
		buttons[named] = ui.node_named(named)
	return {"chimes": chimes, "commands": commands, "driver": driver, "places": places, "buttons": buttons, "counts": counts, "ui": ui, "prompts": prompts, "actions": actions, "guard": guard}


func _done(made: Dictionary) -> void:
	# every root before the driver they leave, then the rest
	for named: StringName in [&"app", &"zoom", &"confirm", &"card", CONSOLE, LEAVING]:
		(made["places"][named] as Node).free()
	# the builder's own three: the clock, the carry and the window's shape
	for made_by_the_builder: Node in [made["ui"].motion, made["ui"].carried, made["ui"].shape]:
		made_by_the_builder.free()
	(made["driver"] as Node).free()
	(made["commands"] as Node).free()
	if is_instance_valid(made["prompts"]):
		(made["prompts"] as Node).free()


## A random move through the door, as [what it was, the answer]: a GO, Back
## or a lowering; and, while the question is on top - where lowering any
## other root is refused - its confirm pressed instead of a lowering and now
## and then instead of a GO, carrying the move it was raised about, as a
## reader's press would.
func _move(made: Dictionary, random: RandomNumberGenerator) -> Array:
	var commands: Commands = made["commands"]
	var driver: Driver = made["driver"]
	var kind := random.randi_range(0, 4)
	if kind >= 3 and driver.get_top() == [LEAVING]:
		return ["onward", commands.dispatch(LEAVING, &"leaves_anyway", {"parameter": driver.get_parameter(LEAVING)})]
	match kind:
		0, 2, 4:
			var to: StringName = GOES[random.randi_range(0, GOES.size() - 1)]
			return ["go %s" % to, commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": to})]
		1:
			return ["back", commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})]
	var lowered: StringName = ROOTS[random.randi_range(0, ROOTS.size() - 1)]
	return ["lower %s" % lowered, commands.dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": lowered})]


## Every sentence about the tree that must hold now and does not.
func _wrong(made: Dictionary) -> Array[String]:
	var driver: Driver = made["driver"]
	var places: Dictionary = made["places"]
	var wrong: Array[String] = []
	# every place: shown iff active, filled once iff shown, its token live iff shown
	for named: StringName in PLACES:
		var place: Place = places[named]
		var filled: int = made["counts"][named]["filled"] - made["counts"][named]["emptied"]
		var active: bool = driver.path_of(place).has(named)
		if place.visible != active:
			wrong.append("%s is %s but %s" % [named, "shown" if place.visible else "hidden", "active" if active else "not active"])
		if filled != (1 if active else 0):
			wrong.append("%s is %s and filled %d times net" % [named, "active" if active else "not active", filled])
		if active and (place.token == null or not place.token.is_live()):
			wrong.append("%s is active without a live token" % named)
		if not active and place.token != null and place.token.is_live():
			wrong.append("%s is not active and its token lives" % named)
		# an active place with children has exactly one active child
		if active and not place.places().is_empty():
			var active_children := 0
			for child: Node in place.places():
				if driver.path_of(child).has(child.name):
					active_children += 1
			if active_children != 1:
				wrong.append("%s is active with %d active children" % [named, active_children])
	# only the layer on top is live, of the layers up: the app with nothing raised, else the top overlay; the panel always
	var top_root: StringName = driver.get_top()[0] if not driver.get_top().is_empty() else &"app"
	for named: StringName in [&"app", &"zoom", &"confirm", &"card", LEAVING]:
		var live: bool = (places[named] as Control).focus_behavior_recursive == Control.FOCUS_BEHAVIOR_INHERITED
		if (places[named] as Control).visible and live != (named == top_root):
			wrong.append("%s is %s while %s is on top" % [named, "live" if live else "off", top_root])
	if (places[CONSOLE] as Control).focus_behavior_recursive != Control.FOCUS_BEHAVIOR_INHERITED:
		wrong.append("the console is switched off")
	# the state is a plain value: nothing in it is a node
	if _holds_a_node(driver.get_state()):
		wrong.append("the state holds a node")
	# the focus, if anything holds it, inside the layer on top or the panel
	var focused := root.gui_get_focus_owner()
	if focused != null and not (places[top_root].is_ancestor_of(focused) or places[CONSOLE].is_ancestor_of(focused)):
		wrong.append("the focus is on %s, outside %s" % [focused.name, top_root])
	return wrong


func _after_every_random_move_what_must_hold_holds() -> void:
	var made := _made()
	var driver: Driver = made["driver"]
	var guard: Guard = made["guard"]
	var random := RandomNumberGenerator.new()
	random.seed = SEED
	var ear := Ear.new()
	(made["chimes"] as Chimes).listen(ear, Chimes.GLOBAL, Driver.NAVIGATED)
	var went_through := 0
	var refused := 0
	var stopped := 0
	var onward := 0
	var broken: Array[String] = []
	# every move, the guard now and then turned, then everything that must hold, until the first that does not
	for step: int in range(MOVES):
		if random.randi_range(0, 5) == 0:
			guard.on = not guard.on
		var shown_before := _shown(made)
		var state_before := driver.get_state()
		var rings_before := ear.rings
		var emptied_before: int = made["counts"][&"notes"]["emptied"]
		var asking := guard.on
		var moved := _move(made, random)
		var rang := ear.rings - rings_before
		if moved[0] == "onward":
			onward += 1
			if moved[1] != null or rang != 2:
				broken.append("move %d, onward: answered '%s' with %d bells, where the question lowered and the move made ring two" % [step, moved[1], rang])
		elif str(moved[1]) == WORDS:
			stopped += 1
			# stopped: the question up with the reader where they were, nothing else shown, a bell at most for the question
			var expected := PLACES.filter(func(named: StringName) -> bool: return shown_before.has(named) or named == LEAVING)
			if not driver.path_of(made["places"][LEAVING]).has(LEAVING) or driver.get_state()["path"] != state_before["path"] or driver.get_state()["history"] != state_before["history"] or _shown(made) != expected or rang > 1:
				broken.append("move %d, %s: stopped to ask, yet the reader moved, or more than the question came, or it rang %d" % [step, moved[0], rang])
		elif moved[1] == null:
			went_through += 1
			if rang != 1:
				broken.append("move %d, %s: went through with %d bells" % [step, moved[0], rang])
		else:
			refused += 1
			if _shown(made) != shown_before or rang != 0:
				broken.append("move %d, %s: refused with %s, yet what is shown changed or it rang %d" % [step, moved[0], moved[1], rang])
		# the notes emptied while they asked first, by anything but the question answered onward
		if asking and made["counts"][&"notes"]["emptied"] > emptied_before and moved[0] != "onward":
			broken.append("move %d, %s: the notes were emptied while they asked first, no question answered onward" % [step, moved[0]])
		var wrong := _wrong(made)
		if not wrong.is_empty():
			broken.append("move %d, %s (%s): %s" % [step, moved[0], "went through" if moved[1] == null else moved[1], "; ".join(wrong)])
		if not broken.is_empty():
			break
	_verdict.check(broken.is_empty(), "after every one of %d random moves, everything held: %s" % [MOVES, "; ".join(broken)])
	_verdict.check(went_through > 100 and refused > 50 and stopped > 10 and onward > 5, "the walk went through %d moves, was refused %d, stopped to ask %d and went on from the question %d, all plenty" % [went_through, refused, stopped, onward])
	_done(made)


## Which places are shown.
func _shown(made: Dictionary) -> Array:
	var shown: Array = []
	# every place, kept if visible
	for named: StringName in PLACES:
		if (made["places"][named] as Control).visible:
			shown.append(named)
	return shown


## The tree with a control performing an action in every leaf and two links
## on the app - to the coins and home, the ways the guidance may send the
## reader, out of the notes among them - the register, the record, the
## prompts, a guide over three steps and the reminders, on the walk's own
## fixture. Every control is a real action control, which rings the
## driver's bell as it changes; the flag is what its usable answer reads.
## As the walk's dictionary plus {actions, prompts, controls}.
func _guided() -> Dictionary:
	var made := _made()
	var chimes: Chimes = made["chimes"]
	var commands: Commands = made["commands"]
	var actions: Actions = made["actions"]
	chimes.register(Chimes.GLOBAL, &"chaos")
	var controls: Array = []
	var model := Model.new()
	made["model"] = model
	# a control in every leaf, drawing an action named for the leaf that the leaf declares, going nowhere; the model answers every one
	for named: StringName in [&"home", &"coins", &"notes", &"zoom", &"confirm", &"front", &"rear", CONSOLE]:
		var action := StringName("does_" + String(named))
		actions.declare_all({action: ["do the " + String(named)]})
		commands.register(Chimes.GLOBAL, action, model)
		(made["places"][named] as Place).performs[action] = &""
		var control := ActionControl.new(chimes, commands, made["places"][named], action)
		(made["places"][named] as Node).add_child(control)
		controls.append(control)
	# a link on the app to the coins and one home, each drawn by a control there, answered by nobody
	for link: Array in [[&"opens_coins", &"coins"], [&"opens_home", &"home"]]:
		actions.declare_all({link[0]: ["open the " + String(link[1])]})
		(made["places"][&"app"] as Place).performs[link[0]] = link[1]
		var drawn := ActionControl.new(chimes, commands, made["places"][&"app"], link[0])
		(made["places"][&"app"] as Node).add_child(drawn)
		controls.append(drawn)
	var taken := Taken.new(chimes, actions, commands)
	# every action worth reminding of
	for action: StringName in actions.get_all():
		taken.track(action)
	root.add_child(taken)
	var prompts: Prompts = made["prompts"]
	# every control asks the prompts whether to glow
	for control: ActionControl in controls:
		control.prompts = prompts
	var random := RandomNumberGenerator.new()
	random.seed = SEED
	root.add_child(Reminders.new(chimes, taken, prompts, &"reminder", random, made["driver"]))
	root.add_child(Guide.new(chimes, commands, actions, prompts, &"guide", [&"does_coins", &"does_rear", &"does_home"], made["driver"]))
	made["actions"] = actions
	made["prompts"] = prompts
	made["controls"] = controls
	made["taken"] = taken
	return made


## A model that refuses the actions the chaos has refused, and does the rest;
## what it refuses is a game fact, read as moving on the chaos bell.
class Model extends RefCounted:
	var refused: Dictionary = {}  # action -> true while the game refuses it

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		Reads.note(Chimes.GLOBAL, &"chaos")
		return Phrase.of("refused by the game") if refused.has(action) else null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		return null


func _guided_done(made: Dictionary) -> void:
	# the guide, the reminders, the prompts and the record, then the walk's own
	for node: Node in root.get_children():
		if node is Guide or node is Reminders or node is Prompts or node is Taken:
			node.free()
	_done(made)


## Every sentence about the guidance that must hold now and does not: the
## glowing action, if any, can be reached and every control glowing draws an
## action that can be reached and the door would not refuse; the bar's words
## are that action's; and every route replays to a state where its action
## can be reached.
func _guidance_wrong(made: Dictionary) -> Array[String]:
	var wrong: Array[String] = []
	var prompts: Prompts = made["prompts"]
	var driver: Driver = made["driver"]
	var glowing := prompts.get_glowing()
	if glowing == &"":
		if prompts.get_words() != "":
			wrong.append("nothing glows yet the bar says %s" % prompts.get_words())
		return wrong
	if prompts.get_words() != (made["actions"] as Actions).get_words(glowing):
		wrong.append("the bar says %s for %s" % [prompts.get_words(), glowing])
	if not driver.is_reachable(glowing):
		wrong.append("%s is named and cannot be reached" % glowing)
	# every control glowing, drawing an action that can be reached, would not be refused, and would not stop to ask first
	for control: ActionControl in made["controls"]:
		if control.is_glowing() and not (driver.is_reachable(control.action) and control.is_usable() and not _would_stop(made, control)):
			wrong.append("%s glows and cannot be pressed, or would stop to ask" % control.get_path())
	# every route asked for, replayed press by press through the one transition and the game's refusals, must end with the action reachable
	for action: StringName in (made["actions"] as Actions).get_all():
		var replayed := _replayed(made, action)
		if replayed != "":
			wrong.append(replayed)
	return wrong


## Whether pressing this control now would be stopped to ask first, worked
## out apart from the driver's answers: its move empties the notes while
## they ask.
func _would_stop(made: Dictionary, control: ActionControl) -> bool:
	var driver: Driver = made["driver"]
	var guarded: Dictionary = {&"notes": WORDS} if (made["guard"] as Guard).on else {}
	var moved := Chart.transition(driver.index.chart(), driver.get_state(), Queries.move_of(control.get_goes_to(), Driver.BACK))
	return control.get_goes_to() != &"" and Queries.stopping(moved, guarded) != &""


## The route to this action replayed on a copy of the state: each press but
## the last a declared move the game allows, through the transition, leaving
## the notes standing while they ask first, and at the end the action
## reachable; empty when it holds or no route exists.
func _replayed(made: Dictionary, action: StringName) -> String:
	var driver: Driver = made["driver"]
	var chart := driver.index.chart()
	var performs := driver.index.performs()
	var state := driver.get_state()
	var would := func(place: StringName, asked: StringName) -> Phrase: return (made["commands"] as Commands).game_refusal(place, asked, {})
	var guarded: Dictionary = {&"notes": WORDS} if (made["guard"] as Guard).on else {}
	var way := Queries.route(chart, performs, state, action, would, Driver.BACK, guarded)
	if way.is_empty():
		return ""
	# every press but the last, the declared move pressed on the copy from a place on its screen
	for step: int in range(way.size() - 1):
		var goes_to: StringName = &""
		for named: StringName in Paths.top(chart, state):
			if (performs[named] as Dictionary).has(way[step]) and would.call(named, way[step]) == null:
				goes_to = performs[named][way[step]]
		if goes_to == &"":
			return "the way to %s presses %s, which goes nowhere from there" % [action, way[step]]
		var out: Dictionary = Chart.transition(chart, state, Queries.move_of(goes_to, Driver.BACK))
		if out["refusal"] != null:
			return "the way to %s is refused at %s: %s" % [action, way[step], out["refusal"]]
		if Queries.stopping(out, guarded) != &"":
			return "the way to %s leaves the notes at %s while they ask first" % [action, way[step]]
		state = out["state"]
	if Queries.reachable(chart, performs, state, action, would, Driver.BACK, guarded):
		return ""
	return "the way to %s, %s, ends with it unreachable" % [action, way]


## The walk with the guidance, checking the guidance after every move as well.
func _walk_guided(made: Dictionary, chaos: bool) -> Array[String]:
	var random := RandomNumberGenerator.new()
	random.seed = SEED + 1
	var broken: Array[String] = []
	# every move, then everything that must hold, until the first that does not
	for step: int in range(MOVES):
		if chaos:
			_disturb(made, random)
		var moved := _move(made, random)
		var wrong := _wrong(made) + _guidance_wrong(made)
		if not wrong.is_empty():
			broken.append("move %d, %s (%s): %s" % [step, moved[0], "went through" if moved[1] == null else moved[1], "; ".join(wrong)])
			break
	return broken


## A random action refused by the game or allowed again, or the notes' guard
## turned, with the bell that says a game fact moved; or a random control
## freed, or a fresh one built in a random leaf.
func _disturb(made: Dictionary, random: RandomNumberGenerator) -> void:
	var controls: Array = made["controls"]
	var model: Model = made["model"]
	var chimes: Chimes = made["chimes"]
	match random.randi_range(0, 4):
		4:
			(made["guard"] as Guard).on = not (made["guard"] as Guard).on
			chimes.strike(Chimes.GLOBAL, &"chaos")
		0, 1:
			var action: StringName = (made["actions"] as Actions).get_all()[random.randi_range(0, 7)]
			if model.refused.has(action):
				model.refused.erase(action)
			else:
				model.refused[action] = true
			chimes.strike(Chimes.GLOBAL, &"chaos")
		2:
			if controls.size() > 3:
				var control: ActionControl = controls[random.randi_range(0, controls.size() - 1)]
				controls.erase(control)
				control.free()
		3:
			var named: StringName = [&"home", &"coins", &"notes", &"zoom", &"confirm", &"front", &"rear"][random.randi_range(0, 6)]
			var fresh := ActionControl.new(made["chimes"], made["commands"], made["places"][named], StringName("does_" + String(named)))
			fresh.prompts = made["prompts"]
			(made["places"][named] as Node).add_child(fresh)
			controls.append(fresh)


func _after_every_random_move_the_guidance_names_only_what_can_be_pressed() -> void:
	var made := _guided()
	var broken := _walk_guided(made, false)
	_verdict.check(broken.is_empty(), "after every one of %d random moves, the guidance named only what could be pressed: %s" % [MOVES, "; ".join(broken)])
	_guided_done(made)


func _with_the_game_refusing_and_allowing_and_controls_freed_and_built_between_moves_the_guidance_still_names_only_what_can_be_pressed() -> void:
	var made := _guided()
	var broken := _walk_guided(made, true)
	_verdict.check(broken.is_empty(), "with the game refusing and allowing, and controls freed and built, between %d moves, the guidance named only what could be pressed: %s" % [MOVES, "; ".join(broken)])
	_guided_done(made)


## Whether a value holds an object anywhere inside it.
func _holds_a_node(value: Variant) -> bool:
	if value is Node:
		return true
	if value is Array:
		for item: Variant in value:
			if _holds_a_node(item):
				return true
	if value is Dictionary:
		for key: Variant in value:
			if _holds_a_node(key) or _holds_a_node(value[key]):
				return true
	return false
