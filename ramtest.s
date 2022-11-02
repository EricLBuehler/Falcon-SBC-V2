	.org $2000

	jmp main

	
	.include header.s

main:
	jsr highram_zero_
	lda #"D"
	sta singlecharbuf
	jsr printchar
	jmp main

;highram_zero
;Registers edited: A
highram_zero_:
	stz ptr_low
	lda #$40
	sta ptr_high

	stz PORTA3

highram_zero_loop_:
	lda #0
	sta (ptr_low)
	lda (ptr_low)
	bne highram_zero_loop_fail_

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
	bne highram_zero_loop_
	lda ptr_high
	cmp #$60
	bne highram_zero_loop_

	stz ptr_low
	lda #$40
	sta ptr_high


	inc PORTA3
	lda PORTA3
	cmp #fpl_zero_max
	bne highram_zero_loop_

	stz PORTA3

	rts

highram_zero_loop_fail_:
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

	jmp highram_zero_loop_