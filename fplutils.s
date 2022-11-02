;FPL utilites

;search_float
;Registers edited: A,Y
;Input:
;ptr is pointer to variable name to find (length <= 32)

;Output:
;Carry set if not found, clear if found.
;If carry set:
;A = 1 if var name is to long. 0 if else
search_float:
	jsr strlen
	lda length
	cmp #33
	bcs search_float_fail_vtle

	lda PORTA3
	pha

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda #float_bank_start
	sta PORTA3

	stz searchcounter


search_float_loop:
	ldy #0

search_float_loop_check_param:
	lda (searchptr),y
	cmp (ptr_low),y
	bne search_float_loop_check_param_done

	iny
	cpy #33
	bne search_float_loop_check_param

	;Found it!

	lda PORTA3
	sta searchptrbank

	pla
	sta PORTA3

	clc
	rts

search_float_fail_vtle:
	lda #1
	sec
	rts

search_float_loop_check_param_done:
	lda searchcounter
	cmp #floatcounter_max
	bne search_float_noinc_bank

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda #255
	sta searchcounter

	inc PORTA3
	lda PORTA3
	cmp #float_bank_max 
	beq search_float_fail

search_float_noinc_bank:
	clc
	lda searchptr
	adc #38
	sta searchptr
	lda searchptr+1
	adc #0
	sta searchptr+1


	inc searchcounter
	jmp search_float_loop

search_float_fail:
	pla
	sta PORTA3

	lda #0
	sec
	rts


;fpl_add_int
;number is num1, result is num2
;number is result
fpl_add_int:
	;jsr clock_off
	;lda #31
	;jsr send_command
	;jsr clock_on
	rts

;fpl_add_float
;number is num1, result is num2
;number is result
fpl_add_float:
	;jsr clock_off
	;lda #32
	;jsr send_command
	;jsr clock_on
	rts


;fpl_num_to_str
;Registers edited: A
;Input:
;result is the type 0=int, 1=float
;number is bytes

;Output:
;opbuf is string
fpl_num_to_str:
	jsr clock_off
	lda #28
	jsr send_command
	jsr clock_on
	rts


;fpl_str_to_num
;Registers edited: A
;Input:
;result is the type 0=int, 1=float
;opbuf is string

;Output:
;number is bytes
fpl_str_to_num:
	jsr clock_off
	lda #30
	jsr send_command
	jsr clock_on
	rts

;fpl_int_cmp
;Registers edited: A
;Input:
;number is representation of number 1
;result is representation of number 2

;Output:
;op_result_reg is result 0 is equal, 1 is greater than, 2 is less than

fpl_int_cmp:
	jsr clock_off
	lda #27
	jsr send_command
	jsr clock_on
	rts


;fpl_float_cmp
;Registers edited: A
;Input:
;number is representation of number 1
;result is representation of number 2

;Output:
;op_result_reg is result 0 is equal, 1 is greater than, 2 is less than

fpl_float_cmp:
	jsr clock_off
	lda #29
	jsr send_command
	jsr clock_on
	rts


;fpl_goto
;Registers edited: A,Y
;number is linenum to goto to.
fpl_goto:
	sec
	lda number
	sbc #1
	sta linenum
	lda number+1
	sbc #0
	sta linenum+1

	rts



;get_data_param_werror
;Registers edited: A,X,Y
;ptr is parameter
;See get_data_param
get_data_param_werror:
	jsr get_data_param
	bcs get_data_param_werror_fail

	rts

get_data_param_werror_fail:
	cmp #1
	beq get_data_param_werror_fail_quotes_missing

get_data_param_werror_invalid:
	jsr print_fpl_error_line
	ldx get_data_param_error
	jsr raise_fpl_error
	;Pull this subroutine return address
	pla
	pla
	jmp fpl_run_error_done

get_data_param_werror_fail_quotes_missing:
	cpx quote_chr
	bne get_data_param_werror_invalid

	jsr print_fpl_error_line
	ldx quotes_missing
	jsr raise_fpl_error
	;Pull this subroutine return address
	pla
	pla
	jmp fpl_run_error_done


