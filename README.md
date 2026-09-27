# gd-chime

gd-chime is a described-interface framework for Godot 4.6: an application says
what its screens hold - places, buttons, fields, lists, charts - and the floor
builds, lays out, moves and dresses them, at every window shape, in every
language it has words for. A model rings a bell that carries nothing when a fact
changes, and every piece reading that fact draws again, so a fact lives in one
place and nothing holds a copy. One look, a Theme, dresses all of it, and an
application is a node a game puts in a scene beside its own.

MIT licensed; see `addons/gd_chime/LICENCE` (and the copy at this folder's root).

## Installing

1. Copy `addons/gd_chime/` into your project's `addons/` folder.
2. Enable the plugin: Project > Project Settings > Plugins > gd-chime. It adds
   no autoload and no editor UI; enabling it is what puts the two names below
   in your project.
3. Set the three project settings the framework needs, or let it set them:
   `GdChime.apply_project_settings(get_window())`, called in your scene's own
   `_ready` before it adds an app, sets all three - an app reads them as it
   enters the tree, not when it is made, so no autoload is needed. An app
   node entering a project that lacks one says so once, in the output,
   naming the setting, the value it wants and that call.

| Setting | Value | Why |
| --- | --- | --- |
| `display/window/size/viewport_width`, `viewport_height` | 1920, 1080 | the base an app's canvas is drawn at; the floor's looks are written for it |
| `display/window/stretch/mode` | `disabled` | an app scales itself, at real pixels; a stretched window would scale it twice |
| `input/ui_accept` | holds a pad button (A) | the engine's own accept holds none, so a pad could move the focus and never press |

Two global names are yours after that: `GdChime`, everything the framework
exports, and `ChimeApp`, the node an application extends. Nothing needs a
preload, and nothing in the addon cares where in the project it sits.

## A first screen

A stall that counts crates - a place, a button with its words, a model whose
value is shown as it changes, and a refusal once the stall is full.

```gdscript
extends ChimeApp

const COUNTS := &"counts_a_crate"

## The stall's crates: how many, and that ten is all it holds.
class Crates extends GdChime.Controller:
	var counted := value(0)

	func answers() -> Array[StringName]:
		return [COUNTS]

	func would(_action: StringName, _payload: Dictionary) -> GdChime.Phrase:
		return GdChime.Phrase.of("Ten crates is all the stall holds") if counted.read() >= 10 else null

	func told(_action: StringName, _payload: Dictionary) -> GdChime.Phrase:
		counted.set_value(counted.read() + 1)
		return null

func declare(register: GdChime.Actions) -> void:
	register.declare_all({COUNTS: ["Count a crate", GdChime.Actions.keys(KEY_C)]})

func describe() -> GdChime.Desc:
	var crates := Crates.new(chimes)
	var shown := crates.counted.map(func(count: Variant) -> GdChime.Phrase: return GdChime.Phrase.with("%d crates counted", [count]))
	return ui.app(&"stall", [ui.screen(&"counting", [ui.column([ui.text(shown), ui.button(COUNTS)])], crates)])
```

Make a scene whose root is a `ChimeApp` - it is in the Create Node dialogue
once the plugin is on - anchor it across the whole window (or any rect you
like: an app in a side panel is a portrait app in a landscape window), attach
this script, and run the scene. The button carries the register's words and
its key; each press tells the model, whose value the text reads again; the
eleventh press is refused, and the button says why. Everything under the node
is the app's, and taking the node out of the tree takes all of it.

The five questions an app answers, each with a default: `look()`, the Theme
its canvas wears; `sources()`, the prompts' sources; `declare(register)`, its
actions and their words, in one table; `describe()`, the app's description,
its models made on the way; `probe()`, the walk that stands in for a reader.
A sixth, `broken(faults)`, is told when the description's tree is broken,
each fault already said in the output; by default it does nothing more.

## Beside a game

The game owns what is global; an app owns its rectangle and its drawing. An
app reads the game's settings and never writes them of its own accord - not
as it enters, builds or leaves.

- **The language is the engine's locale.** An app speaks whatever language
  the game set, `TranslationServer.set_locale("fr")`, before or after the app
  was added, and follows every change whoever makes it. A language picker in
  an app is a player's choice: it sets the engine's locale, and the game and
  every other app follow. Your own catalogues - a folder of `.po` files, one
  per language - go beside the floor's with `GdChime.Catalogues.read(folder)`.
- **Sound plays on the game's bus**: the one named in the project setting
  `gd_chime/sounds/bus`, else a bus called `UI` if the project has one, else
  `Master`. An app never adds a bus, mutes one or sets its volume by itself;
  a volume slider or a mute toggle in an app is a player's choice, set on
  that bus, and every app on it says so (`sound_bus.volume`,
  `sound_bus.muted`).
- **The settings are read as an app enters the tree**, so a scene with no
  autoload applies them first and adds its app after:

```gdscript
const Stall := preload("stall.tscn")

func _ready() -> void:
	GdChime.apply_project_settings(get_window())
	add_child(Stall.instantiate())
```

- **An app's life is the node's.** It is built as it enters the tree and
  taken down as it leaves - its models, its pop-ups, its jobs - so taking it
  out and putting it back, or moving it under another parent, builds it
  afresh, once. A description with a fault in it is reported in the output
  and the app stands empty; an app never quits your game.
- **A key the app takes is the app's.** Keys and pad buttons go to the app
  holding the window's focus; one it takes never reaches your scene's
  `_unhandled_input`, one it leaves does, as in any Godot scene, and a
  second app never hears it. A carry by the keys or the pad stays in the
  app, and in the pop-up it began in.

## The demos

Eight applications, each wearing a look of its own, and a gallery of every
piece in every look. All of them are built on the addon and nothing else, and
their story is a market stall selling crates of fruit.

| Demo | What it is | Look |
| --- | --- | --- |
| `demo/apps/dashboard` | an executive analytics dashboard: ninety days of a network's faults, in charts and cards | swiss |
| `demo/apps/pipes` | an asset register: a hundred thousand rows in the data grid, filtered, picked, assigned | data-dense |
| `demo/apps/form` | a business insurance application of eight steps, on the floor's form and shell | skeuomorphic |
| `demo/apps/kanban` | a team's board of three hundred issues in six lanes, dragged between them | neo-brutalist |
| `demo/apps/console` | a real-time operations console: five hundred devices on a wall, incidents as they open | glass |
| `demo/apps/shop` | a furniture store of a hundred pieces, pictures painted as they load, browsed and ordered | bento |
| `demo/apps/workspace` | a desktop command centre: explorer, editor, results and schema, with a palette | hud |
| `demo/apps/mobile` | a parcel carrier's day of stops, swiped and tapped, on a phone's window | material |
| `demo/gallery` | every piece the floor has, in each of the ten looks under `demo/stalls/` | all ten |

Run one from this folder, with the engine on your path:

    godot --path . --script res://demo/apps/dashboard/dashboard.gd
    godot --path . --script res://demo/gallery/gallery.gd

Add `-- --probe` and it walks itself instead of waiting for you - every place,
every press, every window shape - and prints `PROBE OK` or what it found.

## What you may rely on

What an application may use is exactly what `addons/gd_chime/gd_chime.gd` and
the two lists it extends re-export - read its docs comment, which is the index
by family - plus `ChimeApp`. Everything else in the addon is internal and may
change without a changelog entry. A name the facade exports is a promise:
removing it, renaming it or changing what it takes is a break, moves the
version and is written in `CHANGELOG.md` with what to use instead. A lint
refuses a demo or app file that path-loads a framework file the facade does
not export, and `docs/vocabulary.md` lists the kinds, the recipes and the
models by name.

`CONSTITUTION.md` is this folder's rules, and `checks/verify.py` runs every
check that keeps them true, including the installation check: a second
project under `checks/installed/` with the addon copied in and the first
screen above, built, pressed and refused, headless.
