extends Control

@onready var list=$VBoxContainer/ScrollContainer/BoxContainer
@onready var bt_prev=$VBoxContainer/HBoxContainer/bt_prev
@onready var bt_next=$VBoxContainer/HBoxContainer/bt_next
@onready var bt_page=$VBoxContainer/HBoxContainer/OptionButton

func updatePageCtrl(page,pages):
	bt_page.clear()
	for i in pages:
		bt_page.add_item(str(i))
	
	bt_page.selected=page
	bt_prev.disabled= (page<=0)
	bt_next.disabled= (page>=(pages-1))
		
