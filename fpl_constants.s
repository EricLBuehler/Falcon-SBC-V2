;FPL tokens
;High bit set means that command is ignored.
token_print: .byte 1
token_goto: .byte 2
token_println: .byte 3
token_comment: .byte 4
token_end: .byte 5
token_cls: .byte 6
token_int: .byte 7
token_printvar: .byte 8
token_str: .byte 9
token_input: .byte 10
token_if: .byte 11
token_float: .byte 12
token_add: .byte 13

;Other defentitions
fpl_zero_max = %01000000
fpl_var_type_max = 2 ;Actutal max + 1

;FPL line constants
fpl_line_bank_max = %00010000
linecounter_max = 78

;FPL errors
fpl_error_param_required: .byte 0
fpl_error_varname_to_long: .byte 1
fpl_error_var_not_found: .byte 2
incorrect_number_of_parameters: .byte 3
parameter_to_long: .byte 4
get_data_param_error: .byte 5
quotes_missing: .byte 6
type_mismatch: .byte 7
fpl_if_operation_not_found: .byte 8
oom: .byte 9

;FPL variable constants

;Integer
type_int: .byte 0
;Below allows 16 kB of integer variable storage
int_bank_start = fpl_line_bank_max
int_bank_max = int_bank_start+2
intcounter_max = 221

;String
type_str: .byte 1
;Below allows 32 kB of integer variable storage
str_bank_start = int_bank_max
str_bank_max = str_bank_start+4
strcounter_max = 28

;Float
type_float: .byte 2
;Below allows 32 kB of integer variable storage
float_bank_start = str_bank_max
float_bank_max = float_bank_start+2
floatcounter_max = 221

