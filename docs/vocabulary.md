# The vocabulary

Every name an application may use, by family, each with what its own file says it is.
Written from the code by `checks/vocabulary_page.py`, never by hand; `GdChime.<Name>` is how an application reads one.

## The kinds a description may be

What `ui.<kind>(...)` describes and the builder turns into a node (`floor_kinds.gd`).

### the kinds

- `text` - Words: a phrase, data, or a bound value read again whenever what it read moves - a phrase said in the language on as it is drawn.
- `reason` - Words: a phrase, data, or a bound value read again whenever what it read moves - a phrase said in the language on as it is drawn.
- `image` - A picture: a texture, or a bound value read again whenever its bells ring, drawn to fit its room and keeping its shape.
- `surface` - A ground: a stylebox drawn under whatever it holds, by a Theme name.
- `paragraph` - Running words: spans one after another, wrapped as a paragraph at the width it is given - phrases, a model's data, and links among them, each link a pressable laid in the line where its words fall.
- `pressable` - Something pressed: a control performing one of its place's actions, drawn in the state it is in, holding whatever content it was described with.
- `press_local` - A local press: a face whose press sets a local, and does nothing else.
- `draggable` - Something a reader can pick up and drop somewhere else: a face, focused and drawn like any other, that hands what it carries to whatever takes it - and, described with an action, is pressed as well as carried.
- `drop_target` - Somewhere a carried thing can be dropped: an action control whose action is dispatched with whatever was dropped on it - and, standing for a list, with where among the list it landed.
- `field` - A line a person types: Enter dispatches the action with the line, and the line is cleared once the action is done.
- `area` - An area a person types in: words over as many lines as they take, broken at the width it is given, growing as they grow to the most lines its look allows and scrolling past that.
- `row` - A row or a column: the line layout (flex.gd) with its gap a Theme name.
- `column` - A row or a column: the line layout (flex.gd) with its gap a Theme name.
- `grid` - A grid: the column layout (grid.gd) with its gaps Theme names and its columns declared as shares - one set of them, or one per shape of window.
- `stack` - Pieces over one another, each across the whole of this, the last on top.
- `scroll` - A window onto one piece taller or wider than the room: the engine's own scrolling, by wheel, drag and bar; and, given a bound value naming a piece, scrolled to bring that piece into view whenever the name moves - the reader's own row on a board.
- `virtual_list` - A window of slots over a long list: one piece per visible slot, built once, each slot told its row again only when what it shows has changed.
- `cells` - A line of cells at their columns' widths, on a ground: a table's heading line and every one of its rows, laid out alike so each cell stands under its heading - and WHAT A CELL SAYS NEVER MOVES the line.
- `view` - A sub-viewport: a world of its own drawn inside the interface, holding whatever it was described with.

### the two ways out of the described world (describe_escapes.gd)

- `themed` - A subtree wearing a look of its own: the Theme it is given is set on this, and the engine carries it down to everything built inside, so one part of a screen is drawn in another design language while the rest keeps the root's.
- `embed` - A Control the framework did not build, placed inline among ones it did: the escape hatch. Whatever the engine draws that no primitive of ours wraps - a viewport, a third party's widget, a node a game already has - stands in a row or a column beside described pieces, taking its facts (grow, basis) as any part does.
- `canvas` - Custom drawing: a function handed this control to draw on, called again whenever the bound value it reads has changed.
- `anchored` - A piece attached to another control: drawn just above that control's rect, as wide as it, wherever it ends up, following it every frame.
- `each` - One piece per item of a bound array, down a column or along a row: the template asked for a description per item, given a handle to the item, never the item; the pieces kept by key as the array moves.
- `when` - One of two descriptions, by a bound value: the first while it is true, the other while it is not, swapped as the value changes.
- `by_shape` - The same parts arranged differently by the shape of the window: a row that becomes a column, a wide layout that stacks.
- `by_width` - The same parts arranged by the width THIS has, not the width the window has: a card that stacks itself when it is put in a narrow column, beside another of the same card that stays a row because its column is wide.
- `pulse` - A pulse: what it holds fades and returns, over and over, while a bound value holds - the flash of attention on a control.
- `keyframes` - Keyframes: what it holds carried through a track of frames - opacity, scale, slide and turn moving together - on the one clock.
- `pan_zoom` - A canvas the reader moves: dragged by its empty space it pans, turned by the wheel it zooms, and a press on it picks whatever is under the pointer - each a command to the model that holds the view.
- `pinned` - A drawing with parts pinned on it: a map, and a press standing on each of its regions. The drawing is a recipe's painter, as a canvas's is; each part stands centred on its own point of the drawing; and a press on the drawing itself picks whatever its hit function says lies there.
- `areas` - Named areas: the same parts laid into a grid of areas that each name a part, the grid chosen by the width THIS has - a dashboard's figures along the top and its charts under them on a wide screen, one over another on a narrow one - so the hierarchy is written once per width and kept.
- `key_capture` - A binding: a control that, pressed, listens for the next key or button and hands it to its action - rebinding - showing what is bound while it rests and what it is waiting for while it listens.
- `slider` - A slider: a value along a track, between a minimum and a maximum, moved by the step it is given, every change a command through the door.
- `swipe` - A row a finger swipes: drawn across, what it holds slides with the finger and uncovers, on the side it leaves, what letting go there will do - in words and a mark, never a hue alone; let go past the look's share of its width, that is done, one command through the door; short of it, the row springs back. Tapped, it is pressed like any pressable.
- `pull` - Pull to refresh: a list drawn down past its top by a finger opens, above it, what says letting go will refresh it; let go far enough, the refresh is one command through the door, and it stays open on what says it is refreshing until the refresh has landed.
- `tray_stand` - What a sample's words are made of: the widest letter, never shown.
- `lazy_image` - A picture that loads as the reader nears it: the look's box standing in until it lands, then the picture filling the box - cut to its shape, never stretched - fading in over it.
- `nearing` - What it holds, pressing an action through the door as the reader nears it: the foot of an infinite collection asking for the next page before the reader reaches the end.
- `range_slider` - A range slider: a stretch between two handles along a track - a price from least to most - every change a command through the door carrying {"value": Vector2(least, most)}.

