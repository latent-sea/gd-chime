extends RefCounted

## The data layer: the world's array, served from a thread of its own.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Below the models. It holds the array the table is a window onto - here in
## memory; in a real one, a database or a server - and answers requests for a
## page of it, or for one more at the front. It knows nothing of bells,
## screens or the tree. A request carries a callable to answer, and the answer
## is delivered to the MAIN thread, deferred, so whoever asked runs on the
## thread it lives on and rings its bell from there.
##
## One worker thread serves every request in the order made, and takes as long
## as it takes - so an answer never overtakes an earlier request, and a page
## asked for before an add describes the array before it. Here it is made to take a while on purpose, in a loop that
## HOLDS A CORE rather than sleeping, so the main thread staying alive through
## it is something to watch rather than something to claim.
##
## stop() joins the thread and cuts a held core short. Called by whoever made
## this, on the way out: a thread left running is an error the engine reports
## at exit.
##
## Deliberately absent: cancelling one request, and more than one worker.
## Both are pure additions the day something needs them.

const PAGE := 4

var _thread := Thread.new()
var _lock := Mutex.new()
var _wake := Semaphore.new()
var _queue: Array[Dictionary] = []
var _stopping: bool = false

var _arrivals: Array[int] = []  # newest first, and the world's own
var _add_ms: int
var _page_ms: int


func _init(add_ms: int, page_ms: int, already: int) -> void:
	_add_ms = add_ms
	_page_ms = page_ms
	# the world before anyone looks at it, newest first
	for number: int in range(already, 0, -1):
		_arrivals.append(number)
	_thread.start(_serve)


## Ask for one page. Answered with the page's first index, its arrivals, and
## the count of the whole array.
func fetch_page(page: int, answer: Callable) -> void:
	_post({"what": &"page", "page": page, "answer": answer})


## Ask for one more at the front. Answered with its number and the new count.
func add(answer: Callable) -> void:
	_post({"what": &"add", "answer": answer})


func is_serving() -> bool:
	return _thread.is_alive()


func stop() -> void:
	_lock.lock()
	_stopping = true
	_lock.unlock()
	_wake.post()
	_thread.wait_to_finish()


func _post(request: Dictionary) -> void:
	_lock.lock()
	_queue.append(request)
	_lock.unlock()
	_wake.post()


## The worker. Sleeps until posted, takes the next request, holds a core for
## as long as that kind takes, and answers on the main thread.
func _serve() -> void:
	# a request each time the worker is posted, until it is told to stop
	while true:
		_wake.wait()
		_lock.lock()
		var stopping := _stopping
		var request: Dictionary = {} if _queue.is_empty() else _queue.pop_front()
		_lock.unlock()
		if stopping:
			return
		var answer: Dictionary = {}
		match request["what"]:
			&"add":
				_hold(_add_ms)
				_arrivals.push_front(_arrivals.size() + 1)
				answer = {"arrival": _arrivals[0], "count": _arrivals.size()}
			&"page":
				_hold(_page_ms)
				var first: int = request["page"] * PAGE
				answer = {"first": first, "arrivals": _arrivals.slice(first, first + PAGE), "count": _arrivals.size()}
		request["answer"].call_deferred(answer)


## Hold a core for this long, or until told to stop.
func _hold(ms: int) -> void:
	var until := Time.get_ticks_msec() + ms
	# a busy loop, not a sleep: the core is genuinely taken for the whole time
	while Time.get_ticks_msec() < until:
		_lock.lock()
		var stopping := _stopping
		_lock.unlock()
		if stopping:
			return
