@tool
extends EditorPlugin

var resource_type
var plugin
var dock_item

func _enter_tree():
	plugin = preload("./src/Resources.tscn")
	dock_item = plugin.instantiate()
	dock_item.dock_file_system = get_editor_interface().get_file_system_dock()
	dock_item.editor_file_system = get_editor_interface().get_resource_filesystem()
	dock_item.base_control = get_editor_interface().get_base_control()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock_item)


func _exit_tree():
	remove_control_from_docks(dock_item)