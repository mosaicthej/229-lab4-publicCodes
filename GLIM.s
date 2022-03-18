##############################################################################
#					START OF GLIM
##############################################################################
#Copyright 2017 Austin Crapo
#
#Permission is hereby granted, free of charge, to any person obtaining a copy 
#of this software and associated documentation files (the "Software"), to deal 
#in the Software without restriction, including without limitation the rights 
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
#copies of the Software, and to permit persons to whom the Software is 
#furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
# IN THE SOFTWARE.
######################
# Author: Austin Crapo
# Date: June 2017
# Version: 2017.8.24
#
#
# Does not support being run in a tab; Requires a separate window.
#
# This is a graphics library, supporting drawing pixels, 
# and some basic primitives
#
# @TODO suggestion was made to make a more general version of the updateCursor 
# function from Game of Life into the library
#
# @TODO more primatives?
#
# High Level documentation is provided in the index.html file.
# Per-method documentation is provided in the block comment 
# following each function definition
######################
.data
.align 2
#GLOBALS

# These tell GLIM how big the terminal is currently.
# The setter for these values is setDisplaySize.
# They are used to prevent off screen printing in the positive direction, the negative direction does not require this check as far as I know.
# Any negative value indicates that these variables have not been set.
TERM_ROWS:
	.word -1
TERM_COLS:
	.word -1


.data
.align 2
clearScreenCmd:
	.byte 0x1b, 0x5b, 0x32, 0x4a, 0x00
.text
clearScreen:
	########################################################################
	# Uses xfce4-terminal escape sequence to clear the screen
	#
	# Register Usage
	# Overwrites $v0 and $a0 during operation
	########################################################################
	li	$v0, 4
	la	$a0, clearScreenCmd
	syscall
	
	jr	$ra

.data
setCstring:
	.byte 0x1b, 0x5b, 0x30, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x48, 0x00
.text
setCursor:
	########################################################################
	#Moves the cursor to the specified location on the screen. Max location
	# is 3 digits for row number, and 3 digits for column number. (row, col)
	#
	# $a0 = row number to move to
	# $a1 = col number to move to
	#
	# Register Usage
	# Overwrites $v0 and $a0 during operation
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		# Adjust the stack to save $fp
	sw	$fp, 0($sp)		# Save $fp
	add	$fp, $zero, $sp		# $fp <= $sp
	addi	$sp, $sp, -12		# Adjust stack to save variables
	sw	$ra, -4($fp)		# Save $ra
	#skip $s0, this could be cleaned up
	sw	$s1, -8($fp)		
	sw	$s2, -12($fp)		
	
	#The control sequence we need is "\x1b[$a1;$a2H" where "\x1b"
	#is xfce4-terminal's method of passing the hex value for the ESC key.
	#This moves the cursor to the position, where we can then print.
	
	#The command is preset in memory, with triple zeros as placeholders
	#for the char coords. We translate the args to decimal chars and edit
	# the command string, then print
	
	move	$s1, $a0
	move	$s2, $a1
	
	# NOTE: we add 1 to each coordinate because we want (0,0) to be the top
	# left corner of the screen, but most terminals define (1,1) as top left
	#ROW
	addi	$a0, $s1, 1
	la	$t2, setCstring
	jal	intToChar
	lb	$t0, 0($v0)
	sb	$t0, 5($t2)
	lb	$t0, 1($v0)
	sb	$t0, 4($t2)
	lb	$t0, 2($v0)
	sb	$t0, 3($t2)
	lb	$t0, 3($v0)
	sb	$t0, 2($t2)
	
	#COL
	addi	$a0, $s2, 1
	la	$t2, setCstring
	jal	intToChar
	lb	$t0, 0($v0)
	sb	$t0, 10($t2)
	lb	$t0, 1($v0)
	sb	$t0, 9($t2)
	lb	$t0, 2($v0)
	sb	$t0, 8($t2)
	lb	$t0, 3($v0)
	sb	$t0, 7($t2)

	#move the cursor
	li	$v0, 4
	la	$a0, setCstring
	syscall
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s1, -8($fp)
	lw	$s2, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

