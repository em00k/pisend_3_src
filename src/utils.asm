
;------------------------------------------------------------------------------
; Utils 

getRegister:
getreg:
; IN A > Register to read 
; OUT A < Value of Register 
    
			push    bc                                  ; save BC 
			ld      bc, TBBLUE_REGISTER_SELECT_P_243B
			out     (c), a 
			inc     b 
			in      a, (c) 
			pop     bc 
			ret 


saveAllBanks:
			ld 		b, 6
			ld 		a, 2 
1			push	bc 
			push 	af 
			call 	saveBankSlot
			pop		af 
			inc 	a 
			pop 	bc 
			djnz	1B
			ret 

restoreAllBanks:
			ld 		b, 6
			ld 		a, 2 
2			push	bc 
			push 	af 
			call 	restoreBankSlot
			pop		af 
			inc 	a 
			pop 	bc 
			djnz	2B
			ret 


saveBankSlot: 
; Saves the slot in A to the buffer 
; IN A > SLOT to save, 0-7 
; OUT nothing 
; USES : hl, a 

			ld      hl, slotBuffers
			add     hl, a 
			add     $50         
			call    getRegister
			ld      (hl), a 
			ret 

restoreBankSlot: 
; Restores the buffer to SLOT 
; IN A > SLOT to save, 0-7 
; OUT nothing 
; USES : hl, a 

			ld      hl, slotBuffers
			add     hl, a
			add     $50 
			ld      (.bank+2), a 
			ld      a, (hl)      
.bank: 
			nextreg $50, a 
			ret 


slotBuffers:
    db      $ff, $ff, $0a, $0b, $04, $05, $00, $01  ; default


freebanks:
			ld 	a, (banks_set)
			or	a
			ret z 
			ld a,(bank3) : call free 
			ld a,(bank4) : call free 
			ld a,(bank5) : call free 
			ld a,(bank6) : call free 
			ld a,(bank7) : call free 
			ret 

free:		ld hl,$0003  	; H=banktype (ZX=0, 1=MMC); L=reason (1=allocate)
			ld e,a
			exx
			ld c,7 			; RAM 7 required for most IDEDOS calls
			ld de,$01bd 	; IDE_BANK
			rst $8 : defb $94 ; M_P3DOS
freeend: 	
			ret

bank3       db 0 
bank4       db 0 
bank5       db 0 
bank6       db 0 
bank7       db 0 


getbank:
			; NextZXOSAPI to ask the OS for a free bank 
			;
			ld hl,$0001  	; H=banktype (ZX=0, 1=MMC); L=reason (1=allocate)
			exx
			ld c,7 			; RAM 7 required for most IDEDOS calls
			ld de,$01bd 	; IDE_BANK
			rst $8:defb $94 ; M_P3DOS
			jp nc,.failed
			ld a,e 
			jr .notfailed

.failed:	; added this for when working in CSpect in
			;LOG "FAILED TO RESERVER BANK"
			ld a,34
			;ld hl,bank
			;dec (hl)
.notfailed:	ret 	

bank:       
			db 223

print_version:
			ld 		hl,version
			call 	print_at
			ret 


; Check for space
; 
; 
check_break:
	xor 	a 
	in 		a, ($fe)
	cpl
	and 	15
	jr		nz,._break_pressed
	ret
._break_pressed:
	LOG "BREAK"
	jp 		finish

; Count string 
; IN HL > pointer to zero term string
; OUT A < length of string 

count_str_length:

        ; hl is set 
        ld      b, 0 
        xor     a
.keep_counting:
        cp      (hl)
        jr      z, .no_size 
        inc     hl 
        inc     b 
        jr      nz, .keep_counting
.no_size:
        or      a 
        ld      a, b            ; size max = 255 
        ret 

print_rst16:    ; prints string in HL terminated with 0 
	    ld      a,(hl):inc hl:or a:ret z:rst 16:jr print_rst16

print_fname	;ld a,(quietmode) : bit 0,a : ret nz 
.subprint	ld a,(hl):inc hl:cp 0:ret z:rst 16:jr .subprint
			
print_at	;ld a,(quietmode) : bit 0,a : ret nz 
.subprint	ld a,(hl):inc hl:cp $ff:ret z:rst 16:jr .subprint
			
print_title	
			ld b,32
printloop:	;ld a,(quietmode) : bit 0,a : ret nz 
.subprint	
			ld a,(hl):inc hl : rst 16 : djnz .subprint : ld a,13 : rst 16 : ret 

