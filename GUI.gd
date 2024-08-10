extends Control

@onready var slot_scene = preload("res://slot.tscn")
@onready var board_grid = $BoardGrid
@onready var background = $Background
@onready var youwin_text = $YouWin
@onready var restart_button = $Restart
@onready var piece_scene = preload("res://piece.tscn")

var grid_array := []
var piece_array := []
var fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"
var icon_offset := Vector2(36/2, 36/2)
var piece_selected = null
var legal_moves = []
var white_move = true
var nb_divs = DataHandler.nb_divs
var nb_slots
var radius
var minus_one
var plus_one
var slot_size
var vec_size
var game_over = false
var light_gray = "353535"

# Called when the node enters the scene tree for the first time.
func _ready():
	background.color = Color(light_gray)
	
	nb_slots = 7 * nb_divs + 1
	radius = nb_divs / 2
	minus_one = nb_slots - 1
	plus_one = nb_slots + 1
	var x_size = get_viewport_rect().size[0]
	var y_size = get_viewport_rect().size[1]
	slot_size = int(min(x_size, y_size) / nb_slots)
	vec_size = .8 * Vector2(slot_size, slot_size)
		
	if not len(board_grid.get_children()):
		create_board()
		color_board()

	piece_array.resize(nb_slots**2)
	piece_array.fill(0)
	
	icon_offset = vec_size / 2
	board_grid.columns = nb_slots
	board_grid.size = nb_slots * vec_size
	board_grid.pivot_offset = board_grid.size / 2
	board_grid.anchors_preset = Control.PRESET_CENTER
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(board_grid.size + vec_size * nb_divs / 2)
	DisplayServer.window_set_position((Vector2(x_size, y_size) - board_grid.size) / 2)
	DisplayServer.window_set_title("Continuous Chess")
	call_deferred("parse_fen", fen)

func create_board():
	for i in range(nb_slots**2):
			create_slot()
func color_board():
	#var move_lines = nb_divs / 2 
	#var move_squares = nb_divs / 2 - 1
	var colorbit = 0
	board_grid.columns = nb_slots
	for i in range(nb_slots):
		for j in range(nb_slots):
			if ((not i % (nb_divs)) and (not j % (nb_divs))) or ((not (i-nb_divs/2) % (nb_divs)) and (not (j-nb_divs/2) % (nb_divs))):
				grid_array[coords_to_loc([i, j])].set_background(Color(light_gray))
			#if ((i+move_squares)/nb_divs+(j+move_squares)/nb_divs) % 2:
				#grid_array[coords_to_loc([i, j])].set_background(Color.WHITE)
			#if (i+move_lines) % nb_divs == 0 or (j+move_lines) % nb_divs == 0:
				#grid_array[coords_to_loc([i, j])].set_background(Color.DARK_GRAY)

func parse_fen(fen : String) -> void:
	var boardstate = fen.split(" ")
	var board_index := 0
	for i in boardstate[0]:
		if i == "/":
			board_index += nb_slots * (nb_divs)
			continue
		if i.is_valid_int():
			pass
		else:
			if board_index < nb_slots ** 2:
				add_piece(DataHandler.fen_dict[i], board_index)
			if not (board_index + 1) % nb_slots:
				board_index -= nb_slots - 1
			else:
				board_index += nb_divs


