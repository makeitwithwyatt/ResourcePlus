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
	
	if resource["class"] == "Resource_Saved_Data":
		return
	
	var item = create_item(parent)
	item.set_text(0, resource["class"])
	item.set_metadata(0,"Folder")
	
	var icon = base_control.get_theme_icon("Folder", "EditorIcons")

	if resource["icon"].length() != 0:
		icon = load(resource["icon"])
	
	item.set_meta("ICON",icon)
	
	item.set_icon(0, base_control.get_theme_icon("Folder", "EditorIcons"))
	tree_nodes[resource["class"]] = item
	return item

# Called when the node enters the scene tree for the first time.
func _ready():
	hide_root = true
	create_item()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
