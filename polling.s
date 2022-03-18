.data
str:
.ascii "Hi. This is a text text text text"
.asciiz "\010\010\010\010\010text2 text2 ends"
.text

main: 
    la $t0 str
    loop: 
        lb $t1 0($t0)
        beqz $t1 done
        poll: 
            lb $t2 0xffff0008
            andi $t2 $t2 0x01
            beqz $t2 poll
        sw $t1 0xffff000C
        addi $t0 $t0 1
        j loop
    done:
        jr $ra

