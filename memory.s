;Memory operations: initialize, zero, and move memory

;Initialize

;highram_zero
;Registers edited: A
highram_zero:
	stz ptr_low
	lda #$40
	sta ptr_high

	stz PORTA3

highram_zero_loop:
	lda #0
	sta (ptr_low)
	lda (ptr_low)
	bne highram_zero_loop_fail

	clc
	lda ptr_low
	adc #1
	sta ptr_low
	lda ptr_high
	adc #0
	sta ptr_high

	lda ptr_low
	sta number

	lda ptr_low
	bne highram_zero_loop
	lda ptr_high
	cmp #$60
	bne highram_zero_loop

	stz ptr_low
	lda #$40
	sta ptr_high


	inc PORTA3
	lda PORTA3
	cmp #bank_max
	bne highram_zero_loop

	stz PORTA3

	rts

highram_zero_loop_fail:
	jsr number_zero
	lda ptr_low
	sta number
	lda ptr_high
	sta number+1

	lda #<memory_error
	sta ptr_low
	lda #>memory_error
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr cls
	jsr print

	jsr bin_to_dec

	lda #" "
	sta singlecharbuf
	jsr printchar

	lda #"B"
	sta singlecharbuf
	jsr printchar

	jsr number_zero
	lda PORTA3
	sta number
	jsr bin_to_dec

	stp


;meminit
;Registers edited: A,X
meminit:
	;Setup necessary memory
	stz charcounter
	jsr reset_charbuf
	jsr number_zero
	jsr result_zero
	jsr remainder_zero
	jsr num1_zero
	jsr num2_zero
	jsr mathcounter_zero
	jsr reset_sdbuf
	jsr reset_uptime
	jsr reset_uptimebuf

	lda #1
	sta op_done_reg ;Setup op_done_reg

	;Setup clock
	jsr reset_clock

	;Setup user irq pointer default to just return
	lda #<return
	sta irq_low
	lda #>return
	sta irq_high

	;Setup fcl

	;Pointer to fcl
	lda #<fcl_main
	sta fcl
	lda #>fcl_main
	sta fcl+1
	jsr cls

	stz infcl

meminit_done:
	rts

;Clock

;reset_uptime
;No registers edited
reset_uptime:
	stz uptime
	stz uptime+1
	stz uptime+2
	stz uptime+3
	stz uptime+4
	stz uptime+5
	stz uptime+6
	stz uptime+7
	rts

;reset_uptimebuf
;No registers edited
reset_uptimebuf:
	stz uptimebuf
	stz uptimebuf+1
	stz uptimebuf+2
	stz uptimebuf+3
	stz uptimebuf+4
	stz uptimebuf+5
	stz uptimebuf+6
	stz uptimebuf+7
	rts


;Transfer subroutines

tmathctr: ;Transfer math To result
	lda mathcounter
	sta result
	lda mathcounter+1
	sta result+1
	lda mathcounter+2
	sta result+2
	lda mathcounter+3
	sta result+3
	rts

trtd: ;Transfer Result To Decimal
	lda result
	sta number
	lda result+1
	sta number+1
	lda result+2
	sta number+2
	lda result+3
	sta number+3
	rts

tremtd: ;Transfer Remainder To Decimal
	lda remainder
	sta number
	lda remainder+1
	sta number+1
	lda remainder+2
	sta number+2
	lda remainder+3
	sta number+3
	rts

tmtd: ;Transfer mathcounter To Decimal
	lda mathcounter
	sta number
	lda mathcounter+1
	sta number+1
	lda mathcounter+2
	sta number+2
	lda mathcounter+3
	sta number+3
	rts


;Zeroing subroutines (No registers edited)

milliseconds_zero:
	stz milliseconds
	stz milliseconds+1
	rts


number_zero:
	stz number
	stz number+1
	stz number+2
	stz number+3
	rts

remainder_zero:
	stz remainder
	stz remainder+1
	stz remainder+2
	stz remainder+3
	rts

mathcounter_zero:
	stz mathcounter
	stz mathcounter+1
	stz mathcounter+2
	stz mathcounter+3
	rts


num1_zero:
	stz num1
	stz num1+1
	stz num1+2
	stz num1+3
	rts

num2_zero:
	stz num2
	stz num2+1
	stz num2+2
	stz num2+3
	rts

result_zero:
	stz result
	stz result+1
	stz result+2
	stz result+3
	rts


;"reset" subroutines

;reset_charbuf
;Registers edited: X
reset_charbuf:
	ldx #0

reset_charbuf_loop:
	stz charbuf,x
	cpx #255
	beq return_short10

	inx
	jmp reset_charbuf_loop

;reset_opbuf
;Registers edited: X
reset_opbuf:
	ldx #0

reset_opbuf_loop:
	stz opbuf,x
	cpx #255
	beq return_short10

	inx
	jmp reset_opbuf_loop

;reset_command
;Registers edited: X
reset_command:
	ldx #0

reset_command_loop:
	stz command,x
	cpx #255
	beq return_short10

	inx
	jmp reset_command_loop

return_short10:
	jmp return

;reset_sdbuf
;Registers edited: X
reset_sdbuf:
	ldx #0

reset_sdbuf_loop:
	stz sdbuf,x
	cpx #255
	beq return_short10

	inx
	jmp reset_sdbuf_loop

;reset_ptr
;Registers edited: X
reset_ptr:
	ldy #0
	lda #0

reset_ptr_loop:
	sta (ptr_low),y
	cpy #255
	beq return_short10

	iny
	jmp reset_ptr_loop

