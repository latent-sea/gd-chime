extends RefCounted

## The named options a description takes past its first few, and the one
## check on them: a key none of them knows is said out loud, naming the ones
## it does know.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE HOUSE SHAPE. No public description or recipe takes more than four
## positional parameters. What is left over goes one of two ways, and which
## one is not a choice made afresh each time:
##
##   - an option CHANGES HOW THE THING IS BUILT - the unit a figure is
##     written in, the function a row is keyed by, the place a press goes to
##     - so it is a named option here, in the last parameter, because the
##     function needs it while it builds and a chained name comes too late;
##   - an option only MARKS A DESCRIPTION ALREADY MADE - it wraps, it hides
##     while empty, it keeps what it is not showing - so it is a chained name
##     on the description itself (desc.gd), beside grow, basis and named:
##     ui.text(title).wraps().hides_empty().
##
## That second way is where every boolean went. A bare true at a call site
## says nothing about which of a signature's flags it is, and two of them
## in a row say less; a chained name says it in English, and a flag left off
## is simply a name not said.
##
## WHERE AN OPTION'S MEANING IS WRITTEN: once. The names below are the ones
## more than one description takes, and this file is the only place they are
## explained; a description's own options are explained in its own header,
## which is likewise the only place. A list of known keys sits beside the
## function that takes it, so the two cannot drift apart.

## The Theme name a piece wears, or a bound value reading one (styled.gd).
const STYLE := "style"
## The place a press goes to, none and it stays where it is.
const GOES_TO := "goes_to"
## What a press carries: a dictionary, or a bound value read as the press lands.
const PAYLOAD := "payload"
## Which key of a thing is its identity, for a press that carries it.
const ID_KEY := "id_key"
## How many decimal places a number is written to.
const PLACES := "places"
## The pop-up a press opens, and which one of its kind: the parameter it is entered as.
const OPENS := "opens"
const WITH := "with"
## Which way a line runs: Layout.ROW or Layout.COLUMN, or a bound value reading one.
const RUNS := "runs"
## The action a fold is dispatched as, none and the thing does not fold.
const FOLDS := "folds"
## The words standing where a thing has nothing to show: a phrase.
const SAYS_EMPTY := "says_empty"


## The options given, with every key none of them knows said out loud - what
## takes them, the key, and the keys it does take. It answers the options so
## a caller reads them straight out of the check.
static func checked(what: String, given: Dictionary, known: Array) -> Dictionary:
	# every key given, against the ones this description knows
	for option: String in given:
		if not known.has(option):
			push_error("%s has no option %s; it has %s" % [what, option, known])
	return given
