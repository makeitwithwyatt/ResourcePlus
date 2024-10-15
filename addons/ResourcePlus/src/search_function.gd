@tool
extends TextEdit
@onready var tree: ResourceTree = $"../../../Tree"

var searching_for : String = ""

var SEARCH_ICON
var CANCEL_ICON

func _ready() -> void:

	$Cancel_Search.icon = tree.base_control.get_theme_icon("Search", "EditorIcons")

func _on_text_changed() -> void:


	SEARCH_ICON = tree.base_control.get_theme_icon("Search", "EditorIcons")
	CANCEL_ICON = tree.base_control.get_theme_icon("Close", "EditorIcons")

	
	searching_for = text

	if searching_for.length() == 0:
		$Cancel_Search.icon = SEARCH_ICON
		$Cancel_Search.disabled = true
		$Cancel_Search.mouse_filter = MOUSE_FILTER_IGNORE
		var current_item : TreeItem
		current_item = tree.get_root()
		while current_item != null:
			current_item.visible = true
			current_item = current_item.get_next_in_tree()

		return
	$Cancel_Search.icon = CANCEL_ICON
	$Cancel_Search.disabled = false
	$Cancel_Search.mouse_filter = MOUSE_FILTER_STOP
	var current_item : TreeItem
	current_item = tree.get_root().get_next_in_tree()
	
	while current_item != null:
		var current_text = current_item.get_text(0)
		if current_text.containsn(searching_for):
			current_item.visible = true
		else:
			current_item.visible = false
		current_item = current_item.get_next_in_tree()
	current_item = tree.get_root().get_next_in_tree()
	
	while current_item != null:
	
		if current_item.visible:
			
			
			var children = current_item.get_children()
			for i in children:
				i.visible = true
			
			
			var parent = current_item.get_parent()
			while parent != tree and parent != null:
				parent.visible = true
				parent = parent.get_parent()
				
		current_item = current_item.get_next_in_tree()


func _on_cancel_search_pressed() -> void:
	text = ""
	_on_text_changed()
	grab_focus()