.text
printString:
	########################################################################
	# Prints the specified null-terminated string started at the
	# specified location to the string and then continuing until
	# the end of the string, according to the printing preferences of your
	# terminal (standard terminals print left to right, top to bottom).
	# Is not screen aware, passing paramaters that would print a character
	# off screen have undefined effects on your terminal window. For most
	# terminals the cursor will wrap around to the next row and continue
	# printing. If you have hit the bottom of the terminal window,
	# the xfce4-terminal window default behavior is to scroll the window 
	# down. This can offset your screen without you knowing and is 
	# dangerous since it is undetectable. The most likely useage of this
	# function is to print characters. The reason that it is a string it
	# prints is to support the printing of escape character sequences
	# around the character so that fancy effects are supported. Some other
	# terminals may treat the boundaries of the terminal window different,
	# for example some may not wrap or scroll. It is up to the user to
	# test their terminal window for its default behaviour.
	# Is built for xfce4-terminal.
	# Position (0, 0) is defined as the top left of the terminal.
	#
	# Uses TERM_ROW and TERM_COL to determine if the target tile
	# is outside of the boundary of the terminal screen, in which
	# case it does nothing.
	#
	# $a0 = address of string to print
	# $a1 = integer value 0-999, row to print to (y position)
	# $a2 = integer value 0-999, col to print to (x position)
	#
	# Register Usage
	# $t0 - $t3, $t7-$t9 = temp storage of bytes and values
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		# Adjust the stack to save $fp
	sw	$fp, 0($sp)		# Save $fp
	add	$fp, $zero, $sp		# $fp <= $sp
	addi	$sp, $sp, -8		# Adjust stack to save variables
	sw	$ra, -4($fp)		# Save $ra
	sw	$s0, -8($fp)		# Save $s0
	
	la	$t0, TERM_ROWS      	#check if past boundary
	lw	$t0, 0($t0)
	bge	$a1, $t0, pSend     	#if TERM_ROWS <= print row
	
	la	$t1, TERM_COLS
	lw	$t1, 0($t1)
	bge	$a2, $t1, pSend     	#or if TERM_COLS <= print col

	slt $t2, $a1, $zero     	#or if print row < 0
	slt $t3, $a2, $zero     	#or if print col < 0
	
	or	$t2, $t2, $t3
	bne	$t2, $zero, pSend	#then do nothing
	
	#else	
	move	$s0, $a0
	
	move	$a0, $a1
	move	$a1, $a2
	jal	setCursor
	
	#print the char
	li	$v0, 4
	move	$a0, $s0
	syscall
	
	pSend:
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	addi	$sp, $sp, 8
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