;reset_ptra
;Registers edited: X
reset_ptra:
	ldy #0
	lda #0

reset_ptra_loop:
	sta (ptra_low),y
	cpy #255
	beq return_short10

	iny
	jmp reset_ptra_loop

;reset_ptrb
;Registers edited: X
reset_ptrb:
	ldy #0
	lda #0

reset_ptrb_loop:
	sta (ptrb_low),y
	cpy #255
	beq return_short10

	iny
	jmp reset_ptrb_loop

;reset_param
;Registers edited: X
reset_param:
	ldx #0

reset_param_loop:
	stz param,x
	cpx #255
	beq return_short10

	inx
	jmp reset_param_loop


;Moving subroutines (see strcmp)

;mov_welcome
;Registers edited: X,A
mov_welcome:
	ldx #0

mov_welcome_loop:
	lda welcome,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short10
	inx

	jmp mov_welcome_loop

;mov_sdbuf
;Registers edited: X,A
mov_sdbuf:
	ldx #0

mov_sdbuf_loop:
	lda sdbuf,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short10
	inx

	jmp mov_sdbuf_loop

;mov_fdosstarted
;Registers edited: X,A
mov_fdosstarted:
	ldx #0

mov_fdosstarted_loop:
	lda fdosstarted,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short10
	inx

	jmp mov_fdosstarted_loop

 return_short17:
	jmp return

;mov_fclstarted
;Registers edited: X,A
mov_fclstarted:
	ldx #0

mov_fclstarted_loop:
	lda fclstarted,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short17
	inx

	jmp mov_fclstarted_loop

;mov_ptr_charbuf
;Registers edited: Y,A
mov_ptr_charbuf:
	ldy #0

mov_ptr_charbuf_loop:
	lda (ptr_low),y
	sta charbuf,y ;Before possible return so that null character is accepted

	beq return_short17
	iny

	jmp mov_ptr_charbuf_loop

;mov_number_mathcounter
;Registers edited: A
mov_number_mathcounter:
	lda number
	sta mathcounter
	lda number+1
	sta mathcounter+1
	lda number+2
	sta mathcounter+2
	lda number+3
	sta mathcounter+3

	rts


;mov_mathcounter_number
;Registers edited: Y,A
mov_mathcounter_number:
	lda mathcounter
	sta number
	lda mathcounter+1
	sta number+1
	lda mathcounter+2
	sta number+2
	lda mathcounter+3
	sta number+3

	rts


;mov_fmonstarted
;Registers edited: X,A
mov_fmonstarted:
	ldx #0

mov_fmonstarted_loop:
	lda fmonstarted,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short17
	inx

	jmp mov_fmonstarted_loop

;mov_param_sdbuf
;Registers edited: X,A
mov_param_sdbuf:
	ldx #0

mov_param_sdbuf_loop:
	lda param,x
	sta sdbuf,x ;Before possible return so that null character is accepted

	beq return_short17
	inx

	jmp mov_param_sdbuf_loop

;mov_cmd_not_found
;Registers edited: X,A
mov_cmd_not_found:
	ldx #0

mov_cmd_not_found_loop:
	lda cmd_not_found,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short17
	inx

	jmp mov_cmd_not_found_loop

;mov_param_command
;Registers edited: X,A
mov_param_command:
	ldx #0

mov_param_command_loop:
	lda param,x
	sta command,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_param_command_loop

;mov_command_charbuf
;Registers edited: X,A
mov_command_charbuf:
	ldx #0

mov_command_charbuf_loop:
	lda command,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_command_charbuf_loop

;mov_opbuf_charbuf
;Registers edited: X,A
mov_opbuf_charbuf:
	ldx #0

mov_opbuf_charbuf_loop:
	lda opbuf,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_opbuf_charbuf_loop


;mov_command_param
;Registers edited: X,A
mov_command_param:
	ldx #0

mov_command_param_loop:
	lda command,x
	sta param,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_command_param_loop

;mov_opbuf_param
;Registers edited: X,A
mov_opbuf_param:
	ldx #0

mov_opbuf_param_loop:
	lda opbuf,x
	sta param,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_opbuf_param_loop

;mov_command_opbuf
;Registers edited: X,A
mov_command_opbuf:
	ldx #0

mov_command_opbuf_loop:
	lda command,x
	sta opbuf,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_command_opbuf_loop

;mov_charbuf_param
;Registers edited: X,A
mov_charbuf_param:
	ldx #0

mov_charbuf_param_loop:
	lda charbuf,x
	sta param,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_charbuf_param_loop

;mov_charbuf_command
;Registers edited: X,A
mov_charbuf_command:
	ldx #0

mov_charbuf_command_loop:
	lda charbuf,x
	sta command,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_charbuf_command_loop

;mov_param_charbuf
;Registers edited: X,A
mov_param_charbuf:
	ldx #0

mov_param_charbuf_loop:
	lda param,x
	sta charbuf,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_param_charbuf_loop


return_short8:
	jmp return

;mov_param_opbuf
;Registers edited: X,A
mov_param_opbuf:
	ldx #0

mov_param_opbuf_loop:
	lda param,x
	sta opbuf,x ;Before possible return so that null character is accepted

	beq return_short8
	inx

	jmp mov_param_opbuf_loop


;mov_ptr_ptr
;Registers edited: Y,A
mov_ptr_ptr:
	ldy #0

mov_ptr_ptr_loop:
	lda (ptra_low),y
	sta (ptrb_low),y ;Before possible return so that null character is accepted

	beq return_short8
	iny
	bne mov_ptr_ptr_loop