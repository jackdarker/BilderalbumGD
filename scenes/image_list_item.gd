extends VBoxContainer

signal selected(path:String)


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed && event.button_index==MOUSE_BUTTON_LEFT:
			selected.emit($Label.get_text())

#region dragndrop
func _get_drag_data(at_position: Vector2) -> Variant:
	var cpb = ColorPickerButton.new()	#todo small icon?
	cpb.size = Vector2(50, 50)
	set_drag_preview(cpb)
	return $Label.text

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if(false && data is String):
		return true
	return false
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if(data is String):
		$Label.text = data
#endregion
