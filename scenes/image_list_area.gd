extends Container

var can_drop:Callable
var drop:Callable

#note this is bound to scrollbox not the contained boxcontainer because the boxc. doesnt receive drop-requests?

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return (can_drop.call(at_position, data))
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	drop.call(at_position, data)