batchPrint:
	########################################################################
	# A batch is a list of print jobs. The print jobs are in the format
	# below, and will be printed from start to finish. This function does
	# some basic optimization of color printing (eg. color changing codes
	# are not printed if they do not need to be), but if the list constantly
	# changes color and is not sorted by color, you may notice flickering.
	#
	# List format:
	# Each element contains the following words in order together
	# half words unsigned:[row] [col]
	# bytes unsigned:     [printing code] [foreground color] [background color] 
	#			    [empty] 
	# word: [address of string to print here]
	# total = 3 words
	#
	# The batch must be ended with the halfword sentinel: 0xFFFF
	#
	# Valid Printing codes:
	# 0 = skip printing
	# 1 = standard print, default terminal settings
	# 2 = print using foreground color
	# 3 = print using background color
	# 4 = print using all colors
	# 
	# xfce4-terminal supports the 256 color lookup table assignment, 
	# see the index for a list of color codes.
	#
	# The payload of each job in the list is the address of a string. 
	# Escape sequences for prettier or bolded printing supported by your
	# terminal can be included in the strings. However, including such 
	# escape sequences can effect not just this print, but also future 
	# prints for other GLIM methods.
	#
	# $a0 = address of batch list to print
	#
	# Register Usage
	# $s0 = scanner for the list
	# $s1 = store row info
	# $s2 = store column info
	# $s3 = store print code info
	# $s6 = temporary color info storage accross calls
	# $s7 = temporary color info storage accross calls
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -28		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	sw	$s6, -24($fp)
	sw	$s7, -28($fp)
	
	#store the last known colors, to avoid un-needed printing
	li	$s6, -1		#lastFG = -1
	li	$s7, -1		#lastBG = -1
	
	
	move	$s0, $a0		#scanner = list
	#for item in list
	bPscan:
		#extract row and col to vars
		lhu	$s1, 0($s0)		#row
		lhu	$s2, 2($s0)		#col
		
		#if row is 0xFFFF: break
		li	$t0, 0xFFFF
		beq	$s1, $t0, bPsend
		
		#extract printing code
		lbu	$s3, 4($s0)		#print code
		
		#skip if printing code is 0
		beq	$s3, $zero, bPscont
		
		#print to match printing code if needed
		#if standard print, make sure to have clear color
		li	$t0, 1		#if pcode != 1
		bne	$s3, $t0, bPscCend
		bPsclearColor:
			li	$t0, -1	#if lastFG != -1 
			bne	$s6, $t0, bPscCreset
			bne	$s7, $t0, bPscCreset	#OR lastBG != -1:
			j	bPscCend
			bPscCreset:
				jal	restoreSettings
				li	$s6, -1
				li	$s7, -1
		bPscCend:
		
		#change foreground color if needed
		li	$t0, 2		#if pcode == 2 or pcode == 4
		beq	$s3, $t0, bPFGColor
		li	$t0, 4
		beq	$s3, $t0, bPFGColor
		j	bPFCend
		bPFGColor:
			lbu	$t0, 5($s0)
			beq	$t0, $s6, bPFCend	#if color != lastFG
				move	$s6, $t0	#store to lastFG
				move	$a0, $t0	#set as FG color
				li	$a1, 1
				jal	setColor
		bPFCend:
		
		#change background color if needed
		li	$t0, 3		#if pcode == 2 or pcode == 4
		beq	$s3, $t0, bPBGColor
		li	$t0, 4
		beq	$s3, $t0, bPBGColor
		j	bPBCend
		bPBGColor:
			lbu	$t0, 6($s0)
			beq	$t0, $s7, bPBCend	#if color != lastBG
				move	$s7, $t0	#store to lastBG
				move	$a0, $t0	#set as BG color
				li	$a1, 0
				jal	setColor
		bPBCend:
		
		
		#then print string to (row, col)
		lw	$a0, 8($s0)
		move	$a1, $s1
		move	$a2, $s2
		jal	printString
		
		bPscont:
		addi	$s0, $s0, 12
		j	bPscan
	bPsend:

	
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	lw	$s2, -16($fp)
	lw	$s3, -20($fp)
	lw	$s6, -24($fp)
	lw	$s7, -28($fp)
	addi	$sp, $sp, 28
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	
	jr	$ra
	
.data
.align 2
intToCharSpace:
	.space	4	#storing 4 bytes, potentially up to 9999
.text
intToChar:
	########################################################################
	# Given an int x where 0 <= x <= 9999, converts the integer into 3 bytes,
	# which are the character representation of the int. If the integer
	# requires larger than 3 chars to represent, only the 3 least 
	# significant digits will be converted.
	#
	# $a0 = integer to convert
	#
	# Return Values:
	# $v0 = address of the bytes, in the following order, 1's, 10's, 100's, 1000's
	#
	# Register Usage
	# $t0-$t9 = temporary value storage
	########################################################################
	li	$t0, 0x30	#'0' in ascii, we add according to the number
	#separate the three digits of the passed in number
	#1's = x%10
	#10's = x%100 - x%10
	#100's = x - x$100
	la	$v0, intToCharSpace
	
	#ones
	li	$t1, 10		
	div	$a0, $t1
	mfhi	$t7			#x%10
	add	$t1, $t0, $t7	#byte = 0x30 + x%10
	sb	$t1, 0($v0)
	
	#tens
	li	$t1, 100		
	div	$a0, $t1
	mfhi	$t8			#x%100
	sub	$t1, $t8, $t7	#byte = 0x30 + (x%100 - x%10)/10
	li	$t3, 10
	div	$t1, $t3
	mflo	$t1
	add	$t1, $t0, $t1	
	sb	$t1, 1($v0)
	
	#100s
	li	$t1, 1000		
	div	$a0, $t1
	mfhi	$t9			#x%1000
	sub	$t1, $t9, $t8	#byte = 0x30 + (x%1000 - x%100)/100
	li	$t3, 100
	div	$t1, $t3
	mflo	$t1
	add	$t1, $t0, $t1	
	sb	$t1, 2($v0)
	
	#1000s
	li	$t1, 10000		
	div	$a0, $t1
	mfhi	$t6			#x%10000
	sub	$t1, $t6, $t9	#byte = 0x30 + (x%10000 - x%1000)/1000
	li	$t3, 1000
	div	$t1, $t3
	mflo	$t1
	add	$t1, $t0, $t1	
	sb	$t1, 3($v0)
	
	jr	$ra
	
