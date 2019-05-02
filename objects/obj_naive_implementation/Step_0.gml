switch (state) {
	case State.WaitingForJump:
		if (mouse_check_button(mb_left)) {
			show_debug_message("JUMP");
			y += jump_velocity;
			state = State.Jumping;
			frame = 0;
		}

	break;
	
	case State.Jumping:
		frame++;
		y += grav;
		show_debug_message("HEIGHT == " + string(-(y - original_height)));
		if (y >= original_height) {
			show_debug_message("HIT GROUND");
			state = State.WaitingForJump;
		}	
	
	break;
}
