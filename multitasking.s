;create_task
;Resgisters edited: A
;ptra is the pointer to task. ptrb is the pointer to task id string, ptr is pointer to stack for task. X is task id.
create_task:
	lda ptra_low
	sta taskptrlow,x
	lda ptra_high
	sta taskptrhigh,x

	lda ptrb_low
	sta taskidptrlow,x
	lda ptrb_high
	sta taskidptrhigh,x

	lda ptr_low
	sta taskstackptr_low,x
	lda ptr_high
	sta taskstackptr_high,x

	lda #0
	sta taskstackindex

	;Check if task to schedule is greater than taskmax
	txa 
	cmp taskmax
	beq tasknumeq
	bcs greaterthan_tasknum

	;Else

	rts

greaterthan_tasknum:
	inc taskmax
tasknumeq:
	rts


task1_task:
	lda #255
	sta DDRA2
	sta PORTA2
	jmp task1

task2_task:
	lda #255
	sta DDRB3
	sta PORTB3
	jmp task2