.data
.align 2
setFGorBG:
	.byte 0x1b, 0x5b, 0x34, 0x38, 0x3b, 0x35, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x6d, 0x00
.text
setColor:
	########################################################################
	# Prints the escape sequence that sets the color of the text to the
	# color specified.
	# 
	# xfce4-terminal supports the 256 color lookup table assignment, 
	# see the index for a list of color codes.
	#
	#
	# $a0 = color code (see index)
	# $a1 = 0 if setting background, 1 if setting foreground
	#
	# Register Usage
	# $s0 = temporary arguement storage accross calls
	# $s1 = temporary arguement storage accross calls
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -12		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)		
	
	move	$s0, $a0
	move	$s1, $a1
	
	jal	intToChar		#get the digits of the color code to print
	
	move	$a0, $s0
	move	$a1, $s1
	
	la	$t0, setFGorBG
	lb	$t1, 0($v0)		#alter the string to print, max 3 digits ignore 1000's
	sb	$t1, 10($t0)
	lb	$t1, 1($v0)
	sb	$t1, 9($t0)
	lb	$t1, 2($v0)
	sb	$t1, 8($t0)
	
	beq	$a1, $zero, sCsetBG	#set the code to print FG or BG
		#setting FG
		li	$t1, 0x33
		j	sCset
	sCsetBG:
		li	$t1, 0x34
	sCset:
		sb	$t1, 2($t0)
	
	li	$v0, 4
	move	$a0, $t0
	syscall
		
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

.data
.align 2
rSstring:
	.byte 0x1b, 0x5b, 0x30, 0x6d, 0x00
.text
restoreSettings:
	########################################################################
	# Prints the escape sequence that restores all default color settings to
	# the terminal
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, rSstring
	li	$v0, 4
	syscall
	
	jr	$ra

.text
startGLIM:
	########################################################################
	# Sets up the display in order to provide
	# a stable environment. Call endGLIM when program is finished to return
	# to as many defaults and stable settings as possible.
	# Unfortunately screen size changes are not code-reversible, so endGLIM
	# will only return the screen to the hardcoded value of 24x80.
	#
	#
	# $a0 = number of rows to set the screen to
	# $a1 = number of cols to set the screen to
	#
	# Register Usage
	# NA
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -4		
	sw	$ra, -4($fp)
	
	jal	setDisplaySize
	jal	restoreSettings
	jal	clearScreen
	
	jal	hideCursor
	
	#Stack Restore
	lw	$ra, -4($fp)
	addi	$sp, $sp, 4
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	

.text
endGLIM:
	########################################################################
	# Reverts to default as many settings as it can, meant to end a program
	# that was started with startGLIM. The default terminal window in
	# xfce4-terminal is 24x80, so this is the assumed default we want to
	# return to.
	#
	# Register Usage
	# NA
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -4		
	sw	$ra, -4($fp)
	
	li	$a0, 24
	li	$a1, 80
	jal	setDisplaySize
	jal	restoreSettings
	
	jal	clearScreen
	
	jal	showCursor
	li	$a0, 0
	li	$a1, 0
	jal	setCursor
	
	#Stack Restore
	lw	$ra, -4($fp)
	addi	$sp, $sp, 4
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	
.data
.align 2
hCstring:
	.byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x6c, 0x00
.text
hideCursor:
	########################################################################
	# Prints the escape sequence that hides the cursor
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, hCstring
	li	$v0, 4
	syscall
	
	jr	$ra

.data
.align 2
sCstring:
	.byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x68, 0x00
.text
showCursor:
	########################################################################
	#Prints the escape sequence that restores the cursor visibility
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, sCstring
	li	$v0, 4
	syscall
	
	jr	$ra

.data
.align 2
sDSstring:
	.byte 0x1b, 0x5b, 0x38, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x74 0x00
