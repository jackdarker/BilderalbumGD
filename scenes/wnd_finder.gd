extends Window

signal selected(path:String)

@onready var tags_assigned = $Panel/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/ScrollContainer/tags_assigned
@onready var tags_unassigned=$Panel/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/ScrollContainer2/tags_unassigned
@onready var tags_all=$Panel/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/ScrollContainer3/tags_all

func _ready():
	%ImageList.bt_prev.pressed.connect(switchPage.bind(-1,true))
	%ImageList.bt_next.pressed.connect(switchPage.bind(1,true))
	%ImageList.bt_page.item_selected.connect(switchPage.bind(false))

#TODO reload tags if there was a change in db

func _loadTags():
	for item in tags_assigned.get_children():
		tags_assigned.remove_child(item)
		
	for item in tags_unassigned.get_children():
		tags_unassigned.remove_child(item)
	
	for item in tags_all.get_children():
		tags_all.remove_child(item)
		
	var results
	results=Global.db.findTags([])
	for item in results:
		var tag = Tag.create_tag(item["ID"],item["groupID"],item["name"],item["fgColor"],item["color"])
		tag.pressed.connect(toggleTag.bind(tag))
		tags_all.add_child(tag)

func toggleTag(item):
	if item.get_parent()==tags_all:
		item.get_parent().remove_child(item)
		tags_assigned.add_child(item)
	elif item.get_parent()==tags_assigned:
		item.get_parent().remove_child(item)
		tags_unassigned.add_child(item)
	else:
		item.get_parent().remove_child(item)
		tags_all.add_child(item)
	pass

func _on_close_requested() -> void:
	self.visible=false

func switchPage(increment,relative):
	var page=%ImageList.page
	if(relative):
		page+=increment
	search(page)

func search(page:int):
	_clearImgList()
	var _tags:Array[String]=[]
	var _notags:Array[String]=[]
	for item in tags_assigned.get_children():
		_tags.push_back(item.label)
	for item in tags_unassigned.get_children():
		_notags.push_back(item.label)
	var results =Global.db.findPostByTag(_tags,_notags)
	var start=Global.settings.Listitems*page
	var end=Global.settings.Listitems*(1+page)
	var count=0
	for item in results:
		if (count>=start && count <end):
			var _item:ListItem=ListItem.create_item(item["fileName"])
			_item.selected.connect(selected.emit)
			%ImageList.list.add_child(_item)
		count=count+1
	%ImageList.updatePageCtrl(page,ceili(count/Global.settings.Listitems))

func _on_bt_search_pressed() -> void:
	search(0)
	
	
func _clearImgList()->void:
	var node=%ImageList.list
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()


func _on_visibility_changed() -> void:
	if self.visible:
		_clearImgList.call_deferred()
		_loadTags.call_deferred()
