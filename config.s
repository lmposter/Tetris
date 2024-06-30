.data

##############################################################################
# Configurations
##############################################################################
# Settings
game_grid:      .space 1056           # 22x12 grid, 264 elements, 4 bytes each
total_rows:     .word 22              # Total number of rows
total_cols:     .word 12              # Total number of columns
display_base:   .word 0x10008000      # Base address for display
keyboard_base:  .word 0xffff0000      # Base address for keyboard
tetromino_data: .space 16             # Space for current tetromino (4 elements, 4 bytes each)

# Default colors
color_black:    .word 0x000000
color_grey:     .word 0x808080
color_darkgrey: .word 0x242424

# Tetromino rotation data
O_rotation_0:   .word 0, 0, 0, 0
O_rotation_1:   .word 0, 0, 0, 0
O_rotation_2:   .word 0, 0, 0, 0
O_rotation_3:   .word 0, 0, 0, 0

I_rotation_0:   .word 40, -4, -48, -92
I_rotation_1:   .word -40, 4, 48, 92
I_rotation_2:   .word 40, -4, -48, -92
I_rotation_3:   .word -40, 4, 48, 92

S_rotation_0:   .word -4, 48, 4, 56
S_rotation_1:   .word 4, -48, -4, -56
S_rotation_2:   .word -4, 48, 4, 56
S_rotation_3:   .word 4, -48, -4, -56

Z_rotation_0:   .word 8, 52, 0, 44
Z_rotation_1:   .word -8, -52, 0, -44
Z_rotation_2:   .word 8, 52, 0, 44
Z_rotation_3:   .word -8, -52, 0, -44

L_rotation_0:   .word 52, 0, -52, -8
L_rotation_1:   .word 44, 0, -44, -96
L_rotation_2:   .word -52, 0, 52, 8
L_rotation_3:   .word -44, 0, 44, 96

J_rotation_0:   .word 52, 0, -52, -96
J_rotation_1:   .word 44, 0, -44, 8
J_rotation_2:   .word -52, 0, 52, 96
J_rotation_3:   .word -44, 0, 44, -8

T_rotation_0:   .word -44, 0, 44, -52
T_rotation_1:   .word 52, 0, -52, -44
T_rotation_2:   .word 44, 0, -44, 52
T_rotation_3:   .word -52, 0, 52, 44

# Music data for Tetris theme
note_pitches:   .word 64, 59, 60, 62, 60, 59, 57, 57, 60, 64, 62, 60, 59, 59, 60, 62, 64, 60, 57, 57, 62, 65, 69, 67, 65, 64, 60, 64, 62, 60, 59, 59, 60, 62, 64, 60, 57, 57, 0
note_durations: .word 100, 50, 500, 100, 50, 50, 100, 50, 50, 200, 100, 100, 200, 100, 100, 200, 200, 200, 200, 200, 200, 100, 200, 100, 100, 300, 100, 200, 100, 100, 200, 100, 100, 200, 200, 200, 200, 200, 0
note_delays:    .word 0, 325, 200, 200, 325, 200, 200, 325, 200, 200, 325, 200, 200, 325, 200, 200, 325, 325, 325, 325, 1150, 325, 200, 325, 200, 200, 550, 200, 325, 200, 200, 325, 200, 200, 325, 325, 325, 325, 1000

##############################################################################
# Variables
##############################################################################
collision_flag:         .word -1        # Collision detection flag
movement_flag:          .word -1        # Movement direction flag
rotation_flag:          .word 0         # Tetromino rotation state
current_tetromino:      .word -1        # Current tetromino type
tetromino_color:        .word -1        # Current tetromino color
down_collision_time:    .word 0         # Time in downward collision (ms)
gravity_timer:          .word 0         # Timer for gravity effect
gravity_interval:       .word 100       # Gravity interval (default 100ms)
gravity_increment_timer:.word 0         # Timer for gravity speed increment
gravity_increment_interval:.word 1000   # Interval for increasing gravity speed
music_timer:            .word 0         # Timer for Tetris theme
music_index:            .word 0         # Index for music data arrays

.text