extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Motion := preload("../../motion.gd")
const Keyframes := preload("../primitives/keyframes.gd")
const Phrase := preload("../../phrase.gd")
const Formats := preload("../../formats.gd")

## A countdown: time remaining on something that will happen whether the
## reader acts or not. It travels with the reader: whoever composes puts it
## in the strip, not on the surface that owns the deadline.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE LAST SECONDS BEAT: once the time left is down to the last of it -
## how many seconds is the look's, `beat_for` - the readout dips and comes
## back, once a BEAT, over and over until it runs out. A beat is the look's
## own token and means a second passing; it is not the pulse's period,
## which means "look here". How deep it dips is the look's too. The beat is a second voice and never the
## only one - the seconds are in the words, and the words are all a reader
## whose motion is reduced, and who sees the track rest, ever needed.

## One beat: down quickly, held down, and back over the rest of the period.
const BEATS := [
	{&"at": 0.0, Keyframes.OPACITY: 1.0, Keyframes.SCALE: 1.0},
	{&"at": 0.3, Keyframes.OPACITY: &"beat_opacity", Keyframes.SCALE: &"beat_scale", &"hold": 0.1},
	{&"at": 1.0, Keyframes.OPACITY: 1.0, Keyframes.SCALE: 1.0},
]

## What it says once the time has run out, unless it is given other words.
const NOW := "Now"


## The seconds remaining, a bound value, as minutes and seconds - and the
## words given once it has run out, in English, for the text to say in the
## language on - beating through the last of them.
static func make(ui: Ui, remaining: Bound, then: Variant = null, style: StringName = &"Countdown") -> Desc:
	var at_last: Variant = Phrase.of(NOW) if then == null else then
	var words := ui.text(remaining.map(func(seconds: Variant) -> Variant: return at_last if seconds == null or float(seconds) <= 0.0 else Formats.written_elapsed(floorf(float(seconds)))), style)
	var running_out := remaining.map(func(seconds: Variant) -> bool: return seconds != null and float(seconds) > 0.0 and float(seconds) <= ui.motion.get_token(Motion.BEAT_FOR))
	var beating: Desc = ui.keyframes([words], BEATS, Motion.BEAT, {easing = Motion.MOVE, timed_by = Motion.TYPE, loops = Keyframes.FOREVER, held = running_out, after = 0, style = Themes.PULSE})
	return beating
