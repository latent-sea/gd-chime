extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## The business insurance application's questions, as data: eight steps -
## the company, its activities, its people, what it owns, what it has
## claimed before, its papers, the cover wanted, and the review - each
## question's kind, whether it is needed, what it is asked while, and the
## rules of its own. Nothing here is interface: the form (form.gd) and its
## steps (form_steps.gd) are made from this.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The activities a business may carry on are the insurer's list, data by
## sector, so the main activity is a searched choice NARROWED BY the sector
## chosen: a builder is offered roofing, not catering.

const COMPANY := &"company"
const ACTIVITIES := &"activities"
const EMPLOYEES := &"employees"
const ASSETS := &"assets"
const CLAIMS := &"claims"
const DOCUMENTS := &"documents"
const COVERAGE := &"coverage"
const REVIEW := &"review"
const POUNDS := "£"
const MEGABYTES_10 := 10485760
## The activities of each sector, as the insurer lists them.
const BY_SECTOR := {
	"retail": ["Bakery shop", "Bookshop", "Butcher", "Clothes shop", "Convenience store", "Florist", "Furniture shop", "Greengrocer", "Hardware shop", "Jeweller", "Newsagent", "Pharmacy", "Toy shop"],
	"hospitality": ["Bed and breakfast", "Café", "Caterer", "Coffee van", "Guest house", "Hotel", "Ice cream parlour", "Pub", "Restaurant", "Takeaway", "Wine bar"],
	"construction": ["Bricklayer", "Carpenter", "Electrician", "Flooring fitter", "Glazier", "Groundworker", "Painter and decorator", "Plasterer", "Plumber", "Roofer", "Scaffolder", "Tiler"],
	"manufacturing": ["Bakery", "Brewery", "Cabinet maker", "Clothing maker", "Food producer", "Metal fabricator", "Packaging maker", "Printer", "Signmaker", "Woodworker"],
	"professional": ["Accountant", "Architect", "Bookkeeper", "Consultant", "Designer", "Engineer", "Lawyer", "Marketing agency", "Recruiter", "Software developer", "Surveyor", "Translator"],
	"care": ["Beautician", "Childminder", "Dental practice", "Dog groomer", "Hairdresser", "Home carer", "Massage therapist", "Nursery", "Personal trainer", "Physiotherapist", "Vet"],
}


## The eight steps, each [key, words].
static func steps() -> Array:
	return [[COMPANY, GdChime.Phrase.of("Company details")], [ACTIVITIES, GdChime.Phrase.of("Business activities")], [EMPLOYEES, GdChime.Phrase.of("Employees")], [ASSETS, GdChime.Phrase.of("Assets")], [CLAIMS, GdChime.Phrase.of("Previous claims")], [DOCUMENTS, GdChime.Phrase.of("Supporting documents")], [COVERAGE, GdChime.Phrase.of("Coverage options")], [REVIEW, GdChime.Phrase.of("Review and send")]]


