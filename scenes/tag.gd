class_name Tag extends Button

var ID:int=-1	

static func create_tag(_id,_text,_fgcolor,_bgcolor):
	var _inst= Tag.new()
	_inst.text=_text
	_inst.ID=_id
	var fg= Color.from_string(_fgcolor,Color.FIREBRICK)
	var bg= Color.from_string(_bgcolor,Color.DODGER_BLUE)
	_inst.add_theme_color_override("font_color",fg)
	var _style:StyleBoxFlat=_inst.get_theme_stylebox("normal").duplicate()
	_style.bg_color=bg
	_inst.add_theme_stylebox_override("normal",_style)
	return _inst