;search_str
;Registers edited: A,Y
;Input:
;ptr is pointer to variable name to find (length <= 32)

;Output:
;Carry set if not found, clear if found.
;If carry set:
;A = 1 if var name is to long. 0 if else
search_str:
	jsr strlen
	lda length
	cmp #33
	bcs search_str_fail_vtle

	lda PORTA3
	pha

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda #str_bank_start
	sta PORTA3

	stz searchcounter


search_str_loop:
	ldy #0

search_str_loop_check_param:
	lda (searchptr),y
	cmp (ptr_low),y
	bne search_str_loop_check_param_done

	iny
	cpy #33
	bne search_str_loop_check_param

	;Found it!

	lda PORTA3
	sta searchptrbank

	pla
	sta PORTA3

	clc
	rts

search_str_loop_check_param_done:
	lda searchcounter
	cmp #strcounter_max
	bne search_str_noinc_bank

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda #255
	sta searchcounter

	inc PORTA3
	lda PORTA3
	cmp #str_bank_max 
	beq search_str_fail

search_str_noinc_bank:
	clc
	lda searchptr
	adc #<290
	sta searchptr
	lda searchptr+1
	adc #>290
	sta searchptr+1

	inc searchcounter
	jmp search_str_loop

search_str_fail_vtle:
	lda #1
	sec
	rts

search_str_fail:
	pla
	sta PORTA3

	lda #0
	sec
	rts









;get_data_param
;Registers edited: A,X,Y
;Input:
;ptr is the pointer to data

;Output:
;A is type (0 = int, 1 = str, 2 = variable)
;Carry is set if type is not valid (not imm or varible), clear if type is valid
;If Carry set and A = 2:
	;X = error type from fpl_read_variable
;If Carry set and A = 255:
	;No type recognized

;If A = 0:
	;Result in number

;If A = 1:
	;Result in charbuf

;If A = 2:
;	X = data type (see fpl_constants)
;	If x = int: Result in number
;	If x = string: Result in charbuf
;   if x = float: FP representation in number

get_data_param:
	;Variables
	;Copy/Paste the below 3 lines to add data types

	;Int type
	ldx type_int
	jsr fpl_read_variable
	bcc is_type_var_int_get_data_param_short

	;String type
	ldx type_str
	jsr fpl_read_variable
	bcc is_type_var_str_get_data_param

	;Float type
	ldx type_float
	jsr fpl_read_variable
	bcc is_type_var_float_get_data_param_short


	;Immediate value
	;Check if number
	lda (ptr_low)
	jsr isnumeric
	bcc is_imm_int_get_data_param

	;Check if first char is "
	lda (ptr_low)
	cmp quote_chr
	beq is_imm_str_get_data_param

	;Check if string is an expression

	;Else: Error
	lda #255
	sec
	rts

is_type_var_str_get_data_param:
	;Data already in charbuf
	ldx type_str
	jsr fpl_read_variable
	bcc is_type_var_str_get_data_param_continue

	tax ;Put error type in X
	lda #2
	sec
	rts

is_type_var_str_get_data_param_continue:
	ldx type_str
	lda #2
	clc
	rts



is_imm_str_get_data_param:
	lda ptr_low
	sta ptra_low
	lda ptr_high
	sta ptra_high

	jsr reset_charbuf

	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high

	jsr get_data_in_quotes

	bcs is_imm_str_get_data_param_fail

	lda #1
	clc
	rts

is_imm_str_get_data_param_fail:
	ldx quote_chr
	lda #1
	sec
	rts




is_type_var_int_get_data_param_short:
	jmp is_type_var_int_get_data_param

is_type_var_float_get_data_param_short:
	jmp is_type_var_float_get_data_param



is_imm_int_get_data_param:
	ldy #0
check_int_is_imm_int_get_data_param_loop:
	lda (ptr_low),y
	beq is_int_imm_int_get_data_param_loop
	jsr isnumeric
	bcs not_int_is_imm_int_get_data_param_loop

	iny
	bne check_int_is_imm_int_get_data_param_loop

not_int_is_imm_int_get_data_param_loop:
	lda #0
	sec
	rts

