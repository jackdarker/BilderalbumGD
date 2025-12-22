extends Window

func _on_visibility_changed() -> void:
	if self.visible:
		$Panel/MarginContainer/GridContainer/i_listitems.value=Global.settings.Listitems
		$Panel/MarginContainer/GridContainer/i_previewsize.value=Global.settings.Itemsize

func _on_bt_cancle_pressed() -> void:
	self.hide()

func _on_bt_ok_pressed() -> void:
	#todo validate
	Global.settings.Listitems=$Panel/MarginContainer/GridContainer/i_listitems.value
	Global.settings.Itemsize=$Panel/MarginContainer/GridContainer/i_previewsize.value
	self.hide()
