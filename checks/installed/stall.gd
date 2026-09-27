extends ChimeApp

## The README's first screen, as a reader meets it: a stall that counts
## crates - a place, a button with its words, a model whose value is shown
## as it changes, and a refusal once the stall is full. Kept the same as the
## README's, line for line, so the example a reader copies is the one the
## installation check builds and presses.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of the gd-chime folder.

const COUNTS := &"counts_a_crate"

## The stall's crates: how many, and that ten is all it holds.
class Crates extends GdChime.Controller:
	var counted := value(0)

	func answers() -> Array[StringName]:
		return [COUNTS]

	func would(_action: StringName, _payload: Dictionary) -> GdChime.Phrase:
		return GdChime.Phrase.of("Ten crates is all the stall holds") if counted.read() >= 10 else null

	func told(_action: StringName, _payload: Dictionary) -> GdChime.Phrase:
		counted.set_value(counted.read() + 1)
		return null

func declare(register: GdChime.Actions) -> void:
	register.declare_all({COUNTS: ["Count a crate", GdChime.Actions.keys(KEY_C)]})

func describe() -> GdChime.Desc:
	var crates := Crates.new(chimes)
	var shown := crates.counted.map(func(count: Variant) -> GdChime.Phrase: return GdChime.Phrase.with("%d crates counted", [count]))
	return ui.app(&"stall", [ui.screen(&"counting", [ui.column([ui.text(shown), ui.button(COUNTS)])], crates)])
