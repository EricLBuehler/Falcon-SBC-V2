;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;Address Labels (All addresses in hex)


;RAM:

;Print/input
charcounter = $600 ;1 byte
charbuf = $200 ;200-2FF

;Read/Print char
singlecharbuf = $2FF ;1 byte

;Find all (find all occurances of str)
charfindflags = $300 ;300-3FF
chartofind = $3FF ;Char to find

;Index char (find index of char)
charpos = $400 ;Char to find location of
charpos_charnum = $401 ;What number character to find at
charpos_location = $402 ;Char location (output)

;count (get count of char in charpos)
count_out = $47d

;Parse
charsplit = $403
command = $700 ;700-7FE
param = $800 ;800-8FE
parse_counter = $601 ;1 byte
counter1_parse = $408 ;1 byte
counter2_parse = $409 ;1 byte

;Bin to decimal
value = $403 ;4 bytes
mod10 = $407 ;4 bytes
message_out= $40B ;11 bytes: 10 bytes for number, 1 byte for null terminated string.
convert_counter = $41C
number = $411 ;411-414
b1 = $0415
b2 = $0416
b3 = $0417
b4 = $0418

;Math
num1 = $44b ;4 bytes
num2 = $42f ;4 bytes
result = $433 ;4 bytes
mathcounter = $437 ;4 bytes
remainder = $43b ;4 bytes
mulxp1 = $449
mulxp2 = $44a

;Length
length = $43f ;1 byte

;decimal to binary
dtb_mulby = $440 ;4 bytes 440-443
dtb_charcounter = $444
dtb_valuea = $445

;OpBuf (operation buffer, 256 bytes)
opbuf = $500

;Poke, peek, dump
address_buf = $0 ;2 bytes, needs to be in zero page
pokepeekbuf = $900 ;2 bytes

;CMD execution
cmddone = $8ff

;Copy, move buf
cpymve_buf = $900

;SD card
sdbuf = $1000 ;256 bytes

;mov_ptr
ptr_low = $2 ;1 byte
ptr_high = $3 ;1 byte

;Shift Register
srflags = $1101 ;1 byte, bit 0 is R/W (0 = R, 1 = W), bit 1 is the interrupted flag (1 = TRUE)
srbuf = $1102

;Coprocessor Interface. Start: 4608 (DEC)
command_reg = $1200 ;1 byte DECIMAL: 4608
op_result_reg = $1201 ;1 byte DECIMAL: 4609
length_reg = $1202 ;1 byte DECIMAL: 4610
op_done_reg = $1203 ;1 byte DECIMAL: 4611   0 when done, 1 when not done
size_reg_0 = $1204 ;1 byte DECIMAL: 4612
size_reg_1 = $1205 ;1 byte DECIMAL: 4613
size_reg_2 = $1206 ;1 byte DECIMAL: 4614
size_reg_3 = $1207 ;1 byte DECIMAL: 4615

;Clock
milliseconds = $1208 ;1208 - 1209
seconds = $120a ;120a
minutes = $120b ;120b
hours = $120c ;120c
days = $120d ;120d
uptime = $120f ; 8 bytes
uptimebuf = $1217 ; 8 bytes

;IRQ
;If USR IRQ routine finds an interrupt, it MUST pop the return address of the stack, handle the interrupt and jump to irq_done.
irq_low = $6
irq_high = $7
irq_buf = $121f ;1 byte
irq_buf1 = $1220 ;1 byte


;String operations
ptra_low = $8
ptra_high = $9
ptrb_low = $a
ptrb_high = $b

strindex_ = $1221
strmaxindex = $1222
strcountera = $1223
strcounterb = $1224
strminindex = $1225
strscratch = $1226
strxbuf = $1227

;FCL
fcl_ptr=$1228 ;2 bytes
infcl=$122a ;1 byte
fclindex=$122b ;1 byte


;OS RAM USED MAX: $122b
;ZP RAM USED MAX: $e


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;