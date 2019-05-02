grav = 2;
jump_velocity = -50;
original_height = y;

state = State.WaitingForJump;
frame = 0;

enum State {
	WaitingForJump,
	Jumping
}