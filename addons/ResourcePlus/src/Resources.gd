@tool
extends HBoxContainer

const MENU_ITEM_NAVIGATE = 0
const MENU_ITEM_CREATE = 1
const MENU_ITEM_COLOR = 4
const MENU_ITEM_CHANGE_COLOR = 6

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
	
	var prev_tree = {}
	
	##store collapsed identity
	for i in tree_nodes:
		prev_tree[i.get_text(0)] = i.collapsed

	
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


			#item.font_color = load(tree_nodes[item]).COLOR_HINT
			class_nodes[klass["class"]] = item
			queue.append(klass["class"])
	#print(class_nodes)

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


	for i in tree_nodes:
		var text = i.get_text(0)
		i.collapsed = prev_tree[text]

	for i in tree_nodes:

		if i.get_metadata(0) == "Folder":
			var script = load(tree_nodes[i]["path"])
			if script.has_meta("COLOR_HINT"):
				i.set_custom_bg_color(0,script.get_meta("COLOR_HINT") - Color(0,0,0,0.9))
				for j in i.get_children():
					j.set_custom_bg_color(0,script.get_meta("COLOR_HINT") - Color(0,0,0,0.9))

	#for i in prev_tree:
		##print(i)
		#print(tree_nodes)
		#print(tree_nodes[i])
		#if i == tree_nodes[i]:
			#print("yah")


func _on_tree_item_selected():
	var item = $Tree.get_selected()
	if not item:
		return

# should fully replace the existing function
func _on_tree_gui_input(event:InputEvent):
	if event is not InputEventMouseButton: 
		return

	var mouse_pos = get_global_mouse_position()
	var item = $Tree.get_item_at_position(mouse_pos - $Tree.get_global_position())
		
	if event.button_index == MOUSE_BUTTON_RIGHT:
		
		if item == null:
			return
		
		if item:
			$Tree.set_selected(item, 0)
		if $Tree.get_selected():
			if "class" in tree_nodes[item]:
				$BaseMenu.set_item_text($BaseMenu.get_item_index(MENU_ITEM_CREATE), "Create new %s" % tree_nodes[item]["class"])
				$BaseMenu.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))
				var script = load(tree_nodes[item]["path"])
				if script.has_meta("COLOR_HINT"):
					$BaseMenu.set_item_text(4,"Change Color")
				else:
					$BaseMenu.set_item_text(4,"Add Color")
			else:
				$InstanceMenu.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))
	
	elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		if item != null:
			EditorInterface.edit_resource(load(tree_nodes[item]["path"]))
	
	elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if item != null:
			if item.get_metadata(0) != "Folder":
				EditorInterface.edit_resource(load(tree_nodes[item]["path"]))



func _on_popup_menu_id_pressed(id:int):
	var item = $Tree.get_selected()
	if not item:
		return
	if id == MENU_ITEM_NAVIGATE:
		dock_file_system.navigate_to_path(tree_nodes[item]["path"])
	if id == MENU_ITEM_CREATE:
		$FileDialog.title = "Create new %s" % tree_nodes[item]["class"]
		$FileDialog.show()

	if id == MENU_ITEM_COLOR:
		$ColorPanel.show()

	if id == MENU_ITEM_CHANGE_COLOR:
		$ColorPanel.show()

func _on_file_dialog_file_selected(path:String):
	var item = $Tree.get_selected()
	if not item:
		return
	var klass = tree_nodes[item]
	var resource = load(klass["path"])
	var rez = resource.new()
	ResourceSaver.save(rez, path)


var all_collapsed := false


func _on_collapse_pressed() -> void:
	all_collapsed = !all_collapsed
	if all_collapsed:
		$Collapse.text = "^"
	else:
		$Collapse.text = "v"
	for i in tree_nodes:
		i.collapsed = all_collapsed


var SELECTED_COLOR : Color

func _on_color_picker_color_changed(color: Color) -> void:
	SELECTED_COLOR = color


func _on_color_panel_visibility_changed() -> void:
	var fold = $Tree.get_selected()
	var script = load(tree_nodes[fold]["path"])
	if !script.has_meta("COLOR_HINT"):
		script.set_meta("COLOR_HINT",Color.BLACK)
	else:
		if $ColorPanel.visible:
			$ColorPanel/VBoxContainer/ColorPicker.color = script.get_meta("COLOR_HINT")


func _on_select_pressed() -> void:
	$ColorPanel.hide()
	var fold = $Tree.get_selected()
	var script = load(tree_nodes[fold]["path"])

	script.set_meta("COLOR_HINT",SELECTED_COLOR)
	fold.set_custom_bg_color(0,script.get_meta("COLOR_HINT") - Color(0,0,0,0.9))
	for j in fold.get_children():
		j.set_custom_bg_color(0,script.get_meta("COLOR_HINT") - Color(0,0,0,0.9))
