extends Node

## How to use
# - put this in Auto-Load
# - assign 'Persist' to Nodes that need to be saved
# - also add functions saveData / loadData to them
# - call save-function to save and load to reload
# - you might need to override currentSavefileVersion + upgrade


## options
var currentSavefileVersion:int = 1
var maxBackupQuicksaves:int = 3

## vars
var loadedSavefileVersion:int = -1
var glbUIDCnt:int = 0

func _ready():
	pass

func create_UID()->int:
	glbUIDCnt+=1
	return(glbUIDCnt)

func saveData()->Dictionary:
	var data = {
		"version": currentSavefileVersion,
		"glbUIDCnt": glbUIDCnt,
	}
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("saveData"):
			print("persistent node '%s' is missing a saveData() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("saveData")
		data[node_data.UID]=node_data
	
	return data
	
func loadData(data: Dictionary):
	if(!data.has("version")):
		#Log.printerr("Error: Save file doesn't have a version in it. It might not be a savefile")
		return
	if(data["version"] > currentSavefileVersion):
		#Log.printerr("Error: This savefile is not supported, sorry. Current supported version: "+str(currentSavefileVersion)+". Savefile version: "+data["savefile_version"])
		return
		
	loadedSavefileVersion = data["version"]
	glbUIDCnt = data["glbUIDCnt"]
	
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		i.queue_free()
	#save_nodes[0].free()
	
	for key in data.keys():
		if key=="version" || key=="glbUIDCnt":
			continue
		var node_data = data[key]
		var new_object = load(node_data["filename"]).instantiate()
		get_node(node_data["parent"]).add_child(new_object)
		new_object.call("loadData",node_data)

	#todo post_load()
	return
	
func canSave():
	return true  #todo GM.main.canSave()
	
func save(_path):
	if(!canSave()):
		#Log.printerr("Can't save because one of the scenes doesn't support saving")
		return
	
	var _saveData = saveData()
	var save_game = FileAccess.open(_path, FileAccess.WRITE)
	save_game.store_line(JSON.stringify(_saveData, "\t", true))
	save_game.close()

func load(_path):
	if not FileAccess.file_exists(_path):
		#Log.error("Save file is not found in "+str(_path))
		assert(false, "Save file is not found in "+str(_path))
		return # Error! We don't have a save to load.
	var save_game = FileAccess.open(_path,FileAccess.READ)
	var data_received
	var json= JSON.new()
	var error = json.parse(save_game.get_as_text())
	if error == OK:
		data_received = json.data
	else:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		assert(false, "Trying to load a bad save file "+str(_path))
		return
	save_game.close()
	loadData(data_received)
	