; example 
; call sprint:db "Blocks used = ",0
; ld  hl,16384
; call prthex16
; di : halt 
; jp $ 


prthex16:
	    ld a,h:call prthex8:ld a,l
prthex8:
	    push af:swapnib:call prthex4:pop af
prthex4:
	    and 15:push hl:ld hl,hextab:add hl,a:ld a,(hl):pop hl
prtchr:
        push hl:push de:push bc:push af:exx:push hl:push de:push bc:exx:push ix:push iy
        rst $10
        pop iy:pop ix:exx:pop bc:pop de:pop hl:exx:pop af:pop bc:pop de:pop hl
        ret
sprint: 
        pop hl:call print:jp (hl)
print:  
        ld a,(hl):inc hl:or a:ret z:call prtchr:jr print

dec5:	ld	bc,10000:call dec0
dec4:	ld	bc,1000:call dec0
dec3:	ld	bc,100:call dec0
dec2:	ld	bc,10:call dec0
dec1:	ld	bc,1
dec0:	ld	a,'0'-1
.lp:	inc a:or a:sbc hl,bc:jr nc,.lp
		add hl,bc
        jp prtchr
	
hextab:	db "0123456789ABCDEF"


; combined routine for conversion of different sized binary numbers into
; directly printable ascii(z)-string
; input value in registers, number size and -related to that- registers to fill
; is selected by calling the correct entry:
;
;  entry  inputregister(s)  decimal value 0 to:
;   b2d8             a                    255  (3 digits)
;   b2d16           hl                  65535   5   "
;   b2d24         e:hl               16777215   8   "
;   b2d32        de:hl             4294967295  10   "
;   b2d48     bc:de:hl        281474976710655  15   "
;   b2d64  ix:bc:de:hl   18446744073709551615  20   "
;
; the resulting string is placed into a small buffer attached to this routine,
; this buffer needs no initialization and can be modified as desired.
; the number is aligned to the right, and leading 0's are replaced with spaces.
; on exit hl points to the first digit, (b)c = number of decimals
; this way any re-alignment / postprocessing is made easy.
; changes: af,bc,de,hl,ix
; p.s. some examples below

; by alwin henseler


b2d8:    	ld h,0
			ld l,a
b2d16:   	ld e,0
b2d24:   	ld d,0
b2d32:   	ld bc,0
b2d48:   	ld ix,0          ; zero all non-used bits
b2d64:   	ld (b2dinv),hl
			ld (b2dinv+2),de
			ld (b2dinv+4),bc
			ld (b2dinv+6),ix ; place full 64-bit input value in buffer
			ld hl,b2dbuf
			ld de,b2dbuf+1
			ld (hl)," "
b2dfilc: equ $-1         ; address of fill-character
			ld bc,18
			ldir            ; fill 1st 19 bytes of buffer with spaces
			ld (b2dend-1),bc ;set bcd value to "0" & place terminating 0
			ld e,1          ; no. of bytes in bcd value
			ld hl,b2dinv+8  ; (address msb input)+1
			ld bc,#0909
			xor a
b2dskp0:	dec b
			jr z,b2dsiz     ; all 0: continue with postprocessing
			dec hl
			or (hl)         ; find first byte <>0
			jr z,b2dskp0
b2dfnd1:	dec c
			rla
			jr nc,b2dfnd1   ; determine no. of most significant 1-bit
			rra
			ld d,a          ; byte from binary input value
b2dlus2:	push hl
			push bc
b2dlus1: 	ld hl,b2dend-1  ; address lsb of bcd value
			ld b,e          ; current length of bcd value in bytes
			rl d            ; highest bit from input value -> carry
b2dlus0: 	ld a,(hl)
			adc a,a
			daa
			ld (hl),a       ; double 1 bcd byte from intermediate result
			dec hl
			djnz b2dlus0    ; and go on to double entire bcd value (+carry!)
			jr nc,b2dnxt
			inc e           ; carry at msb -> bcd value grew 1 byte larger
			ld (hl),1       ; initialize new msb of bcd value
b2dnxt:  	dec c
			jr nz,b2dlus1   ; repeat for remaining bits from 1 input byte
			pop bc          ; no. of remaining bytes in input value
			ld c,8          ; reset bit-counter
			pop hl          ; pointer to byte from input value
			dec hl
			ld d,(hl)       ; get next group of 8 bits
			djnz b2dlus2    ; and repeat until last byte from input value
