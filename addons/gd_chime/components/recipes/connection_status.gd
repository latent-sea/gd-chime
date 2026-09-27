extends RefCounted

const Themes := preload("../../theme.gd")
const Phrase := preload("../../phrase.gd")
const Connection := preload("../../connection.gd")
const Outbox := preload("../../outbox.gd")
const Provisional := preload("../../provisional.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Status := preload("status.gd")

## How the connection stands, and what waits on it: a status line for the
## whole application - online, or offline with how many changes are
## awaiting sync - and, for any one thing, whether its change is syncing,
## awaiting sync, or was not kept and why.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A STATE IS A MARK AND WORDS, never a hue alone (status.gd): connected is
## well, connecting or reconnecting mending, lost a fault. What waits is the
## outbox's (outbox.gd) - held until the connection is back - and what one
## thing says is read off the provisional changes (provisional.gd): pending
## while online is syncing, pending while offline is AWAITING SYNC, and a
## refusal on sync is said with its reason until the thing changes again.

## Each state of the connection, the status mark it is drawn with.
const MARKS := {Connection.CONNECTED: Status.WELL, Connection.CONNECTING: Status.MENDING, Connection.RECONNECTING: Status.MENDING, Connection.LOST: Status.FAULT}


## The application's line: the connection's mark, and online - or offline,
## with how many changes wait for it.
static func make(ui: Ui, connection: Connection, outbox: Outbox) -> Desc:
	var state: Bound = connection.state
	var said: Bound = Bound.both(state, ui.bound(outbox.get_held), func(now: StringName, held: int) -> Phrase:
		if now == Connection.CONNECTED:
			return Phrase.of("Online")
		return Phrase.with("Offline: %s", [Phrase.counted("%d change awaiting sync", "%d changes awaiting sync", held, "Every change is kept")]))
	return Status.make(ui, state.map(func(now: StringName) -> StringName: return MARKS[now]), said, {wraps = true})


## What one thing - the key a bound value reads, a template's handle's -
## says of its change: syncing while it is on its way, awaiting sync while
## offline, why it was not kept, or nothing.
static func of(connection: Connection, provisional: Provisional, thing: Bound) -> Bound:
	return Bound.all([Bound.new(provisional.get_pending), Bound.new(connection.get_online), thing], func(pending: Dictionary, online: bool, key: Variant) -> Variant:
		if pending.has(key):
			return Phrase.of("Syncing") if online else Phrase.of("Awaiting sync")
		var refused: Variant = provisional.get_refused().get(key)
		return "" if refused == null else Phrase.with("Not kept: %s", [refused]))
