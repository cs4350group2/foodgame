extends Node2D

@export var note_to_generate : PackedScene
@export var gold_note_to_generate : PackedScene
@export var hold_note_to_generate : PackedScene # for when i work on hold arrows

func make_note() -> Note:
	var instance = note_to_generate.instantiate()
	add_child(instance)
	return instance

func make_gold_note() -> Note:
	var instance = gold_note_to_generate.instantiate()
	add_child(instance)
	return instance
	
func make_hold_note() -> Note:
	var instance = hold_note_to_generate.instantiate()
	add_child(instance)
	return instance

func make_note_from_data(data: Dictionary) -> Note:
	var hitsound: String = data.get("hitsound")
	# var hold_time: float = float(data.get("holdtime", 0.0)) # for hold notes
	
	# if hold_time > 0:
	#	return make_hold_arrow()
	
	if (hitsound == ":clap"):
		return make_gold_note()
	
	return make_note()
