var current_fps = 30;
global.dt = 60/current_fps;
game_set_speed(current_fps, gamespeed_fps);
// If you're looking at this project, change global.dt to appropriate values.
// Please read the article to see why we're hardcoding.

switch (state) {
	case State.WaitingForJump:
		if (mouse_check_button_pressed(mb_left)) {
			show_debug_message("JUMP");
			spd += jump_velocity * global.dt;
			state = State.Jumping;
			frame = 0;
			max_height_found = false;
		}

	break;
	
	case State.Jumping:
		frame++;
		spd += grav * global.dt;
		
		y += spd;
		show_debug_message("HEIGHT == " + string_format(-(y - original_height), 5, 5));
		
		if ((y > yprevious) && (max_height_found == false)) {
			show_debug_message("MAX HEIGHT WAS: " + string_format(yprevious - original_height, 5, 5));	
			max_height_found = true;
		}
		
		if (y >= original_height) {
			show_debug_message("Time in air is: " + string_format(frame / room_speed, 5, 5));
			state = State.WaitingForJump;
		}	
	
	break;
}