### a form's pieces (describe_forms.gd)

- `arrival_focus` - Where the focus lands as a place is arrived at: what this holds takes it, while a bound value holds - a question of a form entered as its key, the day a calendar opens on.
- `file_pick` - A press that picks a file: pressed, it opens the engine's own file dialog - the platform's, where it has one - and the file picked goes through the door as its action, {"value": {name, size, kind}}.

### the shell's pieces (describe_shell.gd)

- `split` - A split: two panes side by side, or one over the other, and a grip between them that shares the room out - the resizable panels of an application shell.
- `grip` - A grip: a thin edge the reader takes hold of to resize something - the sash between a split's two panes (split.gd), a column's edge in a table's heading - every move a command through the door.
- `menu_target` - A menu's target: whatever it holds, given a context menu of declared actions - opened by a right press on it, by the keyboard's menu key or a pad button while the focus is inside it (open_menu.gd).
- `anchored_at` - A piece set down beside a rect a bound value reads - under it, or over it where there is no room below, and never past the window - with the rest of the room around it a press that sends it away: a context menu beside what it was opened over.
- `app` - The places' builder: app, screen, tabs and pop_up made as places (place.gd), declaring what their pressables perform and registering their handler for it.
- `screen` - The places' builder: app, screen, tabs and pop_up made as places (place.gd), declaring what their pressables perform and registering their handler for it.
- `tabs` - The places' builder: app, screen, tabs and pop_up made as places (place.gd), declaring what their pressables perform and registering their handler for it.
- `pop_up` - The places' builder: app, screen, tabs and pop_up made as places (place.gd), declaring what their pressables perform and registering their handler for it.

## The names an application reads

