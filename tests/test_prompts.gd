extends SceneTree

## What must be true of the prompts.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_prompts.gd
##
## Nothing is prompted until a source raises something. A raised prompt is
## current - the action to glow, the register's words for it and its source - and withdrawn,
## nothing is. Of two sources with a prompt each, the one named first when this
## was built wins, whichever was raised first; withdrawn, the other takes over;
## and changing the list afterwards changes nothing. Raising again replaces what
## that source had. A muted source's prompt is kept but not current, and
## unmuting brings it back.
##
## The current prompt and the mutings are values: whatever read the current
## prompt is woken, at the frame's end, every time it changes and never when
## it does not - a losing source raising, a source muted that was not
## current, the same prompt raised again; whatever read a muting is woken
## every time a source's muting changes, whether or not the current prompt
## moved, and never when it does not. Woken at the frame's end, as every
## value is: one timing for every fact.
##
## Refused out loud, and changing nothing: a source it was not built with,
## whether raising, withdrawing or muting; a name that is no action
## performs, a misspelt one or a screen's name alike; and a source
## named twice as it is built. And it stands in the global region.
##
## A refusal is heard through a logger that counts only what is pushed as an
## error, so a refusal made out loud is a property here rather than a line in
## the output nobody reads.
##
## Nothing here is in the tree: a value rings at the frame's end whatever
## holds it, so a property about what woke waits a frame.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Verdict := preload("res://tests/verdict.gd")

const GUIDE := &"guide"
const REMINDER := &"reminder"
## What woke the ear: the current prompt moving, or the reminder's muting.
const PROMPT := &"prompt"
const MUTING := &"muting"

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how the prompts say no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## Reads the current prompt and one source's muting, as whatever shows them
## would, and keeps what woke it, in order.
class Ear extends RefCounted:
	var arrivals: Array[StringName] = []


func _init() -> void:
	OS.add_logger(_hearing)
	await _verdict.states(_nothing_is_prompted_until_a_source_raises_something)
	await _verdict.states(_a_raised_prompt_is_current_until_it_is_withdrawn)
	await _verdict.states(_the_source_named_first_wins_whichever_was_raised_first)
	await _verdict.states(_changing_the_list_of_sources_handed_in_changes_nothing)
	await _verdict.states(_raising_again_replaces_what_that_source_had)
	await _verdict.states(_a_muted_source_is_kept_but_not_current_and_unmuting_brings_it_back)
	await _verdict.states(_a_reader_of_the_prompt_wakes_when_it_changes_and_never_otherwise)
	await _verdict.states(_a_reader_of_a_muting_wakes_when_it_changes_and_never_otherwise)
	await _verdict.states(_a_mute_or_unmute_dispatched_for_a_source_is_done_and_an_unknown_one_refused)
	await _verdict.states(_a_source_it_was_not_built_with_is_refused_out_loud)
	await _verdict.states(_an_action_no_part_performs_is_refused_out_loud)
	await _verdict.states(_a_source_named_twice_is_refused_out_loud_and_counted_once)
	await _verdict.states(_the_prompts_stand_in_the_global_region)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## Prompts built over a register of three actions, with these sources, and
## an ear reading the current prompt (PROMPT) and the reminder's muting
## (MUTING), as {prompts, ear, chimes}.
func _made(sources: Array[StringName] = [GUIDE, REMINDER]) -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var actions := Actions.new()
	actions.declare_all({&"next_step": ["takes the next step"]})
	actions.declare_all({&"open_ledger": ["opens the ledger"]})
	actions.declare_all({&"close_ledger": ["closes the ledger"]})
	var prompts := Prompts.new(chimes, actions, sources)
	var ear := Ear.new()
	chimes.follow(ear, PROMPT, func() -> void: _current(prompts), func() -> void: ear.arrivals.append(PROMPT))
	chimes.follow(ear, MUTING, func() -> void: prompts.is_muted(REMINDER), func() -> void: ear.arrivals.append(MUTING))
	return {prompts = prompts, ear = ear, chimes = chimes}


