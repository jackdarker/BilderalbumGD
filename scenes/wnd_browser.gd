extends Window
## Note: disable "embed subwindows" in project settings or min/maximize button wont show

signal selected(path:String)

@onready var SceneListItem = load("res://scenes/ImageListItem.tscn")

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

func navigateTo(path:String):
	#expand the directory-tree to match path		#todo
	pass

	
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
	navigateTo(data["actual_dir"])

func _on_button_pressed() -> void:
	%FileDialog.popup_centered_ratio()

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

func buildTree() -> void:
	_clearDirTree(null)
	var tree=%Tree
	var root:TreeItem = tree.create_item()
	tree.hide_root = true
	root.set_metadata(0,"")
	var d=DirAccess.get_drive_count()
	for i in d:
		var drive:TreeItem=tree.create_item(root)
		var letter=DirAccess.get_drive_name(i)
		drive.set_text(0,letter)
		drive.set_metadata(0,letter)
		drive.collapsed=true

	_appendDir(root)
	
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
			_clearDirTree(item)
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					var node:TreeItem=tree.create_item(item)
					node.set_text(0,file_name)
					node.set_metadata(0,dir.get_current_dir().path_join(file_name))
					tree.create_item(node)	#add a placeholder for digging deeper
					node.collapsed=true
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("An error occurred when trying to access the path.")

func _on_tree_item_collapsed(item: TreeItem) -> void:
	if item.collapsed:
		return
	call_deferred("_appendDir",item)	#if called directly tree.create_item(item) returns null?!

var actual_dir=null
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
	var _Item=SceneListItem.instantiate()
	var image = Image.load_from_file(path)
	var ThumbnailSize = Global.settings.Itemsize
	var Width =0
	var Height = 0
	var Ratio = image.get_width() / float(image.get_height())
	if Ratio>= 1.0:
		Width = ThumbnailSize;
		Height = (Width * image.get_height()) / float(image.get_width());
	else:
		Height = ThumbnailSize;
		Width = (Height * image.get_width()) / float(image.get_height());

	image.resize(Width,Height)
	var texture = ImageTexture.create_from_image(image)
	_Item.get_node("TextureRect").texture=texture
	_Item.get_node("Label").text=path
	return _Item

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

func _on_button_4_pressed() -> void:
	SaveLoadMgr.save("c://temp//savegame.save")


func _on_button_5_pressed() -> void:
	SaveLoadMgr.load("c://temp//savegame.save")