is_int_imm_int_get_data_param_loop:
	lda ptr_low
	sta ptra_low
	lda ptr_high
	sta ptra_high

	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	jsr strcpy

	jsr dec_to_bin

	lda #0
	clc
	rts




is_type_var_int_get_data_param:
	ldx type_int
	jsr fpl_read_variable
	bcc is_type_var_int_get_data_param_continue

	tax ;Put error type in X
	lda #2
	sec
	rts

is_type_var_int_get_data_param_continue:
	lda #2
	clc
	rts


is_type_var_float_get_data_param:
	ldx type_float
	jsr fpl_read_variable
	bcc is_type_var_float_get_data_param_continue

	tax ;Put error type in X
	lda #2
	sec
	rts

is_type_var_float_get_data_param_continue:
	lda #2
	clc
	rts









;search_int
;Registers edited: A,Y
;Input:
;ptr is pointer to variable name to find (length <= 32)

;Output:
;Carry set if not found, clear if found.
;If carry set:
;A = 1 if var name is to long. 0 if else
search_int:
	jsr strlen
	lda length
	cmp #33
	bcs search_int_fail_vtle

	lda PORTA3
	pha

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda #int_bank_start
	sta PORTA3

	stz searchcounter


search_int_loop:
	ldy #0

search_int_loop_check_param:
	lda (searchptr),y
	cmp (ptr_low),y
	bne search_int_loop_check_param_done

	iny
	cpy #33
	bne search_int_loop_check_param

	;Found it!

	lda PORTA3
	sta searchptrbank

	pla
	sta PORTA3

	clc
	rts

search_int_fail_vtle:
	lda #1
	sec
	rts

search_int_loop_check_param_done:
	lda searchcounter
	cmp #intcounter_max
	bne search_int_noinc_bank

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda #255
	sta searchcounter

	inc PORTA3
	lda PORTA3
	cmp #int_bank_max 
	beq search_int_fail

search_int_noinc_bank:
	clc
	lda searchptr
	adc #38
	sta searchptr
	lda searchptr+1
	adc #0
	sta searchptr+1


	inc searchcounter
	jmp search_int_loop

search_int_fail:
	pla
	sta PORTA3

	lda #0
	sec
	rts

;fpl_read_variable
;Registers edited: A,Y
;Input
;ptr is pointer to variable (length <= 32)
;X is variable type

;Output
;carry set if error (not found), clear if success
;If carry set:
;A = 1 if var name is to long. 0 if else


;For int:
;number is data

;For string:
;charbuf is data

fpl_read_variable:
	jsr strlen
	lda length
	cmp #33
	bcs fpl_read_var_fail_vtle

	lda PORTA3
	pha

	cpx type_int
	beq read_int

	cpx type_str
	beq read_str

	cpx type_float
	beq read_float

	jmp fpl_read_fail

fpl_read_var_fail_vtle:
	lda #1
	sec
	rts

fpl_read_fail:
	pla
	sta PORTA3

	lda #0
	sec
	rts

read_str:
	ldx type_str
	jsr search_str
	bcs fpl_read_fail

	lda searchptrbank
	sta PORTA3

	clc
	lda searchptr
	adc #34
	sta ptra_low
	lda searchptr+1
	adc #0
	sta ptra_high

	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high

	jsr strcpy
	
	pla
	sta PORTA3

	clc
	rts

read_float:
	ldx type_float
	jsr search_float
	bcs fpl_read_fail

	clc
	lda searchptr
	adc #34
	sta searchptr
	lda searchptr+1
	adc #0
	sta searchptr+1

	lda searchptrbank
	sta PORTA3

	ldy #0
	lda (searchptr),y
	sta number
	iny
	lda (searchptr),y
	sta number+1
	iny
	lda (searchptr),y
	sta number+2
	iny
	lda (searchptr),y
	sta number+3

	pla
	sta PORTA3

	clc
	rts



