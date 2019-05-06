# Frame Rate in GameMaker

Hi there, Sanbox here. I’m the producer of **obj_podcast** (mostly making sure Seb wakes up for the podcast). I’m here to talk to you about mastering the power of time, except only in video games. Almost as good.

Spend any significant amount of time in any GameMaker (or other engines) community, and some fancy guy with a 144hz monitor will ask “how do I make my game frame independent?” to which a chorus of intelligent, brave, and extraordinarily handsome Linux users, beard and all, will respond “Delta time”. So that’s where we start.

## Delta Time Won’t Save You (at least, not on its own)
Let’s go through a very simple example of a jump:

First, what is delta time? Conceptually, it's the amount of time in seconds that have passed since the last frame and the start of the current one. If our game is running at exactly 1/60th a second (60 FPS), we would have a flat DT of 1/60th a second. GameMaker exposes this to us in microseconds in the variable `delta_time`. So we can quickly assign a global:
```
global.dt = delta_time / 1000000;
```
That will output `0.0167` each frame. We can totally use that, and many projects do, but personally, I prefer converting it to a ratio. So let's modify our code like this:
```
global.dt = 60 * delta_time / 1000000;
```
Now, `global.dt == 1` at 60 FPS, and 0.5 at 120 FPS and 2 at 30 FPS. In a sense, we're calling 60 FPS our "true" game state -- we want 30 and 120 to look at 60 FPS, just twice as smooth or twice as choppy.

So...how is this useful exactly?

Now, let's do a simple "jump" to see. If you're following along with the project, this is `obj_naive_implementation`:
```cs
#create

grav = 2;
jump_velocity = -10;

original_height = y;
state = State.WaitingForJump;
frame = 0;

enum State {
	WaitingForJump,
	Jumping
}

#step

global.dt = 60 * delta_time / 1000000;

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
		y += grav * global.dt;
		show_debug_message("HEIGHT == " + string(-(y - original_height)));
		if (y >= original_height) {
			show_debug_message("HIT GROUND");
			state = State.WaitingForJump;
		}	
	
	break;
}
```
So, first, we're using a super simple state system, largely so we can make sure to test over time. This will be scaffolding that allows us to test safely and with good logging support.

Secondly, we're applying `global.dt` to our gravity. But we aren't doing it to our jump_velociy. The reason is simple -- framerate is about things changing *over time*, not about *at a time*. We still want to jump 50 pixels at 10 FPS or at 100 FPS -- we just want to make sure that we're falling at the right speed. (If your spidey-sense is tingling at how we're jumping, good, you're ahead of us).

So, how's our delta time faring? Our test is simple -- we run for a few frames, and our raw time data and position in the world should match up. Note: we're not talking `frame` number here, since at 30 FPS, once the 1st (indexing from 0th frame at 0 time) frame has ran, 4 frames at 120 FPS have ran! So when you see a `-` in the charts below, that means that given FPS didn't run a frame at that time moment.

Okay, let's plot some of these out!

| Time    | 30 FPS | 60 FPS | 120 FPS |
| ------- | :----: | -----: | :-----: |
| 0       |   0    |      0 |
| 0.00833 |   -    |      - |    9    |
| 0.01667 |   -    |      8 |    8    |
| 0.02500 |   -    |      - |    7    |
| 0.03333 |   6    |      6 |    6    |


Okay, that's looking good! I could keep going, but I don't want to make these charts too big.

So let's add in one **key metric** -- Time at Landing. If all FPSes are showing the same for that (or within an acceptable margin of error), then we're doing great. Remember, we're measuring real time, not ticks here.

We calculate that by changing our Step Event to Look like this:

```cs
case State.Jumping:
    frame++;
    y += grav * global.dt;
    show_debug_message("HEIGHT == " + string(-(y - original_height)));
    if (y >= original_height) {
        show_debug_message("Time in air is: " + frame / room_speed);
        state = State.WaitingForJump;
    }	

break;
```

For this run.
| FPS | Time In Air |
| --- | :---------: |
| 30  |    0.08     |
| 60  |    0.08     |
| 120 |    0.10     |

