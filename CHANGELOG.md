# Changelog

What changed in gd-chime that can break the code relying on it, newest first.

A public name - anything without a leading underscore - is a promise, as
CONSTITUTION.md says under *Public and internal*. Breaking one means removing
it, renaming it, or changing what it takes or does so that a caller written
against it stops working. A break moves the version, and is written here with
what to use instead.

The version has three numbers. Before 1.0 a break moves the middle one, so
0.1.0 becomes 0.2.0; from 1.0 on, a break moves the first.

This file must never become a second copy of the history. What was added or
fixed, and why, is kept by the commits; only what breaks a caller is listed
here, because that is the one thing a caller has to act on.

## 2.0.0 - 2026-09-27

The hosting round: the game owns what is global, and an app owns its
rectangle and its drawing.

- THE CHECKS BITE WHERE THEY DID NOT. `checks/looks_probe.py` fails on any
  SCRIPT ERROR in a walk, whatever the walk ends saying, and on finding no
  look to walk, where it passed "0 of 0". The commit gate is versioned beside
  the repository's term list (`../governance/pre-commit.sh`) and turned on in
  a fresh clone with `python ../governance/install_pre_commit.py`;
  `checks/vocabulary_page.py --check` now runs on every commit.
  `checks/speed_meter.py` records the folder it measured in and warns when a
  run's folder differs from its baseline's - the same code reads slower in
  some folders than others - and `--window=<windowed engine>` adds the
  easel's render cost in a real 1080p window (`checks/easel_meter.gd`).

- THE LANGUAGE IS THE GAME'S LOCALE (`language.gd`). Made, entering or
  leaving, the language model never sets the engine's locale or its
  pseudolocalization: it reads them, hears the engine say the locale moved
  whoever moved it, and rings `LANGUAGE_CHANGED` then. What breaks: an app
  no longer starts in English whatever the game set - it starts in the
  game's locale; a game or a test that wants English first sets
  `TranslationServer.set_locale("en")` itself. `Language.current()` and
  `get_language()` answer the language with words nearest the locale -
  `&"fr"` for `fr_FR`, `&"en"` for `en_GB` - where they answered the
  locale as it was. `CHANGES_LANGUAGE` is still the player's choice, and
  still sets the engine's locale.
- `Language.read(folder)` is gone: reading a folder of catalogues is
  `Catalogues.read(folder)` (`catalogues.gd`, `GdChime.Catalogues`), a
  static call, since reading words off disk is no language's.
- THE SOUND IS THE GAME'S BUS (`sound_bus.gd`, `GdChime.SoundBus`, an app's
  `sound_bus`). Nothing adds a bus, mutes one or sets its volume of its own
  accord: the sounds play on the bus the project names in the setting
  `gd_chime/sounds/bus`, else on a bus called UI where the project has one,
  else on Master - a project that relied on the floor making a UI bus hears
  its sounds on Master. The bus's volume and mute are the values
  `sound_bus.volume` and `sound_bus.muted`, read off the bus once a frame, so
  the game moving its own bus is followed. What breaks: `Sounds.BUS` is gone;
  `Sounds.SETS_VOLUME`, `Sounds.MUTES_SOUND` and `Sounds.COMMANDS` are
  `SoundBus.SETS_VOLUME`, `SoundBus.MUTES_SOUND` and `SoundBus.COMMANDS`,
  answered by the app's `sound_bus`; `sounds.get_volume()` and
  `sounds.get_muted()` are `sound_bus.volume` and `sound_bus.muted` - values,
  handed to a slider or a toggle as they are, `.read()` for the figure; and
  `Sounds.new(chimes, driver, prompts, under)` takes the bus it plays on,
  `Sounds.new(chimes, driver, prompts, under, sound_bus)`. Sounds are told
  nothing now.
- THE BASE IS READ AS AN APP ENTERS THE TREE (`easel.gd`), not as it is
  made, so `GdChime.apply_project_settings(get_window())` in a host's own
  `_ready`, before it adds the app, is the base the app draws at. What
  breaks: `get_base()` on an app never yet in the tree answers `(0, 0)`. A
  rect of no width or no height fits nothing and leaves the canvas as it
  was, where it wrote a canvas of no size out of a scale of nothing.
- AN APP'S LIFE IS THE NODE'S (`chime_app.gd`). It is built as it enters the
  tree - in `_notification`, so an application's own `_enter_tree` no longer
  replaces the build - and leaving the tree takes down everything it built:
  the job pool's tasks waited out (`jobs.stop()`) and everything under its
  canvas freed, models, places, pop-ups and bells. Coming back, or moved
  under another parent, it is built afresh, once, where it was built a
  second time over the first. What breaks: a game that held an app's
  models, its `ui` or its door across the app leaving the tree holds freed
  nodes - `ui` and `chimes` are null until it enters again - and an app
  moved under another parent starts again from its description.
- NOTHING QUITS THE GAME. A description whose tree is broken is said out
  loud and the app stands empty, nothing arrived at; `ui.start(desc)` given
  no `on_broken` no longer quits. The app is told `broken(faults)`, a sixth
  question with a default that does nothing; `application.gd`, the demos'
  and probes' main loop, answers it by quitting, as a probe of a broken tree
  should.
- KEYS AND CARRYING STAY INSIDE THE APP (`easel.gd`, `carry_walk.gd`). A key
  or a pad button goes on to an app only while a control of that app holds
  the window's one focus - or, while nothing in the window holds it, while a
  control of that app held it last: one the app takes never reaches the game, one it
  leaves goes on to the game, and another app never hears it. The easel
  takes no focus itself, so a click on an app's bare ground leaves the focus
  where it was. What breaks: an app whose shortcuts answered keys while
  the game's own control held the focus, or another app's, no longer hears
  them; give a control of the app the focus. A
  keyboard or pad carry walks the drop targets of its own layer - the app,
  or the pop-up it began in - and never another app's.

The hosting round. To gd-chime the game is models: a fact follows its value,
whoever set it.

- A MOMENT FOLLOWS ITS VALUE. A pop-up presented while a fact holds is raised
  and lowered in the driver's own step of the frame after the fact moved,
  where a control draws, whoever moved it - a press, the game's tick, a job
  landing - and a fact that held and let go again within one frame raises
  nothing. `Driver.settle()` is gone, and the door no longer calls its
  mover's settling at the end of a dispatch: a mover given to `Commands`
  answers no `settle()`. What breaks: a test or probe that read a moment
  raised or lowered straight after the dispatch that moved its fact reads
  it a frame later, after awaiting the frame.
- A PLACE TELLS EACH MODEL ONLY WHAT IT ANSWERS. A place handed ONE model no
  longer registers it for every action the place declares that nothing else
  answers: a model is told exactly what its `answers()` lists, however many
  a place is handed, and a press that only moves the reader - an opener, a
  way back - reaches the mover and no model. A model that relied on being
  its place's only one lists every action it is told in `answers()`. The
  startup check now reports, as `nothing answers <action> in <place>`, an
  action going nowhere that no model answers in its place or from anywhere,
  and the application does not start. `OpenMenu.COMMANDS` holds the pick as
  well as the opening, and `CommandSearch` answers its three.
- A FREED MODEL ANSWERS NOTHING. The door lets go of a model freed, or
  waiting at the end of the frame to be freed, as it looks for a handler:
  `handles()` says no, a press is refused as nothing handling it, and
  registering a model at its address replaces it without a word.
- `Fetched` is told only to ask again, and an answer to its latest asking
  landing after the reader left clears `loading` (the data still lands on
  nothing).
- A refused optimistic change doubts its thing when ANY later change of the
  same thing was sent after it - answered already or not - and reads it back.
- A model's value set off the main thread is refused out loud and does not
  move, as a read off it already was: set it where the job's answer lands.
  `Reads.is_main_thread()` is new.
- The controller's header no longer says a model does not wait for a frame:
  what a model follows reaches it as the bell rings, at the end of the frame;
  a reading that must be current the instant is worked out as it is read.

The hosting round. Nothing grows over a session.

- FOLLOWING AGAIN RUNS THE WORK HANDED LAST. A follow keeps its work and
  what a ring runs instead with its key, and every wire of the key arrives
  through one arrival that looks them up: `follow()` again under the same
  key with new work runs the new work, where it kept the first. A caller
  that relied on the first work surviving a second follow must keep it.
- An address a work read where no bell hangs yet is kept with the rest,
  so drawing again reading the same wires nothing again, and a bell hung
  there later reaches the reader on its first ring. `Chimes.followed_by()`
  lists only the addresses a bell hangs at.
- A model with a region of its own (`Controller.own_region`) takes the
  region down as it is freed: whatever listened into it hears nothing more.
- THE BUILDER'S NAMES LET GO OF FREED PIECES (`built_names.gd`, which
  `ui.gd` now extends): `ui.node_named()` of a freed piece answers nothing
  rather than the freed instance, a keyed list lets go of a piece's name as
  its key goes (`ui.forget_named()`), and every freed piece's name is swept
  as the names held double. A caller that read a name after freeing its
  piece gets null.
- A keyed list takes down a key's bell as the key goes. `Chimes.drop_bell()`
  takes one bell down with its wires; `Reads.forget_bell()` forgets what
  moved there.
- Who is wired at a bell is read from the bell's own connections, and
  listeners are kept by region, so taking a region down costs the wires it
  cuts. Anything reading the private `chimes._wires` finds `_follows`
  (a `Wires.Follow` record per followed key, its addresses in `.at`),
  `_members` and `_waiting` beside `_held`; `Wires.make()` takes the
  address where it took the bell. A draw costs about 4% more than before
  this round's part 6 - each draw reads its follow's record, and each ring
  goes through the record's one arrival - accepted as the price of a
  follow keeping the work handed last.
- THE LOOK'S HELPERS TAKE NAMED OPTIONS, as its boxes do: no more than four
  positional parameters and no bare boolean, an option they do not know said
  out loud. `Look.font(families, weight, italic)` is `Look.font(families,
  {weight = 700, italic = true})`; `Look.pressable(theme, type, boxes, inks,
  focus, base)` is `Look.pressable(theme, type, boxes, {inks = inks, focus =
  focus, base = base})`, inks and focus required; `Look.words(theme, kind,
  size, font, colour)` is `Look.words(theme, kind, size, {font = font, colour
  = colour})`; `Look.line(theme, type, base, gap, justify, align)` is
  `Look.line(theme, type, base, {gap = 8, justify = Look.END, align =
  Look.CENTER})`, no gap when not said; `Look.marked(theme, type, mark, thick,
  side)` is `Look.marked(theme, type, mark, {thick = 6.0, side =
  SIDE_LEFT})`; `Look.field(theme, type, normal, focus, ink)` is
  `Look.field(theme, type, {normal = box, focus = box}, ink)`;
  `Paint.dashed(ink, width, dash, gap, inset, radius)` is `Paint.dashed(ink,
  width, {dash = 8.0, gap = 6.0, inset = 0.0, radius = 0.0})`; and
  `Paint.hatch(ink, spacing, width, diagonal)` is `Paint.hatch(ink, {spacing
  = 4.0, width = 1.0, diagonal = true})`.
- THE PROMPTS' FACTS ARE VALUES (`prompts.gd`): the current prompt and the
  mutings are read as values and heard at the frame's end, one timing with
  every other fact. `Prompts.PROMPT_MOVED` and `Prompts.MUTE_CHANGED` are
  gone: read `get_glowing()`, `get_source()`, `get_words()` or
  `is_muted(source)` where you draw or in a `follow()`, and what you read is
  followed. An action control no longer listens to the prompts; it follows
  what its draw read of them.
- A LONG LIST'S FACTS ARE VALUES (`long_list.gd`, and `feed.gd` and
  `growing_list.gd` over it): the look - the first row and how many show -
  and the pages held, each on a bell of its own, heard at the frame's end.
  `LongList.LOOK_MOVED`, `PAGE_LANDED`, `PAGE_FAILED` and
  `FAILURES_FORGOTTEN` are gone: read `get_first()` and `get_showing()` for
  the look, `count()`, `has()`, `get_item()` and `has_failed()` for the
  pages, where you draw or in a `follow()`. A page landing, a page failing
  and failures forgotten all move the pages; forgetting them on a reset or a
  drop does not, until the pages asked for land. A virtual list follows what
  it reads of its list rather than listening to it; a feed no longer gathers
  its rings through a throttle, since values ring once a frame by themselves.
- THE LANGUAGE ON IS A VALUE (`language.gd`), heard at the frame's end with
  every other fact, at an address by name (`Language.ON`) the same in every
  app's chimes. `Language.LANGUAGE_CHANGED` and `Language.HEARD` are gone: a
  text follows the language because saying a phrase reads it, and listens to
  no bell; what draws its own words reads `Language.on()` or
  `language.get_language()` where it draws, as before. Words that are data,
  never looked up, no longer draw again as the language moves.
- NOTHING IS KEPT ON AN ENGINE OBJECT. The words said to be missing, which
  app held a window's focus last, and the settings already reported are the
  floor's own state, where they were metadata on the TranslationServer, the
  window and the input map. `Language.MISSING` is gone: nothing outside the
  floor reads that memory.
- `Confirm.for_leaving(ui, proceeds, style)` takes its style as an option,
  as `Confirm.make` does: `Confirm.for_leaving(ui, proceeds, {style =
  &"Mine"})`.

The hosting round. A pop-up wears the look it is described in.

- A POP-UP DESCRIBED INSIDE `ui.themed(look, ...)` WEARS THAT LOOK and sizes
  by it, as does one lifted from a place standing inside a themed piece; one
  described outside wears the app's, as before. What breaks: A POP-UP'S
  CONTENT FUNCTION RUNS AS THE POP-UP IS LIFTED, not as `ui.pop_up()` is
  called - a caller that read something its content made straight after
  describing it (as `QuickView` pointed its steps at the pop-up) reads it
  in the content instead, where `ui.current_place()` is the pop-up's own
  place and reads the look it wears; a share of the window a content reads
  from `ui.root` is the app's, not the pop-up's. `ui.lift(overlay)` is
  `ui.lift(overlay, look)`, the look it wears or null for the root's.

## 1.0.0 - 2026-09-20

The first public shape: gd-chime is an addon a project installs, rather than
a project a game is built inside.

- THE FLOOR LIVES UNDER `addons/gd_chime/`. Every floor script, `components/`,
  `words/` and the facade's four files moved there; `demo/`, `tests/`,
  `checks/`, `CONSTITUTION.md`, `CHANGELOG.md` and `README.md` stayed beside
  it and do not ship. So every path into the framework moved: what was
  preloaded at `chimes.gd` under the project root is preloaded at
  `addons/gd_chime/chimes.gd`, and the facade, which was `gd_chime.gd`, is
  `addons/gd_chime/gd_chime.gd`. An application that names the facade needs
  no path at all - see the next entry.
- NOTHING INSIDE THE ADDON SAYS WHERE IT WAS INSTALLED. Every path in it is
  relative to the file saying it - `preload("../chimes.gd")` - the facade's
  lazy lists name a script from the addon's root and join it to where the
  addon sits, and the one path built from a string, the floor's catalogues,
  is resolved from `language.gd`'s own `resource_path`.
  `Language.FLOOR_CATALOGUES` is therefore the folder's name, `"words"`, and
  no longer a whole path: what it used to hand `Language.read()` is now
  `language.gd`'s own folder joined to it. The boundary lint fails on any
  absolute path inside the addon, so a project may install it anywhere - or
  vendor it under a folder of its own.
- THE APPLICATION IS A NODE, `ChimeApp` (`chime_app.gd`), on its own easel
  (`easel.gd`): added anywhere in a scene it builds the whole application
  under itself, the look on its canvas, and takes it away when it leaves. It
  answers the five questions as `application.gd` did - `look()`, `sources()`,
  `declare()`, `describe()`, `probe()` - and `application.gd` is now the
  main loop standing in for one, so a script extending it reads `chimes`,
  `ui` and the rest as before. What breaks: `ui.root` is the app's canvas, a
  Control, and no longer the window - anything that wrote
  `(ui.root as Window).theme` reads `ui.root.get_theme_constant(...)`
  instead; the window's clear colour is never set - the canvas paints the
  look's ground; `Notifications.new(chimes, commands, under)` takes any Node
  where it took a Window; and `SimulatedSight.over(canvas)` and
  `simulate(sight, canvas)` take the canvas the overlay goes on.
- THE WINDOW BELONGS TO THE HOST. Nothing in the framework writes the
  window's stretch mode or base size, its clear colour or the input map at
  run time; the app scales itself on its easel at real pixels, the base
  turning with the app's own rect, and `Shape` reads that rect rather than
  the window and swaps no base. A project that hosts the app across the
  whole window sets `display/window/stretch/mode` to `disabled` - a
  stretched window would scale the app twice - and `application.gd` calls
  `GdChime.apply_project_settings(window)`, the one way the framework sets
  what it needs (`needed_settings.gd`); an app node only reports what is
  missing, once, in words.
- ONE GLOBAL NAME, AND ONE BESIDE IT. `gd_chime.gd` carries
  `class_name GdChime`, so an application needs no preload: `GdChime.Ui`,
  `GdChime.Card`, `GdChime.Themes`; its docs comment is the index of every
  name by family. `chime_app.gd` carries `class_name ChimeApp`, since a
  class cannot extend a name it reads through the facade. `Actions` and
  `Controller` are constants of the facade now rather than lazy names, as an
  app names both in a signature. A name resolves as a global only after the
  editor's scan: a project run bare with `--script` and never imported reads
  the facade by its path, as this folder's own tests do.
- THE PROMISE IS THE FACADE. What an application may use is exactly what
  the three facade files re-export, plus `ChimeApp`; everything else in the
  addon is internal and may change without an entry here, however public
  its names look. The convention lint refuses a demo or app file that
  path-loads a framework file past the facade.
- A HIDDEN CONTROL WAITS TO DRAW UNTIL IT IS SHOWN (`presentation.gd`). What
  a control read moving is still a draw due, and it stays wired to it, but
  while it cannot be seen - hidden by what holds it, or under something
  hidden - the draw waits, and runs once as it is shown, inside the showing,
  so the room it needs is asked again before anything is laid out around it.
  What breaks: a test, a probe or a model that read a hidden control's DRAWN
  state - the words on a closed indicator, the look a lowered overlay's
  option wears - reads what it drew when last seen. Read the model instead
  (the bound value, the Local handed to the description), or read the
  control where a reader meets it, shown. A control whose own draw shows and
  hides it overrides `shows_itself()` to answer true and never waits - a
  text hidden while empty, a pressable absent while refused and a when
  already do; a control of your own that sets its own `visible` in
  `refresh()` must, or it hides once and is never drawn again - and one
  that does not is reported out loud, by its path, as its draw hides it.
- The extraction check, which proved the folder ran alone, is gone; the
  installation check (`checks/installation_test.py`, `checks/installed/`)
  proves the addon installs into another project, and `checks/verify.py`
  runs ten checks. `README.md` and `docs/vocabulary.md` are new.

## 0.31.0 - 2026-09-20

