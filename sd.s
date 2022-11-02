;SD library
;Developed by Eric Buehler Janurary - March 2021
;Interfaces an AtMega to the 6502

;Uses carry flag to indicate whether operation was succesful.


;Ways I have tried to interface the coprocessor
;Started to interface in December 2020
;Completed April 2021
;PARALLEL
; 1) Parallel interface (Used VIA chip)
; 5) DMA (Now)
;SERIAL
; 2) I2C
; 3) SPI
; 4) Hardware shift register


;DOS underlying functions


;Max command number: 25

;appendbyte
;Registers edited: A
;Byte to poke is in number
appendbyte:
	jsr clock_off
	jsr check_inserted
	beq appendbyte_insert_sd

	lda #1
	sta op_result_reg

	lda #25
	jsr send_command

	jmp appendbyte_done
appendbyte_insert_sd:
	sec
appendbyte_done:
	jsr clock_on
	rts


;editbyte
;Registers edited: A
;Byte to poke is in param 
editbyte:
	jsr clock_off
	jsr check_inserted
	beq editbyte_insert_sd

	lda #1
	sta op_result_reg

	lda #24
	jsr send_command

	jmp editbyte_done
editbyte_insert_sd:
	sec
editbyte_done:
	jsr clock_on
	rts

;copy_file
;Registers edited: A
;Returns 1 if fail, 0 if success in carry
copy_file:
	jsr clock_off
	jsr check_inserted
	beq copy_file_insert_sdshort

	jmp copy_file_brige
copy_file_insert_sdshort:
	jmp copy_file_insert_sd

copy_file_brige:

	lda #1
	sta op_result_reg
	
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

	jsr number_zero

	;;;;;

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<param
	sta ptrb_low
	lda #>param
	sta ptrb_high

	lda #0
	sta strindex_

	jsr strlistindex

	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	jsr strlen
	lda length
	sta number

	;;;;;

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	lda #1
	sta strindex_

	jsr strlistindex

	lda #<command
	sta ptr_low
	lda #>command
	sta ptr_high

	jsr strlen
	lda length
	sta number+1


	;;;;;

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	lda #2
	sta strindex_

	jsr strlistindex

	lda #<sdbuf
	sta ptr_low
	lda #>sdbuf
	sta ptr_high

	jsr strlen
	lda length
	sta number+2



	;;;;;

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	lda #3
	sta strindex_

	jsr strlistindex

	lda #<opbuf
	sta ptr_low
	lda #>opbuf
	sta ptr_high

	jsr strlen
	lda length
	sta number+3


	;Actual copy here:
	lda #26
	jsr send_command ;Copy files, With path <- I think this is a pretty cool feature!

	lda op_result_reg
	ror ;Move result into carry

	jmp copy_file_done
copy_file_insert_sd:
	sec
copy_file_done:
	jsr clock_on
	rts

;readbyte
;Registers edited: A
;Byte returned in number
readbyte:
	jsr clock_off
	jsr check_inserted
	beq readbyte_insert_sd

	lda #1
	sta op_result_reg

	jsr number_zero

	lda #23
	jsr send_command

	jmp readbyte_done
readbyte_insert_sd:
	sec
readbyte_done:
	jsr clock_on
	rts

;seek
;Registers edited: A
;Position to seek to should be in number
seek:
	jsr clock_off
	jsr check_inserted
	beq seek_insert_sd

	lda #1
	sta op_result_reg

	lda #21
	jsr send_command

	jmp seek_done
seek_insert_sd:
	sec
seek_done:
	jsr clock_on
	rts

;position
;Registers edited: A
;Position is returned in number
position:
	jsr clock_off
	jsr check_inserted
	beq position_insert_sd

	lda #1
	sta op_result_reg

	jsr number_zero

	lda #22
	jsr send_command

	jmp position_done
position_insert_sd:
	sec
position_done:
	jsr clock_on
	rts

;name_file
;Registers edited: A
;Name is returned in sdbuf
name_file:
	jsr clock_off
	jsr check_inserted
	beq name_file_insert_sd

	lda #1
	sta op_result_reg

	lda #20
	jsr send_command

	jmp name_file_done
name_file_insert_sd:
	sec
name_file_done:
	jsr clock_on
	rts