read_int:
	ldx type_int
	jsr search_int
	bcs fpl_read_fail

	clc
	lda searchptr
	adc #34
	sta searchptr
	lda searchptr+1
	adc #0
	sta searchptr+1

	lda searchptrbank
	sta PORTA3

	ldy #0
	lda (searchptr),y
	sta number
	iny
	lda (searchptr),y
	sta number+1
	iny
	lda (searchptr),y
	sta number+2
	iny
	lda (searchptr),y
	sta number+3

	pla
	sta PORTA3

	clc
	rts



;fpl_create_variable
;Registers edited: A,Y
;Input
;ptr is pointer to variable (length <= 32)

;For string
;If X = type_str:
;ptra is data to initialize with

;For int:
;number is data to initialize with


;Output
;maxint/str is max byte (linear memory)
;maxint/strbyte is max byte bank
;intcounter is incremented OR strcounter is incremented.
;carry set if error, clear if success
;If carry set:
;A = 1 if var name is to long. 0 if else

fpl_create_variable:
	jsr strlen
	lda length
	cmp #33
	bcs fpl_create_var_fail_vtle

	lda PORTA3
	pha

	cpx type_int
	beq create_int_start_short

	cpx type_str
	beq create_str_start

	cpx type_float
	beq create_float_start_short
	

	;We better not ever get here!!!

fpl_create_var_fail_vtle:
	lda #1
	sec
	rts

fpl_create_var_fail:
	pla
	sta PORTA3

	jsr print_fpl_error_line
	ldx oom
	jsr raise_fpl_error
	pla
	pla
	jmp fpl_run_error_done


create_str_start:
	lda maxstrbank
	sta PORTA3

	ldx type_str
	jsr search_str
	bcc str_found_create_str

	lda strcounter
	cmp #strcounter_max
	bne create_str

	lda #255
	sta strcounter


	inc PORTA3
	lda PORTA3
	cmp #str_bank_max 
	beq fpl_create_var_fail

	bra create_str

str_found_create_str:
	lda searchptrbank
	sta PORTA3

	lda searchptr
	sta maxstr
	lda searchptr+1
	sta maxstr+1

	dec strcounter

	bra create_str

create_int_start_short:
	jmp create_int_start

create_float_start_short:
	jmp create_float_start


create_str:
	ldy #0
fpl_create_str_loop_save_name:
	lda (ptr_low),y
	sta (maxstr),y

	iny
	cpy #33
	bne fpl_create_str_loop_save_name
	
	lda #0
	;Null byte
	sta (maxstr),y

	;Copy string
	clc
	lda maxstr
	adc #34
	sta ptrb_low
	lda maxstr+1
	adc #0
	sta ptrb_low+1

	jsr strcpy


	clc
	lda maxstr
	adc #<290
	sta maxstr
	lda maxstr+1
	adc #>290
	sta maxstr+1

	inc strcounter
	
	lda PORTA3
	sta maxstrbank

	pla
	sta PORTA3

	clc
	rts

fpl_create_var_fail_short:
	jmp fpl_create_var_fail

create_float_start:
	lda maxfloatbank
	sta PORTA3

	ldx type_float
	jsr search_float
	bcc float_found_create_float

	lda floatcounter
	cmp #floatcounter_max
	bne create_float

	lda #255
	sta floatcounter

	inc PORTA3
	lda PORTA3
	cmp #float_bank_max 
	beq fpl_create_var_fail_short

	bra create_float

float_found_create_float:
	lda searchptrbank
	sta PORTA3

	lda searchptr
	sta maxfloat
	lda searchptr+1
	sta maxfloat+1

	dec floatcounter

create_float:
	ldy #0
fpl_create_float_loop_save_name:
	lda (ptr_low),y
	sta (maxfloat),y

	iny
	cpy #33
	bne fpl_create_float_loop_save_name
	
	lda #0
	;Null byte
	sta (maxfloat),y
	;Actual variable data
	iny
	lda number
	sta (maxfloat),y
	iny
	lda number+1
	sta (maxfloat),y
	iny
	lda number+2
	sta (maxfloat),y
	iny
	lda number+3
	sta (maxfloat),y

	clc
	lda maxfloat
	adc #38
	sta maxfloat
	lda maxfloat+1
	adc #0
	sta maxfloat+1

	inc floatcounter

	lda PORTA3
	sta maxfloatbank

	pla
	sta PORTA3

	clc
	rts

