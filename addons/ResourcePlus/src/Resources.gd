@tool
extends HBoxContainer

const MENU_ITEM_NAVIGATE = 0
const MENU_ITEM_CREATE = 1
const MENU_ITEM_COLOR = 2
const MENU_ITEM_OPEN_SCRIPT = 3

@onready var tree = $VBoxContainer/Tree

var base_control: Control
var resource_regex = RegEx.new()

var editor_file_system: EditorFileSystem
var dock_file_system: FileSystemDock

var _nodes = {}

var data : Resource_Saved_Data

func _ready():
	editor_file_system.filesystem_changed.connect(_on_filesystem_changed)
	data = load("res://addons/ResourcePlus/src/data.tres")
	collapse_check()

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

func _exit_() -> void:
	ResourceSaver.save(data,data.resource_path)


func _on_filesystem_changed():
	if not visible:
		return
	refresh()

func collapse_check():
	for i in _nodes:
		var text = i.get_text(0)
		if data.RESOURCE_COLLAPSED_VALUE.has(text):
			i.collapsed = data.RESOURCE_COLLAPSED_VALUE[text]

func refresh():
	tree.base_control = base_control
	

	
	##store collapsed identity
	for i in _nodes:
		data.RESOURCE_COLLAPSED_VALUE[i.get_text(0)] = i.collapsed

	
	_nodes.clear()
	tree.reset()

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
			var item = tree.add_base_resource(klass)
			_nodes[item] = klass
			class_nodes[klass["class"]] = item
			queue.append(klass["class"])


	var resource_files = find_resources(editor_file_system.get_filesystem())
	for resource in resource_files:
		if resource["base"] not in class_nodes:
			continue
		var item = tree.create_item(class_nodes[resource["base"]])
		var name = resource["path"].split("/")[-1].split(".")[0].capitalize()
		var icon = base_control.get_theme_icon("ResourcePreloader", "EditorIcons")
		item.set_icon(0, icon)
		item.set_text(0, name)
		_nodes[item] = resource


	if data != null:
		collapse_check()

	for i in _nodes:

		if i.get_metadata(0) == "Folder":
			process_colors(i)




func _on__item_selected():
	var item = tree.get_selected()
	if not item:
		return


func _on_gui_input(event:InputEvent):
	if event is not InputEventMouseButton: 
		return

	var mouse_pos = get_global_mouse_position()
	var item = tree.get_item_at_position(mouse_pos - tree.get_global_position())
		
	if event.button_index == MOUSE_BUTTON_RIGHT:
		
		if item == null:
			return
		
		if item:
			tree.set_selected(item, 0)
		if tree.get_selected():
			if "class" in _nodes[item]:
				$BaseMenu.set_item_text($BaseMenu.get_item_index(MENU_ITEM_CREATE), "Create new %s" % _nodes[item]["class"])
				$BaseMenu.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))
				if data.RESOURCE_SAVED_DATA.has(_nodes[item]["path"]):
					$BaseMenu.set_item_text($BaseMenu.get_item_index(MENU_ITEM_COLOR),"Change Color")
				else:
					$BaseMenu.set_item_text($BaseMenu.get_item_index(MENU_ITEM_COLOR),"Add Color")
			else:
				$InstanceMenu.popup(Rect2i(mouse_pos.x, mouse_pos.y, 0, 0))
	
	elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if item != null:
			if item.get_metadata(0) != "Folder":
				EditorInterface.edit_resource(load(_nodes[item]["path"]))
	
	
	
	#elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		#if item != null:
			#EditorInterface.edit_resource(load(_nodes[item]["path"]))
	




func _on_popup_menu_id_pressed(id:int):
	var item = tree.get_selected()
	if not item:
		return
	
	if id == MENU_ITEM_NAVIGATE:
		dock_file_system.navigate_to_path(_nodes[item]["path"])
	if id == MENU_ITEM_CREATE:
		$FileDialog.title = "Create new %s" % _nodes[item]["class"]
		$FileDialog.show()

	if id == MENU_ITEM_COLOR:
		$ColorPanel.show()

	if id == MENU_ITEM_OPEN_SCRIPT:
		EditorInterface.edit_resource(load(_nodes[item]["path"]))

func _on_file_dialog_file_selected(path:String):
	var item = tree.get_selected()
	if not item:
		return
	var klass = _nodes[item]
	var resource = load(klass["path"])
	var rez = resource.new()
	ResourceSaver.save(rez, path)


var all_collapsed := false


func _on_collapse_pressed() -> void:
	all_collapsed = !all_collapsed
	if all_collapsed:
		$VBoxContainer/PanelContainer/HBoxContainer/Collapse.text = "^"
	else:
		$VBoxContainer/PanelContainer/HBoxContainer/Collapse.text = "v"
	for i in _nodes:
		i.collapsed = all_collapsed

	for i in data.RESOURCE_COLLAPSED_VALUE:
		data.RESOURCE_COLLAPSED_VALUE[i] = all_collapsed

var SELECTED_COLOR : Color

func _on_color_picker_color_changed(color: Color) -> void:
	SELECTED_COLOR = color


func _on_color_panel_visibility_changed() -> void:
	var fold = tree.get_selected()
	var script = load(_nodes[fold]["path"])
	
	if data.RESOURCE_SAVED_DATA.has(_nodes[fold]["path"]):
		var color = data.RESOURCE_SAVED_DATA[_nodes[fold]["path"]]
		if $ColorPanel.visible:
			$ColorPanel/VBoxContainer/ColorPicker.color = color
	else:
		data.RESOURCE_SAVED_DATA[_nodes[fold]["path"]] = Color.BLACK


func process_colors(fold) -> void:



	if data != null:

		if data.RESOURCE_SAVED_DATA.has(_nodes[fold]["path"]):
			fold.set_custom_bg_color(0,data.RESOURCE_SAVED_DATA[_nodes[fold]["path"]] - Color(0,0,0,0.9))
			for j in fold.get_children():
				if j.get_custom_bg_color(0) == Color(0,0,0,1):
					j.set_custom_bg_color(0,data.RESOURCE_SAVED_DATA[_nodes[fold]["path"]] - Color(0,0,0,0.9))

func _on_select_pressed() -> void:
	$ColorPanel.hide()
	var fold = tree.get_selected()
	data.RESOURCE_SAVED_DATA[_nodes[fold]["path"]] = SELECTED_COLOR
	ResourceSaver.save(data,data.resource_path)
	process_colors(fold)
