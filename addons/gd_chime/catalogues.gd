extends RefCounted

## The catalogues: files of words, one per language, read off disk and
## handed to the engine beside whatever catalogues the game has of its own.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A CATALOGUE IS A FILE, one per language (words/fr.po), in the gettext form
## the engine reads itself: load() makes it a Translation, the plural rule
## taken from its own header, and it is registered with the engine's
## TranslationServer, so a tr() anywhere reads the same words. A file that
## cannot be read is said out loud, in these words and never in the engine's
## own complaints, and nothing it held is offered.
##
## ADDING IS ALL IT EVER DOES. A catalogue registered stands beside the
## game's own and changes nothing the game set - the locale is the game's
## (language.gd). A file read again, as an app coming back reads the floor's,
## is the one Translation the engine already holds, and the engine holds it
## once.
##
## Deliberately absent: taking a catalogue away, which would take words from
## whatever else in the game reads them.


## Every catalogue in this folder read and registered with the engine: the
## floor's, as the language is made, and an application's own beside them.
static func read(folder: String) -> void:
	# every catalogue file in the folder
	for file: String in DirAccess.get_files_at(folder):
		if file.get_extension() != "po":
			continue
		var catalogue: Translation = load(folder.path_join(file)) if _reads_as_catalogue(folder.path_join(file)) else null
		if catalogue == null:
			push_error("the catalogue %s could not be read, and nothing in it is offered" % folder.path_join(file))
			continue
		TranslationServer.add_translation(catalogue)


## Whether a file off disk reads as a catalogue before the engine is asked:
## every line blank, a comment, or a keyword or more words, each in closed
## quotes.
static func _reads_as_catalogue(path: String) -> bool:
	var line_of := RegEx.create_from_string("^(msgctxt|msgid|msgid_plural|msgstr(\\[\\d+\\])?)?\\s*\"([^\"\\\\]|\\\\.)*\"$")
	# every line of the file, for one that is none of those
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var bare := line.strip_edges()
		if bare != "" and not bare.begins_with("#") and line_of.search(bare) == null:
			return false
	return true
