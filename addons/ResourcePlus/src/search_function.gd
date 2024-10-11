@tool
extends TextEdit
@onready var tree: ResourceTree = $"../../../Tree"

var searching_for : String = ""

func _on_text_changed() -> void:

		
	searching_for = text

	if searching_for.length() == 0:
		var current_item : TreeItem
		current_item = tree.get_root()
		while current_item != null:
			current_item.visible = true
			current_item = current_item.get_next_in_tree()

		return

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
