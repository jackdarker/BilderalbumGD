class_name Tag extends Button

var ID:int=-1
var groupID:int=-1	
var label:String:
	set(value):
		self.text=value
	get:
		return self.text

var bgcolor:Color:
	set(value):
		var _style:StyleBoxFlat=self.get_theme_stylebox("normal").duplicate()
		_style.bg_color=value
		self.add_theme_stylebox_override("normal",_style)
	get:
		var _style = self.get_theme_stylebox("normal") as StyleBoxFlat
		return _style.bg_color

var fgcolor:Color:
	set(value):
		self.add_theme_color_override("font_color",value)
	get:
		return self.get_theme_color("font_color")

static func create_tag(_id,_groupID,_text,_fgcolor,_bgcolor):
	var _inst= Tag.new()
	_inst.text=_text
	_inst.ID=_id
	_inst.groupID=_groupID
	var fg= Color.from_string(_fgcolor,Color.FIREBRICK)
	var bg= Color.from_string(_bgcolor,Color.DODGER_BLUE)
	_inst.fgcolor=fg
	_inst.bgcolor=bg
	return _inst
