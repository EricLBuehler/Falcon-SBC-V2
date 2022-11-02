;String operations


;get_data_in_quotes
;Registers edited: A,X,Y
;String in in ptra. Output string in ptrb
;ptr is edited
;Carry set if fail, clear if success
get_data_in_quotes:
	lda ptra_low
	sta ptr_low
	lda ptra_high
	sta ptr_high

	jsr strlen
	dec length
	ldy length

	lda (ptr_low)
	cmp quote_chr
	bne get_data_in_quotes_fail

	lda (ptr_low),y
	cmp quote_chr
	bne get_data_in_quotes_fail

	ldy #1
	ldx length

	jsr strslice

	clc
	rts

get_data_in_quotes_fail:
	sec
	rts


;strslice
;Registers edited: A,Y,X
;Y is start pos
;X is end pos (excluisive)
;Input string in ptra_low / ptra_high.
;Output string in ptrb_low / ptrb_high.
strslice:
	stz strscratch
	sty strindex_
	dex
	stx strxbuf
strslice_loop:	
	ldy strindex_
	lda (ptra_low),y
	ldy strscratch
	sta (ptrb_low),y

	ldx strindex_
	inc strindex_
	inc strscratch
	cpx strxbuf
	bne strslice_loop

	rts
	

;isnumeric
;Registers edited: A,Y
;Carry clear if character is numeric, set if not.
;A is char
isnumeric:
	cmp #48
	bcc isnumeric_fail

	cmp #58 ;57=9
	bcs isnumeric_fail

	clc
	rts

isnumeric_fail:

	sec
	rts

;strlistindex
;Registers edited: A,Y,X
;ptra is input
;ptrb is the output
;index in strindex_

;If you want to get first index, set strindex_ to 0

;strcountera is start pos, strcounterb is end pos
strlistindex:
	stz strcountera
	stz strcounterb

	lda strindex_
	beq strlistindex_getmax_start

strlistindex_getmin:
	ldy strcountera
	lda (ptra_low),y
	bmi strlistindex_getmin_high_set ;High bit set

	inc strcountera

	jmp strlistindex_getmin

strlistindex_getmin_high_set:
	inc strcountera
	inc strcounterb ;Next split

	lda strcounterb
	cmp strindex_
	bne strlistindex_getmin
	
strlistindex_getmin_done:
	lda strcountera
	sta strminindex




	;strcountera and strcounterb is kept, this is an optimization

strlistindex_getmax_start:
	lda strindex_
	inc
	sta strscratch

strlistindex_getmax:
	ldy strcountera
	lda (ptra_low),y
	bmi strlistindex_getmax_high_set ;High bit set

	inc strcountera

	jmp strlistindex_getmax

strlistindex_getmax_high_set:
	inc strcountera
	inc strcounterb

	lda strcounterb
	cmp strscratch
	bne strlistindex_getmax

strlistindex_getmax_done:
	lda strindex_
	bne not_zero_strlistindex


	;else

	lda strcountera
	dec
	sta strmaxindex

	stz strcountera

	stz strcounterb

	jmp strlistindex_split

not_zero_strlistindex:
	lda strcountera
	dec
	sta strmaxindex

	lda strminindex
	sta strcountera

	stz strcounterb

strlistindex_split:	
	ldy strcountera
	lda (ptra_low),y
	ldy strcounterb
	sta (ptrb_low),y

	inc strcountera
	inc strcounterb

	lda strcountera
	cmp strmaxindex
	bne strlistindex_split

strlistindex_splitdone:

	ldy strcounterb
	lda #0
	sta (ptrb_low),y

	rts




;listtostr
;ptr is the string in/out
listtostr:
	ldy #0
listtostr_loop:
	lda (ptr_low),y
	and #%01111111
	sta (ptr_low),y

	iny
	bne listtostr_loop
	


;strtolist
;Registers edited: Y,X
;A is the char to split on
;ptr is the string in/out
;length is length of list
strtolist:
	ldy #0
	ldx #0
