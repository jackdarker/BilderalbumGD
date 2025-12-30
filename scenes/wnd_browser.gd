extends Window
## Note: disable "embed subwindows" in project settings or min/maximize button wont show

signal selected(path:String)

@onready var SceneListItem = load("res://scenes/image_list_item.tscn")

var UID:int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%ImageList.bt_prev.pressed.connect(switchPage.bind(-1,true))
	%ImageList.bt_next.pressed.connect(switchPage.bind(1,true))
	%ImageList.bt_page.item_selected.connect(switchPage.bind(false))
	
	%ImageList.list.get_parent().can_drop=can_drop_file
	%ImageList.list.get_parent().drop=drop_file
	$WndMove.done.connect(switchPage.bind(0,true))
	$WndMove.visible=false
	$WndCreate.visible=false
	Global.file_moved.connect(extRefresh)
	item_created.connect(updateList)
	all_item_created.connect(%ImageList.updatePageCtrl)
	buildTree()

func can_drop_file(at_position: Vector2, data: Variant):
	return(data is String)

func drop_file(at_position: Vector2, data: Variant):
	$WndMove.from=(data as String)
	$WndMove.to=actual_dir
	$WndMove.show()
	pass

func extRefresh(path:String):
	#on notification of filemove
	if(actual_dir!=path.get_base_dir()):
		return
	switchPage(0,true)

	
func saveData()->Dictionary:
	var data ={
		"scene" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"UID":UID,
		"x":position.x,
		"y":position.y,
		"w":size.x,
		"h":size.y,
		"actual_dir":actual_dir
	}
	return data

func loadData(data: Dictionary):
	position.x = data["x"]
	position.y = data["y"]
	size.x=data["w"]
	size.y=data["h"]
	UID=data["UID"]
	if (data["actual_dir"]):
		navigateTo.call_deferred(data["actual_dir"])
		
func _on_file_dialog_file_selected(path: String) -> void:
	# Load an image of any format supported by Godot from the filesystem.
	var image = Image.load_from_file(path)
	image.resize(100,100)
	var texture = ImageTexture.create_from_image(image)
	#texture.set_size_override(Vector2(100,100))
	%TextureRect.texture=texture

func _displayImage(path)->void:	
	selected.emit(path)

func _clearImgList()->void:
	var node=%ImageList.list
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()

func _clearDirTree(item:TreeItem)->void:
	if item:
		for n in item.get_children():
			n.free()
	else:
		%Tree.clear()
var _item:TreeItem
func navigateTo(path:String,force:bool=true):
	#force==true: expand the directory-tree to match path
	#force==false: if the path is unfolded, update the second-last dir to refresh new/deleted subdirs
	var _dirs=path.split("/")
	_item = %Tree.get_root()
	var _subitems
	for i in _dirs.size():
		_subitems=_item.get_children()
		for _subitem in _subitems:
			if (_dirs[i]== _subitem.get_text(0)):
				_item=_subitem	#dir already in tree, step deeper
				if(force):
					_appendDir(_item)
					#_item.collapsed=false
				else:
					if(!_item.collapsed):
						_appendDir(_item)
						#_item.collapsed=false
				break
			else:
				if(force && i==0):
					#_item.set_collapsed_recursive(true)
					pass
	if(force):
		var t=_item.get_text(0)
		_item.uncollapse_tree()
		_item.get_tree().set_selected(_item,0)
	pass


func buildTree() -> void:
	_clearDirTree(null)
	var tree=%Tree
	var root:TreeItem = tree.create_item()
	tree.hide_root = true
	root.set_metadata(0,"")
	var d=DirAccess.get_drive_count()
	for i in d: #add drives to root
		var drive:TreeItem=tree.create_item(root)
		var letter=DirAccess.get_drive_name(i)
		drive.set_text(0,letter)
		drive.set_metadata(0,letter)
		drive.collapsed=true

	_appendDir(root)

func _getNodeByText(parent:TreeItem,text:String)->TreeItem:
	var _nodes=parent.get_children()
	for _node in _nodes:
		if(_node.get_text(0)==text):
			return(_node)
	return(null)
	
