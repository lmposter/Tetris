.data

##############################################################################
# Constants
##############################################################################
# Game settings and configurations
game_list:     .space 1056             # Reserve space for a 22x12 grid (264 elements, 4 bytes each)
num_rows:       .word 22                # Define total number of rows
num_cols:       .word 12                # Define total number of columns
display_base:   .word 0x10008000        # Base address for the display
keyboard_base:  .word 0xffff0000        # Base address for the keyboard
current_tetro:  .space 16               # Space for the current tetromino (4 elements, 4 bytes each)

# Default colors
clr_black:      .word 0x000000
clr_grey:       .word 0x808080
clr_dark_grey:  .word 0x242424

##############################################################################
# Variables
##############################################################################
# Flags and state variables
collision_flag:         .word -1        # Flag for collision detection (1 if collision, 0 otherwise)
movement_flag:          .word -1        # Flag for movement direction (0=down, 1=left, 2=right, 3=rotate)
rotation_state_flag:    .word 0         # Flag for the rotation state of the current tetromino (0 to 3)
active_tetromino:       .word -1        # Flag for current tetromino type (0=O, 1=I, etc.)
tetromino_color:        .word -1        # Current tetromino color
down_collision_time:    .word 0         # Time spent in downward collision (ms)
gravity_timer:          .word 0         # Timer for gravity effect
gravity_interval:       .word 100       # Interval for gravity effect (default 100ms)
gravity_speedup_timer:  .word 0         # Timer for increasing gravity speed
gravity_speedup_interval:.word 1000     # Interval for gravity speedup
music_play_timer:       .word 0         # Timer for Tetris theme music
music_note_index:       .word 0         # Index for music data lists

.text

##############################################################################
# Main
##############################################################################

# Function to handle keyboard input
handleKeyboardInput:
    lw $t0, keyboard_base        # Load keyboard base address
    lw $t1, 0($t0)               # Read keyboard input
    beq $t1, 0, exit_handleInput # If no input, exit function
    
    lw $t2, 4($t0)               # Load key press value
    beq $t2, 0x61, move_left     # If 'A' key, move left
    beq $t2, 0x73, move_down     # If 'S' key, move down
    beq $t2, 0x64, move_right    # If 'D' key, move right
    beq $t2, 0x77, rotate_tetro  # If 'W' key, rotate tetromino
    beq $t2, 0x71, quit_game     # If 'Q' key, quit game
    j exit_handleInput
    
    move_left:
        li $t3, 1
        sw $t3, movement_flag    # Set movement flag to 1 (left)
        j exit_handleInput
    move_down:
        li $t3, 0
        sw $t3, movement_flag    # Set movement flag to 0 (down)
        j exit_handleInput
    move_right:
        li $t3, 2
        sw $t3, movement_flag    # Set movement flag to 2 (right)
        j exit_handleInput
    rotate_tetro:
        li $t3, 3
        sw $t3, movement_flag    # Set movement flag to 3 (rotate)
        j exit_handleInput
    quit_game:
        li $v0, 10               # Syscall for exit
        syscall                  # Exit program

exit_handleInput:
    jr $ra                       # Return from function

# Function to move tetromino based on movement_flag
moveTetromino:
    la $t0, current_tetro        # Load address of current tetromino
    lw $t1, num_cols             # Load number of columns
    lw $t2, movement_flag        # Load movement flag

    moveTetromino_loop:
        lw $t3, 0($t0)           # Load current tetromino cell address
        lw $t4, display_base     # Load display base address

        # Calculate new position based on movement direction
        beq $t2, 0, move_down    # Move down
        beq $t2, 1, move_left    # Move left
        beq $t2, 2, move_right   # Move right
        j end_moveTetromino

    move_down:
        mul $t5, $t1, 4          # Calculate offset for moving down
        add $t3, $t3, $t5
        sw $t3, 0($t0)
        j update_next_cell
    move_left:
        sub $t3, $t3, 4          # Calculate offset for moving left
        sw $t3, 0($t0)
        j update_next_cell
    move_right:
        add $t3, $t3, 4          # Calculate offset for moving right
        sw $t3, 0($t0)
        j update_next_cell

    update_next_cell:
        addi $t0, $t0, 4         # Move to next cell in tetromino
        bne $t0, 16, moveTetromino_loop  # Loop until all cells are updated

    end_moveTetromino:
    li $t2, -1
    sw $t2, movement_flag        # Reset movement flag
    jr $ra                       # Return from function

