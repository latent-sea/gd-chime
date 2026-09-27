extends RefCounted

## The sounds a look carries: a stream for each moment, the look's default
## or a style's own, kept on the Theme and found along the engine's own
## variation chain.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE SOUNDS BELONG TO THE LOOK. A Theme holds icons, fonts, boxes, colours
## and numbers and nothing else, so a stream is kept on the Theme resource as
## metadata under a name this file spells: set_sound(look, moment, stream),
## and the same with a style for that style's own. Asked under a style it
## takes the style's own, then what that style varies, then the default -
## the fall-back a box or an ink makes. It plays nothing and hears nothing:
## what plays them is sounds.gd, which reads the look from the root every
## time, so a palette brings its sounds with it.


## Where a look sets its sounds, as it is built: the default, or a style's own.
static func set_sound(look: Theme, moment: StringName, stream: AudioStream, style: StringName = &"") -> void:
	look.set_meta(_key(moment, style), stream)


## The look's sound for a moment under a style: the style's own, then what it
## varies, then the default. {"stream", "style"}, or nothing.
static func get_sound(look: Theme, moment: StringName, style: StringName) -> Dictionary:
	if look == null:
		return {}
	var named := style
	# the style, then every style it varies, and the empty name last - the default
	while not look.has_meta(_key(moment, named)):
		if named == &"":
			return {}
		named = look.get_type_variation_base(named)
	return {"stream": look.get_meta(_key(moment, named)), "style": named}


## Where a sound is kept on the Theme: the moment, under a style or not.
static func _key(moment: StringName, style: StringName) -> StringName:
	return StringName("sound_%s" % moment) if style == &"" else StringName("sound_%s_%s" % [style, moment])
