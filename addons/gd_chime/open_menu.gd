extends "controller.gd"

const Actions := preload("actions.gd")
const Relay := preload("relay.gd")

## A context menu's items and picks: the actions a menu opened over a target
## offers, what they are about, and a pick of one sent on through the door.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A CONTEXT MENU IS AN ANCHORED POP-UP OF ACTIONS (context_menu.gd). Any
## control is made a menu's target by describing it inside one
## (menu_target.gd), with a list of declared actions and what a press of
## them is about - a row's own payload, say - and a right press, the
## keyboard's menu key or a pad button on it opens the menu: OPENS, a press
## going to the app's context menu, carrying {actions, payload, region, at}
## as the pop-up's PARAMETER - which one of its kind this menu is. So what
## the menu offers is a function of that parameter (items_of), which the
## menu's pop-up is handed as a bound value, gone with the pop-up as Back
## lowers it; and a data grid hands its rows' actions over in exactly this
## way. This reads nothing of the driver.
##
## EACH ITEM IS THE PRESS IT STANDS FOR (relay.gd): the action pressed in
## the target's region, carrying the target's payload - so the item is
## refused as that press would be, its reason on it before it is picked -
## with the register's words for it. PICKS {item}, the item itself, lowers
## the menu and sends the press. OPENS with nothing to open - the menu key
## where no target has the focus - is refused; the menu's way out is every
## pop-up's (describe_places.gd: CLOSES).
##
## Deliberately absent: an item that is not an action, a separator, and a
## menu within a menu.

## The press that opens a menu over its target, {"parameter"}; a pick of an item, {"item"}.
const OPENS := &"opens_the_menu"
const PICKS := &"picks_from_the_menu"
## The one action this is told: a pick is the offered action, dispatched by the relay.
const COMMANDS: Array[StringName] = [OPENS]

var _door: Object
var _actions: Actions


## The menu's items pressed through this door, their words from this register.
func _init(chimes: Chimes, door: Object, actions: Actions) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_door = door
	_actions = actions


## The items of a menu opened as this parameter, in order: each {value -
## its place in the list, words, action, payload, region}; none for none.
func items_of(up: Variant) -> Array:
	if up == null:
		return []
	var items: Array = []
	# every action offered, as the press it stands for over the target
	for at: int in up["actions"].size():
		items.append({"value": at, "words": Phrase.of(_actions.get_words(up["actions"][at])), "action": up["actions"][at], "payload": up["payload"], "region": up["region"]})
	return items


func would(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		OPENS:
			return Phrase.of("Nothing here has a menu") if payload.get("parameter") == null else null
		PICKS:
			return Phrase.of("That is no longer there to pick") if payload["item"] == null else Relay.refusal(_door, payload["item"])
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	if action == PICKS:
		return Relay.send(_door, payload["item"])
	return null


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
