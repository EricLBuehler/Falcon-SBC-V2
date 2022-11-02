;FOS strings
welcome: .byte "Welcome to FOS v1.5!",13,"Developed by Eric Buehler 2020.",00
fdosstarted: .byte 13,"FDOS started.",00
fclstarted: .byte 13,"FCL started.",13,00
fmonstarted: .byte 13,"FMON started.",00
cmd_not_found: .byte 13,"Command not found.",00
ram_amount: .byte 13,"528 kB RAM system. 512 kB high RAM.",0
initializing_memory: .byte "Zeroing High RAM...",0
memory_error: .byte "Memory error at ",0


;SD card library strings
file_opening_error: .byte 13,"FILE_ERROR: Cannot open file. Make sure the file exists and the sd card is mounted.",0
file_rm_error: .byte 13,"FILE_ERROR: Cannot remove file. Make sure the file exists and the sd card is mounted.",0
dir_rm_error: .byte 13,"DIR_ERROR: Cannot remove directory. Make sure the directory is empty, it exists and the sd card is mounted.",0
insert_sd: .byte 13,"Insert SD card.",0
bytes: .byte " byte(s).",0
dirstring: .byte "<DIR>",0
file_exists: .byte 13,"File or directory exists.",0
file_no_exists: .byte 13,"File or directory does not exist.",0
copy_fail: .byte 13,"Copy fail. File/directory to copy from/to does not exist.",0
autoexec: .byte "autoexec.exe",0

;FCL Strings
no_highram_error: .byte "Make sure your sytem has at least 512 kB of High RAM.",0
_1_mb_highram: .byte "1 mB High RAM system.",13,0
_512_kb_highram: .byte "512 kB High RAM system.",13,0
no_highram: .byte 13,"No High RAM.",13,0
fos_1_mb_highram: .byte 13,"1040 kB RAM system.",13,0
fos_512_kb_highram: .byte 13,"528 kB RAM system.",13,0
fcl_command_load_str: .byte "load",0