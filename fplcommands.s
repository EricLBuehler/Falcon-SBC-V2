;[] means required parameter
;{} means optional parameter


;FPL commands
;[LINENUM] print [DATA]
;[LINENUM] println [DATA]
;[LINENUM] goto [LINENUM]
;[LINENUM] # {COMMENT TEXT}
;[LINENUM] end
;[LINENUM] cls
;[LINENUM] int [VARIABLE_NAME]=[INITIALIZER]
;[LINENUM] str [VARIABLE_NAME]="[INITIALIZER]"
;[LINENUM] input "[PROMPT]",[VARIABLE]
;[LINENUM] if [DATA #1 (VAR/IMM) ],[COMPARISON],[DATA #1 (VAR/IMM) ],[IF COMPARISON TRUE GOTO (VAR/IMM)]

;FPL inline commands
;list {LINENUM}
;run
;exit
;new
;load [FILENAME]
;save [FILENAME]
;cls
;print {TEXT}


;list
print_command_list_fpl:
	lda command
	and #%01111111

	cmp token_print
	beq token_print_list

	cmp token_goto
	beq token_goto_list

	cmp token_println
	beq token_println_list

	cmp token_comment
	beq token_comment_list

	cmp token_end
	beq token_end_list

	cmp token_cls
	beq token_cls_list

	cmp token_int
	beq token_int_list

	cmp token_str
	beq token_str_list

	cmp token_input
	beq token_input_list

	cmp token_if
	beq token_if_list

	cmp token_float
	beq token_float_list

	cmp token_add
	beq token_add_list

	rts

token_add_list:
	jmp token_add_list_

token_int_list:
	jmp token_int_list_

token_input_list:
	jmp token_input_list_

token_str_list:
	jmp token_str_list_

token_if_list:
	jmp token_if_list_

token_float_list:
	jmp token_float_list_


token_print_list:
	lda #<print_str
	sta ptr_low
	lda #>print_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_goto_list:
	lda #<goto_str
	sta ptr_low
	lda #>goto_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_println_list:
	lda #<println_str
	sta ptr_low
	lda #>println_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_comment_list:
	lda #<comment_str
	sta ptr_low
	lda #>comment_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_end_list:
	lda #<end_str
	sta ptr_low
	lda #>end_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_cls_list:
	lda #<cls_str
	sta ptr_low
	lda #>cls_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_int_list_:
	lda #<int_str
	sta ptr_low
	lda #>int_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_str_list_:
	lda #<str_str
	sta ptr_low
	lda #>str_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_input_list_:
	lda #<input_str
	sta ptr_low
	lda #>input_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_if_list_:
	lda #<if_str
	sta ptr_low
	lda #>if_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts


token_float_list_:
	lda #<float_str
	sta ptr_low
	lda #>float_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts

token_add_list_:
	lda #<add_str
	sta ptr_low
	lda #>add_str
	sta ptr_high
	jsr mov_ptr_charbuf
	jsr print
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;add
tokenize_add:
	lda command
	cmp #"a"
	bne not_tokenize_add
	lda command+1
	cmp #"d"
	bne not_tokenize_add
	lda command+2
	cmp #"d"
	bne not_tokenize_add
	lda command+3
	bne not_tokenize_add
	
	lda token_add
	clc
	rts
not_tokenize_add:
	sec
	rts



run_add:
	lda command
	cmp token_add
	beq found_add
	rts

found_add:
	;Split param
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	lda #"," ;Char to search for

	jsr strtolist

	lda length
	cmp #3
	beq start_add

	jsr print_fpl_error_line
	ldx incorrect_number_of_parameters
	jsr raise_fpl_error
	jmp fpl_run_error_done

start_add:
	jsr reset_sdbuf
	jsr reset_command
	jsr reset_opbuf 

	;Num1
	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	lda #0
	sta strindex_

	jsr strlistindex

	;Num2
	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	jsr reset_command

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	lda #1
	sta strindex_

	jsr strlistindex

	;Result
	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	lda #2
	sta strindex_

	jsr strlistindex

	;sdbuf is num1
	;command is num2
	;opbuf is result var

	lda #<sdbuf
	sta ptr_low
	lda #>sdbuf
	sta ptr_high

	jsr get_data_param_werror

	cmp #0
	beq add_add_check_num2
	
	cmp #1
	beq fpl_add_is_str

	;Is variable
	cpx type_str
	beq fpl_add_is_str


add_add_check_num2:
	stx strscratch
	lda number
	sta num1
	lda number+1
	sta num1+1
	lda number+2
	sta num1+2
	lda number+3
	sta num1+3
	

	lda #<command
	sta ptr_low
	lda #>command
	sta ptr_high

	jsr get_data_param_werror

	cmp #0
	beq add_add_final_check
	
	cmp #1
	beq fpl_add_is_str

	;Is variable
	cpx type_str
	beq fpl_add_is_str


add_add_final_check:
	cpx strscratch
	beq add_start_add


fpl_add_is_str:
	jsr print_fpl_error_line
	ldx type_mismatch
	jsr raise_fpl_error
	jmp fpl_run_error_done

add_start_add:
	cpx add_start_add_float

	lda num1
	sta number
	lda num1+1
	sta number+1
	lda num1+2
	sta number+2
	lda num1+3
	sta number+3

	lda number
	sta result
	lda number+1
	sta result+1
	lda number+2
	sta result+2
	lda number+3
	sta result+3

	jsr fpl_add_int

	jsr bin_to_dec

	rts

add_start_add_float:

	rts


;float
tokenize_float:
	lda command
	cmp #"f"
	bne not_tokenize_float
	lda command+1
	cmp #"l"
	bne not_tokenize_float
	lda command+2
	cmp #"o"
	bne not_tokenize_float
	lda command+3
	cmp #"a"
	bne not_tokenize_float
	lda command+4
	cmp #"t"
	bne not_tokenize_float
	lda command+5
	bne not_tokenize_float
	
	lda token_float
	clc
	rts
not_tokenize_float:
	sec
	rts



run_float:
	lda command
	cmp token_float
	beq found_float
	rts

found_float:
	;Split param
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	lda #"=" ;Char to search for

	jsr strtolist
	
	lda length
	cmp #2
	beq create_float_var_runfloat

	jsr print_fpl_error_line
	ldx incorrect_number_of_parameters
	jsr raise_fpl_error
	jmp fpl_run_error_done


create_float_var_runfloat:
	jsr reset_sdbuf
	jsr reset_opbuf

	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	lda #0
	sta strindex_

	jsr strlistindex


	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	lda #1
	sta strindex_

	jsr strlistindex


	;Varname is in sdbuf
	;Data in opbuf

	;Str to float
	lda #<opbuf
	sta ptr_low
	lda #>opbuf
	sta ptr_high
	jsr strlen

	lda length
	sta length_reg

	lda #1
	sta result

	jsr fpl_str_to_num
	;Representation in number


	lda #<sdbuf
	sta ptr_low
	lda #>sdbuf
	sta ptr_high

	ldx type_float

	jsr fpl_create_variable
	bcc create_float_done

	jsr print_fpl_error_line
	ldx fpl_error_varname_to_long
	jsr raise_fpl_error
	jmp fpl_error_done

create_float_done:
	
	rts





;if
tokenize_if:
	lda command
	cmp #"i"
	bne not_tokenize_if
	lda command+1
	cmp #"f"
	bne not_tokenize_if
	lda command+2
	bne not_tokenize_if

	jsr check_param
	bcc continue_tokenizing_if

	ldx fpl_error_param_required
	jsr raise_fpl_error
	jmp fpl_error_done

continue_tokenizing_if:
	lda token_if
	clc
	rts
not_tokenize_if:
	sec
	rts



run_if:
	lda command
	cmp token_if
	beq found_if
	rts

found_if:
	;Split param
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	lda #"," ;Char to search for

	jsr strtolist

	lda length
	cmp #4
	beq start_if

	jsr print_fpl_error_line
	ldx incorrect_number_of_parameters
	jsr raise_fpl_error
	jmp fpl_run_error_done

start_if:
	;sdbuf is var/imm 1
	;opbuf is var/imm 2
	;if_operation byte 1 is operation (see fpl_constants)
	;if_true_line is line to goto to if operation is true

	jsr reset_sdbuf
	jsr reset_opbuf
	jsr number_zero
	jsr reset_command

	;Var/imm 1

	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	lda #0
	sta strindex_

	jsr strlistindex

	;Operation
	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	jsr reset_command

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	lda #1
	sta strindex_

	jsr strlistindex

	lda command
	sta if_operation
	lda command+1
	sta if_operation+1

	stz null_if

	jsr reset_command

	;Var/imm 2
	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	lda #2
	sta strindex_

	jsr strlistindex

	;If true:
	;Goto line
	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	lda #3
	sta strindex_

	jsr strlistindex

	jsr dec_to_bin
	lda number
	sta if_true_line
	lda number+1
	sta if_true_line+1


	;Get data out of param 1
	lda #<sdbuf
	sta ptr_low
	lda #>sdbuf
	sta ptr_high

	jsr get_data_param_werror

	cmp #0
	beq if_operation_data_int
	
	cmp #1
	beq if_operation_data_str

	cmp #2
	beq if_operation_data_var


if_operation_data_str: ;Imm str
	jsr reset_sdbuf

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	jsr strcpy

	lda type_str
	sta if_type_a

	bra if_operation_partb

if_operation_data_int: ;Imm int
	jsr reset_sdbuf

	lda number
	sta sdbuf
	lda number+1
	sta sdbuf+1
	lda number+2
	sta sdbuf+2
	lda number+3
	sta sdbuf+3

	lda type_int
	sta if_type_a

	bra if_operation_partb

if_operation_data_var:
	cpx type_int
	beq if_operation_data_var_int

	cpx type_str
	beq if_operation_data_var_str

if_operation_data_var_str: ;Var str
	jsr reset_sdbuf

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	jsr strcpy

	lda type_str
	sta if_type_a

	bra if_operation_partb

if_operation_data_var_int: ;Var int
	jsr reset_sdbuf

	lda number
	sta sdbuf
	lda number+1
	sta sdbuf+1
	lda number+2
	sta sdbuf+2
	lda number+3
	sta sdbuf+3

	lda type_int
	sta if_type_a

	;Fall through

if_operation_partb:
	;Get data out of param 2
	lda #<command
	sta ptr_low
	lda #>command
	sta ptr_high


	jsr get_data_param_werror

	cmp #0
	beq if_operation_partb_data_int
	
	cmp #1
	beq if_operation_partb_data_str

	cmp #2
	beq if_operation_partb_data_var


if_operation_partb_data_str: ;Imm str
	jsr reset_command

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	jsr strcpy


	lda type_str
	sta if_type_b

	bra if_start_cmp

if_operation_partb_data_int: ;Imm int
	jsr reset_command

	lda number
	sta command
	lda number+1
	sta command+1
	lda number+2
	sta command+2
	lda number+3
	sta command+3

	lda type_int
	sta if_type_b

	bra if_start_cmp

if_operation_partb_data_var:
	cpx type_int
	beq if_operation_partb_data_var_int

	cpx type_str
	beq if_operation_partb_data_var_str

if_operation_partb_data_var_str: ;Var str
	jsr reset_command

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	jsr strcpy

	lda type_str
	sta if_type_b

	bra if_start_cmp

if_operation_partb_data_var_int: ;Var int
	jsr reset_command

	lda number
	sta command
	lda number+1
	sta command+1
	lda number+2
	sta command+2
	lda number+3
	sta command+3

	lda type_int
	sta if_type_b

	;Fall through

	
	;Compare

if_start_cmp:
	lda #<if_operation
	sta ptra_low
	lda #>if_operation
	sta ptra_high

	lda #<operation_eq
	sta ptrb_low
	lda #>operation_eq
	sta ptrb_high

	jsr strcmp
	beq if_operation_eq_cmp_short



	lda #<if_operation
	sta ptra_low
	lda #>if_operation
	sta ptra_high

	lda #<operation_neq
	sta ptrb_low
	lda #>operation_neq
	sta ptrb_high

	jsr strcmp
	beq if_operation_neq_cmp_short



	lda #<if_operation
	sta ptra_low
	lda #>if_operation
	sta ptra_high

	lda #<operation_gte
	sta ptrb_low
	lda #>operation_gte
	sta ptrb_high

	jsr strcmp
	beq if_operation_gte_cmp_short


	lda #<if_operation
	sta ptra_low
	lda #>if_operation
	sta ptra_high

	lda #<operation_gt
	sta ptrb_low
	lda #>operation_gt
	sta ptrb_high

	jsr strcmp
	beq if_operation_gt_cmp_short



	lda #<if_operation
	sta ptra_low
	lda #>if_operation
	sta ptra_high

	lda #<operation_lte
	sta ptrb_low
	lda #>operation_lte
	sta ptrb_high

	jsr strcmp
	beq if_operation_lte_cmp_short



	lda #<if_operation
	sta ptra_low
	lda #>if_operation
	sta ptra_high

	lda #<operation_lt
	sta ptrb_low
	lda #>operation_lt
	sta ptrb_high

	jsr strcmp
	beq if_operation_lt_cmp_short


	jsr print_fpl_error_line
	ldx fpl_if_operation_not_found
	jsr raise_fpl_error
	jmp fpl_run_error_done

if_operation_gte_cmp_short:
	jmp if_operation_gte_cmp

if_operation_gt_cmp_short:
	jmp if_operation_gt_cmp

if_operation_neq_cmp_short:
	jmp if_operation_neq_cmp

if_operation_eq_cmp_short:
	jmp if_operation_eq_cmp

if_operation_lte_cmp_short:
	jmp if_operation_lte_cmp

if_operation_lt_cmp_short:
	jmp if_operation_lt_cmp


if_operation_eq_cmp:
	lda if_type_a
	cmp if_type_b
	bne if_type_mismatch_error

	lda #<sdbuf
	sta ptra_low
	lda #>sdbuf
	sta ptra_high

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	jsr strcmp
	beq if_operation_eq_cmp_iseq

	rts

if_operation_eq_cmp_iseq:
	;Equal

	lda if_true_line
	sta number
	lda if_true_line+1
	sta number+1

	jsr fpl_goto

	rts

if_type_mismatch_error:
	jsr print_fpl_error_line
	ldx type_mismatch
	jsr raise_fpl_error
	jmp fpl_run_error_done

;;;;;
	
if_operation_neq_cmp:
	lda if_type_a
	cmp if_type_b
	bne if_type_mismatch_error

	lda #<sdbuf
	sta ptra_low
	lda #>sdbuf
	sta ptra_high

	lda #<command
	sta ptrb_low
	lda #>command
	sta ptrb_high

	jsr strcmp
	bne if_operation_neq_cmp_isneq

	rts

if_operation_neq_cmp_isneq:
	;Not Equal

	lda if_true_line
	sta number
	lda if_true_line+1
	sta number+1

	jsr fpl_goto

	rts

;;;;;
	
if_operation_gte_cmp:
	lda if_type_a
	cmp if_type_b
	bne if_type_mismatch_error

	;Make sure type is int. ADD LINES HERE TO SUPPORT FLOAT
	lda if_type_a
	cmp type_str
	beq if_type_mismatch_error

	lda sdbuf
	sta number
	lda sdbuf+1
	sta number+1
	lda sdbuf+2
	sta number+2
	lda sdbuf+3
	sta number+3

	lda command
	sta result
	lda command+1
	sta result+1
	lda command+2
	sta result+2
	lda command+3
	sta result+3

	jsr fpl_int_cmp

	lda op_result_reg
	beq if_operation_gte_cmp_iseq
	cmp #1
	beq if_operation_gte_cmp_iseq

	rts

if_operation_gte_cmp_iseq:
	;Greater/equal.
	lda if_true_line
	sta number
	lda if_true_line+1
	sta number+1

	jsr fpl_goto

	rts

;;;;;

if_type_mismatch_error_1:
	jmp if_type_mismatch_error
	
if_operation_gt_cmp:
	lda if_type_a
	cmp if_type_b
	bne if_type_mismatch_error_1

	;Make sure type is int. ADD LINES HERE TO SUPPORT FLOAT
	lda if_type_a
	cmp type_str
	beq if_type_mismatch_error_1


	lda sdbuf
	sta number
	lda sdbuf+1
	sta number+1
	lda sdbuf+2
	sta number+2
	lda sdbuf+3
	sta number+3

	lda command
	sta result
	lda command+1
	sta result+1
	lda command+2
	sta result+2
	lda command+3
	sta result+3


	jsr fpl_int_cmp

	lda op_result_reg
	cmp #1
	beq if_operation_gt_cmp_iseq

	rts

if_operation_gt_cmp_iseq:
	;Greater/equal.
	lda if_true_line
	sta number
	lda if_true_line+1
	sta number+1

	jsr fpl_goto

	rts

;;;;;
	
if_operation_lte_cmp:
	lda if_type_a
	cmp if_type_b
	bne if_type_mismatch_error_1

	;Make sure type is int. ADD LINES HERE TO SUPPORT FLOAT
	lda if_type_a
	cmp type_str
	beq if_type_mismatch_error_1

	lda sdbuf
	sta number
	lda sdbuf+1
	sta number+1
	lda sdbuf+2
	sta number+2
	lda sdbuf+3
	sta number+3

	lda command
	sta result
	lda command+1
	sta result+1
	lda command+2
	sta result+2
	lda command+3
	sta result+3


	jsr fpl_int_cmp

	lda op_result_reg
	beq if_operation_lte_cmp_iseq
	cmp #2
	beq if_operation_lte_cmp_iseq

	rts

if_operation_lte_cmp_iseq:
	;Less than/equal.
	lda if_true_line
	sta number
	lda if_true_line+1
	sta number+1

	jsr fpl_goto

	rts

;;;;;
	
if_operation_lt_cmp:
	lda if_type_a
	cmp if_type_b
	bne if_type_mismatch_error_2

	;Make sure type is int. ADD LINES HERE TO SUPPORT FLOAT
	lda if_type_a
	cmp type_str
	beq if_type_mismatch_error_2

	lda sdbuf
	sta number
	lda sdbuf+1
	sta number+1
	lda sdbuf+2
	sta number+2
	lda sdbuf+3
	sta number+3

	lda command
	sta result
	lda command+1
	sta result+1
	lda command+2
	sta result+2
	lda command+3
	sta result+3


	jsr fpl_int_cmp

	lda op_result_reg
	cmp #2
	beq if_operation_lt_cmp_iseq

	rts

if_operation_lt_cmp_iseq:
	;Less than/equal.
	lda if_true_line
	sta number
	lda if_true_line+1
	sta number+1

	jsr fpl_goto

	rts

if_type_mismatch_error_2:
	jmp if_type_mismatch_error




;input
tokenize_input:
	lda command
	cmp #"i"
	bne not_tokenize_input
	lda command+1
	cmp #"n"
	bne not_tokenize_input
	lda command+2
	cmp #"p"
	bne not_tokenize_input
	lda command+3
	cmp #"u"
	bne not_tokenize_input
	lda command+4
	cmp #"t"
	bne not_tokenize_input
	lda command+5
	bne not_tokenize_input

	jsr check_param
	bcc continue_tokenizing_input

	ldx fpl_error_param_required
	jsr raise_fpl_error
	jmp fpl_error_done

continue_tokenizing_input:
	lda token_input
	clc
	rts
not_tokenize_input:
	sec
	rts



run_input:
	lda command
	cmp token_input
	beq found_input
	rts

found_input:
	;Split param
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	lda #"," ;Char to search for

	jsr strtolist
	
	lda length
	cmp #2
	beq start_input

	jsr print_fpl_error_line
	ldx incorrect_number_of_parameters
	jsr raise_fpl_error
	jmp fpl_run_error_done

quotes_missing_input:
	jsr print_fpl_error_line
	ldx quotes_missing
	jsr raise_fpl_error
	jmp fpl_run_error_done


start_input:
	jsr reset_sdbuf
	jsr reset_opbuf

	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	lda #0
	sta strindex_

	jsr strlistindex


	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	lda #1
	sta strindex_

	jsr strlistindex


	;Prompt in sdbuf
	;Varname in opbuf


	lda #<sdbuf
	sta ptra_low
	lda #>sdbuf
	sta ptra_high

	jsr reset_charbuf

	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high

	jsr get_data_in_quotes
	bcs quotes_missing_input

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	jsr reset_sdbuf
	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	jsr strcpy



	;Do input

	lda #13
	sta singlecharbuf
	jsr printchar

	lda #<sdbuf
	sta ptra_low
	lda #>sdbuf
	sta ptra_high

	jsr reset_charbuf
	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high

	jsr strcpy

	jsr print

	jsr input
	;jsr print


	lda #<opbuf
	sta ptr_low
	lda #>opbuf
	sta ptr_high
	
	jsr search_str
	bcs input_data_var_not_found

	bra input_data_var

input_data_var_not_found:
	;Not variable
	jsr print_fpl_error_line
	ldx fpl_error_var_not_found
	jsr raise_fpl_error
	jmp fpl_run_error_done


input_data_var:
	cpx type_int
	beq type_mismatch_input

	cpx type_str
	beq input_data_var_str

input_data_var_str:
	lda #<opbuf
	sta ptr_low
	lda #>opbuf
	sta ptr_high

	lda #<charbuf
	sta ptra_low
	lda #>charbuf
	sta ptra_high

	ldx type_str
	jsr fpl_create_variable ;Re init str variable

	lda #13
	sta singlecharbuf
	jsr printchar

	rts

type_mismatch_input:
	jsr print_fpl_error_line
	ldx type_mismatch
	jsr raise_fpl_error
	jmp fpl_run_error_done




;str
tokenize_str:
	lda command
	cmp #"s"
	bne not_tokenize_str
	lda command+1
	cmp #"t"
	bne not_tokenize_str
	lda command+2
	cmp #"r"
	bne not_tokenize_str
	lda command+3
	bne not_tokenize_str
	
	lda token_str
	clc
	rts
not_tokenize_str:
	sec
	rts



run_str:
	lda command
	cmp token_str
	beq found_str
	rts

found_str:
	;Split param
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	lda #"=" ;Char to search for

	jsr strtolist
	
	lda length
	cmp #2
	beq create_str_var_runint

	jsr print_fpl_error_line
	ldx incorrect_number_of_parameters
	jsr raise_fpl_error
	jmp fpl_run_error_done


create_str_var_runint:
	jsr reset_sdbuf
	jsr reset_opbuf

	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	lda #0
	sta strindex_

	jsr strlistindex


	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	lda #1
	sta strindex_

	jsr strlistindex


	;Varname is in sdbuf
	;Data in opbuf
	lda #<opbuf
	sta ptra_low
	lda #>opbuf
	sta ptra_high

	jsr reset_charbuf

	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high

	jsr get_data_in_quotes
	bcs quotes_missing_str_

	lda #<sdbuf
	sta ptr_low
	lda #>sdbuf
	sta ptr_high

	lda ptrb_low
	sta ptra_low
	lda ptrb_high
	sta ptra_high

	ldx type_str
	jsr fpl_create_variable
	bcc create_str_done

	jsr print_fpl_error_line
	ldx fpl_error_varname_to_long
	jsr raise_fpl_error
	jmp fpl_error_done

quotes_missing_str_:
	jsr print_fpl_error_line
	ldx quotes_missing
	jsr raise_fpl_error
	jmp fpl_error_done

create_str_done:
	
	rts


;int
tokenize_int:
	lda command
	cmp #"i"
	bne not_tokenize_int
	lda command+1
	cmp #"n"
	bne not_tokenize_int
	lda command+2
	cmp #"t"
	bne not_tokenize_int
	lda command+3
	bne not_tokenize_int
	
	lda token_int
	clc
	rts
not_tokenize_int:
	sec
	rts



run_int:
	lda command
	cmp token_int
	beq found_int
	rts

found_int:
	;Split param
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	lda #"=" ;Char to search for

	jsr strtolist
	
	lda length
	cmp #2
	beq create_int_var_runint

	jsr print_fpl_error_line
	ldx incorrect_number_of_parameters
	jsr raise_fpl_error
	jmp fpl_run_error_done


create_int_var_runint:
	jsr reset_sdbuf
	jsr reset_opbuf

	lda #<param
	sta ptra_low
	lda #>param
	sta ptra_high

	lda #<sdbuf
	sta ptrb_low
	lda #>sdbuf
	sta ptrb_high

	lda #0
	sta strindex_

	jsr strlistindex


	lda #<opbuf
	sta ptrb_low
	lda #>opbuf
	sta ptrb_high

	lda #1
	sta strindex_

	jsr strlistindex


	;Varname is in sdbuf
	;Data in opbuf

	;Str to float
	lda #<opbuf
	sta ptr_low
	lda #>opbuf
	sta ptr_high
	jsr strlen

	lda length
	sta length_reg

	stz result

	jsr fpl_str_to_num



	lda #<sdbuf
	sta ptr_low
	lda #>sdbuf
	sta ptr_high

	ldx type_int

	jsr fpl_create_variable
	bcc create_int_done

	jsr print_fpl_error_line
	ldx fpl_error_varname_to_long
	jsr raise_fpl_error
	jmp fpl_error_done

create_int_done:
	
	rts

;cls
tokenize_cls:
	lda command
	cmp #"c"
	bne not_tokenize_cls
	lda command+1
	cmp #"l"
	bne not_tokenize_cls
	lda command+2
	cmp #"s"
	bne not_tokenize_cls
	lda command+3
	bne not_tokenize_cls
	
	lda token_cls
	clc
	rts
not_tokenize_cls:
	sec
	rts



run_cls:
	lda command
	cmp token_cls
	beq found_cls
	rts

found_cls:
	jsr cls
	rts



;end
tokenize_end:
	lda command
	cmp #"e"
	bne not_tokenize_end
	lda command+1
	cmp #"n"
	bne not_tokenize_end
	lda command+2
	cmp #"d"
	bne not_tokenize_end
	lda command+3
	bne not_tokenize_end

	lda token_end
	clc
	rts
not_tokenize_end:
	sec
	rts




;println
tokenize_println:
	lda command
	cmp #"p"
	bne not_tokenize_println
	lda command+1
	cmp #"r"
	bne not_tokenize_println
	lda command+2
	cmp #"i"
	bne not_tokenize_println
	lda command+3
	cmp #"n"
	bne not_tokenize_println
	lda command+4
	cmp #"t"
	bne not_tokenize_println
	lda command+5
	cmp #"l"
	bne not_tokenize_println
	lda command+6
	cmp #"n"
	bne not_tokenize_println
	lda command+7
	bne not_tokenize_println

	jsr check_param
	bcc continue_tokenizing_println

	ldx fpl_error_param_required
	jsr raise_fpl_error
	jmp fpl_error_done

continue_tokenizing_println:
	lda token_println
	clc
	rts
not_tokenize_println:
	sec
	rts



run_println:
	lda command
	cmp token_println
	beq found_println
	rts

found_println:
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	jsr get_data_param_werror

	cmp #0
	beq println_data_int
	
	cmp #1
	beq println_data_str

	cmp #2
	beq println_data_var


println_data_str:
	jsr print
	lda #13
	sta singlecharbuf
	jsr printchar
	rts

println_data_int:
	jsr bin_to_dec
	lda #13
	sta singlecharbuf
	jsr printchar
	rts

println_data_var:
	cpx type_int
	beq println_data_var_int

	cpx type_str
	beq println_data_var_str

	cpx type_float
	beq println_data_var_float


println_data_var_float:
	jsr fpl_num_to_str
	lda #<opbuf
	sta ptra_low
	lda #>opbuf
	sta ptra_high
	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high
	jsr strcpy
	jsr print
	
	lda #13
	sta singlecharbuf
	jsr printchar
	rts

println_data_var_str:
	jsr print

	lda #13
	sta singlecharbuf
	jsr printchar
	rts

println_data_var_int:
	jsr bin_to_dec
	lda #13
	sta singlecharbuf
	jsr printchar
	rts






;print
tokenize_print:
	lda command
	cmp #"p"
	bne not_tokenize_print
	lda command+1
	cmp #"r"
	bne not_tokenize_print
	lda command+2
	cmp #"i"
	bne not_tokenize_print
	lda command+3
	cmp #"n"
	bne not_tokenize_print
	lda command+4
	cmp #"t"
	bne not_tokenize_print
	lda command+5
	bne not_tokenize_print

	jsr check_param
	bcc continue_tokenizing_print

	ldx fpl_error_param_required
	jsr raise_fpl_error
	jmp fpl_error_done

continue_tokenizing_print:
	lda token_print
	clc
	rts
not_tokenize_print:
	sec
	rts



run_print:
	lda command
	cmp token_print
	beq found_print
	rts

found_print:
	lda #<param
	sta ptr_low
	lda #>param
	sta ptr_high

	jsr get_data_param_werror

	cmp #0
	beq print_data_int
	
	cmp #1
	beq print_data_str

	cmp #2
	beq print_data_var


print_data_str:
	jsr print
	rts

print_data_int:
	jsr bin_to_dec
	rts

print_data_var:
	cpx type_int
	beq print_data_var_int

	cpx type_str
	beq print_data_var_str

	cpx type_float
	beq print_data_var_float


print_data_var_float:
	jsr fpl_num_to_str
	lda #<opbuf
	sta ptra_low
	lda #>opbuf
	sta ptra_high
	lda #<charbuf
	sta ptrb_low
	lda #>charbuf
	sta ptrb_high
	jsr strcpy
	jsr print
	rts

print_data_var_str:
	jsr print
	rts

print_data_var_int:
	jsr bin_to_dec
	rts










;goto
tokenize_goto:
	lda command
	cmp #"g"
	bne not_tokenize_goto
	lda command+1
	cmp #"o"
	bne not_tokenize_goto
	lda command+2
	cmp #"t"
	bne not_tokenize_goto
	lda command+3
	cmp #"o"
	bne not_tokenize_goto
	lda command+4
	bne not_tokenize_goto

	jsr check_param
	bcc goto_param

	ldx fpl_error_param_required
	jsr raise_fpl_error
	jmp fpl_error_done


goto_param:
	lda token_goto
	clc
	rts
not_tokenize_goto:
	sec
	rts


run_goto:
	lda command
	cmp token_goto
	beq found_goto
	rts

found_goto:
	jsr mov_param_opbuf

	jsr dec_to_bin

	jsr fpl_goto

	rts

;comment
tokenize_comment:
	lda command
	cmp #"#"
	bne not_tokenize_comment
	lda command+1
	bne not_tokenize_comment

	lda token_comment
	clc
	rts
not_tokenize_comment:
	sec
	rts
