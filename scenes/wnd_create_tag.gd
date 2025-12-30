extends Window

@onready var groups=$Panel/MarginContainer/TabContainer/Manage_Groups/VBoxContainer/GridContainer/ScrollContainer/taggroups
@onready var txt_group=$Panel/MarginContainer/TabContainer/Manage_Groups/VBoxContainer/GridContainer/VBoxContainer/txt_group
@onready var col_bg=$Panel/MarginContainer/TabContainer/Manage_Groups/VBoxContainer/GridContainer/VBoxContainer/color_bg
@onready var col_fg=$Panel/MarginContainer/TabContainer/Manage_Groups/VBoxContainer/GridContainer/VBoxContainer/color_fg
@onready var tags=$Panel/MarginContainer/TabContainer/Manage_Tags/VBoxContainer2/GridContainer/ScrollContainer/tags
@onready var sel_group=$Panel/MarginContainer/TabContainer/Manage_Tags/VBoxContainer2/GridContainer/VBoxContainer/sel_group
@onready var txt_tag=$Panel/MarginContainer/TabContainer/Manage_Tags/VBoxContainer2/GridContainer/VBoxContainer/txt_tag

func _on_visibility_changed() -> void:
	if self.visible:
		_on_tab_container_tab_selected($Panel/MarginContainer/TabContainer.current_tab)
		pass

func _loadTagGroups():
	sel_group.clear()
	%bt_add_group.disabled=true
	for item in groups.get_children():
		groups.remove_child(item)
		item.queue_free()
		
	var results=Global.db.findTagGroups()
	for item in results:
		var group = Tag.create_tag(item["ID"],item["ID"],item["name"],item["fgColor"],item["color"])
		group.pressed.connect(groupEdit.bind(group))
		groups.add_child(group)
		sel_group.add_item(group.label,group.ID)

func groupEdit(item):
	txt_group.text=item.label
	col_bg.color=item.bgcolor

func _on_txt_group_text_changed() -> void:
	validate_groupedit()
	pass # Replace with function body.

func validate_groupedit():
	if(txt_group.text!=""):
		%bt_add_group.disabled=false
	else:
		%bt_add_group.disabled=true
		
func _on_bt_add_group_pressed() -> void:
	Global.db.createTagGroup({"name":txt_group.text,"color":col_bg.color.to_html(),
		"fgcolor":col_fg.color.to_html(),"shape":""});
	_loadTagGroups()


func _on_tab_container_tab_selected(tab: int) -> void:
	if !is_node_ready():
		return
	_loadTagGroups()
	_loadTags()

func _loadTags():
	%bt_add_tag.disabled=true
	for item in tags.get_children():
		tags.remove_child(item)
		item.queue_free()
		
	var results=Global.db.findTags([])
	for item in results:
		var tag = Tag.create_tag(item["ID"],item["groupID"],item["name"],item["fgColor"],item["color"])
		tag.pressed.connect(tagEdit.bind(tag))
		tags.add_child(tag)

func tagEdit(item):
	txt_tag.text=item.label
	sel_group.select(sel_group.get_item_index(item.groupID))

func validate_tagedit():
	if(txt_tag.text!=""):
		%bt_add_tag.disabled=false
	else:
		%bt_add_tag.disabled=true

func _on_txt_tag_text_changed() -> void:
	validate_tagedit()
	
func _on_sel_group_item_selected(index: int) -> void:
	validate_tagedit()

func _on_bt_add_tag_pressed() -> void:
	Global.db.createTag({"name":txt_tag.text,
		"groupID":sel_group.get_item_id(sel_group.selected)});
	_loadTags()

func _on_close_requested() -> void:
	self.visible=false

func _on_color_fg_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed && event.button_index==MOUSE_BUTTON_LEFT:
			pass	#selected.emit(self.text)