.text
setDisplaySize:
	########################################################################
	# Prints the escape sequence that changes the size of the display to 
	# match the parameters passed. The number of rows and cols are 
	# ints x and y s.t.:
	# 0<=x,y<=999
	#
	# $a0 = number of rows
	# $a1 = number of columns
	#
	# Register Usage
	# $s0 = temporary $a0 storage
	# $s1 = temporary $a1 storage
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -12		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)
	
	slt	$t0, $a0, $zero		#if either argument is negative, do nothing
	slt	$t1, $a1, $zero
	or	$t0, $t0, $t1
	bne	$t0, $zero, sDSend
	
					#else
	
	move	$s0, $a0
	move	$s1, $a1
	
	la	$t0, TERM_ROWS		#set the TERM globals
	sw	$a0, 0($t0)
	la	$t0, TERM_COLS
	sw	$a1, 0($t0)
	
	#rows
	jal	intToChar		#get the digits of the params to print
	
	la	$t0, sDSstring
	lb	$t1, 0($v0)		#alter the string to print
	sb	$t1, 7($t0)
	lb	$t1, 1($v0)
	sb	$t1, 6($t0)
	lb	$t1, 2($v0)
	sb	$t1, 5($t0)
	lb	$t1, 3($v0)
	sb	$t1, 4($t0)
	
	#cols
	move	$a0, $s1
	jal	intToChar		#get the digits of the params to print
	
	la	$t0, sDSstring
	lb	$t1, 0($v0)		#alter the string to print
	sb	$t1, 12($t0)
	lb	$t1, 1($v0)
	sb	$t1, 11($t0)
	lb	$t1, 2($v0)
	sb	$t1, 10($t0)
	lb	$t1, 3($v0)
	sb	$t1, 9($t0)
	
	li	$v0, 4
	move	$a0, $t0
	syscall
	
	sDSend:
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

.data
cDchar:
	.asciiz "█"
.text
colorDemo:
	########################################################################
	# Attempts to print the 16-256 color gamut of your terminal.
	# Requires that the terminal size be at least 30 rows and 6 cols big.
	# Currently skips the first 15 colors because it's prettier :P
	#
	# Register Usage
	# $s0 = Holds the initial offset - we start at color 16 because the first 16 (0-15) don't align very well in this demo. Change it to 0 if you want to FULL color gamut
	# $s1 = Holds the current column being printed to.
	# $s2 = Holds the current row being printed to.
	########################################################################
	jal	clearScreen
	#print the color space, skip the first 15 because prettier
	li	$s0, 16	#start at 16 so that we dont get offset weirdly by the first 15 colors
	li	$s1, 1
	li	$s2, 1
	mLoop:		#while True
		move	$a0, $s0
		li	$a1, 1
		jal	setColor
		la	$a0, char
		move	$a1, $s2
		move	$a2, $s1
		jal	printString
		addi	$s1, $s1, 1
		li	$t0, 7
		bne	$s1, $t0, mLcont
			li	$s1, 1
			addi	$s2, $s2, 1
		mLcont:
		addi	$s0, $s0, 1
		li	$t0, 256
		beq	$s0, $t0, mLend
		j	mLoop
	mLend:
	jr	$ra
	
.data
pClist:
	.align 2
	.space 100	#9*3*4 words, only prints 8 pixels at a time
pCchar:
	.asciiz " " #character to print with
