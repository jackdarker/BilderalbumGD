extends Window
## Note: disable "embed subwindows" in project settings or min/maximize button wont show

signal selected(path:String)

@onready var SceneListItem = load("res://scenes/ImageListItem.tscn")

var UID:int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buildTree()

func saveData()->Dictionary:
	var data ={
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"UID":UID,
		"x":position.x,
		"y":position.y,
	}
	return data

func loadData(data: Dictionary):
	position.x = data["x"]
	position.y = data["y"]
	UID=data["UID"]

func _on_button_pressed() -> void:
	%FileDialog.popup_centered_ratio()

func _on_file_dialog_file_selected(path: String) -> void:
	# Load an image of any format supported by Godot from the filesystem.
	var image = Image.load_from_file(path)
	image.resize(100,100)
	var texture = ImageTexture.create_from_image(image)
	#texture.set_size_override(Vector2(100,100))
	%TextureRect.texture=texture


var _actual_image=null	
func _displayImage(path)->void:	
	_actual_image=path
	selected.emit(path)

func _loadImgToList(path)->void:
	var _Item=SceneListItem.instantiate()
	var image = Image.load_from_file(path)
	var ThumbnailSize = 128
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
	_Item.selected.connect(_displayImage)
	%ImageList.get_child(0).add_child(_Item)

func _clearImgList()->void:
	var node=%ImageList.get_child(0)
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
	var root = tree.create_item()
	tree.hide_root = true
	#root.set_text(0,"d:/temp")
	root.set_metadata(0,"")
	var d=DirAccess.get_drive_count()
	for i in d:
		var drive=tree.create_item(root)
		var letter=DirAccess.get_drive_name(i)
		drive.set_text(0,letter)
		drive.set_metadata(0,letter)

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
					var node=tree.create_item(item)
					node.set_text(0,file_name)
					node.set_metadata(0,dir.get_current_dir().path_join(file_name))
					tree.create_item(node)
					node.collapsed=true
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("An error occurred when trying to access the path.")

func _on_tree_item_collapsed(item: TreeItem) -> void:
	if item.collapsed:
		return
	call_deferred("_appendDir",item)	#if called directly tree.create_item(item) returns null?!

func _on_tree_item_selected() -> void:
	var item=%Tree.get_selected()
	_fetchImagesThreaded(item.get_metadata(0))

signal item_created(item)
func _fetchImagesThreaded(dir_path)->void:
	_clearImgList()
	item_created.connect(updateList)
	Global.create_task(fetchImagesByThread.bind(dir_path))

func fetchImagesByThread(dir_path):
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				if Global.isSupportedImage(file_name):
					var path=dir_path.path_join(file_name)
					var _Item=SceneListItem.instantiate()
					var image = Image.load_from_file(path)
					var ThumbnailSize = 128
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
					item_created.emit.call_deferred(_Item)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")

func updateList(item):
	item.selected.connect(_displayImage)
	%ImageList.get_child(0).add_child(item)


func _on_close_requested() -> void:
	hide()
	call_deferred("free")

func _on_button_4_pressed() -> void:
	SaveLoadMgr.save("c://temp//savegame.save")


func _on_button_5_pressed() -> void:
	SaveLoadMgr.load("c://temp//savegame.save")

func _on_texture_rect_resized() -> void:
	if _actual_image:
		_displayImage(_actual_image)
