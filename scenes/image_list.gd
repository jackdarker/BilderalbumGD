extends Control

@onready var list=$VBoxContainer/ScrollContainer/BoxContainer
@onready var bt_prev=$VBoxContainer/HBoxContainer/bt_prev
@onready var bt_next=$VBoxContainer/HBoxContainer/bt_next
@onready var bt_page=$VBoxContainer/HBoxContainer/OptionButton

var page:int:
	get():
		return bt_page.selected

var scroll_vertical:int:
	get():
		return $VBoxContainer/ScrollContainer.scroll_vertical
	set(value):
		$VBoxContainer/ScrollContainer.set_deferred("scroll_vertical", value)

func updatePageCtrl(page,pages):
	bt_page.clear()
	for i in pages:
		bt_page.add_item(str(i))
	
	bt_page.selected=page
	bt_prev.disabled= (page<=0)
	bt_next.disabled= (page>=(pages-1))


var show_fulltext:bool=false:
	set(value):
		show_fulltext=value
		%bt_fulltext.button_pressed=show_fulltext
		for item in list.get_children():
			item.show_fulltext=value
	get():
		return show_fulltext

func _on_bt_fulltext_toggled(toggled_on: bool) -> void:
	var _set=%bt_fulltext.button_pressed
	show_fulltext=_set
	
