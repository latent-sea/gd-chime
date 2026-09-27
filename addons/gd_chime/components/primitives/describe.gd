extends RefCounted

const Desc := preload("desc.gd")
const Options := preload("options.gd")
const Bound := preload("bound.gd")
const Actions := preload("../../actions.gd")
const Chimes := preload("../../chimes.gd")
const Driver := preload("../../driver.gd")
const Local := preload("local.gd")
const Motion := preload("../../motion.gd")
const Inputs := preload("../../input_map.gd")
const Carried := preload("../../carried.gd")
const Shape := preload("../../shape.gd")
const Touch := preload("../../touch.gd")
const Eased := preload("eased.gd")
const Layout := preload("layout.gd")
const Language := preload("../../language.gd")
const Phrase := preload("../../phrase.gd")

## The descriptions: one for every primitive, and for the places. A recipe
## calls these and returns what they answer; the builder (ui.gd), which
## extends this, turns the answer into nodes. A primitive of the game's own
## is described through the generic door, Desc.new(kind, props, children),
## its kind registered on the builder.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A STYLE MAY BE BOUND: a text's, a surface's and a pressable's style is a
## Theme name or a bound value reading one (styled.gd), worn in place as it
## moves - a look that follows a value, with no piece built again.

var actions: Actions
## What a local is made with: the bells it rings on, and the history a kept one lives with.
var chimes: Chimes
var driver: Driver
## The one clock whatever moves runs on (motion.gd), made with the builder and put under the root as it starts.
var motion: Motion
## The map of inputs a hint reads (input_map.gd), handed in by whoever composes the application.
var inputs: Inputs = null
## The one thing being carried, if any (carried.gd): made with the builder and put under the root as it starts.
var carried: Carried
## The window's shape (shape.gd) - its orientation and its size class - made with the builder and put under the root as it starts.
var shape: Shape
## The language words are read in (language.gd), made with the builder and put under the root as it starts.
var language: Language
## The one reader of a finger's gestures (touch.gd), made with the builder and put under the root as it starts.
var touch := Touch.new()


## --- content ---

## Words: a phrase, data, or a bound value reading either. Chain wraps to
## break them onto more lines at the width they are given, and hides_empty
## to take them off the screen while they say nothing (desc.gd).
func text(content: Variant, style: Variant = &"") -> Desc:
	return Desc.new(&"text", {"content": content, "style": style, "hides_empty": false, "wraps": false})


## The register's words for an action: a phrase of its English, which the
## text says in the language on as it draws.
func words(action: StringName) -> Phrase:
	return Phrase.of(actions.get_words(action))


func image(content: Variant) -> Desc:
	return Desc.new(&"image", {"content": content})


func surface(style: Variant, content: Array = []) -> Desc:
	return Desc.new(&"surface", {"style": style}, content)


## Running words wrapped as a paragraph (paragraph.gd): spans one after
## another - a phrase, data, or a bound value reading either, said as a text
## says them - and pressables among them, each laid where its words fall and
## walked by the pad in the order they are read.
func paragraph(spans: Array, style: StringName = &"Paragraph") -> Desc:
	return Desc.new(&"paragraph", {"spans": spans, "style": style}, spans.filter(func(span: Variant) -> bool: return span is Desc))


## An entity named in running words: its words - a phrase, data, or a bound
## value - and, pressed, the move its place declares for the action, the
## entity's id - or a bound value reading one - carried as the move's
## parameter, as a row carries its entry. Chain goes_to for where it goes.
## Its options: style, and words_style, the kind the words are said in.
const LINK_OPTIONS: Array[String] = [Options.STYLE, "words_style"]

func link(action: StringName, entity: Variant, words: Variant, options: Dictionary = {}) -> Desc:
	Options.checked("a link", options, LINK_OPTIONS)
	var parameter: Variant = entity.map(func(id: Variant) -> Dictionary: return {"parameter": id}) if entity is Bound else {"parameter": entity}
	return pressable(action, parameter, [text(words, options.get("words_style", &"Paragraph"))], options.get(Options.STYLE, &"Link"))


