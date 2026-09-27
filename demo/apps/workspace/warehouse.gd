extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## The warehouse the workspace queries: its datasets and their columns, the
## project's saved queries, and a query run over them - the demo's data,
## made up and the same every run.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE CATALOGUE IS LARGE ON PURPOSE: twenty schemas of twelve kinds of
## table, each in ten versions - 2,400 datasets - which the command palette
## searches as the reader types. The project's explorer lists the handful
## the project uses. A dataset's columns are its kind's. A QUERY is read as
## far as a demo needs: the dataset after FROM, the columns after SELECT
## (all of them for *), and a LIMIT; its rows are made from the dataset's
## name, so a query run twice answers the same. It holds nothing and rings
## nothing: the workbench (workbench.gd) is the model.

const SCHEMAS: Array[String] = ["sales", "ops", "finance", "hr", "marketing", "logistics", "support", "product", "billing", "growth", "risk", "retail", "web", "mobile", "partners", "procurement", "legal", "research", "platform", "field"]
const KINDS := {
	"orders": [["order_id", "bigint"], ["customer_id", "bigint"], ["ordered_at", "timestamp"], ["status", "text"], ["total", "numeric"]],
	"customers": [["customer_id", "bigint"], ["name", "text"], ["region", "text"], ["joined_on", "date"], ["lifetime_value", "numeric"]],
	"invoices": [["invoice_id", "bigint"], ["order_id", "bigint"], ["issued_on", "date"], ["due_on", "date"], ["amount", "numeric"], ["paid", "boolean"]],
	"shipments": [["shipment_id", "bigint"], ["order_id", "bigint"], ["carrier", "text"], ["shipped_at", "timestamp"], ["delivered_at", "timestamp"]],
	"payments": [["payment_id", "bigint"], ["invoice_id", "bigint"], ["method", "text"], ["paid_at", "timestamp"], ["amount", "numeric"]],
	"products": [["product_id", "bigint"], ["name", "text"], ["category", "text"], ["price", "numeric"]],
	"stores": [["store_id", "bigint"], ["name", "text"], ["region", "text"], ["opened_on", "date"]],
	"suppliers": [["supplier_id", "bigint"], ["name", "text"], ["region", "text"], ["rating", "numeric"]],
	"returns": [["return_id", "bigint"], ["order_id", "bigint"], ["reason", "text"], ["returned_at", "timestamp"]],
	"events": [["event_id", "bigint"], ["session_id", "bigint"], ["name", "text"], ["happened_at", "timestamp"]],
	"sessions": [["session_id", "bigint"], ["customer_id", "bigint"], ["started_at", "timestamp"], ["pages", "integer"]],
	"refunds": [["refund_id", "bigint"], ["payment_id", "bigint"], ["refunded_at", "timestamp"], ["amount", "numeric"]],
}
const VERSIONS: Array[String] = ["", "_daily", "_monthly", "_raw", "_clean", "_2023", "_2024", "_archive", "_staging", "_v2"]
## The datasets this project uses, which its explorer lists.
const PROJECT: Array[String] = ["sales.orders", "sales.customers", "sales.returns", "ops.shipments", "ops.stores", "finance.invoices", "finance.payments", "finance.refunds", "product.products", "web.sessions", "web.events", "procurement.suppliers"]
## The project's saved queries: a file's name and its words.
const QUERIES := {
	"daily_revenue.sql": "select ordered_at, total\nfrom sales.orders_daily\nlimit 200",
	"top_customers.sql": "select name, region, lifetime_value\nfrom sales.customers\nlimit 50",
	"late_shipments.sql": "select shipment_id, carrier, shipped_at, delivered_at\nfrom ops.shipments\nlimit 120",
	"refund_rate.sql": "select *\nfrom finance.refunds_monthly\nlimit 80",
	"unpaid_invoices.sql": "select invoice_id, due_on, amount, paid\nfrom finance.invoices\nlimit 150",
	"sessions_by_page.sql": "select session_id, pages\nfrom web.sessions_clean\nlimit 300",
}
## Words a text column is made from.
const WORDS: Array[String] = ["north", "south", "east", "west", "open", "closed", "pending", "card", "transfer", "cash", "alpha", "birch", "cedar", "delta", "ember"]
## The most rows a result keeps to show; the count says how many there were.
const SHOWN := 100


