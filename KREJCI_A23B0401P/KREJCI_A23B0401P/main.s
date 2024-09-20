		.h8300s
;-----definice sekce .vects------------------------
; sekce .vects obsahuje adresu symbolicke promenne _start.
; Sestavovaci program ulozi sekci do pameti od adresy
; 0x000000. Tim je po resetu zajisteno spusteni programu
; od adresy _start.
 
        .section    .vects,"a",@progbits
rs:        .long        _start        

;-----definice uzitecnych symbolu------------------
        .equ    syscall,0x1FF00    ; simulated IO area
        .equ    PUTS,0x0114        ; kod PUTS
        .equ    GETS,0x0113        ; kod GETS

; ------ datova sekce ------------------------------
        .data
		
dec_c:						;desetinne rady
		.long 1
		.long 10
		.long 100
		.long 1000
		.long 10000
		.align 1
		.space 100

vstup:    .space 100
result:   .space 50
prompt:    .asciz "-->\n\r"
minus:	   .asciz "-"
goodbye:   .asciz "Thanks for using me! See you later."
undefined: .asciz "Undefined."
tab:	   .asciz "\n\r"

        .align 2

par_vstup:    .long vstup
par_prompt:   .long prompt
par_result:	  .long result
par_minus:	  .long minus
par_goodbye:  .long goodbye
par_undefined:.long undefined 
par_tab:	  .long tab

		
        .align 1
        .space 100

stck:
        .text
        .global        _start
		
		
;...      			sekce registru					...


_start:
;...				zde probehne nulovani registru	...
;zakladni implementace registru, vlozeni pomocne nuly, vypsani pokynu apod.
	
	xor.l ER2, ER2
	xor.l ER3, ER3
	xor.l ER4, ER4
	xor.l ER5, ER5
	xor.l ER6, ER6
	
	mov.l #stck, ER7
	mov.l #vstup, ER2
	
	
	mov.w #PUTS, R0
	mov.l #par_prompt, ER1
	jsr @syscall
	
	mov.w #GETS, R0			
	mov.l #par_vstup, ER1
	jsr @syscall
	

	mov.b @ER2, R4L
	mov.b #'0', R4H				;presune ascii hodnotu '0' (0x30) do registru R4H
	
	xor ER1, ER1
	mov.l #dec_c, ER1			;presune desetinne rady do registru ER1
	
	add #0x0A, ER3 ;****************************
	push.l ER3
	xor.l ER3, ER3
	
	jmp @string_check


string_check:
;projizdi vstup uzivatele a podle toho urcuje dalsi krok programu
;pricita jednicky, doku se cisla nerovnaji, v pripade spatneho vstupu
;se zepta na vstup znova

			cmp.b #'e', R4L
			beq bye
			cmp.b #'=', R4L	;pokud se jedna o rovna se, provede vypocet
			beq delete_process		;beq delete_process
			cmp.b #'+', R4L	;porovna, jestli jde o soucet
			beq process
			cmp.b #'-', R4L	;porovna, jestli jde o rozdil
			beq process
			cmp.b #'/', R4L	;porovna, jestli jde o podil
			beq process
			cmp.b #'*', R4L	;porovna, jestli jde o soucin
			beq process
					
			cmp.b R4L, R4H	;porovnava cisla
			beq pridej
			
			cmp.b #0x40, R4H	;pokud byl zadan spatny znak, skonci se hned
			beq _start
			
			add #0x01, R4H	;pokud zadne cislo nesedelo, prida jedna a proces opakuje
			jmp @string_check
bye:
		mov.w #PUTS, R0
		mov.l #par_goodbye, ER1
		jsr @syscall
		jmp @loop
	
loop: jmp @loop
process:
;uklada prvni cislo do registru pomoci popovani ze zasobniku a naslednym
;nasobenim dekadickymi rady

		xor ER4, ER4
		xor ER6, ER6
		mov.b @ER1, ER6
		pop.l ER4				;TADY SE ZPUSOBUJE CHYBA SE ZASOBNIKEM
		cmp.l #0x0A, ER4 ;******************************************
		beq before_decrement
		add #0x01, R3L
		mulxu.w R6, ER4
		add.w R4, R5
		inc.l #2, ER1
		inc.l #2, ER1
		jmp @process
		
