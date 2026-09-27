# gd-chime

A small floor for keeping controllers apart: bells that can be struck and
carry nothing, chimes that say who hears which, and two bases for the things
that listen. MIT licensed; see LICENCE.

This document is the folder's rules. Every rule below is checked by
`checks/verify.py`, except the three marked as exceptions.

## A bell is a doorbell, not a letterbox

A bell carries nothing. Struck, it tells whoever is listening that something
they care about is different; it never says what. The listener reads the model
that struck it. So a fact lives in exactly one place, nothing holds a copy that
can disagree with it, and the bells never become the place the data lives.

Bells stop coupling from running both ways. They do not remove coupling and are
not meant to: what is left runs one way. A listener is handed the model it
reads, knows the address of the bell it hears, and knows that model's getters.
The model knows none of it back - it hangs a bell and strikes it, and cannot
tell who is listening, how many, or whether anyone is. Only the chimes hold both
ends, which is why dropping a region takes everything in it at once.

The direction never changes: whoever cares depends on whoever holds the fact,
never the reverse. A screen depends on its model, and a model may depend on
another model - a drain on a busy gate, a console on a log - but nothing ever
depends on what listens to it. That is the layering itself rather than a
convention beside it. A lower layer must never know that a higher one exists,
and without a bell a model would have to call its screens to tell them something
had changed. The bell lets the fact travel up while the dependency points down.

Because a bell carries nothing, the one-way coupling left over is as small as it
can be: an address and some getters. A listener can never come to depend on the
shape of a message, so changing what a model holds reaches only the code that
reads it.

Two shapes, both bells. A *request*: a screen calls a model with a question and
a return address - a bell in the screen's own region - and the model strikes it
when the answer is ready. An *event*: a model strikes a bell of its own that
any screen may listen to. Striking an address nobody has hung is quiet by
design, because the screen that asked may have closed before the answer came.

## A command goes through one door, and is never a bell

A bell is a fact: it carries nothing, any number may listen, and there is no
answer. A command is an intent: it carries a payload, has exactly one handler,
and can be refused. So a press is never a strike. A control that performs an
action dispatches it through `commands.gd` - `dispatch(region, action,
payload)` - and the model registered for that action, in the control's region
or globally, is `told(action, payload)` and answers a String: empty when it did
it, otherwise the reason, which comes back on the same call for the control to
show where the press happened. A handler is always a model, never a control.

Every command that ran is kept as the last, and `COMMAND_RAN` rings in the
global region once it is kept, so whatever watches what the player does - the
interface map recording an action taken, guidance seeing a step done - hears
one bell and reads one record. What changes a model is therefore a question
with an answer: the commands it is registered for.

**Nothing dispatches from inside `heard()`, whichever bell rang.** A ring runs
every listener in turn, and a listener of `COMMAND_RAN` that dispatched would
overwrite the last command before the listeners after it read it - the map
would record the wrong action, and nothing would say so. The commands refuse a
dispatch made while any bell is sounding, out loud, so the rule never depends
on which bell a `heard()` came from. A listener that must act on what it heard
- a guided step moving on - defers its dispatch until the ring is over, with
`call_deferred`, which runs at the end of the current frame.

A prompt names an ACTION, never a control: what matters is where the player
is being pointed, not which of several ways there they take, so every control
performing the action glows.

Closing a screen drops its region from two places, the chimes and the
commands, and nothing keeps them in step: whatever closes a screen, once it
exists, makes one call that does both.

A screen only draws. It holds its parts, the models it was handed, and the
engine's own ephemera - hover, focus, the caret - and nothing else. Where a
list is scrolled to, what is selected, which tab is open: each is a fact, and
a fact lives in a model, read by the screen and moved by a command. A model
built with a screen registers in the screen's region and is dropped with it.

A scanner cannot tell a command from a call, so this is held by review.

