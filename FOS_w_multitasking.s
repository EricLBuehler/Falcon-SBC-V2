;FOS (FalconOS)
;Version 1.6
;November 2020 -
;Eric Buehler

;65c02s ASM
;Run: vasm6502_oldstyle -Fbin -dotdir -wdc02 "FOS.s" -o "FOS.bin"

;fcl pointer
fcl = $4 ; 2 bytes, ZP    |     This is the pointer to fcl


    .org $8000 ;Start of ROM in Falcon SBC memory map


	.include constants.s ;FOS constants and conditional assembly triggers
	.include labels.s ;Memory labels
	.include strings.s ;OS strings
	.include sd.s ;DOS subroutines
	.include io.s ;Hardware I/O subroutines
	.include string.s ;String operations
	.include memory.s ;Memory operations
	.include fcl.s ;Main FCL


;Note:
;BCC can be thought of "branch if less than" 
;BCS can be thought of "branch if greater or equal to"
;"string" is just a series of bytes that is null terminated.
;To change high RAM bank ($4000 - $5fff) write to PORTA3, or $6301 (25345). High bit is unused. Bit 6/7 MUST be 0 for the 512 kB of RAM configuration (1 mB planned as of 4/18/21)
;fcl variables cannot be deleted.

;Reset
reset:
	;Flags setup  
	clc
	cld
	cli

	;Init stack pointer
	ldx #$ff
	txs

	;Device init
	jsr deviceinit

	jsr cls

	;Initialize memory (done after device init so that highram bank can be switched)
	jsr meminit


	;Start multitasking
	ldx tasks
	inc tasks

	lda #<continue_boot
	sta task_codeptrlo,x
	lda #>continue_boot
	sta task_codeptrhi,x

	lda #<os_id
	sta task_idstrlo,x
	lda #>os_id
	sta task_idstrhi,x

	lda #<$3000
	sta task_stackptrlo,x
	lda #>$3000
	sta task_stackptrhi,x

	lda #0
	sta task_info,x


	txa
	tay

	tsx
	txa
	sta task_stackindex,y

	php
	pla
	sta task_s,x


	jsr clock_on ;Start clock

boot_waitloop:
	jmp boot_waitloop

continue_boot:
	;Init SD card
	jsr mount ;Mount sd card
	bcc mount_success_boot

	;Fail
	lda #<insert_sd
	sta ptr_low
	lda #>insert_sd
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jmp autoexec_notexists

mount_success_boot:
	;Load autoexec.exe
	lda #<autoexec
	sta ptra_low
	lda #>autoexec
	sta ptra_high
	lda #<param
	sta ptrb_low
	lda #>param
	sta ptrb_high
	jsr strcpy

	jsr close_file ;Close any open file
	jsr open_file ;Open autoexec.exe
	bcs autoexec_notexists

	jsr number_zero

	lda #$20
	sta number+1 ;Set autoexec load to 8192 ( $2000 )

	jsr load_file ;Load to $2000

	jsr $2000 ;Run program at $2000

autoexec_notexists:
	jsr close_file ;Close autoexec.exe

boot:

	;Boot
	jsr welcome_screen

	.ifdef PS2_ENABLED
	;NEW!
	lda PORTA1
	ora #%00001000 ;Bring PS2 controller out of reset
	sta PORTA1
	.endif

	jmp fdos;(fcl)







;FDOS
fdos:
	jsr mov_fdosstarted
	jsr print

	jsr terminal_prompt_dos

fdosloop:
	jsr input

	lda #32
	sta charpos
	jsr count
	lda count_out
	beq fdos_commandonly ;Zero
	bne fdos_commandparam_ ;Non zero

fdos_commandparam_:
	jsr parse
	jmp fdos_commandparam

fdos_commandonly:
	jsr reset_param
	jsr mov_charbuf_command

fdos_commandparam:
	jsr run_command

	jsr terminal_prompt_dos
	
	jmp fdosloop





;FMON: type monitor
fmon:
	jsr mov_fmonstarted
	jsr print
	jsr terminal_prompt
fmonloop:
	jsr input

	lda #32
	sta charpos
	jsr count
	lda count_out
	beq fmon_commandonly ;Zero
	bne fmon_commandparam_ ;Non zero

fmon_commandparam_:
	jsr parse
	jmp fmon_commandparam

fmon_commandonly:
	jsr reset_param
	jsr mov_charbuf_command

fmon_commandparam:
	jsr run_commandfmon

	jsr terminal_prompt
	
	jmp fmonloop


;FDOS command decoding and execution
run_command: 
	lda command
	bne not_enter_1

	rts
not_enter_1:

	stz cmddone

	jsr check_exit ;exit
	lda cmddone
	bne cmdfounda

	;DOS commands
	jsr check_mount ;TYPE: mou
	jsr check_open ;TYPE: op
	jsr check_close ;TYPE: cl
	jsr check_size ;TYPE: si
	jsr check_read ;TYPE: re
	jsr check_load ;TYPE: lo
	jsr check_save ;TYPE: sa
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

	;Other
	jsr check_fcl ;fcl
	jsr check_fmon ;monitor
	jsr check_dtbtest ;dtbtest
	jsr check_halt ;halt
	jsr check_reset ;reset
	jsr check_sys ;sys
	jsr check_time ;time
	jsr check_cls ;cls

	lda cmddone
	bne cmdfounda

	jsr mov_cmd_not_found
	jsr print

cmdfounda:
	rts

;FMON command decoding and execution
run_commandfmon: 
	lda command
	bne not_enter_2

	rts
not_enter_2:

	stz cmddone

	jsr check_exit ;exit
	jsr check_sys ;sys
	jsr check_poke ;poke
	jsr check_peek ;peek
	jsr check_dump ;dump
	jsr check_zero ;zero
	jsr check_copy ;copy
	jsr check_move ;move
	jsr check_bank ;bank
	jsr check_halt ;halt
	jsr check_reset ;reset
	jsr check_wai ;wai
	jsr check_printint ;printint
	jsr check_cls ;cls

	lda cmddone
	bne cmdfoundc

	jsr mov_cmd_not_found
	jsr print

cmdfoundc:
	rts




command_done:
	stz address_buf
	stz address_buf
	lda #1
	sta cmddone
	rts





check_fdos:
	lda command
	cmp #"f"
	bne return_short31
	lda command+1
	cmp #"d"
	bne return_short31
	lda command+2
	cmp #"o"
	bne return_short31
	lda command+3
	cmp #"s"
	bne return_short31

	;Pop off return address
	pla
	pla
	jmp fdos

return_short31:
	jmp return



return_short30:
	jmp return

