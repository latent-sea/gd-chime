extends "controller.gd"

const Token := preload("token.gd")
const Notifications := preload("notifications.gd")

## What a place fills with, and every asking for it again: asked for as the
## place is entered, on its way, here - or failed, saying why, with a way to
## ask again.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## STRUCTURE EXISTS FROM STARTUP; DATA LOADS WHEN SHOWN (place.gd). So a
## place's controls stand before what they act on has arrived, and while it
## has not, THE PLACE'S ACTIONS ARE REFUSED: would() answers "Still
## loading" for any action but asking again, a refusal like any other, which
## the model answering the place's actions asks of this first - so a button
## is inert with the reason on its face and a press dispatches nothing.
##
## THE SOURCE IS HANDED IN, as fetches(answer): it answers LATER, on the main
## thread and never within the call that asked - the contract a provisional
## change's far side keeps (provisional.gd) - with answer(data, null), or
## answer(null, a phrase saying why not).
##
## IT IS THE PLACE'S on_fill: ui.screen(named, content, models, {on_fill = fetched.fill})
## hands it the token of the stay as the reader arrives (place.gd), and an
## answer under any other token - a stay the reader has left, or one begun
## again since - lands nothing, so what was asked for late never lands on a
## place the reader has moved on from; the latest asking answered after the
## reader left is no longer loading all the same, since nothing is on its
## way. Asked for within one stay it holds what it has: the reader sees the
## last data while the next is on its way.
##
## ASKING AGAIN IS THE SAME THING AS REFRESHING, so there is one of it, and
## it is the one action this answers and is told - handed to a place, alone
## or beside others, it is told nothing else the place declares:
## ASKS_AGAIN is dispatched from wherever a reader asks - a pull (pull.gd), a
## button, a key, a way to try again - it is refused "Asking already" while
## one is out, an answer to an asking no longer the latest is let go, and a
## failure loses nothing: what was shown stays shown.
##
## THREE VALUES, read wherever it is drawn (value.gd): DATA, what landed,
## nothing before the first landing; LOADING, whether an asking is out; and
## FAILURE, why the last one failed, until the next begins. Whatever reads
## one follows it, so the shapes standing in for the content give way to the
## content the moment it lands (ui.loading, loading.gd).
##
## A FAILURE IS SAID THE ONE WAY EVERY FAR-SIDE FAILURE IS SAID: a
## notification, by the words this is known by, and the mark on the thing
## itself - here the failure value, which ui.loading draws over the shapes
## with a way to ask again. Nothing else may invent a second way to say it.
##
## Deliberately absent: how far along the loading is, asking again by
## itself, and any hold on what a screen does with what landed - the data is
## a value, and whoever draws it reads it.

const ASKS_AGAIN := &"asks_again"
## The one action this is told: another asking, which a failure offers.
const COMMANDS: Array[StringName] = [ASKS_AGAIN]

## What landed, nothing before the first landing.
var data := value(null)
## Whether an asking is on its way.
var loading := value(false)
## Why the last asking failed, until the next begins; nothing where it did not.
var failure := value(null)

var _fetches: Callable  # the source: fetches(answer), answer(data, failure) called later
var _notices: Notifications
var _words: Phrase  # what this is known by, as a failure says it
var _stay: Token = null  # the token of the stay this is asking under, or none before the first
var _asked: Token = null  # the token the asking on its way waits under


## The source, where a failure is said, and the words the reader knows this
## by - all of it given here, so nothing is put in after it is built.
func _init(chimes: Chimes, fetches: Callable, notices: Notifications, words: Phrase) -> void:
	super(chimes)
	_fetches = fetches
	_notices = notices
	_words = words


## The place filling: the token of this stay taken, and the source asked.
func fill(stay: Token) -> void:
	_stay = stay
	_ask()


## Told to ask again - the one action it answers - within the same stay,
## under a token of its own, so what the asking before it brings lands on
## nothing.
func told(_action: StringName, _payload: Dictionary) -> Phrase:
	_stay = Token.new(_stay)
	_ask()
	return null


## Asking again refused while an asking is out; any other action - asked by
## the place's own model - refused while nothing has landed.
func would(action: StringName, _payload: Dictionary) -> Phrase:
	if action == ASKS_AGAIN:
		return Phrase.of("Asking already") if loading.read() else null
	return null if data.read() != null else Phrase.of("Still loading")


func answers() -> Array[StringName]:
	return COMMANDS


## The source asked under the token of the stay as it stands now.
func _ask() -> void:
	_asked = _stay
	loading.set_value(true)
	failure.set_value(null)
	_fetches.call(_answered.bind(_asked))


## The source's answer: landed, the data set out; failed, the reason kept on
## the thing, said in a notification, and what was shown left as it was. An
## answer to an asking no longer the latest is let go; one to the latest
## after the reader left lands nothing, but nothing is on its way any more.
func _answered(landed: Variant, why: Phrase, under: Token) -> void:
	if under != _asked:
		return
	loading.set_value(false)
	if not under.is_live():
		return
	failure.set_value(why)
	if why == null:
		data.set_value(landed)
		return
	_notices.notify(Phrase.with("%s could not be loaded: %s", [_words, why]))
