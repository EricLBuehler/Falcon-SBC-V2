;FCL

;get_configured_ram_size
;Registers edited: A
;Returns in A,  0=no highram, 1=512 kb highram, 2=1 mb highram
get_configured_ram_size:
	lda BANK
	pha
	
	lda #%00000000
	sta BANK

	lda #$55
	sta $4000

	lda $4000
	cmp #$55
	bne get_configured_ram_size_nohighram

	lda #$aa
	sta $4000

	lda $4000
	cmp #$aa
	bne get_configured_ram_size_nohighram


	lda #%01000000
	sta BANK

	lda #$55
	sta $4000

	lda $4000
	cmp #$55
	bne get_configured_ram_size_512_kb_highram

	lda #$aa
	sta $4000

	lda $4000
	cmp #$aa
	bne get_configured_ram_size_512_kb_highram

	bra get_configured_ram_size_1_mb_highram




get_configured_ram_size_nohighram:
	pla
	sta BANK

	lda #0
	rts

get_configured_ram_size_512_kb_highram:
	pla
	sta BANK

	lda #1
	rts

get_configured_ram_size_1_mb_highram:
	pla
	sta BANK

	lda #2
	rts

;fcl_load_readbyte
;Registers edited: A
;Result in A
fcl_load_readbyte:
	lda op_done_reg
	beq fcl_load_fail

	lda sdbuf ;Char in first byte of sdbuf

	sei ;Disable IRQ
	wai
	cli ;Enable IRQ

	clc
	rts

fcl_load_fail:
	sec
	
	
	



fcl_main:
	lda #1
	sta infcl

	jsr mov_fclstarted
	jsr print

	jsr get_configured_ram_size
	beq fcl_no_highram
	cmp #1
	beq fcl_512kb_highram
	cmp #2
	beq fcl_1mb_highram

fcl_no_highram:
	lda #<no_highram_error
	sta ptr_low
	lda #>no_highram_error
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jmp fdos

fcl_512kb_highram:
	lda #<_512_kb_highram
	sta ptr_low
	lda #>_512_kb_highram
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	bra fcl_done_ramtest

fcl_1mb_highram:
	lda #<_1_mb_highram
	sta ptr_low
	lda #>_1_mb_highram
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

fcl_done_ramtest:

fcl_mainloop:
	jsr terminal_prompt
	jsr input

	;Split string

	jsr reset_command
	jsr reset_param

	lda #" "
	sta chartofind
	lda #<charbuf
	sta ptr_low
	lda #>charbuf
	sta ptr_high
	jsr strcount

	lda fclindex
	bne fcl_mainloop_gt1

	;No parameters
	jsr mov_charbuf_command

	jmp fcl_mainloop_check_command

fcl_mainloop_gt1:
	;Command
	lda #<charbuf
	sta ptr_low
	lda #>charbuf
	sta ptr_high

	jsr strlen

	lda #" "

	jsr strtolist

	lda ptr_low
	sta ptra_low
	lda ptr_high
	sta ptra_high

	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	lda #0
	sta strindex_

	jsr strlistindex

	lda #<opbuf
	sta ptra_low
	lda #>opbuf
	sta ptra_high

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	jsr strcpy



	;Paramter
	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<param
	sta ptrb_low
	lda #>param
	sta ptrb_high

	lda #<charbuf
	sta ptr_low
	lda #>charbuf
	sta ptr_high

	jsr strlen

	ldy strcounterb
	iny ;Move past space
	ldx length

	jsr strslice

	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	jsr listtostr

fcl_mainloop_check_command:
	;Check command
	lda #<command
	sta ptra_low
	lda #>command
	sta ptra_high

	lda #<fcl_command_load_str
	sta ptrb_low
	lda #>fcl_command_load_str
	sta ptrb_high
	jsr strcmp
	beq fcl_command_load

	;DOS commands
	jsr check_mount ;TYPE: mou
	;jsr check_open ;TYPE: op
	jsr check_close ;TYPE: cl
	jsr check_size ;TYPE: si
	jsr check_read ;TYPE: re
	;jsr check_load ;TYPE: lo
	;jsr check_save ;TYPE: sa
	jsr check_remove_file ;TYPE: rmf
	jsr check_remove_dir ;TYPE: rmd
	jsr check_make_file ;TYPE: mkf
	jsr check_make_dir ;TYPE: mkd
	jsr check_cd ;TYPE: cd
	jsr check_list_dir ;TYPE: ls
	jsr check_path ;TYPE: pa
	jsr check_root ;TYPE: ro
	;jsr check_position ;TYPE: po
	;jsr check_seek ;TYPE: se
	;jsr check_readbyte ;TYPE: rdb
	jsr check_exists ;TYPE: ex
	jsr check_copydos ;TYPE: cp
	;jsr check_editbyte ;TYPE: edb
	;jsr check_appendbyte ;TYPE: adb

	jsr check_fmon ;monitor
	jsr check_fdos ;fdos


	jmp fcl_mainloop


;fcl commands
fcl_command_done:
	jmp fcl_mainloop

fcl_command_load:
	stz BANK

	jsr close_file
	jsr open_file

	bcc openfile_success_fcl
	;Fail
	lda #<file_opening_error
	sta ptr_low
	lda #>file_opening_error
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jmp fcl_command_done

openfile_success_fcl:
	jsr clock_off

	lda #1
	sta op_result_reg

	lda #4
	jsr send_command ;Start load readstyle on wai

	lda #1
	sta op_done_reg

	lda #$00
	sta ptr_low
	lda #$40
	sta ptr_high

fcl_command_load_loop:
	jsr result_zero

fcl_command_load_inner_loop:
	;Inner loop
	jsr fcl_load_readbyte
	pha
	lda op_done_reg
	beq fcl_command_load_loop_done
	pla
	sta (ptr_low)

	clc
	lda number
	adc #1
	sta number
	lda number+1
	adc #0
	sta number+1
	lda number+2
	adc #0
	sta number+2
	lda number+3
	adc #0
	sta number+3

	clc
	lda result
	adc #1
	sta result
	lda result+1
	adc #0
	sta result+1

	lda result
	cmp #<$2000
	bne fcl_command_load_inner_loop
	lda result+1
	cmp #>$2000
	bne fcl_command_load_inner_loop

	;Done with inner loop, inc bank and start again

	inc PORTA3
	lda PORTA3
	cmp #fcl_program_bank_max
	bne fcl_command_load_loop

fcl_command_load_loop_done:
	jmp fcl_command_done






;For all fcl_op subroutines, only parameter is A
;Return value in A, 0=success, 1=done
fcl_op_print_char:
	beq fcl_op_print_char_done
	sta singlecharbuf
	jsr printchar

	lda #0
	rts

fcl_op_print_char_done:
	lda #1
	rts



;FCL program text operation
fcl_text_op:
	stz ptr_low
	lda #$40
	sta ptr_high

	stz BANK

fcl_text_op_loop:
	lda (ptr_low)
	jsr fcl_indirect_jsr
	cmp #1
	beq fcl_text_op_loop_done

	clc
	lda ptr_low
	adc #1
	sta ptr_low
	lda ptr_high
	adc #0
	sta ptr_high


	lda ptr_low
	bne fcl_text_op_loop
	lda ptr_high
	cmp #$60
	bne fcl_text_op_loop

	stz ptr_low
	lda #$40
	sta ptr_high


	inc BANK
	lda BANK
	cmp #bank_max
	bne fcl_text_op_loop

	stz BANK

fcl_text_op_loop_done:
	rts

;Jump to fcl_ptr
fcl_indirect_jsr:
	jmp (fcl_ptr)
	