check_bank:
	lda command
	cmp #"b"
	bne return_short30
	lda command+1
	cmp #"a"
	bne return_short30
	lda command+2
	cmp #"n"
	bne return_short30
	lda command+3
	cmp #"k"
	bne return_short30

	jsr mov_param_opbuf
	jsr dec_to_bin
	lda number
	sta PORTA3

	jmp command_done



return_short6:
	jmp return

check_exit:
	lda command
	cmp #"e"
	bne return_short6
	lda command+1
	cmp #"x"
	bne return_short6
	lda command+2
	cmp #"i"
	bne return_short6
	lda command+3
	cmp #"t"
	bne return_short6

	;Pop the return address off stack
	plx
	plx

	jmp (fcl) ;fdos

check_fcl:
	lda command
	cmp #"f"
	bne return_short6
	lda command+1
	cmp #"c"
	bne return_short6
	lda command+2
	cmp #"l"
	bne return_short6

	;Pop the return address off stack
	plx
	plx
	
	jmp (fcl)

check_fmon:
	lda command
	cmp #"m"
	bne return_short6
	lda command+1
	cmp #"o"
	bne return_short6
	lda command+2
	cmp #"n"
	bne return_short6
	lda command+3
	cmp #"i"
	bne return_short6
	lda command+4
	cmp #"t"
	bne return_short6
	lda command+5
	cmp #"o"
	bne return_short6
	lda command+6
	cmp #"r"
	bne return_short6

	;Pop the return address off stack
	plx
	plx

	jmp fmon

return_short26:
	jmp return

check_cls:
	lda command
	cmp #"c"
	bne return_short26
	lda command+1
	cmp #"l"
	bne return_short26
	lda command+2
	cmp #"s"
	bne return_short26

	jsr cls
	
	jmp command_done

check_appendbyte:
	lda command
	cmp #"a"
	bne return_short21
	lda command+1
	cmp #"p"
	bne return_short21
	lda command+2
	cmp #"b"
	bne return_short21

	jsr mov_param_opbuf

	jsr dec_to_bin

	jsr appendbyte
	
	jmp command_done

check_editbyte:
	lda command
	cmp #"e"
	bne return_short21
	lda command+1
	cmp #"d"
	bne return_short21
	lda command+2
	cmp #"b"
	bne return_short21

	jsr mov_param_opbuf

	jsr dec_to_bin

	jsr editbyte
	
	jmp command_done

check_readbyte:
	lda command
	cmp #"r"
	bne return_short21
	lda command+1
	cmp #"d"
	bne return_short21
	lda command+2
	cmp #"b"
	bne return_short21

	jsr readbyte

	lda #13
	sta singlecharbuf
	jsr printchar

	jsr bin_to_dec
	
	jmp command_done

check_seek:
	lda command
	cmp #"s"
	bne return_short21
	lda command+1
	cmp #"e"
	bne return_short21

	jsr mov_param_opbuf
	jsr dec_to_bin

	jsr seek
	
	jmp command_done

return_short21:
	jmp return


check_time:
	lda command
	cmp #"t"
	bne return_short21
	lda command+1
	cmp #"i"
	bne return_short21
	lda command+2
	cmp #"m"
	bne return_short21
	lda command+3
	cmp #"e"
	bne return_short21

	lda #13
	sta singlecharbuf
	jsr printchar

	jsr print_time

	jmp command_done


return_short23:
	jmp return


check_path:
	lda command
	cmp #"p"
	bne return_short23
	lda command+1
	cmp #"a"
	bne return_short23
	lda command+2

	lda #13
	sta singlecharbuf
	jsr printchar
	
	jsr path

	jsr mov_sdbuf
	jsr print

	jmp command_done

check_root:
	lda command
	cmp #"r"
	bne return_short23
	lda command+1
	cmp #"o"
	bne return_short23
	lda command+2

	jsr reset_param
	lda #"/"
	sta param	
	jsr cd

	jmp command_done

check_copydos:
	lda command
	cmp #"c"
	bne return_short23
	lda command+1
	cmp #"p"
	bne return_short23

	jsr copy_file ;Parameters in param

	bcc copydos_success_
	;Fail
	lda #<copy_fail
	sta ptr_low
	lda #>copy_fail
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

copydos_success_:

	jmp command_done

check_position:
	lda command
	cmp #"p"
	bne return_short18
	lda command+1
	cmp #"o"
	bne return_short18
	lda command+2

	jsr position
	
	lda #13
	sta singlecharbuf
	jsr printchar

	jsr bin_to_dec

	jmp command_done

check_exists:
	lda command
	cmp #"e"
	bne return_short18
	lda command+1
	cmp #"x"
	bne return_short18

	jsr open_file

	bcc filedirexist
	bcs filedirnoexist

filedirexist:
	;Fail
	lda #<file_exists
	sta ptr_low
	lda #>file_exists
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jsr close_file

	jmp exists_filedir_success

filedirnoexist:
	;Fail
	lda #<file_no_exists
	sta ptr_low
	lda #>file_no_exists
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	jmp exists_filedir_success

exists_filedir_success:

	jsr close_file

	jmp command_done

return_short18:
	jmp return


check_mount:
	lda command
	cmp #"m"
	bne return_short18
	lda command+1
	cmp #"o"
	bne return_short18
	lda command+2
	cmp #"u"
	bne return_short18


	jsr mount

	bcc mount_success_
	;Fail
	lda #<insert_sd
	sta ptr_low
	lda #>insert_sd
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

mount_success_:

	jmp command_done

check_open:
	lda command
	cmp #"o"
	bne return_short18
	lda command+1
	cmp #"p"
	bne return_short18


	jsr open_file

	bcc openfile_success_
	;Fail
	lda #<file_opening_error
	sta ptr_low
	lda #>file_opening_error
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

openfile_success_:

	jmp command_done

check_close:
	lda command
	cmp #"c"
	bne return_short18
	lda command+1
	cmp #"l"
	bne return_short18


	jsr close_file

	jmp command_done

check_size:
	lda command
	cmp #"s"
	bne return_short18
	lda command+1
	cmp #"i"
	bne return_short18

	jsr size_file

	lda #13
	sta singlecharbuf
	jsr printchar

	lda size_reg_0
	sta number
	lda size_reg_1
	sta number+1
	lda size_reg_2
	sta number+2
	lda size_reg_3
	sta number+3

	jsr bin_to_dec

	lda #<bytes
	sta ptr_low
	lda #>bytes
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	
	jmp command_done

return_short22:
	jmp return

check_read:
	lda command
	cmp #"r"
	bne return_short22
	lda command+1
	cmp #"e"
	bne return_short22
	lda command+2
	cmp #"a"
	bne return_short22


	jsr read_file

	jmp command_done

