extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const NavControl := preload("nav_control.gd")

## A relationship graph: a set of individuals as nodes, the strength of
## each connection a line between them, so families pull together and a
## narrowing line is visible as a tightening cluster; zoomed in and out on
## the wheel and on buttons, panned by dragging its empty space, a node
## picked by a press on it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The picture is the MODEL's: it holds the nodes, [{id, name, at}] with
## at where the force-directed layout - library code the model calls - put
## each, the links, [{a, b, strength}], and the view, {centre, scale}; it
## answers the pan, the zoom and the pick, and refuses what it will not.
## No shared ancestry, no line: a node with no link floats free, and a
## connected component is a family. Relatedness is carried by distance and
## line weight, never by hue.
##
## A PRESS ON A NODE SELECTS IT, and which node is selected is the model's:
## the pick is a command, and the model answers selected, that node or
## nothing. The selected node wears a ring and shows a small panel with
## two ways on - EXPAND, a command to the model, which loads that node's
## wider family into the picture, and OPEN, an inline link to that
## individual carrying its id. What is loaded and drawn is data, so none of
## this is the interface's own state, and the canvas knows commands alone.


## The graph over this model's reads - picture, selected - and actions,
## {pans, zooms, picks, zooms_in, zooms_out, expands, opens}, an opened
## individual's place being opens_to.
static func make(ui: Ui, graph: Object, actions: Dictionary, opens_to: StringName) -> Desc:
	var style := &"Graph"
	var selected: Bound = ui.bound(graph.get_selected)
	var picture: Bound = Bound.both(ui.bound(graph.get_picture), selected, _with_selected)
	var hit := func(at: Vector2) -> Variant: return _node_at(picture.read(), at)
	var canvas := ui.pan_zoom(_paint, picture, {"pans": actions["pans"], "zooms": actions["zooms"], "picks": actions["picks"]}, {hit = hit, style = style})
	var buttons := ui.column([ui.button(actions["zooms_in"]), ui.button(actions["zooms_out"])])
	var expanded: Bound = selected.map(func(node: Variant) -> Dictionary: return {"id": node["id"] if node != null else null})
	var panel := ui.surface(&"GraphPanel", [ui.column([NavControl.inline(ui, actions["opens"], selected, {goes_to = opens_to}), ui.button(actions["expands"], {payload = expanded})])])
	return ui.surface(style, [ui.row([canvas.grow(6.0), ui.column([buttons, ui.when(selected, panel)]).grow(2.0)])])


## The picture noted with which of its nodes is selected, for the painter:
## the one dictionary the painter notes the canvas's size on, for the hit.
static func _with_selected(picture: Variant, selected: Variant) -> Variant:
	if picture != null:
		picture["selected"] = selected["id"] if selected != null else null
	return picture


## Where a node lands on the canvas: its place through the view.
static func _on_canvas(picture: Dictionary, at: Vector2) -> Vector2:
	var view: Dictionary = picture["view"]
	return (at - view["centre"]) * view["scale"] + picture["size"] / 2.0


static func _node_at(picture: Variant, point: Vector2) -> Variant:
	if picture == null:
		return null
	for node: Dictionary in picture["nodes"]:
		if _on_canvas(picture, node["at"]).distance_to(point) <= picture["radius"] * picture["view"]["scale"]:
			return node["id"]
	return null


## The picture painted: every link a line as thick as its strength, every
## node a disc with its name beside it.
static func _paint(control: Control, picture: Variant) -> void:
	if picture == null:
		return
	picture["size"] = control.size
	var ink := control.get_theme_color(&"line")
	var soft := control.get_theme_color(&"link")
	var by_id: Dictionary = {}
	for node: Dictionary in picture["nodes"]:
		by_id[node["id"]] = node
	for link: Dictionary in picture["links"]:
		control.draw_line(_on_canvas(picture, by_id[link["a"]]["at"]), _on_canvas(picture, by_id[link["b"]]["at"]), soft, 1.0 + 4.0 * float(link["strength"]))
	var radius: float = picture["radius"] * picture["view"]["scale"]
	for node: Dictionary in picture["nodes"]:
		var at := _on_canvas(picture, node["at"])
		control.draw_circle(at, radius, ink)
		if node["id"] == picture["selected"]:
			control.draw_arc(at, radius * 1.6, 0.0, TAU, 32, ink, 2.0)
		control.draw_string(control.get_theme_default_font(), at + Vector2(radius + 4.0, 4.0), str(node["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_default_font().get_height(), ink)
