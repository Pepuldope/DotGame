extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_node_2d_score_gained(new_score: int):
	text = "Score: %d" % new_score


func _on_draw() -> void:
	pass # Replace with function body.
