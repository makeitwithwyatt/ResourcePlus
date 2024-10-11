@tool
class_name ResourceTree extends Tree

var tree_nodes: Dictionary = {}
var base_control: Control

func reset():
	clear()
	create_item()

func add_base_resource(resource):
	var parent = get_root()
	if resource["base"] != "Resource":
		parent = tree_nodes[resource["base"]]
	var item = create_item(parent)
	item.set_text(0, resource["class"])
	item.set_metadata(0,"Folder")
	var load_icon = base_control.get_theme_icon("Folder", "EditorIcons")
	item.set_icon(0, load_icon)
	tree_nodes[resource["class"]] = item
	return item

# Called when the node enters the scene tree for the first time.
func _ready():
	hide_root = true
	create_item()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
