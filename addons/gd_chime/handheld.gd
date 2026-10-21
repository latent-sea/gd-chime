extends RefCounted

## What a handheld's screen tells an easel (easel.gd) of what covers an app on
## it, read from the engine: the system's unobscured area, which names a
## cutout and a home bar; the keyboard's height; and whether a window covers
## the whole screen, so that its corners are the screen's rounded ones.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ON A DESK IT TELLS NOTHING: the engine's unobscured area there names the
## taskbar a full screen window covers, and a desk's corners are square.


## The engine's unobscured area on a handheld; none on a desk.
static func unobscured() -> Rect2i:
	return DisplayServer.get_display_safe_area() if OS.has_feature("mobile") else Rect2i()


## The engine's keyboard height where its screen has a keyboard on it; none
## where it has none, which the engine would warn of being asked.
static func keyboard() -> int:
	return DisplayServer.virtual_keyboard_get_height() if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD) else 0


## Whether `window` is a handheld's and covers its whole screen.
static func covers_screen(window: Window) -> bool:
	return OS.has_feature("mobile") and window.size == DisplayServer.screen_get_size()
