extends "controller.gd"

## The bus the interface's sounds play on - the game's, named by the project
## - with its volume and its mute read as values, and set only by a player's
## choice told here.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE BUS IS THE GAME'S. A bus is the project's, as the locale is: this never
## adds one, and never sets a volume or a mute of its own accord - made,
## entering or leaving. It is the bus the project names under SETTING; where
## the project names none, a bus called UI where the project has one, and
## Master where it has not.
##
## ITS VOLUME AND ITS MUTE ARE VALUES (value.gd) of the bus as it stands. A
## settings slider or toggle presses one of the two commands, and the choice
## is set on the game's bus - the one truth - so the game and every app on
## that bus follow it: two apps on one bus, muted in one, say so in both.
## The engine says nothing when a bus moves, so the bus is read once a frame,
## and a value moves only where the bus stands otherwise than it says - a
## game's own slider, or another app's, reaches every screen within the frame.
##
## The volume is compared as the bus holds it, in decibels, so a volume told
## here keeps the figure it was told and is never moved by the round trip.
##
## Deliberately absent: a bus of the framework's own, and a level kept apart
## from the bus - either would be a second truth for the game to fight.

## Where a project names the bus; the one taken where it names none, if the project has one; the one every project has.
const SETTING := "gd_chime/sounds/bus"
const UI := &"UI"
const MASTER := &"Master"
## The volume a bus is set to for none at all: the engine's own floor for one.
const SILENT_DB := -80.0

## The two commands: the volume {"value": 0 to 1}, a choice's payload, and mute {"on"}.
const SETS_VOLUME := &"sets_volume"
const MUTES_SOUND := &"mutes_sound"
const COMMANDS: Array[StringName] = [SETS_VOLUME, MUTES_SOUND]

## The bus the sounds play on, by name.
var named: StringName
## How loud, 0 to 1, and whether muted: the bus's own, as it stands.
var volume: Value
var muted: Value


func _init(chimes: Chimes) -> void:
	super(chimes, [], Chimes.GLOBAL)
	named = ProjectSettings.get_setting(SETTING, UI if AudioServer.get_bus_index(UI) != -1 else MASTER)
	var at := AudioServer.get_bus_index(named)
	volume = value(_level(AudioServer.get_bus_volume_db(at)))
	muted = value(AudioServer.is_bus_mute(at))


## A player's choice, set on the game's bus: the volume, or the mute.
func told(action: StringName, payload: Dictionary) -> Phrase:
	var at := AudioServer.get_bus_index(named)
	if action == SETS_VOLUME:
		volume.set_value(clampf(payload["value"], 0.0, 1.0))
		AudioServer.set_bus_volume_db(at, _decibels(volume.read()))
	else:
		muted.set_value(payload["on"])
		AudioServer.set_bus_mute(at, muted.read())
	return null


## Once a frame, the bus read: a value moved only where the bus stands
## otherwise - set by the game, or by another app on it.
func _process(_delta: float) -> void:
	var at := AudioServer.get_bus_index(named)
	if AudioServer.is_bus_mute(at) != muted.read():
		muted.set_value(AudioServer.is_bus_mute(at))
	if not is_equal_approx(AudioServer.get_bus_volume_db(at), _decibels(volume.read())):
		volume.set_value(_level(AudioServer.get_bus_volume_db(at)))


## A volume, 0 to 1, as the bus holds it: the engine's floor for none at all.
static func _decibels(level: float) -> float:
	return SILENT_DB if level <= 0.0 else linear_to_db(level)


## What the bus holds, as a volume 0 to 1: none at all from the floor down.
static func _level(decibels: float) -> float:
	return 0.0 if decibels <= SILENT_DB else db_to_linear(decibels)