b2dsiz:  	ld hl,b2dend    ; address of terminating 0
			ld c,e          ; size of bcd value in bytes
			or a
			sbc hl,bc       ; calculate address of msb bcd
			ld d,h
			ld e,l
			sbc hl,bc
			ex de,hl        ; hl=address bcd value, de=start of decimal value
			ld b,c          ; no. of bytes bcd
			sla c           ; no. of bytes decimal (possibly 1 too high)
			ld a,"0"
			rld             ; shift bits 4-7 of (hl) into bit 0-3 of a
			cp "0"          ; (hl) was > 9h?
			jr nz,b2dexph   ; if yes, start with recording high digit
			dec c           ; correct number of decimals
			inc de          ; correct start address
			jr b2dexpl      ; continue with converting low digit
b2dexp:  	rld             ; shift high digit (hl) into low digit of a
b2dexph: 	ld (de),a       ; record resulting ascii-code
			inc de
b2dexpl: 	rld
			ld (de),a
			inc de
			inc hl          ; next bcd-byte
			djnz b2dexp     ; and go on to convert each bcd-byte into 2 ascii
			sbc hl,bc       ; return with hl pointing to 1st decimal
			ret

b2dinv:  	ds 8            ; space for 64-bit input value (lsb first)
b2dbuf:  	ds 20           ; space for 20 decimal digits
b2dend:  	ds 1            ; space for terminating 0

print_A:

			; >> input a 
			call    b2d8 
			ld      hl, b2dend-2
			call    print_rst16
			ret 
print_AA:

			; >> input hl
			call    b2d16 
			ld      hl, b2dend-5
			call    print_rst16
			ret 

div32_16:
			; https://www.omnimaga.org/asm-language/(z80)-32-bit-by-16-bits-division-and-32-bit-square-root/msg406903/#msg406903
			;this divides hlix by bc
			;the result is stored in hlix, the remainder in de
			;bc is unmodified
			;a is 0
			;it doesnt use any other registers or ram
			ld de,0  ; 10
			ld a,32  ; 7
div32_16loop:
			add ix,ix  ; 15
			adc hl,hl  ; 15
			ex de,hl  ; 4
			adc hl,hl  ; 15
			or a   ; 4
			sbc hl,bc  ; 15
			inc ix   ; 10
			jr nc,cansub  ; 12/7
			add hl,bc  ; 11
			dec ix  ; 10
cansub:
			ex de,hl  ; 4
			dec a   ; 4
			jr nz,div32_16loop ; 12/7
			ret   ; 1
	

clear_screen:

			ld		hl, blankline_at 
			call 	print_at

			ld 		b, 22
.loop: 
			push 	bc
			ld		hl, blankline_txt
			call 	print_rst16
			pop 	bc 
			djnz	.loop 

			ld		hl, blankline_at 
			call 	print_at

			ret 

Reg2Asc:
		; hl number to print 
		; Asciibuffer will contain 
		;ld		bc,-10000
		;call	Num1
		;ld		bc,-1000
		;call	Num1
		ld		bc,-100
		call	Num1
		ld		c,-10
		call	Num1
		ld		c,-1
Num1:	ld		a,'0'-1
Num2:	inc		a
		add		hl,bc
		jr		c,Num2
		sbc		hl,bc
		rst 	16 
		ret 

	
;////////////////////////////////////////////////
;// convert string to HL  
;// de = start of string  
;// out hl = number 
;// Taken from Remy Sharp's http https://github.com/remy/next-http/blob/911673f56b806c76762ca68c891d8aeb1c929f6d/src/utils.asm#L92

string_to_hl:


			ld 		hl, 0				; flatten hl 
.convLoop:
			ld 		a, (de)				; get digit from left 
			or 		a					; is it 0
			ret 	z					; yes then exit / return 

			sub		$30					; sub $30 to get 0-9 from a 
			ret		c					; exit if a is less $30

			scf							; set cf
			cp 		$0a					; if a > 10 error 
			jr 		nc, .error

			inc 	de					; move to next string char 

			ld 		b, h				
			ld 		c, l

			add 	hl, hl				; (HL * 4 + HL) * 2 = HL * 10
			add 	hl, hl
			add 	hl, bc
			add 	hl, hl

			add 	a, l
			ld 		l, a
			jr 		nc, .convLoop
			inc 	h
			jr 		.convLoop

.error:
			scf
			ret