strtolist_loop:
	pha
	lda (ptr_low),y
	bne not_null_strtolist
	pla

	inx
	stx length
	rts

not_null_strtolist:
	pla
	cmp (ptr_low),y ;Compare char to search to char in string
	beq strtolist_charfound

	iny

	jmp strtolist_loop

strtolist_charfound:
	pha ;Save char in
	lda (ptr_low),y
	ora #$80 ;Set high bit
	sta (ptr_low),y
	pla

	iny
	inx

	jmp strtolist_loop

	

return_short24:
	jmp return

;strcount
;Registers edited: A,Y
;String in ptr_low / ptr_high
;Find and flag all occurances of chartofind.
;Count in fclindex
strcount:
	ldy #0

	stz fclindex

strcountloop:
	lda (ptr_low),y
	beq return_short24 ;Null, then return
	cmp chartofind
	beq found_strcount


	iny
	jmp strcountloop

found_strcount:
	inc fclindex

	iny
	jmp strcountloop


;strmatch
;Registers edited: A,Y
;String in ptr_low / ptr_high
;Find and flag all occurances of chartofind.
strmatch:
	ldy #0

strmatchloop:
	lda (ptr_low),y
	beq return_short24 ;Null, then return
	cmp chartofind
	beq found_strmatch

	lda #0
	sta charfindflags,y

	cpy #255
	beq return_short24

	iny
	jmp strmatchloop

found_strmatch:
	lda #1
	sta charfindflags,y

	cpy #255
	beq return_short24

	iny
	jmp strmatchloop

;strindexoccurance
;Registers edited: A,X,Y
;Get index of the charpos_charnum'th occurance of charpos.
;String in ptr_low / ptr_high
;Result in charpos_location
strindexoccurance:
	lda charpos
	sta chartofind
	jsr strmatch ;Make sure there is something to 'find'
	
	ldx #0 ;Char
	ldy #0 ;Chars found

strindexoccurance_loop:
	phy ;Y is already used, save it
	phx
	ply
	lda (ptr_low),y
	ply ;Pull saved Y value

	beq return_short24 ;Null, then return

	lda charfindflags,x
	cmp #1
	beq found_char_strindexoccurance

	cpx #255
	beq return_short24

	inx
	jmp strindexoccurance_loop

found_char_strindexoccurance:
	cpy charpos_charnum
	beq strindexoccurance_position_found

	iny

	inx
	jmp strindexoccurance_loop

strindexoccurance_position_found:
	
	stx charpos_location
	rts	

;strlen
;Registers edited: A,Y
;String in ptr_low / ptr_high
;Length in length
strlen:
	ldy #0

strlenloop:
	lda (ptr_low),y
	beq strlen_finished ;Null, then return

	iny
	jmp strlenloop

strlen_finished:
	;If 3 characters, length will hold 2
	sty length
	rts	

;strindex
;Registers edited: A
;String in ptr_low / ptr_high
;Index in string is Y
;Value returned in opbuf
strindex:
	lda (ptr_low),y
	sta opbuf
	rts	

;strwindex
;No registers edited
;String in ptr_low / ptr_high
;Index in string is Y
;Value to write  in A
strwindex:
	sta (ptr_low),y
	rts	

;strcmp
;Registers edited: A, Y
;String a in ptra_low / ptra_high
;String a in ptrb_low / ptrb_high
;A = 0 if stra and strb are equal, A = 1 if not equal
strcmp:
	ldy #0

strcmp_loop:
	;Check if either char is null
	lda (ptra_low),y 
	ora (ptrb_low),y 
	beq strcmp_done

	lda (ptra_low),y
	cmp (ptrb_low),y ;Actual compare
	bne strcmp_ne

	iny
	bne strcmp_loop

strcmp_ne:
	lda #1
	rts	

strcmp_done:
	lda #0
	rts

;strcpy
;Registers edited: A, Y
;String a in ptra_low / ptra_high
;String b in ptrb_low / ptrb_high
;Copies ptra to ptrb
strcpy:
	jmp mov_ptr_ptr
		
return_short25:
	jmp return	