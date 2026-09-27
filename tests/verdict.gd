extends RefCounted

## Collects what a test found, and delivers the one line a harness reads.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every test states its properties into a verdict and hands it back. Keeping
## the wording and the exit code here rather than in each test is what makes a
## harness able to trust the last line: a format each test hand-rolled would be
## a convention, and conventions drift.
##
## A property is RUN through states() rather than called directly. GDScript
## abandons a function on a runtime error - comparing an Object with an int is
## one - and carries on with the next, so a property can stop before its first
## check and leave nothing behind to say so.
##
## Deliberately absent: no test discovery, no timing, no grouping, no expected
## failures. It holds a list and prints a sentence.

var _failures: Array[String] = []
var _checks: int = 0


## Run one property and require that it said something. Nothing is claimed
## about how many checks it should make, only that it reached one of them.
func states(property: Callable) -> void:
	var before := _checks
	await property.call()
	if _checks == before:
		_failures.append("%s stated nothing" % property.get_method())


## Record a property that was meant to hold. Failures are collected rather than
## asserted, so one run reports every broken property instead of only the first.
func check(held: bool, what: String) -> void:
	_checks += 1
	if not held:
		_failures.append(what)


## Print the result and return the exit code the test should quit with. Takes
## the caller's own script so the name it reports cannot drift from the file it
## is in - a harness compares the two, and a mismatch means it ran the wrong one.
func deliver(test_script: Script) -> int:
	var named := test_script.resource_path.get_file().get_basename()
	# every failure found, one line each, so one run reports all of them
	for failure: String in _failures:
		print("  NOT TRUE: ", failure)
	if _failures.is_empty():
		print("PASSED ", named)
		return 0
	print("FAILED %s (%d)" % [named, _failures.size()])
	return 1
