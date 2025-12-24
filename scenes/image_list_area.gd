extends ScrollContainer

var can_drop:Callable
var drop:Callable

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	#if(data is String):
	return (can_drop.call(at_position, data))
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	#if(data is String):
	#	$Label.text = data
	drop.call(at_position, data)
