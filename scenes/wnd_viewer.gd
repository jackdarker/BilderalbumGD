extends Control

func _ready() -> void:
	# Optimization for Desktop-App to consume less resources
	# see Project->Run (advanced settings=true): 
	# 	low processor mode = true
	# 	max_fps =30
	# Project -> Physics->common
	# 	physics ticks per second = 6
	# also switch to mobile instead compatibility, this seems to reduce GPU greatly
	# -> this didnt work for my old pc as it has no d3d12
	# had to enable Rendering/Renderer/render method=gl_compatibility  which switch back to compatibility mode
	# GPU now around <1%, CPU <1%
	
	Global.db=$db
	%ImageList.list.get_children().map(
		func(x): 
			x.get_parent().remove_child(x)
			x.queue_free())
	%PopupMenu.id_pressed.connect(_selectedCtxtMenu)
	

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
		item.menuRequested.connect(_showCtxtMenu)
		%ImageList.list.add_child(item)
	updateView(path)
	
func updateView(path):
	_actual_image=path
	%TextureRect.texture=Global.loadImgToTexture(_actual_image,%TextureRect.size.x,%TextureRect.size.y)
	%WndTagger.displayImage(_actual_image)

var _ctxtItem=null
func _showCtxtMenu(path):
	_ctxtItem=path
	%PopupMenu.clear()
	%PopupMenu.add_item("Cancle", 1)
	%PopupMenu.add_item("Remove from list", 2)
	var _x=DisplayServer.mouse_get_position()	#takes multi-screen into acount
	#get_global_position()    is relativ to Canvas
	%PopupMenu.position=(_x)
	%PopupMenu.show()

func _selectedCtxtMenu(ID:int):
	if _ctxtItem:
		if ID==2:	#Remove
			for item in %ImageList.list.get_children():
				if(item.data==_ctxtItem):
					%ImageList.list.remove_child(item)
					break
	_ctxtItem=null


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
