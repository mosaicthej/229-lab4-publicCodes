.data
char:
    .byte   0


.text

main:
    # enable interrupts
    lw      $t0 0xffff0000 # Enable Keyboard interrupt
    ori     $t0 $t0 0x02
    sw      $t0 0xffff0000  
forever:
# character input into $v0 ______________________
	lui	    $t0, 0xffff	#ffff0000
readloop:
	lw	    $t1, 0($t0)	        # keyboard control
	andi	$t1, $t1, 0x0001    
	beq	    $t1, $0, readloop   # wait when 'ready'
	lw	    $v0, 4($t0)	        # put keyboard data to $v0
                                # 0xffff 0004
	sb		$v0, char			# store word to char
    
    j       checkq              # check if quit
doneRead:
    lbu    $a0, char            # save the keyboard data to $a0
# output of character in $a0_________________
	lui	$t0,0xffff	#ffff0000
writeDouble:
    # using $a1 as counter, jump to main when counter reach to 2.
    li      $a2, 2
    li      $a1, 0  
    
writeloop:
	lw	    $t1,8($t0)	        # display control
	andi	$t1,$t1, 0x0001
	beq	    $t1,$0, writeloop   # wait when 'ready'
	sw	    $a0,12($t0)	        # put data to display location 
                                # 0xffff 000C
    addi    $a1, $a1, 1         # increase counter
    beq     $a1, $a2, forever      # get new key when printed 2 times
    j       writeloop           # if not yet 2 times, print again

checkq:
    li      $v1, 0x71       # "q" at 0x71
    bne     $v0, $v1, doneRead
                            # if not 'q', proceeds to write
    jal     $ra    # if is 'q', finish and quit
