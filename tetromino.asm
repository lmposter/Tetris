.data

##############################################################################
# Constants
##############################################################################
grid:           .space 1056             # 22x12 grid (264 elements, 4 bytes each)
total_rows:     .word 22                # Number of rows
total_cols:     .word 12                # Number of columns
display_base:   .word 0x10008000        # Bitmap display base address
keyboard_base:  .word 0xffff0000        # Keyboard base address
tetro_space:    .space 16               # Space for current tetromino (4 elements, 4 bytes each)

# Default colors
color_black:    .word 0x000000
color_grey:     .word 0x808080
color_darkgrey: .word 0x242424

##############################################################################
# Variables
##############################################################################
collision_flag:         .word -1        # Collision detection flag
movement_flag:          .word -1        # Movement direction flag
rotation_state:         .word 0         # Rotation state of current tetromino (0 to 3)
current_tetromino:      .word -1        # Current tetromino type
tetromino_color:        .word -1        # Current tetromino color
collision_time:         .word 0         # Time in downward collision (ms)
gravity_timer:          .word 0         # Timer for gravity effect
gravity_interval:       .word 100       # Gravity interval (default 100ms)
gravity_speedup_timer:  .word 0         # Timer for gravity speedup
gravity_speedup_interval:.word 1000     # Interval for increasing gravity speed
music_timer:            .word 0         # Timer for Tetris theme music
music_index:            .word 0         # Index for music data arrays

.text

##############################################################################
# Main
##############################################################################

# Function to place a random tetromino on the board
placeTetromino: 
    subi $sp, $sp, 4                   # Decrement stack pointer
    sw $ra, 0($sp)                     # Store $ra onto the stack
    
    li $v0, 42                         # syscall number for generating a random integer
    li $a0, 0
    li $a1, 7                          # Upper bound of range of returned values
    syscall                            # Generate random number

    sw $a0, current_tetromino          # Store random number as current tetromino

    jal clearTetromino                 # Clear current tetromino in array

    # Determine tetromino type
    beq $a0, 0, load_O_tetromino
    beq $a0, 1, load_I_tetromino
    beq $a0, 2, load_S_tetromino
    beq $a0, 3, load_Z_tetromino
    beq $a0, 4, load_L_tetromino
    beq $a0, 5, load_J_tetromino
    beq $a0, 6, load_T_tetromino

load_O_tetromino:
    jal loadOTetromino
    j finish_loading
load_I_tetromino:
    jal loadITetromino
    j finish_loading
load_S_tetromino:
    jal loadSTetromino
    j finish_loading
load_Z_tetromino:
    jal loadZTetromino
    j finish_loading
load_L_tetromino:
    jal loadLTetromino
    j finish_loading
load_J_tetromino:
    jal loadJTetromino
    j finish_loading
load_T_tetromino:
    jal loadTTetromino
    j finish_loading

finish_loading:
    jal getTetrominoColor              # Get the color of the current tetromino
    
    # Check for game over
    la $s0, grid                       # Base address of 2D array
    la $s1, tetro_space                # Base address of tetromino array
    lw $s2, display_base               # Base address of bitmap display
    addi $t0, $zero, 0                 # Loop counter
    
check_game_over:
    beq $t0, 4, end_check_game_over
    
    lw $t1, ($s1)                      # Load current tetromino cell address
    sub $t1, $t1, $s2                  # Calculate offset in grid
    add $t2, $s0, $t1                  # Calculate absolute address in grid
    
    lw $t3, color_grey                 # Load grey color
    lw $t4, color_darkgrey             # Load dark grey color
    lw $t5, ($t2)                      # Load color at current address
    
    beq $t5, $t3, no_end_game
    beq $t5, $t4, no_end_game
    beq $t5, $zero, no_end_game

end_game:
    li $v0, 10                         # syscall code for exit
    syscall                            # Exit program

no_end_game:
    addi $s1, $s1, 4                   # Increment tetromino address
    addi $t0, $t0, 1                   # Increment loop counter
    j check_game_over

end_check_game_over:
    jal printTetromino

    lw $ra, 0($sp)                     # Restore return address
    addi $sp, $sp, 4                   # Increment stack pointer
    jr $ra                             # Return to caller

# Function to get the color of the current tetromino
getTetrominoColor:
    lw $t0, current_tetromino

    beq $t0, 0, set_yellow
    beq $t0, 1, set_blue
    beq $t0, 2, set_red
    beq $t0, 3, set_green
    beq $t0, 4, set_orange
    beq $t0, 5, set_pink
    beq $t0, 6, set_purple
    jr $ra

