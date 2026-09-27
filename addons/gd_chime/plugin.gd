@tool
extends EditorPlugin

## The editor plugin: what the editor runs when gd-chime is enabled, which
## is nothing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Enabling the plugin is what puts the addon in a project; the two global
## names an application uses, GdChime and ChimeApp, are class_name
## declarations the editor's own scan registers, and an application is a
## node put in a scene. So there is no autoload to add, no dock, no menu
## and no setting to write - a plugin that registered any of those would be
## a second way the framework reaches a project, beside
## GdChime.apply_project_settings(), and nothing outside an app's own subtree
## is written except by that one explicit call.
##
## Deliberately absent: undoing anything on being disabled, since nothing
## was done on being enabled.


func _enter_tree() -> void:
	pass
