extends "keyframes.gd"

const Themes := preload("../../theme.gd")

## A pulse: what it holds fades and returns, over and over, while a bound
## value holds - the flash of attention on a control.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ONE NAMED TRACK of keyframes (keyframes.gd) and nothing else: whole,
## part faded at the half way point, whole again - which is where it rests.
## Its period, in milliseconds, and how far it fades, in hundredths, are
## the look's, under the type Pulse, so the track is worked out afresh
## every time the look changes. Given no bound value, it pulses always. It
## takes no press and needs the room its content does.


func _init(chimes: Chimes, content: Variant, style: StringName) -> void:
	super(chimes, {&"frames": [], &"easing": Motion.MOVE, &"lasts": &"period", &"timed_by": Themes.PULSE, &"loops": FOREVER, &"after": 0}, content, style)


## Whether it is pulsing now: the value holds, or there is none.
func is_pulsing() -> bool:
	return is_holding()


## The pulse's track, as the look has it now.
func get_frames() -> Array:
	var faded := 1.0 - float(get_theme_constant(&"depth", Themes.PULSE)) / 100.0
	return [{&"at": 0.0, OPACITY: 1.0}, {&"at": 0.5, OPACITY: faded}, {&"at": 1.0, OPACITY: 1.0}]


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"pulse").new(ui.chimes, desc.props["content"], desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
