# In SPIM, a timer is simulated with two more coprocessor registers: 
# Count (register 9), 
# whose value is continuously incremented by the hardware, 
# and Compare (register 11), 
# whose value can be set. 

# When Count and Compare are equal, 
# an interrupt is raised, at Cause register bit 15.

# which, 15th bit of reg $13 turns to 1
.data
time:   .word 0
timeChars:  .byte 0, 0, 0
# timeChars are "10's" then "1's" then zero end

timerText1:
        .asciiz "timer triggered, time is "
timerText2:.asciiz " seconds\n"


.kdata
rAt:    .space 4
rS0:    .space 4
rS1:    .space 4
rS2:    .space 4
rRa:    .space 4


.ktext  0x80000180
# location of exception
.set    noat
move    $k0, $at
.set    at
la      $k1, rAt
sw      $k0, 0($k1)
sw      $s0, 4($k1)
sw      $s1, 8($k1)
sw      $s2, 12($k1)
sw      $ra, 16($k1)

mfc0    $s0, $13    # getting the cause reg
andi    $s1, $s0, 0x7C  # extracting bit [6:2], which is excption code
beq     $s1, $zero, hwInt   # code zero, to hardware interrupt

# if not hw, then it is program exception
# skip the bad instructions (by altering epc)
mfc0    $s0, $14    # getting EPC
addiu   $s0, $s0, 4 # adding 4 to EPC (move to next instruction)
mtc0    $s0, $14    # save at EPC

j       exceptionEnd # end of exception

hwInt:
# dealing hardware level interruptions
mfc0    $s0, $13    # get the cause reg
andi    $s0, $s0, 0x8000    # get the 15th bit (timer)
beqz    $s0, timerEnd       # timer not triggered
# if timer is triggered:
mtc0    $zero, $9   # reset timer count to 0

# using MMIO to update timer text
la      $s0, time   
lw      $s1, 0($s0)     # get the time value to s0
addi    $s1, $s1, 1     # increase $s1 by 1
sw      $s1, 0($s0)     # update the `time` var

la      $s0, timerText1
jal     dispLoop    # display text 1

# display seconds
dispSec:
# first use div and mod to get 1's and 10's of seconds
# then display each number
# using div and mfhi, mflo, 
# where hi has reminder (1's), lo has quotient (10's)
# adding 48 to a number will convert to its ascii val
la      $s0, time
lw      $s1, 0($s0) # $s1 has the time's integer value
li      $s2, 10
div     $s1, $s2    # separate the 1's and 10's
mfhi    $s1     # $s1 has the reminder (1's)
mflo    $s2     # $s2 has the quotient (10's)
la      $s0, timeChars
addi    $s2, $s2, 48
sb      $s2, 0($s0) # save 10's char
addi    $s1, $s1, 48
sb      $s1, 1($s0) # then 1's char

# now 10's and 1's digits are saved in timeChars, display now
jal     dispLoop
# now the seconds are being displayed
# now display the ending text
la      $s0, timerText2
jal     dispLoop
# timer's display done
j       timerEnd


dispLoop:
# we assume that address of chars starting from $s0,
# and the text is null-ended
    nextChar:
    lb  $s1, 0($s0)     # s1 now holds the next char
    beqz    $s1, dispLoopDone    
    pollpre:
        lb  $s2, 0xffff0008    # wait for output is enabled
        andi $s2, $s2, 0x01    # check bit 0
        beqz $s2, pollpre
    sw  $s1, 0xffff000C         # save the char to the output
    addi $s0, $s0, 1
    j   nextChar
    dispLoopDone:
    jr  $ra    

timerEnd:
exceptionEnd:
    # finished dealing exception, return to old procedure
    # think $k1 as $SP
    lw      $ra, 16($k1)
    lw      $s2, 12($k1)
    lw      $s1, 8($k1)
    lw      $s0, 4($k1)
    lw      $k0, 0($k1)
    .set    noat
    move    $at, $k0
    .set    at

    mtc0    $zero, $13  # clear the cause
    mfc0    $k0, $12    # get the Status
    ori     $k0, $k0, 0x01  # make sure bit 0 is 1
                            # (enable interrupts)
    mtc0    $k0, $12
    eret

.text
.globl __start
__start:
    mfc0    $t0, $12
    ori     $t0, 0x01
    mtc0    $t0, $12
    # enable interrupts

    li      $t0, 100
    mtc0    $t0, $11    # compare = 10 (x100ms)
    mtc0    $zero, $9

forever:
    j       forever

li  $v0, 10
syscall
