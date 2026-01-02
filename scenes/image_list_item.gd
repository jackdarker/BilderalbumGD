class_name ListItem extends Control

signal selected(path:String)

static var SceneListItem
static func create_item(path)-> Object:
	if(!SceneListItem):
		SceneListItem = load("res://scenes/image_list_item.tscn")
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
	_Item.texture=texture
	_Item.data=path

	return _Item


var show_fulltext:bool=true:
	set(value):
		show_fulltext=value
		_refresh()
	get:
		return(show_fulltext)

var data:String:
	set(value):
		data=value
		_refresh()
	get:
		return(data)

var _text:String:
	set(value):
		$Control/Label.text=value
	get:
		return($Control/Label.text)

var texture:
	set(value):
		$Control/TextureRect.texture=value	
	get:
		return $Control/TextureRect.texture	

func _notification(what):
	match what:
		NOTIFICATION_PARENTED:
			#this is a hack to apply the setting from the ImageList to the Item
			# ImageList/VBoxContainer/ScrollContainer/BoxContainer	TODO this will break if ImageList.tscn is modified
			show_fulltext=get_parent().get_parent().get_parent().get_parent().show_fulltext
		NOTIFICATION_UNPARENTED:
			pass

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed && event.button_index==MOUSE_BUTTON_LEFT:
			pass

func _refresh():
	if show_fulltext:
		_text=data
	else:
		_text=data.get_file()
	_resize.call_deferred()

func _resize():
	#hack to avoid having a fixed custom-minimum-size
	#TODO if this causes the scrollbar to appear, it will not perfectly fit
	var _size=$Control/TextureRect.size+Vector2(4,4)
	_size.y+=$Control/Label.size.y
	custom_minimum_size=_size

#region dragndrop
func _get_drag_data(at_position: Vector2) -> Variant:
	var cpb = ColorPickerButton.new()	#todo small icon?
	cpb.size = Vector2(50, 50)
	set_drag_preview(cpb)
	return self.data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if(data is String):
		return true
	return false
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	self.get_parent().get_parent()._drop_data(at_position,data)
	#if(data is String):
		#$Label.text = data
#endregion


func _on_focus_entered() -> void:
	$Focus.visible=true #.add_theme_color_override("normal",Color.ANTIQUE_WHITE)
	selected.emit(self.data)
	pass # Replace with function body.


func _on_focus_exited() -> void:
	$Focus.visible=false #$Panel.remove_theme_color_override("normal")
	pass # Replace with function body.
