extends SceneTree

## A cancellation token (token.gd): live until cancelled, dead with the token
## it was issued under, and cancelled twice is cancelled.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_token.gd

const Token := preload("res://addons/gd_chime/token.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_a_token_is_live_until_cancelled_and_stays_cancelled)
	await _verdict.states(_a_token_issued_under_another_is_dead_with_it_and_on_its_own)
	quit(_verdict.deliver(get_script()))


func _a_token_is_live_until_cancelled_and_stays_cancelled() -> void:
	var token := Token.new()
	_verdict.check(token.is_live(), "issued, it is live")
	token.cancel()
	_verdict.check(not token.is_live(), "cancelled, it is dead")
	token.cancel()
	_verdict.check(not token.is_live(), "and cancelled again, still dead, without a word")


func _a_token_issued_under_another_is_dead_with_it_and_on_its_own() -> void:
	var place := Token.new()
	var list := Token.new(place)
	_verdict.check(list.is_live(), "issued under a live token, it is live")
	list.cancel()
	_verdict.check(not list.is_live() and place.is_live(), "cancelled on its own, it is dead and the one above stands")
	var again := Token.new(place)
	place.cancel()
	_verdict.check(not again.is_live(), "and the one above cancelled, a token under it is dead without being told")
