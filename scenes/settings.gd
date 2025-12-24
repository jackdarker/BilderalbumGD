extends Node
class_name Settings

var Listitems :int= 6
var Itemsize: int = 128

func _init():
	pass

func saveData()->Variant:
	return {"Listitems": Listitems,
		"Itemsize":Itemsize}

func loadData(data:Variant):
	Listitems=data["Listitems"]
	Itemsize=data["Itemsize"]