A name marked *(lazy)* is fetched the first time it is read, so it is read at run time only:
never as a type (a variable's, an argument's, a return's, an `is`), never inside a `const`, never in `extends`.
A name without the mark is a constant, usable as a type and inside a `const`.

## The recipes, by the family of the look they dress under

### collections

- `Lanes` *(lazy)* - Lanes: a board's lists side by side - each a list target (drop_target.gd) standing for its lane (lane.gd), its heading over the reason it would refuse what is carried and its pieces - the columns of a kanban board.
- `SwipeRow` *(lazy)* - A row of a list with actions a finger swipes to, and the same actions in its menu: drawn right it does one, drawn left another, tapped it does its own - and the keys, the pad and the pointer reach every one of them from its menu, so a swipe is never the only way.

### feedback

- `Avatar` *(lazy)* - An avatar: a person shown by their initials on the look's ground, round.
- `Badge` *(lazy)* - A badge: short words saying how pressing something is - a priority, a deadline - with a MARK beside them saying the same by its shape.
- `Loading` *(lazy)* - Loading: the ONE look of anything on its way from a far side - the MARK, turning, with the words that say so, the SHAPES standing in where the content will land, the FAILURE said on the thing itself with a way to ask again, and, once it has landed, the content.
- `Progress` *(lazy)* - Progress: how much of a whole is done - a title, a bar whose filled length is the share done, and the words saying how many of how many.
- `PullToRefresh` *(lazy)* - A list a finger pulls to ask for what it shows again, over what the place fills with (fetched.gd): what the pull says as it opens - pull, let go, and loading's own mark while it is on its way.

### fields

- `CalendarSheet` *(lazy)* - The calendar's pop-up: the month shown between the presses turning it, the days of the week, six weeks of days to pick from, and a way out.
- `Chip` *(lazy)* - A chip: short words that are toggled on their body, and - given a remove - removed on the x beside them.
- `Combo` *(lazy)* - A combo: a closed field showing the current choice. Pressed, it opens the choosing in an overlay - a choice's short list (setting.gd), or a type-ahead for a long one - and picking closes the overlay, the field showing the new value.
- `CommandPalette` *(lazy)* - The command palette: a pop-up over everything, with a line to type in, how many entries match, and the entries themselves - commands, datasets, files - each reading what it is, what sort of thing, the key it is on and why it cannot be used, if it cannot.
- `FormField` *(lazy)* - One question of a form laid out: its words, what it says under them, the control its kind is answered with, and its message beside it - the whole taking the focus as its step is entered as its key.
- `FormReview` *(lazy)* - What a form says back to its reader: the SUMMARY of what needs attention, each problem a press taking the reader to its question, and the REVIEW of every answer, step by step, each a press taking the reader to change it.
- `FormSteps` *(lazy)* - A form of many steps, whole: the steps along the top, each saying how far the reader is through it, and one screen per step - its questions, a section shown while an answer holds, what needs attention on it, and the ways back, on, out and to save - the last step the review and sending.
- `Stepper` *(lazy)* - A number stepper: a number with a minus before it and a plus after it, typed or stepped, between a minimum and a maximum by a step.
- `TextArea` *(lazy)* - A text area: words a reader writes at length - feedback, a note - under its label, sent by a press of its own. Beside text_field.gd, which is the same shape for one line sent by Enter; here Enter breaks the words, so it cannot send them.

### navigation

- `AdaptiveNav` *(lazy)* - Navigation that follows the window: a bar of destinations at a phone's foot, under what they open; a rail down the side of a tablet's or a desktop's window, beside it - the SAME destinations, built once, only re-flowed (by_shape.gd), so the focus, a scroll and a typed line survive the window turning or widening.
- `Shell` *(lazy)* - The frame of an application shell: the bar of its commands along the top, the work in the middle - its panes (panes.gd) - and its foot: what the application says about itself, and the tray its notifications stand in (notification_tray.gd).

### pressables

- `InlineChoice` *(lazy)* - A short choice laid out inline, with no overlay: a RADIO GROUP, a column of options, and a SEGMENTED CONTROL, a row of joined ones.
- `NavControl` *(lazy)* - A navigation control: a control that takes the reader somewhere - a MENU ITEM to a named place, an INLINE one on any named thing wherever it appears, a BACK that retraces, a PLAY that opens a recording wherever the thing recorded is shown.
- `NotificationTray` *(lazy)* - The notification tray: where the application's notifications stand (notifications.gd), ONE AT A TIME - on one line, the press of its offer when it has one and a press that dismisses it, then its words, then how many more are waiting. The presses lead, at the tray's leading edge, so the pad walking down from what stands above reaches them.
- `PromptBar` *(lazy)* - Where a prompt's words are drawn, with the switch that turns its source off: a recipe, shown only while a prompt is current.

### tables

- `DataGrid` *(lazy)* - A data grid: the floor's standard way to show, narrow and act on a large collection - the long table (long_table.gd) under a bar of its filters, over a bar of what is picked and what can be done to it, and a line saying how the view stands - reusable by any application over its own rows and columns (table_models.gd).
- `LiveFeed` *(lazy)* - A live feed on the screen: the rows of a feed (feed.gd) as many as fit, the newest at the foot, and under them the one press that says where the reader stands - following the newest, or how many have arrived since they stepped away, pressed to follow again.
- `LongTable` *(lazy)* - A table of more rows than will ever be nodes: the heading line over a window of rows (virtual_list.gd) onto a queried view (table_models.gd), every line a line of cells (cells.gd) at the columns' widths - the table's shape (table.gd) for a hundred thousand rows.
- `Wall` *(lazy)* - A status wall: a tile for every item of a keyed set (keyed_items.gd) - five hundred devices, say - each its status's mark and its name, the tiles wrapping at the wall's width and the wall scrolling where they run past its height; and its legend, how many items stand in each state.

### the look's own types

- `AmountField` *(lazy)* - An amount field: where an amount the reader is committing is entered - and only where the reader sets the number. The unit's mark stands before the field, and Enter commits the line as the action.
- `Attention` *(lazy)* - Attention: drawing the reader's eye to one control and saying why. The GLOW alone is the pressable's own, lit while the prompts name its action - an invitation, never a gate. A BUBBLE is the glow plus a short line attached to the control, pulsing, for a control never used. The WORDS IN THE INSTRUCTION BAR are the bar's, read from the prompts.
- `BarChart` *(lazy)* - A bar chart: one bar a thing - a region, a cause - its length its value against the longest, its name before it and its figure after, so the largest reads at a glance and every figure can still be read exactly.
- `Board` *(lazy)* - A board: a ranked list of participants with the reader's own position always findable - one board per measure, several boards not one.
- `Bracket` *(lazy)* - A bracket: the ties of a knockout and the rounds they run in - a tree read left to right, one column per round, one cell per tie, and inside a cell the two entrants as links to whatever their place is.
- `Card` *(lazy)* - A card: a tile that summarises one thing and opens it - the whole tile is the target. LIST style, a full-width row; TILE style, a grid cell; DENSE, a cell combining a live view, the numbers and the controls for acting on it; and EMPTY, a free position carrying the ways to fill it, RESERVED once one of them has claimed it.
- `CellReadout` *(lazy)* - A cell readout: ONE value about one item, in the space of a cell. A QUANTITY in the product's unit of account - one mark, where the language puts it (formats.gd) - or drawn as a BAR on a logarithmic scale against an anchor; a LABEL; a TRACE of recent outcomes; a MARK with a count; and a RELATIVE value, which is a control as well as a readout and gets its own region.
- `Collection` *(lazy)* - A collection: many peers of one set, laid out as ROWS or as TILES, and acted on. The shape is not the identity - one component, since sorting, filtering and selecting are the same either way. An OUTCOME LIST is one in outcome order.
- `Confirm` *(lazy)* - A confirm: asking "are you sure" before a press that cannot be undone - a pop-up holding the consequence in words and the two ways out of it, opened by a button of the asking action (describe_places.gd: button).
- `ConnectionStatus` *(lazy)* - How the connection stands, and what waits on it: a status line for the whole application - online, or offline with how many changes are awaiting sync - and, for any one thing, whether its change is syncing, awaiting sync, or was not kept and why.
- `ContextMenu` *(lazy)* - A context menu: the pop-up a target opens (menu_target.gd), set down beside what it was opened over, one item per action it offers - its words, the key it is on, and why it cannot be used, if it cannot.
- `Countdown` *(lazy)* - A countdown: time remaining on something that will happen whether the reader acts or not. It travels with the reader: whoever composes puts it in the strip, not on the surface that owns the deadline.
- `DateRange` *(lazy)* - A date range: the stretch a filters' date column stands in - whichever presets the application handed in, today and the last 7 days among them - as one segmented choice, and, where the one picked sets no length, the first and last day the reader sets by hand.
- `Disposition` *(lazy)* - A disposition: the single control on an item saying what it will do this cycle, with the second half that choice needs beside it - one per available choice, each with its own second half, and INERT where the phase does not allow that choice yet.
- `Divider` *(lazy)* - A divider: a rule placed between parts - across a column, or down a row - drawn as the look's style says.
- `Drawer` *(lazy)* - A drawer: a side sheet sliding in from an edge over the shade, holding what belongs beside the screen rather than on it - a basket, the filters of a narrow window, the actions of the stop open - and closed by pressing the shade, by its own close press, or by Back.
- `DrillDown` *(lazy)* - A drill-down: the rows behind a figure, in the floor's data grid on a sheet over the dashboard - what they stand behind over them, the grid's own filters, sort, grouping and columns, and the way back.
- `FacetList` *(lazy)* - The facets of a collection drawn: each column its title over its values, each value a press showing how many it would keep; the stretch a range slider; and the chips of what narrows it. It is a VIEW over the one filter model (filters.gd) and holds nothing itself.
- `FilterSet` *(lazy)* - Filters: filters the reader BUILDS over a long list, each becoming a toggle - a BUILDER of property, comparison and value with a live match count, CHIPS (chip.gd) each toggling on its body and removing on its X, and a MATCH COUNT. The property's type decides the rest: a number offers is over / is under / is exactly and takes a value; a date is before / is after and takes one written year-month-day; a list offers is / is not and picks from the values there are; a find offers includes / does not include over names; a boolean offers its two words and no value.
- `Gallery` *(lazy)* - A gallery: one picture large, a row of its fellows small under it, and a press either side stepping through them - the pictures of one thing, looked at one at a time.
- `Graph` *(lazy)* - A relationship graph: a set of individuals as nodes, the strength of each connection a line between them, so families pull together and a narrowing line is visible as a tightening cluster; zoomed in and out on the wheel and on buttons, panned by dragging its empty space, a node picked by a press on it.
- `Hint` *(lazy)* - A hint: the key or button that presses an action, in words, beside the control that performs it.
- `InfiniteCollection` *(lazy)* - An infinite collection: a card a row, in equal columns as many as fit, the next page asked for as the reader nears the foot - a card standing in, the shape of what will land, for every row still on its way.
- `InstructionBar` *(lazy)* - The instruction bar: a bar across the top of the work, in the second person, saying what the surface is asking for and how far through it the reader is - IDLE, a message or nothing; ASKING, mid-act; DONE, what just resolved. It carries three things and no more: the ask, the progress as a count against its ceiling, and the way out. And it is where guidance speaks: idle, it says the prompts' words.
- `KpiCard` *(lazy)* - A KPI card: ONE figure a reader watches - what it is, the figure large in its unit (formats.gd), how it stands against the stretch before it, and a small trend of its days - and the whole card a press opening what stands behind the figure.
- `LineChart` *(lazy)* - A line chart: values over time, one or more series over the same two axes, so a trend, a plateau and a crossing read at a glance while the series are still being extended - and an AREA, a series filled down to a lower edge: a band between two lines, or the ground under one.
- `Matrix` *(lazy)* - A matrix: two axes and what their crossing says. A set down the rows, a set across the columns, and for each pair a cell the matrix asks the next layer for - a function of the row and the column - and places. It knows nothing about what it is showing. ONE SET AGAINST ITSELF shows one triangle, the diagonal being meaningless.
- `MeasureCharts` *(lazy)* - A dashboard's figures over its days as charts: a figure's TREND - its days as an area, the stretch before laid over it while the dashboard compares - and a spread's BAND - the middle half of each day's values as an area, their middle as a line through it. Each is a line chart (line_chart.gd) over a figure of the measures (measures.gd), with its loading and empty states (loaded_or_empty.gd).
- `Moment` *(lazy)* - A moment: something presented at a boundary and handed on from - not a place the reader goes. It has no row and no way in: it arrives while its model says so, is read, and is dismissed by one press, which is a command to the model. It never enters the history.
- `Panes` *(lazy)* - The panes of an application shell over its panels (panels.gd): a split of two panes the model shares the room of, a titled pane, and the presses that fold a pane away and bring it back or expand one over the rest - each showing the key it is on and whether its pane shows.
- `QuickView` *(lazy)* - A quick view: one item of a collection looked at over the collection, never leaving it - opened on the item as its place's parameter, stepping to the item before and after without closing, and closed by Back to the very card it was opened from.
- `RegionMap` *(lazy)* - A region map: every region drawn from data, shaded by how much of a figure falls in it, and each a press - its name pinned on it for the keys and the pad, its ground for the pointer - that picks it.
- `Sections` *(lazy)* - Sections: one collection grouped under headings - a list shown the way it divides, and a settings page whose rows stand in groups. The heading, how many are under it and what is under it are one piece per group.
- `Setting` *(lazy)* - The settings controls: the ROW a setting is stated in - its name, the one line saying what it does, and the control at the end - and the three controls a setting is changed by: a TOGGLE, a CHOICE over the options there are, and a BINDING that takes the next key or button.
- `Sheet` *(lazy)* - A sheet over everything: a shade across the whole of what is beneath, and one sheet of content in the middle of it - the one overlay contract.
- `Table` *(lazy)* - A table: many items of one set, a line each, read down a column at a time - the columns named overhead, and every heading a control that sorts by it. Cells hold values, not cards: this is the shape for comparing.
- `Tabs` *(lazy)* - Tabs: switching between views of the same subject without leaving it. A tab is a place, so it is in the history: each tab is a navigation control to its place, and Back returns the tab that was open.
- `TextField` *(lazy)* - A text field: a named line of words - what a thing is called - under its label, beside amount_field.gd, which is the same shape for a sum. The line always shows the words the model holds, so Enter leaves it as it stands and the model's answer is what is read back.
- `TypeAhead` *(lazy)* - A type-ahead picker: a line to type in, how many options match, and the ones that do, each pressable. A picker is this and never a drop-down, because there can be sixty options, or six hundred.

## The floor and the models

### the vocabulary: the builder, a description and the values a description reads

- `Areas` - Named areas: the same parts laid into a grid of areas that each name a part, the grid chosen by the width THIS has - a dashboard's figures along the top and its charts under them on a wide screen, one over another on a narrow one - so the hierarchy is written once per width and kept.
- `Bound` - A bound value: a read, which knows what it read.
- `Desc` - A description of a piece of interface: what kind of primitive, what it is given, and what it holds. A recipe returns one; the builder (ui.gd) turns one into nodes, top-down, and does not keep it.
- `LazyImage` - A picture that loads as the reader nears it: the look's box standing in until it lands, then the picture filling the box - cut to its shape, never stretched - fading in over it.
- `Local` - A local: a value that belongs to what was built, and to nothing else.
- `PressLocal` - A local press: a face whose press sets a local, and does nothing else.
- `Pressable` - Something pressed: a control performing one of its place's actions, drawn in the state it is in, holding whatever content it was described with.
- `Ui` - The floor's primitives, each a script with build(ui, desc, parent) (floor_kinds.gd).

### the one recipe an application reads inside a constant of its own

- `Status` - A status: a shape, its words and its ink together, so a state is read by a reader who sees no colour at all - never a hue alone.

### the look: the Theme itself

- `Themes` - The look, as the engine's own Theme, built from a palette: placeholder defaults for exactly the types the primitives and the floor's recipes ask for.

### the floor: the models an application annotates with, and the two every model and every app names in a signature

- `Actions` - The actions the interface has, each with the words that say what it does, said once.
- `Controller` - A model: the facts an application is made of, held as values, and the commands that move them. It faces no reader.
- `Calendar` - The calendar: which date field opened it last, the month it shows, and a day picked from it sent on through the door as that field's own press.
- `Chimes` - Who hears which bell.
- `CommandSearch` - What the command palette searches: every command the reader could press on the screen now, and whatever else the application hands in - its datasets, its files - narrowed by what is typed, one pick sending it on.
- `Connection` - Whether the far side can be reached: a connection, said by whoever can tell - the device's network, a socket's reader - and read by anything that waits on it or says it.
- `Documents` - The documents open in an application: which are open, in the order their tabs stand, and which one is in front - the open files of an editor, the queries of a workspace - saved as plain data between runs.
- `Drills` - What stands behind a figure: the rows it counted, in a data grid (data_grid.gd) scoped to exactly them (queried_rows.gd, scope_to).
- `Driver` - The driver: the moves - the door's four commands and its presses that go somewhere, each made through the chart and carried out by the applier - with one bell when a move is done.
- `Feed` - A feed: entries arriving at the end of a long list, looked at by rows (virtual_list.gd) - following the newest while the reader stands there, holding still while they have scrolled away or are on an entry.
- `Fetched` - What a place fills with, and every asking for it again: asked for as the place is entered, on its way, here - or failed, saying why, with a way to ask again.
- `Filters` - The one filter model: what a reader has narrowed a collection to, over packed rows (packed_rows.gd) and over ordinary items alike, declared once as a spec.
- `Form` - A form of many steps: its answers held through the door, a draft saved, the reader asked before unsaved answers are left, taken to a step or a question, and the form sent - or the reader taken to the first thing stopping it.
- `GrowingList` - A long list that grows as the reader goes: its look runs from the first row and takes one more page each time it is asked - the model of an infinite collection (infinite_collection.gd).
- `ImageLoads` - Pictures made or read off the frame, held while something shown wants them: a catalogue's hundreds of pictures, of which only those near the reader are ever in memory.
- `KeyedItems` - Items by key, each a value with a bell of its own: one item changing tells what shows that item and nothing else - the tile of one device on a wall of five hundred - and the tallies of the whole set move at a reader's pace.
- `Lane` - A lane: one list of a board - a column of cards - as the reader sees it: its items in order, and the thing being carried shown where it would land.
- `Measures` - What a dashboard shows of a collection: every figure and every split of one (rollup.gd), worked out off the frame each time what it is taken over moves, and read by every card and chart.
- `Narrowing` - A narrowing: the text a reader has typed to find one option among many, and the options that text leaves.
- `Notifications` - The application's notifications: short messages that arrive, stay for a time the look gives, and leave, one showing at a time and the rest waiting their turn in the order they came.
- `OpenMenu` - A context menu's items and picks: the actions a menu opened over a target offers, what they are about, and a pick of one sent on through the door.
- `Orders` - The order a collection runs in, chosen by name - "Price, low to high" - as a choice's options, set on the rows' view as its sort.
- `Outbox` - An outbox: a far side that holds what is sent while the connection is down, and sends it, oldest first, the moment it is back - so a change made offline is made at once and kept, waiting, as provisional.gd keeps any change the far side has not yet said yes to.
- `PacedNotices` - Notifications at a pace a reader can take: at most one stands a pace, and what arrives together is gathered into one - how many, and one offer to see them all - so a hundred alerts in a second never bury what the reader was doing.
- `PackedRows` - Rows held column by column: a hundred thousand rows are a dozen packed arrays, never a hundred thousand dictionaries.
- `Panels` - The panels of an application shell: how the room of each split is shared between its two panes, which panes are folded away, and which one is expanded over the rest - one model, saved as plain data between runs.
- `Phrase` - A phrase: words not said yet - an English key, or a pattern and the data that fills it, a count, the name of a key, a number written the language's way - carried as it is, and said in the language on only as a text draws it (text.gd), and again whenever the language changes.
- `Provisional` - Provisional changes: what a model has changed AT ONCE, before whoever keeps the record - a server, a far side - has said yes; and, told no, each change undone, its reason kept on the thing and said in a notification. The recipe for optimistic updates, for any model.
- `QueriedRows` - A collection with a query: rows held column by column (packed_rows.gd), the query asked of them - its clauses, its order, its grouping - and the VIEW that query answered, read a place at a time by whatever shows it. Built for a hundred thousand rows: nothing here copies a row into a node or runs once a row on the frame.
- `QueryPacing` - The pace a query is asked at while a reader types: a filter's line changes on every keystroke, and the view's query (queried_rows.gd) goes only once the typing settles.
- `RollingSeries` - A rolling window of a line chart's points (line_chart.gd): values taken as they come, gathered into buckets of time, and the last whole buckets given as the chart the line chart reads - so a live chart is the floor's one chart, fed.
- `Rollup` - A rollup of rows over a stretch of time and the stretch before it: each figure a dashboard shows, day by day as well as whole, and each figure split by the words of a column - an answer of numbers, never of rows.
- `SettingsFile` - An application's settings kept between runs: one file of plain data, a section per model that keeps something - how the panels stand, which documents are open, what keys are bound - read as the application starts and written again as any of them moves.
- `Stream` - A stream: the events a source pushes, handed to the models that take them once a frame, for as long as a place's stay lasts - held while the reader has it paused, and caught up on as it resumes.
- `TableModels` - Everything a large table stands on, made together in one region: the rows' view and its query, the long list of its places, the picks and the cursor, the columns shown, the edits and the cell being edited, the filters, and whether the view is behind its rows - so an application hands over rows and columns and gets a table whose every model already answers the table's recipe (data_grid.gd).
- `Throttle` - Whatever is asked for any number of times in a frame, done once: at the end of the frame it was first asked in, no oftener than a token of the look - PACED - or once the asking has rested for one - SETTLED.

### the vocabulary: what describes, beside the builder

- `Draggable` *(lazy)* - Something a reader can pick up and drop somewhere else: a face, focused and drawn like any other, that hands what it carries to whatever takes it - and, described with an action, is pressed as well as carried.
- `Grip` *(lazy)* - A grip: a thin edge the reader takes hold of to resize something - the sash between a split's two panes (split.gd), a column's edge in a table's heading - every move a command through the door.
- `Layout` *(lazy)* - A row or a column: the line layout (flex.gd) with its gap a Theme name.
- `MenuTarget` *(lazy)* - A menu's target: whatever it holds, given a context menu of declared actions - opened by a right press on it, by the keyboard's menu key or a pad button while the focus is inside it (open_menu.gd).
- `Places` *(lazy)* - The descriptions of the places: the app, a screen, a set of tabs, a pop-up - and the panel, a pop-up that blocks nothing - and the button, which may open a pop-up as one of its kind.
- `SimulatedSight` *(lazy)* - A simulation of colour-blind sight laid over the whole screen, so a look can be checked by eye rather than by argument.
- `Text` *(lazy)* - Words: a phrase, data, or a bound value read again whenever what it read moves - a phrase said in the language on as it is drawn.
- `Transition` *(lazy)* - The transitions: how a thing arrives, and how it goes.

### the look: the Theme's families of types, and what paints one

- `Charts` *(lazy)* - The figures and charts of a dashboard, as the floor's look draws them until a look says otherwise: a KPI card and its words, a bar chart's bars, a map's regions and the presses pinned on them, and the words a chart says when it has nothing to show.
- `Collections` *(lazy)* - COLLECTIONS, as the floor's look draws them until a look says otherwise: the many ways a set of things is laid out - a card as a row, a tile or dense, an infinite collection of cards, a gallery of pictures, a facet's values, a board of lanes and the cards carried between them, a wall of tiles, and a row a finger swipes.
- `Feedback` *(lazy)* - FEEDBACK, as the floor's look draws it until a look says otherwise: everything that tells the reader how something stands - loading's mark and the shape standing in for what has not landed, a picture loading as they near it, a notification, a status's mark and its line, a progress bar, a badge of how pressing something is, a person's initials, a countdown, the bubble pointing at what to look at, and what stands over a list pulled to refresh.
- `Fields` *(lazy)* - FIELDS, as the floor's look draws them until a look says otherwise: everything a reader types into or sets a value with - the typed line itself, a text area, code, an amount, a slider, a stepper, a combo, a type-ahead, a key binding, a chip and the filters built from them - and a form of many steps: a question and the message beside it, a section asked while an answer holds, the steps along the top, the summary of what needs attention, a step of the review, a date field and the calendar's days.
- `Look` *(lazy)* - What every look is made of: the boxes (look_boxes.gd, which this extends), the fonts, and the theme entries a design language is written in, so a look says what it believes in a few lines and never repeats the engine's spelling.
- `MotionTokens` *(lazy)* - A look's motion written into its Theme (motion.gd reads it): the durations and the stagger in milliseconds, and each easing's curve, its ease and which duration it lasts, all under the type Motion.
- `Navigation` *(lazy)* - NAVIGATION, as the floor's look draws it until a look says otherwise: everything that takes the reader somewhere or divides where they are - tabs and their panel, a document's flap, a section and its heading, a link in running words, an inline way out and a step back, the bar at a phone's foot and the rail at a wider window's side, and the panes, grips and foot an application's shell is framed by.
- `Overlays` *(lazy)* - OVERLAYS, as the floor's look draws them until a look says otherwise: the shade everything that stands over the screen stands on, the sheet itself - which a confirmation, a choice's options, a context menu, a drill and a moment all wear - a drawer at the window's edge, a quick view, a context menu's items and the command palette's sheet and entries.
- `Paint` *(lazy)* - The painters: what a flat box cannot draw - a dashed edge, corner brackets, a rule along one side, a hatch, a gradient, a bevel - each a function of (canvas item, rect, theme) for a layered box (look.gd) to draw in its turn.
- `PaintedBox` *(lazy)* - A stylebox drawn by layers: each a stylebox of the engine's drawn at an offset, or a painter given the canvas, the rect and the theme, in order, so a look that needs two shadows, a bracketed corner, a dashed edge or a bevel is made of the engine's own boxes and a few lines, never a texture.
- `Pressables` *(lazy)* - BUTTONS AND PRESSABLES, as the floor's look draws them until a look says otherwise: the pressable itself in every state it passes through, the common button, a toggle and a choice's options, the inline options of a radio group and of a segmented control, and the rows of presses a recipe lays out - the prompt bar, the instruction bar, a collection's controls, a disposition's picker.
- `Tables` *(lazy)* - TABLES, as the floor's look draws them until a look says otherwise: the heading line, a row, a row picked, the row the cursor is on, a group's heading, the words in the cells, and the lines a table, a data grid and a matrix stand in.

### the floor: the door, the chimes, the driver, and the models an application is made of

- `Belfry` *(lazy)* - The belfry: every bell there is, each hung at an address.
- `Carried` *(lazy)* - What is being carried: the one thing a reader has picked up to drop somewhere else, what it carries, and where it would land now.
- `Catalogues` *(lazy)* - The catalogues: files of words, one per language, read off disk and handed to the engine beside whatever catalogues the game has of its own.
- `Commands` *(lazy)* - The one door every command goes through: a control says what it wants done, the model registered for that action does it, and the answer comes back on the same call.
- `Console` *(lazy)* - The developer's console: what the app and the engine have said with a line to type commands into, and the path the reader has walked.
- `Dates` *(lazy)* - Days as a reader types them and reads them back: a day written as a typed line in the language's order, a typed line read back as a day, and the sums a calendar needs - how long a month is, which day of the week it starts on.
- `DebugLog` *(lazy)* - The developer's log: everything the app and the engine say while the app runs - prints, warnings and errors - kept for a screen to read, and written to files on disk.
- `DevCommands` *(lazy)* - The commands a developer can run while the app runs, and the running of a typed line.
- `EditingCell` *(lazy)* - The cell being edited: the one the cursor is on (row_selection.gd), opened for a line to be typed into, until the line is written or given up - so a table is edited where it is read, one cell at a time.
- `FormActions` *(lazy)* - The actions a form's controls press, named and declared in one place: one per question, one opening each choice and one typing into each searched choice, and the form's own - going to a step, to a question, on and back, saving the draft, sending, starting again.
- `Formats` *(lazy)* - Numbers, money, dates and stretches of time, written as the language on writes them: as phrases a text says as it draws (phrase.gd) - the value carried as it is, written only at that moment, and again whenever the language changes - and as the writing itself, for a painter drawing its own numbers.
- `Guide` *(lazy)* - The guided steps: one action at a time, pointed at from wherever the player is, and moved on when they take it.
- `Inputs` *(lazy)* - The map from inputs to actions: which key or pad button presses which action, which device the player is on, and what a rebinding changed.
- `Language` *(lazy)* - The language words are said in: which one is on, a value, and the lookups a text makes as it draws, each a read of it.
- `LongList` *(lazy)* - A long list: more rows than fit on a screen, held a page at a time near the look, which is this model's too.
- `Motion` *(lazy)* - One value on its way, stepped here (run.gd).
- `Prompts` *(lazy)* - Which action is being prompted, and the words that go with it: one at a time, chosen from every source that has something to say.
- `Question` *(lazy)* - A question a form asks, as plain data, and the one reading of its answer: what the answer held means, whether it breaks a rule, whether it can be held at all, and how it is written back to the reader.
- `Reads` *(lazy)* - What a piece of work read: the address of every bell that what it read moves on, noted as it is read, so whoever did the work listens to exactly those.
- `Reminders` *(lazy)* - Reminds the player of an action they have never taken, by prompting it while a control they can reach performs it.
- `RowEdits` *(lazy)* - Edits to rows held column by column (packed_rows.gd): a typed line written as a value of its column's kind, many rows given one value at once, and the last change taken back.
- `RowFilters` *(lazy)* - The filters a reader builds over a queried view (queried_rows.gd): the model the filter-set recipe (filter_set.gd) reads and presses, each chip on becoming a clause of the view's query (row_query.gd).
- `RowQuery` *(lazy)* - A query over packed rows (packed_rows.gd): the rows every clause keeps, in the order asked, and where each group of them starts - an answer of row ids, never of rows.
- `RowSelection` *(lazy)* - Which rows of a queried view (queried_rows.gd) are picked, and where the reader is: the CURSOR, the place of the row they are on, and MOVES_ACROSS, the column in it - so the keys, the pad and the pointer all move one thing, and whatever acts on "this row" asks here which it is.
- `SaveShape` *(lazy)* - The shape a save must have, declared once, and what makes plain data read back not that shape, in words - for every model that keeps itself between runs (settings_file.gd): the panels, the documents open, the key bindings, an application's own.
- `Shape` *(lazy)* - The window's shape, as two values anything may bind to: which way round it is, and how much room it has across.
- `Sounds` *(lazy)* - The interface's sounds: a look's sound for each moment, played by hearing the bells that already ring.
- `SoundBus` *(lazy)* - The bus the interface's sounds play on - the game's, named by the project - with its volume and its mute read as values, and set only by a player's choice told here.
- `Stretch` *(lazy)* - The stretch of time a filters' date column stands in (filters.gd): the preset a reader picked out of the ones handed in as data, or the days they set by hand, and the stretch as long just before it.
- `TableColumns` *(lazy)* - The columns a table shows: which of them, in their order, and how wide each is as a share of the table - moved by command, so a drag, a key and the pad resize alike, and a column hidden is one pressed away.
- `Taken` *(lazy)* - Which of the interface's actions the player has ever taken, and which of them are worth asking about.
- `Thresholds` *(lazy)* - Thresholds: numbers watched against a limit each, and a notification (notifications.gd) as one crosses above its limit - an alert, standing in the shell's tray, offering the press that goes to what crossed.
- `Token` *(lazy)* - A cancellation token: live until cancelled, and dead with its parent.
- `Touch` *(lazy)* - A finger on the glass: the one reader of every touch, handing each gesture whole to the one thing that takes it - a scroll it pans, a row it swipes, a list it pulls - and nothing else.
- `ViewBehind` *(lazy)* - Whether a queried view (queried_rows.gd) is behind its rows: written since its query was worked out, and not yet asked again.