check_load:
	lda command
	cmp #"l"
	bne return_short22
	lda command+1
	cmp #"o"
	bne return_short22

	jsr number_zero

	jsr mov_param_opbuf
	jsr dec_to_bin

	jsr load_file

	jmp command_done

return_short19:
	jmp return

check_save:
	lda command
	cmp #"s"
	bne return_short19
	lda command+1
	cmp #"a"
	bne return_short19

	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high

	jsr strcpy

	lda #<charbuf
	sta ptr_low
	lda #>charbuf
	sta ptr_high

	lda #"," ;Char to search for

	jsr strtolist

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<param
	sta ptrb_low
	lda #>param
	sta ptrb_high

	;;;

	lda #0
	sta strindex_

	jsr strlistindex ;Address base

	jsr mov_param_opbuf
	jsr dec_to_bin

	lda number
	sta size_reg_0
	lda number+1
	sta size_reg_1
	lda number+2
	sta size_reg_2
	lda number+3
	sta size_reg_3

	;;;

	lda #1
	sta strindex_

	jsr strlistindex ;How many bytes to save?

	jsr mov_param_opbuf
	jsr dec_to_bin

	;Save on stack
	lda number
	sta number

	lda number+1
	sta number+1

	lda number+2
	sta number+2

	lda number+3
	sta number+3

	jsr save_file

	jmp command_done


check_printint:
	lda command
	cmp #"p"
	bne return_short20
	lda command+1
	cmp #"r"
	bne return_short20
	lda command+2
	cmp #"i"
	bne return_short20
	lda command+3
	cmp #"n"
	bne return_short20
	lda command+4
	cmp #"t"
	bne return_short20
	lda command+5
	cmp #"i"
	bne return_short20
	lda command+6
	cmp #"n"
	bne return_short20
	lda command+7
	cmp #"t"
	bne return_short20

	lda #13
	sta singlecharbuf
	jsr printchar

	lda param
	sta number
	jsr bin_to_dec

	jmp command_done

return_short20:
	jmp return

check_remove_file:
	lda command
	cmp #"r"
	bne return_short20
	lda command+1
	cmp #"m"
	bne return_short20
	lda command+2
	cmp #"f"
	bne return_short20

	jsr remove_file

	bcc remove_file_success_
	;Fail
	lda #<file_rm_error
	sta ptr_low
	lda #>file_rm_error
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

remove_file_success_:

	jmp command_done

check_remove_dir:
	lda command
	cmp #"r"
	bne return_short20
	lda command+1
	cmp #"m"
	bne return_short20
	lda command+2
	cmp #"d"
	bne return_short20

	jsr remove_dir


	bcc remove_dir_success_
	;Fail
	lda #<dir_rm_error
	sta ptr_low
	lda #>dir_rm_error
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

remove_dir_success_:

	jmp command_done

check_make_file:
	lda command
	cmp #"m"
	bne return_short20
	lda command+1
	cmp #"k"
	bne return_short20
	lda command+2
	cmp #"f"
	bne return_short20

	jsr make_file

	jmp command_done

check_make_dir:
	lda command
	cmp #"m"
	bne return_short16
	lda command+1
	cmp #"k"
	bne return_short16
	lda command+2
	cmp #"d"
	bne return_short16

	jsr make_dir

	jmp command_done

check_cd:
	lda command
	cmp #"c"
	bne return_short16
	lda command+1
	cmp #"d"
	bne return_short16

	jsr cd
	
	jmp command_done

check_list_dir:
	lda command
	cmp #"l"
	bne return_short16
	lda command+1
	cmp #"s"
	bne return_short16

	jsr list_dir
	
	jmp command_done

check_wai:
	lda command
	cmp #"w"
	bne return_short16
	lda command+1
	cmp #"a"
	bne return_short16
	lda command+2
	cmp #"i"
	bne return_short16

	wai
	
	jmp command_done

return_short16:
	jmp return


check_halt:
	lda command
	cmp #"h"
	bne return_short14
	lda command+1
	cmp #"a"
	bne return_short14
	lda command+2
	cmp #"l"
	bne return_short14
	lda command+3
	cmp #"t"
	bne return_short14

	stp ;STOP processor

return_short14:
	jmp return


check_reset:
	lda command
	cmp #"r"
	bne return_short14
	lda command+1
	cmp #"e"
	bne return_short14
	lda command+2
	cmp #"s"
	bne return_short14
	lda command+3
	cmp #"e"
	bne return_short14
	lda command+4
	cmp #"t"
	bne return_short14

	jmp reset

check_sys:
	lda command
	cmp #"s"
	bne return_short14
	lda command+1
	cmp #"y"
	bne return_short14
	lda command+2
	cmp #"s"
	bne return_short14

	jsr mov_param_opbuf

	jsr dec_to_bin

	lda result
	sta address_buf 
	lda result+1
	sta address_buf+1

	jsr jsr_indirect_go

	jmp command_done

jsr_indirect_go:
	jmp (address_buf)

check_zero:
	lda command
	cmp #"z"
	bne return_short14
	lda command+1
	cmp #"e"
	bne return_short14
	lda command+2
	cmp #"r"
	bne return_short14
	lda command+3
	cmp #"o"
	bne return_short14

	jsr mov_param_opbuf

	jsr dec_to_bin

	lda result
	sta address_buf 
	lda result+1
	sta address_buf+1

	lda #0
	sta (address_buf)

	jmp command_done

return_short13:
	jmp return

check_dump:
	lda command
	cmp #"d"
	bne return_short13
	lda command+1
	cmp #"u"
	bne return_short13
	lda command+2
	cmp #"m"
	bne return_short13
	lda command+3
	cmp #"p"
	bne return_short13

	stz parse_counter

	;dtb
	jsr reset_opbuf
	jsr mov_param_opbuf

	jsr dec_to_bin

	lda #13
	sta singlecharbuf
	jsr printchar

	jsr bin_to_dec

	lda #":"
	sta singlecharbuf
	jsr printchar


	;Big endian to little endian 
	lda number
	sta address_buf
	lda number+1
	sta address_buf+1

	jsr mathcounter_zero

	jmp dump_loop

return_short12:
	jmp return

command_done_short1:
	jmp command_done
	
dump_loop:
	ldy parse_counter
	lda (address_buf),y;$0,x
	jsr number_zero
	sta number

	lda #" " ;space
	sta singlecharbuf
	jsr printchar

	jsr bin_to_dec

	lda #" " ;space
	sta singlecharbuf
	jsr printchar

	lda number
	sta singlecharbuf
	ldx #0
	jsr printchar_printable

	inc parse_counter

	lda parse_counter 
	cmp #16
	beq command_done_short1

	jmp dump_loop


