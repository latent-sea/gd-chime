extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Motion := preload("../../motion.gd")
const Keyframes := preload("../primitives/keyframes.gd")

## Attention: drawing the reader's eye to one control and saying why. The
## GLOW alone is the pressable's own, lit while the prompts name its action
## - an invitation, never a gate. A BUBBLE is the glow plus a short line
## attached to the control, pulsing, for a control never used. The WORDS IN
## THE INSTRUCTION BAR are the bar's, read from the prompts.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## One glow at a time is the prompts' rule: they name one action. A bubble
## follows the same name: it shows while the prompts name the action of the
## control it is attached to, and says that action's words, the register's
## - its OWN action's, never whichever the prompts name now, so a bubble
## fading out as the prompts move on says what it said to the end.
##
## THE GLOW'S TRACK is the pulse (pulse.gd): whole, part faded, whole
## again, over and over on the look's own period and depth. A track that
## loops rests while motion is reduced, which is why a bubble carries the
## prompts' WORDS and not the pulse alone - reduced, the words stay and
## nothing is lost.

## The idle breathe: something waiting for a reader who has not come to it,
## rising and falling where it stands on the same period as the pulse. Two
## properties on the one track - it fades a little as it grows - so it
## reads as breathing rather than as a blink. It loops, so it rests while
## motion is reduced, and what it waits for must be said in words too.
const BREATHES := [
	{&"at": 0.0, Keyframes.OPACITY: 1.0, Keyframes.SCALE: 1.0},
	{&"at": 0.5, Keyframes.OPACITY: &"breathe_opacity", Keyframes.SCALE: &"breathe_scale"},
	{&"at": 1.0, Keyframes.OPACITY: 1.0, Keyframes.SCALE: 1.0},
]


## A bubble attached to the control named so, shown while the prompts name
## this action.
static func bubble(ui: Ui, target: StringName, action: StringName, style: StringName = &"Bubble") -> Desc:
	var named: Bound = ui.bound(ui.prompts.get_glowing).map(func(glowing: StringName) -> bool: return glowing == action)
	return ui.when(named, ui.anchored(target, [ui.pulse([ui.surface(style, [ui.text(ui.words(action), Themes.REASON)])])]))


## What this holds left breathing, while a bound value holds - always,
## given none.
static func breathing(ui: Ui, content: Array, held: Bound = null) -> Desc:
	var breathes: Desc = ui.keyframes(content, BREATHES, &"period", {easing = Motion.MOVE, timed_by = Themes.PULSE, loops = Keyframes.FOREVER, held = held, after = 0, style = Themes.PULSE})
	return breathes
