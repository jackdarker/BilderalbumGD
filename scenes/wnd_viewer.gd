extends Control

func _ready() -> void:
	Global.db=$db
	%ImageList.list.get_children().map(
		func(x): 
			x.get_parent().remove_child(x)
			x.queue_free())
	pass

# see https://docs.godotengine.org/en/stable/tutorials/inputs/handling_quit_requests.html
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Global.saveToFile()
		get_tree().quit() # default behavior
	
var _actual_image=null	
func displayImage(path)->void:
	var _item=null
	for item in %ImageList.list.get_children():
		if(item.data==path):
			_item=item
	if(!_item):
		var item=ListItem.create_item(path)
		item.selected.connect(updateView)
		%ImageList.list.add_child(item)
	updateView(path)
	
func updateView(path):
	_actual_image=path
	%TextureRect.texture=Global.loadImgToTexture(_actual_image,%TextureRect.size.x,%TextureRect.size.y)
	%WndTagger.displayImage(_actual_image)

func _on_bt_new_browser_pressed() -> void:
	Global.createBrowser()

func _on_bt_settings_pressed() -> void:
	%WndSettings.process_mode=Node.PROCESS_MODE_ALWAYS
	%WndSettings.show()

#as resized is fred constantly it would waste a lot of processing if we continously resize image
func _on_texture_rect_resized() -> void:
	%TextureRect/ResizeTimer.start()

func _on_resize_timer_timeout() -> void:
	if _actual_image:
		updateView(_actual_image)

func _on_bt_edit_tags_pressed() -> void:
	%WndTagger.visible=!%WndTagger.visible


func _on_bt_edit_tags_2_pressed() -> void:
	%WndCreateTag.visible=!%WndCreateTag.visible


func _on_bt_new_finder_pressed() -> void:
	Global.createFinder()
