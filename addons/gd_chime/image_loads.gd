extends "controller.gd"

const Jobs := preload("jobs.gd")

## Pictures made or read off the frame, held while something shown wants
## them: a catalogue's hundreds of pictures, of which only those near the
## reader are ever in memory.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PICTURE IS A KEY AND A SIZE - a product and how many pixels square -
## made by the MAKER this is handed, make(key, size) -> Image, which runs on
## the job pool (jobs.gd): it must touch nothing shared. A picture that
## lands is made a texture on the main thread, where the engine takes it,
## and LANDED rings; texture_of(key, size) is it, or null while it is not.
##
## WANTED, IT COMES; LET GO, IT GOES. want(key, size, by) is a claim by
## whatever shows it (lazy_image.gd, as it comes near the reader): the
## first claim asks for it, at most so many at once - the rest wait their
## turn, newest wanted first, since that is where the reader is going. A
## claim let go (let_go) before its turn comes asks for nothing; one let go
## after keeps the picture a while - at most KEEP pictures nobody claims are
## held, the one let go longest ago freed first - so scrolling back finds it
## at once, and memory stays flat however far the reader goes.
##
## How long each picture took, from the first claim to its landing, is kept
## (get_waits), so an application can say how long a reader waits.
##
## Deliberately absent: failing to make one - a maker answers an image -
## and more than one size made from another.

const LANDED := &"image_landed"

var _jobs: Jobs
var _make: Callable
var _at_once: int
var _keep: int
var _textures: Dictionary = {}  # [key, size] -> its texture, for every picture landed and held
var _claims: Dictionary = {}  # [key, size] -> the things claiming it, as a set
var _waiting: Array = []  # [key, size], wanted and not yet asked for, oldest first
var _out: Dictionary = {}  # [key, size] asked for and not landed -> when it was first wanted, in microseconds
var _wanted_at: Dictionary = {}  # [key, size] waiting -> when it was first wanted, in microseconds
var _unclaimed: Array = []  # [key, size] held and claimed by nothing, let go longest ago first
var _waits: PackedFloat32Array = PackedFloat32Array()


## Made by this maker on this pool, so many at once, keeping so many nobody claims.
func _init(chimes: Chimes, jobs: Jobs, make: Callable, at_once: int, keep: int) -> void:
	super(chimes, [], own_region("image_loads"))
	_jobs = jobs
	_make = make
	_at_once = at_once
	_keep = keep
	register_bell(LANDED)


## The picture of this key at this size, or null while it has not landed.
func texture_of(key: Variant, size: int) -> Texture2D:
	return _textures.get([key, size])


## How many pictures are held now, claimed or not.
func get_held() -> int:
	return _textures.size()


## How many pictures are claimed now.
func get_claimed() -> int:
	return _claims.size()


## Whether a picture claimed is still on its way: waiting its turn or being made.
func get_busy() -> bool:
	return not _waiting.is_empty() or not _out.is_empty()


## How long each picture landed took, first wanted to landed, in milliseconds.
func get_waits() -> PackedFloat32Array:
	return _waits


## A claim on this picture by this thing: asked for if it is neither held nor on its way.
func want(key: Variant, size: int, by: Object) -> void:
	var picture := [key, size]
	if not _claims.has(picture):
		_claims[picture] = {}
	_claims[picture][by] = true
	_unclaimed.erase(picture)
	if _textures.has(picture) or _out.has(picture) or _waiting.has(picture):
		return
	_waiting.append(picture)
	_wanted_at[picture] = Time.get_ticks_usec()
	_ask()


## This thing's claim let go: waiting, it is never asked for; held, it is kept a while.
func let_go(key: Variant, size: int, by: Object) -> void:
	var picture := [key, size]
	if not _claims.has(picture):
		return
	_claims[picture].erase(by)
	if not _claims[picture].is_empty():
		return
	_claims.erase(picture)
	if _waiting.has(picture):
		_waiting.erase(picture)
		_wanted_at.erase(picture)
	elif _textures.has(picture):
		_unclaim(picture)


## The newest wanted asked for while fewer than so many are out.
func _ask() -> void:
	# while there is room and something waits: the one wanted last goes next
	while _out.size() < _at_once and not _waiting.is_empty():
		var picture: Array = _waiting.pop_back()
		_out[picture] = _wanted_at[picture]
		_wanted_at.erase(picture)
		_jobs.submit(_make.bind(picture[0], picture[1]), _landed.bind(picture))


## A picture made, on the main thread: a texture now, kept, said.
func _landed(image: Image, picture: Array) -> void:
	_waits.append((Time.get_ticks_usec() - _out[picture]) / 1000.0)
	_out.erase(picture)
	_textures[picture] = ImageTexture.create_from_image(image)
	if not _claims.has(picture):
		_unclaim(picture)
	_ask()
	strike(region, LANDED)


## Held by nobody: kept among the unclaimed, the longest unclaimed freed past KEEP.
func _unclaim(picture: Array) -> void:
	_unclaimed.append(picture)
	# while more are kept unclaimed than may be, the one let go longest ago is freed
	while _unclaimed.size() > _keep:
		_textures.erase(_unclaimed.pop_front())
