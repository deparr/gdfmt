extends Node2D

@export var a: float = 1.0
const bullet = preload("res://somepathtoscnene")

func _ready() -> void:
	if a < 0.0:
		print(TAU)