Round 3. Contrast is a property the suite asserts.

- `Hands.say_every(cut, over)` is no longer static: it says the faint words
  these hands gathered as well, so it is called on the hands
  (`_hands.say_every(...)`, which every probe already did). A caller that
  said `Hands.say_every(...)` must hold the hands it judged with.
- Every probe that judges a window claims `words_stand_out`
  (faint_words.gd): words against the ground they stand on, 4.5 to 1, and
  3 to 1 for words of 24 base pixels and up. A look below the line fails
  its probe. A piece dressed by the floor now carries the ink that goes
  with the ground the floor set (table heading, context-menu item, palette
  entry): a look that set an ink for those by its own pressable no longer
  reaches them.
- The ink a press's words are drawn in is face_ink.gd's, moved out of
  face.gd whole: `of_state(face, state)` and `on_words(node, colour)`. A
  press no longer inks the words of a press inside it - each draws its own
  box, and each inks its own words for the state it is in - so a button on
  a card keeps the button's ink. A look that relied on a card's ink
  reaching the button on it must dress that button.
- A link's words are the look's accent taken deep enough to read on the
  page, not the accent itself, in flat, neumorphic and neo-brutalist; the
  floor's rule - a link is the accent - is unchanged, and a look whose
  accent already reads sets nothing.
- `Drawer.ROOM` is gone and a bottom sheet is no longer named areas: it is
  a by_shape of `shape.whose_window`, which reads PHONE while the window
  is compact and on its end and DESKTOP otherwise. A look that dressed
  `DrawerFoot` as a grid must dress it as a row.
- A line chart names a series' marker only where two or more series share
  the chart.
- `Pieces.graph()` takes the kind of words its "who is picked" line is
  written in, the readout's unless another is asked for.

Round 3. An address is one name, and what a work read is a set.

- `Reads.end()` hands back a DICTIONARY used as a set - the one name of every
  address read, in the order first read - where it handed back an Array of
  `[region, name]` pairs. A caller reading it takes `.keys()`, or asks `.has()`.