check_dtbtest:
	lda command
	cmp #"d"
	bne return_short7
	lda command+1
	cmp #"t"
	bne return_short7
	lda command+2
	cmp #"b"
	bne return_short7
	lda command+3
	cmp #"t"
	bne return_short7
	lda command+4
	cmp #"e"
	bne return_short7
	lda command+5
	cmp #"s"
	bne return_short7
	lda command+6
	cmp #"t"
	bne return_short7

	jsr reset_opbuf
	jsr mov_param_opbuf

	jsr dec_to_bin

	lda #13
	sta singlecharbuf
	jsr printchar

	jsr bin_to_dec

	jmp command_done_short1

return_short7:
	jmp return

check_poke:
	lda command
	cmp #"p"
	bne return_short7
	lda command+1
	cmp #"o"
	bne return_short7
	lda command+2
	cmp #"k"
	bne return_short7
	lda command+3
	cmp #"e"
	bne return_short7
	
	jsr reset_opbuf
	jsr number_zero

	lda #","
	sta chartofind
	jsr findallparam ;Find commas
	lda #","
	sta charpos 
	lda #0
	sta charpos_charnum
	jsr index_charparam
	lda charpos_location
	sta charsplit ;Save the first occurance of comma

addressparse_poke:
	stz counter1_parse

addressparse_poke_loop:
	lda counter1_parse
	cmp charsplit
	beq addressparse_poke_loopdone

	ldx counter1_parse
	lda param,x

	sta opbuf,x
	;sta singlecharbuf
	;jsr printchar

	inc counter1_parse

	jmp addressparse_poke_loop

addressparse_poke_loopdone:
	jsr dec_to_bin

	lda number
	sta address_buf
	lda number+1
	sta address_buf+1

dataparse_pokeparse:
	jsr reset_opbuf
	stz counter2_parse
	lda charsplit
	sta counter1_parse
	inc counter1_parse ;Move past space

dataparse_pokeparseloop:
	ldx counter1_parse
	lda param,x
	beq dataparse_pokeparsedone

	ldx counter2_parse
	sta opbuf,x
	;sta singlecharbuf
	;jsr printchar

	inc counter1_parse
	inc counter2_parse

	jmp dataparse_pokeparseloop

dataparse_pokeparsedone:
	jsr dec_to_bin
	lda number

	sta (address_buf)

	jmp command_done_short2

command_done_short2:
	jmp command_done

check_peek:
	lda command
	cmp #"p"
	bne return_short3
	lda command+1
	cmp #"e"
	bne return_short3
	lda command+2
	cmp #"e"
	bne return_short3
	lda command+3
	cmp #"k"
	bne return_short3
	
	jsr reset_opbuf
	jsr mov_param_opbuf

	jsr dec_to_bin

	lda result
	sta address_buf
	lda result+1
	sta address_buf+1

	jsr number_zero
	lda (address_buf)
	sta number

	lda #13
	sta singlecharbuf
	jsr printchar

	jsr bin_to_dec
	
	jmp command_done_short2

return_short3:
	jmp return

check_copy:
	lda command
	cmp #"c"
	bne return_short3
	lda command+1
	cmp #"o"
	bne return_short3
	lda command+2
	cmp #"p"
	bne return_short3
	lda command+3
	cmp #"y"
	bne return_short3

	
	jsr reset_opbuf
	jsr number_zero

	lda #","
	sta chartofind
	jsr findallparam ;Find commas
	lda #","
	sta charpos 
	lda #0
	sta charpos_charnum
	jsr index_charparam
	lda charpos_location
	sta charsplit ;Save the first occurance of comma

address1parse_copy:
	stz counter1_parse

address1parse_copy_loop:
	lda counter1_parse
	cmp charsplit
	beq address1parse_copy_loopdone

	ldx counter1_parse
	lda param,x

	sta opbuf,x
	;sta singlecharbuf
	;jsr printchar

	inc counter1_parse

	jmp address1parse_copy_loop

address1parse_copy_loopdone:
	jsr dec_to_bin

	lda number
	sta address_buf
	lda number+1
	sta address_buf+1

address2parse_copyparse:
	jsr reset_opbuf
	stz counter2_parse
	lda charsplit
	sta counter1_parse
	inc counter1_parse ;Move past space

address2parse_copyparseloop:
	ldx counter1_parse
	lda param,x
	beq address2parse_copyparsedone

	ldx counter2_parse
	sta opbuf,x
	;sta singlecharbuf
	;jsr printchar

	inc counter1_parse
	inc counter2_parse

	jmp address2parse_copyparseloop

address2parse_copyparsedone:
	jsr number_zero
	lda (address_buf) ;Load 
	sta cpymve_buf

	jsr dec_to_bin
	lda number
	sta address_buf
	lda number+1
	sta address_buf+1

	lda cpymve_buf
	sta (address_buf)

	jmp command_done_short2

return_short15:
	jmp return

check_move:
	lda command
	cmp #"m"
	bne return_short15
	lda command+1
	cmp #"o"
	bne return_short15
	lda command+2
	cmp #"v"
	bne return_short15
	lda command+3
	cmp #"e"
	bne return_short15


	
	jsr reset_opbuf
	jsr number_zero

	lda #","
	sta chartofind
	jsr findallparam ;Find commas
	lda #","
	sta charpos 
	lda #0
	sta charpos_charnum
	jsr index_charparam
	lda charpos_location
	sta charsplit ;Save the first occurance of comma

address1parse_mov:
	stz counter1_parse

address1parse_mov_loop:
	lda counter1_parse
	cmp charsplit
	beq address1parse_mov_loopdone

	ldx counter1_parse
	lda param,x

	sta opbuf,x
	;sta singlecharbuf
	;jsr printchar

	inc counter1_parse

	jmp address1parse_mov_loop

address1parse_mov_loopdone:
	jsr dec_to_bin

	lda number
	sta address_buf
	lda number+1
	sta address_buf+1

address2parse_movparse:
	jsr reset_opbuf
	stz counter2_parse
	lda charsplit
	sta counter1_parse
	inc counter1_parse ;Move past space

address2parse_movparseloop:
	ldx counter1_parse
	lda param,x
	beq address2parse_movparsedone

	ldx counter2_parse
	sta opbuf,x
	;sta singlecharbuf
	;jsr printchar

	inc counter1_parse
	inc counter2_parse

	jmp address2parse_movparseloop

address2parse_movparsedone:
	jsr number_zero
	lda (address_buf) ;Load 
	sta cpymve_buf
	lda #0
	sta (address_buf)

	jsr dec_to_bin
	lda number
	sta address_buf
	lda number+1
	sta address_buf+1

	lda cpymve_buf
	sta (address_buf)

	jmp command_done_short2




