## Every dataset there is, {value, words}: its full name as both.
static func catalogue() -> Array:
	var all: Array = []
	# every schema, every kind in it, every version of that kind
	for schema: String in SCHEMAS:
		for kind: String in KINDS:
			for version: String in VERSIONS:
				var named := "%s.%s%s" % [schema, kind, version]
				all.append({"value": named, "words": named})
	return all


## A dataset's columns, [name, type] each; none for a name that is no dataset.
static func columns_of(dataset: String) -> Array:
	if dataset.get_slice_count(".") != 2 or not SCHEMAS.has(dataset.get_slice(".", 0)):
		return []
	var table := dataset.get_slice(".", 1)
	# every kind, for the one this table is a version of
	for kind: String in KINDS:
		if table.begins_with(kind) and VERSIONS.has(table.trim_prefix(kind)):
			return KINDS[kind]
	return []


## How many rows a dataset holds: made from its name, the same every time.
static func rows_in(dataset: String) -> int:
	return 400 + absi(hash(dataset)) % 9600


## A query run: {columns, rows - at most SHOWN, total, said, failed}. What it
## could not read is failed, and said in words.
static func run(sql: String) -> Dictionary:
	var words := sql.to_lower().replace("\n", " ").replace(";", " ").split(" ", false)
	var from := words.find("from")
	if from < 0 or from + 1 >= words.size():
		return _failed(GdChime.Phrase.of("A query needs FROM and a dataset"))
	var dataset: String = words[from + 1]
	var known := columns_of(dataset)
	if known.is_empty():
		return _failed(GdChime.Phrase.with("There is no dataset called %s", [dataset]))
	var picked := _picked(" ".join(words.slice(1, from)), known)
	if picked.is_empty():
		return _failed(GdChime.Phrase.with("%s has none of those columns", [dataset]))
	var limit := words.find("limit")
	var total := mini(rows_in(dataset), int(words[limit + 1]) if limit >= 0 and limit + 1 < words.size() else rows_in(dataset))
	var rows: Array = []
	# every row kept to show, each a value per column picked
	for at: int in mini(total, SHOWN):
		rows.append(picked.map(func(column: Array) -> String: return _value(column, at, dataset)))
	return {"columns": picked.map(func(column: Array) -> String: return column[0]), "rows": rows, "total": total, "said": null, "failed": false}


static func _failed(said: GdChime.Phrase) -> Dictionary:
	return {"columns": [], "rows": [], "total": 0, "said": said, "failed": true}


## The columns a SELECT names, among the dataset's, in its order - every one for *.
static func _picked(named: String, known: Array) -> Array:
	if named.strip_edges() == "*":
		return known
	var asked := Array(named.replace(",", " ").split(" ", false))
	return known.filter(func(column: Array) -> bool: return asked.has(column[0]))


## One value of a column in a row, made from the row and the dataset's name.
static func _value(column: Array, row: int, dataset: String) -> String:
	var seed := absi(hash("%s%d%s" % [dataset, row, column[0]]))
	match column[1]:
		"bigint", "integer":
			return str(seed % 90000 + 1000)
		"numeric":
			return "%.2f" % (float(seed % 100000) / 100.0)
		"timestamp":
			return "2024-%02d-%02d %02d:%02d" % [seed % 12 + 1, seed % 28 + 1, seed % 24, seed % 60]
		"date":
			return "2024-%02d-%02d" % [seed % 12 + 1, seed % 28 + 1]
		"boolean":
			return "true" if seed % 3 != 0 else "false"
	return WORDS[seed % WORDS.size()]