- `Reads.hung(region, name)` is the one name an address is known by, made as
  the bell is hung and kept. `Reads.note_at(address)` notes a read through
  that name, which is what a value's own bell now uses; `Reads.note(region,
  name)` stands for a reader with no address of its own.
- `Reads.tracked(work)` runs the work with its reads noted and hands back the
  set; `apart(work)` is that with the answer dropped. `begin()`/`end()` stand.
- What `Reads.worked` keeps per address is `[address, moves]`, where it was
  `[region, name, moves]`. `Reads.forget(region)` drops those names too.
- A bell carries where it hangs: `region`, `name`, `at`. `Bell.new()` takes
  the three, and `Belfry.bell_at(address)` finds one by that name or nothing.
- The chimes keep their wires in `wires.gd` - by listener, then by the key
  they were made under, then by address - and a wire is the arrival alone.
  A draw that reads what it read last time is left alone: nothing cut, nothing
  made. Anything reading the private `chimes._wires` must read
  `chimes._wires._held`. `Chimes.LISTENED` is the key a plain listen is kept
  under.

Round 3. The one import stops compiling the framework at start.

- `gd_chime.gd` holds 44 of its 163 names as constants; the other 119 are
  static vars on the two lists it extends (`gd_chime_recipes.gd`,
  `gd_chime_floor.gd`, over `gd_chime_on_first_use.gd`), fetched the first
  time the name is read. `GdChime.Card`, `GdChime.Themes.FACE` and
  `GdChime.Shell.make(...)` are unchanged. What breaks: one of those 119 can
  no longer be used as a TYPE, in an `extends`, or inside a `const` value,
  and a call through one is checked when it runs rather than when it is
  parsed, so `var x := GdChime.Panes.split(...)` no longer infers - write
  the type, `var x: GdChime.Desc = ...`. A name needed as a constant moves
  back to gd_chime.gd, one line in each file.
- `checks/words_template.py --check` now fails, as well, on a phrase its
  template holds that the code no longer says. Write the templates again,
  after finding out whether the phrase went or the scanner stopped seeing it.

## 0.30.0 - 2026-09-19

Round 3. A model's facts that move at different moments ring apart.

- `Controller.value(initial)` takes an optional second argument, a bell of
  the model's own that the value rings instead of the model's one bell.
  Nothing that calls it today has to change, and nobody lists a bell still:
  a reader reads a value and follows whichever bell it hangs on. A model
  whose facts move at different moments and are read by different readers
  declares the bell as a member and passes it - `queried_rows.gd`: the view
  and the answer ring `_answered`, apart from the sort, the grouping and
  whether a query is out, so asking a query no longer wakes the long list
  holding the answer (539 draws while a query was out, back to 19).

Round 2. What a tracked reading holds, and which thread may read.

- `Reads.worked(held, work)` now lets a memoised reading go by itself. It
  counts, per address, how often what that bell rings for has moved
  (`Reads.moved`, called by `chimes.strike` and by `own_bell.moved` as a
  value is set, ahead of the ring that bell defers to the end of the frame)
  and keeps that count with each address the work read. A writer that
  emptied the held array by hand must stop: delete the clearing, and do not
  read the array's shape, which now holds `[region, name, moves]` per
  address. `Answers._replace(held, to)` is gone with it - set the value.
  `Reads.forget(region)` drops what a dropped region counted.
- `Reads.note` is the main thread only, and says so. A read of anything
  bound from a background job now says which address was read and is noted
  for nobody, where before it was noted silently for whatever the main
  thread was working out. A job reads plain data, never a value.

Round 2. Named options instead of long positional signatures.

- No public description or recipe takes more than four positional
  parameters. What is left over goes one of two ways, and which one is not
  a choice made afresh (`components/primitives/options.gd`): an option that
  CHANGES HOW THE THING IS BUILT is a named option in a last `options`
  dictionary, and one that only MARKS A DESCRIPTION ALREADY MADE is a
  chained name on `desc.gd`. `Options.checked(what, given, known)` says an
  unknown key out loud, naming what took it and the keys it does take; a
  `const *_OPTIONS` list sits beside every function that takes one. The
  names more than one description takes - `style`, `goes_to`, `payload`,
  `id_key`, `places`, `opens`, `with`, `runs`, `folds`, `says_empty` - are
  explained in `options.gd` and nowhere else.
- Every boolean parameter of the vocabulary is a chained name:
  `ui.text(words, style).wraps().hides_empty()`, `ui.when(a, b, c).keeps()`,
  `ui.virtual_list(list, template, style, cursor).fits()`,
  `ui.field(action, style, options).takes_focus()`,
  `ui.area(action, shows, style).takes_focus()`,
  `ui.pop_up(kind, content, model).blocks_nothing()`,
  `ui.local(initial).kept()`. `ui.pressable`'s fifth parameter is
  `Desc.goes_to(place)` too.
- These take named options now, so a call written against the old order
  must be rewritten: `ui.link`, `ui.cells`, `ui.keyframes`, `ui.pan_zoom`,
  `ui.pinned`, `ui.slider`, `ui.range_slider`, `ui.swipe`, `ui.grip`,
  `ui.split(first, second, share, options)`, `ui.screen`, and the recipes
  `KpiCard.make`, `BarChart.make`, `Matrix.make`, `Card.list`/`tile`/`dense`,
  `Combo.short`/`long`, `Setting.toggle`/`choice`/`binding`,
  `Collection.make`, `Table.make`/`heading`, `Sections.make`/`static_groups`,
  `TypeAhead.make`, `Chip.make`, `FormSteps.make`, `Lanes.make`,
  `LiveFeed.row`, `NavControl.inline`, `Stepper.make`, `SwipeRow.make`,
  `Board.make`, `Gallery.make`, `LoadedOrEmpty.over`, `Shell.make`,
  `Wall.tile`, `Panes.split(ui, first, second, options)`,
  `AmountField.make`, `Bracket.make`, `Confirm.make`, `Drawer.over`,
  `FacetList.one`/`range_of`, `QuickView.make`, `Sheet.tall`,
  `MeasureCharts.trend`/`band`, `RegionMap.make`, `Status.make`,
  `TextField.make`, `TextArea.make`.
- `Setting.row`, `Collection.outcomes`, `NavControl.play`,
  `CellReadout.relative`, `DateField.make`, `InlineChoice.radios`/`segments`,
  `Moment.make`, `Progress.make`, `RelationshipGraph.make` lose their
  trailing `style`: each wore one style only, now named inside.
  `InlineChoice`'s `options` parameter is `offers`.
- `ui.build_template(template, handle, parent, in_place)`: its `facts`
  parameter is gone, having been given nothing by anyone.
- `BarChart.longest(all, figures)` and `BarChart.shares(one, longest,
  figures)` take `BarChart.NOW` or `BarChart.NOW_AND_BEFORE` where they took
  a boolean. `FormReview.review(ui, form)` is two functions: `review`, whose
  headings and answers are pressed, and `record`, the read-back of what was
  sent, which presses nothing.
- `ui.button(action, options)` is THE common button: its words, its reason
  and its style come from the action and the look, and its options are
  `opens`, `with`, `goes_to`, `payload`, `content` and `style`. A press
  wanting content of its own is a `pressable`. `bell_button.gd` was the same
  thing by another name and is GONE - `BellButton.make(ui, action, payload,
  goes_to, content, style)` is `ui.button(action, {payload = ..., goes_to =
  ..., content = ..., style = ...})`. `BellButton` survives only as the
  look's name for the style.
- A by_shape arrangement is never written as a dictionary. `ui.row_of(order,
  facts, style)` and `ui.column_of(order, facts, style)` are the only two
  things that make one, and a part named in no facts takes its own length
  rather than needing an empty entry. `ui.by_shape` and `ui.by_width` move
  from `describe.gd` to `components/primitives/describe_shapes.gd`; the
  builder reaches both as before.
- `TextField.make(ui, action, label, options)` and `TextArea.make(ui,
  changes, sends, options)` take the bound value they show as the option
  `holds` (and the area its `label`), and lose their own option checkers for
  the one in `options.gd`; so does `Question.make`.

Round 2. Standing an app up.

- What every application had a copy of is an `Application` default, and an
  application overrides one only where it needs to:
  - `application.budget`, a `FrameBudget` measured against the display's own
    refresh rate (`FRAME_SHARE`, `FRAME_RUN`, `FRAME_RATE`);
  - `application.jobs`, one `Jobs` pool reading that budget (`JOBS_AT_ONCE`
    is 3, `JOBS_WAITING` 64 - the shop's old pool, big enough for every app);
  - the clear colour, set once from the look's ground: an application's
    `look()` no longer calls `RenderingServer.set_default_clear_color`, and
    one that does sets it twice;
  - `settings_path(own, probed)`, the file `--settings=` names, else the
    application's own, else - probing - the probe's, removed first;
  - `probe()`, answering the walk that stands in for a reader. It is made and
    begun by `Application` once `ui.start` has built everything, not inside
    `describe()`, so a probe sees the whole interface. An application's own
    `--probe` const and its `if OS.get_cmdline_user_args().has(PROBE)` go.
  `Application` now holds the names `FRAME_SHARE`, `FRAME_RUN`,
  `FRAME_RATE`, `JOBS_AT_ONCE`, `JOBS_WAITING`, `SETTINGS_SWITCH`,
  `PROBE_SWITCH`, `budget`, `jobs`, `probe`, `settings_path` and `_probe`:
  an application that declares one of those itself must rename it.

- `Form.new(chimes, door, questions, steps, sent_to, notices)` takes the
  notifications in its constructor; `Form.notices` is gone. `Application`
  makes its notifications before it asks the application to declare, so a
  model made in `declare()` can be given them.
- `Panels.fold(pane)` folds or unfolds one and `Panels.bring_into_view(pane)`
  brings one into view, said in words instead of `panels.told(ACTION, {})`.
- `ui.fetched(source)` is what a place fills with (`fetched.gd`): hand it to
  the place among the models that answer there, and `fetched.fill` to the
  place as what it does on filling. Its `.data`, `.loading` and `.failure`
  are values read wherever they are drawn, it refuses a place's actions
  "Still loading" until the data is in, and `Fetched.ASKS_AGAIN` asks again
  under a token of its own. `ui.loading(fetched, content, rows)` draws
  loading's mark over so many shapes until it lands.
- `landing.gd` is gone. `Landing.new(chimes, region)`, `begin(token)`,
  `land(token)` and `get_landed()` are `ui.fetched(source)`, the place's
  `fill`, the source's own `answer(data, failure)`, and `.data`.
- `Loading.mark`, `.shapes` and `.until` take the builder untyped, since the
  builder's own vocabulary names them.
- A model says what it answers and is stood up where it was handed in:
  `Controller.answers()` returns every action it is told, and
  `Commands.stand(region, model)` registers it for those and nothing else.
  `Application.model(made)` puts a model beside the app and stands it up in
  the global region; `ui.screen(named, content, models)`, `ui.tabs` and
  `ui.pop_up` take ONE model or an ARRAY of them and stand each up in THAT
  PLACE'S region - the region follows the place, and an application never
  writes one. `ui.app(named, content, models)` takes them too. A place given
  one model still gives it every action the place declares that nothing
  answers yet; given several, each answers exactly what it says.
- So a model takes no door and no region: `QueriedRows.new(chimes, rows,
  jobs)`, `RowEdits.new(chimes, rows, checks)`, `LongList.new(chimes, fetch,
  page, keep, showing, rows)`, `TableColumns.new(chimes, columns, least)`,
  `RowSelection.new(chimes, view, columns)`, `EditingCell.new(chimes, view,
  picks, columns, edits)`, `RowFilters.new(chimes, view, properties,
  motion)`, `ViewBehind.new(chimes, view, edits)`, `Facets.new(chimes, view,
  jobs, facets, ranged, searched, words)`, `Orders.new(chimes, view,
  named)`, `GrowingList.new(chimes, fetch, page, rows)`, `Feed.new(chimes,
  capacity, showing)`, `ImageLoads.new(chimes, jobs, make, at_once, keep)`,
  `Narrowing.new(chimes, source, limit, types)`, `QueryPacing.new(chimes,
  view, motion)`, `Measures.new(chimes, rows, filter, jobs, spec, times)`,
  `Drills.new(chimes, measures, models, words, split)`,
  `DashboardFilter.new(chimes, region_column, time_column, now, starts)`,
  `Stream.new(chimes, source, sinks, capacity, most)`,
  `KeyedItems.new(chimes, items, key, tallied)`, `RollingSeries.new(chimes,
  series, bucket, points, x_words, y_words)`, `Refresh.new(chimes, fetches,
  lands)`, `Outbox.new(chimes, connection, sends)`, `Connection.new(chimes)`,
  `Provisional.new(chimes, sends, notices, reads, settles)` and
  `TableModels.new(ui, rows, spec, checks, jobs, showing, row_actions)`.
- `TableModels.all()` is every model of a table, for the place it is
  described in to stand up; `TableModels.region` is gone, and so is setting
  `row_actions` after it is built. `LongList` and `ImageLoads` hang their
  bells in a region of their OWN (`Controller.own_region`), so two of either
  never collide: whatever listens reads `list.region`, and whatever
  dispatches uses its own place's region, not the list's. A virtual list's
  cursor loses its `"region"` key for the same reason.
- Nothing is injected after construction: `Provisional.reads` and
  `.settles`, `Workbench.documents`, `.notices` and `.table`,
  `KanbanBoard.panels` and `TableModels.row_actions` are all constructor
  arguments now. `Workbench.new(chimes, notifications, results)` makes its
  own `Documents`. `Form.answers(key)` is `Form.answering(key)` (and
  `FormActions.answering`), since `answers()` is now every model's.
- `ui.also(node)` leaves a node that is already in the tree where it is, so
  a model held by another model - a route's refresh - can be stood up
  without being reparented.
- One action table, and no other way to declare:
  `actions.declare_all({OPENS: ["Open the ledger", keys(KEY_L), pad(JOY_BUTTON_Y)]})`
  - the words first, then the inputs the action is on to begin with.
  `Actions.declare(action, words, inputs)` is gone, and so are the three
  shapes an application wrote its table in: `{action: ["words", [[key,
  modifiers], pad]]}` with the lambda that unpacked it, a `WORDS` map beside
  an `INPUTS` map, and a `declare` call an action at a time.
- An input is made by the register: `Actions.keys(code, modifiers)` and
  `Actions.pad(button)`. `InputMap.key()`, `InputMap.chord()` and
  `InputMap.pad()` are gone - `keys(KEY_K, KEY_MASK_CTRL)` is the chord.
- `DataGrid.INPUTS` is gone; `DataGrid.table(of)` answers the register's
  table for the actions asked for, which `DataGrid.declare`,
  `DataGrid.declare_table` and `DrillDown.declare` hand over whole.

Round 2. Values track what they read.

- A model declares its values: `var count := value(0)` (`Controller.value`).
  A value is its own bound value (`value.gd`): hand it to a primitive as it
  is, `read()` it, `set_value(to)` it. Setting rings the model's one bell
  (`own_bell.gd`) once, at the end of the frame, however many values were
  set in it - so what hears a model hears it a frame on, never inside the
  set - and a set rings even to what the value holds; the bell carries
  nothing. A value holding an array or a dictionary changed in place is set
  again to ring. One bell a model: whatever reads one of its values is woken
  by any of them moving (`Taken.set_taken` rings with the rest).
- A bound value lists nothing: `Bound.new(read, bells, answerer)` is
  `Bound.new(read, answerer)`, and `Bound.bells()` is gone. Whatever reads a
  bound value follows exactly what it read (`reads.gd`, `Chimes.follow`): a
  control follows what its draw read, its refusal among it.
  `Bound.on_bell(read, region, bell)` is a handle moving on one bell alone.
- Gone: `Controller.reads_move_on()`, `Controller.refusal_moves_on()`,
  `Controller.bound(&"name")` and the `get_name` convention behind it,
  `Commands.listening_for()`, `Shape.bound()`. Instead of
  `model.bound(&"count")`: the value itself (`model.count`), or, for a
  reading worked out, `ui.bound(model.get_count)`. `local.bound()` is the
  local itself, and `Local.get_value()` is `read()`.
- A control's refusal kept from a press (`ActionControl.get_refusal()`)
  stands until what the refusal reads moves - followed apart from the
  draw, under `ActionControl.REFUSAL` - or a bell it listens to rings; its
  own draw moving no longer clears it. A subclass keeps a refusal with
  `_keep_refusal(answer)`, never by setting `_refusal`.
  `Chimes.unfollow(listener, key)` stops a follow.
- Rings come a frame's end on, so what reads a model's state after a set
  reads it at once, but what FOLLOWS it - a view behind its rows, a
  reminder, a settings file, an outbox - moves as the frame ends.
  `RowEdits.get_written()` is every row written in the frame of the last
  write, not the last write's alone.
- `ui.bound(work)` is a value worked out by a function, on whatever it
  read; `ui.every_frame(work)` is one read again every frame (`frames.gd`).
  The clock demo's `Ticker` is gone.
- A controller that works something out from bound values calls
  `follow(key, work)`: the work runs now and again whenever what it read
  moves. `Reads.apart(work)` does what a follower does without following
  it. `Reads.worked(held, work)` keeps a reading worked out once, with
  what it read.
- The bells a value replaced are gone: `Shape.TURNED`/`RECLASSED` (the
  values `Shape.orientation`, `Shape.size_class`), `Motion.REDUCED_MOVED`,
  `InputMap.REBOUND`/`DEVICE_SWITCHED`, `Connection.MOVED` (the value
  `Connection.state`), `Outbox.MOVED`, `Refresh.MOVED`, `Provisional.MOVED`,
  `Landing.LANDING_MOVED`, `Carried.LIFTED`/`PUT_DOWN`/`MOVED_OVER`,
  `DebugLog.ENTRY_LOGGED`, `Documents.DOCUMENTS_MOVED`, `Panels.PANELS_MOVED`,
  `Taken.ACTION_FIRST_TAKEN`, `Guide.STEP_MOVED`, `Answers.ANSWERED`/`CHECKED`,
  `Form.DRAFT_SAVED`/`SENT`, `Narrowing.NARROWED`, `QueriedRows.VIEW_MOVED`/
  `QUERY_MOVED`, `RowSelection.CURSOR_MOVED`/`PICKS_MOVED`,
  `RowEdits.ROWS_WRITTEN`, `TableColumns.COLUMNS_MOVED`, `ViewBehind.MOVED`,
  `EditingCell.EDITING_MOVED`, `RowFilters.MOVED`, `QueryPacing.WAITING_MOVED`,
  `Facets.MOVED`/`COUNTED`, `Measures.MEASURED`, `DashboardFilter.MOVED`,
  `Drills.SHOWN`, `Orders.MOVED`, `Notifications.STANDING_MOVED`,
  `Feed.FOLLOW_MOVED`/`CURSOR_MOVED`, `KeyedItems.MOVED` and
  `KeyedItems.bell_of()` (an item is a value of its own: `item(key)`),
  `Lane.SHOWN_MOVED`, `RollingSeries.MOVED`, `Stream.PAUSE_TURNED`/
  `CONNECTION_MOVED`/`MOVED`, `Sounds.SOUND_CHANGED`. The events stay:
  `Driver.NAVIGATED` (read through `Whereabouts.where()`, which notes it),
  `Commands.COMMAND_RAN`, `Prompts.PROMPT_MOVED`/`MUTE_CHANGED`,
  `Language.LANGUAGE_CHANGED`, the long list's four, `Notifications.ARRIVED`.
- What took a list of bells takes nothing, or a bound value to follow:
  `SettingsFile.keep(section, model)` follows what `saved()` reads;
  `LongList.new(..., rows: Bound, region)` and `GrowingList.new(..., rows,
  region)` reset as `rows` moves; `Guide.new` and `Reminders.new` lose
  `also`; `Confirm.for_rows` loses `also`.

Round 2. Overlays travel with their descriptions.

- A pop-up is described where it is used, and the builder lifts it beside
  the app by itself (`ui.lift`, `place_builder.gd`): among what it stands
  over, on the press opening it, as the question a screen asks. Gone:
  `Application.beside()` and `ui.start`'s second parameter -
  `ui.start(app, on_broken)`. A pop-up described inside a template is
  refused out loud: describe it once and open it with the item.
- `ui.pop_up(kind, content, handled_by, blocks)`: no name - the builder
  names it `"<kind> <n>"`, so two of one kind never collide (`Desc.get_place()`
  reads it) - and its content is a function of the parameter it is entered
  as, a bound value. Instead of `ui.driver.get_parameter(NAME)` in a bound
  value, read the parameter handed in.
- `ui.button(action, {opens = overlay, with = which})` opens a pop-up as one
  of its kind: `with` is a value or a bound value. Its options are only
  these two for now and an unknown one is said out loud. `Desc.opens(overlay)`
  makes any press open one. `Confirm.opener` is gone.
- Every recipe answers one `Desc`: `Setting.choice`, `Combo.short`,
  `Combo.long` the control (their overlay travels on it, and they lose their
  `overlay` name); `Confirm.make(ui, consequence, action, carries, style)` and
  `Confirm.for_leaving(ui, proceeds, style)` the question (`for_rows` is
  `make` with a consequence that is a function of the parameter, and the
  cancel is gone); `DataGrid.grid` the grid; `FormField.make(ui, form, key,
  calendar)` the question; `FormSteps.make(ui, form, named, review, asks,
  closes_to, calendar)` the form's screen; `DrillDown.make(ui, drills,
  models, style)` its pop-up; `Drawer.over(ui, title, content, foot, from)`
  its pop-up, `title` a phrase or a function of the parameter and `content`
  a function of it; `QuickView.make(ui, content, back, on, neighbours)` its
  pop-up, `content` a function of the item (`QuickView.item_of` is gone);
  `CommandPalette.make(ui, search)`, `CalendarSheet.make(ui, calendar)`,
  `ContextMenu.make(ui, menu)` their pop-ups.
- Every pop-up owns its way out: `ui.CLOSES` (`closes_the_overlay`, "Close",
  Escape and the pad's B), declared by the builder and by every pop-up's
  place going back; `Sheet.close(ui)` is its button. Gone:
  `OpenMenu.CLOSES`, `CommandSearch.CLOSES`, `Calendar.CLOSES`,
  `DataGrid.CLOSES`, `Drawer.over`'s `closes`, and every application's own.
  Of several actions on one input, a shortcut presses the one a place on the
  top path declares: `InputMap.get_action(input)` is
  `get_actions(input)`, every action on it.
- One overlay contract (`sheet.gd`): the shade every sheet stands on is a
  press of the way out (`Sheet.shade(ui)`, style `Shade`, drawn in every
  state); the drawer stands on it, and `DrawerShade` is gone; a long combo
  is `Sheet.tall`. A moment is a pop-up PRESENTED while its fact holds,
  raised and lowered through the chart by `Driver.settle()`, which the door
  calls at the end of every dispatch (a mover given to `Commands` answers
  `settle()`); it is no longer a `when`. The context menu stands on the
  choice's sheet (`Setting.SHEET`): the `Menu` style is gone.
- Models work from the parameter, never the driver: `OpenMenu.new(chimes,
  door, actions)`, its items `items_of(parameter)` (`get_items`, `get_at`
  and `PLACE` gone), a pick `{"item"}`; `Calendar.new(chimes, door)` notes
  the field as OPENS is told, a pick carries `{"value", "for"}`, and
  `Calendar.PLACE` is gone; `CommandSearch.new(chimes, door, driver,
  actions, sources, limit)`; `Relay.send(door, entry)` lowers the pop-up on
  top. `menu_target` loses `menu`: every target opens the application's one
  context menu, `ui.context_menu`, which `ContextMenu.make` says - a
  description the builder lets go once the tree stands, so read its place
  from `ui.menu_place` after that. A screen's `asks_before_leaving` is the
  question's `Desc`. `FormActions.choosing` is gone.

Round 2. One way for each common thing.

- `Throttle.new(deed, options)` takes named options in place of its `paced`
  boolean and its `token`: `Throttle.new(deed, {paced_by =
  Throttle.CADENCE})` for what was `Throttle.new(deed, true)`, and
  `Throttle.new(deed, {paced_by = PACE})` for `Throttle.new(deed, true,
  PACE)`. A deed given neither option is still done at the frame's end.
- A throttle SETTLES as well as paces: `Throttle.new(deed, {settles_by =
  token, on = motion})` does the deed once the asking has RESTED for that
  token of the look, on the one clock, each ask putting it further off, and
  `throttle.forget()` drops what waits without doing it. That is the
  framework's one debounce: `query_pacing.gd` holds one instead of a
  `Motion.Run` of its own, and nothing else may count keystrokes or keep a
  timer.
- `refresh.gd` is GONE. A refresh and a first fetch were the same asking, so
  there is one model for both: `Refresh.new(chimes, fetches, lands)` is
  `ui.fetched(source, notices, words)`, `Refresh.REFRESHES` is
  `Fetched.ASKS_AGAIN`, `refresh.get_refreshing()` is `fetched.loading`,
  `refresh.get_failure()` is `fetched.failure`, and what `lands(data)` took
  is `fetched.data`, a value whoever draws it reads. `test_refresh.gd` is
  gone with it.
- `Fetched.ASKS_AGAIN` is `&"asks_again"`, not `&"asks_for_it_again"`: a
  constant's name and its value say the same thing.
- `ui.fetched(source)` is `ui.fetched(source, notices, words)`, and
  `Fetched.new(chimes, fetches)` is `Fetched.new(chimes, fetches, notices,
  words)`: a far-side failure is said ONE way, and both halves of it are
  given here - a notification, "<words> could not be loaded: <why>", and
  the mark on the thing, which `ui.loading` draws.
- `ui.loading(fetched, content, rows)` draws that failure itself - the
  fault's mark, the reason, and a press of `ASKS_AGAIN` - over whatever was
  already shown. `Loading.of(ui, fetched, content, standing_in)` is the
  whole of it and `Loading.failure(ui, why)` the line alone;
  `Loading.until(ui, landed, content, standing_in)` is unchanged, for a
  bare bound value. No screen may write a line of its own for a failed
  fetch.
- `PullToRefresh.make(ui, refresh, content)` is `PullToRefresh.make(ui,
  fetched, content)` and says nothing of a failure: wrap the content in
  `ui.loading`, which says it.
- `Status.mark` and `Status.make` take the builder untyped, as `Loading`
  does: loading says the one failure, and a preload of the builder in
  `status.gd` would be a cycle.
- `Card.loading(ui, lines, options)` is the one loading look a card wears -
  its own ground over loading's pulsing shapes, with `above` for whatever
  stands where its picture will and `style` for the ground. A stack of
  grounds built at the call site, and the string `"..."` standing in for a
  row not yet landed, are both gone from the demos; a slot with nothing in
  it yet is `Loading.shapes(ui, 1)`.
- ONE FILTER MODEL, `filters.gd`, over packed rows AND ordinary items, from
  a spec declared once: `Filters.new(chimes, {search = [&"title",
  &"person"], one_of = &"person", any_of = &"labels", between = {column,
  bounds, words}}, {over = rows, on = jobs, asks = view.ask})`. It is read
  two ways - `get_clauses()` for a query over packed rows, and
  `keeps(item)`, through `get_keeps()`, for ordinary items - and one file,
  `filter_query.gd`, says what the spec means, so the two cannot drift.
  Over packed rows `search` names ONE column, since clauses are ANDed.
- Its actions are `Filters.SEARCHES {line}`, `PICKS {column, value}`,
  `TOGGLES {column, value}`, `SETS_RANGE {value}`, `TURNS {id}`, `REMOVES
  {id}` and `CLEARS`. `CLEARS` is refused "No filters are on" while there
  is nothing to take.
- `facets.gd` is now a VIEW over the filters and nothing else: the counts,
  worked out off the frame. `Facets.new(chimes, view, jobs, facets, ranged,
  searched, range_words)` is gone - a filters given `over` and `on` makes
  one itself, reachable as `filters.facets`. `Facets.TOGGLES {facet,
  value}` is `Filters.TOGGLES {column, value}`, `Facets.SEARCHES`,
  `SETS_RANGE`, `TURNS`, `REMOVES` and `CLEARS` are the filters', and
  `facets.get_facets()` is `filters.get_values(column)`,
  `facets.get_count()` is `filters.get_count()`, and `get_chips`,
  `get_line`, `get_range`, `get_bounds` are the filters' too. A stretch's
  words take the `Vector2` rather than two floats.
- `FacetList.make`/`one`/`range_of`/`chips` take a `Filters`, and `one`'s
  third parameter is a column.
- `TypeAhead.make` and `Combo.long` take a `payload` option: what every
  option's press carries beside its `value`, for a picker over one of
  several columns.
- The kanban's hand-rolled `kanban_filters.gd` is GONE:
  `KanbanFilters.SEARCHES` is `Filters.SEARCHES`, `PICKS_PERSON` is
  `Filters.PICKS {column = &"person"}`, `TOGGLES_LABEL` is
  `Filters.TOGGLES {column = &"labels"}`, `CLEARS_FILTERS` is
  `Filters.CLEARS`, `filters.shows` is `filters.keeps`, and
  `filters.people` is the app's own `Narrowing`, which answers its typing
  itself.
- AN ACTION CONSTANT'S NAME AND ITS VALUE SAY THE SAME THING, VERB FIRST.
  Twenty-nine constants are renamed; their values are unchanged, so a saved
  key binding still finds its action. In the floor: `Calendar.EARLIER` and
  `LATER` are `SHOWS_MONTH_BEFORE` and `SHOWS_MONTH_AFTER`; `Drills.DRILLS`
  is `SHOWS_ROWS_BEHIND`; `EditingCell.RESIZES_HERE` is
  `RESIZES_THIS_COLUMN`; `Feed.CLEARS` is `LETS_GO`;
  `FormActions.DISCARDS` is `LEAVES_WITHOUT_SAVING`;
  `RowFilters.TYPES_PROPERTY` and `TYPES_VALUE` are `NARROWS_PROPERTIES`
  and `NARROWS_VALUES`, and `RowFilters.TYPES_LINE`'s value is
  `&"types_the_line"` (the one value that moves); `RowSelection.ACROSS` is
  `MOVES_ACROSS` and `PICKS_ALL` is `PICKS_EVERY_ROW_KEPT`. In the demos:
  the kanban's `FOLDS_DETAIL` is `FOLDS_CARD`, `ADVANCES` and `RETREATS`
  are `MOVES_ON` and `MOVES_BACK`; the mobile app's `ACTS` is
  `SHOWS_DELIVERY_ACTIONS`; pipes' `INSPECTS` is `MARKS_INSPECTED` and
  `OPENS_ASSIGNING` is `OPENS_PROGRAMMES`; the shop's `OPENS_ORDER`,
  `OPENS_QUICK`, `STEPS_BACK` and `STEPS_ON` are `CHOOSES_ORDER`,
  `LOOKS_CLOSER`, `SHOWS_ONE_BEFORE` and `SHOWS_ONE_AFTER`.

Round 2. The dashboard chain.

- DATES ARE A COLUMN OF THE ONE FILTER MODEL, and the stretches are passed
  in as data: `Filters.new(chimes, {one_of = &"region", dates = {column =
  &"reported", now = <hours>, presets = [{value, words, days}, ...], starts
  = &"week"}})`. A preset with no `days` is the stretch SET BY HAND, its
  first and last day the reader's. `stretch.gd` holds it and answers for
  it - `Stretch.PICKS {value}`, `SETS_FIRST_DAY` and `SETS_LAST_DAY
  {value: a day, or null}`, refused "That is not a date", "That day has not
  come yet" and "The first day is after the last" - and the filters' own
  `filters.stretch` reads `get_stretches()`, `get_presets()`,
  `get_picked()`, `get_by_hand()`, `get_first_day()`, `get_last_day()` and
  `get_today()`. A stretch set by hand starts on today, both ends.
- A COLUMN PICKED ON A DRAWING is declared `on_a_drawing = &"region"` and
  answers `Filters.picks_of(column)` - `&"picks_a_region"` - taking the
  `{picked}` a map's region and a chart's bar carry (`pinned.gd`). It
  toggles the value, so the one picked pressed again is let go, and in a
  `one_of` column `TOGGLES` now REPLACES whatever was picked rather than
  piling up beside it.
- `Filters.get_rollup()` is what a rollup is taken over: `{clauses,
  stretches}` - the clauses WITHOUT the dates, and the stretch with the one
  before it - because every measure takes its own column of time within it
  (`rollup.gd`).
- `dashboard_filter.gd` is GONE, and so is `test_dashboard_filter.gd`.
  `DashboardFilter.new(chimes, region_column, time_column, now, starts)` is
  a `Filters` with a `one_of` column and a `dates` column;
  `PICKS_REGION {picked}` is `Filters.picks_of(&"region")`, `PICKS_RANGE`
  (whose value was already `&"picks_a_stretch"`) is `Stretch.PICKS`,
  `SETS_FROM` and `SETS_TO` are `Stretch.SETS_FIRST_DAY` and
  `SETS_LAST_DAY`, `TOGGLES` and `REMOVES` are `Filters.TURNS` and
  `Filters.REMOVES`; `get_region()` and `get_picked()` are
  `filters.get_chosen(column)`, `region_clauses()` and `stretch_clauses()`
  are the filters' own clauses, and `get_ranges`, `get_range`,
  `get_first_day`, `get_last_day`, `get_today` and `get_stretches` are
  `filters.stretch`'s. `COMPARES`, `get_comparing()`, `get_before_words()`
  and `get_before_within()` have no floor home: whether a dashboard sets
  each figure beside the stretch before is the interface's own state, and
  what that stretch is called is the words of whoever named the presets.
  The dashboard demo holds both (`demo/apps/dashboard/dashboard_view.gd`:
  a `ui.local`, `stretches()`, `before_words()`, `before_within()`).
- `Measures.new(chimes, rows, filter, jobs, spec, times)` takes a BOUND
  VALUE where it took a filter: `Measures.new(chimes, rows,
  ui.bound(filters.get_rollup), jobs, spec, times)`, reading `{clauses,
  stretches}`. It knows no filter now, and a test can hand it those by
  hand.
- `MeasureCharts.trend(ui, measures, filter, figure, options)` is
  `MeasureCharts.trend(ui, measures, figure, options)` with `comparing` and
  `before_words` among its options, as `KpiCard.make` and `BarChart.make`
  already take them.
- `DateRange.make(ui, filter, custom, style)` is `DateRange.make(ui,
  stretch, by_hand, style)` - `filters.stretch` - and draws the presets and
  the days set by hand alone. The comparison's toggle is NOT a date range's:
  it belongs to whoever compares, which in the dashboard is a local pressed
  in the shell's bar.
- `Filters.get_count()` answers nothing where no rows were given to count,
  so a filters with no facets may wear chips.
- `Filters.get_columns()` is gone: `FilterQuery.columns(spec)`.
  `Filters.RANGE_CHIP` and `SEARCH_CHIP` are `FilterQuery`'s, which now
  says what the chips are as well as what the spec means -
  `FilterQuery.chips(spec, set_by)` - and `FilterQuery.beneath` narrows by
  the dates, with `FilterQuery.apart_from_dates` for what leaves them out.
  A column's values and their counts are joined in the view that counts
  them, `Facets.get_values(column, picked)`, which
  `filters.get_values(column)` reads.

Round 2. Themes.

- The floor's look is organised BY COMPONENT FAMILY, never by the
  application that drove it. `theme.gd` holds the floor's own vocabulary -
  the palette, the types every style varies (`Pressable`, `Row`, `Column`,
  `Grid`, `Tiles`, `Surface`, `Pulse`), the kinds of words - and each family
  is a file of its own. A style name moves with the family that dresses it,
  so a caller naming one through the old module renames its import.
- `theme_pressables.gd` is buttons and pressables: the pressable's own
  boxes in every state, `Themes.BUTTON` (now `Pressables.BUTTON`),
  `Themes.TOGGLE_ON`/`TOGGLE_OFF`/`CHOICE`/`CHOICE_CHOSEN` (now
  `Pressables.`), `Themes.BAR` (now `Pressables.PROMPT_BAR`), and the
  inline options `theme_values.gd` used to hold - `Values.RADIO`,
  `RADIO_CHOSEN`, `SEGMENTS`, `SEGMENT`, `SEGMENT_CHOSEN`, `MARK` and `PAD`
  are `Pressables.`'s.
- `demo/gallery/looks/inline_options.gd` is GONE. Its work - the four
  inline option looks from the look's own pressable, and the overlap
  spacing that keeps no segment's box off its neighbour - is the floor's:
  `Look.toggle(theme, mark, thick)` dresses the toggle, the choice AND the
  inline options, and `Pressables.stand_apart(theme)` is the spacing helper.
  A look that called both now calls `Look.toggle` alone.
- `Look.marked(theme, type, mark, thick)` takes the side the bar runs along
  as a fifth parameter, `SIDE_BOTTOM` as before.
- `theme_fields.gd` is fields: everything a reader types into or sets a
  value with, and a form of many steps. `theme_values.gd` and
  `theme_forms.gd` are GONE - `Values.SLIDER`, `STEPPER`, `COMBO` and
  `TALL` and every one of `theme_forms.gd`'s names are `Fields.`'s, and so
  are `Themes.FIELD`, `Themes.TEXT_AREA` and `theme_shell.gd`'s `CODE` and
  `FIXED_WIDTH`.
- `theme_tables.gd` is tables: `theme_grid.gd` under the name of what it
  dresses, with `Themes.TABLE_CELL` and the lines a table, a data grid and
  a matrix stand in. Every `Grid.` of the old module is `Tables.`'s.
- `theme_navigation.gd` is navigation: `Themes.TAB`, `TAB_STRIP`,
  `TAB_PANEL`, `TAB_SET` and `SECTION_HEADING`; `theme_marks.gd`'s `LINK`;
  the phone's `NAV_BAR`, `NAV_RAIL`, `NAV_ITEM`, `NAV_FRAME` and `SCREEN`,
  which were `theme_mobile.gd`'s; and the shell's `GRIP`, `PANE`,
  `PANE_COLUMN`, `DOCUMENT_FLAP` and `STATUS`, which were
  `theme_shell.gd`'s. It takes in a section, the sections' column, an
  inline way out, a step and the shell's foot, which had no floor entry.
- `theme_overlays.gd` is overlays: the shade, the sheet, the line what is
  asked stands in, a drawer, a quick view, a moment, a drill, a context
  menu's items and the command palette. `theme_shell.gd` is GONE - its
  `MENU_ITEM`, `PALETTE` and `PALETTE_ENTRY` are `Overlays.`'s - and
  `theme_browsing.gd` keeps only what a collection is browsed with.
  `Moment` and `Asked` now have floor entries: a moment stands on the sheet
  and what is asked is centred both ways, as every look already had it.
- `theme_collections.gd` is collections: `theme_browsing.gd`'s cards,
  gallery and facets under the name of what they are, with the board's
  lanes and cards (`Board.LANES`, `LANE`, `LANE_COLUMN`, `LANE_HEADING`,
  `CARD`, `CARD_COLUMN`, `CARD_LINE`, `CARD_TITLE`, `CARD_META` are
  `Collections.`'s, the card's five under `BOARD_CARD*`), the wall
  (`Live.WALL`, `WALL_TILE`) and the swiped row (`Mobile.SWIPE_ROW`,
  `SWIPE_REVEAL`). `theme_browsing.gd` is GONE.
- `theme_charts.gd` takes in every line a chart draws: `Themes.DRAWN` is
  `Charts.DRAWN`, and `Themes.BRACKET_ROUND` is `Charts.BRACKET_ROUND`,
  beside the bracket, its ties and a relationship graph's panel, which had
  no floor entry at all. `Themes.KEYFRAMES` is the floor's own.
- `theme_feedback.gd` is feedback, and `theme_arrivals.gd`,
  `theme_live.gd`, `theme_board.gd` and `theme_mobile.gd` are GONE: every
  `Arrivals.`, `Live.`, `Board.` and `Mobile.` name is `Feedback.`'s.
  `Countdown` and `Bubble` have floor entries now, where they had none.
- The design tokens an application draws its own content on are the
  FLOOR's, not the demos': `DemoTheme.RAISED`, `CARD`, `TITLE`, `NUMBER`
  and `CENTRED` are `Themes.RAISED`, `Themes.CARD`, `Themes.TITLE`,
  `Themes.NUMBER` and `Themes.CENTRED`, and a component may name a title or
  a number, which `checks/convention_lint.py` used to forbid.
  `demo_theme.gd` keeps `READOUT`, `LINE`, `SHADE`, `PANEL`, `TIGHT` and
  `CONFIRM`; its `ASKED` is gone, the floor centring that line itself.
- Two additions, in `components/primitives/describe_escapes.gd`:
  `ui.themed(look, content)` draws a subtree in a Theme of its own, and
  `ui.embed(control)` places a Control the framework did not build inline
  among described parts, taking its facts as any part does - the escape
  hatch the vocabulary lacked. `ui.also` is unchanged and stays
  full-window. `describe_shapes.gd` extends `describe_escapes.gd`; the
  builder reaches all of it as before.
- `theme_marks.gd` is GONE. `Marks.PARAGRAPH`, `Marks.DIVIDER`,
  `DIVIDER_ACROSS` and `DIVIDER_DOWN` are `Themes.`'s, the floor's own;
  `Marks.CHIP` is `Fields.CHIP` and `Marks.LINK` is `Navigation.LINK`.
- An addition: `Bound.constant(value)` is the bound value that never moves,
  where a lambda reading a settled thing was written by hand -
  `Bound.new(func() -> Array: return [...])`.
- An addition: `ui.parameter(place)` is what a place is entered as, as a
  bound value. `Bound.new(func() -> Variant: return driver.get_parameter(X))`
  written by hand is that, and no description reaches the driver for it.
- An addition: `ui.shape.portrait` is whether the window is on its end, as
  a bound value. `shape.orientation.map(func(way): return way ==
  Shape.PORTRAIT)` is that, and four app files no longer preload
  `shape.gd` at all.
- An addition: `Stepper.steps(ui, action, options)` is the minus and the
  plus on their own, around whatever `shows` stands between them, each press
  carrying what `carries(how far this press moves)` answers. `Stepper.make`
  is that with the number's field between; the basket line's and the
  dashboard day's hand-written `ui.pressable(action, ..., [ui.text("−")])`
  pairs are gone, and the dashboard's day steps wear `Fields.STEPPER`, which
  they wore no style at all before.
- An addition: `Formats.written_elapsed(seconds, parts, places)` writes a
  stretch of time as a clock face - `Formats.MINUTES` or `Formats.HOURS`
  parts, the first plain and the rest to two digits. The countdown and the
  console's log both wrote their own. The console's log column reads
  `0:12:04.3` where it read `00:12:04.3`.
- `Phrase.within(words)` LOWERS THE FIRST LETTER of what it says, where it
  was the same as `Phrase.of` and only a marking for the template's check.
  So its English is written in sentence case now, the same key a phrase
  shown on its own uses: `Phrase.within("Recovering")` says `recovering`.
  A caller passing lowercase English - a line of a sentence broken over
  several - is unaffected. The doubled tables this was for are gone:
  `Operations.STATUS_WORDS_WITHIN` and `MobileRoute.STATUS_WORDS_WITHIN`
  are `STATUS_WORDS` through `Phrase.within`.
- A face's look state is PUBLIC: `_state()` is `get_state()`, on `face.gd`
  and on everything extending it - `pressable.gd`, `press_local.gd`,
  `draggable.gd`, `drop_target.gd`, `slider.gd`, `key_capture.gd`. A look
  overriding it renames its own; a test or a probe asserting how a control
  is drawn reads it without reaching for an underscore.
- A face's drawn boxes are public too: `_drawn()` is `get_drawn()`, for the
  same reason.
- An addition: `slider_track.gd`'s `point_at(value)` is where a value
  stands in the canvas, so a hand aiming a drag at a value has somewhere to
  aim.
- `tests/hands.gd` is THE test driver: one pair of hands for every test and
  every probe - `press(action)`, `click`, `drag`, `key`, `pad`, `types`,
  `words`, `texts`, `saying`, `shows_words`, `shown`, `place`, `focused`,
  `judged`, `say_every`, and a finger - `touch`, `tap`, `drawn`,
  `draws_on`. The five each demo grew for itself are GONE:
  `demo/gallery/reader.gd`, `demo/apps/form/hands.gd`,
  `kanban_hands.gd`, `mobile_hands.gd` and `pipes_hands.gd`. No probe
  touches `Applier.shows`, `driver.index` or an underscore member of the
  framework any more.
- The gallery's models are its stall's public members: `_things`,
  `_filters`, `_act`, `_item`, `_family`, `_drafts`, `_prefs`, `_ledger`,
  `_knockout`, `_takings`, `_kept`, and the gallery's `_shelf`, `_keys`,
  `_baskets`, `_order`, `_labels`, `_draft`, `_stock`, `_sales`, are
  `things`, `filters`, ... - a member another file reads is not private.
- `checks/convention_lint.py` exempts a probe from the 250-line cap, as it
  exempts a test: `demo/**/probe.gd` and `demo/**/*_probe.gd`. The splits
  that existed only to fit one are gone: `pipes_timing.gd` and
  `pipes_hands.gd` are `pipes_probe.gd` again.
- `menu_target.gd` answers `payload()`, what a press of its menu's actions
  is about, as a pressable does.
- ONE IMPORT: `gd_chime.gd` re-exports the whole public API under the names
  the demos already used - `const GdChime := preload("res://addons/gd_chime/gd_chime.gd")`,
  and then `GdChime.Ui`, `GdChime.Bound`, `GdChime.Card`,
  `GdChime.Themes.FACE`. Every one of the eight applications is on it: 42
  app files held 349 framework preloads between them and now hold 46 - one
  each, and `tests/hands.gd` beside it in the nine probes; three files that
  preloaded nothing of the framework still preload nothing. Nothing inside
  gd-chime preloads the facade - a file of the floor names what it uses -
  and a name in it is a promise like any other.

## 0.29.0 - 2026-09-17

Routing asks the places and the state, never the buttons; the door answers
whether a press would be refused; GO is the one kind of move.

- A place declares what it performs: `Place.performs` maps an action to
  where it goes (a place name, `Driver.BACK`, or nothing), set as the place
  is built. A button draws one of its place's actions and reads where it
  goes from the place: `ActionControl.goes_to` is gone, `get_goes_to()`
  reads the declaration, and a button drawing an action its place does not
  declare is reported out loud as it enters. `Index.performs()` gathers
  every declaration; the index holds places only - `is_control`, `is_link`,
  `place_of`, `controls_of`, `links_in`, `controls`, `is_reachable` and the
  bell `Index.CONTROL_CHANGED` are gone.
- A handler implements `would(action, payload) -> Phrase` beside `told`:
  one refusal, never reading navigation; `Controller` refuses nothing by
  default. `Commands.refusal(region, action, payload)` is the handler's
  `would` then the mover's refusal of the move (`mover.would_move(goes_to,
  state)`); `Commands.game_refusal` is the handler's alone; `dispatch`
  checks the refusal before `told` and moves after. The usable Callable is
  gone from `ActionControl.new(chimes, commands, region, listening)` and
  `BellButton.new(chimes, commands, face, region, listening)`; `is_usable()`
  is that refusal being null, `get_reason()` is it, and `is_pressable()`
  is gone.
- One move: `Events.Kind.GO` with `Events.Event.go(place)`. The chart
  decides: the app path, a pop-up not up raised onto that place, a move
  within the layer on top, or the panel. ARRIVE and RAISE are gone with
  their refusals; a GO into a pop-up up but not on top is refused "is not
  on top". The driver's commands are `go` (`{"place": name}`), `go_back`,
  `lower`, `forget_the_way_back`.
- `Queries.reachable(chart, performs, state, action, would)` and
  `Queries.route(chart, performs, state, action, would, back)` are pure
  searches over the declarations, `would(place, action)` the game's
  refusal; `Driver.is_reachable(action)` and `Driver.route(action)` ask
  them through the door. `Queries.event_of` and `Queries.path_to` are gone;
  `Paths.path_to(chart, place)` reads the chart's `parent` map.
- The guide and the reminders re-point on `COMMAND_RAN` and `NAVIGATED`
  and on the bells handed to them as `also`; a game fact changing outside
  a command rings its own model's bell.
- A press carries the game's data alone: `ActionControl.payload()` is `{}`
  and the door reads where the press goes from the region's declaration,
  `Driver.goes_to(place, action)`, never from the payload; a subclass
  overriding `payload()` loses nothing. `Driver.would_move(goes_to)` takes
  no state. A button's region is its place's name, and one entering a
  place under another region is reported; a button whose declared action
  goes somewhere listens to `Driver.NAVIGATED` by itself.
  `Driver.check_drawn(action)`, asked by the guide and the reminders as a
  prompt is raised, reports a place on the screen declaring the action,
  allowed by the game, that no control under it draws; a place still loading is its
  handler's to refuse. `PromptBar.new(chimes, commands, prompts,
  in_region)` takes the region of the place it sits in.
- A PLACE BUILDS ITS BUTTONS. `Place.new(chimes, named, driver, actions,
  prompts)` takes the register and the prompts beside the driver, and
  `place.button(action)` is a bell button of that place for an action it
  declares: the place hands it the chimes, the door, itself - its name the
  region - the register's words and the prompts. `BellButton.new(chimes,
  commands, place, action, words)` and `ActionControl.new(chimes, commands,
  place, action)` take the place and the action, and no region, face or
  listening; a control for an action its place does not declare is
  reported as it is built. `PromptBar.new(chimes, commands, prompts, place)`
  takes the place it sits in, and its switch is a button of that place. The
  guided demo's `Screens.button` is gone.
- A button knows what to listen to: a handler declares the bells its
  refusal moves on, `refusal_moves_on() -> Array` of `[region, bell]`
  pairs (`Controller` names none); the door answers
  `Commands.listening_for(region, action)` with them, and a control listens
  there by itself, and to `Driver.NAVIGATED` when its action goes
  somewhere. `LongList`, `TableModel` and `SlowSource` declare theirs.
- The engine scales to the window: `project.godot` sets a base size of
  1920 by 1080, stretched by `canvas_items` with the aspect `expand`. The
  Theme sizes words once, at that base size, by kind - `Themes.FACE`,
  `REASON`, `WORDS`, `READOUT`, `LINE`, `TITLE`, `NUMBER`, each a variation
  of Label a control names - and holds the focus ring's `ring_gap` and
  `ring_width` as constants under LOOK, read by `Presentation.get_constant`.
  A control's parts are placed by anchors as it is built; the `arrange()`
  overrides of the bell button, the prompt bar and the demos' readouts,
  dials and slot lists are gone, with every per-control font size.
- THE BELL BUTTON IS A COMPONENT, at `components/bell_button.gd`: it is one
  state - `glowing`, `inert`, `hover`, `normal` - drawn as the Theme says
  under the type `BellButton`: a stylebox per state, a `focus` stylebox
  drawn over it while the focus shows (its gap the stylebox's expand
  margins), and `font_color_<state>` for its words. A kind of button is a
  `theme_type_variation` of `BellButton`, never a subclass. Its content is
  passed in: `BellButton.new(chimes, commands, place, action, words,
  content)` and `place.button(action, content)` put the controls handed in
  a box container - separation and alignment the type's constants - before
  the words and the reason, which hides while empty. The ground and ring
  rects, the palette chain, the layout shares and the font kinds are gone
  from it; the convention lint refuses a file under `components/` that
  names a palette colour, a demo type, a layout number or a font size.
- The other drawn controls and the layouts are components too, at
  `components/prompt_bar.gd`, `text_field.gd`, `long_list_presentation.gd`,
  `flex.gd`, `flex_line.gd`, `grid.gd` and `grid_columns.gd`; every
  path to them moves. The prompt bar holds its words and its
  switch in a box container and takes, under the type `PromptBar`, its
  words' colour and the width shared between them (`Themes.BAR`).
- `theme.gd` holds placeholder defaults for the floor's own controls alone:
  `Themes.BUTTON` (the `BellButton` type's styleboxes, font colours and
  constants), `Themes.WORDS` for the prompt bar, `default_font_size`, and
  the palette under LOOK. `FACE`, `REASON`, `READOUT`, `LINE`, `TITLE`,
  `NUMBER`, the ring constants and `Presentation.get_constant` are gone;
  the demos' kinds of words live in `demo/demo_theme.gd`, a Theme built
  over the floor's defaults with `merge_with`. A palette handed to
  `Themes.new` names every colour the defaults are built from.
- INTERFACE IS DESCRIBED, NOT BUILT BY HAND. The primitives under
  `components/primitives/` are the only engine code: `text`, `image`,
  `surface`; `pressable`, `field`; `row`, `column`, `grid`, `stack`,
  `scroll`, `virtual_list`; `view`, `canvas`, `anchored`; `each`, `when`;
  and `later`, the one deferral. Every other component is a recipe - a
  function returning a description (`desc.gd`) - under
  `components/recipes/`: `BellButton.make(ui, action, payload, goes_to,
  content, style)` and `PromptBar.make(ui, prompts)`. The builder,
  `Ui.new(root, chimes, commands, driver, prompts, actions)`, answers a
  description for every primitive (`describe.gd`), builds places with
  `ui.app`, `ui.screen(name, content, handled_by, on_fill, on_empty)`,
  `ui.tabs` and `ui.pop_up(name, content, handled_by, blocks)` - declaring
  `performs` from the pressables inside and registering `handled_by` in the
  place's region - and `ui.start(app, beside)` builds top-down, checks the
  tree once it has entered, quits on failure and makes the first move;
  `ui.also(node)` puts a hand-made node beside it; `ui.build(desc, parent)`
  builds into a place made by hand, as the console does.
- An application is `application.gd`, a SceneTree an application extends:
  it puts the look on the root, makes the chimes, the driver, the door, the
  register and the prompts - registered for their own muting from anywhere
  - and the builder, and starts what the application answers to `look()`,
  `sources()`, `declare(actions)`, `describe()` and `beside()`. Every demo
  is one.
- A PRIMITIVE REGISTERS ITSELF: every primitive script has a static
  `build(ui, desc, parent)`; the builder keeps a table from kind to script,
  the floor's filled as it is built, and `ui.register(kind, script)` adds a
  game's own, described through `Desc.new(kind, props, children)`. The
  places are built by `components/primitives/place_builder.gd`. `ui.attach`,
  `ui.build_into`, `ui.region()`, `ui.current_pressable()`,
  `ui.primitive(kind)` and `ui.declare(desc, place)` are the doors a
  primitive uses.
- `each(items, template, key, style)` and `each_across` take a key, a
  function from an item to its identity: pieces are kept by key - an item
  added builds one, an item gone frees one (its focus handed on), an item
  moved is moved - so the focus, a typed line, a kept when side and a
  scroll survive a sort, a filter and a removal; `Each.piece_for(key)`. With
  no key, the index is the key and any change rebuilds every piece. A
  handle reads its item by key.
- A place asks every template inside it once with an empty handle as it
  is built, and declares what the template describes, so a collection that
  starts empty has its actions declared and its handler registered; a
  template must cope with an empty handle. A pressable built later no
  longer declares itself.
- The copy check is exact: a handle reports a read of itself while its
  own template function runs (`Bound.set_template_running`), and nothing
  else; the string-matching guess is gone.
- `later.gd` is gone; the floor's machinery defers directly. The convention
  lint's engine-code rule covers interface code alone: components, recipes,
  and a demo file that describes; not a model, not the floor's machinery.
- A collection demo, `demo/collection/`, over a model of things.
- A bound value: `model.bound(&"name")` reads the model's `get_name()` on
  the bells the model declares in `reads_move_on() -> Dictionary`; a
  primitive given one re-reads it on those bells; `map(format)` formats,
  `field(key)` reads a key. A template - `each(items, template)`,
  `virtual_list(list, template)` - is given a handle, a bound value at the
  item, and one that writes the item's value into a description is
  reported.
- Gone, replaced: `components/bell_button.gd`, `prompt_bar.gd`,
  `text_field.gd` (a `field` dispatches the line as its action, `{"line":
  ...}`, cleared when done) and `long_list_presentation.gd`; `Place.new`
  takes chimes, name and driver alone, `place.button` and `place.actions`
  and `place.prompts` are gone, and a described place fills and empties
  through `on_fill(token)` and `on_empty`. `Commands.dispatch` keeps the
  outer command's record straight when a command is told from inside one,
  so a dev command may move the reader without deferring. `Flex.set_gap`,
  `Grid.set_gaps`; `Console.new(ui, debug_log)`, its pages two pressables,
  `Console.SHOWS_STREAM` and `SHOWS_PATH`, Ctrl+Tab turning between them.
- The theme holds defaults for the primitives' styles - `Themes.PRESSABLE`
  (with the recipes' `BUTTON` a variation of it), `ROW`, `COLUMN`, `GRID`,
  `SURFACE`, `BAR` - and the kinds of words `FACE`, `REASON`, `WORDS`. The
  convention lint reports engine code outside the primitives: anchors,
  `add_child`, mouse filters, size flags, theme overrides, type variations,
  `ColorRect`, `Label.new` and `call_deferred`.
- `StartupCheck.broken(index, actions)` reads the declarations: a declared
  action not in the register, a declaration to no place, a registered
  action no place declares, a declaration of a driver command, duplicate
  and reserved names.
- A PLACE TAKES A PARAMETER - which one of its kind it is entered as:
  `Events.Event.go(place, parameter)`, `Driver.move(goes_to, parameter)`,
  `Driver.would_move(goes_to, parameter)`, a press carrying
  `"parameter"` in its payload. The state holds `params` (place ->
  parameter) and `history_params` (one per history entry); `Place.parameter`
  is set as it fills; `Driver.get_parameter(place)` reads it. The same
  place with another parameter is a move - left and entered again from the
  place whose parameter moved (`Paths.parting`); the history cuts back
  only to the same view, path and parameters; BACK restores the entry's
  parameters. A card, an inline link and a play control carry the item's
  id as the parameter.
- STATE KEPT WITH THE HISTORY ENTRY: `Driver.keep(name, object)` and
  `Driver.kept(name)` keep and find a state controller for the view the
  reader is on now; a detour and Back find it intact, and it goes with the
  entry when the history is cut back or forgotten.
- New primitives: `pulse(content)` (period and depth from the theme),
  `pan_zoom(paint, content, actions, hit, style)` (pans, zooms and picks as
  actions), `scroll(content, reveal)` (a bound name kept in view),
  `canvas(paint, content, style)` takes a style, a pressable may be
  `absent_when_refused()`, and a tiles layout wraps (`Themes.TILES`).
  `each(...).pieces_named(prefix)` names every piece after its key. A
  place declares a field's action and a pan_zoom's actions as it declares a
  pressable's.
- The components, as recipes under `components/recipes/`: `nav_control`
  (menu, inline, back, play), `card` (list, tile, dense, empty),
  `collection` (rows, tiles, outcomes; controls and filters), `cell_readout`
  (quantity, bar, label, trace, mark, relative), `tab_bar`, `filter_set`,
  `countdown`, `amount_field`, `board`, `attention` (bubble), `matrix`,
  `instruction_bar`, `relationship_graph`, `disposition`, `moment`. Each
  has a test, and all show in `demo/gallery/`.
- Routing keeps the parameter a place already has: a simulated press,
  `Queries.pressed(chart, state, goes_to, back)`, moves with the parameter
  the place has in the state searched - none when it has none - so no
  state is imagined that a press could not make. Back hands the arrival a
  copy of the entry's parameters, never the record. A thing kept with the
  view (`Driver.keep`) is a RefCounted, freed as its entry goes; a Node is
  refused out loud. `Index.draws(place, action)` is where the driver's
  drawn check walks. `Events.leaving`, `Events.entering`, `Events.outcome`
  and `Events.refused` are the chart's effect sequences and answer shapes,
  moved whole out of `chart.gd`.
- Every holder that takes its room from its content - `interaction.gd`
  and so every presentation and pressable, `surface`, `stack`, `pulse`,
  `anchored` - is the engine's Container, not a bare Control: a part whose
  words arrive after the build now takes its room and its row moves the
  rest, where before it kept no width and its siblings were drawn over it.
  A presentation sets the stop a control needs, since a container's
  default lets a press through.
- A style the look does not know falls back to its base: a row or column
  is laid out as a row or column (align, gap, justify), a pressable is
  drawn as a pressable, a surface as a surface, a pulse as a pulse. Every
  recipe names its own style; the floor's look defines the bases alone.
- `scroll` gives its one piece the whole window across and along, so tiles
  wrap at the window's width and rows run its width.
- `anchored` sits just above its target, as wide as it, never over its
  words; a bubble is above the control it points at.
- LOOKS. `look.gd` is the vocabulary a design language is written in:
  `Look.flat`, `ring`, `nothing`, `layered` (boxes and painters drawn in
  order, `painted_box.gd`), painters `dashed`, `brackets`, `rule` (any
  side; `underline` and `left_bar` are rules), `hatch`, `gradient`,
  `bevel`, `soft` (paired shadows), `elevation` (ambient and key), a
  system `font` by family, and the entries `pressable`, `words`, `line`,
  `field` (a LineEdit variation) and `ground` (with a blur). A type is
  never made a variation of itself. `demo/demo_theme.gd` takes a palette.
- A look put on the root re-dresses what shows: a layout re-reads its
  gap, justify, align and wrap on the theme changing; a pressable, a
  surface and a pulse try their style again and fall back to the base if
  the new look lacks it; nothing loops.
- A surface with a `blur` constant frosts what is behind it through one
  screen-texture shader on a rect under its content.
- A pressable's and a surface's content sits inside its box's padding
  (`components/primitives/inset.gd`); a pressable's ink is its style's,
  else a pressable's; plain words under no kind are in the palette's ink.
- The tab strip's style is `TabStrip`: `TabBar` is the engine's own class.
- Ten looks under `demo/gallery/looks/`, one design language each - flat,
  material, glass, neumorphic, neo_brutalist, swiss, bento, skeuomorphic,
  data_dense, hud - picked from the gallery's first tab or `--look=<name>`.
- TEN STALL DEMOS, one per design language, under `demo/stalls/`: the
  same functionality - the models, the actions, the guide, the note kept
  with the detail - arranged as each philosophy lays a screen out. The
  functionality is `demo/gallery/stall.gd`, which every stall extends
  answering `arrange()` and `worn()`; the gallery is the placeholder
  arrangement. Run with `-- --probe` a stall walks its functionality and
  prints PROBE OK; `checks/stalls_probe.py` runs every demo so, and
  `verify.py` runs it. The picked crate re-reads on every move.
- A TAB IS A FLAP ON THE PANEL IT REVEALS. A pressable has a fifth state,
  `current`, for one whose destination is on the screen the reader is on:
  selected, not unavailable - it gives no reason, and takes normal's box
  and ink where a look defines none. `Tabs.make(ui, tabs, content)` gives
  the flaps over a `TabPanel` holding the content with nothing between
  (`TabSet`), the flaps bottom-aligned on the `TabStrip`, the current one
  taller in the panel's fill; given no content, the strip alone. The
  placeholder look draws them so; `Look.flap` is a box rounded at its
  top corners. Every stall demo's components are `demo/gallery/pieces.gd`,
  built once by name for the arrangement to place.
- `current` compares the parameter: a press is current only when the place
  it goes to is on the screen entered as the very one the press carries.
- A box takes its fill and NAMED OPTIONS: `Look.flat(fill, {radius = 8,
  border = 2, border_colour = x, pad = 12})`, and so `flap`, `ring`, `soft`,
  `elevation`; an option a box does not know is reported out loud.
  `Look.line` takes the flex layout's own constants (`Look.START` ...
  `Look.STRETCH`). The painters are `paint.gd` (`Paint.dashed`, `brackets`,
  `rule`, `underline`, `left_bar`, `hatch`, `gradient`, `bevel`,
  `outline`): a gradient and a dashed edge take a radius and follow a
  rounded box's corners; brackets and a hatch are square-only and
  `Look.layered` reports either over a rounded box.
- `field(action, style, takes_focus, {changes, shows})`: a second action on
  every change, and a bound value the line is set to when it moves. One
  field style, `Themes.FIELD`, for every typed line. `key_capture(action,
  shown, asks, style)`: pressed, it listens for the next key or button
  and hands it to its action; the cancel key binds nothing. A place
  declares both. `Bound.both(a, b, blend)` reads two bound values on the
  bells of both.
- Eight components: `setting` (row, toggle, choice opening an overlay,
  binding), `type_ahead` over `narrowing.gd`, `table` (sort by header, a
  virtual list when long, formatting by mark and weight), `sections`,
  `confirm`, `text_field`, `bracket`, `line_chart`. `filter_set` picks a
  property and a list value by type-ahead; its model gains
  `get_property_narrowing()`, `get_value_narrowing()`, the two option
  reads and the actions `picks_value`, `types_property`, `types_value`,
  and `picks_property` carries `{value}`.
- Every stall has four more places - SETTINGS, LEDGER, KNOCKOUT, TAKINGS
  (`demo/gallery/more_pieces.gd`, `more_models.gd`) - which a demo adds to
  its stack as `more.screens()`, their overlays beside the app; the probe
  (`demo/gallery/probe.gd`) walks them too.
- A style may be a bound value on `text`, `surface` and `pressable`: it is
  worn again in place on the bound's bells, the node kept. `Surface.new`
  takes the chimes second. The table's cells are styled this way
  (`Themes.TABLE_CELL` by default); the keyed one-item `each` per cell is
  gone.
- One confirm serves every row: `Confirm.opener(ui, asks, overlay, row)`
  goes to the overlay as the row, and `Confirm.for_rows(ui, overlay,
  consequence, action, cancels, carries, also)` says the consequence of,
  and confirms on, the row it was opened as. `Confirm.make` keeps its shape
  and its opener is `Confirm.opener` with no row. The sheet sits in a line
  styled `Asked`.
- `key_capture` stops listening, binding nothing, when the focus leaves it
  and when the mouse is pressed on anything else, as well as on the cancel
  key; listening, it holds the focus.
- The type-ahead count reads "no matches", "1 match", "3 matches", from
  `TypeAhead.counted`. `Setting.toggle(ui, action, on, on_style,
  off_style)`: the words are "On" and "Off" and the look is one of two
  styles, `Themes.TOGGLE_ON` and `Themes.TOGGLE_OFF`, by a bound style;
  the style `Toggle` is gone. `Look.toggle(theme, mark)` draws both from a
  look's own pressable.
- `Bound.all(sources, blend)` reads any number of bound values at once on
  the bells of all, each once; `Bound.both` is its two-source case.
- The pressable is split: `face.gd` is how a pressed thing looks - hover,
  focus, a box and an ink by state, the bound style - and knows nothing of
  actions; `action_control.gd` extends it, taking the style last in
  `_init`, and the pressable adds the door's, the prompts' and the driver's
  states as before. `ui.local(initial, kept)` is a value of the interface's
  own (`local.gd`: `get_value`, `set_value`, `bound`), freed with what was
  built from it, or kept with the history entry. `ui.press_local(local,
  gives, content, style)` sets one, through no door; its state over hover
  and normal is `selected`, which `Look.pressable` draws as a look's
  glowing where the look gives none.
- A choice's chosen option is drawn by a bound style, `Setting.CHOSEN`
  (`Themes.CHOICE_CHOSEN`) against `Setting.OPTION`; `Setting.PICKED` and
  `UNPICKED` and the marks in the words are gone, and `Setting.choice`
  takes `chosen_style` last. `Look.marked(theme, type, mark)` draws any
  marked pressable; `Look.toggle` marks the chosen option too.
- The confirm, the moment and the choice's overlay share one shape,
  `components/recipes/sheet.gd` (`Sheet.over(ui, content, style)`): the
  moment's sheet now stands in the `Asked` line, not `Centred`.
- A section's heading shuts and opens what is under it, by a kept local:
  the heading is a local press styled `Sections.HEADING`, wearing the mark
  `Sections.OPEN` or `SHUT` before its words. `Card.more(ui, detail)` is a
  line of detail shown in place, among a card's readouts.
- `RelationshipGraph.make(ui, graph, actions, opens_to, style)`: the model
  answers `selected` beside `picture`, the actions gain `expands` and
  `opens`, and the selected node wears a ring and shows a panel of the two.
- MOTION, first pieces. `motion.gd` is the one clock: `Motion.run(from, to,
  easing, apply, fades, done)`, `retarget(run, to)`, `step(seconds)` with
  `by_hand` for a test, `budget` (a `FrameBudget`; over it, new motion
  snaps), and reduced motion as the command `Motion.REDUCES` and the read
  `reduced`. The look holds the tokens under the Theme type `Motion`,
  written by `Motion.tokens(theme, durations, easings)`; `theme.gd` sets
  defaults. The builder makes the clock, `ui.motion`, and puts it under
  the root as it starts; a test that builds without starting frees it.
  `ui.eased(bound, easing)` is a bound value going smoothly to its source
  (`eased.gd`); `own_bell.gd` is the base it shares with the local. A
  quantity rolls, a bar fills, and a line chart's series is reached:
  `LineChart.reached(places, reach)`; the chart's canvas is handed
  `{chart, reach}`.
- A change of look blends: a face's box by state or bound style, a
  surface's bound style, and a text's bound kind. The old box is left
  fading over the new (`components/primitives/outgoing.gd`, an internal
  child - `get_children(true)` sees it) and the ink goes between the two
  colours, by the easing `Motion.RESTYLE`. The builder hands the clock to
  whatever it attaches that has a `motion` attribute; a control built by
  hand has none and switches. A test reading a look straight after a
  change steps the clock past the blend first.
- A `when`'s swap and an `each`'s arrivals and departures are transitions
  (`components/primitives/transition.gd`: none, fade, scale, grow, from a
  side), asked for with `Desc.transition(kind)` or named by the look
  (`Transition.defaults(theme, {what: kind})`; `theme.gd` fades a when
  and grows an each). A thing going stays until its exit has run and NEVER
  leaves the tree (`going.gd`): it is in the group `Going.GROUP`, last among
  its holder's children, with no press and no focus, neither placed nor
  measured by a described line layout, and everything beneath it that
  answers `going()` is told - `Place.going()` gives up its stay, its name
  in the index and its node name there and then, so a `when` over two
  layouts of the same places swaps cleanly. A walk of a holder's children
  sees a going thing until it is freed.
  A keyed `each` takes pieces whose place changed to their new one by a
  planned reorder (`reorder.gd`, `Reorder.plan`): what stays in step
  slides, what would cross anything is lifted out and set down, in three
  beats - out, across, in - so nothing is ever drawn over anything else;
  arrivals enter in the third beat, staggered; what is there as it is
  built is simply there. `Motion.still`
  makes every run arrive at once - the test fixture sets it, and a test
  about motion sets it back; `Run.wait(seconds)` delays one.
- `Motion.drive(node, what, from, to, easing, apply, fades, done)` is the
  one run that writes that property of that node: it takes over from
  whatever was driving it, from the value reached, and the run taken over
  is over and never says it arrived. Transitions and the reorder drive
  (`Transition.WHAT_OPACITY`, `WHAT_SCALE`, `WHAT_SLIDE`,
  `Reorder.WHAT_CARRY`). A driven run reads the motion tokens from its
  node's look, not the window's; `Motion.lasts(easing, under)`,
  `stagger(under)` and `run(..., under)` take the node. A shift takes
  its rest again whenever its host is somewhere it did not put it; a
  `when` tells the shift on its side as it is arranged, as an each does.
- PLACES ARE SEEN TO COME AND GO (`place_motion.gd`, from the applier). With
  a clock - `Driver.motion`, which the builder sets - a place leaving is
  switched off at once but stays `visible` until it has been seen out, so
  code reading `place.visible` straight after a move sees the leaving place
  still shown; `Driver.get_top()` and the state are the truth of where the
  reader is. One place taking another's room is a push, edge to edge, from
  the right going on and the left going Back, or the way two side by side
  lie; a pop-up fades and the panel slides, by the look's transitions
  `overlay` and `panel`; what is first shown is simply there.
  `Applier.apply` takes the chart's kinds and whether the move was Back;
  `Applier.active_in(state)` names the places a state names.
  `Desc.arrives(kind)` has a described thing arrive its own way each time
  its place is shown (`Place.arriving`): `Sheet.over`'s sheet scales in.
  The room a push goes through clips only while the push lasts and is
  given back as it was (`PlaceMotion.push_of`; `PlaceMotion.change` takes a
  `pushed` callable).
- A going thing is skipped by every layout that arranges or measures: the
  described line and grid (`layout.gd`, `grid_layout.gd` override what
  they take), the stack and the inset.
- NO NUMBER OF A TRACK LIVES IN A RECIPE. A keyframe's value may be the NAME
  of a Motion token, read from the node's look in thousandths. `theme.gd`
  gathers every undecided number in `_placeholders()`: `breathe_opacity`,
  `breathe_scale`, `beat` (a second passing, its own token - not the
  pulse's period), `beat_opacity`, `beat_scale`, `beat_for` (how many last
  seconds beat), `settle_scale`, and the Shape breakpoints. `Countdown.make`
  no longer takes `last`. `Motion.get_token(named, under)` reads any token.
- UI sounds: `sounds.gd`, made by `Application` (`sounds`), plays a look's
  sound for a moment - hovered, focus moved, pressed, refused, glow
  started, raised, lowered, moved. A look sets one with
  `Sounds.set_sound(look, moment, stream, style)` (Theme metadata), found
  under the style, then what it varies, then the look's default; the floor's
  look sets none. A PRESS SOUNDS ONLY FROM A HAND: `interaction.gd` rings
  `HOVERED`, `FOCUS_MOVED` and `PRESSED` (through `face.gd`), `PRESSED`
  after the control's own `pressed()`, and `Interaction.get_pressed()`
  answers which control it landed on, whose own answer says refused or
  not; a command run by a model, the console or the opening move sounds
  nothing, and nothing sounds until the reader has first been moved.
  `Sounds.SETS_VOLUME {"value"}`, `Sounds.MUTES_SOUND {"on"}` on the `UI`
  bus. A held press that repeats rings `PRESSED` once, as it lands: the
  repeats press again and ring nothing.
- A PAINTER TAKES AN INK, NOT A COLOUR, and resolves it from the theme on
  every draw: a palette name (`&"accent"`), `Paint.under(name, type)`,
  `Paint.faded(ink, alpha)`, `Paint.mixed(ink, toward, by)`, and the
  hue-free `Paint.light(alpha)` / `Paint.shade(alpha)`. A painter is
  `(canvas, rect, theme)`; a `PaintedBox` is told its theme
  (`set_look`, held weakly) by `Look.layered(theme, layers, pad)` and again
  by `Palettes.rewear`. `Look.layered`, `Look.soft` and `Look.elevation`
  take the theme FIRST; `Look.toggle` and `Look.marked` take an ink. A name
  the theme does not hold is reported once and drawn in magenta. A look's
  own drawing colours moved into its PALETTE by name.
- WHERE A SCROLL STANDS IS KEPT WITH THE VIEW: a scroll keeps its offset,
  and a virtual list its first row, with the history entry (`driver.keep`),
  so a detour and Back land where the reader left and another view of the
  same screen keeps its own. The offset is written down as the content is
  placed and put back as it is next placed after the driver's bell -
  waiting, never clamped short, for content that arrives later. A scroll
  now follows the focus into view (`follow_focus`); a focus given back on
  arrival never moves it from where the reader stood. A virtual list is
  taken back to its row by `LongList.SCROLL_ROWS`, the wheel's own command.
  `Applier.shows(state, node, index)` answers whether the state shows a node.
- FOCUS, as ruled: a pop-up or the panel keeps the focus of
  its own only while it is up, and forgets it as it is lowered - the next
  raise lands on its default; what opened it is remembered apart, as
  before. The focus memory moved out of the applier into `kept_focus.gd`
  (`KeptFocus.note`, `give_back`, `forget_lowered`, `default_focus` -
  `Applier.default_focus` is gone). A scroll puts back where the reader
  stood on a view after the focus is given back and before anything is
  drawn, so a focus given back never leaves it elsewhere; a fresh view is
  left as it stands, and the focus given to its default brings that into
  view.
- AN APP VIEW'S FOCUS IS KEPT WITH ITS HISTORY ENTRY, as its scroll is:
  Back finds it exactly where it was in that entry, a fresh visit lands on
  the default, the same screen with other parameters is another entry, and
  an entry the history drops lets it go. `Applier.apply` takes the store
  (`kept.gd`) and the entry being left; `KeptFocus.note_view` and
  `give_back_view`. The driver lets dropped entries go after the move is
  carried out, not before.
- `ui.text(content, style, hides_empty, wraps)`: words that break onto more
  lines at the width they are given. A wrapping line layout measures the
  height of all its lines, so what follows it sits below them. The line's
  placing along it moved to `FlexLine.spread`, and the line constants
  (`START`...`STRETCH`) live in `flex_line.gd`, re-exported by `flex.gd`.
- `ui.scroll(content, reveal, along)`: `Scroll.ACROSS` scrolls sideways
  alone, as tall as what it holds, with no bar. A tab strip whose flaps are
  wider than its room scrolls across in one; the strip is now a
  ScrollContainer holding the row.
- A `when` and a `stack` give what they hold the whole of themselves as they
  are placed: words that wrap, held straight inside either, wrap at the
  holder's width instead of standing at their own least width, one letter
  to a line. A side or piece on its way out stays where it stood.
- The stalls probe judges a window on its end like the other two shapes, at
  9:16 - the base turned - and at every shape raises each pop-up and
  presents the moment as well as seeing every place.
- EVERY HOLDER PLACES A PIECE THROUGH `Shift.fit(holder, piece, rect,
  tells)`, which keeps the scale and turn the piece's motion has reached -
  the engine's fitting sets them back - and tells the shift on it, unless
  the holder tells its shifts itself (an each). Row, column, grid, stack,
  when, surface, a pressable's content and keyframes all do.
- A row or a column (`layout.gd`, so `by_shape` and `each` too) and a grid
  take no press: what they hold does. A line laid over another layer no
  longer swallows the presses meant for what is beneath it.
- Words that wrap have what they need asked again as they are placed, shown
  or not: a screen not yet shown no longer needs the height of its words at
  no width, a letter to a line, and a stack of screens is never taller than
  its window for it.
- The applier settles each place as ITS move comes to rest - the place and
  the places inside it - never every place the state no longer names, which
  hid a place another move was still pushing out; and a room a push goes
  through is given back only when the latest push through it rests.
  `PlaceMotion.change` hands `settled` and `pushed` the place they are about.
- `ui.grid(children, columns, style, turned)`: `turned` gives columns for a
  shape of window - `{Shape.PORTRAIT: [0.5, 0.5]}` - the same cells
  re-flowing into them as the window turns, a span clamped to the columns
  there are.
- A PLACE MAY ASK BEFORE IT IS LEFT (`leave_guard.gd`).
  `ui.screen(named, content, handled_by, on_fill, on_empty,
  asks_before_leaving)` names a pop-up; while `handled_by.would(Driver.LEAVES,
  {})` answers words, a move that would empty that screen - a place inside
  the one left included - is stopped before any handler is told and the
  pop-up raised with the stopped command as its parameter, `{region, action,
  payload, asks}`. `Confirm.for_leaving(ui, overlay, proceeds, cancels,
  style)` is that pop-up: its cancel goes `Driver.BACK`, its confirm goes
  `Driver.ONWARD`, a new destination, and makes the stopped move with the
  guard passed once. `Place.handled_by` and `Place.asks_before_leaving` hold
  the two; the startup check reports a question that is no pop-up and a
  place asking with no model.
- The door puts every command that moves the reader - a press going
  somewhere, or one of the mover's own - to `mover.stops_to_ask(region,
  action, payload) -> String` past its refusal and before its handler is
  told: a mover of your own implements it. `Commands.get_last()` gains
  `"paused"`, true for a command so stopped, whose answer is the words asked;
  the control pressed shows no refusal for it.
- `Queries.reachable(chart, performs, state, action, would, back, guarded)`
  and `Queries.route(chart, performs, state, action, would, back, guarded)`
  take the Back destination and the places asking first (`{place: words}`),
  and never leave one; `Queries.stopping(outcome, guarded)` names the place a
  move stops for.
- The driver's reads are `whereabouts.gd`, which `driver.gd` extends: every
  public name stays on the driver, but a script extending the driver may not
  declare `Index`, `Chart` or `Kept`. What is kept per history entry is
  `kept.gd`: `Kept.entry_of(state)`, `keep(entry, name, thing)`,
  `kept(entry, name)`, `let_go(state)`. `Driver.event_of(action, payload)` is
  public.
- A place takes the room what it holds needs, hidden pieces included, going
  ones not, and fits every piece to itself as it sorts, keeping the piece's
  scale: a screen needing more than it is given pushes what lies below it on
  instead of hanging over it.
- The confirm's words wrap at the width the sheet gives them
  (`Confirm.make`, `for_rows`, `for_leaving`).
- A filter's settle wait runs on the one clock: `Motion.after(token, done,
  under)` and `Run.waiting(seconds, done)`, so a test steps it by hand.
  `Motion.tokens(theme, durations, easings)` is gone - use
  `MotionTokens.write(...)` (`motion_tokens.gd`).
- BROWSING (from the furniture shop, demo/apps/shop): `ui.lazy_image(loads,
  key, sizes)` over `image_loads.gd` - pictures painted on the job pool as
  the reader nears them (`nearness.gd`), held while shown, the unseen let
  go; `ui.nearing(action, payload, content)` presses an action as it comes
  near; `growing_list.gd` and `InfiniteCollection.make` - cards in equal
  columns growing a page at a time, stand-ins while a page is on its way, a
  failure with "try again"; a wrapping line whose style names `least_column`
  lays out in equal auto-fill columns; `Drawer.over(ui, title, content, foot,
  closes, from)` - a side or bottom sheet over a shade; `Gallery.make`,
  `QuickView.make`; `ui.range_slider` - two ends on one track, `{value:
  Vector2}`; `facets.gd`, `facet_counts.gd`, `orders.gd`, `FacetList` -
  counted filter values, a value that would keep nothing refused. `SORTS`
  may name `ascending`. The floor's kinds are `floor_kinds.gd`'s table
  (`ui.FLOOR` reads it). Looks in `theme_browsing.gd`.
- A running stream keeps to its capacity too (`stream.gd`): events left
  waiting past a frame's share are kept to the newest, the oldest counted
  missed; a `behind` read says how many wait, and `missed` counts the whole
  time the stream is open. The console's status line says so, with the
  notice's mark. In `clipped_text.gd` a scroll inside a scroll keeps the
  outer one's movable edges, so words the outer can bring in are not cut.
- MANY AT ONCE COME TO REST AT ONCE, as was ruled: past the look's `bulk`
  (a Motion token, placeholder 12) pieces starting to arrive or go in one
  frame - a filter's, a search's - every such run of that frame finishes at
  once (motion.gd); one change alone, and every move, keeps its motion.
  `each` finds items by key and rings each piece's handle only when its own
  item changes; a line whose parts, sizes, reaches and settings are
  unchanged places nothing; a closed command palette offers nothing, its
  entries built as it opens; `anchored_at` takes the focus only where its
  layer lets it. The probes' hands press only what stands in an active place.
- SENTENCE CASE, as was ruled: every phrase shown on its own starts with a
  capital, written in the English where it is written. Words said only
  inside another phrase are `Phrase.within(words)`, or a constant named
  `_WORDS_WITHIN`, and stay lowercase; `words_template.py --check` fails a
  commit on a phrase starting lowercase unmarked. Every catalogue's keys
  move with the English. `FilterSet.COMPARISON_WORDS` is renamed
  `COMPARISON_WORDS_WITHIN`; `LineChart.MARKER_WORDS` are capitalised
  ("Circle", "Square", ...); `DashboardFilter.get_before_within()` is the
  stretch before as said within a figure's change.
- THE TRAY HOLDS ROOM FOR ONE, as was ruled: one notification shows,
  cleared one by one, the rest waiting in order with "N more" on the same
  line; only the one showing spends its stay. A notice is one line -
  presses, then words, then the count - so the room is 8 to 10% of a
  1080-high window. `HOLDS` is gone (and glass's override with it); the
  paging press is gone; a new placeholder, `LETTERS`, is the least width of
  a line of words beside the presses, which `fits()` measures against.
- TOUCH (from the parcel-delivery app, demo/apps/mobile): a finger is read
  once (`touch.gd`, `ui.touch`) - a gesture goes whole to the nearest taker
  on its axis, a finger's press is a tap on release within `Touch/slop`
  leaving no hover, and sliders, grips and draggables hold a finger drawn on
  them. A pressable holding content is at least the look's `Touch/least`
  each way on a phone's window (`Shape.PHONE`, a window meta; the floor's
  look sets 0). A `scroll` takes a finger where it can move and glides
  (`scroll_finger.gd`, `Motion/glide`); its carry near an edge is
  `scroll_edge.gd`. New: `ui.swipe` (`swipe.gd`, `get_slid`, `is_armed`,
  `Touch/swipe_commit`), `ui.pull` (`pull.gd`), `refresh.gd` (`REFRESHES`),
  `connection.gd`, `outbox.gd`; recipes `SwipeRow`, `AdaptiveNav`,
  `PullToRefresh`, `ConnectionStatus`; looks in `theme_mobile.gd`. A
  description may say what it declares (`"declares": {action: goes_to}`),
  and a declared destination stands over a menu's offer of the same action.
- An optimistic change never ends silently different from the far side
  (`provisional.gd`): a thing whose later changes a refusal undid is read
  back once every answer is in - `reads(key, answer)` and `settles(key,
  state)`, handed in - the far side's record winning and a late yes landing;
  with no way to read back, the reader is told the thing may differ. A
  lane's shown test is its own (`Lane.new` takes `shows` after `source`;
  `Lane.HIDDEN` is gone), so a search changes no card.
- FORMS (from the insurance application, demo/apps/form): a form is its
  data - `question.gd`, `answers.gd`, `form.gd`, `form_actions.gd` - rules on
  the model answering through `would()`, conditional questions kept while
  hidden, dirty against the saved draft, a submit refused taking the reader
  to the first problem; recipes `FormField`, `FormSteps`, `FormReview`; a
  typed date in the language's order (`dates.gd`, `DateField`) with one
  shared calendar pop-up (`calendar.gd`, `CalendarSheet`); `ui.file_pick`
  through the engine's own dialog, holding a file's name, size and kind,
  never its bytes; `ui.arrival_focus` - a place entered for a question puts
  the focus on it. `AmountField.make` may show the amount a model holds.
  Descriptions in `describe_forms.gd`; looks in `theme_forms.gd`. The
  shell's status line is its own kind of words, `ShellLooks.STATUS`, a
  variation of `REASON`. A place pushed out and later shown within another
  arriving stands at rest, whole, never still slid away or faded.
- DIRECT MANIPULATION (from the kanban, demo/apps/kanban): a carried thing
  is its payload (`carried.gd`), where it would land `{into, at}` with a
  `MOVED_OVER` bell; `lift` takes `(payload, over, by_keys)` and
  `get_lifted()` is gone. `carry_walk.gd` - keys and pad walk along and
  across lists, accept drops, cancel puts back. A `drop_target` may stand for
  a list (`into`) and places the drop among what it shows, one command sent
  before the card is set down; a `draggable`'s click without a drag is its
  `presses` action, and it leaves a hole while lifted. `lane.gd` shows the
  carried card where it would land; `lanes.gd` stands lanes side by side,
  each scrolling down, in a strip across. `provisional.gd` - OPTIMISTIC
  CHANGES: a change stands at once, and a refusal undoes it and every later
  change to the same thing, once, with the reason on it and in a
  notification. `avatar.gd`, `badge.gd` (words and a level mark, never a hue
  alone), `progress.gd`; looks in `theme_board.gd`. A scroll's DOWN mode
  scrolls down only and is never narrower than what it holds; in
  `clipped_text.gd` a scroll a strip holds follows the strip's rule. The
  floor's look dresses every family of pieces from one list in `theme.gd`.
- THE GRID, AS RULED: a filter's query goes once typing settles
  (`query_pacing.gd`, the Motion token `typing_settles`), at once on Enter or
  a pick; `PackedRows.copy()` is gone - `snapshot()`, the rows at a version,
  shared until a column is next written. `RowFilters.new` takes the `Motion`
  its wait is read from, before the region. A view behind its rows says so
  (`view_behind.gd`): the line reads out of date once a shown row is written,
  a row that no longer fits is dimmed and marked in place, and "bring the
  view up to date" (`ViewBehind.REAPPLIES`) runs the query again, the scope
  with it. `TableModels.replace(rows, columns)` and `RowSelection.replace` are
  new; the table rebuilds its lines for new columns; `DataGrid.declare_table`
  declares a read-only table's actions alone. The view's places are
  `view_places.gd`'s.
- A LIVE SCREEN'S FLOOR (from the operations console, demo/apps/console):
  `throttle.gd` - a deed asked many times in a frame done once, or paced by
  a Motion token (`live_cadence`); `keyed_items.gd` - each item its own bell,
  so one changing tells only what shows it; `stream.gd` - a source's events
  handed on once a frame for a place's stay, held while paused and caught up
  over frames; `feed.gd` - entries arriving at a long list's end, following
  or holding where the reader stands; `rolling_series.gd` - a live line
  chart fed through the one `LineChart`; `paced_notices.gd` (`notice_pace`);
  recipes `Status` (a shape, words and an ink, never a hue alone), `Wall`,
  `LiveFeed`; looks in `theme_live.gd`.
- THE TRAY HOLDS ITS ROOM, as was ruled: the shell's foot keeps room for the
  look's `HOLDS` notifications of `LINES` lines and a reason, whether any
  stands or not, so a notification arriving, stacking or leaving moves
  nothing above it; past the number, a "+N more" press pages back through the
  rest; words too long scroll within the room and are reported. A tray must
  answer `TrayStand.fits(words)`. `Shell.make`'s status may be a description,
  and the foot stands on `ShellFoot`. `ToggleOn` and `ChoiceChosen` are padded
  as a pressable is, so a toggle turning on keeps its height. Every look
  chimes as a notification arrives: the floor's placeholder, made in numbers
  (`theme_placeholders.gd`); `DemoTheme` carries the floor's sounds across
  `merge_with`.
- Layout costs less and settles: a face and a text answer for their own
  drawn reach, worked out once and again only when the look, the kind of
  words, the box or the content's placing changes; a line asks each part's
  reach once; a face asks its state once a refresh, re-sorts only when its
  box keeps different room, and inks words put into it after its first
  draw; a scroll's reveal of a piece longer than its room shows its start
  and settles. A field shows a refused line's reason under it (or in a
  `refused` local); `carries` shapes every change, and `leaves` dispatches as
  the focus leaves. `TableModels.row_actions` gives a grid's rows a context
  menu. A virtual list takes the focus only where its layer allows. An
  application clears the window to its look's ground. `save_shape.gd`
  declares a save's shape once - panels, documents, the input map and the
  workbench refuse a torn save through it. `Looks.asked(own)` gives an app
  its own look.
- THE DASHBOARD PIECES (from the analytics dashboard, demo/apps/dashboard):
  `dashboard_filter.gd` - one model of filters every figure and chart reads;
  `rollup.gd`, `measures.gd`, `thresholds.gd`, `drills.gd`; `KpiCard`,
  `BarChart`, `RegionMap` (pressable, focusable regions), `DateRange`
  (presets and a comparison period), `DrillDown` (a scoped data grid in a
  sheet), `MeasureCharts`, `LoadedOrEmpty`; `ui.areas` (named areas per
  width, the same parts re-flowed) and `ui.pinned`; looks in
  `theme_charts.gd`. `LineChart`'s extent, `to_canvas` and ticks move to
  `ChartAxes`, its margins a Vector4 by `margin_of(control, chart)`; it takes a
  span a model gives, areas filled to a lower edge, and a legend in REASON
  words that wraps. `Canvas` asks its least height of the look.
  `QueriedRows.scope_to` - clauses beneath the filters, part of reapply.
  `Formats.quantity`, `Sheet.tall`.
- `settings_file.gd` writes safely: a write starts from what the file held
  and writes each kept section over its own, so a section no model kept this
  run survives untouched; the file is written whole to `<file>.writing` and
  renamed over it, a failed write leaving it as it was and said out loud; a
  file that is not settings is moved aside to `<file>.unreadable`
  (`.unreadable.2` and on) as it is read, said once, and never written over.
- THE DATA GRID (from the enterprise grid, demo/apps/pipes): `data_grid.gd`
  and `long_table.gd` over `table_models.gd` - 100,000 rows that never
  become nodes: `packed_rows.gd` holds them, `row_query.gd` and
  `queried_rows.gd` sort, filter and group them off the frame,
  `row_selection.gd` picks and moves a cursor, `row_edits.gd` edits with
  undo, `editing_cell.gd` edits in place, `table_columns.gd` hides, shows and
  resizes columns (each edge a `ui.grip`), `row_filters.gd` and
  `held_pages.gd`. `ui.cells` (`cells.gd`) is a table line that never lays
  itself out again as words change and drops whole columns that do not
  fit; `slot_rows.gd`, `list_cursor.gd`, `kept_row.gd`. `virtual_list`
  gains a cursor mode, rows fitted to its height and recycled slots told
  only when their row changes; `long_list.gd` a `SHOWS` count; `filter_set`
  date comparisons and a builder that stands apart from its chips. Looks:
  `theme_grid.gd`. `TableHeading` pads only above and below; `Table` has no
  gap between its heading and its rows.
- A slider's drag is one command: a local shows the value under the pointer
  while it is held and the release sends it, a refused release settling back
  with the reason; `slider_track.gd`, which `slider.gd` extends, draws it.
  The pad never traps on a slider: left and right step it only where nothing
  that takes the focus stands beside it in the nearest row holding it
  (`Layout.is_row()`); elsewhere they walk past it and accept grabs it.
- `Notifications.notify()` reports out loud, naming the notification, when
  no tray stands: a tray says it stands through its mark, `tray_stand.gd`
  (`Notifications.add_tray`/`remove_tray`), and `NotificationTray.make`
  returns that stand. The notifications must outlive the tray; the test
  fixture frees what stands under the root newest first.
- THE APPLICATION SHELL (from the desktop command centre, demo/apps/workspace):
  `panels.gd` and `ui.split` - panels that fold, resize and persist; one
  resize handle, `ui.grip(action, carries, down, folds, style)`, dispatching
  `{"by"}` (and `{"to"}` where the holder states a share) by pointer, keys and
  pad; `panes.gd`; `shell.gd`, a frame that always holds the notification
  tray. `documents.gd` and `TabBar.documents()` - tabs for open files that
  are not places. `settings_file.gd` - named model sections in one JSON file,
  read at start, written at most once a frame after a change. A command
  palette - `command_search.gd`, `command_palette.gd` - over the screen's
  commands and the app's own sources. Context menus - `open_menu.gd`,
  `ui.menu_target(actions, payload, content)`, `ui.anchored_at`,
  `context_menu.gd` - opened by right-click, the menu key or a pad button,
  each item through the door. `relay.gd` - a pick standing for another press.
  `desc.current_while(bound)` - a pressable drawn current while a value holds.
  `Inputs.chord` - a key held with its modifiers is its own input ("Ctrl+K").
  Their looks are `theme_shell.gd`'s. The descriptions' chain is describe.gd,
  describe_inputs.gd, describe_shell.gd, describe_places.gd, ui.gd.
- Escape reaches a place's action before a line or area being typed into
  takes it. `transition.exit(NONE)` frees at the frame's end, never inside
  the node's own call. A narrowing works out its matches once a keystroke.
  A strip rests again once its row is placed, so a narrowed holder cuts no
  flap. `checks/stalls_probe.py` also runs `demo/apps/<name>/<name>.gd`.
- A `when` that holds nothing is hidden, so a line gives it no gap. A stack
  takes the room of its largest piece, shown or not, so the frame around it
  never jumps as its pieces swap - stated and tested. `checks/verify.py`
  walks the gallery in every look (`checks/looks_probe.py`).
- An inline option - `Radio`, `Segment`, `RadioChosen`, `SegmentChosen` -
  draws padded boxes of its own (`option_pad` under `Segment`): a look that
  dresses only its `Pressable` no longer reaches them and must dress them
  too. `Combo.long`'s overlay is no longer `Sheet.over`: its sheet takes the
  look's share of the window's height (`sheet_tall` under `Combo`).
- A strip shows whole flaps only (`strip.gd`): it moves a flap at a time,
  rests with a flap's start at its near edge, keeps the current flap in view
  after any move, and covers an end with more beyond by the look's
  `more_before`/`more_after` under `Scroll` (`more_room` wide).
  `clipped_text.gd` names words part-cut at a strip's edge and spares words
  wholly scrolled away; in a list it spares words cut at an edge the list
  can still scroll toward and names those where it cannot. The kept offset
  of a scroll is `scroll_kept.gd`'s.
- The focused row of any list that runs down is shown whole: moved onto by
  the pad or keys, and after Back once the scroll is put back - which wins
  over the offset kept; scrolled by hand, it is left alone. A virtual list
  moves one whole row when the pad passes its last or first slot.
- A line leaves room for what a neighbour draws past its edge only where a
  shadow falls across the words' letters, reading the box a face stays in -
  `Face.get_drawn_box()` - never one it only passes through; the lines are
  collected by `flex_lines.gd`, the reach measured by `drawn_reach.gd`.
- What arrives: `ui.area(action, shows, style, takes_focus)` (area.gd), words
  typed over many lines, growing between the look's `least_lines` and
  `most_lines`, Enter a new line - `TextArea.make` sends them by its own
  press; `landing.gd`, a model a place's handler asks first, refusing "still
  loading" until `land(token)` under the stay it began, and
  `Loading.mark`/`shapes`/`until`; `notifications.gd`, made by the
  application before the sounds - `notify(words, offer, payload)`, each
  staying the Motion token `notice_stays`, dismissed by `DISMISSES
  {"notice"}` or its offer done - drawn by `NotificationTray.make` in room
  the layout leaves, the sounds playing `NOTIFIED` as one arrives. An app
  composing the tray declares `DISMISSES` and every offer in its register.
  Their looks are `theme_arrivals.gd`'s.
- Running words with links: `ui.paragraph(spans, style)` (paragraph.gd)
  shapes phrases, data and inline pressables as one paragraph, the pad and
  Tab walking its links in reading order, a language change re-laying it in
  place; `ui.link(action, entity, words, goes_to)` is an entity named in
  them, carrying `{"parameter": id}`. `Chip.make` (chip.gd) is the filter
  set's chip made public, and `Divider.across`/`down` (divider.gd) a rule
  between parts; their looks are `theme_marks.gd`'s. `clipped_text.gd` and
  `drawn_over.gd` judge a paragraph's laid-out lines; the convention lint's
  "sets no font size" matches only a size set, never one read.
- The value controls: `ui.slider(action, value, minimum, maximum, step)`
  (slider.gd), `Stepper.make`, `Combo.short`/`long`,
  `InlineChoice.radios`/`segments`; a field may carry what its line means
  (`"carries"`), and `TypeAhead.make` where a pick then goes (`then`).
- The descriptions of what the reader puts in - `draggable`, `drop_target`,
  `field`, `key_capture`, `slider` - are `describe_inputs.gd`'s, between
  `describe.gd` and `describe_places.gd`; the builder's vocabulary is the same.
- Every undecided number of the floor's look is in `theme_placeholders.gd`
  (`Placeholders.put(theme)`), no longer `Theme._placeholders()`; the
  value controls' looks are dressed by `theme_values.gd`.
- `Sounds.SETS_VOLUME` takes `{"value": 0..1}`, the payload a settings
  choice carries, as the language's change does; `{"volume"}` is gone.
- What an input is called is a phrase: `Inputs.words_of()`, `get_hint()`
  and `hint()` hand back a `Phrase`, or `null` where the action has no
  input; a pad button no pad names is `Phrase.with("button %d", [n])`.
  `Hint.make` no longer wraps it.
- A binding at rest takes no key: `key_capture` takes input only while it
  listens, and at rest asks the door about `{"action": the action it
  binds}`; `input_map.would()` reads the event only when one is carried.
- `Motion.REDUCES` is answered from anywhere: `Application` registers it
  with the door beside the language, sounds and inputs.
- Whoever puts a look on dresses it for the script of the language on: the
  application at start.
- `Queries.route` tells the states it has searched apart by where the
  reader is, what stands over it, what each place last showed and with
  what - never by the history behind, which every move lengthens: a way to
  an action nowhere to be reached is given up once every state has been
  searched from once, where it searched every order of every move to its
  depth and the frame never ended (a guide after an act was cancelled).
- A count of none can say words of its own: `Phrase.counted(one, many, n,
  zero)`, said before any plural, since English's rule has no zero form. The
  type-ahead and the filter set say "no matches", the sections "no items".
- The console's words are data, never translated: only a developer reads it.
- Fonts are the look's: `Look.fonts(theme, by_script)`, `Look.dress(theme,
  script)`, `Look.FONTS`, `Look.LATIN`; `script_fonts.gd` is gone. The look's
  box-making half is `look_boxes.gd`, which `look.gd` extends. The language
  names only the script it is written in.
- `words/fr.po` is an unreviewed placeholder until a translator reviews it:
  said at its top, and `#, fuzzy` on its header.
