@tool
extends VBoxContainer

const MENU_ITEM_NAVIGATE = 0
const MENU_ITEM_CREATE = 1

var base_control: Control
var resource_regex = RegEx.new()

var editor_file_system: EditorFileSystem
var dock_file_system: FileSystemDock

var tree_nodes = {}

func _ready():
	editor_file_system.filesystem_changed.connect(_on_filesystem_changed)

func find_resources(dir: EditorFileSystemDirectory) -> Array:
	var results: Array = []
	for idx in range(dir.get_file_count()):
		var file_type = dir.get_file_type(idx)
		if file_type != "Resource":
			continue

		var scene = FileAccess.open(dir.get_file_path(idx), FileAccess.READ)
		var content = scene.get_as_text()
		scene.close()
		resource_regex.compile("script_class=\"(\\w+)\"")
		var resource_result = resource_regex.search(content)
		if resource_result:
			results.append({
				"path": dir.get_file_path(idx),
				"base": resource_result.get_string(1)
			})
	for idx in range(dir.get_subdir_count()):
		results = results + find_resources(dir.get_subdir(idx))
	return results

func _on_visibility_changed():
	if not visible:
		return
	refresh()

func _on_filesystem_changed():
	if not visible:
		return
	refresh()

func refresh():
	$Tree.base_control = base_control
	tree_nodes.clear()
	$Tree.reset()

	var classes = ProjectSettings.get_global_class_list()
	var memo = {}
	for klass in classes:
		memo[klass["class"]] = klass
	
	var class_map = {}
	for name in memo:
		var start = memo[name]
		var klass = memo[name]
		while true:
			if memo[klass["class"]]["base"] == "Resource":
				if start["base"] not in class_map:
					class_map[start["base"]] = []
				class_map[start["base"]].append(start)
				break
			if klass["base"] not in memo:
				break
			klass = memo[klass["base"]]

	var queue = ["Resource"]
	var class_nodes = {}
	while len(queue) > 0:
		var base = queue.pop_front()
		if base not in class_map:
			continue
		for klass in class_map[base]:
			var item = $Tree.add_base_resource(klass)
			tree_nodes[item] = klass
			class_nodes[klass["class"]] = item
			queue.append(klass["class"])

	var resource_files = find_resources(editor_file_system.get_filesystem())
	for resource in resource_files:
		if resource["base"] not in class_nodes:
			continue
		var item = $Tree.create_item(class_nodes[resource["base"]])
		var name = resource["path"].split("/")[-1].split(".")[0].capitalize()
		var icon = base_control.get_theme_icon("ResourcePreloader", "EditorIcons")
		item.set_icon(0, icon)
		item.set_text(0, name)
		tree_nodes[item] = resource


func _on_tree_item_selected():
	var item = $Tree.get_selected()
	if not item:
		return

func _on_tree_gui_input(event:InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		var mouse_pos = get_global_mouse_position()
		var item = $Tree.get_item_at_position(mouse_pos - $Tree.get_global_position())
		if item:
			$Tree.set_selected(item, 0)
		if $Tree.get_selected():
			if "class" in tree_nodes[item]:
				$BaseMenu.set_item_text($BaseMenu.get_item_index(MENU_ITEM_CREATE), "Create new %s" % tree_nodes[item]["class"])
				$BaseMenu.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))
			else:
				$InstanceMenu.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))

func _on_popup_menu_id_pressed(id:int):
	var item = $Tree.get_selected()
	if not item:
		return
	if id == MENU_ITEM_NAVIGATE:
		dock_file_system.navigate_to_path(tree_nodes[item]["path"])
	if id == MENU_ITEM_CREATE:
		$FileDialog.title = "Create new %s" % tree_nodes[item]["class"]
		$FileDialog.show()

func _on_file_dialog_file_selected(path:String):
	var item = $Tree.get_selected()
	if not item:
		return
	var klass = tree_nodes[item]
	var resource = load(klass["path"])
	var rez = resource.new()
	ResourceSaver.save(rez, path)