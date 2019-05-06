grav = 2;
jump_velocity = -10;
spd = 0;


original_height = y;
state = State.WaitingForJump;
frame = 0;
max_height_found = false;

//enum State {
//	WaitingForJump,
//	Jumping
//}

show_debug_message("Room Speed is " + string(room_speed));