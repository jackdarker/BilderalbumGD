extends Window

@onready var tags_assigned = $Panel/MarginContainer/VBoxContainer/GridContainer/ScrollContainer/tags_assigned
@onready var tags_unassigned=$Panel/MarginContainer/VBoxContainer/GridContainer/ScrollContainer2/tags_unassigned
@onready var filename=$Panel/MarginContainer/VBoxContainer/lb_image

var _actual_image:String
var _postID:int
func displayImage(path)->void:
	%bt_ok.disabled=true
	%bt_cancle.disabled=true
	_actual_image=path
	var results=Global.db.findPost(_actual_image)
	_postID=-1
	if(results.size()>=1):
		_postID=results[0]["postID"]
		%cnt_rating.value=results[0]["favRating"]
	else:
		%cnt_rating.value=0
	_loadTags(_postID)
	filename.text=_actual_image.get_file() + "    " + str(_postID)

func _loadTags(postID):
	for item in tags_assigned.get_children():
		tags_assigned.remove_child(item)
	for item in tags_unassigned.get_children():
		tags_unassigned.remove_child(item)
	var results=Global.db.findPostTags(postID)
	var _tagids:Array[int]=[]
	for item in results:
		_tagids.push_back(item["ID"])
		var tag = Tag.create_tag(item["ID"],item["groupID"],item["name"],item["fgColor"],item["color"])
		tag.pressed.connect(toggleTag.bind(tag))
		tags_assigned.add_child(tag)

	results=Global.db.findTags(_tagids)
	for item in results:
		var tag = Tag.create_tag(item["ID"],item["groupID"],item["name"],item["fgColor"],item["color"])
		tag.pressed.connect(toggleTag.bind(tag))
		tags_unassigned.add_child(tag)

func _on_cnt_rating_value_changed(value: float) -> void:
	%bt_ok.disabled=false
	%bt_cancle.disabled=false

func toggleTag(item):
	%bt_ok.disabled=false
	%bt_cancle.disabled=false
	if item.get_parent()==tags_unassigned:
		item.get_parent().remove_child(item)
		tags_assigned.add_child(item)
	else:
		item.get_parent().remove_child(item)
		tags_unassigned.add_child(item)
	pass
	
func _on_visibility_changed() -> void:
	if self.visible:
		pass

func _on_bt_ok_pressed() -> void:
	var _tagids:Array[int]=[]
	for item in tags_assigned.get_children():
		if(item.ID>0):
			_tagids.push_back(item.ID)
	
	_postID=Global.db.createPost({"filename":_actual_image,"name":_actual_image.get_file(),
			"favRating":%cnt_rating.value})
	Global.db.assignTagToPost(_postID,_tagids)
	displayImage(_actual_image)


func _on_bt_cancle_pressed() -> void:
	displayImage(_actual_image)


func _on_close_requested() -> void:
	self.visible=false
