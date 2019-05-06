grav = 2;
jump_velocity = -10;
original_height = y;

state = State.WaitingForJump;
frame = 0;

enum State {
	WaitingForJump,
	Jumping
}

show_debug_message(room_speed);