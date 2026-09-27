extends RefCounted

const Actions := preload("res://addons/gd_chime/actions.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Ledger := preload("res://demo/guided/ledger.gd")
const Places := preload("res://addons/gd_chime/components/primitives/describe_places.gd")

## The guided demo's actions, declared once with what each does, and the
## guide's steps.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The interface itself is the tree the demo builds (guided.gd); nothing here
## says what a place holds. What an action does is one fact about it, read
## the same by a prompt, a reminder or a step, so it is said here, once, into
## the register (actions.gd). The ledger's own names are the ledger's
## (ledger.gd); the home's are here, and so is muting, which the bar's
## switch performs - the startup check found it missing. Unmuting is a
## command the prompts answer and no control here performs, so it is no
## action of this demo's. This file declares and builds nothing.

const SAVES := &"saves_the_day"
const WAVES := &"waves"
## What each action does, said once.
const ACTIONS := {SAVES: ["Save the day"], WAVES: ["Wave at everyone"], Ledger.OPENS: ["Open the ledger"], Ledger.COUNTS: ["Count a coin"], Ledger.JOTS: ["Jot a note"], Ledger.SHOWS_COINS: ["Show the coins"], Ledger.SHOWS_NOTES: ["Show the notes"], Ledger.ZOOMS: ["Zoom in on a coin"], Ledger.GOES_BACK: ["Go back"], Prompts.MUTES: ["Mute these prompts"]}
## The guide's steps: content, the actions in order - the zoom closed by the way out every pop-up has.
const STEPS := [SAVES, Ledger.COUNTS, Ledger.ZOOMS, Places.CLOSES, Ledger.JOTS, WAVES]


## Every action declared on this register, with its words.
static func declare(actions: Actions) -> void:
	actions.declare_all(ACTIONS)