;CLOS underlying functions (Eric was here 2/16/21 and knows that CLOS was the name used here!)




;Math subroutines

return_short5:
	jmp return

decrement:
	sec
	lda mathcounter
	sbc #1
	sta mathcounter
	lda mathcounter+1
	sbc #0
	sta mathcounter+1
	lda mathcounter+2
	sbc #0
	sta mathcounter+2
	lda mathcounter+3
	sbc #0
	sta mathcounter+3
	rts


increment: ;Do not use inc for 16 bit or beyond.
	clc
    lda mathcounter
    adc #1
    sta mathcounter
    lda mathcounter+1
    adc #0
    sta mathcounter+1
	lda mathcounter+2
    adc #0
    sta mathcounter+2
	lda mathcounter+3
    adc #0
    sta mathcounter+3

	

    rts


add:
	clc
    lda num1
    adc num2
    sta result
    lda num1+1
    adc num2+1
    sta result+1
	lda num1+2
    adc num2+2
    sta result+2
	lda num1+3
    adc num2+3
    sta result+3

	

    rts

subtract:
	sec
    lda num1
    sbc num2
    sta result
    lda num1+1
	sbc num2+1
    sta result+1
	lda num1+2
    sbc num2+2
    sta result+2
	lda num1+3
    sbc num2+3
    sta result+3

	

    rts

multiply_32:  
	lda     #$00
	sta     result+4   ;Clear upper half of
	sta     result+5   ;resultuct
	sta     result+6
	sta     result+7
	ldx     #$20     ;Set binary count to 32
shift_r:   
	lsr     num1+3   ;Shift multiplyer right
	ror     num1+2
	ror     num1+1
	ror     num1
	bcc     rotate_r ;Go rotate right if c = 0
	lda     result+4   ;Get upper half of resultuct
	clc              ; and add multiplicand to
	adc     num2    ; it
	sta     result+4
	lda     result+5
	adc     num2+1
	sta     result+5
	lda     result+6
	adc     num2+2
	sta     result+6
	lda     result+7
	adc     num2+3
rotate_r:  
	ror     a        ;Rotate partial resultuct
	sta     result+7   ; right
	ror     result+6
	ror     result+5
	ror     result+4
	ror     result+3
	ror     result+2
	ror     result+1
	ror     result
	dex              ;Decrement bit count and
	bne     shift_r  ; loop until 32 bits are
	clc              ; done
	lda     mulxp1   ;Add dps and put sum in mulxp2
	adc     mulxp2
	sta     mulxp2
	rts

multiply:
	lda #0       ;Initialize RESULT to 0
    sta result+2
    ldx #16      ;There are 16 bits in NUM2
L1_mul:
	lsr num2+1   ;Get low bit of NUM2
    ror num2
    bcc L2_mul   ;0 or 1?
    tay          ;If 1, add NUM1 (hi byte of RESULT is in A)
    clc
    lda num1
    adc result+2
    sta result+2
    tya
    adc num1+1
L2_mul:
	ror a        ;"Stairstep" shift
    ror result+2
    ror result+1
    ror result
    dex
    bne L1_mul
    sta result+3

    rts

divide:
	lda #0      ;Initialize REM to 0
    sta remainder
    sta remainder+1
    ldx #16     ;There are 16 bits in NUM1
L1_div:
	asl num1    ;Shift hi bit of NUM1 into REM
    rol num1+1  ;(vacating the lo bit, which will be used for the quotient)
    rol remainder
    rol remainder+1
    lda remainder
    sec         ;Trial subtraction
    sbc num2
    tay
    lda remainder+1
    sbc num2+1
    bcc L2_div  ;Did subtraction succeed?
    sta remainder+1   ;If yes, save it
    sty remainder
    inc num1    ;and record a 1 in the quotient
L2_div:
	dex
    bne L1_div

	lda num1
	sta result
	lda num1+1
	sta result+1

	rts

;Parse
;Registers edited: A,X
parse:
	jsr reset_command
	jsr reset_param

	lda #32
	sta chartofind
	jsr findall ;Find spaces
	lda #32
	sta charpos
	lda #0
	sta charpos_charnum ;Find first occurance of space
	jsr index_char
	lda charpos_location
	sta charsplit ;Save the first occurance of space

cmdparse:
	stz counter1_parse

cmdloop:
	lda counter1_parse
	cmp charsplit
	beq cmdloopdone

	ldx counter1_parse
	lda charbuf,x

	;sta singlecharbuf
	;jsr printchar
	sta command,x

	inc counter1_parse

	jmp cmdloop

cmdloopdone:
	jmp paramparse

paramparse:
	stz counter2_parse
	lda charsplit
	sta counter1_parse
	inc counter1_parse ;Move past space

paramloop:
	ldx counter1_parse
	lda charbuf,x
	;sta singlecharbuf
	;jsr printchar
	beq paramloopdone

	ldx counter2_parse
	sta param,x

	inc counter1_parse
	inc counter2_parse

	jmp paramloop

paramloopdone:
	rts

;parseparam
;Registers edited: A,X
;Input: chartofind and charpos_charnum
parseparam:
	lda #",";32
	sta chartofind
	jsr findallparam ;Find spaces
	lda chartofind
	sta charpos
	jsr index_charparam
	lda charpos_location
	sta charsplit ;Save the first occurance of space

cmdparseparam:
	stz counter1_parse

cmdloopparam:
	lda counter1_parse
	cmp charsplit
	beq cmdloopdoneparam

	ldy counter1_parse
	lda param,y;(ptr_low),y
	sta command,y;(ptra_low),y

	inc counter1_parse

	jmp cmdloopparam

cmdloopdoneparam:
	jmp paramparseparam

paramparseparam:
	stz counter2_parse
	lda charsplit
	sta counter1_parse
	inc counter1_parse ;Move past space

paramloopparam:
	ldy counter1_parse
	lda param,y;(ptr_low),y

	beq paramloopdoneparam

	ldy counter2_parse
	sta opbuf,y;(ptrb_low),y

	inc counter1_parse
	inc counter2_parse

	jmp paramloopparam

paramloopdoneparam:
	
	rts


;dec_to_bin
;Registers edited: A,X and stack
;Converts an ascii representation of an 32bit unsigned integer to its 32 bit binary representation.
dec_to_bin:
	jsr lengthopbuf

	lda #1
	sta dtb_mulby
	stz dtb_mulby+1
	stz dtb_mulby+2
	stz dtb_mulby+3


	stz dtb_valuea
	stz dtb_valuea+1
	stz dtb_valuea+2
	stz dtb_valuea+3

	stz convert_counter

	dec length
	lda length
	sta dtb_charcounter

