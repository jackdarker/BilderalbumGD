extends Node

signal file_moved(path:String)

var db:TagDatabase =null
var current_scene = null
var settings:Settings =Settings.new()

var SceneBrowser = preload("res://scenes/wnd_browser.tscn")

func goto_scene(path):
	# This function will usually be called from a signal callback,
	# or some other function in the current scene.
	# Deleting the current scene at this point is
	# a bad idea, because it may still be executing code.
	# This will result in a crash or unexpected behavior.

	# The solution is to defer the load to a later time, when
	# we can be sure that no code from the current scene is running:
	_deferred_goto_scene.call_deferred(path)

func _deferred_goto_scene(path):
	# It is now safe to remove the current scene.
	current_scene.free()
	# Load the new scene.
	var s = ResourceLoader.load(path)
	# Instance the new scene.
	current_scene = s.instantiate()
	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)
	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var root = get_tree().root
	get_tree().set_auto_accept_quit(false)	# see https://docs.godotengine.org/en/stable/tutorials/inputs/handling_quit_requests.html
	# Using a negative index counts from the end, so this gets the last child node of `root`.
	current_scene = root.get_child(-1)
	loadFromFile()

func quitGodot():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
	
func getGlobalViewer():
	return get_tree().root.get_node("WndViewer")

func getGlobalTagger():
	return get_tree().root.get_node("Tagger")

func createBrowser():
	var s=SceneBrowser.instantiate()
	s.selected.connect(getGlobalViewer().displayImage)
	self.get_tree().root.add_child.call_deferred(s)
	return s

#region image tools
func isSupportedImage(file_name)->bool:
	match file_name.get_extension().to_lower() :
		"png","jpg","jpeg","tga","webp":
			return(true)
		"svg":
			return(false)	
		_:
			return(false)

func loadImgToTexture(path,max_width,max_height)->ImageTexture:
	var m_ImageScalingMode=-1
	var image = Image.load_from_file(path)
	var ImageWidth=image.get_width()
	var ImageHeight=image.get_height()
	var Ratio_W = max_width/ImageWidth
	var Ratio_H = max_height/ImageHeight
	var scale = min(Ratio_W, Ratio_H);
	if ((m_ImageScalingMode == -1) || (m_ImageScalingMode == -2 && scale < 1)):
		image.resize(snapped(ImageWidth * scale,2),snapped(ImageHeight * scale,2))
	elif ((1 <= m_ImageScalingMode) && (m_ImageScalingMode <= 1000)):
		image.resize(snapped((ImageWidth * m_ImageScalingMode) / 100.0,2),snapped((ImageHeight * m_ImageScalingMode) / 100.0,2))
	else:
		pass
	var texture = ImageTexture.create_from_image(image)
	return(texture)
#endregion

#region tasks
# Task is a wrapper for a thread; use create_task to spawn and wait for finished-signal
class Task extends Object:
	signal finished(taskid)
	var taskid
	
	func _init(taskid):
		self.taskid=taskid
	
	func is_completed()->bool:
		return WorkerThreadPool.is_task_completed(taskid)
		
	func cleanup():
		if (WorkerThreadPool.is_task_completed(taskid)):
			WorkerThreadPool.wait_for_task_completion(taskid)
			finished.emit(taskid)

var tasks=[]
func create_task(action:Callable,high_priority=false):
	var taskid= WorkerThreadPool.add_task(action,high_priority)
	var task = Task.new(taskid)
	tasks.append(task)
	return task

func _process(_delta: float) -> void:
	var completed = tasks.filter(
		func filter(task:Task):
			return task.is_completed()
	)
	for task:Task in completed:
		task.cleanup()
		tasks.erase(task)
	
#endregion	

#region settings
var SETTINGS_FILE="user://Settings.save"	
#located in C:\Users\xxx\AppData\Roaming\Godot\app_userdata\BilderalbumGD

func saveToFile():
	var _path=SETTINGS_FILE
	var saveData = saveData()
	var save_game=FileAccess.open(_path, FileAccess.WRITE)
	save_game.store_string(JSON.stringify(saveData))
	save_game.close()
	
func loadFromFile():
	var _path=SETTINGS_FILE
	if not FileAccess.file_exists(_path):
		#Log.error("Save file is not found in "+str(_path))
		#assert(false, "Save file is not found in "+str(_path))
		return # Error! We don't have a save to load.
	
	var save_game=FileAccess.open(_path, FileAccess.READ)
	#var saveData = parse_json(save_game.get_as_text())
	var json=JSON.new()
	var jsonResult = json.parse(save_game.get_as_text())
	if(jsonResult != OK):
		assert(false, "Trying to load a bad save file "+str(_path))
		return
	
	loadData(json.data)
	save_game.close()

func loadData(data):
	var myPromise
	Global.settings.loadData(data.settings)
	if(data.browsers.size()>0):
		var dialog = ConfirmationDialog.new() 
		dialog.title = "Restore windows?" 
		dialog.dialog_text = dialog.title
		#dialog.canceled.connect(dialog_canceled)
		#dialog.confirmed.connect(dialog_confirmed)
		myPromise=Promise.new([dialog.canceled,dialog.confirmed])
		add_child(dialog)	
		dialog.popup_centered() # center on screen
		dialog.show()
		var res = await myPromise.completed
		if(res[0][0]==dialog.confirmed.get_name()):
			for item in data.browsers:
				var s=createBrowser()
				s.loadData(item)
		#myPromise.free()
		
func saveData()->Variant:
	var data ={
		"settings":Global.settings.saveData(),
		"browsers": [],
	}
	var save_nodes = get_tree().get_nodes_in_group("Items")
	for node in save_nodes:
		data.browsers.append(node.saveData())
		
	return(data)

#endregion