before_decrement:
;upravuje zasobnik do spravneho tvaru, aby nenastavala chyba s "pretecenym" 
;zasobnikem

		mov.l #0x0A, ER4
		push.l ER4
		xor ER4, ER4
		jmp @decrement_operation
continue:
;nastavi dalsi bit ze vstupu
;pripravi pomocnou nulu
		
		xor ER4, ER4
		;add #0x00, ER4
		;push.l ER4
		;xor ER4, ER4
		inc.l #1, ER2
		mov.b @ER2, R4L
		add #'0', R4H
		jmp @string_check

delete_process:
;pouze maze registry

		xor ER4, ER4
		xor ER6, ER6
		jmp @process2
		
pridej:
;prida cislo do zasobniku v dekadickem tvaru

		xor.b R4H, R4H
		add.b #-'0', R4L
		push.l ER4
		jmp @another
		
another:
;posune pointer a pripravi pomocnou nulu

		xor.b R4L, R4L
		add #'0', R4H
		inc.l #1, ER2		;posunuje pointer
		mov.b @ER2, R4L		;naplni dalsi bit do R4L
		jmp @string_check 	;proces se opakuje
		
decrement_operation:
;dekrementuje registr vstupu 

		cmp.l #0x00, ER3
		beq continue
		dec.l #2, ER1
		dec.l #2, ER1
		add #-0x01, R3L
		jmp @decrement_operation

process2:
		;volne registry: ER3, ER4, ER6- VYUZIT!!!!
		mov.b @ER1, ER4
		pop.l ER3
		cmp.l #0x0A, ER3 ;******************************************************
		beq reverse_string
		mulxu.w R3, ER4
		add.w R4, R6
		inc.l #2, ER1
		inc.l #2, ER1
		jmp @process2
		
reverse_string:
		dec.b #1, ER2
		mov.b @ER2, R4L
		cmp.b #'+', R4L	;porovna, jestli jde o soucet
		beq addition
		cmp.b #'-', R4L	;porovna, jestli jde o rozdil
		beq substraction
		cmp.b #'/', R4L	;porovna, jestli jde o podil
		beq division
		cmp.b #'*', R4L	;porovna, jestli jde o soucin
		beq multiplication
		jmp @reverse_string

multiplication:
		mulxu.l R5, ER6
		xor ER5, ER5
		xor ER4, ER4
		jmp @lab1

addition:
		add.l ER5, ER6
		mov.l #par_result, ER1
		jmp @move

substraction:
		;pokud je prave cislo vetsi nez leve
		;odecte se od vetsiho mensi a vlozi se minus pred cislo
		cmp.w R6, R5
		bhs	sub_fir_low
		cmp.w R6, R5
		bls sub_sec_low
		
sub_fir_low:
			;prvni cislo mensi nez druhe (R5<R6)
			;nutne doplnit '-' pred vysledek
			sub.w R6 ,R5
			xor.l ER6, ER6
			mov.l ER5, ER6		;vysledek do ER6
			xor ER3, ER3
			xor ER4, ER4
			xor ER5, ER5
			jmp @lab1

sub_sec_low:
			;druhe cislo mensi nez prvni (R6<R5)
			xor ER3, ER3
			xor ER4, ER4
			sub.w R5, R6		;vysledek v ER6
			xor ER5, ER5
			mov.w #'-', E4
			jmp @minus_print
			
division:
		xor ER4, ER4
		xor ER3, ER3
		cmp.l #0x00, ER6
		beq undef
		cmp.l ER6, ER5
		blt div_fir_low
		cmp.l ER6, ER5
		bhs div_sec_low
		divxu.l R6, ER5

undef:
		mov.w #PUTS, R0
		mov.l #par_undefined, ER1
		jsr @syscall
		jmp @_start

div_fir_low:
		mov.l #0x30, ER6    ;vysledek s desetinnou teckou vraci jako 0
		jmp @zero_result

div_sec_low:
		divxu.l R6, ER5
		xor.l ER6, ER6
		mov.l ER5, ER6
		xor ER5, ER5
		jmp @move
		
		
move:
		xor ER4, ER4
		xor ER5, ER5
		jmp @lab1
		
lab_jedna:
			mov.l #0x2710, ER3
			sub.l ER3, ER6
			inc.b R4L 		;R4L rady deseti tisice
			jmp @lab1

lab_dva:
			mov.l #0x3E8, ER3 
			sub.l ER3, ER6
			inc.b R4H		;R4H rady tisice
			jmp @lab2
