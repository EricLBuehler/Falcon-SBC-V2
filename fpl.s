;FPL: type fpl
;Syntax: [LINE] [COMMAND] [PARMATER]
fpl_main:
	jsr mov_fplstarted
	jsr print
	jsr terminal_prompt

	stz PORTA3

fplloop:
	jsr input

	lda charbuf
	sta sdbuf

	lda #32
	sta charpos
	jsr count
	lda count_out
	beq fpl_commandonly ;Zero
	cmp #1
	beq fpl_command_param
	bne fpl_linecommandparam ;>1

fpl_command_param:
	jsr parse

	lda command
	jsr isnumeric
	bcc isnumeric_fpl
	;Not numeric.

	jmp fpl_runcmd

isnumeric_fpl:
	jsr mov_command_opbuf

	jsr dec_to_bin
	lda number
	sta linenum
	lda number+1
	sta linenum+1
	lda number+2
	sta linenum+2
	lda number+3
	sta linenum+3

	jsr mov_param_command

	jsr reset_param

	jmp fpl_runcmd

fpl_linecommandparam:
	jsr parsefpl
	jmp fpl_runcmd

fpl_commandonly:
	jsr reset_param
	jsr mov_charbuf_command

fpl_runcmd:
	jsr run_commandfpl

	jsr terminal_prompt
	
	jmp fplloop

;FPL command decoding and execution


