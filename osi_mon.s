
; minimal monitor for EhBASIC and 6502 simulator V1.05


; put the IRQ and MNI code in RAM so that it can be changed

IRQ_vec	= VEC_SV+2		; IRQ code vector
NMI_vec	= IRQ_vec+$0A	; NMI code vector


	.include "devices.s"

char = $5000

value = $5403 ;4 bytes
mod10 = $5407 ;4 bytes
message_out= $540B ;11 bytes: 10 bytes for number, 1 byte for null terminated string.
convert_counter = $541C
number = $5411 ;411-414
b1 = $5415
b2 = $5416
b3 = $5417
b4 = $5418


; now the code. all this does is set up the vectors and interrupt code
; and wait for the user to select [C]old or [W]arm start. nothing else
; fits in less than 128 bytes

	;.org	$8000

	.include "basic.asm"


readchar_ACIA_:
	lda ACIA_STATUS       ; get ACIA status
    and #$08        ; mask rx buffer status flag
    beq readchar_ACIA_ ; loop if rx buffer empty
 
    lda ACIA_DATA     ; get byte from ACIA data port

	rts

printchar_:
	pha
printchar_loop:
	lda ACIA_STATUS     ; get status byte
	and #$10        ; mask transmit buffer status flag
	beq printchar_loop ; loop if tx buffer full

	ldx #255
	ldy #255
	jsr delay
	lda char
	sta ACIA_DATA      ; save byte to ACIA data port
	pla
	rts	

init_acia_:
	sta ACIA_STATUS
	lda #$0B;NO interrupt on byte recieved. $09 will allow interrupt on data recieved.
	sta ACIA_COMMAND 
	lda #$1E ;9600 baud
	;lda #$1F ;19200 baud
	sta ACIA_CONTROL

	rts







ACIA_init
	jmp init_acia_

; reset vector points here
RES_vec
	cld				; clear decimal mode
	LDX	#$FF			; empty stack
	TXS				; set the stack
	JSR	ACIA_init

; set up vectors and interrupt code, copy them to page 2
	LDY	#END_CODE-LAB_vec	; set index/count

LAB_stlp
	LDA	LAB_vec-1,Y		; get byte from interrupt code
	STA	VEC_IN-1,Y		; save to RAM
	DEY				; decrement index/count
	BNE	LAB_stlp		; loop if more to do

; now do the signon message, Y = $00 here
LAB_signon
	LDA	LAB_mess,Y		; get byte from sign on message
	BEQ	LAB_nokey		; exit loop if done

	JSR	V_OUTP		; output character
	INY				; increment index
	BNE	LAB_signon		; loop, branch always

LAB_nokey
	JSR	V_INPT		; call scan input device

	BCC	LAB_nokey		; loop if no key
	
	JSR V_OUTP

	AND	#$DF			; mask xx0x xxxx, ensure upper case
	CMP	#'W'			; compare with [W]arm start
	BEQ	LAB_dowarm		; branch if [W]arm start

	CMP	#'C'			; compare with [C]old start
	BNE	RES_vec		; loop if not [C]old start

	JMP	LAB_COLD		; do EhBASIC cold start

LAB_dowarm
	JMP	LAB_WARM		; do EhBASIC warm start


;delay
;Registers edited: X,Y
delay:
	dex
	bne delay
	dey
	bne delay
	rts

; byte out to ACIA routine
ACIA_out
	sta char

	jmp printchar_
	

; get character from ACIA routine
ACIA_in
	jmp readchar_ACIA_


no_load				; empty load vector for EhBASIC
no_save				; empty save vector for EhBASIC
	RTS

; vector tables
LAB_vec
	.word	ACIA_in		; byte in from simulated ACIA
	.word	ACIA_out		; byte out to simulated ACIA
	.word	no_load		; null load vector for EhBASIC
	.word	no_save		; null save vector for EhBASIC

; EhBASIC IRQ support
IRQ_CODE
	PHA				; save A
	LDA	IrqBase		; get the IRQ flag byte
	LSR				; shift the set b7 to b6, and on down ...
	ORA	IrqBase		; OR the original back in
	STA	IrqBase		; save the new IRQ flag byte
	PLA				; restore A
	RTI
NMI_CODE
	PHA				; save A
	LDA	NmiBase		; get the NMI flag byte
	LSR				; shift the set b7 to b6, and on down ...
	ORA	NmiBase		; OR the original back in
	STA	NmiBase		; save the new NMI flag byte
	PLA				; restore A
	RTI

END_CODE

LAB_mess
	.byte	$0D,$0A,"6502 EhBASIC [C]old/[W]arm ?",$00
					; sign on string

; system vectors
	.org $fffa
	.word	NMI_vec		; NMI vector
	.word	RES_vec		; RESET vector
	.word	IRQ_vec		; IRQ vector