`checks/convention_lint.py` checks the half of this a scanner can see: only
`bell.gd` declares a signal, only `belfry.gd` makes one, only `chimes.gd`
connects one or takes one out of the belfry, and a screen asks the look for a
colour while drawing and nowhere else. The look itself is the engine's Theme,
built from a palette and set on the root; the engine carries it to every
screen, and no bell is involved. That a screen was handed a model rather than
reaching for one is not in the text, and is the first exception: review holds
it.

A bell is named for the event it announces - what happened, to what:
`page_landed`, `busy_began`, `ticked`. Never the thing that changed (`rows`,
`time`) and never the state it left behind (`busy`, `over`). An action a
control dispatches says what it does to what: `add_arrival`,
`scroll_table_up`. The strike record and the last command print their names,
so the string has to say it, not only the constant that stands for it in code.
A scanner cannot tell an event from a noun, so this is the second exception:
review holds it.

## It depends on nothing above it

The project that uses this folder depends on it. It depends on nothing in that
project — not its code, not its data, not its names.

The addon installs alone. That is not a claim, it is
`checks/installation_test.py`: a second project under `checks/installed/`,
with its own `project.godot` and the README's first screen, into which the
check copies `addons/gd_chime/` and nothing else, imports it there - a global
class name resolves only after an import pass - and runs it headless, asserting
that the screen builds, that a press is refused with a reason, and that the
words show. It also asserts that no file under the addon mentions an absolute
resource path, `demo/`, `tests/` or `checks/`: the addon may sit anywhere in a
project, and nothing it ships may reach for what stayed behind in this folder.

## It never says a word from the world above it

Nothing here names what the consuming project is about — not in code, not in a
comment, not in a test, not in a file name. `checks/boundary_lint.py` scans
every text file's contents and every file and directory name for terms from a
list, and refuses any resource reference that does not land inside the folder.

The list of terms is supplied at the command line and lives **outside** this
folder. A file in here enumerating the vocabulary of the project above would be
the largest possible instance of the thing the check exists to catch, and it
would match itself on every run, so a clean folder could never pass.

Where a term is also an ordinary word this folder wants — a *durable* identity,
the *holder* of something, a *phase* of a sequence, a *concurrent* write — the
word here is changed rather than the check narrowed. A check with exceptions
accumulating in it is a check on its way to being switched off.

## Its tests run, and say so out loud

Every property worth relying on lives in `tests/`, discovered and run by
`checks/run_tests.py`. Nothing is checked in a script the harness cannot see.

A test is green only when three things agree: the process exited zero, the test
printed that it passed and named itself, and nothing in its output looks like a
failure. Any one of them can be true while the test did not run.

A check that cannot fail is not a check. Break the thing on purpose, watch the
check fail, and record what failed — before believing it.

## Its demos still compile

A demo exists to be looked at, so nothing asserts what one looks like — but
`checks/demos_compile.py` loads every one, so a renamed method or a changed
base is caught before somebody opens it.

## What an application may use is exactly what the facade exports

The promise is `addons/gd_chime/gd_chime.gd` and the two lists it extends -
every name they re-export, read as `GdChime.<Name>` - plus `ChimeApp`, the
node an application extends. Everything else in the addon is internal and may
change without a changelog entry, however public its own names look. That
includes `application.gd`, the main loop the demos and their probes are run
through: it is named from `demo/` and `checks/` and nowhere else, and a game
extends `ChimeApp`.

Within that promise, a name beginning with an underscore is internal and may
change; everything else is kept: breaking it needs a version bump and a line
in the changelog, including before version one.

The edge of the promise is a check: `checks/convention_lint.py` refuses a demo
or app file that path-loads a framework file the facade does not export, and
any file outside `demo/` and `checks/` that names `application.gd`. What
is kept within it is review's, the third exception: a scanner cannot tell a
break from a change, and it is stated anyway because it governs what may be
relied on from outside.

## Running the checks

    python checks/verify.py <this folder> <path to the term list> <path to the engine>

Ten checks, named by the claim each answers. All ten run, or none do — a
missing check is a failure with its own exit code, because a run that quietly
does nine of ten and reports success is worse than no run at all.