;FPL command entry:
;1 null byte (also serves as null terminating byte for previous lines' param)
;2 bytes for line number
;1 byte for command token
;100 bytes of parameter

;This allows 1260 lines in 128 kB (8192*16/104).

;FPL string entry:
;32 bytes for variable name
;1 null byte
;256 bytes of null terminated string

;This allows 113 string variables in 64 kB (8192*4/289)

;FPL integer entry
;32 bytes for variable name
;1 null byte
;4 bytes integer

;This allows 442 integer variables in 16 kB (8192*2/37)

;FPL floating point entry:
;32 bytes for variable name
;1 null byte
;4 bytes float representation

;This allows 442 floating point variables in 16 kB (8192*2/37)

run_commandfpl: 
	;Check if length of param > 100
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	jsr strlen
	lda length
	cmp #101
	bcc length_param_lte_100

	lda #<param_to_long_error
	sta ptr_low
	lda #>param_to_long_error
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jsr readchar
	lda singlecharbuf
	cmp #"i"
	bne ptle_fpl

	lda #<ptle_info
	sta ptr_low
	lda #>ptle_info
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

ptle_fpl:
	rts

length_param_lte_100:
	lda command
	bne fpl_command_run_start

	rts
fpl_command_run_start:
	lda sdbuf
	jsr isnumeric
	bcs inline_cmd_fpl

	;Tokenize FPL program commands
	jsr tokenize_println ;println
	bcc start_tokenizing

	jsr tokenize_print ;print
	bcc start_tokenizing

	jsr tokenize_goto ;goto
	bcc start_tokenizing

	jsr tokenize_comment ;#
	bcc start_tokenizing

	jsr tokenize_end ;end
	bcc start_tokenizing

	jsr tokenize_cls ;cls
	bcc start_tokenizing

	jsr tokenize_int ;int
	bcc start_tokenizing

	jsr tokenize_str ;str
	bcc start_tokenizing

	jsr tokenize_input ;input
	bcc start_tokenizing

	jsr tokenize_if ;if
	bcc start_tokenizing

	jsr tokenize_float ;float
	bcc start_tokenizing

	jsr tokenize_add ;add
	bcc start_tokenizing

	jmp fpl_tokenizer_cmd_nf ;No command found

start_tokenizing:
	jmp start_tokenizing_

inline_cmd_fpl:
	;Check for inline
	stz cmddone
	;jsr check_exit ;exit
	jsr check_run ;run
	jsr check_list ;list
	jsr check_new ;new
	jsr check_comment ;comment
	jsr check_uncomment ;uncomment
	jsr check_save_fpl ;save
	jsr check_load_fpl ;load 
	;Other commands
	jsr check_fdos ;fdos
	jsr check_fmon ;monitor

	;FDOS commands
	jsr check_mount ;TYPE: mou
	jsr check_open ;TYPE: op
	jsr check_close ;TYPE: cl
	jsr check_size ;TYPE: si
	jsr check_read ;TYPE: re
	jsr check_remove_file ;TYPE: rmf
	jsr check_remove_dir ;TYPE: rmd
	jsr check_make_file ;TYPE: mkf
	jsr check_make_dir ;TYPE: mkd
	jsr check_cd ;TYPE: cd
	jsr check_list_dir ;TYPE: ls
	jsr check_path ;TYPE: pa
	jsr check_root ;TYPE: ro
	jsr check_position ;TYPE: po
	jsr check_seek ;TYPE: se
	jsr check_readbyte ;TYPE: rdb
	jsr check_exists ;TYPE: ex
	jsr check_copydos ;TYPE: cp
	jsr check_editbyte ;TYPE: edb
	jsr check_appendbyte ;TYPE: adb

	;FPL inline commands that are also fpl program commands
	jsr check_cls ;cls
	jsr check_print ;print


	lda cmddone
	bne ptle_fpl_short


	jmp fpl_tokenizer_cmd_nf ;No command found

ptle_fpl_short:
	jmp ptle_fpl

search_fail_tokenize:
	jsr number_zero
	lda #104
	sta number

	jsr maxline_add

	;Check if over 104*78 bytes
	lda maxlinecounter
	cmp #linecounter_max
	bne no_bank_switch_fpl_maxline

	lda #$00
	sta maxline
	lda #$40
	sta maxline+1

	lda #255
	sta maxlinecounter

	inc maxlinebank
	lda maxlinebank
	cmp #fpl_line_bank_max
	beq outofmemory_short ;THIS ONLY ALLOWS FPL TO USE 128 kB OF RAM

no_bank_switch_fpl_maxline:

	inc maxlinecounter

	jmp continue_tokenizing

outofmemory_short:
	jmp outofmemory

search_fail_tokenize_short:
	jmp search_fail_tokenize


start_tokenizing_:
	pha ;Save token

	lda linenum
	bne tokenize_line_gt_0
	lda linenum+1
	bne tokenize_line_gt_0

	pla

	;Print out error
	lda #<line_1_not_allowed
	sta ptr_low
	lda #>line_1_not_allowed
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	rts

tokenize_line_gt_0:
	;Check if over 104*78 bytes
	lda linecounter
	cmp #linecounter_max
	bne no_bank_switch_fpl

	lda #$00
	sta nextline
	lda #$40
	sta nextline+1

	lda #255
	sta linecounter

	inc PORTA3
	lda PORTA3
	cmp #fpl_line_bank_max
	beq outofmemory ;THIS ONLY ALLOWS FPL TO USE 128 kB OF RAM

no_bank_switch_fpl:

	;Check if maxline
	lda linenummax
	cmp linenum
	bcs not_gt_tokenize

	lda linenummax+1
	cmp linenum+1
	beq tokenize_line_eq
	bcs not_gt_tokenize

tokenize_line_eq:
	;Max line
	lda linenum
	sta linenummax
	lda linenum+1
	sta linenummax+1

not_gt_tokenize:

	lda linenum
	sta linenum_old
	lda linenum+1
	sta linenum_old+1

	;Search for line
	jsr search_line
	bcs search_fail_tokenize_short

	lda searchptr
	sta nextline

	lda searchptr+1
	sta nextline+1

	lda searchptrbank
	sta nextlinebank
	sta PORTA3

continue_tokenizing:
	;Length of line
		
	lda #0 ;Null byte for first byte of line AND also null byte for previous line's parameter
	ldy #0
	sta (nextline),y

	;Line num
	lda linenum
	ldy #1
	sta (nextline),y

	lda linenum+1
	ldy #2
	sta (nextline),y

	;Token
	pla
	ldy #3
	sta (nextline),y

	;Not out of memory:
	jmp no_wraparound

outofmemory:
	lda #<out_of_memory_error
	sta ptra_low
	lda #>out_of_memory_error
	sta ptra_high

	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high

	jsr strcpy ;Copy string	

	jsr print

	jsr readchar
	lda singlecharbuf
	cmp #"i"
	bne oome_fpl

	lda #<oome_info
	sta ptr_low
	lda #>oome_info
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

oome_fpl
	rts

no_wraparound:

	;Parameter

	ldy #4
	ldx #0
tokenize_loop:
	lda param,x
	sta (nextline),y
	
	inx
	iny
	cpx #101 ;Make sure actually 100 bytes are copied.
	bne tokenize_loop

	jsr number_zero
	lda #104
	sta number
	jsr nextline_add

	inc linecounter

	rts


fpl_tokenizer_cmd_nf:
	jsr mov_cmd_not_found
	jsr print

	rts


fpl_load_readbyte:
	lda op_done_reg
	beq fpl_load_fail

	lda sdbuf ;Char in first byte of sdbuf

	sei ;Disable IRQ
	wai
	cli ;Enable IRQ

	clc
	rts

fpl_load_fail:
	sec
	rts

fpl_load_read_fpl_status:
	;Read nextline
	jsr fpl_load_readbyte
	sta nextline
	jsr fpl_load_readbyte
	sta nextline+1
	jsr fpl_load_readbyte
	sta nextlinebank
	;Read maxline
	jsr fpl_load_readbyte
	sta maxline
	jsr fpl_load_readbyte
	sta maxline+1
	jsr fpl_load_readbyte
	sta maxlinebank
	;Read linenum_old
	jsr fpl_load_readbyte
	sta linenum_old
	jsr fpl_load_readbyte
	sta linenum_old+1
	;Read linenummax
	jsr fpl_load_readbyte
	sta linenummax
	jsr fpl_load_readbyte
	sta linenummax+1
	rts



check_load_fpl:
	lda command
	cmp #"l"
	bne return_short31
	lda command+1
	cmp #"o"
	bne return_short31
	lda command+2
	cmp #"a"
	bne return_short31
	lda command+3
	cmp #"d"
	bne return_short31

	jsr check_param
	bcc load_param

	ldx fpl_error_param_required
	jsr raise_fpl_error
	jmp fpl_error_done

load_ptle:
	ldx parameter_to_long
	jsr raise_fpl_error

	lda #<gt_twelve_str
	sta ptr_low
	lda #>gt_twelve_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jmp fpl_error_done

load_param:
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	jsr strlen
	lda length
	cmp #13
	bcs load_ptle

	jsr close_file
	jsr open_file
	bcc load_fpl_file_found

	lda #<file_opening_error
	sta ptr_low
	lda #>file_opening_error
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jmp command_done

load_fpl_file_found:
	jsr clock_off

	jsr new_fpl

	lda #1
	sta op_result_reg

	lda #4
	jsr send_command ;start load readstyle on wai

	lda #1
	sta op_done_reg

	lda fplloadflag
	beq first_load_loadfpl

	jsr fpl_load_readbyte

first_load_loadfpl:
	lda #255
	sta fplloadflag

	jsr fpl_load_read_fpl_status ;Read in fpl status

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	stz PORTA3
	stz searchcounter

fpl_load_loop_outer:

	ldy #0
fpl_load_loop_inner:
	jsr fpl_load_readbyte
	bcs fpl_load_done
	sta (searchptr)

	clc
	lda searchptr
	adc #1
	sta searchptr
	lda searchptr+1
	adc #0
	sta searchptr+1

	iny

	cpy #104
	bne fpl_load_loop_inner

	;Outer loop

	lda searchcounter
	cmp #linecounter_max
	bne fpl_load_goaround

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda #255
	sta searchcounter

	inc PORTA3
	lda PORTA3
	cmp #fpl_line_bank_max
	beq fpl_load_done ;THIS ONLY ALLOWS FPL TO USE 128 kB OF RAM

fpl_load_goaround:
	inc searchcounter

	jmp fpl_load_loop_outer

fpl_load_done:
	stz PORTA3

	stz op_done_reg ;Tell coprocessor that we are done

	sei ;Disable IRQ
	wai
	cli ;Enable IRQ

	jsr close_file
	jsr clock_on
	jmp command_done


check_save_fpl:
	lda command
	cmp #"s"
	bne return_short30
	lda command+1
	cmp #"a"
	bne return_short30
	lda command+2
	cmp #"v"
	bne return_short30
	lda command+3
	cmp #"e"
	bne return_short30


	;Save format:
	;2 bytes nextline
	;1 byte nextlinebank
	;2 bytes maxline
	;1 byte maxlinebank
	;2 bytes linenum_old
	;2 bytes linenummax
	;Data
	jsr check_param
	bcc save_param

	ldx fpl_error_param_required
	jsr raise_fpl_error
	jmp fpl_error_done

save_ptle:
	ldx parameter_to_long
	jsr raise_fpl_error

	lda #<gt_twelve_str
	sta ptr_low
	lda #>gt_twelve_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jmp fpl_error_done

save_param:
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	jsr strlen
	lda length
	cmp #13
	bcs save_ptle

start_save:
	lda PORTA3
	pha

	stz PORTA3

	jsr close_file
	jsr remove_file
	jsr make_file
	jsr open_file

	;nextline
	lda nextline
	sta number
	jsr appendbyte

	lda nextline+1
	sta number
	jsr appendbyte

	;nextlinebank
	lda nextlinebank
	sta number
	jsr appendbyte

	;maxline
	lda maxline
	sta number
	jsr appendbyte

	lda maxline+1
	sta number
	jsr appendbyte

	;maxlinebank
	lda maxlinebank
	sta number
	jsr appendbyte

	;linenum_old
	lda linenum_old
	sta number
	jsr appendbyte

	lda linenum_old+1
	sta number
	jsr appendbyte

	;linenummax
	lda linenummax
	sta number
	jsr appendbyte

	lda linenummax+1
	sta number
	jsr appendbyte


	stz linenum
	stz linenum+1
	stz linenum+2
	stz linenum+3


save_fpl_loop:
	jsr search_line
	bcs save_fpl_goaround

	lda searchptrbank
	sta PORTA3

	ldy #3
	lda (searchptr),y
	beq save_fpl_goaround

	stz size_reg_0
	stz size_reg_1
	stz size_reg_2
	stz size_reg_3

	lda searchptr
	sta size_reg_0
	lda searchptr+1
	sta size_reg_1

	jsr number_zero
	lda #104
	sta number
	
	jsr save_file

save_fpl_goaround:
	lda linenum
	cmp linenummax
	bne save_fpl_goaround_ne

	lda linenum+1
	cmp linenummax+1
	bne save_fpl_goaround_ne

	jmp save_fpl_done
	
save_fpl_goaround_ne:
	clc
	lda linenum
	adc #1
	sta linenum
	lda linenum+1
	adc #0
	sta linenum+1

	jmp save_fpl_loop

save_fpl_done:
	jsr close_file
	pla
	sta PORTA3
	jmp command_done



return_short29:
	jmp return

check_uncomment:	
	lda command
	cmp #"u"
	bne return_short29
	lda command+1
	cmp #"n"
	bne return_short29
	lda command+2
	cmp #"c"
	bne return_short29
	lda command+3
	cmp #"o"
	bne return_short29
	lda command+4
	cmp #"m"
	bne return_short29
	lda command+5
	cmp #"m"
	bne return_short29
	lda command+6
	cmp #"e"
	bne return_short29
	lda command+7
	cmp #"n"
	bne return_short29
	lda command+8
	cmp #"t"
	bne return_short29

	jsr mov_param_opbuf
	jsr dec_to_bin

	lda number
	sta linenum
	lda number+1
	sta linenum+1
	lda number+2
	sta linenum+2
	lda number+3
	sta linenum+3

	jsr search_line
	bcc fpl_uncomment_line_found

	lda #<line_not_found_fpl_list_str
	sta ptr_low
	lda #>line_not_found_fpl_list_str
	sta ptr_high

	jsr mov_ptr_charbuf
	jsr print
	jmp command_done

fpl_uncomment_line_found:
	ldy #3
	lda (searchptr),y
	and #%01111111
	sta (searchptr),y

	jmp command_done

check_comment:	
	lda command
	cmp #"c"
	bne return_short28
	lda command+1
	cmp #"o"
	bne return_short28
	lda command+2
	cmp #"m"
	bne return_short28
	lda command+3
	cmp #"m"
	bne return_short28
	lda command+4
	cmp #"e"
	bne return_short28
	lda command+5
	cmp #"n"
	bne return_short28
	lda command+6
	cmp #"t"
	bne return_short28

	jsr mov_param_opbuf
	jsr dec_to_bin

	lda number
	sta linenum
	lda number+1
	sta linenum+1
	lda number+2
	sta linenum+2
	lda number+3
	sta linenum+3

	jsr search_line
	bcc fpl_comment_line_found

	lda #<line_not_found_fpl_list_str
	sta ptr_low
	lda #>line_not_found_fpl_list_str
	sta ptr_high

	jsr mov_ptr_charbuf
	jsr print
	jmp command_done

fpl_comment_line_found:
	ldy #3
	lda (searchptr),y
	ora #%10000000
	sta (searchptr),y

	jmp command_done


return_short28:
	jmp return


check_list:	
	lda command
	cmp #"l"
	bne return_short28
	lda command+1
	cmp #"i"
	bne return_short28
	lda command+2
	cmp #"s"
	bne return_short28
	lda command+3
	cmp #"t"
	bne return_short28

	lda PORTA3
	pha

	stz PORTA3

	lda param
	jsr isnumeric
	bcs isnotnumeric_fpl_list_

	jsr mov_param_opbuf
	jsr dec_to_bin

	lda number
	sta linenum
	lda number+1
	sta linenum+1
	lda number+2
	sta linenum+2
	lda number+3
	sta linenum+3
	
	lda #13
	sta singlecharbuf
	jsr printchar

	jsr search_line
	bcs fpl_list_lnf_wparam

	lda searchptrbank
	sta PORTA3

	;Found line!

	ldy #3
	lda (searchptr),y
	sta command
	bmi fpl_list_commented_line_numeric ;Line is commented.
	beq fpl_list_lnf_wparam

	jmp fpl_list_notcommented_line_numeric

fpl_list_commented_line_numeric:
	lda #"#"
	sta singlecharbuf
	jsr printchar

fpl_list_notcommented_line_numeric:

	jsr result_zero

	lda #4
	sta result
	jsr searchptr_add

	jmp get_param_list_wparam

fpl_list_lnf_wparam:
	lda #<line_not_found_fpl_list_str
	sta ptr_low
	lda #>line_not_found_fpl_list_str
	sta ptr_high

	jsr mov_ptr_charbuf
	jsr print



	pla
	sta PORTA3

	jmp command_done






isnotnumeric_fpl_list_:
	jmp isnotnumeric_fpl_list


get_param_list_wparam:
	jsr reset_param

	ldy #0
mov_param_list_loop_wparam:
	lda (searchptr),y
	sta param,y

	iny
	cpy #101 ;Make sure actually 100 bytes are copied.
	bne mov_param_list_loop_wparam

	jsr number_zero
	lda linenum
	sta number
	lda linenum+1
	sta number+1
	jsr bin_to_dec

	jsr print_command_list_fpl ;Print out command

	jsr mov_param_charbuf
	jsr print

	pla
	sta PORTA3

	jmp command_done


isnotnumeric_fpl_list:	
	stz linenum
	stz linenum+1
	stz linenum+2
	stz linenum+3

	lda #13
	sta singlecharbuf
	jsr printchar

fpl_list_loop:
	jsr search_line
	bcs fpl_list_nextline_short

	lda searchptrbank
	sta PORTA3

	;Found line!

	ldy #3
	lda (searchptr),y
	sta command
	bmi fpl_list_commented_line ;Line is commented.
	beq fpl_list_nextline_short

	jmp fpl_list_noncommented_line

fpl_list_commented_line:
	lda #"#"
	sta singlecharbuf
	jsr printchar

fpl_list_noncommented_line:
	jsr result_zero

	lda #4
	sta result
	jsr searchptr_add

	jmp get_param_list

fpl_list_nextline_short:
	jmp fpl_list_nextline

get_param_list:
	jsr reset_param

	ldy #0
mov_param_list_loop:
	lda (searchptr),y
	sta param,y

	iny
	cpy #101 ;Make sure actually 100 bytes are copied.
	bne mov_param_list_loop


	jsr number_zero
	lda linenum
	sta number
	lda linenum+1
	sta number+1
	jsr bin_to_dec

	jsr print_command_list_fpl ;Print out command

	jsr mov_param_charbuf
	jsr print



	;Check CTRL-C
	jsr check_pressed
	bcs noquit_fpl_list

	jsr readchar ;Register keypress
	lda singlecharbuf
	cmp ctrl_c_chr ;CTRL-C
	bne noquit_fpl_list

	lda #<break_str
	sta ptr_low
	lda #>break_str
	sta ptr_high

	jsr mov_ptr_charbuf
	jsr print

	jsr number_zero
	lda linenum
	sta number
	lda linenum+1
	sta number+1
	jsr bin_to_dec

	lda #"."
	sta singlecharbuf
	jsr printchar
	

	pla
	sta PORTA3

	jmp command_done



noquit_fpl_list:

	lda linenum
	cmp linenummax
	bne fpl_list_printenter
	beq fpl_list_nextline

	lda linenum+1
	cmp linenummax+1
	beq fpl_list_nextline

fpl_list_printenter:
	lda #13
	sta singlecharbuf
	jsr printchar


fpl_list_nextline:
	lda linenum
	cmp linenummax
	bne fpl_list_loop_goaround

	lda linenum+1
	cmp linenummax+1
	bne fpl_list_loop_goaround


	pla
	sta PORTA3

	jmp command_done
	
fpl_list_loop_goaround:
	clc
	lda linenum
	adc #1
	sta linenum
	lda linenum+1
	adc #0
	sta linenum+1

	jmp fpl_list_loop

return_short27:
	jmp return

check_new:	
	lda command
	cmp #"n"
	bne return_short27
	lda command+1
	cmp #"e"
	bne return_short27
	lda command+2
	cmp #"w"
	bne return_short27

	jsr new_fpl

	jmp command_done

check_run:	
	lda command
	cmp #"r"
	bne return_short27
	lda command+1
	cmp #"u"
	bne return_short27
	lda command+2
	cmp #"n"
	bne return_short27

	stz linenum
	stz linenum+1
	stz linenum+2
	stz linenum+3

	lda #13
	sta singlecharbuf
	jsr printchar

	lda PORTA3
	pha

	stz PORTA3

	jsr new_variables

	jmp fpl_run_loop

fpl_run_nextline_short:
	jmp fpl_run_nextline

run_done:
	pla
	sta PORTA3
	jmp command_done

fpl_run_loop:
	jsr search_line
	bcs fpl_run_nextline_short

	lda searchptrbank
	sta PORTA3


	;Found line!

	ldy #3
	lda (searchptr),y
	bmi fpl_run_nextline_short ;Line is commented
	cmp token_comment
	beq fpl_run_nextline_short ;Comment
	cmp token_end
	beq run_done ;End programs
	sta command

	jsr result_zero

	lda #4
	sta result
	jsr searchptr_add

	jsr reset_param

	ldy #0
mov_param_run_loop:
	lda (searchptr),y
	sta param,y

	iny
	cpy #101 ;Make sure actually 100 bytes are copied.
	bne mov_param_run_loop

	;Check CTRL-C
	jsr check_pressed
	bcs noquit_fpl_run_first

	jsr readchar ;Register keypress
	lda singlecharbuf
	cmp ctrl_c_chr ;CTRL-C
	bne noquit_fpl_run_first

	lda #<break_str
	sta ptr_low
	lda #>break_str
	sta ptr_high

	jsr mov_ptr_charbuf
	jsr print

	jsr number_zero
	lda linenum
	sta number
	lda linenum+1
	sta number+1
	jsr bin_to_dec

	lda #"."
	sta singlecharbuf
	jsr printchar
	
fpl_run_done:
	pla
	sta PORTA3
	jmp command_done

noquit_fpl_run_first:







	;Check/run commands
	jsr run_print
	jsr run_goto
	jsr run_println
	jsr run_cls
	jsr run_int
	jsr run_str
	jsr run_input
	jsr run_if
	jsr run_float
	jsr run_add





	;Check CTRL-C
	jsr check_pressed
	bcs noquit_fpl_run

	jsr readchar ;Register keypress
	lda singlecharbuf
	cmp ctrl_c_chr ;CTRL-C
	bne noquit_fpl_run

	lda #<break_str
	sta ptr_low
	lda #>break_str
	sta ptr_high

	jsr mov_ptr_charbuf
	jsr print

	jsr number_zero
	lda linenum
	sta number
	lda linenum+1
	sta number+1
	jsr bin_to_dec

	lda #"."
	sta singlecharbuf
	jsr printchar
	
	
	jmp fpl_run_done

noquit_fpl_run:
	;;;;;

fpl_run_nextline:
	
	lda linenum
	cmp linenummax
	bne fpl_run_loop_goaround

	lda linenum+1
	cmp linenummax+1
	bne fpl_run_loop_goaround

	
	jmp fpl_run_done
	
fpl_run_loop_goaround:
	clc
	lda linenum
	adc #1
	sta linenum
	lda linenum+1
	adc #0
	sta linenum+1

	jmp fpl_run_loop



















