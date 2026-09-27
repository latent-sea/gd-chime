extends SceneTree

## Load every demo script, so that the engine reports any that will not compile.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run by demos_compile.py, which is the half that reads the answer. Loading and
## not running is the whole of it: a demo exists to be looked at, and what it
## looks like is not a thing to assert.
##
## It does not judge. Measured on 4.6.2: load() hands back a script object even
## when that script failed to parse, and says so only by printing - so what it
## returns cannot be tested, and the engine's own complaint is the signal. This
## half makes the complaint happen; the other half hears it.
##
## A folder with no scripts in it fails here. Loading nothing proves nothing,
## and it is what a moved or renamed demo folder looks like from inside.

func _init() -> void:
	var scripts := _scripts_under("res://demo")
	# every demo script, loaded where a compile error is the only thing that can go wrong
	for path: String in scripts:
		load(path)
	print("%d demo script(s) loaded" % scripts.size())
	quit(1 if scripts.is_empty() else 0)


## Every .gd under a folder, and under the folders under it.
func _scripts_under(folder: String) -> Array[String]:
	var found: Array[String] = []
	# the folders first, so a demo in a folder of its own is found the same way
	for inner: String in DirAccess.get_directories_at(folder):
		found.append_array(_scripts_under(folder + "/" + inner))
	# then the scripts in this folder itself
	for name: String in DirAccess.get_files_at(folder):
		if name.ends_with(".gd"):
			found.append(folder + "/" + name)
	return found