dec_to_bin_loopa:
	ldy dtb_charcounter
	lda opbuf,y
	beq dec_to_bin_done_short
	sec
	sbc #"0"
	sta num1

	lda dtb_mulby
	sta num2
	lda dtb_mulby+1
	sta num2+1
	lda dtb_mulby+2
	sta num2+2
	lda dtb_mulby+3
	sta num2+3

	jsr multiply_32	

	jmp dtb_bridge

dec_to_bin_done_short:
	jmp dec_to_bin_done

dtb_bridge:
	lda result
	sta num1
	lda result+1
	sta num1+1
	lda result+2
	sta num1+2
	lda result+3
	sta num1+3

	lda dtb_valuea
	sta num2
	lda dtb_valuea+1
	sta num2+1
	lda dtb_valuea+2
	sta num2+2
	lda dtb_valuea+3
	sta num2+3

	jsr add

	lda result
	sta dtb_valuea
	lda result+1
	sta dtb_valuea+1
	lda result+2
	sta dtb_valuea+2
	lda result+3
	sta dtb_valuea+3


	;Multiply dtb_mulby by 10

	jsr num1_zero
	jsr num2_zero

	lda dtb_mulby
	sta num1
	lda dtb_mulby+1
	sta num1+1
	lda dtb_mulby+2
	sta num1+2
	lda dtb_mulby+2
	sta num1+2

	
	lda #10
	sta num2

	jsr multiply_32

	lda result
	sta dtb_mulby
	lda result+1
	sta dtb_mulby+1
	lda result+2
	sta dtb_mulby+2
	lda result+3
	sta dtb_mulby+3

	lda dtb_charcounter
	beq dec_to_bin_done
	dec dtb_charcounter
	jmp dec_to_bin_loopa

dec_to_bin_done:
	lda dtb_valuea
	sta number
	sta result
	lda dtb_valuea+1
	sta number+1
	sta result+1
	lda dtb_valuea+2
	sta number+2
	sta result+2
	lda dtb_valuea+3
	sta number+3
	sta result+3

	rts



;bin_to_dec
;Registers edited: A,Y,X and stack
;Prints out a 32 bit binary string.
bin_to_dec:
	;init string
	lda #0
	sta message_out

	;init value
	lda number 
	sta value 
	lda number+1
	sta value+1 
	lda number+2
	sta value+2
	lda number+3
	sta value+3

divide_btd:
	stz mod10 ;set lower byte of mod10 to 0
	stz mod10+1 
	stz mod10+2 
	stz mod10+3 
	clc

	ldx #32

divloop:
	rol value
	rol value+1
	rol value+2
	rol value+3
	rol mod10
	rol mod10+1
	rol mod10+2
	rol mod10+3

	sec
	lda mod10 
	sbc #10
	sta b1 ;save low byte 
	lda mod10+1
	sbc #0
	sta b2
	lda mod10+2
	sbc #0
	sta b3
	lda mod10+3
	sbc #0
	sta b4

	bcc ignore_result ;branching if dividend < divisor
	lda b1
	sta mod10
	lda b2
	sta mod10+1
	lda b3
	sta mod10+2
	lda b4
	sta mod10+3

	jmp ignore_result

divide_short:
	jmp divide_btd

ignore_result:
	dex
	bne divloop ;if not 0, then repeat process

	;if done:
	rol value
	rol value+1
	rol value+2
	rol value+3

	lda mod10
	clc
	adc #"0" ;number will be an ascii.

	;sta singlecharbuf
	;jsr printchar

	jsr push_char

	;if value!= 0, continue dividing.
	lda value
	ora value+1
	ora value+2
	ora value+3
	bne divide_short ;branch if a register is not 0

    stz convert_counter
print_number:
	ldx convert_counter
    lda message_out,x
    beq return_short4 ;if we have reached the null char (end) return from bin to decimal subroutine)
    sta singlecharbuf
	jsr printchar
    inc convert_counter
    jmp print_number


;add char in a register to beginning of null-terminated string.
push_char:
	pha ;push new first char onto stack
	ldy #0
char_loop:
	lda message_out,y ;get char from string and put into x
	tax
	pla 
	sta message_out,y ;pull char off stack and add it to the string
	iny 
	txa
	pha ;push char from string onto stack
	bne char_loop

	pla
	sta message_out,y ;pull null of the stack and add to end of string

	rts

;print
;Registers edited: A,X,Y and stack
;To print is in charbuf and must be null terminated.
print:
	lda #0
	sta charcounter

print_loop:
	ldy charcounter
	lda charbuf,y
	beq return_short4

	cmp #92 ; Backslash
	beq print_escape

	sta singlecharbuf
	jsr printchar

	inc charcounter

	jmp print_loop

return_short4:
	jmp return

print_escape:
	inc charcounter

	ldy charcounter
	lda charbuf,y

	cmp #"n"
	bne tab
	lda #13 ;newline
	sta singlecharbuf
	jsr printchar

	inc charcounter

	jmp print_loop

tab:
	cmp #"t"
	bne backslash
	lda #9 ;tab
	sta singlecharbuf
	jsr printchar

	inc charcounter

	jmp print_loop

backslash:
	cmp #"\"
	bne escape_not_found_print
	lda #92 ;backslash
	sta singlecharbuf
	jsr printchar

	inc charcounter

	jmp print_loop

escape_not_found_print:
	dec charcounter

	ldy charcounter
	lda charbuf,y
	sta singlecharbuf
	jsr printchar

	inc charcounter
	jmp print_loop

;input
;Registers edited: A,X,Y and stack
;input a series of bytes from readchar to charbuf. Enter exits
input: 
	lda #0
	sta charcounter

	stz singlecharbuf

	jsr reset_charbuf
input_loop:
	jsr readchar
	lda singlecharbuf
	
	cmp #13 ;Enter
	beq input_return

	cmp #127 ;backspace
	beq input_backspace

	jsr printchar

	ldx charcounter
	lda singlecharbuf
	sta charbuf,x

	inc charcounter
	jmp input_loop

input_return:
	lda charcounter
	tax
	stz charbuf,x
	jmp return

return_short1:
	jmp return

input_backspace:
	lda charcounter
	beq input_loop ;If position is 0, do not backspace

	jsr printchar

	dec charcounter

	ldx charcounter
	stz charbuf,x

	jmp input_loop


;UTILS: 

;Accurate delays

