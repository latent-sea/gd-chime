extends "describe_places.gd"

const ImageLoads := preload("../../image_loads.gd")
const Fetched := preload("../../fetched.gd")
const Notifications := preload("../../notifications.gd")
const Loading := preload("../recipes/loading.gd")

## The descriptions of what loads: what a place fills with, the shapes
## standing in until it lands, a picture that loads as the reader nears it,
## and a press made by coming near.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's and the layers between,
## which this extends; the builder (ui.gd) extends this. These stand apart
## because they are what makes a screen feel instant without holding
## everything: what a place shows is asked for as the place is entered
## (fetched.gd), nothing far from the reader is asked for, and what is
## near is on its way before it is seen (nearness.gd).

## A lazy picture's look, unless another is named.
const LAZY_IMAGE := &"LazyImage"


## What a place fills with, asked of this source as the place is entered:
## hand it to the place among the models that answer there, and hand
## fetched.fill to the place as what it does on filling - the place then
## stands it up and puts it in the tree (place_builder.gd). Its .data,
## .loading and .failure are read wherever they are drawn (fetched.gd); a
## failure is said in the notifications by the words it is known by, and on
## the thing itself where ui.loading draws it. Asking again - refreshing,
## pulling, trying again - is Fetched.ASKS_AGAIN.
func fetched(source: Callable, notices: Notifications, words: Phrase) -> Fetched:
	return Fetched.new(chimes, source, notices, words)


## The content once what the place fills with has landed; until then
## loading's mark over so many shapes, standing in for the lines coming;
## and over both, why the last asking failed, with a way to ask again
## (loading.gd).
func loading(waiting: Fetched, content: Desc, rows: int = 1) -> Desc:
	return Loading.of(self, waiting, content, Loading.shapes(self, rows))


## A picture of the key a bound value reads, from the image loads model,
## at the least of these sizes - pixels square - as wide as it is drawn,
## claimed only while near the reader, its style's box standing in until it
## lands (lazy_image.gd).
func lazy_image(loads: ImageLoads, key: Bound, sizes: Array, style: StringName = LAZY_IMAGE) -> Desc:
	return Desc.new(&"lazy_image", {"loads": loads, "key": key, "sizes": sizes, "style": style})


## What it holds, pressing the action - with a payload, a dictionary or a
## bound value read as it presses - each time the reader nears it somewhere
## new (nearing.gd). Its place declares the action.
func nearing(action: StringName, payload: Variant, content: Array) -> Desc:
	return Desc.new(&"nearing", {"action": action, "payload": payload}, content)
