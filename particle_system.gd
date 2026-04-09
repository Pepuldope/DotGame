extends CanvasLayer

const PARTICLE_SCENE = preload("res://particle.tscn")
const PARTICLE_COUNT = 6

func _ready() -> void:
	for i in PARTICLE_COUNT:
		var p = PARTICLE_SCENE.instantiate()
		add_child(p)