## --- behaviour ---

## A press of this action, carrying this payload - a dictionary, or a bound
## value read as the press lands. Chain goes_to for the place it moves the
## reader to, or opens for the pop-up it raises (desc.gd).
func pressable(action: StringName, payload: Variant = {}, content: Array = [], style: Variant = &"Pressable") -> Desc:
	return Desc.new(&"pressable", {"action": action, "payload": payload, "style": style, "goes_to": &""}, content)


## A press that sets a local to this value - or, given a function, to its
## answer to the value as it is now - and is selected while they agree. No
## action, no door, no glow.
func press_local(to: Local, gives: Variant, content: Array = [], style: Variant = &"Pressable") -> Desc:
	return Desc.new(&"press_local", {"local": to, "gives": gives, "style": style}, content)


## Why the pressable this sits in cannot be used, or was refused: words
## hidden while there is nothing to say.
func reason(style: StringName = &"") -> Desc:
	return Desc.new(&"reason", {"style": style})


## --- layout ---

func row(children: Array, style: StringName = &"Row") -> Desc:
	return Desc.new(&"row", {"style": style}, children)


func column(children: Array, style: StringName = &"Column") -> Desc:
	return Desc.new(&"column", {"style": style}, children)


## Columns as shares of the width, or as many as fit given none; and, given
## columns for a shape of window - {Shape.PORTRAIT: [0.5, 0.5]} - those while
## the window is that shape, the same cells re-flowing into them.
func grid(children: Array, columns: Array[float] = [], style: StringName = &"Grid", turned: Dictionary = {}) -> Desc:
	return Desc.new(&"grid", {"columns": columns, "style": style, "turned": turned}, children)


func stack(children: Array) -> Desc:
	return Desc.new(&"stack", {}, children)


## A window onto one piece, scrolled to the piece named by the bound value
## whenever that name moves.
func scroll(content: Desc, reveal: Bound = null, along: StringName = &"either_way") -> Desc:
	return Desc.new(&"scroll", {"reveal": reveal, "along": along}, [content])


## One piece per visible slot of a long list, from the template given a
## handle to the slot's row; given a cursor (list_cursor.gd), the list is
## one place to be in, its keys and presses the cursor's commands. Chain
## fits to show as many rows as its own height holds (desc.gd).
func virtual_list(list: Object, template: Callable, style: StringName = &"Column", cursor: Dictionary = {}) -> Desc:
	return Desc.new(&"virtual_list", {"list": list, "template": template, "style": style, "cursor": cursor, "fits": false})


## A line of cells at their columns' widths, on a ground (cells.gd): a
## part per column, named in order, and the columns shown - a bound value
## of [{name, share}]. Its options: samples, the words each column may
## hold, {column: {"words"}}, one dictionary shared by every line of a
## table, which keeps their measures; words_kind, the kind they are
## measured in; ground, what the line is drawn on; and edges, an edge per
## part standing after its column.
const CELLS_OPTIONS: Array[String] = ["samples", "words_kind", "ground", "edges"]

