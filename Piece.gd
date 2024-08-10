extends Node2D

signal piece_selected(piece)
@onready var icon_path = $Icon
@onready var circle_path = $Circle
@onready var click_path = $Click
var slot_ID := -1
var type : int
var nb_divs = DataHandler.nb_divs


# Called when the node enters the scene tree for the first time.
func _ready():
	var x_size = get_viewport_rect().size[0]
	var y_size = get_viewport_rect().size[1]
	var nb_slots = 7 * nb_divs + 1
	var slot_size = int(min(x_size, y_size) / nb_slots)
	var vec_size = Vector2(slot_size, slot_size)
	#icon_path.size = vec_size * max(nb_divs / 4, 3)
	if nb_divs >= 4:
		circle_path.size = vec_size * (nb_divs - 1)
		icon_path.size = circle_path.size / 2
	else:
		circle_path.modulate = Color(1, 1, 1, 0)
		icon_path.size = vec_size
	if nb_divs >= 8:
		click_path.size = vec_size
	else:
		click_path.color = Color(1, 1, 1, 0)
	icon_path.anchors_preset = 8
	icon_path.position += Vector2(0, -10)
	circle_path.anchors_preset = 8
	click_path.anchors_preset = 8
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_icon(piece_name):
	icon_path.texture = load(DataHandler.assets[piece_name])




func _on_click_gui_input(event):
	if event.is_action_pressed("mouse_left"):
		emit_signal("piece_selected", self)