fpl_create_var_fail_short2:
	jmp fpl_create_var_fail

create_int_start:
	lda maxintbank
	sta PORTA3

	ldx type_int
	jsr search_int
	bcc int_found_create_int

	lda intcounter
	cmp #intcounter_max
	bne create_int

	lda #255
	sta intcounter

	inc PORTA3
	lda PORTA3
	cmp #int_bank_max 
	beq fpl_create_var_fail_short2

	bra create_int

int_found_create_int:
	lda searchptrbank
	sta PORTA3

	lda searchptr
	sta maxint
	lda searchptr+1
	sta maxint+1

	dec intcounter

create_int:
	ldy #0
fpl_create_int_loop_save_name:
	lda (ptr_low),y
	sta (maxint),y

	iny
	cpy #33
	bne fpl_create_int_loop_save_name
	
	lda #0
	;Null byte
	sta (maxint),y
	;Actual variable data
	iny
	lda number
	sta (maxint),y
	iny
	lda number+1
	sta (maxint),y
	iny
	lda number+2
	sta (maxint),y
	iny
	lda number+3
	sta (maxint),y

	clc
	lda maxint
	adc #38
	sta maxint
	lda maxint+1
	adc #0
	sta maxint+1

	inc intcounter

	lda PORTA3
	sta maxintbank

	pla
	sta PORTA3

	clc
	rts

;fpl_run_error_done
;Registers edited: A
;Goes to FPL command prompt from a run_COMMAND
;THIS IS NOT A SUBORUTINE!
fpl_run_error_done:
	;FPL run commands (not acutal inline run)
	pla
	pla
	;PORTA
	pla
	sta PORTA3
	jmp command_done

;fpl_error_done
;Registers edited: A
;Goes to FPL command prompt from a run_COMMAND
;THIS IS NOT A SUBORUTINE!
fpl_error_done:
	;Tokenize subroutine
	pla
	pla
	rts ;Go back to param prompt

;print_fpl_error_line
;Registers edited: A
;number is edited.
print_fpl_error_line:
	lda #<error_line
	sta ptr_low
	lda #>error_line
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print

	jsr number_zero
	lda linenum
	sta number
	lda linenum+1
	sta number+1
	lda linenum+2
	sta number+2
	lda linenum+3
	sta number+3

	jsr bin_to_dec

	rts

;raise_fpl_error
;Registers edited: A
;X is the error number
raise_fpl_error:
	cpx fpl_error_param_required
	beq error_param_required

	cpx fpl_error_varname_to_long
	beq error_varname_to_long

	cpx fpl_error_var_not_found
	beq error_varname_not_found

	cpx incorrect_number_of_parameters
	beq error_incorrect_number_of_parameters

	cpx parameter_to_long
	beq error_parameter_to_long

	cpx get_data_param_error
	beq error_get_data_param_error

	cpx quotes_missing
	beq quotes_missing_error

	cpx type_mismatch
	beq type_mismatch_error

	cpx fpl_if_operation_not_found
	beq fpl_if_operation_not_found_error

	cpx oom
	beq oom_error


	rts

type_mismatch_error:
	jmp type_mismatch_error_
oom_error:
	jmp oom_error


fpl_if_operation_not_found_error:
	lda #<fpl_if_operation_not_found_str
	sta ptr_low
	lda #>fpl_if_operation_not_found_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

error_param_required:
	lda #<error_param_required_str
	sta ptr_low
	lda #>error_param_required_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

error_varname_to_long:
	lda #<var_name_to_long_not_found_str
	sta ptr_low
	lda #>var_name_to_long_not_found_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

error_varname_not_found:
	lda #<var_not_found_str
	sta ptr_low
	lda #>var_not_found_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

error_incorrect_number_of_parameters:
	lda #<incorrect_number_of_parameters_str
	sta ptr_low
	lda #>incorrect_number_of_parameters_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

error_parameter_to_long:
	lda #<parameter_to_long_str
	sta ptr_low
	lda #>parameter_to_long_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