## A frame's end passed, so whatever a value woke has been woken.
func _settled() -> void:
	await process_frame
	await process_frame


func _done(made: Dictionary) -> void:
	(made["prompts"] as Prompts).free()


## The current prompt as one value, so a check can say all of it: [source, action, words].
func _current(prompts: Prompts) -> Array:
	return [prompts.get_source(), prompts.get_glowing(), prompts.get_words()]


## How many times the ear was woken by this.
func _rings(ear: Ear, woke: StringName) -> int:
	return ear.arrivals.count(woke)


func _nothing_is_prompted_until_a_source_raises_something() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]

	_verdict.check(_current(prompts) == [&"", &"", ""], "built, nothing glows, no words, no source: %s" % [_current(prompts)])
	_done(made)


func _a_raised_prompt_is_current_until_it_is_withdrawn() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]

	prompts.raise(REMINDER, &"open_ledger")
	_verdict.check(_current(prompts) == [REMINDER, &"open_ledger", "opens the ledger"], "raised, it is current, with its words and its source: %s" % [_current(prompts)])
	prompts.withdraw(REMINDER)
	_verdict.check(_current(prompts) == [&"", &"", ""], "withdrawn, nothing is: %s" % [_current(prompts)])
	_done(made)


## Which source matters more is the order the prompts were built with, not the
## order things happened to be raised in.
func _the_source_named_first_wins_whichever_was_raised_first() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]

	prompts.raise(REMINDER, &"open_ledger")
	prompts.raise(GUIDE, &"next_step")
	_verdict.check(_current(prompts) == [GUIDE, &"next_step", "takes the next step"], "the guide, named first, wins though raised second: %s" % [_current(prompts)])
	prompts.withdraw(GUIDE)
	_verdict.check(_current(prompts) == [REMINDER, &"open_ledger", "opens the ledger"], "withdrawn, the reminder takes over: %s" % [_current(prompts)])
	_done(made)


## The order is taken as it was handed in; the caller still holds its list, and
## what it does with it afterwards is its own business.
func _changing_the_list_of_sources_handed_in_changes_nothing() -> void:
	var order: Array[StringName] = [GUIDE, REMINDER]
	var made := _made(order)
	var prompts: Prompts = made["prompts"]
	order.reverse()

	prompts.raise(REMINDER, &"open_ledger")
	prompts.raise(GUIDE, &"next_step")
	_verdict.check(prompts.get_source() == GUIDE, "the guide still wins after the caller reversed its list: %s" % prompts.get_source())
	_done(made)


func _raising_again_replaces_what_that_source_had() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]

	prompts.raise(REMINDER, &"open_ledger")
	prompts.raise(REMINDER, &"close_ledger")
	_verdict.check(_current(prompts) == [REMINDER, &"close_ledger", "closes the ledger"], "the second prompt replaced the first: %s" % [_current(prompts)])
	prompts.withdraw(REMINDER)
	_verdict.check(_current(prompts) == [&"", &"", ""], "and one withdrawal leaves nothing behind it: %s" % [_current(prompts)])
	_done(made)


## A player turning reminders off does not lose what a reminder would have said:
## turned back on, it is there.
func _a_muted_source_is_kept_but_not_current_and_unmuting_brings_it_back() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]

	prompts.raise(GUIDE, &"next_step")
	prompts.raise(REMINDER, &"open_ledger")
	prompts.set_muted(GUIDE, true)
	_verdict.check(prompts.is_muted(GUIDE), "the guide says it is muted")
	_verdict.check(_current(prompts) == [REMINDER, &"open_ledger", "opens the ledger"], "muted, the guide's prompt is not current: %s" % [_current(prompts)])
	prompts.set_muted(REMINDER, true)
	_verdict.check(_current(prompts) == [&"", &"", ""], "both muted, nothing is: %s" % [_current(prompts)])
	prompts.set_muted(GUIDE, false)
	_verdict.check(not prompts.is_muted(GUIDE) and _current(prompts) == [GUIDE, &"next_step", "takes the next step"], "unmuted, the guide's prompt is back as it was: %s" % [_current(prompts)])
	_done(made)


