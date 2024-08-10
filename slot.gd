extends ColorRect

@onready var filter_path = $Filter
var GUI = "res://GUI.gd"
var slot_ID := -1
signal slot_clicked(slot)
var state = DataHandler.slot_states.None
var nb_divs = DataHandler.nb_divs


# Called when the node enters the scene tree for the first time.
func _ready():
	var x_size = get_viewport_rect().size[0]
	var y_size = get_viewport_rect().size[1]
	var nb_slots = 7 * nb_divs + 1
	var slot_size = int(min(x_size, y_size) / nb_slots)
	var vec_size = .8 * Vector2(slot_size, slot_size) 
	custom_minimum_size = vec_size
	pass # Replace with function body.

func set_background(c):
	color = c

	
func set_filter(color = DataHandler.slot_states.None):
	state = color
	match color:
		DataHandler.slot_states.None:
			filter_path.color = Color(0, 0, 0, 0)
		DataHandler.slot_states.Free:
			filter_path.color = Color(0, 1, 0, 0.5)
		DataHandler.slot_states.Selected:
			filter_path.color = Color(0.5, 0.5, 1, 0.5)
		DataHandler.slot_states.Capture:
			filter_path.color = Color(1, 0, 0, 0.5)





func _on_filter_gui_input(event):
	if event.is_action_pressed("mouse_left"):
		emit_signal("slot_clicked", self)
