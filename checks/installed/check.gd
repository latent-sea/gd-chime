extends SceneTree

const Stall := preload("stall.gd")
const Scene := preload("stall.tscn")

## The installed project run headless: the stall's scene - its root a
## ChimeApp, as the README tells an author to make it - added to the
## window, its button pressed ten times and refused the eleventh, the words
## read off the screen, and the language switched once, into French. Prints
## INSTALLED OK, or every claim that did not hold, and quits with that.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of the gd-chime folder.
##
## Run by installation_test.py, in a temporary copy of this folder with the
## addon copied in and imported - GdChime and ChimeApp are global names,
## which resolve only once the editor's scan has registered them. It reads
## nothing of the gd-chime folder: what it asserts is what a game that
## installed the addon would see. The French of the stall's own words is
## given here, as a game gives its own; the floor's French is the addon's,
## found where the addon was installed.

## The reason the eleventh press is refused with, as the README writes it.
const FULL := "Ten crates is all the stall holds"
## The stall's words in French, as a game that installed the addon gives its own.
const FRENCH := {"Count a crate": "Compter une caisse", "%d crates counted": "%d caisses comptées", FULL: "L'étal ne tient que dix caisses"}

var _failed: Array[String] = []


func _init() -> void:
	await process_frame
	root.size = Vector2i(1280, 800)
	var app: ChimeApp = Scene.instantiate()
	root.add_child(app)
	await _frames(3)
	_claim(app.driver.index.has_place(&"counting") and app.driver.get_top() == [&"stall", &"counting"], "the screen builds and the reader arrives on it: %s" % [app.driver.get_top()])
	var presses: Array = app.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is GdChime.Pressable and part.action == Stall.COUNTS)
	_claim(presses.size() == 1, "the screen holds one button for the action: %d" % presses.size())
	var button: GdChime.Pressable = presses[0]
	_claim(_shows("Count a crate") and _shows("0 crates counted"), "the button carries the register's words and the model's value shows: %s" % [_words()])
	# ten presses, each landing on the model
	for press: int in 10:
		button.pressed()
		await _frames(1)
	_claim(_shows("10 crates counted"), "ten presses counted ten crates, and the words follow the value: %s" % [_words()])
	var refused := app.commands.dispatch(&"counting", Stall.COUNTS, {})
	button.pressed()
	await _frames(2)
	_claim(refused != null and str(refused) == FULL and not button.is_usable() and str(button.get_reason()) == FULL, "the eleventh press is refused with a reason: %s, %s" % [refused, button.get_reason()])
	_claim(_shows(FULL) and _shows("10 crates counted"), "and the reason shows on the screen beside the count: %s" % [_words()])
	var french := Translation.new()
	french.locale = "fr"
	# the stall's own words in French, as the game gives them
	for english: String in FRENCH:
		french.add_message(english, FRENCH[english])
	TranslationServer.add_translation(french)
	app.commands.dispatch(GdChime.Chimes.GLOBAL, GdChime.Language.CHANGES_LANGUAGE, {"value": &"fr"})
	await _frames(2)
	_claim(TranslationServer.get_locale() == "fr" and _shows(FRENCH["Count a crate"]) and _shows("10 caisses comptées") and _shows(FRENCH[FULL]), "switched into French once, the screen says it all in French: %s" % [_words()])
	_claim(GdChime.Language.word("Close") == "Fermer", "and the floor's own French is on, read from where the addon was installed: %s" % GdChime.Language.word("Close"))
	app.free()
	if _failed.is_empty():
		print("INSTALLED OK")
	# every claim that did not hold, on its own line
	for sentence: String in _failed:
		print("NOT TRUE: %s" % sentence)
	quit(0 if _failed.is_empty() else 1)


func _frames(count: int) -> void:
	# so many frames, for a build or a press to be laid out
	for frame: int in count:
		await process_frame


func _claim(held: bool, what: String) -> void:
	if not held:
		_failed.append(what)


## Every set of words drawn on the window now.
func _words() -> Array:
	return root.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return (label as Label).is_visible_in_tree()).map(func(label: Node) -> String: return (label as Label).text)


func _shows(said: String) -> bool:
	return _words().has(said)
