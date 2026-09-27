extends RefCounted

const Chimes := preload("chimes.gd")
const Driver := preload("driver.gd")
const Phrase := preload("phrase.gd")

## A press picked from a list and SENT ON: what an entry of the command
## palette or of a context menu stands for, asked of the door and pressed
## through it, the pop-up it was picked in lowered first.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## An ENTRY names an action, the payload its press carries and the region
## it is pressed in - {action, payload, region} - as the control it stands
## for would press it there. So a picked entry is refused exactly as that
## control is (refusal()), its reason shown on the entry before it is ever
## picked, and it does exactly what that control does: the pop-up it was
## picked in is lowered first, and only then is the action dispatched - so
## an action that moves the reader moves them from where they were, never
## from inside a pop-up already on its way down.
##
## THE POP-UP PICKED IN IS THE ONE ON TOP - only the top takes input - so
## it is lowered by going back, and nothing here knows its name.
##
## It holds nothing: the palette's search (command_search.gd), the context
## menu (open_menu.gd) and the calendar (calendar.gd) hand it the door and an entry.


## Why the door would refuse the press this entry stands for, or nothing.
static func refusal(door: Object, entry: Dictionary) -> Phrase:
	return door.refusal(entry["region"], entry["action"], entry["payload"])


## The pop-up picked in lowered, then the entry's press dispatched; its answer.
static func send(door: Object, entry: Dictionary) -> Phrase:
	door.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	return door.dispatch(entry["region"], entry["action"], entry["payload"])