error_get_data_param_error:
	lda #<get_data_param_error_str
	sta ptr_low
	lda #>get_data_param_error_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

quotes_missing_error:
	lda #<quotes_missing_str
	sta ptr_low
	lda #>quotes_missing_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

type_mismatch_error_:
	lda #<type_mismatch_str
	sta ptr_low
	lda #>type_mismatch_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

oom_error_:
	lda #<oom_str
	sta ptr_low
	lda #>oom_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts



;check_param
;Registers edited: A
;Carry set if no param, clear if param
check_param:
	lda param
	beq noparam_check_param

	clc
	rts

noparam_check_param:
	sec
	rts



;search_line
;Registers edited: A,Y
;linenum is the line to search for
;maxline is the max linear memory ptr
;maxlinebank is the max bank
;pointer in searchptr and searchptrbank
;carry set if not found. clear if else.
search_line:
	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda PORTA3
	pha

	stz searchcounter
	stz PORTA3

	jsr number_zero
search_line_loop:	
	;Get ptr on stack
	lda searchptr
	pha

	lda searchptr+1
	pha

	ldy #1
	;Get linenum
	lda (searchptr),y
	cmp linenum
	bne search_line_loop_goaround

	ldy #2
	lda (searchptr),y
	cmp linenum+1
	bne search_line_loop_goaround

	pla
	sta searchptr+1
	pla
	sta searchptr

	lda PORTA3
	sta searchptrbank

	pla
	sta PORTA3

	clc
	rts

search_line_loop_goaround:
	jsr number_zero

	pla
	sta number+1
	pla
	sta number

	lda number
	cmp maxline
	bne search_line_loop_goaround_

	lda number+1
	cmp maxline+1
	bne search_line_loop_goaround_

	lda PORTA3
	cmp maxlinebank
	bne search_line_loop_goaround_


	lda PORTA3
	sta searchptrbank

	pla
	sta PORTA3

	sec
	rts

search_line_loop_short:
	inc searchcounter
	jmp search_line_loop

search_line_loop_goaround_:
	jsr result_zero

	lda #104
	sta result
	jsr searchptr_add

	jsr result_zero
	jsr number_zero

	lda searchcounter
	cmp #linecounter_max
	bne search_line_loop_short

	lda #$00
	sta searchptr
	lda #$40
	sta searchptr+1

	lda #255
	sta searchcounter

	inc PORTA3
	lda PORTA3
	cmp #fpl_line_bank_max
	bne search_line_loop_short ;THIS ONLY ALLOWS FPL TO USE 128 kB OF RAM

	lda PORTA3
	sta searchptrbank

	pla
	sta PORTA3

	sec
	rts







;maxline_inc
;Registers edited: P, A
;Increments maxline
maxline_inc:
	clc
	lda maxline
	adc #1
	sta maxline
	lda maxline+1
	adc #0
	sta maxline+1

	rts 


;maxline_add
;Registers edited: P, A
;Adds number to maxline
maxline_add:
	clc
	lda maxline
	adc number
	sta maxline
	lda maxline+1
	adc number+1
	sta maxline+1

	rts 


;searchptr_inc
;Registers edited: P, A
;Increments searchptr
searchptr_inc:
	clc
	lda searchptr
	adc #1
	sta searchptr
	lda searchptr+1
	adc #0
	sta searchptr+1

	rts 


;searchptr_add
;Registers edited: P, A
;Adds result to searchptr
searchptr_add:
	clc
	lda searchptr
	adc result
	sta searchptr
	lda searchptr+1
	adc result+1
	sta searchptr+1

	rts 





	

;nextline_inc
;Registers edited: P, A
;Increments nextline
nextline_inc:
	clc
	lda nextline
	adc #1
	sta nextline
	lda nextline+1
	adc #0
	sta nextline+1

	rts 


;nextline_add
;Registers edited: P, A
;Adds number to nextline
nextline_add:
	clc
	lda nextline
	adc number
	sta nextline
	lda nextline+1
	adc number+1
	sta nextline+1

	rts 