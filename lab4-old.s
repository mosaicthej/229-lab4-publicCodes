.kdata:

rS1:
    .word 0
rS2:
    .word 0

.data:
minutes:
    .word 0
seconds:
    .word 0
change:
    .word 1
buffer:
    .asciiz     "\010\010\010\010\01000:00"
   

.text:
.globl __start
__start:
    
    # set bit 15, 11, 4 and 0 for interrupts to be enabled
    li      $t0, 0x00008811        #Enable interrupts
    mtc0    $t0, $12    

    lw      $t0, 0xffff0000     #Enable keyboard
    ori     $t0, $t0, 0x02     
    sw      $t0, 0xffff0000     
    
    la      $t2, buffer         #load addr to 00:00
    addiu   $t2, $t2, 5
    mtc0    $0, $9              #Set the timer to 0
    li      $t0, 100            #Every 1s
    mtc0    $t0, $11            

    jal     forever


    li $v0 10
    syscall

forever:
    lw      $t0, change     #t0 to change flag
    beq     $t0, 0, forever # if flag 0, wait until it turns to 1
    # when change flags
    sw      $zero, change   # clear flag
    la      $t7, buffer     # change buffer
    li      $s1, 10
    lw      $t0, minutes    # 

.ktext:     0x80000180
.set    
    noat
    move    $k1, $at
.set    
    at 
    sw      $v0, rS1
    sw      $a0, rS2
    mfc0    $k0, $13
    srl     $a0, $k0, 2
    andi    $a0, $a0, 0x1f
    andi    $a0, $k0, 0x800     #Check for keyboard interrupt
    beq     $a0, $zero, nkeyboard
    lw      $a0, 0xffff0000     #Check keyboard status
    andi    $a0, $a0, 0x01      #Extract exception code (bit 1)
    beq     $a0, $zero, nkeyboard

    # Codes to handle keyboard
keyboard:
    lw      $a0, 0xffff0004     #Get the key pressed
    li      $v0, 0x72           # 'r' at 0x72
    bne     $a0, $v0, checkq    # if it is R, reset, if not, check if it is 'q'
    # reset
    mtc0    $0, $9
    sw      $0, minutes
    sw      $0, seconds
    j       nsix

    checkq:
    li      $v0, 0x71       # "q" at 0x71
    bne     $a0, $v0, ret   # if not 'q', don't do anything
                            # if is 'q', proceed to quit
    li      $v0, 10         # exit using syscall-10
    syscall


    andi    $a0, $k0, 0x8000
    beq     $a0, $zero, ret
    
    # Codes to handle timer
timer: 

    
