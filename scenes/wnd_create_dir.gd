extends Window

signal done(path:String)
signal cancled

var from:String
var filename:String

@onready var _from=$Panel/MarginContainer/GridContainer/from
@onready var _edit=$Panel/MarginContainer/GridContainer/Edit

func _on_visibility_changed() -> void:
	if self.visible:
		_from.text=from
		filename="New folder"
		_edit.text=filename
		validator()

func _on_bt_cancle_pressed() -> void:
	self.hide()
	cancled.emit()

func _on_bt_ok_pressed() -> void:
	var _new=from.path_join(filename)
	DirAccess.make_dir_recursive_absolute(_new)
	self.hide()
	done.emit(_new)
	Global.file_moved.emit(from)


func _on_edit_text_changed(new_text: String) -> void:
	filename=_edit.text
	validator()

func validator():
	var disabled=false
	if(DirAccess.dir_exists_absolute(from.path_join(filename))):
		disabled=true
	%bt_ok.disabled=disabled
	
