extends RefCounted

## The one thing the facade's lists of names are written in terms of: a script
## found by its path the first time its name is read, and kept after.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## `const X := preload(...)` is EAGER: naming a script in a constant compiles
## it, and everything it names, when the file holding the constant loads. The
## facade names the whole framework, so an application that draws a card used
## to compile the region map, the calendar sheet and the console as well,
## before its own _init ran. A `static var` with a getter is not: the path is
## a string until something reads the name.
##
## It holds no list itself and is never made. The lists are the files that
## extend it - gd_chime_recipes.gd, then gd_chime_floor.gd, then gd_chime.gd,
## the one name an application preloads - because a static var is inherited
## through that chain, so `GdChime.Card` finds a name wherever in the chain it
## is written, and 163 names in one file would be over the 250-line cap.
##
## IT MUST NEVER BE PRELOADED BY ANYTHING INSIDE gd-chime. A file of the floor
## names what it uses, by its own path; this exists only between an application
## and the framework.
##
## Chosen against: `load()` at every read with nothing kept. The engine's
## resource cache would answer it, but a name here is read in the middle of
## describing a screen - `GdChime.Phrase.of(...)` stands in loops - and a
## Dictionary hit is cheaper than a path hashed and looked up in the cache.

## A path in a list is written from the addon's root, never from the
## project's: the addon may be installed anywhere. A static function has no
## script of its own to ask where that is, so it is read off a neighbour -
## phrase.gd, which gd_chime.gd compiles at start whatever else is read, so
## asking it costs nothing.
const _NEIGHBOUR := preload("phrase.gd")
## where the addon sits, which every path in the lists is joined to
static var _here: String = (_NEIGHBOUR as Script).resource_path.get_base_dir()
## every script already fetched, under the path it was fetched by
static var _scripts: Dictionary = {}


## The script at this path from the addon's root, fetched the first time it is asked for.
static func _at(path: String) -> GDScript:
	if not _scripts.has(path):
		_scripts[path] = load(_here.path_join(path))
	return _scripts[path]
