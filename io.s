;Hardware inteface (sound, screen, keyboard)

	.include devices.s


;cls
;Registers edited: A
;Clears screen
cls:
	lda #12 ;<CTRL-L>
	sta singlecharbuf
	jsr printchar
	rts


;readchar
;PS2 Registers edited: A
;Serial Registers edited: A, X, Y
;Char is returned in singlecharbuf
readchar:
	.ifdef PS2_ENABLED

readchar_loop:
	lda PORTA1
	and #%00000010 ;Data ready
	bne readchar_loop

	lda PORTB1
	sta singlecharbuf

	lda PORTA1
	and #%11111011 ;Clear ACK pin
	sta PORTA1

	;5 us delay
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	lda PORTA1
	ora #%00000100 ;Set ACK pin
	sta PORTA1

	lda singlecharbuf

	cmp #8
	beq is_backspace

	sta singlecharbuf

	rts

is_backspace:
	lda #127
	sta singlecharbuf

	rts


	.endif
	
	.ifndef PS2_ENABLED
	jmp readchar_ACIA

	.endif


readchar_ACIA:
	lda ACIA_STATUS       ; get ACIA status
    and #$08        ; mask rx buffer status flag
    beq readchar ; loop if rx buffer empty
 
    lda ACIA_DATA     ; get byte from ACIA data port
	sta singlecharbuf

	rts


;printchar
;Registers edited: A, X, Y
;Char to print is in singlecharbuf
printchar:
	lda ACIA_STATUS     ; get status byte
	and #$10        ; mask transmit buffer status flag
	beq printchar ; loop if tx buffer full

	ldx #255
	ldy #32
	jsr delay

	lda singlecharbuf
	sta ACIA_DATA      ; save byte to ACIA data port

	rts	

;check_pressed
;Registers edited: A
;Result in carry: 1 means not pressed, 0 means pressed.
check_pressed:
	.ifdef PS2_ENABLED

	lda PORTA1
	and #%00000010 ;1 if not pressed, 0 if pressed

	;Move result into carry
	ror
	ror

	.endif

	.ifndef PS2_ENABLED

	lda ACIA_STATUS       ;Get ACIA status
    and #$08        ;Mask RX buffer status flag. 0 means not pressed, 1 means pressed.
	eor #255 ;Invert A. 1 means not pressed, 0 means pressed.

	;Move result into carry 
	ror
	ror
	ror
	ror

	.endif
	

;clock_off
;Registers edited: A
clock_off:
	lda #%01111111 ;Disable all VIA 1 interrupts.
	sta IER1

	;Setup Aux. 
	lda #%00000000
	sta ACR1 ;Interrupt on load

	rts

;clock_on
;Registers edited: A
clock_on:
	lda #%11000000 ;Enable Timer 1 VIA 1 interrupt.
	sta IER1

	;Setup Aux. 
	lda #%01000000
	sta ACR1 ;Contious interrupts, PB7 square wave diabled.

	;Init timer 1 on VIA 1
	lda #136 ;Low byte of 5000
	sta T1CL1 ;Load T1 low latches

	lda #19 ;High byte of 5000
	sta T1CH1 ;Loads T1 high latches and start countdown. Also reset Timer 1 IRQ flag.

	rts

;init_acia
;Registers edited: A
init_acia:
	lda #$0B;NO interrupt on byte recieved. $09 will allow interrupt on data recieved.
	sta ACIA_COMMAND 
	lda #$1E ;9600 baud
	;lda #$1F ;19200 baud
	sta ACIA_CONTROL

	rts

;init_via
;Registers edited: A
init_via:
	;Setup VIA interrupts
	lda #%11000000 ;Enable Timer 1 VIA 1 interrupt
	sta IER1
	lda #%01111111 ;Disable all interrupts
	sta IER2
	sta IER3 ;Disable all VIA 3 interrupts

	;Setup bank control register
	lda #255
	sta DDRA3
	stz PORTA3 

	.ifdef PS2_ENABLED

	;Setup VIA ports
	lda #%11111100 ;Set DDRA0 (SD_INSERTED), DDRA1 (PS2_RDY) to input, the rest to output
	sta DDRA1

	stz DDRB1 ;Set PORTB1 to input

	lda PORTA1
	and #%11110111 ;Keep PS2 controller in reset
	sta PORTA1

	.endif

	.ifndef PS2_ENABLED
	;Setup VIA ports
	lda #%11111110 ;Set DDRA0 (SD_INSERTED), the rest to output
	sta DDRA1
	.endif

	jsr clock_off

	rts


;deviceinit
;Registers edited: A
deviceinit:
	;ACIA init
	jsr init_acia

	;Setup VIAs
	jsr init_via
	rts