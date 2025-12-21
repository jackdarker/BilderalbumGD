extends Control

@onready var SceneListItem = load("res://scenes/ImageListItem.tscn")
@onready var SceneBrowser = preload("res://scenes/wnd_browser.tscn")

func _ready() -> void:
	_clearImgList()

func displayImage(path)->void:	
	%TextureRect.texture=Global.loadImgToTexture(path,%TextureRect.size.x,%TextureRect.size.y)

func loadImgToList(path)->void:
	var _Items = %ImageList.get_child(0).get_children()
	var alreadyPresent=false
	for _x in _Items:
		if _x.get_node("Label").text==path:
			alreadyPresent=true
			break
	if !alreadyPresent:		
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
		_Item.selected.connect(displayImage)
		%ImageList.get_child(0).add_child(_Item)
	displayImage(path)

func _clearImgList()->void:
	var node=%ImageList.get_child(0)
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()


func _on_bt_new_browser_pressed() -> void:
	var s=SceneBrowser.instantiate()
	s.selected.connect(displayImage)
	self.get_tree().root.add_child(s)
