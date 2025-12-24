extends Window

var from:String
var to:String
var filename:String

signal done

func _on_visibility_changed() -> void:
	if self.visible:
		$Panel/MarginContainer/GridContainer/from.text=from.get_base_dir()
		$Panel/MarginContainer/GridContainer/to.text=to.get_base_dir()
		filename=from.get_file()
		$Panel/MarginContainer/GridContainer/Edit.text=filename
		validator()

func _on_bt_cancle_pressed() -> void:
	self.hide()

func _on_bt_ok_pressed() -> void:
	if(DirAccess.copy_absolute(from,to.path_join(filename))==Error.OK):
		DirAccess.remove_absolute(from)
	self.hide()
	done.emit()
	Global.file_moved.emit(from)


func _on_bt_delete_pressed() -> void:
	DirAccess.remove_absolute(from)
	self.hide()
	done.emit()

func _on_edit_text_changed(new_text: String) -> void:
	filename=$Panel/MarginContainer/GridContainer/Edit.text
	validator()

func validator():
	var disabled=false
	if(FileAccess.file_exists(to.path_join(filename))):
		disabled=true
	%bt_ok.disabled=disabled
	
