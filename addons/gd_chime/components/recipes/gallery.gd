extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Local := preload("../primitives/local.gd")
const ImageLoads := preload("../../image_loads.gd")
const Phrase := preload("../../phrase.gd")

## A gallery: one picture large, a row of its fellows small under it, and a
## press either side stepping through them - the pictures of one thing,
## looked at one at a time.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHICH PICTURE SHOWS IS THE INTERFACE'S, a local (local.gd) of the place it
## is built in: not a fact of the thing, and never through the door. A
## thumbnail is a local press giving its place in the row - drawn selected
## while it is the one showing - so the pointer presses one, the keys and
## the pad walk the row and accept one, and the step presses turn the
## showing one back and on, round from the last to the first. Where it
## stands is said in words, "2 of 4", never by the selected thumbnail alone.
##
## EVERY PICTURE LOADS AS IT NEARS THE READER (lazy_image.gd): the large one
## at a large size, the thumbnails small, each its box standing in until it
## lands. What the pictures are is a bound value of their keys, the same
## count always - the shots of a product - so moving to another thing swaps
## every picture in place and builds nothing.
##
## Deliberately absent: zooming into the large picture, and swiping.

## The gallery's column, the large picture, the thumbnails' row, a thumbnail's press and its picture, a step's press.
const COLUMN := &"Gallery"
const PICTURE := &"GalleryPicture"
const THUMBS := &"GalleryThumbs"
const THUMB := &"GalleryThumb"
const THUMB_PICTURE := &"GalleryThumbPicture"
const STEP := &"GalleryStep"


## The gallery of the pictures a bound value's keys name - this many - from
## the image loads model, the large one at the least of these sizes that
## fits and the thumbnails at the least of those.
## Its options: count, how many pictures there are; sizes, the sizes the
## large one may be shown at; and thumb_sizes, the thumbnails'.
const OPTIONS: Array[String] = ["count", "sizes", "thumb_sizes"]

static func make(ui: Ui, loads: ImageLoads, keys: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a gallery", options, OPTIONS)
	var count: int = options["count"]
	var sizes: Array = options["sizes"]
	var thumb_sizes: Array = options["thumb_sizes"]
	var showing: Local = ui.local(0)
	var thumbs: Array = []
	# one thumbnail a picture, each pressing its own place in the row
	for at: int in count:
		var key: Bound = keys.map(func(all: Variant) -> Variant: return null if all == null else all[at])
		thumbs.append(ui.press_local(showing, at, [ui.lazy_image(loads, key, thumb_sizes, THUMB_PICTURE)], THUMB))
	var back := ui.press_local(showing, func(now: int) -> int: return (now + count - 1) % count, [ui.text("‹", Themes.FACE)], STEP)
	var on := ui.press_local(showing, func(now: int) -> int: return (now + 1) % count, [ui.text("›", Themes.FACE)], STEP)
	var where := ui.text(showing.map(func(now: int) -> Phrase: return Phrase.with("%d of %d", [now + 1, count])), Themes.REASON)
	var large := ui.lazy_image(loads, Bound.both(keys, showing, func(all: Variant, place: int) -> Variant: return null if all == null else all[place]), sizes, PICTURE)
	return ui.column([large, ui.row([back, ui.row(thumbs, THUMBS).grow(), on, where], THUMBS)], COLUMN)