;path
;Registers edited: A
path:
	jsr clock_off
	jsr check_inserted
	beq path_insert_sd

	lda #1
	sta op_result_reg

	lda #19
	jsr send_command

	jmp path_done
path_insert_sd:
	sec
path_done:
	jsr clock_on
	rts

;list_dir
;Registers edited: A,X
list_dir:
	jsr clock_off
	jsr check_inserted
	beq list_dir_insert_sd

	lda #1
	sta op_done_reg
	
	lda #17
	jsr send_command ;Set root to the current dir

	jmp list_dir_loop

list_dir_insert_sd:
	sec

list_dir_done:
	lda #18
	jsr send_command ;Close root
	jsr clock_on

	;jsr mount

	rts

list_dir_loop:
	;Print data about file/directory

	lda #12
	jsr send_command ;Open next file in root

	lda op_done_reg
	beq list_dir_done ;If done...

	lda #13
	jsr send_command ;Get filename of next file

	lda #13 ;newline
	sta singlecharbuf
	jsr printchar

	;; Print filename

	;Filename is in sdbuf
	lda #<sdbuf
	sta ptr_low
	lda #>sdbuf
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	;Print size

	lda #15
	jsr send_command ;Check is_dir
	
	lda number
	bne is_dir

	lda #" "
	sta singlecharbuf
	jsr printchar

	lda #14
	jsr send_command ;Get size of next file

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

	jmp not_dir

	;; Is directory

is_dir:
	lda #" "
	sta singlecharbuf
	jsr printchar

	;Print <DIR>
	lda #<dirstring
	sta ptr_low
	lda #>dirstring
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

not_dir:
	jsr check_pressed
	bcs notpressed_listdir

	jsr readchar ;Register keypress
	cmp ctrl_c_chr ;CTRL-C
	bne notpressed_listdir
	rts

notpressed_listdir:
	jmp list_dir_loop

;cd
;Registers edited: A
;Directory is in param
cd:
	jsr clock_off
	jsr check_inserted
	beq cd_insert_sd

	lda #1
	sta op_result_reg

	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	
	jsr strlen
	lda length
	sta length_reg

	lda #11
	jsr send_command

	jmp cd_done
cd_insert_sd:
	sec
cd_done:
	jsr clock_on
	rts

;make_dir
;Registers edited: A
;Directoru is in param
make_dir:
	jsr clock_off
	jsr check_inserted
	beq makedir_insert_sd

	lda #1
	sta op_result_reg

	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	
	jsr strlen
	lda length
	sta length_reg

	lda #10
	jsr send_command

	jmp makedir_done
makedir_insert_sd:
	sec

makedir_done:
	jsr clock_on
	rts

;make_file
;Registers edited: A
;Filename is in param
make_file:
	jsr clock_off
	jsr check_inserted
	beq makefile_insert_sd

	lda #1
	sta op_result_reg

	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	
	jsr strlen
	lda length
	sta length_reg

	lda #9
	jsr send_command

	jmp makefile_done
makefile_insert_sd:
	sec
makefile_done:
	jsr clock_on
	rts

;remove_dir
;Registers edited: A,X
;Directory is in param
;Returns 1 if fail, 0 if success in carry
remove_dir:
	jsr clock_off
	jsr check_inserted
	beq remove_dir_insert_sd

	lda #1
	sta op_result_reg

	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	
	jsr strlen
	lda length
	sta length_reg

	lda #8
	jsr send_command

	lda op_result_reg
	ror ;Move result into carry

	jmp remove_dir_success
remove_dir_insert_sd:
	sec
remove_dir_success:
	jsr clock_on
	rts

;remove_file
;Registers edited: A,X
;Filename is in param
;Returns 1 if fail, 0 if success in carry
remove_file:
	jsr clock_off
	jsr check_inserted
	beq remove_file_insert_sd

	lda #1
	sta op_result_reg

	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	
	jsr strlen
	lda length
	sta length_reg

	lda #7
	jsr send_command

	lda op_result_reg
	ror ;Move result into carry

	jmp remove_file_success
remove_file_insert_sd:
	sec
remove_file_success:
	jsr clock_on
	rts

;save_file
;Registers edited: A
;Location to save from is in size_reg0-1
;Length is in number
save_file:
	jsr clock_off
	jsr check_inserted
	beq savefile_insert_sd

	lda #1
	sta op_result_reg

	lda #6
	jsr send_command

	jmp savefile_done