;increment_uptime
;No registers edited
increment_uptime:
	clc
	lda uptime
	adc #1
	sta uptime

	lda uptime+1
	adc #0
	sta uptime+1
	
	lda uptime+2
	adc #0
	sta uptime+2
	
	lda uptime+3
	adc #0
	sta uptime+3
	
	lda uptime+4
	adc #0
	sta uptime+4

	lda uptime+5
	adc #0
	sta uptime+5

	lda uptime+6
	adc #0
	sta uptime+6

	lda uptime+7
	adc #0
	sta uptime+7
	rts

;delay_ms
;Registers edited: A
;Delay in MS in number
;2^32 ms max delay (~49.7 days)
delay_ms:
	clc
	lda uptime
	adc number
	sta uptimebuf

	lda uptime+1
	adc number+1
	sta uptimebuf+1
	
	lda uptime+2
	adc number+2
	sta uptimebuf+2
	
	lda uptime+3
	adc number+3
	sta uptimebuf+3
	
	lda uptime+4
	adc #0
	sta uptimebuf+4

	lda uptime+5
	adc #0
	sta uptimebuf+5

	lda uptime+6
	adc #0
	sta uptimebuf+6

	lda uptime+7
	adc #0
	sta uptimebuf+7

delay_ms_loop:
	lda uptime
	cmp uptimebuf
	bne delay_ms_loop

	lda uptime+1
	cmp uptimebuf+1
	bne delay_ms_loop
	
	lda uptime+2
	cmp uptimebuf+2
	bne delay_ms_loop
	
	lda uptime+3
	cmp uptimebuf+3
	bne delay_ms_loop
	
	lda uptime+4
	cmp uptimebuf+4
	bne delay_ms_loop
	
	lda uptime+5
	cmp uptimebuf+5
	bne delay_ms_loop
	
	lda uptime+6
	cmp uptimebuf+6
	bne delay_ms_loop
	
	lda uptime+7
	cmp uptimebuf+7
	bne delay_ms_loop

	rts



;Screen Out

;printchar_printable
;Registers edited: A, X
;Character to print when character is not printable should be in X
;Character to print is in singlecharbuf
printchar_printable:
	lda singlecharbuf

	clc
	cmp #" "
	bcc not_printable ;Less than

	cmp #127 ;Backspace
	bcs not_printable ;Greater or equal to

	jsr printchar

	rts

not_printable:
	stx singlecharbuf
	jsr printchar

	rts

;Clock routines
;See io.s for clock on/off

;reset_clock
;No registers edited.
reset_clock:
	jsr milliseconds_zero
	stz seconds
	stz minutes
	stz hours
	stz days

	rts

;print_time_all
;Registers edited: A
;Format
;DAYS:HOURS:MINUTES:SECONDS:MILLISECONDS
print_time_all:
	jsr number_zero

	lda days
	sta number
	jsr bin_to_dec

	lda #":"
	sta singlecharbuf
	jsr printchar

	lda hours
	sta number
	jsr bin_to_dec

	lda #":"
	sta singlecharbuf
	jsr printchar

	lda minutes
	sta number
	jsr bin_to_dec

	lda #":"
	sta singlecharbuf
	jsr printchar

	lda seconds
	sta number
	jsr bin_to_dec

	lda #":"
	sta singlecharbuf
	jsr printchar

	lda milliseconds
	sta number
	lda milliseconds+1
	sta number+1
	jsr bin_to_dec

	rts

;print_time
;Registers edited: A
;Format
;DAYS:HOURS:MINUTES:SECONDS
print_time:
	jsr number_zero

	lda days
	sta number
	jsr bin_to_dec

	lda #":"
	sta singlecharbuf
	jsr printchar

	lda hours
	sta number
	jsr bin_to_dec

	lda #":"
	sta singlecharbuf
	jsr printchar

	lda minutes
	sta number
	jsr bin_to_dec

	lda #":"
	sta singlecharbuf
	jsr printchar

	lda seconds
	sta number
	jsr bin_to_dec

	rts



;lengthparam
;Registers edited: A,X
lengthparam:
	ldx #0

lengthloop:
	lda param,x
	beq length_finished ;Null, then return

	inx
	jmp lengthloop

length_finished:
	stx length
	rts	

;lengthbuf
;Registers edited: A,X
lengthsdbuf:
	ldx #0

lengthsdbufloop:
	lda sdbuf,x
	beq lengthsdbuf_finished ;Null, then return

	inx
	jmp lengthsdbufloop

lengthsdbuf_finished:
	stx length
	rts	

;lengthopbuf
;Registers edited: A,X
lengthopbuf:
	ldx #0

lengthopbufloop:
	lda opbuf,x
	beq lengthopbuf_finished ;Null, then return

	inx
	jmp lengthopbufloop

lengthopbuf_finished:
	stx length
	rts	

;lengthcharbuf
;Registers edited: A,X
lengthcharbuf:
	ldx #0

lengthcharbufloop:
	lda charbuf,x
	beq lengthcharbuf_finished ;Null, then return

	inx
	jmp lengthcharbufloop

lengthcharbuf_finished:
	stx length
	rts	


;findall
;Registers edited: A,X
findall:
	ldx #0

findallloop:
	lda charbuf,x
	beq return_short2 ;Null, then return
	cmp chartofind
	beq found_findall

	lda #0
	sta charfindflags,x

	cpx #255
	beq return_short2

	inx
	jmp findallloop

found_findall:
	lda #1
	sta charfindflags,x

	cpx #255
	beq return_short2

	inx
	jmp findallloop

return_short2:
	jmp return

;index_char
;Registers edited: A,X,Y
index_char:
	lda charpos
	sta chartofind
	jsr findall ;Make sure there is something to 'find'
	
	ldx #0 ;Char
	ldy #0 ;Chars found

index_char_loop:
	lda charbuf,x
	beq return_short2 ;Null, then return

	lda charfindflags,x
	cmp #1
	beq found_char

	cpx #255
	beq return_short2

	inx
	jmp index_char_loop

found_char:
	cpy charpos_charnum
	beq index_char_position_found

	iny

	inx
	jmp index_char_loop

index_char_position_found:
	stx charpos_location
	rts	

;findallparam
;Registers edited: A,X
findallparam:
	ldx #0

findallparamloop:
	lda param,x
	beq return_short2 ;Null, then return
	cmp chartofind
	beq found_findallparam

	lda #0
	sta charfindflags,x

	cpx #255
	beq return_short2

	inx
	jmp findallparamloop

found_findallparam:
	lda #1
	sta charfindflags,x

	cpx #255
	beq return_short2

	inx
	jmp findallparamloop

;index_charparam
;Registers edited: A,X,Y
index_charparam:
	lda charpos
	sta chartofind
	jsr findallparam ;Make sure there is something to 'find'
	
	ldx #0 ;Char
	ldy #0 ;Chars found