- The translators' templates, `words/gd-chime.pot` and `demo/words/demo.pot`,
  are written from the code by `checks/words_template.py`, whose `--check`
  (run at every commit) fails on any English phrase missing from them. A
  constant whose values are English phrases kept as data is named `..._WORDS`,
  since a constant cannot call `Phrase.of`: `FilterSet.COMPARISONS` is
  `COMPARISON_WORDS`, `LineChart.MARKERS` is `MARKER_WORDS`; and three that are
  not phrases were renamed off the ending - `Language.FLOOR_CATALOGUES`,
  `Inputs.PAD_NAMES`, `DevCommands.TYPE_SAID`.
- A catalogue that does not read as one is refused before the engine is
  asked, and said in our words, never the engine's own complaints.
- Motion's run is `run.gd` (`Motion.Run` still names it), with `get_past()`
  and `restart(from)`; what a keyframe may set is `keyframe_property.gd`. A
  repeating track keeps time with the clock - time carried past a frame's end
  goes into the next - and a track that runs for ever follows reduced motion
  turned on or off at once.
- The tab strip keeps the current flap in view after any move and cuts no
  flap at its far end; `ui.scroll` brings a name that moves on navigation into
  view after the move, and places its content at the bar's exact offset.
- A move is one sound: whatever the driver rang in a frame is heard once, at
  the frame's end, the app's path moved winning over a pop-up lowered on the
  way - a question confirmed sounds only the move it held. The look's sounds
  are kept by `look_sounds.gd`: `LookSounds.set_sound` and `get_sound` replace
  `Sounds.set_sound` and `Sounds.get_sound`.
