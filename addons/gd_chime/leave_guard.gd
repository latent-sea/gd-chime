extends RefCounted

const Phrase := preload("phrase.gd")
const Chart := preload("chart.gd")
const Events := preload("events.gd")
const Queries := preload("queries.gd")

## The leave guard: a command whose move would empty a place that asks
## before it is left is stopped before any of it runs, and that place's
## question raised in its stead; answered onward, the command runs after
## all, unstopped that once.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PLACE ASKS FIRST while its description names a question - a pop-up
## beside the app, an ordinary confirm (confirm.gd, for_leaving) - and the
## model answering for it refuses the leaving: would(Driver.LEAVES, {}) is
## the sentence to ask, or nothing while the place may be left. The model is
## asked at the moment of each move, so a draft saved meanwhile is left
## without a word.
##
## THE DOOR ASKS THIS FOR A COMMAND THAT MOVES THE READER - one of the
## driver's own, or a press whose place says it goes somewhere - past its
## refusal and BEFORE ANY HANDLER IS TOLD (commands.gd), so a press that
## would change something and leave has changed nothing when it is stopped.
## The stopping is no refusal of the press, which is never drawn inert for
## it, but of its move, which becomes another: the words asked are the
## door's answer, and the door keeps the command as PAUSED - not done, for
## whatever tracks what the player did, and refused by nobody, so the
## control pressed shows nothing of it. The chart works the move out
## without making it (chart.gd): the places it would EMPTY are those it
## leaves, a place deeper than the one left among them, innermost first, and
## the first of them asking first stops it (queries.gd). Raising the
## question empties nothing, and lowering it empties only itself.
##
## THE STOPPED COMMAND IS THE QUESTION'S PARAMETER, a plain value: the
## region, the action and the payload it was dispatched with, and the words
## to ask, read as the question opens. A pop-up raised is never walked, so
## the question is in no history entry. Answered ONWARD (Driver.ONWARD), the
## question is lowered - the reader where they stood, the focus back on what
## opened it - and the command dispatched again with the guard passed for
## that one dispatch: a Back is the Back that was asked for, a press's
## handler is told then and not before, and the move lands as it would have
## with no guard; the next leaving asks again. A command refused by the time
## it goes on answers with its refusal, the reader where they stood.
## Cancelled, the question is lowered and nothing else is done.
##
## Routing asks guarded() and treats every place in it as refused to leave
## (queries.gd), so the guidance never points the reader out of one.
##
## It holds nothing of where the reader is and never touches the tree: it
## asks the driver that made it, and moves the reader only through it.

## The driver this guards, which made it and moves the reader for it.
var driver: Node

var _passing: bool = false  # whether the next command asked about goes unstopped: the one a question was answered onward for


func _init(guarding: Node) -> void:
	driver = guarding


## A command that moves the reader, about to run: stopped when its move
## would empty a place asking first now - that place's question raised with
## the command as its parameter, and the words asked answered. Else, and for
## the one command a question was answered onward for, nothing.
func stops_to_ask(in_region: StringName, action: StringName, payload: Dictionary) -> Phrase:
	if _passing:
		_passing = false
		return null
	var asking := guarded()
	# the move the command means: one of the driver's own, else where its place says a press of it goes
	var move: Events.Event = driver.event_of(action, payload) if driver.COMMANDS.has(action) else Queries.move_of(driver.goes_to(in_region, action), driver.BACK, payload.get("parameter"))
	var stopped := Queries.stopping(Chart.transition(driver.index.chart(), driver.get_state(), move), asking)
	if stopped == &"":
		return null
	var question := {"region": in_region, "action": action, "payload": payload.duplicate(true), "asks": asking[stopped]}
	driver.told(driver.GO, {"place": driver.index.place_named(stopped).asks_before_leaving, "parameter": question})
	return asking[stopped]


## The command a question stopped, run after all: the question on top
## lowered, then the command dispatched again with the guard passed for it
## alone; its answer is the answer.
func goes_on(stopped: Dictionary) -> Phrase:
	driver.told(driver.LOWERS, {"place": driver.get_top()[0]})
	_passing = true
	var answer: Phrase = driver.door.dispatch(stopped["region"], stopped["action"], stopped["payload"])
	_passing = false
	return answer


## Every place that would ask before it is left now, by name: the words the
## model answering for it refuses the leaving with.
func guarded() -> Dictionary:
	var asking: Dictionary = {}
	# every place naming a question, its model asked now
	for place: Node in driver.index.places():
		var words: Phrase = place.handled_by.would(driver.LEAVES, {}) if place.asks_before_leaving != &"" else null
		if words != null:
			asking[place.name] = words
	return asking
