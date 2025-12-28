class_name Promise  extends Object

#use this to wait for any/all signals
#it will then fire the completed signal with information

signal completed(args) # [ [signal0_name, signal1.arg0,...] ,[ signal1_name, signal1.arg0,... ] ]

enum MODE {ANY, ALL}
var mode: int = MODE.ANY

var _signals: Dictionary = {} # signal: {has_emitted: bool, data: any}
var _completed: bool = false

func _init(signals: Array, _mode: int=MODE.ANY) -> void:
	self.mode=_mode
	for s:Signal in signals:
		_signals[s] = {"has_emitted":false}
		s.connect(_on_signal.bind(s))


func _on_signal(...args:Array) -> void:
	var _signal= args.pop_back()
	_signals[_signal].has_emitted = true
	var _args = [_signal.get_name()]
	_args.append_array(args)
	_signals[_signal].data = _args
	_check_completion()

func _check_completion():
	if _completed:
		return

	if mode == MODE.ANY:
		_check_any_completion()
	elif mode == MODE.ALL:
		_check_all_completion()


func _check_any_completion() -> void:
	for _signal in _signals:
		if _signals[_signal].has_emitted:
			completed.emit([_signals[_signal].data])
			return


func _check_all_completion() -> void:
	var return_data: Array = []
	
	for _signal in _signals:
		if not _signals[_signal].has_emitted:
			return
		
		return_data.append(_signals[_signal].data)
	completed.emit(return_data)
