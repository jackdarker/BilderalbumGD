extends Control

@onready var SceneListItem = load("res://scenes/ImageListItem.tscn")
@onready var SceneBrowser = preload("res://scenes/wnd_browser.tscn")

func _ready() -> void:
	pass
	
var _actual_image=null	
func displayImage(path)->void:	
	%TextureRect.texture=Global.loadImgToTexture(path,%TextureRect.size.x,%TextureRect.size.y)
	_actual_image=path	



func _on_bt_new_browser_pressed() -> void:
	var s=SceneBrowser.instantiate()
	s.selected.connect(displayImage)
	self.get_tree().root.add_child(s)


func _on_bt_settings_pressed() -> void:
	%WndSettings.process_mode=Node.PROCESS_MODE_ALWAYS
	%WndSettings.show()

#as resized is fred constantly it would waste a lot of processing if we continously resize image
func _on_texture_rect_resized() -> void:
	$HBoxContainer/TextureRect/ResizeTimer.start()

func _on_resize_timer_timeout() -> void:
	if _actual_image:
		displayImage(_actual_image)