# Function to detect collisions
detectCollisions:
    lw $t0, display_base         # Load display base address
    la $t1, current_tetro        # Load address of current tetromino
    la $t2, game_list           # Load game list base address
    lw $t3, clr_dark_grey        # Load dark grey color value

    detectCollisions_loop:
        lw $t4, 0($t1)           # Load current tetromino cell address
        sub $t4, $t4, $t0        # Calculate offset in game list
        add $t4, $t4, $t2        # Calculate absolute address in game list
        lw $t5, 0($t4)           # Load value at game list address

        # Check for collision based on movement direction
        lw $t6, movement_flag
        beq $t6, 0, check_down_collision
        beq $t6, 1, check_left_collision
        beq $t6, 2, check_right_collision
        j end_detectCollisions

    check_down_collision:
        lw $t7, num_cols
        mul $t7, $t7, 4          # Calculate offset for down movement
        add $t4, $t4, $t7
        lw $t8, 0($t4)
        bne $t8, clr_black, collision_detected
        bne $t8, clr_dark_grey, collision_detected
        j no_collision

    check_left_collision:
        sub $t4, $t4, 4          # Calculate offset for left movement
        lw $t8, 0($t4)
        bne $t8, clr_black, collision_detected
        bne $t8, clr_dark_grey, collision_detected
        j no_collision

    check_right_collision:
        add $t4, $t4, 4          # Calculate offset for right movement
        lw $t8, 0($t4)
        bne $t8, clr_black, collision_detected
        bne $t8, clr_dark_grey, collision_detected
        j no_collision

    no_collision:
        li $t9, 0
        sw $t9, collision_flag   # No collision
        j next_cell

    collision_detected:
        li $t9, 1
        sw $t9, collision_flag   # Collision detected
        j end_detectCollisions

    next_cell:
        addi $t1, $t1, 4         # Move to next cell in tetromino
        blt $t1, 16, detectCollisions_loop

    end_detectCollisions:
    jr $ra                       # Return from function

# Function to rotate the tetromino
rotateTetromino:
    la $t0, current_tetro        # Load current tetromino address
    la $t1, game_list           # Load game list base address
    lw $t2, display_base         # Load display base address
    lw $t3, clr_dark_grey        # Load dark grey color value
    lw $t4, active_tetromino     # Load current tetromino type
    lw $t5, rotation_state_flag  # Load current rotation state

    # Calculate rotation list base address
    mul $t4, $t4, 64
    mul $t5, $t5, 16
    add $t6, $t4, $t5
    la $t7, O_rotation_0
    add $t7, $t7, $t6

    rotate_check_loop:
        lw $t8, 0($t0)           # Load current cell address
        lw $t9, 0($t7)           # Load rotation offset
        add $t8, $t8, $t9        # Calculate new position
        sub $t8, $t8, $t2        # Calculate offset in game list
        add $t8, $t8, $t1        # Calculate absolute address in game list
        lw $t10, 0($t8)          # Load value at game list address

        bne $t10, clr_black, rotation_collision_detected
        bne $t10, clr_dark_grey, rotation_collision_detected

        addi $t0, $t0, 4         # Move to next cell
        addi $t7, $t7, 4
        blt $t0, 16, rotate_check_loop

    rotate_update_loop:
        lw $t8, 0($t0)           # Load current cell address
        lw $t9, 0($t7)           # Load rotation offset
        add $t8, $t8, $t9        # Calculate new position
        sw $t8, 0($t0)           # Update tetromino position

        addi $t0, $t0, 4         # Move to next cell
        addi $t7, $t7, 4
        blt $t0, 16, rotate_update_loop

    # Update rotation state
    lw $t11, rotation_state_flag
    addi $t11, $t11, 1
    bge $t11, 4, reset_rotation_state
    j update_rotation_state

    reset_rotation_state:
        li $t11, 0

    update_rotation_state:
        sw $t11, rotation_state_flag

    # Play sound for rotation
    li $v0, 31
    li $a0, 60
    li $a1, 5
    li $a2, 87
    li $a3, 100
    syscall

    rotation_collision_detected:
    jr $ra                       # Return from function
