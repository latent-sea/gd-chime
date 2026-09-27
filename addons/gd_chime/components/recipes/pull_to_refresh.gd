extends RefCounted

const Themes := preload("../../theme.gd")
const Fetched := preload("../../fetched.gd")
const Phrase := preload("../../phrase.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Pull := preload("../primitives/pull.gd")
const Loading := preload("loading.gd")
const Feedback := preload("../../theme_feedback.gd")

## A list a finger pulls to ask for what it shows again, over what the place
## fills with (fetched.gd): what the pull says as it opens - pull, let go,
## and loading's own mark while it is on its way.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The pull (pull.gd) dispatches ASKS_AGAIN; so does the application's own
## press or key, and so does the way to try again a failure offers, which a
## pull shows as it would its own. A REFRESH AND A FIRST FETCH ARE THE SAME
## ASKING, so there is one model and one action for both, and this holds
## none of it: whether one is on its way is the fetch's `loading`.
##
## NOTHING HERE SAYS A FAILURE. There is one presentation of a far-side
## failure - a notification and the mark on the thing itself - and it is
## loading's (loading.gd), inside the content this wraps, so a list keeps
## everything it showed while the reason stands over it.
##
## Its look is the pull's line, PullIndicator (theme_feedback.gd).


## The list, held in a pull that asks the far side for it again.
static func make(ui: Ui, fetched: Fetched, content: Desc) -> Desc:
	var says := func(phase: Bound) -> Desc: return indicator(ui, phase)
	return ui.pull(Fetched.ASKS_AGAIN, fetched.loading, says, content)


## What a pull says, by its phase: pull to refresh; let go, once it would;
## and loading's mark and words while the asking is on its way.
static func indicator(ui: Ui, phase: Bound) -> Desc:
	var words: Bound = phase.map(func(now: Variant) -> Phrase: return Phrase.of("Let go to refresh") if now == Pull.ARMED else Phrase.of("Pull to refresh"))
	var refreshing: Bound = phase.map(func(now: Variant) -> bool: return now == Pull.REFRESHING)
	return ui.row([ui.when(refreshing, Loading.mark(ui), ui.text(words, Themes.REASON))], Feedback.PULL)