set_yellow:
    li $t1, 0xFFFF00
    sw $t1, tetromino_color
    jr $ra

set_blue:
    li $t1, 0x0000FF
    sw $t1, tetromino_color
    jr $ra

set_red:
    li $t1, 0xFF0000
    sw $t1, tetromino_color
    jr $ra

set_green:
    li $t1, 0x00FF00
    sw $t1, tetromino_color
    jr $ra

set_orange:
    li $t1, 0xFFA500
    sw $t1, tetromino_color
    jr $ra

set_pink:
    li $t1, 0xFF1493
    sw $t1, tetromino_color
    jr $ra

set_purple:
    li $t1, 0x800080
    sw $t1, tetromino_color
    jr $ra

# Function to print tetromino to the display
printTetromino:
    lw $s1, display_base
    la $s2, tetro_space
    li $t0, 0
    li $t1, 4

print_loop:
    lw $t3, 0($s2)
    addi $s2, $s2, 4
    addi $t0, $t0, 1

    add $s1, $zero, $t3
    lw $t4, tetromino_color
    sw $t4, 0($s1)

    bge $t0, $t1, end_print_loop
    j print_loop

end_print_loop:
    jr $ra

# Function to clear the tetromino array
clearTetromino:
    la $s2, tetro_space
    li $t0, 0
    li $t1, 4

clear_loop:
    sw $zero, 0($s2)
    addi $s2, $s2, 4
    addi $t0, $t0, 1

    bge $t0, $t1, end_clear_loop
    j clear_loop

end_clear_loop:
    jr $ra

# Function to transfer tetromino data to the grid array
tetrominoToArray:
    la $s0, grid
    la $s1, tetro_space
    lw $s2, display_base
    li $t0, 0

transfer_loop:
    beq $t0, 4, end_transfer_loop
    
    lw $t1, 0($s1)
    sub $t1, $t1, $s2
    add $t2, $s0, $t1
    lw $t3, tetromino_color
    sw $t3, 0($t2)

    addi $s1, $s1, 4
    addi $t0, $t0, 1
    j transfer_loop

end_transfer_loop:
    sw $zero, rotation_state

    li $v0, 31
    li $a0, 30
    li $a1, 5
    li $a2, 87
    li $a3, 100
    syscall

    jr $ra

# Function to load Z tetromino
loadZTetromino:
    lw $s1, display_base
    la $s2, tetro_space

    addi $t1, $zero, 4
    addi $t2, $zero, 64

    add $s1, $s1, $t2
    sw $s1, 0($s2)

    addi $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    li $t3, 3
    sw $t3, current_tetromino
    jr $ra

# Function to load S tetromino
loadSTetromino:
    lw $s1, display_base
    la $s2, tetro_space

    addi $t1, $zero, 4
    addi $t2, $zero, 72

    add $s1, $s1, $t2
    sw $s1, 0($s2)

    sub $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    sub $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    li $t3, 2
    sw $t3, current_tetromino
    jr $ra

# Function to load I tetromino
loadITetromino:
    lw $s1, display_base
    la $s2, tetro_space

    addi $t1, $zero, 4
    addi $t2, $zero, 68

    add $s1, $s1, $t2
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    li $t3, 1
    sw $t3, current_tetromino
    jr $ra

# Function to load L tetromino
loadLTetromino:
    lw $s1, display_base
    la $s2, tetro_space

    addi $t1, $zero, 4
    addi $t2, $zero, 68

    add $s1, $s1, $t2
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    li $t3, 4
    sw $t3, current_tetromino
    jr $ra

# Function to load J tetromino
loadJTetromino:
    lw $s1, display_base
    la $s2, tetro_space

    addi $t1, $zero, 4
    addi $t2, $zero, 72

    add $s1, $s1, $t2
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 48
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    sub $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    li $t3, 5
    sw $t3, current_tetromino
    jr $ra

# Function to load T tetromino
loadTTetromino:
    lw $s1, display_base
    la $s2, tetro_space

    addi $t1, $zero, 4
    addi $t2, $zero, 64

    add $s1, $s1, $t2
    sw $s1, 0($s2)

    addi $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 44
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    li $t3, 6
    sw $t3, current_tetromino
    jr $ra

# Function to load O tetromino
loadOTetromino:
    lw $s1, display_base
    la $s2, tetro_space

    addi $t1, $zero, 4
    addi $t2, $zero, 68

    add $s1, $s1, $t2
    sw $s1, 0($s2)

    addi $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 44
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    addi $s1, $s1, 4
    addi $s2, $s2, 4
    sw $s1, 0($s2)

    li $t3, 0
    sw $t3, current_tetromino
    jr $ra
