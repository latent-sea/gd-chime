extends RefCounted

## A cancellation token: live until cancelled, and dead with its parent.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## CANCELLATION IS TIED TO A STATE'S LIFETIME. Entering a place issues a
## token and leaving it cancels that token (driver.gd, applier.gd); anything
## the place set loading in the background is handed the token and asks it
## before its result lands, so a page that arrives after the reader left
## lands on nothing. A token issued under another is live only while both
## are: a list inside a place issues its own under the place's, cancels and
## reissues it when its rows are replaced, and is dead with the place
## without being told. That is the one mechanism for a state left and for
## data replaced.
##
## It answers is_live() and is cancelled; nothing rings, nothing listens, and
## a token cancelled twice is cancelled.

var _live: bool = true
var _under: RefCounted = null  # the token this one is issued under, or none


func _init(under: RefCounted = null) -> void:
	_under = under


## Whether this token, and every token it was issued under, still stands.
func is_live() -> bool:
	return _live and (_under == null or (_under as RefCounted).is_live())


func cancel() -> void:
	_live = false