savefile_insert_sd:
	sec
savefile_done:
	jsr clock_on
	rts

;load_file
;Registers edited: A
;Location to load to is in number
load_file:
	jsr clock_off
	jsr check_inserted
	beq load_file_insert_sd

	lda #1
	sta op_result_reg

	lda #5
	jsr send_command

	jmp load_file_done
load_file_insert_sd:
	sec
load_file_done:
	jsr clock_on
	;Loop done
	rts 

;read_file
;Registers edited: A
;Every 512 chars, the reading pauses. Press <ESC> to quit and <PGDOWN> to continue
read_file:
	jsr clock_off
	jsr check_inserted
	beq read_file_insert_sd

	lda #1
	sta op_result_reg

	lda #4
	jsr send_command

	lda #1
	sta op_done_reg

	jsr number_zero

	lda #13
	sta singlecharbuf
	jsr printchar

	;Actual print loop

read_file_loop:
	lda op_done_reg
	beq read_file_done

	lda sdbuf ;Char in first byte of sdbuf
	sta singlecharbuf
	jsr printchar_printable

	sei ;Disable IRQ
	wai
	cli ;Enable IRQ

	lda number
	cmp #1
	bne not_512_read
	lda number+1
	cmp #2
	bne not_512_read

read_waitkey:
	jsr readchar ;Wait for keypress

	lda singlecharbuf
	cmp #27 ;ESC
	beq read_file_done

	lda singlecharbuf
	cmp #147 ;PGDOWN
	bne read_waitkey

	jsr number_zero ;Pressed enter
	
not_512_read:

	clc
	lda number
	adc #1
	sta number
	lda number+1
	adc #0
	sta number+1

	jmp read_file_loop

read_file_insert_sd:
	sec

read_file_done:
	jsr number_zero

	stz op_done_reg ;Tell coprocessor that we are done

	sei ;Disable IRQ
	wai
	cli ;Enable IRQ



	;Loop done
	jsr clock_on
	rts 

;size_file
;Registers edited: A,X
;result in size_reg_0-3
size_file:
	jsr clock_off
	jsr check_inserted
	beq sizefile_insert_sd

	lda #1
	sta op_result_reg

	jsr number_zero
	stz size_reg_0
	stz size_reg_1
	stz size_reg_2
	stz size_reg_3

	lda #3
	jsr send_command

	jmp sizefile_done
sizefile_insert_sd:
	sec
	
sizefile_done:
	jsr clock_on
	rts

;close_file
;Registers edited: A
close_file:
	jsr clock_off
	jsr check_inserted
	beq closefile_insert_sd

	lda #1
	sta op_result_reg

	lda #2
	jsr send_command ;Close does not return	

	jmp closefile_done
closefile_insert_sd:
	sec
closefile_done:
	jsr clock_on
	rts

;open_file
;Registers edited: A,X
;Filename is in param
;Returns 1 if fail, 0 if success in carry
open_file:
	jsr clock_off
	jsr check_inserted
	beq openfile_insert_sd

	lda #1
	sta op_result_reg

	jsr mov_param_sdbuf

	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high
	
	jsr strlen
	lda length
	sta length_reg

	lda #1 
	jsr send_command

	lda op_result_reg
	ror ;Move result into carry

	jmp openfile_success
openfile_insert_sd:
	sec
openfile_success:
	jsr clock_on
	rts

;mount
;Registers edited: A
;Returns 1 if fail, 0 if success in carry
mount:
	jsr clock_off
	jsr check_inserted
	beq insert_sd_mou

	lda #1
	sta op_result_reg

	lda #0
	jsr send_command

	jsr reset_param
	lda #"/"
	sta param
	jsr cd

	lda op_result_reg
	ror ;Move result into carry

	jmp mount_success

insert_sd_mou:
	sec
mount_success:
	jsr clock_on

	rts

;RX/TX commands and data
;To read status: lda op_result_reg

;check_inserted
;Registers edited: A
;Returns 0 if not inserted.
check_inserted:
	clc
	
	lda PORTA1
	and #1
	bne inserted
inserted:
	rts

;send_command
;Registers edited: A
;Command to send is in A
send_command:
	sei ;Disable IRQ
	sta command_reg
	wai
	cli ;Enable IRQ
	rts