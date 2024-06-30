######################## Bitmap Display Configuration ########################
# Configuration details for the bitmap display
# - Pixel dimensions per unit: 1x1
# - Display size in pixels: 12x22 (includes 2-pixel boundary)
# - Base display address: 0x10008000 ($gp)
##############################################################################

##############################################################################
# Data Allocation
##############################################################################
# Constants
list:           .space 1056        # 22 rows x 12 columns, 264 elements, 4 bytes each
num_rows:        .word 22           # Total number of rows
num_cols:        .word 12           # Total number of columns
base_display:    .word 0x10008000   # Display base address
keyboard_addr:   .word 0xffff0000   # Keyboard base address
tetromino_mem:   .space 16          # Space for current tetromino (4 elements, 4 bytes each)

# Variables for game state management
collision_flag:        .word -1     # Collision detection flag (-1 means uninitialized)
movement_flag:         .word -1     # Movement direction flag (-1 means uninitialized)
rotation_state:        .word 0      # Tetromino rotation state (0 to 3)
active_tetromino:      .word -1     # Current tetromino type (0 to 6)
tetromino_color:       .word -1     # Current tetromino color code
down_collision_time:   .word 0      # Time spent in downward collision (ms)
gravity_timer:         .word 0      # Timer for gravity effect
gravity_interval:      .word 100    # Gravity interval (default 100ms)
gravity_inc_timer:     .word 0      # Timer for gravity speed increment
gravity_inc_interval:  .word 1000   # Interval for increasing gravity speed
music_timer:           .word 0      # Timer for Tetris theme playback
music_index:           .word 0      # Index for current note in the music lists

##############################################################################
# Imports
##############################################################################
# Including shared data and functionality from other files
.entry main
.include "config.s"
.include "keys.asm"
.include "list.asm"
.include "tetromino.asm"

##############################################################################
# Main Code
##############################################################################
main:
    # Initial game setup
    jal initDisplay                  # Initialize and display the game board
    jal spawnTetromino               # Spawn a new tetromino

game_loop:
    ######################## HANDLE USER INPUT ###########################
    jal getKeyboardInput             # Read keyboard input

    # Process input for movement and rotation
    lw $t0, movement_flag            # Load movement flag
    beq $t0, 0, detectCollision
    beq $t0, 1, detectCollision
    beq $t0, 2, detectCollision
    beq $t0, 3, rotateTetromino
    j skip_rotation

detectCollision:
    jal checkCollision               # Check for collisions in the specified direction
    lw $t0, collision_flag
    beq $t0, 0, moveTetromino        # Move if no collision
    j skip_movement
moveTetromino:
    jal clearTetromino               # Clear current tetromino from display
    jal updateTetromino              # Update tetromino position
    j skip_rotation
skip_movement:
    j skip_rotation

rotateTetromino:
    jal clearTetromino
    jal rotateCurrentTetromino       # Rotate tetromino
skip_rotation:
    jal renderTetromino              # Render tetromino on display

    ######################## PLACE TETROMINO ###########################
    sw $zero, collision_flag         # Reset collision flag
    sw $zero, movement_flag          # Set movement direction to down
    jal checkCollision               # Check for downward collisions
    addi $t0, $zero, -1
    sw $t0, movement_flag            # Reset movement flag

    # Handle downward collision timing
    lw $t0, collision_flag
    beq $t0, 1, incCollisionTimer
    beq $t0, 0, resetCollisionTimer
    j end_collision_timer
incCollisionTimer:
    lw $t0, down_collision_time
    addi $t0, $t0, 1
    sw $t0, down_collision_time
    j end_collision_timer
resetCollisionTimer:
    sw $zero, down_collision_time
end_collision_timer:

    # Place tetromino if collision time exceeds threshold
    lw $t0, down_collision_time
    bge $t0, 50, finalizeTetromino
    j end_finalize_tetromino
finalizeTetromino:
    jal transferTetrominoToGrid      # Transfer tetromino to grid
    jal clearTetromino
    jal spawnTetromino               # Spawn new tetromino
    jal clearCompletedLines          # Clear any completed lines
    jal redrawGrid                   # Redraw the grid
    jal renderGrid                   # Render grid to display
end_finalize_tetromino:

    ######################## HANDLE GRAVITY ###########################
    # Update gravity timer
    lw $t0, gravity_timer
    addi $t0, $t0, 1
    sw $t0, gravity_timer

    # Update gravity increment timer
    lw $t0, gravity_inc_timer
    addi $t0, $t0, 5
    sw $t0, gravity_inc_timer

    # Move tetromino down if gravity timer exceeds interval
    lw $t0, gravity_timer
    lw $t1, gravity_interval
    bge $t0, $t1, applyGravity
    j end_gravity
applyGravity:
    sw $zero, collision_flag         # Reset collision flag
    sw $zero, movement_flag          # Set movement direction to down
    jal checkCollision               # Check for downward collisions
    lw $t0, collision_flag
    beq $t0, 0, moveDownward
    j gravity_collision
moveDownward:
    jal clearTetromino
    jal updateTetromino
    jal renderTetromino
    sw $zero, gravity_timer          # Reset gravity timer
gravity_collision:
    addi $t0, $zero, -1
    sw $t0, movement_flag            # Reset movement flag
end_gravity:

    # Increase gravity speed if increment timer exceeds interval
    lw $t0, gravity_inc_timer
    lw $t1, gravity_inc_interval
    bge $t0, $t1, speedUpGravity
    j end_speed_up
speedUpGravity:
    lw $t2, gravity_interval
    bge $t2, 20, decreaseGravityInterval
    j end_decrease_interval
decreaseGravityInterval:
    addi $t2, $t2, -10
    sw $t2, gravity_interval
end_decrease_interval:
    sw $zero, gravity_inc_timer      # Reset gravity increment timer
end_speed_up:

    ######################## PLAY MUSIC ###########################
    # Reset music index if at end of list
    lw $t0, music_index
    bge $t0, 39, resetMusicIndex
    j end_reset_index
resetMusicIndex:
    addi $t0, $zero, 0
    sw $t0, music_index
end_reset_index:

    # Play note if music timer exceeds delay
    mul $t0, $t0, 4
    la $t1, delays
    add $t1, $t1, $t0
    lw $t2, ($t1)
    lw $t3, music_timer
    bge $t3, $t2, playNote
    ble $t0, 0, playNote
    addi $t3, $t3, 5
    sw $t3, music_timer
    j end_play_note
playNote:
    la $t4, pitches
    add $t4, $t4, $t0
    lw $a0, ($t4)
    la $t5, durations
    add $t5, $t5, $t0
    lw $a1, ($t5)
    li $v0, 31
    li $a2, 0
    li $a3, 100
    syscall
    sw $zero, music_timer
    lw $t0, music_index
    addi $t0, $t0, 1
    sw $t0, music_index
end_play_note:

    ######################## SLEEP AND REPEAT ###########################
    li $v0, 32
    li $a0, 5
    syscall

    # Loop back to the start of the game loop
    j game_loop
end_game_loop:

    # Exit the program
    li $v0, 10
    syscall