Remember, we want all these numbers to be the same, so that's a great result, and in track with what our initial frame by frame comparison numbers were showing. Our 30 FPS is off because 10/4 is not even, so it simply has to wait all the way till its 3rd frame to move. This is a problem, but not a huge issue. 
This is called an **Off by 1** error in game timing. These are common, but it's the first of the problems introduced by delta timing our engine.

If this is how you jump in your game, you're good to go!

Unfortunately, this isn't how you jump in your game, because it looks terrible! We're just teleporting to our maximum height and then falling evenly. Gravity doesn't work like that -- it's an acceleration. And beyond "how it works in real life", in nearly every 2D game, and certainly in the big boys, like Mario, gravity is an acceleration. 

Let's change our code to reflect that:

```cs
#create
//... everything we wrote above still here
spd = 0;
max_height_found = false;
```
and let's just post the whole new Step Event
```cs
#step

global.dt = 60 * delta_time / 1000000;

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
```
Two things to notice:
1. We've changed our core movement. Now when we jump, we add a number to our `spd`, and when we fall, we add a number to our `spd` to lower it (technically we add a negative to jump and a positive for gravity, but I largely flip that because that makes no sense outside of GMS2's room structure).
2. We've added a nice new **key metric**: Maximum Jump height. As we will soon see, there are times when we'll jump for just as long, but we'll actually go much higher.

So, let's plug this into the hopper and see if trust ol DT is gonna help us out!

For the moment let's just look at our key graph (with our new max height!):

For this run.
| FPS | Time In Air | Max Height |
| --- | :---------: | :--------: |
| 30  |   0.13333   |     8      |
| 60  |   0.15000   |     20     |
| 120 |   0.15833   |     45     |

Oh no! Everything is gone astray now!
First, we're spending progressively longer in the air as our FPS increases, but even more egregiously, our height is decisively fucked. There seems to be an interesting relationship between these numbers, but more on that in Part II of this article.

Let's look at the frame by frame to get some clues...

|  Time   | 30 FPS | 60 FPS | 120 FPS |
| :-----: | :----: | :----: | :-----: |
|    0    |   10   |   10   |   10    |
| 0.00833 |   -    |   -    |    9    |
| 0.01667 |   -    |   8    |   17    |
| 0.02500 |   -    |   -    |   24    |
| 0.03333 |   6    |   14   |   30    |
| 0.04167 |   -    |   -    |   35    |
| 0.05000 |   -    |   18   |   39    |
| 0.05833 |   -    |   -    |   42    |
| 0.06667 |   8    |   20   |   44    |
| 0.07500 |   -    |   -    |   45    |
| 0.08333 |   -    |   20   |   45    |
| 0.09167 |   -    |   -    |   44    |
| 0.10000 |   6    |   18   |   42    |
| 0.10833 |   -    |   -    |   39    |
| 0.11667 |   -    |   14   |   35    |
| 0.12500 |   -    |   -    |   30    |
| 0.13333 |   0    |   8    |   24    |
| 0.14167 |   -    |   -    |   17    |
| 0.15000 |   -    |   0    |    9    |
| 0.15833 |        |        |    0    |

Huh. So this might look like a whole load of numbers, but it gives us a clue as to what we're doing.

These numbers are "parabolic", which means, for our purposes right now, we're going up at a certain rate and then we're falling at that same rate. This is *exactly* how gravity works in the real world. 

Physicists have long solved this problem in the real world. The equation for movement under a constant acceleration (like us) is as given:

```
p(t) = (1/2)at^2 + vt;
```

But that's math, and math is for losers.

First, we need to figure out mathematically what we were doing. 

If you look carefully, you'll find we were actually just doing:
```
p(t) = a (t * 60) + v + p(t - 1);
```
Let's walk through and prove it at 30 FPS:
```
p(1/30) = -2 (60/30) + 10 + 0 = 6
p(2/30) = -2 (60 * 2/ 30) + 10 + p(1/30) = 8
p(3/30) = -2 (60 * 3/ 30) + 10 + p(2/30) = 6
p(4/30) = -2 (60 * 4/ 30) + 10 + p(3/30) = 0
```
and at 60 FPS:
```
p(1/60)