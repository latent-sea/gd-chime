extends RefCounted

const Themes := preload("theme.gd")

## The ink the words on a press are drawn in: the colour the state it is in
## asks the look for, and putting that colour on the words it holds.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WORDS ON A PRESS ARE THE PRESS'S, never the kind of words' own. A look
## inks a kind - Face, Reason - for the page it is usually read on; a press
## draws its own box under them, so the only ink that is right there is the
## one its state asks for, and face.gd puts it on as it refreshes.
##
## AND NEVER ON ANOTHER PRESS'S WORDS. A press stands inside a press often
## - a button on a card, a card's "more" on the card - and each draws its
## own box. Inking through one leaves the inner press's words in the
## outer's ink on the inner's own ground: a card's dark ink on a blue
## button, which is what flat and neo-brutalist drew until this
## (faint_words.gd). So the walk stops at whatever inks its own words,
## which is whatever answers for the boxes it is drawn in (get_drawn).
##
## It holds nothing and draws nothing: the face holds the colour its words
## are on their way to, and hands it here. It is face.gd's alone; nothing
## else asks a control what ink its words are in.

## A state's ink: the style's own, else a pressable's, else normal's - so a
## look that dresses a press for some states alone still inks the rest.
static func of_state(face: Control, state: StringName) -> Color:
	var named := StringName("font_color_" + state)
	if face.has_theme_color(named):
		return face.get_theme_color(named)
	if face.has_theme_color(named, Themes.PRESSABLE):
		return face.get_theme_color(named, Themes.PRESSABLE)
	return face.get_theme_color(&"font_color_normal")


## Every word this press holds, in this ink - and none of the words held by
## a press inside it, which inks its own.
static func on_words(node: Node, colour: Color) -> void:
	# every part it holds: the words in it inked, and anything that inks its own left to do it
	for child: Node in node.get_children():
		if child is Label:
			(child as Label).add_theme_color_override(&"font_color", colour)
		if not child.has_method(&"get_drawn"):
			on_words(child, colour)
