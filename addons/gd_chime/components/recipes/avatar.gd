extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Feedback := preload("../../theme_feedback.gd")

## An avatar: a person shown by their initials on the look's ground, round.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## NEVER A HUE ALONE: a colour per person is a legend the reader must learn
## and cannot read at all without colour, so a person is their initials -
## data, the same in every language - on the ground the look gives every
## avatar alike. Nobody is the ring with nothing in it. The name is a bound
## value, read again as it moves; the initials are the first letter of its
## first two words.
##
## Deliberately absent: a picture, which is a pure addition over the ring.


## An avatar of the person a bound value names, or of nobody.
static func make(ui: Ui, person: Bound, style: StringName = Feedback.AVATAR) -> Desc:
	return ui.surface(style, [ui.text(person.map(initials), Feedback.AVATAR_INITIALS)])


## A name's initials: the first letter of each of its first two words,
## capitals - "Ana Lopez" is AL - and nothing for nobody.
static func initials(person: Variant) -> String:
	if person == null:
		return ""
	var words := (person as String).split(" ", false)
	return "".join(Array(words.slice(0, 2)).map(func(word: String) -> String: return word.left(1).to_upper()))