lab_tri:
			mov.l #0x64, ER3
			sub.l ER3, ER6
			inc.b R5L		;R5L rady stovek
			jmp @lab3

lab_ctyri: 
			mov.l #0x0A, ER3
			sub.l ER3, ER6
			inc.b R5H		;R5H rady desitek
			jmp @lab4

lab_pet:	
			mov.l #0x01, ER3
			sub.l ER3, ER6
			inc.w #1, E5		;E5 rady jednotek
			jmp @lab5

lab1:
		cmp.l #0x2710, ER6
		bcc lab_jedna
lab2:
		cmp.l #0x3E8, ER6
		bcc lab_dva
lab3:
		cmp.l #0x64, ER6
		bcc lab_tri
lab4:
		cmp.l #0x0A, ER6
		bcc lab_ctyri
lab5:
		cmp.l #0x01, ER6
		bcc lab_pet


first_char:
			xor ER3,ER3
			cmp.b #0x00, R4L
			beq does_not_start_10k
			jmp @from10k
			
does_not_start_10k:
;kontroluje, jestli registr tisicu je prazdny
			cmp.b #0x00, R4H
			beq does_not_start_1k
			jmp @from1k

does_not_start_1k:
;kontroluje, jestli registr stovek je prazdny
			cmp.b #0x00, R5L
			beq does_not_start_hund
			jmp @fromhund
			
does_not_start_hund:
;kontroluje, jestli registr desitek je prazdny
			cmp.b #0x00, R5H
			beq does_not_start_tens
			jmp @fromtens
			
does_not_start_tens:
;kontroluje, jestli registr jednotek je prazdny
			cmp.w #0x00, E5
			beq zero_result
			jmp @fromones
			
zero_result:
			


from10k:
		xor ER6, ER6	;counter cisel
		mov.l #result, ER3
		
		
		add #0x30, R4L
		mov.l R4L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		add #0x30, R4H
		mov.l R4H, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		add #0x30, R5L
		mov.l R5L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		add #0x30, R5H
		mov.l R5H, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		xor R5H, R5H
		mov.w E5, R5
		add.w #0x30, R5L
		mov.b R5L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		jmp @pokus
from1k:
		xor ER6, ER6	;counter cisel
		mov.l #result, ER3
		
		add #0x30, R4H
		mov.l R4H, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		add #0x30, R5L
		mov.l R5L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		add #0x30, R5H
		mov.l R5H, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		xor R5H, R5H
		mov.w E5, R5
		add.w #0x30, R5L
		mov.b R5L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		jmp @pokus
fromhund:
		xor ER6, ER6	;counter cisel
		mov.l #result, ER3
		
		add #0x30, R5L
		mov.l R5L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		add #0x30, R5H
		mov.l R5H, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		xor R5H, R5H
		mov.w E5, R5
		add.w #0x30, R5L
		mov.b R5L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		jmp @pokus
		
fromtens:
		xor ER6, ER6	;counter cisel
		mov.l #result, ER3
		
		add #0x30, R5H
		mov.l R5H, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		xor R5H, R5H
		mov.w E5, R5
		add.w #0x30, R5L
		mov.b R5L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
		jmp @pokus
		
fromones:
		xor ER6, ER6	;counter cisel
		mov.l #result, ER3
		
		xor R5H, R5H
		mov.w E5, R5
		add.w #0x30, R5L
		mov.b R5L, @ER3
		inc.l #1, ER3
		inc.l #1, ER6
		
pokus:

		mov.w #PUTS, R0
		mov.l #par_result, ER1
		jsr syscall

		mov.w #PUTS, R0
		mov.l #par_tab, ER1
		jsr @syscall

		jmp @cleaning
		
minus_print:	
			
			mov.w #PUTS, R0
			mov.l #par_minus, ER1
			jsr @syscall
			jmp @lab1
			
cleaning:
		mov.b #0x00, R4L
		mov.b R4L, @ER3
		dec.b #1, ER6
		cmp.b #0x00, R6L
		beq delete_reg
		dec.l #1, ER3
		jmp @cleaning
		
delete_reg:

	xor.l ER2, ER2
	xor.l ER3, ER3
	xor.l ER4, ER4
	xor.l ER5, ER5
	xor.l ER6, ER6
	jmp @_start


	.end