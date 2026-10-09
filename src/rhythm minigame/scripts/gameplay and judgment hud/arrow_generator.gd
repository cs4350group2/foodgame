extends Node2D

@export var arrow_to_generate : PackedScene
@export var gold_arrow_to_generate : PackedScene
@export var hold_arrow_to_generate : PackedScene # for when i work on hold arrows

func make_arrow() -> Arrow:
	var instance = arrow_to_generate.instantiate()
	add_child(instance)
	return instance

func make_gold_arrow() -> Arrow:
	var instance = gold_arrow_to_generate.instantiate()
	add_child(instance)
	return instance
	
func make_hold_arrow() -> Arrow:
	var instance = hold_arrow_to_generate.instantiate()
	add_child(instance)
	return instance

func make_note_from_data(data: Dictionary) -> Arrow:
	print(data)
	var hitsound: String = data.get("hitsound")
	# var hold_time: float = float(data.get("holdtime", 0.0)) # for hold notes
	
	# if hold_time > 0:
	#	return make_hold_arrow()
	
	if (hitsound == ":clap"):
		print("Spawning gold arrow!")
		return make_gold_arrow()
	
	return make_arrow()
