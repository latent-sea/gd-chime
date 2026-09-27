extends RefCounted

## How many columns a grid has, how wide each one is, and which cell each part
## falls into.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## CSS Grid Layout Level 1, the share of § 7 and § 11 a subset needs. Columns
## are declared one of two ways and this answers both: as SHARES of what is left
## after the gaps, or AUTO - as many equal columns of at least a width as fit,
## which is the whole of reflowing and is one line of arithmetic:
##
##     count = max(1, floor((room + gap) / (least + gap)))
##
## Shares are worked out by flex_line.gd, because a column taking two shares is
## a part growing at two: it starts at what the parts in it need, grows by its
## share, and gives nothing back - so a grid whose columns cannot fit overflows
## rather than crushing them, by the same rule and the same proved arithmetic.
##
## A part covering several columns asks them TOGETHER, whichever way the columns
## were declared: only what those columns cannot hold between them, their gaps
## counted, is asked of them. The other way - its whole width against each
## column it touches - is how one wide heading silently widens every column of a
## table.
##
## This is arithmetic and nothing else: a part arrives as the width it needs and
## the number of columns it covers, and leaves as a cell. That is what lets the
## cases be asserted as numbers rather than read back out of rectangles.

const FlexLine := preload("flex_line.gd")


## How many columns there are. None, where neither shares nor a least width was
## given, which is a grid nobody finished building.
static func count(shares: Array[float], least_column: float, room: float, gap: float) -> int:
	if not shares.is_empty():
		return shares.size()
	if least_column <= 0.0:
		return 0
	return maxi(1, floori((room + gap) / (least_column + gap)))


## The cell each part falls into, as its row and the column it starts at, in the
## order the parts were given. A part that will not fit the room left on its row
## starts the next one, and the hole it leaves stays a hole.
static func cells(spans: Array[int], count: int) -> Array[Vector2i]:
	var at: Array[Vector2i] = []
	var row := 0
	var column := 0
	# every part in turn, into the next free cell
	for span: int in spans:
		if column + mini(span, count) > count:
			row += 1
			column = 0
		at.append(Vector2i(row, column))
		column += mini(span, count)
	return at


## Every column's width. Auto-fitting they are equal, and each is no narrower
## than any part needs of it - a part in one column its whole width, a part
## covering several its width less the gaps inside it, split between them - so
## a part too wide for its columns overflows the grid rather than the part
## beside it.
static func widths(spans: Array[int], needs: Array[float], at: Array[Vector2i],
		shares: Array[float], least_column: float, room: float, gap: float) -> Array[float]:
	var count := count(shares, least_column, room, gap)
	var widths: Array[float] = []
	if count == 0:
		return widths
	if shares.is_empty():
		var each := (room - gap * (count - 1)) / count
		# every part, by what it needs of each column it covers: its width less the gaps inside it, split between them
		for part: int in needs.size():
			var span := mini(spans[part], count)
			each = maxf(each, (needs[part] - gap * (span - 1)) / span)
		widths.resize(count)
		widths.fill(each)
		return widths
	var least := least_of(spans, needs, at, count, gap)
	var tracks: Array = []
	# every column as a part of a line: growing at its share, giving nothing back
	for column: int in count:
		tracks.append({"base": least[column], "least": least[column], "most": INF,
			"grow": shares[column], "shrink": 0.0})
	return FlexLine.lengths(tracks, room, gap * (count - 1))


## What each column needs to be, from the parts in it: the parts in one column
## first, then what the parts covering several cannot fit between them.
static func least_of(spans: Array[int], needs: Array[float], at: Array[Vector2i], count: int, gap: float) -> Array[float]:
	var least: Array[float] = []
	least.resize(count)
	least.fill(0.0)
	# every part in one column alone, which asks for its width outright
	for part: int in spans.size():
		if mini(spans[part], count) == 1:
			least[at[part].y] = maxf(least[at[part].y], needs[part])
	# then every part covering several, which asks only for what they lack
	for part: int in spans.size():
		var span := mini(spans[part], count)
		if span == 1:
			continue
		var covered := gap * (span - 1)
		# the columns this part covers, for the width they already give it with their gaps
		for column: int in range(at[part].y, at[part].y + span):
			covered += least[column]
		if needs[part] > covered:
			# the same columns, each widened by an even share of what the part still lacks
			for column: int in range(at[part].y, at[part].y + span):
				least[column] += (needs[part] - covered) / span
	return least