- A root lowered lets the parameters of its places go: a lowered pop-up has
  no view to be one of its kind in, so nothing of it lingers in the state.
- `Chimes.listen` refuses a second name across every region, and says why:
  `heard()` is handed the name alone.
- THE HISTORY RETRACES EXACTLY, as a browser's does: every arrival in the
  app adds an entry - no cut back to a view walked already - unless it is
  the view the newest entry is; Back pops the newest and arrives at the one
  beneath with its parameters; past `Chart.HISTORY_CAP` (50, a placeholder)
  the oldest is dropped. The state gains `history_ids` - each entry's
  serial - and `serial`, the last issued; `Paths.walked(state, landing,
  params, cap)` answers all four. `Kept.entry_of(state)` is the newest
  entry's serial, so two visits to one view keep their own, and whatever was
  kept with an entry dropped - gone Back past, over the cap, forgotten - is
  let go. A fresh visit lands fresh: a scroll or a virtual list whose place
  was entered afresh stands at its top, one whose place stayed (a strip in
  the frame) is left as it stands.
- NOTHING IS DRAWN OVER ANYTHING ELSE, as a check (`drawn_over.gd`,
  `DrawnOver.covered(root, window)`) beside `clipped_text.gd`, and a probe
  claim, `nothing_drawn_over`, at every shape. `Surface.get_style()` answers
  the style a surface was described with, whatever the look wears.