## Every question, in the order asked.
static func questions() -> Array:
	var vehicles := [&"vehicles", true]
	var claimed := [&"claimed", true]
	return [
		GdChime.Question.make(&"legal_name", COMPANY, GdChime.Phrase.of("Registered name of the business"), GdChime.Question.TEXT, {"needed": true}),
		GdChime.Question.make(&"trading_name", COMPANY, GdChime.Phrase.of("Trading name, if different"), GdChime.Question.TEXT),
		GdChime.Question.make(&"structure", COMPANY, GdChime.Phrase.of("How the business is set up"), GdChime.Question.CHOICE, {"needed": true, "options": _options([["sole", "Sole trader"], ["partnership", "Partnership"], ["limited", "Limited company"], ["charity", "Charity"]])}),
		GdChime.Question.make(&"company_number", COMPANY, GdChime.Phrase.of("Company registration number"), GdChime.Question.TEXT, {"says": GdChime.Phrase.of("Eight letters and figures, as on the register"), "rule": _company_number}),
		GdChime.Question.make(&"founded", COMPANY, GdChime.Phrase.of("Date the business started"), GdChime.Question.DAY, {"needed": true, "says": GdChime.Dates.shape(), "rule": _in_the_past}),
		GdChime.Question.make(&"email", COMPANY, GdChime.Phrase.of("Contact email"), GdChime.Question.TEXT, {"needed": true, "rule": _an_email}),
		GdChime.Question.make(&"phone", COMPANY, GdChime.Phrase.of("Contact phone number"), GdChime.Question.TEXT, {"rule": _a_phone}),
		GdChime.Question.make(&"sector", ACTIVITIES, GdChime.Phrase.of("Sector"), GdChime.Question.CHOICE, {"needed": true, "options": _options([["retail", "Retail"], ["hospitality", "Hospitality"], ["construction", "Construction"], ["manufacturing", "Manufacturing"], ["professional", "Professional services"], ["care", "Care and personal services"]])}),
		GdChime.Question.make(&"activity", ACTIVITIES, GdChime.Phrase.of("Main activity"), GdChime.Question.CHOICE, {"needed": true, "search": true, "narrowed_by": [&"sector", _activities()], "says": GdChime.Phrase.of("Type to search the activities of the sector chosen")}),
		GdChime.Question.make(&"turnover", ACTIVITIES, GdChime.Phrase.of("Annual turnover"), GdChime.Question.AMOUNT, {"needed": true, "mark": POUNDS, "rule": _more_than_nothing}),
		GdChime.Question.make(&"sells_online", ACTIVITIES, GdChime.Phrase.of("Does the business sell online?"), GdChime.Question.YES_NO, {"needed": true}),
		GdChime.Question.make(&"hazardous", ACTIVITIES, GdChime.Phrase.of("Does it work with hazardous materials?"), GdChime.Question.YES_NO, {"needed": true}),
		GdChime.Question.make(&"staff", EMPLOYEES, GdChime.Phrase.of("Number of employees"), GdChime.Question.QUANTITY, {"least": 0.0, "most": 500.0}),
		GdChime.Question.make(&"part_time", EMPLOYEES, GdChime.Phrase.of("Of whom part-time"), GdChime.Question.QUANTITY, {"least": 0.0, "most": 500.0, "rule": _no_more_than_the_staff}),
		GdChime.Question.make(&"payroll", EMPLOYEES, GdChime.Phrase.of("Annual payroll"), GdChime.Question.AMOUNT, {"mark": POUNDS, "rule": _a_payroll_for_staff}),
		GdChime.Question.make(&"heights", EMPLOYEES, GdChime.Phrase.of("Does anyone work above two metres?"), GdChime.Question.YES_NO, {"needed": true}),
		GdChime.Question.make(&"premises", ASSETS, GdChime.Phrase.of("Premises"), GdChime.Question.CHOICE, {"needed": true, "options": _options([["owned", "Owned"], ["leased", "Leased"], ["home", "Worked from home"], ["none", "No premises"]])}),
		GdChime.Question.make(&"buildings", ASSETS, GdChime.Phrase.of("Rebuild value of the buildings"), GdChime.Question.AMOUNT, {"needed": true, "mark": POUNDS, "while": [&"premises", "owned"]}),
		GdChime.Question.make(&"contents", ASSETS, GdChime.Phrase.of("Value of contents and equipment"), GdChime.Question.AMOUNT, {"needed": true, "mark": POUNDS}),
		GdChime.Question.make(&"stock", ASSETS, GdChime.Phrase.of("Value of stock"), GdChime.Question.AMOUNT, {"mark": POUNDS}),
		GdChime.Question.make(&"vehicles", ASSETS, GdChime.Phrase.of("Does the business own commercial vehicles?"), GdChime.Question.YES_NO, {"needed": true}),
		GdChime.Question.make(&"vehicle_count", ASSETS, GdChime.Phrase.of("How many vehicles"), GdChime.Question.QUANTITY, {"least": 1.0, "most": 50.0, "while": vehicles}),
		GdChime.Question.make(&"vehicle_kind", ASSETS, GdChime.Phrase.of("Kind of vehicle, mostly"), GdChime.Question.CHOICE, {"needed": true, "while": vehicles, "options": _options([["vans", "Vans"], ["lorries", "Lorries"], ["cars", "Cars"], ["plant", "Plant and specialist"]])}),
		GdChime.Question.make(&"vehicle_value", ASSETS, GdChime.Phrase.of("Value of the vehicles together"), GdChime.Question.AMOUNT, {"needed": true, "mark": POUNDS, "while": vehicles, "rule": _more_than_nothing}),
		GdChime.Question.make(&"young_drivers", ASSETS, GdChime.Phrase.of("Does anyone under 25 drive them?"), GdChime.Question.YES_NO, {"needed": true, "while": vehicles}),
		GdChime.Question.make(&"claimed", CLAIMS, GdChime.Phrase.of("Any insurance claims in the last five years?"), GdChime.Question.YES_NO, {"needed": true}),
		GdChime.Question.make(&"claim_count", CLAIMS, GdChime.Phrase.of("How many claims"), GdChime.Question.QUANTITY, {"least": 1.0, "most": 20.0, "while": claimed}),
		GdChime.Question.make(&"last_claim", CLAIMS, GdChime.Phrase.of("Date of the latest claim"), GdChime.Question.DAY, {"needed": true, "while": claimed, "says": GdChime.Dates.shape(), "rule": _within_five_years}),
		GdChime.Question.make(&"claims_paid", CLAIMS, GdChime.Phrase.of("Paid on those claims in all"), GdChime.Question.AMOUNT, {"needed": true, "mark": POUNDS, "while": claimed}),
		GdChime.Question.make(&"claim_story", CLAIMS, GdChime.Phrase.of("What happened, in a line"), GdChime.Question.TEXT, {"while": claimed}),
		GdChime.Question.make(&"accounts", DOCUMENTS, GdChime.Phrase.of("Latest accounts"), GdChime.Question.FILE, {"needed": true, "kinds": ["pdf"], "most_bytes": MEGABYTES_10, "says": GdChime.Phrase.of("A PDF of 10 MB at most")}),
		GdChime.Question.make(&"certificate", DOCUMENTS, GdChime.Phrase.of("Health and safety certificate"), GdChime.Question.FILE, {"kinds": ["pdf", "png", "jpg"], "most_bytes": MEGABYTES_10}),
		GdChime.Question.make(&"photo", DOCUMENTS, GdChime.Phrase.of("A photo of the premises"), GdChime.Question.FILE, {"kinds": ["png", "jpg"], "most_bytes": MEGABYTES_10}),
		GdChime.Question.make(&"cover_start", COVERAGE, GdChime.Phrase.of("Cover to start on"), GdChime.Question.DAY, {"needed": true, "says": GdChime.Dates.shape(), "rule": _within_ninety_days}),
		GdChime.Question.make(&"liability", COVERAGE, GdChime.Phrase.of("Public liability cover"), GdChime.Question.CHOICE, {"needed": true, "options": _options([["1m", "£1 million"], ["2m", "£2 million"], ["5m", "£5 million"], ["10m", "£10 million"]])}),
		GdChime.Question.make(&"employers", COVERAGE, GdChime.Phrase.of("Employers' liability cover"), GdChime.Question.YES_NO, {"needed": true, "rule": _employers_cover_for_staff}),
		GdChime.Question.make(&"excess", COVERAGE, GdChime.Phrase.of("Excess paid on each claim"), GdChime.Question.CHOICE, {"needed": true, "options": _options([["250", "£250"], ["500", "£500"], ["1000", "£1,000"]])}),
		GdChime.Question.make(&"notes", COVERAGE, GdChime.Phrase.of("Anything else the insurer should know"), GdChime.Question.TEXT),
	]