func add_piece(piece_type, location):
	var new_piece = piece_scene.instantiate()
	board_grid.add_child(new_piece)
	new_piece.type = piece_type
	new_piece.load_icon(piece_type)
	new_piece.global_position = grid_array[location].global_position + icon_offset
	piece_array[location] = new_piece
	new_piece.slot_ID = location
	new_piece.piece_selected.connect(_on_piece_selected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	board_grid.add_child(new_slot)
	grid_array.push_back(new_slot)
	new_slot.slot_clicked.connect(_on_slot_clicked)
	
func _on_slot_clicked(slot):
	if not piece_selected or game_over:
		return
	elif slot.slot_ID == piece_selected.slot_ID:
		piece_selected = null
		legal_moves = []
		clear_board_filters()
	if slot.slot_ID in legal_moves:
		move_piece(piece_selected, slot.slot_ID)
		piece_selected = null
		legal_moves = []
		white_move = not white_move
		var tween = get_tree().create_tween().set_parallel()
		tween.tween_property(board_grid, "rotation_degrees", 180.0, 0.5).as_relative().set_delay(0.2)
		icon_offset = vec_size * (0.5 if white_move else -0.5)
		for piece in piece_array:
			if piece:
				#pass
				tween.tween_property(piece, "rotation_degrees", -180.0, 0.5).as_relative().set_delay(0)
		clear_board_filters()
	
func move_piece(piece, location):
	var slots = get_radius_around(location, radius)
	for to_capture in slots:
		if piece_array[to_capture] and piece_array[to_capture] != piece:
			if piece_array[to_capture].type in [1, 7]:
				game_over = true
				restart_button.visible = true
				youwin_text.text = "WHITE WINS" if white_move else "BLACK WINS"
				youwin_text.show
			piece_array[to_capture].queue_free()
			piece_array[to_capture] = 0
	
	var tween = get_tree().create_tween()
	tween.tween_property(piece, "global_position", grid_array[location].global_position + icon_offset, 0.1)
	piece_array[piece.slot_ID] = 0  # delete piece from original location

	var y_pos = location / nb_slots
	if piece.type == 3 and y_pos == 0:
		add_piece(4, location)
	elif piece.type == 9 and y_pos == minus_one:
		add_piece(10, location)
	else:
		piece_array[location] = piece  # move it to the new location
		piece.slot_ID = location	
	
func get_radius_around(location, radius):
	var x_loc = location % nb_slots
	var y_loc = location / nb_slots
	
	var left = max(x_loc - radius, 0)
	var right = min(x_loc + radius, minus_one)
	var top = max(y_loc - radius, 0)
	var bot = min(y_loc + radius, minus_one)
	
	var good = []
	
	for x_search in range(left, right+1):
		for y_search in range(top, bot+1):
			var distance_squared = (x_search - x_loc)**2 + (y_search - y_loc)**2
			if distance_squared < radius**2:
				var found = coords_to_loc([x_search, y_search])
				good.append(found)
				
	return good
	
func _on_piece_selected(piece):
	if game_over:
		return
	var can_play = false
	if (white_move and piece.type <= 5) or ((not white_move) and piece.type >= 6):
		can_play = true
	if can_play:
		clear_board_filters()
		legal_moves = []
		if piece_selected != piece:
			piece_selected = piece
			legal_moves = get_legal_moves(piece)
		else:
			piece_selected = null
	else:
		_on_slot_clicked(grid_array[piece.slot_ID])
		

func get_legal_moves(piece):
	var piece_type = piece.type
	var location = piece.slot_ID
	if piece_type in [0, 6]:
		legal_moves += get_4_directional(piece, piece_type, location, "d")
	if piece_type in [1, 7]:
		legal_moves += get_4_directional(piece, piece_type, location, "d", nb_divs)
		legal_moves += get_4_directional(piece, piece_type, location, "s", nb_divs)
	if piece_type in [2, 8]:
		legal_moves += get_knight_moves(piece, piece_type, location)
	if piece_type == 3:
		legal_moves += get_pawn_moves(piece, piece_type, location, "u", nb_divs)
		legal_moves += get_pawn_moves(piece, piece_type, location, "ud", nb_divs)
	if piece_type == 9:
		legal_moves += get_pawn_moves(piece, piece_type, location, "d", nb_divs)
		legal_moves += get_pawn_moves(piece, piece_type, location, "dd", nb_divs)
	if piece_type in [4, 10]:
		legal_moves += get_4_directional(piece, piece_type, location, "d")
		legal_moves += get_4_directional(piece, piece_type, location, "s")
	if piece_type in [5, 11]:
		legal_moves += get_4_directional(piece, piece_type, location, "s")
	
	set_board_free(legal_moves)
	set_board_selected([location])
	return legal_moves
	
	
func check_collisions(checking, radius_c, piece, piece_type):
	var can_capture = []
	var circle = get_radius_around(checking, radius_c)
	var keep_in_mind = range(nb_slots**2)
	var foundCollision = 0
	for position in circle: # Check for intersections
		if piece_array[position] and piece_array[position] != piece:
			var target_type = piece_array[position].type
			if (piece_type <= 5 and target_type >= 6) or (piece_type >= 6 and target_type <= 5):
				can_capture.append(position)
				keep_in_mind = get_radius_around(position, radius_c)
				foundCollision = 1
			else:
				foundCollision = 2

	return [foundCollision, can_capture, keep_in_mind]

func get_4_directional(piece, piece_type, location, angle, distance=nb_slots-1):
	var x_loc = location % nb_slots
	var y_loc = location / nb_slots
	var right_dist = minus_one - x_loc
	var left_dist = x_loc
	var top_dist = y_loc
	var bot_dist = minus_one - y_loc
	var distances = [right_dist, bot_dist, left_dist, top_dist]
	var checking = -1
	var valid = []
	var can_capture = []
	var change_dict_dict = {
		"d": {0: -minus_one, 1: plus_one, 2: minus_one, 3: -plus_one},
		"s": {0: 1, 1: nb_slots, 2: -1, 3:-nb_slots}
		
	}
	var change_dict = change_dict_dict[angle]
	
	var keep_in_mind = range(nb_slots**2)
	# top right diagonal
	for i in range(len(change_dict)):
		var to_check = get_to_check(distances, angle, i, distance)
		checking = location
		var foundCollision = 0
		for j in range(to_check):
			checking += change_dict[i]
			if checking not in keep_in_mind:
				break

			if not foundCollision:
				var output = check_collisions(checking, radius, piece, piece_type)
				foundCollision = output[0]
				can_capture += output[1]
				keep_in_mind = output[2]
			if foundCollision == 2:
				break
			valid.append(checking)
		foundCollision = 0
		keep_in_mind = range(nb_slots**2)

	set_board_capture(can_capture)
	
	return valid
	
func get_to_check(distances, angle, i, distance):
	if angle == "d":
		return min(distances[i-1], distances[i], distance)
	else:
		return min(distances[i], distance)

		
func get_knight_moves(piece, piece_type, location):
	var x_loc = location % nb_slots
	var y_loc = location / nb_slots
	var valid = []
	var foundCollision = 0
	var can_capture = []
	var keep_in_mind = range(nb_slots**2)
	var locations = []
	for possible in [[1, 2], [1, -2], [-1, 2], [-1, -2]]:
		locations.append([x_loc + nb_divs*possible[0], y_loc + nb_divs*possible[1]])
		locations.append([x_loc + nb_divs*possible[1], y_loc + nb_divs*possible[0]])
	
	for test in locations:
		var line = get_line_between([x_loc, y_loc], test)
		for checking in line:
			var output = check_collisions(coords_to_loc(checking), radius, piece, piece_type)
			foundCollision = output[0]
			can_capture += output[1]
			if keep_in_mind == range(nb_slots**2):
				keep_in_mind = output[2]
			else:
				keep_in_mind += output[2]
			if checking[0] in range(nb_slots) and checking[1] in range(nb_slots) and foundCollision != 2:
				valid.append(checking)
			
		foundCollision = 0
		keep_in_mind = range(nb_slots**2)
	
	for i in range(len(valid)):
		valid[i] = coords_to_loc(valid[i])

	set_board_capture(can_capture)
	
	return valid
	
	
func get_pawn_moves(piece, piece_type, location, direction, distance):
	var x_loc = location % nb_slots
	var y_loc = location / nb_slots
	var valid = []
	var valid_temp = []
	var foundCollision = 0
	var can_capture = []
	var keep_in_mind = range(nb_slots**2)
	var locations = []
	if direction == "d":
		locations.append([x_loc, y_loc + distance])
	elif direction == "u":
		locations.append([x_loc, y_loc - distance])
	elif direction == 'dd':
		locations.append([x_loc - distance, y_loc + distance])
		locations.append([x_loc + distance, y_loc + distance])
	elif direction == 'ud':
		locations.append([x_loc - distance, y_loc - distance])
		locations.append([x_loc + distance, y_loc - distance])
	
	for test in locations:
		var line = get_line_between([x_loc, y_loc], test)
		for checking in line:
			if coords_to_loc(checking) not in keep_in_mind:
				break
			if not foundCollision:
				var output = check_collisions(coords_to_loc(checking), radius, piece, piece_type)
				foundCollision = output[0]
				if direction in ["dd", "ud"]:
					can_capture += output[1]
				keep_in_mind = output[2]
			if foundCollision and direction in ["d", "u"]:
				break
			if foundCollision == 2:
				break
			if checking[0] in range(nb_slots) and checking[1] in range(nb_slots):
				valid_temp.append(checking)
				
		if direction in ["dd", "ud"] and not foundCollision:
			keep_in_mind = []
		for pos in valid_temp:
			if coords_to_loc(pos) in keep_in_mind and direction in ["dd", "ud"]:
				valid.append(pos)
			if direction in ["d", "u"]:
				valid = valid_temp
		foundCollision = 0
		keep_in_mind = range(nb_slots**2)
	
	if direction in ["dd", "ud"] and not len(can_capture):
		valid = []
	
	for i in range(len(valid)):
		valid[i] = coords_to_loc(valid[i])

	set_board_capture(can_capture)
	
	return valid
	
func get_line_between(point1, point2):
	var x1 = point1[0]
	var y1 = point1[1]
	var x2 = point2[0]
	var y2 = point2[1]
	var line = []
	var diff = [x2 - x1, y2 - y1]

	if abs(diff[0]) == abs(diff[1]):
		for i in range(abs(diff[0]) + 1):
			line.append([x1 + i*sign(diff[0]), y1 + i*sign(diff[1])])
	elif abs(diff[0]) > abs(diff[1]):
		var var_y = float(abs(diff[1])) / abs(diff[0])
		for i in range(abs(diff[0]) + 1):
			var x_coord = x1 + i*sign(diff[0])
			var y_coord = y1 + int(round(i*sign(diff[1])*var_y))
			line.append([x_coord, y_coord])
	else:
		var var_x = float(abs(diff[0])) / abs(diff[1])
		for i in range(abs(diff[1]) + 1):
			var y_coord = y1 + i*sign(diff[1])
			var x_coord = x1 + int(round(i*sign(diff[0])*var_x))
			line.append([x_coord, y_coord])

	return line
	
func coords_to_loc(coords):
	if coords[0] in range(nb_slots) and coords[1] in range(nb_slots):
		return nb_slots*coords[1] + coords[0]
	else:
		return -1

func clear_board_filters():
	for i in range(nb_slots**2):
		grid_array[i].set_filter(DataHandler.slot_states.None)

func set_board_free(positions):
	for i in positions:
		grid_array[i].set_filter(DataHandler.slot_states.Free)
		
func set_board_selected(positions):
	for i in positions:
		grid_array[i].set_filter(DataHandler.slot_states.Selected)
		
func set_board_capture(positions):
	for i in positions:
		grid_array[i].set_filter(DataHandler.slot_states.Capture)
