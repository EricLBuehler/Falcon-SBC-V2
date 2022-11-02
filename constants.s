;Conditional Assembly

;Comment out below to disable PS2
PS2_ENABLED = $0 ;Dummy defenition


;Constants
ctrl_c_chr: .byte 3
quote_chr: .byte '"'
esc_chr: .byte 27


bank_max=%10000001