func cells(parts: Array, names: Array, columns: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a line of cells", options, CELLS_OPTIONS)
	var edges: Array = options.get("edges", [])
	return Desc.new(&"cells", {"names": names, "columns": columns, "samples": options["samples"], "words_kind": options["words_kind"], "ground": options.get("ground"), "edges": edges.size()}, parts + edges)


## --- special ---

func view(content: Array = []) -> Desc:
	return Desc.new(&"view", {}, content)


## Custom drawing: paint(control, value) called with the bound value, again
## as it changes.
func canvas(paint: Callable, content: Variant = null, style: StringName = &"") -> Desc:
	return Desc.new(&"canvas", {"paint": paint, "content": content, "style": style})


## What it holds fading and returning while the bound value holds - always,
## given none.
func pulse(content: Array, held: Bound = null, style: StringName = &"Pulse") -> Desc:
	return Desc.new(&"pulse", {"content": held, "style": style}, content)


## A track of keyframes over what it holds (keyframes.gd): the frames, each
## {at: where in the track from 0 to 1, a property: what it is there, hold:
## how long it waits there}, over this duration of the look. Its options:
## easing, the easing of the look it is gone through by; timed_by, the
## Theme type the duration is a constant of; loops, that many passes or 0
## for ever; held, a bound value it runs while; after, that many of the
## look's staggers waited before the first pass; and style.
const KEYFRAMES_OPTIONS: Array[String] = ["easing", "timed_by", "loops", "held", "after", Options.STYLE]

func keyframes(content: Array, frames: Array, lasts: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a track of keyframes", options, KEYFRAMES_OPTIONS)
	var track := {&"frames": frames, &"easing": options.get("easing", Motion.MOVE), &"lasts": lasts, &"timed_by": options.get("timed_by", Motion.TYPE), &"loops": options.get("loops", 1), &"after": options.get("after", 0)}
	return Desc.new(&"keyframes", {"track": track, "held": options.get("held"), "style": options.get(Options.STYLE, &"Keyframes")}, content)


## A canvas the reader pans, zooms and picks on: the actions, as
## {pans, zooms, picks}, are the model's that holds the view. Its options:
## hit, which answers what is under a point, and style.
const PAN_ZOOM_OPTIONS: Array[String] = ["hit", Options.STYLE]

func pan_zoom(paint: Callable, content: Variant, actions: Dictionary, options: Dictionary = {}) -> Desc:
	Options.checked("a panned canvas", options, PAN_ZOOM_OPTIONS)
	return Desc.new(&"pan_zoom", {"paint": paint, "content": content, "actions": actions, "hit": options["hit"], "style": options.get(Options.STYLE, &"")})


## A drawing with parts pinned on it (pinned.gd): paint draws in the unit
## square fitted to it, and each part stands on its point of that square -
## the keys and the pad walking the parts. Its options: points, one per
## part; picks, the action a press on the drawing itself dispatches with
## {"picked": hit(point)}, nothing where hit answers none; hit; and style.
const PINNED_OPTIONS: Array[String] = ["points", "picks", "hit", Options.STYLE]

func pinned(paint: Callable, content: Variant, parts: Array, options: Dictionary = {}) -> Desc:
	Options.checked("a pinned drawing", options, PINNED_OPTIONS)
	return Desc.new(&"pinned", {"paint": paint, "content": content, "points": options["points"], "picks": options["picks"], "hit": options["hit"], "style": options.get(Options.STYLE, &"")}, parts)


## A piece attached to the node named so, over its rect wherever it goes.
func anchored(target: StringName, content: Array) -> Desc:
	return Desc.new(&"anchored", {"target": target}, content)


## --- choosing ---

## One piece per item of a bound array, down a column, from the template
## given a handle to each item; the pieces kept by key, a function from an
## item to its identity - given none, by index, rebuilt on any change.
func each(items: Bound, template: Callable, key: Callable = Callable(), style: StringName = &"Column") -> Desc:
	return Desc.new(&"each", {"items": items, "template": template, "key": key, "style": style, "direction": Layout.COLUMN})


func each_across(items: Bound, template: Callable, key: Callable = Callable(), style: StringName = &"Row") -> Desc:
	return Desc.new(&"each", {"items": items, "template": template, "key": key, "style": style, "direction": Layout.ROW})


## The first description while the bound value holds, else the second,
## which may be nothing; the side not showing is freed. Chain keeps to
## hold it hidden instead, so what it has - a half-typed line - survives.
func when(bound: Bound, a: Desc, b: Desc = null) -> Desc:
	return Desc.new(&"when", {"bound": bound, "a": a, "b": b, "keeps": false})