index_charparam_loop:
	lda param,x
	beq return_short2 ;Null, then return

	lda charfindflags,x
	cmp #1
	beq found_charparam

	cpx #255
	beq return_short2

	inx
	jmp index_charparam_loop

found_charparam:
	cpy charpos_charnum
	beq index_char_position_found

	iny

	inx
	jmp index_charparam_loop

index_charparam_position_found:
	stx charpos_location
	rts


;count
;Registers edited: A,X
;charbuf is input
count:
	lda charpos
	sta chartofind
	jsr findall ;Make sure there is something to 'find'
	
	ldx #0 ;Char
	stz count_out

count_loop:
	lda charbuf,x
	beq return_short11 ;Null, then return

	lda charfindflags,x
	cmp #1
	beq found_charcount

	cpx #255
	beq return_short11

	inx
	jmp count_loop

found_charcount:
	inc count_out
	inx
	jmp count_loop

return_short11:
	jmp return

;terminal_prompt_dos
;Registers edited: A
terminal_prompt_dos:
	lda #13
	sta singlecharbuf
	jsr printchar

	;Print out cwd
	jsr path
	jsr mov_sdbuf
	jsr print

	lda #">"
	sta singlecharbuf
	jsr printchar
	lda #" "
	sta singlecharbuf
	jsr printchar
	rts


;terminal_prompt
;Registers edited: A
terminal_prompt:
	lda #13
	sta singlecharbuf
	jsr printchar
	lda #">"
	sta singlecharbuf
	jsr printchar
	lda #" "
	sta singlecharbuf
	jsr printchar
	rts

;welcome_screen
;Registers edited: A,X,Y
welcome_screen:
	jsr reset_charbuf
	jsr mov_welcome
	jsr print

	lda #<ram_amount
	sta ptr_low
	lda #>ram_amount
	sta ptr_high

	jsr mov_ptr_charbuf
	jsr print

	;jsr terminal_prompt

	rts




;delay
;Registers edited: X,Y
delay:
	dex
	bne delay
	dey
	bne delay
	rts

return:
	rts




nmi:
	rti


	pha
	phx
	phy
	php
	jmp nmi_done

nmi_done:
	plp
	ply
	plx
	pla
	rti

jsr_indirect_irq:
	jmp (address_buf)

irq:
	;BRK instruction
	;1) Push high byte of return address
	;2) Push low byte of return address
	;3) Push processor status

	;RTI instruction
	;1) Pull processor status
	;2) Pull low byte of return address
	;3) Pull high byte of return address

	pha
	phx
	phy
	php

	;VIA 1 Interrupts

	jmp no_sr_irq

	;Shift register interrupt
	lda IFR1
	and #%10000100
	cmp #%10000100
	beq sr_irq_short

no_sr_irq:
	;Timer 1 interrupt
	lda IFR1
	and #%11000000
	cmp #%11000000
	beq t1_1_irq

	jsr jsr_indirect_irq ;User IRQ. If USR IRQ routine finds an interrupt, it MUST pop the return address of the stack (pla, pla), handle the interrupt and jump to irq_done.

	jmp irq_done

;IRQ BRIDGES HERE
irq_done:
	plp
	ply
	plx
	pla
	rti

sr_irq_short:
	jmp sr_irq

t1_1_irq:
	lda T1CL1 ;Clear the Timer 1 flag

	sei

	jsr clock_off

	;Context switch
	ldx current_task

	;OLD task

	;Save a,x,y
	pla ;S

	pla ;Y
	sta task_y,x
	pla ;X
	sta task_x,x
	pla ;A
	sta task_a,x

	;Pull S
	pla
	sta task_s,x

	;Pull PC lo
	pla
	sta task_codeptrlo,x

	;Pull PC hi
	pla
	sta task_codeptrhi,x


	;Get stack index
	phx

	tsx
	txa

	plx

	sta task_stackindex,x



	;Copy OLD stack out
	lda task_stackptrlo,x
	sta cntx_swtch_ptr
	lda task_stackptrhi,x
	sta cntx_swtch_ptr+1

	ldy #0
copy_stack_out_cntxswtch:
	lda $100,y
	sta (cntx_swtch_ptr),y

	iny

	cpy #0
	bne copy_stack_out_cntxswtch

	;;;


	;Check max tasks
	inc current_task
	lda current_task
	cmp tasks
	bne lt_tasks_max

	stz current_task

lt_tasks_max:
	;NEW task
	ldx current_task

	;Copy NEW stack in	

	lda task_stackptrlo,x
	sta cntx_swtch_ptr
	lda task_stackptrhi,x
	sta cntx_swtch_ptr+1

	ldy #0
copy_stack_in_cntxswtch:
	lda (cntx_swtch_ptr),y
	sta $100,y

	iny

	cpy #0
	bne copy_stack_in_cntxswtch

	;;;

	;Setup new stack pointer
	phx

	lda task_stackindex,x
	tax
	txs
	
	plx


	;Push hi
	lda task_codeptrhi,x
	pha
	;Push lo
	lda task_codeptrlo,x
	pha
	;Push s
	lda task_s,x
	pha


	;Restore a,x,y
	lda task_y,x
	pha
	lda task_x,x
	pha
	lda task_a,x
	pha

	jsr clock_on
	
	cli


	jsr increment_uptime

	clc
    lda milliseconds
    adc #1
    sta milliseconds
    lda milliseconds+1
    adc #0
    sta milliseconds+1

	lda milliseconds
	cmp #%11101000 ;Low byte of 1000
	bne irq_done_simple

	lda milliseconds+1
	cmp #%00000011 ;High byte of 1000
	bne irq_done_simple
	
	inc seconds

	jsr milliseconds_zero

	lda seconds
	cmp #60
	bne irq_done_simple

	inc minutes

	stz seconds

	lda minutes
	cmp #60
	bne irq_done_simple

	inc hours

	stz minutes

	lda hours
	cmp #24
	bne irq_done_simple

	inc days

	stz hours

	jmp irq_done_simple

irq_done_simple:
	pla
	plx
	ply

	rti

sr_irq:
	;Set bit 1, interrupt flag
	lda srflags
	ora #2 ; bit 1
	sta srflags

	;Check if R/W
	lda srflags
	and #1 ;Mask out bottom bit
	cmp #0
	beq sr_irq_r ;A register = 0

	;Otherwise, we were writing.

	stz SR1 ;Clear interrupt
	jmp irq_done

sr_irq_r:
	lda SR1 ;Clear interrupt
	sta srbuf
	jmp irq_done


	.org $fffa
	.word nmi
	.word reset
	.word irq