## Options from [value, English words] pairs, as a bound value that never moves.
static func _options(pairs: Array) -> GdChime.Bound:
	var options: Array = pairs.map(func(pair: Array) -> Dictionary: return {"value": pair[0], "words": GdChime.Phrase.of(pair[1])})
	return GdChime.Bound.new(func() -> Array: return options)


## Every sector's activities as options, the insurer's words being data.
static func _activities() -> Dictionary:
	var by_sector: Dictionary = {}
	# every sector, its activities as options
	for sector: String in BY_SECTOR:
		by_sector[sector] = BY_SECTOR[sector].map(func(activity: String) -> Dictionary: return {"value": activity.to_lower(), "words": activity})
	return by_sector


static func _company_number(number: Variant, form: Object) -> GdChime.Phrase:
	if form.value_of(&"structure") == "limited" and (number == null or not RegEx.create_from_string("^[A-Za-z0-9]{8}$").search(number.strip_edges())):
		return GdChime.Phrase.of("A limited company's number has eight letters and figures")
	return null


static func _in_the_past(day: Variant, _form: Object) -> GdChime.Phrase:
	return GdChime.Phrase.of("The date must not be in the future") if day != null and day > GdChime.Dates.today() else null


static func _an_email(email: Variant, _form: Object) -> GdChime.Phrase:
	return null if email == null or RegEx.create_from_string("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$").search(email) else GdChime.Phrase.of("Type an email address, like name@example.com")


static func _a_phone(phone: Variant, _form: Object) -> GdChime.Phrase:
	return null if phone == null or RegEx.create_from_string("^\\+?[0-9 ]{7,15}$").search(phone) else GdChime.Phrase.of("Type a phone number in figures")


static func _more_than_nothing(amount: Variant, _form: Object) -> GdChime.Phrase:
	return GdChime.Phrase.of("The amount must be more than nothing") if amount != null and amount <= 0.0 else null


static func _no_more_than_the_staff(part_time: Variant, form: Object) -> GdChime.Phrase:
	var staff: Variant = form.value_of(&"staff")
	return GdChime.Phrase.of("More part-time staff than employees") if part_time != null and part_time > (0.0 if staff == null else staff) else null


static func _a_payroll_for_staff(payroll: Variant, form: Object) -> GdChime.Phrase:
	var staff: Variant = form.value_of(&"staff")
	return GdChime.Phrase.of("With employees, a payroll is needed") if staff != null and staff > 0.0 and payroll == null else null


static func _within_five_years(day: Variant, _form: Object) -> GdChime.Phrase:
	if day == null:
		return null
	return GdChime.Phrase.of("Only claims of the last five years are asked for") if day < GdChime.Dates.today() - 5 * 365 or day > GdChime.Dates.today() else null


static func _within_ninety_days(day: Variant, _form: Object) -> GdChime.Phrase:
	if day == null:
		return null
	return GdChime.Phrase.of("Cover can start from today to ninety days on") if day < GdChime.Dates.today() or day > GdChime.Dates.today() + 90 else null


static func _employers_cover_for_staff(wanted: Variant, form: Object) -> GdChime.Phrase:
	var staff: Variant = form.value_of(&"staff")
	return GdChime.Phrase.of("Employers' liability is required by law with employees") if wanted == false and staff != null and staff > 0.0 else null
