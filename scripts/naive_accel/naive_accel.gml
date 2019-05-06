switch (state) {
	case State.WaitingForJump:
		if (mouse_check_button(mb_left)) {
			show_debug_message("JUMP");
			spd += jump_velocity;
			state = State.Jumping;
			frame = 0;
		}

	break;
	
	case State.Jumping:
		frame++;
		spd += grav * global.dt;
		
		y += spd;
		show_debug_message("HEIGHT == " + string(-(y - original_height)));
		
		if ((y > yprevious) && (max_height_found == false)) {
			show_debug_message("MAX HEIGHT WAS: " + string(yprevious - original_height));	
			max_height_found = true;
		}
		
		if (y >= original_height) {
			show_debug_message("Time in air is: " + string(frame / room_speed));
			state = State.WaitingForJump;
		}	
	
	break;
}