## A control reads the prompts again every time what it read moves, so a wake
## that changed nothing is a redraw for nothing, and a change that woke nothing
## is a control left glowing wrongly.
func _a_reader_of_the_prompt_wakes_when_it_changes_and_never_otherwise() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]
	var ear: Ear = made["ear"]

	prompts.raise(GUIDE, &"next_step")
	_verdict.check(_rings(ear, PROMPT) == 0, "a raise wakes nothing the instant it is made: the prompt is a value, heard at the frame's end")
	await _settled()
	_verdict.check(_rings(ear, PROMPT) == 1, "raising the first prompt wakes its reader: %d" % _rings(ear, PROMPT))
	prompts.raise(REMINDER, &"open_ledger")
	await _settled()
	_verdict.check(_rings(ear, PROMPT) == 1, "a losing source raising does not: %d" % _rings(ear, PROMPT))
	prompts.set_muted(REMINDER, true)
	await _settled()
	_verdict.check(_rings(ear, PROMPT) == 1, "nor muting a source that was not current: %d" % _rings(ear, PROMPT))
	prompts.raise(GUIDE, &"next_step")
	await _settled()
	_verdict.check(_rings(ear, PROMPT) == 1, "nor the same prompt raised again: %d" % _rings(ear, PROMPT))
	prompts.set_muted(GUIDE, true)
	await _settled()
	_verdict.check(_rings(ear, PROMPT) == 2, "and the current source muted, leaving nothing, wakes it: %d" % _rings(ear, PROMPT))
	_done(made)


## A switch showing whether a source is muted reads it again when it moves, so
## it follows a mute made anywhere - from the words' own off link, say - even
## when the prompt on screen did not move.
func _a_reader_of_a_muting_wakes_when_it_changes_and_never_otherwise() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]
	var ear: Ear = made["ear"]
	prompts.raise(GUIDE, &"next_step")
	await _settled()

	prompts.set_muted(REMINDER, true)
	await _settled()
	_verdict.check(_rings(ear, MUTING) == 1 and _rings(ear, PROMPT) == 1, "muting a source that is not current wakes its reader, though the prompt did not move: %s" % [ear.arrivals])
	prompts.set_muted(REMINDER, true)
	await _settled()
	_verdict.check(_rings(ear, MUTING) == 1, "muting it again does not: %d" % _rings(ear, MUTING))
	prompts.set_muted(REMINDER, false)
	await _settled()
	_verdict.check(_rings(ear, MUTING) == 2, "unmuting it does: %d" % _rings(ear, MUTING))
	prompts.set_muted(GUIDE, false)
	await _settled()
	_verdict.check(_rings(ear, MUTING) == 2, "and unmuting one that was never muted does not: %d" % _rings(ear, MUTING))
	_done(made)


## The off switch a prompt carries is a command through the door: the prompts,
## registered for it, mute and unmute the source it names, and answer a source
## they were not built with as the refusal.
func _a_mute_or_unmute_dispatched_for_a_source_is_done_and_an_unknown_one_refused() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]
	var door := Commands.new(made["chimes"])
	door.register(Chimes.GLOBAL, Prompts.MUTES, prompts)
	door.register(Chimes.GLOBAL, Prompts.UNMUTES, prompts)
	prompts.raise(REMINDER, &"open_ledger")

	_verdict.check(door.dispatch(&"a_screen", Prompts.MUTES, {"source": REMINDER}) == null and prompts.is_muted(REMINDER), "a mute dispatched is done, and the source is muted")
	_verdict.check(_current(prompts) == [&"", &"", ""], "so its prompt is no longer current: %s" % [_current(prompts)])
	_verdict.check(door.dispatch(&"a_screen", Prompts.UNMUTES, {"source": REMINDER}) == null and not prompts.is_muted(REMINDER), "an unmute dispatched is done, and the source is back")
	var before := _hearing.refusals
	var answer := door.dispatch(&"a_screen", Prompts.MUTES, {"source": &"giude"})
	_verdict.check(_hearing.refusals == before + 1 and str(answer).contains("giude"), "a source it was not built with is refused out loud and as the answer: '%s'" % answer)
	door.free()
	_done(made)


