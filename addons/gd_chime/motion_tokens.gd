extends RefCounted

const Motion := preload("motion.gd")

## A look's motion written into its Theme (motion.gd reads it): the
## durations and the stagger in milliseconds, and each easing's curve, its
## ease and which duration it lasts, all under the type Motion.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A look calls write() once as it is made; the one clock reads the tokens
## back by name wherever something moves. It holds nothing and reads
## nothing: writing a look's motion is the look's, running it the clock's.
##
## Deliberately absent: a token for one node alone - a part of the screen
## under a look of its own is given a Theme of its own, written the same way.


## A look's motion written into its Theme: the durations and the stagger in
## milliseconds, and each easing as [Tween.TransitionType, Tween.EaseType, which duration].
static func write(theme: Theme, durations: Dictionary, easings: Dictionary) -> void:
	# every duration and the stagger, in milliseconds
	for named: StringName in durations:
		theme.set_constant(named, Motion.TYPE, durations[named])
	# every easing: its curve, its ease, and the index of the duration it lasts
	for easing: StringName in easings:
		theme.set_constant(StringName(easing + "_curve"), Motion.TYPE, easings[easing][0])
		theme.set_constant(StringName(easing + "_ease"), Motion.TYPE, easings[easing][1])
		theme.set_constant(StringName(easing + "_lasts"), Motion.TYPE, Motion.DURATIONS.find(easings[easing][2]))