func _appendDir(item: TreeItem)->void:
	if !is_inside_tree():
		return
	var tree=%Tree
	var full_path:String=item.get_metadata(0)
	if full_path=="":	
		for drive in item.get_children():
			_appendDir(drive)
	else:
		var dir = DirAccess.open(full_path)
		if dir:
			#_clearDirTree(item)	#instead of recreating all nodes we try to reuse existing
			var _itemsKeep=[]
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					var node:TreeItem=_getNodeByText(item,file_name)
					if(!node):
						node=tree.create_item(item)
						node.set_text(0,file_name)
						node.set_metadata(0,dir.get_current_dir().path_join(file_name))
						tree.create_item(node)	#add a placeholder for digging deeper
						node.collapsed=true
					elif node.get_children().size()<=0:
						tree.create_item(node)	#if there isnt at least one childnode, the node would not be uncollapsable and appendDir would not be triggered
						node.collapsed=true
					_itemsKeep.push_back(file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
			for node in item.get_children():
				if(!_itemsKeep.find(node.get_text(0))>=0):
					node.free()
		else:
			print("An error occurred when trying to access the path.")

func _on_tree_item_collapsed(item: TreeItem) -> void:
	if !item.collapsed:
		call_deferred("_appendDir",item)	#if called directly tree.create_item(item) returns null?!

var actual_dir:String
func _on_tree_item_selected() -> void:
	actual_dir=%Tree.get_selected().get_metadata(0)
	$".".title="Browser "+actual_dir
	_fetchImagesThreaded(actual_dir,0)

signal item_created(item)
signal all_item_created(page,pages)
func _fetchImagesThreaded(dir_path,page:int)->void:
	_clearImgList()
	Global.create_task(fetchImagesByThread.bind(dir_path,page))

func fetchImagesByThread(dir_path,page):
	var dir = DirAccess.open(dir_path)
	var start=Global.settings.Listitems*page
	var end=Global.settings.Listitems*(1+page)
	var count=0
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				if Global.isSupportedImage(file_name):
					if (count>=start && count <end):
						var path=dir_path.path_join(file_name)
						item_created.emit.call_deferred(_create_item(path))
					count=count+1
			file_name = dir.get_next()
		dir.list_dir_end()
		all_item_created.emit.call_deferred(page,ceili(count/Global.settings.Listitems))
	else:
		print("An error occurred when trying to access the path.")

func _create_item(path)-> Object:
	return ListItem.create_item(path)

func updateList(item):
	item.selected.connect(_displayImage)
	%ImageList.list.add_child(item)

func switchPage(increment,relative):
	var page=%ImageList.bt_page.selected
	if(relative):
		page+=increment
	_fetchImagesThreaded(actual_dir,page)

func _on_close_requested() -> void:
	hide()
	call_deferred("free")

func _on_bt_delete_dir_pressed() -> void:
	if(actual_dir):
		var myPromise:Promise
		var _fcount=DirAccess.get_files_at(actual_dir).size()
		var _dcount=DirAccess.get_directories_at(actual_dir).size()
		var text = actual_dir+"\n"
		text += str(_dcount)+" directorys\n" if _dcount>0 else ""		
		text += str(_fcount)+" files\n" if _fcount>0 else ""
		var dialog = ConfirmationDialog.new() 
		dialog.title = "Delete directory?" 
		dialog.dialog_text = text
		myPromise=Promise.new([dialog.canceled,dialog.confirmed])
		add_child(dialog)	
		dialog.popup_centered() # center on screen
		dialog.show()
		var res = await myPromise.completed
		if(res[0][0]==dialog.confirmed.get_name()):
			var path=actual_dir
			actual_dir=actual_dir.get_base_dir()
			#DirAccess.remove_absolute(path)  only deletes empty dirs
			OS.move_to_trash(ProjectSettings.globalize_path(path))
			navigateTo(actual_dir,true)
		#myPromise.free()

func _on_bt_create_dir_pressed() -> void:
	if(actual_dir):
		var myPromise:Promise
		myPromise=Promise.new([$WndCreate.done,$WndCreate.cancled])
		$WndCreate.from=actual_dir
		$WndCreate.popup_centered() 
		$WndCreate.show()
		var res = await myPromise.completed
		if(res[0][0]==$WndCreate.done.get_name()):
			navigateTo(res[0][1])
		#myPromise.free()