## A prompt from a source nobody built the prompts with would never be shown and
## nothing would say why, so it is refused - raising, withdrawing and muting alike.
func _a_source_it_was_not_built_with_is_refused_out_loud() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]
	var ear: Ear = made["ear"]
	prompts.raise(GUIDE, &"next_step")
	await _settled()
	var before := _hearing.refusals

	prompts.raise(&"giude", &"open_ledger")
	_verdict.check(_hearing.refusals == before + 1, "raising from it is refused out loud")
	prompts.withdraw(&"giude")
	_verdict.check(_hearing.refusals == before + 2, "so is withdrawing")
	prompts.set_muted(&"giude", true)
	_verdict.check(_hearing.refusals == before + 3, "and muting")
	await _settled()
	_verdict.check(_current(prompts) == [GUIDE, &"next_step", "takes the next step"] and ear.arrivals == [PROMPT], "and none of it changed what is current or woke anything: %s" % [ear.arrivals])
	_done(made)


## A prompt at an action no part performs - a misspelt one, or a screen's name -
## would glow nowhere: it is refused as it is raised, where the mistake is.
func _an_action_no_part_performs_is_refused_out_loud() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]
	var ear: Ear = made["ear"]
	var before := _hearing.refusals

	prompts.raise(REMINDER, &"open_ledgr")
	_verdict.check(_hearing.refusals == before + 1, "a misspelt action is refused out loud")
	prompts.raise(REMINDER, &"home")
	_verdict.check(_hearing.refusals == before + 2, "and so is a screen's name, which no part performs")
	await _settled()
	_verdict.check(_current(prompts) == [&"", &"", ""] and ear.arrivals.is_empty(), "and nothing is current or woke: %s" % [_current(prompts)])
	prompts.raise(REMINDER, &"open_ledger")
	_verdict.check(prompts.get_glowing() == &"open_ledger", "while an action a part performs is taken: %s" % prompts.get_glowing())
	_done(made)


## A source named twice says two different things about where it stands, so the
## repeat is refused as the prompts are built, and the first place it was named
## is the one it holds.
func _a_source_named_twice_is_refused_out_loud_and_counted_once() -> void:
	var before := _hearing.refusals
	var made := _made([GUIDE, REMINDER, GUIDE])
	var prompts: Prompts = made["prompts"]

	_verdict.check(_hearing.refusals == before + 1, "the repeat is refused out loud")
	prompts.raise(REMINDER, &"open_ledger")
	prompts.raise(GUIDE, &"next_step")
	_verdict.check(prompts.get_source() == GUIDE, "the guide holds the first place it was named: %s" % prompts.get_source())
	_done(made)


## There is one set of prompts and it outlives every screen, so it stands in
## the global region, and whatever reads it hears both its facts move.
func _the_prompts_stand_in_the_global_region() -> void:
	var made := _made()
	var prompts: Prompts = made["prompts"]
	var ear: Ear = made["ear"]

	prompts.raise(REMINDER, &"open_ledger")
	await _settled()
	prompts.set_muted(GUIDE, true)
	await _settled()
	_verdict.check(prompts.region == Chimes.GLOBAL, "the prompts are in the global region: %s" % prompts.region)
	_verdict.check(ear.arrivals == [PROMPT, MUTING], "and whatever reads them hears both move: %s" % [ear.arrivals])
	_done(made)
