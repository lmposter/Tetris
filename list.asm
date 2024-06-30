##############################################################################
# Display Configuration Constants
##############################################################################
# - Unit dimensions: 1x1 pixels
# - Display size: 12x22 pixels (10 blocks + 2 boundaries each)
# - Base Address for Display: 0x10008000 ($gp)
##############################################################################

##############################################################################
# Definitions
##############################################################################
# Constants
list:          .space 1056          # 22x12 grid, 264 elements (4 bytes each)
row_count:      .word 22             # Number of rows
column_count:   .word 12             # Number of columns
display_base:   .word 0x10008000     # Display base address
keyboard_base:  .word 0xffff0000     # Keyboard base address
tetromino_mem:  .space 16            # Space for current tetromino (4 elements, 4 bytes each)

# Variables
collision_flag:     .word -1         # Collision detection flag
movement_flag:      .word -1         # Movement direction flag
rotation_state:     .word 0          # Tetromino rotation state
current_piece:      .word -1         # Current tetromino
tetromino_color:    .word -1         # Current tetromino color
down_collision_time:.word 0          # Time in downward collision (ms)
gravity_timer:      .word 0          # Gravity effect timer
gravity_interval:   .word 100        # Gravity interval (default 100ms)
gravity_inc_timer:  .word 0          # Gravity speed increment timer
gravity_inc_interval:.word 1000      # Interval for increasing gravity speed
music_timer:        .word 0          # Tetris theme timer
music_index:        .word 0          # Index for music data lists

##############################################################################
# Main
##############################################################################
.entry main
.include "config.s"
.include "keys.asm"
.include "list.asm"
.include "tetromino.asm"

main:
    # Initialize game
    jal initializeDisplay
    jal spawnTetromino

gameLoop:
    ######################## HANDLE INPUT ###########################
    jal readKeyboardInput

    # Process movement and rotation
    lw $t0, movement_flag
    beq $t0, 0, handleCollision
    beq $t0, 1, handleCollision
    beq $t0, 2, handleCollision
    beq $t0, 3, handleRotation
    j skipRotation

handleCollision:
    jal checkForCollision
    lw $t0, collision_flag
    beq $t0, 0, movePiece
    j skipMovement
movePiece:
    jal eraseTetromino
    jal moveTetromino
    j skipRotation
skipMovement:
    j skipRotation

handleRotation:
    jal eraseTetromino
    jal rotatePiece
skipRotation:
    jal renderTetromino

    ######################## PLACE TETROMINO ###########################
    sw $zero, collision_flag
    sw $zero, movement_flag
    jal checkForCollision
    addi $t0, $zero, -1
    sw $t0, movement_flag

    # Handle collision timing
    lw $t0, collision_flag
    beq $t0, 1, incrementCollisionTimer
    beq $t0, 0, resetCollisionTimer
    j endCollisionTimer
incrementCollisionTimer:
    lw $t0, down_collision_time
    addi $t0, $t0, 1
    sw $t0, down_collision_time
    j endCollisionTimer
resetCollisionTimer:
    sw $zero, down_collision_time
endCollisionTimer:

    # Place tetromino if collision time exceeds threshold
    lw $t0, down_collision_time
    bge $t0, 50, placeTetromino
    j endPlaceTetromino
placeTetromino:
    jal transferToGrid
    jal clearTetrominoMemory
    jal spawnTetromino
    jal clearFullLines
    jal refreshBackground
    jal renderGrid
endPlaceTetromino:

    ######################## HANDLE GRAVITY ###########################
    # Update gravity timer
    lw $t0, gravity_timer
    addi $t0, $t0, 1
    sw $t0, gravity_timer

    # Update gravity increment timer
    lw $t0, gravity_inc_timer
    addi $t0, $t0, 5
    sw $t0, gravity_inc_timer

    # Apply gravity if timer exceeds interval
    lw $t0, gravity_timer
    lw $t1, gravity_interval
    bge $t0, $t1, applyGravity
    j endGravity
applyGravity:
    sw $zero, collision_flag
    sw $zero, movement_flag
    jal checkForCollision
    lw $t0, collision_flag
    beq $t0, 0, moveDown
    j gravityCollision
moveDown:
    jal eraseTetromino
    jal moveTetromino
    jal renderTetromino
    sw $zero, gravity_timer
gravityCollision:
    addi $t0, $zero, -1
    sw $t0, movement_flag
endGravity:

    # Increase gravity speed if timer exceeds interval
    lw $t0, gravity_inc_timer
    lw $t1, gravity_inc_interval
    bge $t0, $t1, increaseGravity
    j endIncreaseGravity
increaseGravity:
    lw $t2, gravity_interval
    bge $t2, 20, decreaseGravityInterval
    j endDecreaseInterval
decreaseGravityInterval:
    addi $t2, $t2, -10
    sw $t2, gravity_interval
endDecreaseInterval:
    sw $zero, gravity_inc_timer
endIncreaseGravity:

    ######################## PLAY MUSIC ###########################
    # Reset music index if end of list is reached
    lw $t0, music_index
    bge $t0, 39, resetMusicIndex
    j endResetIndex
resetMusicIndex:
    addi $t0, $zero, 0
    sw $t0, music_index
endResetIndex:

    # Play note if timer exceeds delay
    mul $t0, $t0, 4
    la $t1, delays
    add $t1, $t1, $t0
    lw $t2, ($t1)
    lw $t3, music_timer
    bge $t3, $t2, playNote
    ble $t0, 0, playNote
    addi $t3, $t3, 5
    sw $t3, music_timer
    j endPlayNote
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
endPlayNote:

    ######################## SLEEP AND LOOP ###########################
    li $v0, 32
    li $a0, 5
    syscall

    j gameLoop
endGameLoop:

    li $v0, 10
    syscall

