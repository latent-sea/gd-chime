extends RefCounted

const Ui := preload("res://addons/gd_chime/components/primitives/ui.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Taken := preload("res://addons/gd_chime/taken.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The bottom lines of the guided demo: the record, the prompt, the last
## deed and the last command, each a bound value re-read as what it read moves.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.


static func make(ui: Ui, taken: Taken, prompts: Prompts, deeds: Object, commands: Commands) -> Desc:
	var record: Bound = ui.bound(taken.get_taken).map(func(done: Array) -> Phrase: return Phrase.with("Taken: %s", [", ".join(PackedStringArray(done))]))
	# the prompt's words are the register's English, said as words; what glows and whose it is are names
	var prompt: Bound = ui.bound(prompts.get_words).map(func(words: String) -> Phrase: return Phrase.with("Prompt: %s - %s (%s)", [prompts.get_glowing(), Phrase.of(words), prompts.get_source()]))
	var deed: Bound = ui.bound(deeds.get_last).map(func(last: Phrase) -> Phrase: return Phrase.with("Last deed: %s", [last]))
	# the last command's action, a name, and its answer - a phrase - or done when there was none
	var command: Bound = ui.bound(commands.get_last).map(func(last: Dictionary) -> Phrase: return Phrase.of("Last command: none") if last.is_empty() else Phrase.with("Last command: %s -> %s", [last["action"], Phrase.of("Done") if last["answer"] == null else last["answer"]]))
	var lines: Array = []
	for line: RefCounted in [record, prompt, deed, command]:
		lines.append(ui.text(line, DemoTheme.READOUT))
	return ui.column(lines, DemoTheme.TIGHT)