.text
printCircle:
	############################
	# Prints a circle onto the screen using the midpoint circle algorithm
	# and the character pCchar.
	#
	# $a0 = row to print at 
	# $a1 = col to print at
	# $a2 = radius of the circle to print
	# $a3 = byte code [printing code][fg color][bg color][empty] determining
	#		how to print the circle pixels, compatible with printList
	############################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -36		
	sw    $ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	sw	$s4, -24($fp)
	sw	$s5, -28($fp)
	sw	$s6, -32($fp)
	sw	$s7, -36($fp)
	
	move	$s0, $a2	#row = radius
	li	$s1, 0	#col = 0
	li	$s2, 0	#err = 0
	la	$s3, pCchar
	move	$s4, $a0	#store the args
	move	$s5, $a1
	move	$s6, $a3
	
	pCloop:	#while (col <= row)
	addi	$t1, $s1, -1
	slt	$t0, $t1, $s0
	beq	$t0, $zero, pClend
		#draw a pixel to each octant of the screen
		la	$t0, pClist
		add	$t1, $s4, $s0
		add	$t2, $s5, $s1
		sh	$t1, 0($t0)		#pixel location
		sh	$t2, 2($t0)
		sw	$s6, 4($t0)		#pixel printing code
		sw	$s3, 8($t0)
		addi	$t0, $t0, 12
		add	$t1, $s4, $s1
		add	$t2, $s5, $s0
		sh	$t1, 0($t0)
		sh	$t2, 2($t0)
		sw	$s6, 4($t0)
		sw	$s3, 8($t0)
		addi	$t0, $t0, 12
		sub	$t1, $s4, $s1
		add	$t2, $s5, $s0
		sh	$t1, 0($t0)
		sh	$t2, 2($t0)
		sw	$s6, 4($t0)
		sw	$s3, 8($t0)
		addi	$t0, $t0, 12
		sub	$t1, $s4, $s0
		add	$t2, $s5, $s1
		sh	$t1, 0($t0)
		sh	$t2, 2($t0)
		sw	$s6, 4($t0)
		sw	$s3, 8($t0)
		addi	$t0, $t0, 12
		sub	$t1, $s4, $s0
		sub	$t2, $s5, $s1
		sh	$t1, 0($t0)
		sh	$t2, 2($t0)
		sw	$s6, 4($t0)
		sw	$s3, 8($t0)
		addi	$t0, $t0, 12
		sub	$t1, $s4, $s1
		sub	$t2, $s5, $s0
		sh	$t1, 0($t0)
		sh	$t2, 2($t0)
		sw	$s6, 4($t0)
		sw	$s3, 8($t0)
		addi	$t0, $t0, 12
		add	$t1, $s4, $s1
		sub	$t2, $s5, $s0
		sh	$t1, 0($t0)
		sh	$t2, 2($t0)
		sw	$s6, 4($t0)
		sw	$s3, 8($t0)
		addi	$t0, $t0, 12
		add	$t1, $s4, $s0
		sub	$t2, $s5, $s1
		sh	$t1, 0($t0)
		sh	$t2, 2($t0)
		sw	$s6, 4($t0)
		sw	$s3, 8($t0)
		addi	$t0, $t0, 12
		li	$t1, 0xFFFF
		sh	$t1, 0($t0)

        	# Sterilize the input to GLIR_BatchPrint of the guard value
        	# 0xFFFF in print row to avoid not printing the remainder of a
        	# batch if the guard is encountered
		addi	$t0, $zero, 0		#i = 0
		addi	$t1, $zero, 8		#loop 8 times
		la	$t2, pClist
		pCguardl:
			lhu	$t3, 0($t2)	#print row
			li	$t4, 0xFFFF	#guard
			bne	$t3, $t4, pCsterile
			sb	$zero, 4($t2)	#set print code 0
			sb	$zero, 0($t2)	#reset print row
			pCsterile:
			addi	$t2, $t2, 12	#increment by 3 words (1 job)
			addi	$t0, $t0, 1	#i++
		bne $t0, $t1, pCguardl
		
		pCguarde:
		la	$a0, pClist
		jal	batchPrint
		
				
		addi	$s1, $s1, 1		#y += 1
		bgtz	$s2, pClmoveRow	#if(err <= 0)
			add	$s2, $s2, $s1	#err += 2y+1
			add	$s2, $s2, $s1
			addi	$s2, $s2, 1
			j	pClcont
		pClmoveRow:			#else
			addi	$s0, $s0, -1	#x -= 1
			sub	$t0, $s1, $s0	#err += 2(y-x) + 1
			add	$s2, $s2, $t0
			add	$s2, $s2, $t0
			addi	$s2, $s2, 1
		pClcont:
		j	pCloop
	pClend:

	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	lw	$s2, -16($fp)
	lw	$s3, -20($fp)
	lw	$s4, -24($fp)
	lw	$s5, -28($fp)
	lw	$s6, -32($fp)
	lw	$s7, -36($fp)
	addi	$sp, $sp, 36
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
##############################################################################
#					END OF GLIM
##############################################################################