##############################################################################
# Initialization Functions
##############################################################################

initializeDisplay:
    # Save the return address ($ra) onto the stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal setuplist
    jal renderlist

    # Restore the return address ($ra) from the stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

setuplist:
    # Load list base address
    la $t0, list

    # Load row and column counts
    lw $t1, row_count
    lw $t2, column_count
    addi $t7, $t1, -1
    addi $t8, $t2, -1

    li $t3, 0  # Row counter
    
outerLoop:
    bge $t3, $t1, exitOuterLoop
    li $t4, 0  # Column counter
    
innerLoop:
    bge $t4, $t2, exitInnerLoop
    
    # Set boundary colors
    beq $t3, $zero, setGrey
    beq $t3, $t7, setGrey
    beq $t4, $zero, setGrey
    beq $t4, $t8, setGrey
    
    # Alternate black and dark grey
    add $t5, $t3, $t4
    andi $t5, $t5, 1
    beq $t5, 0, setBlack
    beq $t5, 1, setDarkGrey

setGrey:
    lw $t6, grey
    j storeValue
setBlack:
    lw $t6, black
    j storeValue
setDarkGrey:
    lw $t6, dark_grey
    j storeValue

storeValue:
    sw $t6, 0($t0)
    addi $t0, $t0, 4
    addi $t4, $t4, 1
    j innerLoop
exitInnerLoop:
    addi $t3, $t3, 1
    j outerLoop
exitOuterLoop:
    jr $ra

renderlist:
    la $s0, list
    lw $s1, display_base

    lw $t1, row_count
    lw $t2, column_count

    li $t3, 0
    li $t4, 0
    
outerPrintLoop:
    bge $t3, $t1, exitOuterPrintLoop
    
innerPrintLoop:
    bge $t4, $t2, exitInnerPrintLoop
    
    mul $t5, $t3, $t2
    add $t5, $t5, $t4
    
    sll $t6, $t5, 2
    add $t6, $s0, $t6
    lw $t7, ($t6)
    
    sw $t7, 0($s1)
    addi $s1, $s1, 4
    addi $t4, $t4, 1
    j innerPrintLoop
exitInnerPrintLoop:
    li $t4, 0
    addi $t3, $t3, 1
    j outerPrintLoop
exitOuterPrintLoop:
    jr $ra

clearFullLines:
    la $s0, list
    addi $t0, $zero, 1
    lw $t4, dark_grey

outerClearLoop:
    beq $t0, 21, endOuterClearLoop
    addi $t1, $zero, 1
innerClearLoop:
    mul $t2, $t0, 48
    mul $t3, $t1, 4
    add $t5, $t2, $t3
    add $t5, $t5, $s0
    lw $t5, ($t5)
    
    beq $t5, $zero, noColorDetected
    beq $t5, $t4, noColorDetected
    j colorDetected
noColorDetected:
    j endInnerClearLoop
colorDetected:
    beq $t1, 11, endDetection
    addi $t1, $t1, 1
    j innerClearLoop
endDetection:
    addi $t1, $zero, 1
    add $t6, $zero, $t0
shiftLinesDown:
    addi $t7, $zero, 1
    beq $t6, 0, endShiftLines
    beq $t6, 1, loadEmptyLine
    j loadAboveLine
loadEmptyLine:
    beq $t7, 11, endLoadLine
    add $t8, $zero, $t6
    mul $t8, $t8, 12
    mul $t8, $t8, 4
    add $t9, $zero, $t7
    mul $t9, $t9, 4
    add $s1, $t8, $t9
    add $s1, $s1, $s0
    sw $zero, 0($s1)
    addi $t7, $t7, 1
    j loadEmptyLine
loadAboveLine:
    beq $t7, 11, endLoadLine
    add $t8, $zero, $t6
    mul $t8, $t8, 12
    mul $t8, $t8, 4
    add $t9, $zero, $t7
    mul $t9, $t9, 4
    add $s1, $t8, $t9
    add $s1, $s1, $s0
    addi $s2, $s1, -48
    lw $t9, ($s2)
    sw $t9, ($s1)
    addi $t7, $t7, 1
    j loadAboveLine
endLoadLine:
    addi $t6, $t6, -1
    j shiftLinesDown
endShiftLines:
    li $v0, 31
    li $a0, 80
    li $a1, 5
    li $a2, 80
    li $a3, 127
    syscall
endInnerClearLoop:
    addi $t0, $t0, 1
    j outerClearLoop
endOuterClearLoop:
    jr $ra

refreshBackground:
    la $s0, list
    addi $t0, $zero, 0
    
refreshOuterLoop:
    beq $t0, 22, endRefreshOuterLoop
    addi $t1, $zero, 0
refreshInnerLoop:
    beq $t1, 12, endRefreshInnerLoop
    addi $t1, $t1, 1
    
    add $t2, $t0, $t1
    andi $t2, $t2, 1
    beq $t2, 0, setBlackCell
    beq $t2, 1, setDarkGreyCell
setBlackCell:
    lw $t3, black
    j storeCellValue
setDarkGreyCell:
    lw $t3, dark_grey
storeCellValue:
    add $t4, $zero, $t0
    mul $t4, $t4, 48
    add $t5, $zero, $t1
    mul $t5, $t5, 4
    add $t6, $t4, $t5
    add $t6, $t6, $s0
    lw $t7, ($t6)
    lw $t8, dark_grey
    beq $t7, $zero, replaceCell
    beq $t7, $t8, replaceCell
    j notBackgroundCell
replaceCell:
    sw $t3, 0($t6)
notBackgroundCell:
    j refreshInnerLoop
endRefreshInnerLoop:
    addi $t0, $t0, 1
    j refreshOuterLoop
endRefreshOuterLoop:
    jr $ra