- A frame after the window turns, everything standing on it measures
  again (`shape.gd`): what the turn re-arranged out of sight tells nobody,
  and a page grown for the other way round kept that height.
- WORDS ARE TRANSLATED BY THE TEXT ALONE, AS IT DRAWS, AND ENGLISH WORDS
  ARE PHRASES; DATA IS NOT. A text says a `Phrase` (`phrase.gd`) - a key,
  a pattern with its data, a count, a key's name, a number, money or a
  date, words joined to a mark - in the language on, and shows anything
  else, a string above all, as it is. Every word written for a reader is
  written as one: `Phrase.of("save the day")`, or `Phrase.with("%s is not
  on top", [name])` with data in it. `ui.words(action)` returns a phrase of
  the register's English; a recipe's word parameters - a label, a says, a
  heading, a column's words, a countdown's `then` - take a phrase or data.
  THE DOOR'S ANSWER IS A PHRASE OR NULL: `would`, `told`,
  `Commands.refusal`, `game_refusal` and `dispatch`, a chart's and the
  driver's refusals, `ActionControl.get_reason()`/`get_refusal()`, the leave
  guard's words; nothing refused is `null`, and a caller asks `answer ==
  null`. Printed, a phrase is its English, for a log or a test. `ui.language`
  (`language.gd`) reads a catalogue by key (`words/fr.po`), rings
  `LANGUAGE_CHANGED`, answers `Language.CHANGES_LANGUAGE` from anywhere,
  reports a missing key once, and has a pseudo-locale; a look names a font
  per script (`Look.fonts`, since moved into the look); `formats.gd` writes numbers, money and dates
  the language's way.
- `Ui.declare` is `PlaceBuilder.declare(ui, desc, place)`: a place declares
  what it performs where places are built.
- THE BUILDER MAKES THE FLOOR'S OWN and puts them under the root as it is
  built: `ui.motion`, `ui.carried` (carried.gd), `ui.shape` (shape.gd). A
  test that builds a `Ui` by hand frees all three. `ui.inputs` (the map of
  inputs) is handed in by whoever composes the application;
  `Application` and the test fixture make it and the shortcuts node.
  The places' descriptions moved to `describe_places.gd`, which `ui.gd`
  extends; `describe.gd` keeps the rest.
- An input map for actions: `actions.declare(action, words, [Inputs.key(KEY_S),
  Inputs.pad(JOY_BUTTON_Y)])` - an input says which device it is, since a
  key's and a pad button's numbers overlap. `input_map.gd` holds what is
  bound, the device last used, `BINDS {action, event}` and
  `RESTORES_DEFAULTS` through the door, `saved()`/`restore()` as plain
  data; `shortcuts.gd` presses an unhandled key's action THROUGH the control
  that draws it in the nearest place on the top path declaring it
  (`Index.drawn_by`), so a refusal lands on that button; a typed line and a
  waiting binding take the event first; an action whose press carries a
  payload is reported, never pressed. `Hint.make(ui, action)`. Two actions
  on one input reachable at once are reported as bound and at startup.
  `key_capture` carries which action it rebinds (`Setting.binding(ui,
  action, bound_to, rebinds)`).
- Drag and drop: `ui.draggable(payload, content)`, `ui.drop_target(action,
  content)` - a drop target is an action control its place declares, the
  door's `would` with the carried payload decides accepting or refusing
  (states of those names, and `lifted`, under a pressable's style), a drop
  dispatches once in the target's region. Mouse by the engine's own drag;
  pad and keys lift with accept, walk across targets only, drop with
  accept, put back with cancel. A scroll moves while something is carried
  near its edge (`drag_edge`, `drag_edge_speed` under `Scroll`).
- Layout by shape: `ui.shape` answers `orientation` and `size_class` on
  bells `TURNED` and `RECLASSED`, once per change, holding a class by the
  look's `dead_band` (Theme type `Shape`: `compact_below`, `wide_from`); a
  turned window turns the stretch base size too. `ui.by_shape(parts,
  arrangements, reads)` and `ui.by_width(parts, arrangements, breakpoints)`
  arrange THE SAME PARTS, built once: only direction, order, style and
  facts change, so state, focus and places survive a turn.
- Keyframes: `ui.keyframes(content, frames, lasts, easing, timed_by, loops,
  held, after)` - opacity, scale, slide and turn off one track, holds and
  loops, on the one clock; `ui.pulse` is one named track of it, so a test
  of a pulse turns the clock by hand. The moment's entrance, the idle
  breathe (`Attention.breathing`) and the countdown's last seconds are
  tracks.
- Each stall look says how it moves (`DemoTheme.moves(durations, easings,
  swaps)`), and wears a palette turned for an eye (`looks/palettes.gd`,
  `looks/sight.gd`; `Looks.new` takes the sight, `Looks.make(look, sight)`).
  A table reports, in a developer's build, two values it dresses
  differently under the same mark (`format_marks.gd`). The console command
  `sight <plain|deuteranopia|protanopia|tritanopia>` lays a simulation of
  that eye over the screen (`simulated_sight.gd`).

## 0.28.0 - 2026-09-17

Navigation is three structures - the index, the state and the chart - and
every feature is a question asked of them.

- `history.gd`, `routes.gd` and `links.gd` are gone. The history is in the
  chart's state: `Chart.transition` takes ARRIVE, BACK, RAISE, LOWER and
  FORGET (`Events.Event.forget()`), Back and Forget carrying nothing;
  `Chart.can_go_back(state)`; the state holds no node. `Driver.new(chimes,
  commands)` has `index`, `get_state()`, `path_of`, `get_top`, `is_raised`,
  `can_go_back`; `FORGETS` is its fifth command. `NAVIGATED` rings as before.
- `index.gd` (`Index`) is what exists: places and action controls enter it
  from the tree; `place_named`, `has_place`, `is_place`, `is_control`,
  `is_link`, `place_of`, `place_above`, `controls_of`, `links_in`,
  `controls`, `places`, `refused_names`, `is_reachable`, `chart()`; its
  bell `Index.CONTROL_CHANGED` rings as a control's pressable answer flips.
  `Place.is_place`, `Place.place_of`, `Place.pressable`, `Actions.group_of`
  and the engine groups are gone; a control answers `is_pressable()`.
- `queries.gd`: `Queries.reachable(index, chart, control, state)`,
  `Queries.route(index, chart, state, action, back)` by making the moves
  through the transition, `Queries.event_of`, `Queries.path_to`.
- A press that carries `goes_to` is handed to the driver by the commands
  once its handler, if any, has not refused: a link needs no handler, and
  the per-link registration is gone. The door is built with its mover,
  `Commands.new(chimes, driver)`, and registers the driver's five commands
  itself, now named for code and the console: `arrive_at`, `go_back`,
  `raise_up`, `lower_down`, `forget_the_way_back` (`Driver.COMMANDS`). A
  button navigates by its `goes_to` alone, under an action of its own; the
  startup check reports one whose action is a driver command. `Driver.new(
  chimes)` takes no commands. `Driver.is_reachable(control)` is the one
  answer, and a place exposes `driver` beside `index`.
- `StartupCheck.broken(index, actions)`; `Closing.close(chimes, commands,
  index, place)`; `Console.new(chimes, commands, debug_log, driver)`;
  `Guide.new(..., driver)` without the history; `Place.new` keeps its shape
  and exposes `index`.

## 0.27.0 - 2026-09-17

Reachable means the player can press it; the statechart's words are typed;
an action's group is named by the register.

- `Driver.is_reachable(control)` and `Routes.way` answer only for a control
  the player can press: shown up to its place and usable (`Place.pressable`).
  A control rings `Driver.CONTROL_CHANGED` as that changes; the guide and
  the reminders listen to it beside `NAVIGATED`.
- `chart.gd`'s events and effects are typed (`events.gd`): `Events.Event`
  built by `arrive`, `back`, `raise` or `lower`, `Events.Effect` with a
  `Doing`, and `Chart.transition` takes an `Event`; the effect-kind and
  event-kind constants on the chart are gone. A link's press is read by
  `links.gd`.
- An action's engine group is `Actions.group_of(action)`, never the bare
  name: everything that joins or asks for one calls it.
- `History.arrive` at a path walked already cuts the history back to it.
- The chimes keep wires by listener, and a controller or presentation cuts
  itself loose as it is freed; `Chimes.count_listeners()` reads that.
  `Chimes.RESERVED` names the regions no place may be named after, and the
  startup check reports one that is.
- `Commands.get_last()` read while a command runs is that command, its
  answer still empty.

## 0.26.0 - 2026-09-17

A state remembers the child it was last on.

- `chart.gd`'s `resolved` moved to `paths.gd` as `Paths.resolved(chart,
  state, path)`, taking the state, since where an arrival lands now depends
  on what each state was last on; the state value gains `last`. Entering a
  screen enters the tab it was left on, else its first.

## 0.25.0 - 2026-09-16

The interface is a statechart: the driver, the chart and the applier take
the layers' place, and navigation goes through the command door.

- `layers.gd` is gone. `driver.gd` (`Driver.new(chimes, commands, history)`,
  attribute `app`) keeps the state, answers `ARRIVES {path}`, `GOES_BACK`,
  `RAISES {place}` and `LOWERS {place}` and every link action it is
  registered for, and rings `Driver.NAVIGATED` once per transition where
  `LAYERS_CHANGED` rang; `Routes.BACK` is `Driver.BACK`. `path_of`,
  `get_top`, `is_reachable`, `is_raised`, `can_go_back`, `index`, `unindex`
  and `find_place` read as before. Nothing arrives on the history directly
  any more: the driver adds to it.
- `place.gd` is passive: `Place.new(chimes, name, driver)`, no listening, no
  `opens_on()`, `_on_path` gone; `blocks` says whether a root blocks what
  is beneath, `token` is the token of the reader's stay (`token.gd`), and
  `Place.place_of(node)` and `place_above()` find places. `fill()` and
  `empty()` are called by the applier in the fixed order.
- `long_list.gd` looks under a token: `look(token)`; the generation is gone.
- `console.gd` is the panel, blocking nothing; F10 dispatches `RAISES` and
  `LOWERS` for it.
- `guide.gd`, `reminders.gd`, `routes.gd` take the driver where they took
  the layers, and `action_control.gd`'s `payload()` carries `goes_to`.

## 0.24.0 - 2026-09-16

The console is a pop-up place on the layers.

- `console.gd` is built `Console.new(chimes, commands, debug_log, history,
  layers)` - the listening and the region are gone from its constructor, as
  it listens for the log and the history itself and its region is its place
  name, `Console.CONSOLE`. It sits beside the app under the window, F10
  raises and lowers it through the layers, and an arrival lowers it as it
  lowers any pop-up.

## 0.23.0 - 2026-09-16

The long list loads when shown.

- `long_list.gd` no longer asks the source for anything as it is built. Call
  `look()` to start it asking for the look's pages - the place it sits in
  calls it from `fill()` - and `drop()` to forget everything but the look,
  from `empty()`. A builder that relied on the first pages being asked for at
  once now calls `look()` after building.

## 0.22.0 - 2026-09-16

One tree, and the nodes are it: the map is gone.

- `map.gd`, `map_links.gd`, `map_screens.gd`, `map_routes.gd`, `showing.gd`
  and `switcher.gd` are gone. Nesting is parent and child; a place is a node
  (`place.gd`, `Place.new(chimes, name, layers)`) whose unique name is its
  identity and its region; a control carries `action` and `goes_to`
  (`action_control.gd`) and is in the engine's group named for its action.
- `identity` is gone from `presentation.gd` and `controller.gd`, and with it
  the group a screen joined. A place's name is its identity.
- `actions.gd` is new: `declare(action, words)`, `has()`, `get_words()`,
  `get_all()` - the one register outside the tree. `prompts.gd` is made with
  `new(chimes, actions, sources)`, `taken.gd` with `new(chimes, actions,
  commands)`; each refuses a name that is no action, and whether any control
  performs one is `startup_check.gd`'s: `StartupCheck.broken(window,
  actions)`, run once when the structure stands.
- `history.gd`: a view is a path, `Array[StringName]` of place names root
  down; `arrive(path)`, `get_current()` a path, `get_paths()` in place of
  `get_views()`.
- `layers.gd` is new: `Layers.new(chimes, history)` with `app` set before
  the first arrival; `path_of(node)`, `get_top()`, `is_reachable(node)`,
  `raise(pop_up)`, `lower()`, `is_raised()`, `back()`, `can_go_back()`,
  `find_place(name)`, `LAYERS_CHANGED`. Only the layers hear the history;
  every place hears the layers.
- `routes.gd` replaces `map_routes.gd`: `Routes.way(layers, history,
  action)`; `Routes.BACK` is where a control goes back.
- `guide.gd` is made with `new(chimes, commands, actions, prompts, source,
  steps, layers, history)` and `reminders.gd` with `new(chimes, taken,
  prompts, source, random, layers)`.
- `closing.gd`: `Closing.close(chimes, commands, place)` takes a place's
  subtree out and frees it, every region beneath dropped.

## 0.21.0 - 2026-09-15

An interruption borrows the reader, and the switcher says what can be
reached.

- `guide.gd` is made with `new(chimes, commands, map, prompts, source, steps,
  switcher, path_back)` and `reminders.gd` with `new(chimes, map, taken,
  prompts, source, random, switcher)`: the addresses at which a screen
  arriving rings are gone from both. Each listens to the switcher's
  `SHOWING_CHANGED` and asks `is_reachable()` for what is on screen - never
  the engine directly - so nothing beneath an interruption is pointed at or
  chosen.
- `switcher.gd`: `interrupt(screen)`, `restore()`, `get_interruption()` and
  `is_reachable(identity)`; its `app` attribute is the node every screen
  hangs from, switched off while an interruption is up - set it before any,
  and hang a pop-up beside it, never under. `map.gd`: a screen may say
  `interruption`.
  `map_screens.gd`: where a screen opens skips interruptions as it skips
  screens always on.

## 0.20.0 - 2026-09-15

Screens nest the way the blueprint says, and the way there knows it.

- `map_routes.gd`'s `way()` answers differently: a hop - forward or Back -
  lands on everything an arrival puts on screen, the tab the screen opens on
  included, so a route through a default tab is one hop shorter than it was,
  and a screen is reached once per count of Backs, so the way home from a tab
  is two Backs where it used to be none. A caller written against the old
  routes reads a different way.
- `map.gd`: a screen item may say `always_on`; a part that is not a screen
  saying it is refused, and `map_links.gd` reports a link that goes to one.
- `map_screens.gd` is where a screen opens: `opens_on(map, screen)` and
  `shown_on_arrival(map, screen)`.
- `switcher.gd` is new: `Switcher.new(chimes, map, history)` shows and hides
  screens as the history's path changes, rings `SHOWING_CHANGED` once it has,
  and answers `is_hidden(screen)`. Anything reading what is on screen when
  the reader arrives listens to it, not to the history.

## 0.19.0 - 2026-09-14

What an action does is said once, on the map.

- `map.gd`: `add_action(action, words)` declares an action with its words
  before any part performs it; a part naming an action not declared is
  refused. `get_words(action)` reads them.
- `prompts.gd`'s `raise(source, action)` takes no words; `get_words()` is the
  map's for the glowing action.
- `taken.gd`'s `track(action)` takes no words, and its `get_words()` is gone.
- `guide.gd` is made with `new(chimes, commands, map, prompts, source, steps,
  path_back, arriving)`, `steps` an array of actions; a hop on the way is
  raised in the map's words for it.

## 0.18.0 - 2026-09-14

The way to an action starts from everything showing, and Back is a link.

- `map.gd`: `goes_to` may be `Map.BACK`, a part that takes the reader back to
  where they were; no item may have that word as its identity. `map_links.gd`
  lets such a link stand.
- `map_routes.gd`'s `way(map, showing, path_back, action)`: `showing` is a
  function answering whether an identity is on screen, `path_back` the screens
  beneath the player on the history's path, nearest first. The screen it was
  given before is gone.
- `guide.gd` is made with `new(chimes, commands, map, prompts, source, steps,
  path_back, arriving)` - `path_back` a function returning those screens - and
  asks the engine what is showing, so it must be in the tree; it points at its
  first step as it enters.
- `showing.gd` is new: `Showing.is_showing(tree, identity)`.

## 0.17.0 - 2026-09-14

A reminder comes when a screen arrives and when the reminded action is taken,
never on a clock.

- `reminders.gd` is made with `new(chimes, map, taken, prompts, source, random,
  arriving)`: the addresses at which a screen arriving rings, the history's
  `PATH_CHANGED` in an application. Any of them heard reminds; the reminded
  action taken reminds again at once, where it used to withdraw and wait.

## 0.16.0 - 2026-09-14

The console commands a typed line through the door.

- `console.gd` is made with `new(chimes, commands, debug_log, history,
  listening, in_region)`: the dev commands it was handed are gone. A submitted
  line is dispatched as `DevCommands.RUN_LINE` with `{line}`; register the dev
  commands for it, globally, when composing.
- `dev_commands.gd` has `told(RUN_LINE, {line})`, which runs the line and
  answers done; `run(line)` is unchanged.

## 0.15.0 - 2026-09-14

What the player has ever done is its own file, so the map holds only what is
declared.

- `taken.gd` is new: `Taken.new(chimes, map, commands)` carries `track(action,
  words)`, `get_words()`, `set_taken()`, `get_taken()`, `take()`, `untaken()`
  and the bell `ACTION_FIRST_TAKEN`, all gone from `map.gd`, which is made with
  `new(chimes)` again and hangs no bell.
- `reminders.gd` is made with `new(chimes, map, taken, prompts, source, random)`.

## 0.14.0 - 2026-09-14

A prompt names an action; a bell has to be hung before anything listens.

- `prompts.gd`'s `raise(source, action, words)` takes an action some part in
  the map performs; `get_glowing()` is that action. A control glows while the
  prompts name its `action`. `reminders.gd` raises the action it chose.
- `chimes.gd`'s `listen()` refuses out loud an address nobody has hung;
  `drop_region()` takes every bell in the region and every connection of a
  listener belonging to it or listening into it. `belfry.gd`'s `at()` no
  longer hangs a bell, and `drop_region()` keeps nothing. Hang a model's bells
  before building what listens to them.
- `commands.gd` refuses out loud a `dispatch()` made while `COMMAND_RAN`
  rings. Defer it with call_deferred, which runs at the end of the frame.
- `action_control.gd`'s `heard()` clears the refusal and asks for a draw;
  a subclass that overrides it calls `super`.
- `map.gd` gains `performs(action)`, and records only an action some part
  performs.

## 0.13.0 - 2026-09-14

A command goes through one door and is never a bell, and a screen only draws.

- `commands.gd` is new: `register(region, action, model)`, `dispatch(region,
  action, payload) -> String`, `get_last()`, `handles()`, `drop_region()`,
  and the bell `COMMAND_RAN`. A model told a command has
  `told(action, payload) -> String`, empty when done, the reason when refused.
- `action_control.gd` and `bell_button.gd` are made with the commands after
  the chimes: `new(chimes, commands, ...)`. Set `action` as you set
  `identity`; a usable press dispatches it in the control's region and hangs
  and strikes nothing. `get_refusal()` is the last press's answer. A subclass
  overrides `payload()` for what its press carries.
- `map.gd` is made with `new(chimes, commands)`, listens to `COMMAND_RAN` and
  takes the action of a command that was done. It no longer listens at part
  identities, and `add()` no longer refuses a part with an action and no
  screen above it.
- `long_list.gd` owns the look: made with `new(chimes, commands, fetch, page,
  keep, showing, listening, in_region)`, registered in its region for
  `SCROLL_ROW_UP`, `SCROLL_ROW_DOWN`, `SCROLL_PAGE_UP`, `SCROLL_PAGE_DOWN`,
  `SCROLL_ROWS` (payload `by`) and `ASK_AGAIN`; `get_first()`,
  `get_showing()`; rings `LOOK_MOVED` and `FAILURES_FORGOTTEN`. `look_at()`
  and `ask_again()` are gone: dispatch the commands.
- `long_list_presentation.gd` is made with `new(chimes, commands, list,
  in_region)` and holds nothing: the command bells, `FIRST_ROW_MOVED`,
  `get_first_row()` and `get_slots()` are gone. Read the list.

## 0.12.0 - 2026-09-14

Every control that performs an action strikes its own address, so nothing
hands it one.

- `bell_button.gd` is made with `new(chimes, face, in_region, usable,
  listening)`: the address it struck is gone. Set its `identity`; a press
  strikes `[its region, its identity]`, so whatever carries the action out
  listens there. An identity named for the bell that was handed in keeps the
  same address.
- `action_control.gd` is new: the press, the question of whether it can be
  used, and the prompts, for any control with an action. `bell_button.gd`
  extends it; `is_usable()`, `get_reason()` and `is_glowing()` are what a
  control of your own reads when it draws.

## 0.11.0 - 2026-09-14

A part that performs an action is heard where its control strikes, so the map
records the action taken without the control knowing the map.

- `map.gd`'s `add()` refuses a part with an action that has no screen above it
  - an item whose `component` is `&"screen"` - since its bell has nowhere to be
  heard. Put such a part inside a screen; the nearest screen's identity is its
  region.
- The map listens to every part with an action as it is added, at
  `[its nearest screen's identity, its own identity]`, and takes the action when
  that bell is struck.

## 0.10.0 - 2026-09-14

A listener can arrive before the bell it listens to is hung, and keeps hearing
a region that is dropped and made again.

- Listening at an address nobody has hung hangs the bell there; hanging it
  afterwards is not refused. Only hanging an address its striker already hung
  is refused.
- Dropping a region cuts the connections of listeners whose `region` is that
  region, and forgets its bells - except a bell a listener belonging elsewhere
  still hears, whose connection is kept. A listener with no `region` belongs to
  none and is never cut by a drop; the engine still drops it when it is freed.
- `belfry.gd`'s `drop_region()` takes the names to keep.

## 0.9.0 - 2026-09-14

The check on the map's links is its own file, so the map holds only its records.

- `map.gd`'s `get_broken_links()` is gone. Call `MapLinks.broken(map)` from
  `map_links.gd` instead; it reports the same sentences. `get_identities()` is
  new on the map.

## 0.8.0 - 2026-09-13

An action worth reminding the player of is declared with the words that say
what it does.

- `map.gd`'s `track(action)` is `track(action, words)`. Pass what the action
  does, once per action however many parts perform it; `get_words(action)`
  reads it back.

## 0.7.0 - 2026-09-13

A control glows when the prompts name it, and in no other way.

- `glowing(on)` is gone from `interaction.gd` and `bell_button.gd`. Set a
  button's `identity` and its `prompts`, and raise a prompt at that identity
  with `prompts.gd`; the button glows while the prompts name it. A control of
  your own that drew a glow reads `get_glowing()` from the prompts it is given,
  when it draws.

## 0.6.0 - 2026-09-13

A wake arrives at `heard()` and nowhere else: the chimes call it directly.

- `on_change()` is gone from `controller.gd` and `presentation.gd`, and the
  chimes no longer call it. A controller or a screen changes nothing: it
  overrides `heard()` as before. A listener of your own that is neither renames
  its `on_change(what)` to `heard(what)`.

## 0.5.0 - 2026-09-13

A page the long list's source could not give is remembered, so a screen can
show the failure where the rows would be.

- `long_list.gd`: a page that could not be given is no longer asked for again by
  the next look that covers it. Call `ask_again()` to try again. `PAGE_FAILED`
  rings when a page could not be given, and `has_failed(index)` says which rows.

## 0.4.0 - 2026-09-13

The job pool no longer holds the busy gate. Busy means the player is waiting,
and work on the pool is waited on only sometimes, so whatever the player is
waiting on holds the gate itself, for the whole of the wait.

- `jobs.gd` is made with `new(chimes, budget, ceiling, depth, inline)`: the busy
  gate it used to be handed is gone.
- `jobs.gd`'s `HOLD` is gone. Take a hold of your own, named for what the player
  is waiting on, where the wait begins, and release it where the wait ends.

## 0.3.0 - 2026-09-13

The map now holds which actions are tracked and which have been taken, so
`action_registry.gd` is gone. The map, the history, the debug log, the busy gate,
the frame budget, the downtime drain and the job pool - one of each per
application - all belong to the global region instead of one their builder chose.

- `action_registry.gd` is gone. `track()`, `take()`, `untaken()` and
  `get_taken()` are on `map.gd`; hand the player's record to `set_taken()`
  instead of to a constructor, and listen for `ACTION_FIRST_TAKEN` on the map.
- `map.gd` is made with `new(chimes)` instead of `new()`, and is now a node, so
  whoever makes it frees it.
- `history.gd` is made with `new(chimes)`; it no longer takes a region.
- `debug_log.gd` is made without its last argument, the region.
- `busy.gd` is made with `new(chimes)`, and `frame_budget.gd`, `downtime.gd` and
  `jobs.gd` without their last argument, the region.
- Listen for `ACTION_FIRST_TAKEN`, `PATH_CHANGED`, `ENTRY_LOGGED`, `BUSY_BEGAN`,
  `BUSY_ENDED`, `FRAME_OVERRAN` and `FRAME_RECOVERED` in `Chimes.GLOBAL`.

## 0.2.0 - 2026-09-13

`action_registry.gd` records only what the player has done; which part performs
which action is declared in `map.gd`.

- `register()` is gone. Give the part's item an `action` in the map instead.
- `controls_offering()` is gone, and nothing replaces it yet. Which parts
  perform an action is declared in the map.
- It is made with `new(chimes, already_taken, region)` instead of `new()`, and
  is now a node, so whoever makes it frees it.

## 0.1.0 - 2026-09-13

Where recording starts: the folder as it stands. Nothing is listed, because
there is no earlier version for anything to break against.
