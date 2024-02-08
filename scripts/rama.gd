tool
class_name Rama
extends GameObject

export(Texture) var image_texture
export(bool) var flip_image_horizontal = false
export(bool) var flip_image_vertical = false
onready var image = $image

func _ready():
	update_image()

func update_image():
	image.texture = image_texture
	image.scale.x = 192 / image_texture.get_size().x
	image.scale.y = 192 / image_texture.get_size().y
	image.flip_h = flip_image_horizontal
	image.flip_v = flip_image_vertical
