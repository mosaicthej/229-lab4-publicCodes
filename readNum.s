# this program read a number 
# inputed with keyboard, using MMIO, end with `\r`
# and save it to register $v0

# 1. read the keyboard
# 2. convert from ascii to num value (-48)
# 3. save the single digit value to a var
# 4. keep waiting for new digit
# 5. as new digit arrive, times the var by 10 (move up)
# 6. add the new digit to the var
# 7. keeps doing until received '\r'

.data
num:    .word 0
endText: .asciiz "returned"

.text
main:
forever:
    
    lui     $t0, 0xffff
readloop:
    lw	    $t1, 0($t0)	        # keyboard control
    andi	$t1, $t1, 0x0001    
    beq	    $t1, $0, readloop   # wait when 'ready'
    lw	    $v0, 4($t0)	        # put keyboard data to $v0
                                # 0xffff 0004
    j       checkr              # check if or line feed
doneRead:
    # before proceeding, add the value to the var num
    lw      $t0, num
    li      $t1, 10
    mult    $t0, $t1            # multiply existing value by 10
    mflo    $t0
    addi    $v0, $v0, -48       # convert from ascii to num val
    add     $t0, $v0, $t0        # add the new digit
    sw      $t0, num
    addi    $v0, $v0, 48        # get the ascii back


move    $a0, $v0            # save the keyboard data to $a0
# output of character in $a0_________________
	lui	$t0,0xffff	#ffff0000
writeloop:
	lw	    $t1,8($t0)	        # display control
	andi	$t1,$t1, 0x0001
	beq	    $t1,$0, writeloop   # wait when 'ready'
	sw	    $a0,12($t0)	        # put data to display location 
                                # 0xffff 000C
    j       forever             # forever loop
checkr:
    li      $v1, 10
    bne     $v0, $v1, checkq
exitR:
    # when end by `\r`
    la      $a0, endText
    li      $v0, 4
    syscall
    j       exit


checkq:
    li      $v1, 0x71       # "q" at 0x71
    bne     $v0, $v1, doneRead
                            # if not 'q', proceeds to write

exit:
    lw      $v1, num
    li		$v0,10
    syscall
#    jal     $ra    # if is 'q', finish and quit
