extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Feedback := preload("../../theme_feedback.gd")

## A badge: short words saying how pressing something is - a priority, a
## deadline - with a MARK beside them saying the same by its shape.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A LABEL PLUS A MARK, NEVER A HUE ALONE. The words are the meaning -
## "Urgent", "Due in 2 days" - and the level, from 0 for nothing pressing to
## 4 for the most, is drawn as the look draws it: a mark of bars before the
## words, filled as many as the level (theme_feedback.gd), so two badges are
## told apart in grey as well as in colour. Both are bound values, and the
## badge is worn again in place as the level moves - the same badge, never
## built again.
##
## What a level means is the caller's: a priority's order, how near a date
## is. Deliberately absent: a count, which is a mark with a number
## (cell_readout.gd), not a level.

## The highest level a badge draws.
const MOST := 4


## A badge of these words - a phrase, data, or a bound value reading either
## - at the level a bound value reads, 0 to MOST.
static func make(ui: Ui, words: Variant, level: Bound) -> Desc:
	var worn: Bound = level.map(func(at: Variant) -> StringName: return Feedback.BADGES[clampi(0 if at == null else int(at), 0, MOST)])
	return ui.surface(worn, [ui.text(words, Feedback.BADGE_LABEL)])
