; Encode BASE64.


; > HL = Source
; > DE = Destination
; > BC = Original data length (0 = 65536)

; < HL = Updated
; < DE = Updated
; < BC = Encoded length
	
encodebase64:	

			di
			ld	(labstack+1),sp

			ld	sp,hl			; SP = source
			add	hl,bc
			ld	(labhl+1),hl		; PTR+LEN
			ld	(labde+1),de		; LEN

			dec	bc

labpacket:	
			pop	hl			; Input (WORD)
			ld	a,b
			or	c			; >=1 ?
			jr	nz,labok
			ld	h,a			; NULL

labok:	
			ld	a,l
			ex	af,af'
			ld	a,h
			ld	h,encode256tab/256
			ldi				; Translate>Output
			inc	bc

			ld	l,a
			ex	af,af'
			rra
			rr	l
			rra
			rr	l
			ld	h,encode256tab/256
			ldi				; Translate>Output

		;	------------

			pop	hl			; Input (BYTE)
			dec	sp
			ld	a,b
			or	c
			jp	z,lab2bytes		; Zero?
			bit	7,b
			jp	z,lab3bytes		; Negative?

labpad2:	
			ld	a,'='			; Pad ==
			ld	(de),a
			inc	de
labpad1:	
			ld	a,'='			; Pad =
			ld	(de),a
			inc	de
			jr	labdone

		;	------------

lab2bytes:	
			ld	l,a			; NULL

lab3bytes:	
			ex	af,af'
			ld	h,a
			ex	af,af'
			add	hl,hl
			add	hl,hl
			ld	a,l
			res	7,h
			res	6,h
			ld	l,h
			ld	h,encode64tab/256
			ldi				; Translate>Output

			bit	7,b
			jr	nz,labpad1		; Negative?

			ld	l,a
			ld	h,encode256tab/256

			ld	a,b
			or	c
			ldi				; Translate>Output
			jp	nz,labpacket		; Zero?

		;	------------

labdone:	
			ld	h,d			; Calculate LEN
			ld	l,e
labde:	
			ld	bc,0
			xor	a			; CF=0
			sbc	hl,bc
			ld	b,h
			ld	c,l
labhl:	
			ld	hl,0			; Return PTR

labstack:	
			ld	sp,0
			ei
			ret 



; **MUST BE 256 BYTE ALIGNED**


decode256_tab:
	db	0		;     0
	db	0		;     1
	db	0		;     2
	db	0		;     3
	db	0		;     4
	db	0		;     5
	db	0		;     6
	db	0		;     7
	db	0		;     8
	db	0		;     9
	db	0		;     10
	db	0		;     11
	db	0		;     12
	db	0		;     13
	db	0		;     14
	db	0		;     15
	db	0		;     16
	db	0		;     17
	db	0		;     18
	db	0		;     19
	db	0		;     20
	db	0		;     21
	db	0		;     22
	db	0		;     23
	db	0		;     24
	db	0		;     25
	db	0		;     26
	db	0		;     27
	db	0		;     28
	db	0		;     29
	db	0		;     30
	db	0		;     31
	db	0		; " " 32
	db	0		; "!" 33
	db	0		;     34
	db	0		; "#" 35
	db	0		; "$" 36
	db	0		; "%" 37
	db	0		; "" 38
	db	0		; "'" 39
	db	0		; "(" 40
	db	0		; ")" 41
	db	0		; "*" 42
	db	62		; "+" 43
	db	0		; "," 44
	db	0		; "-" 45
	db	0		; "." 46
	db	63		; "/" 47
	db	52		; "0" 48
	db	53		; "1" 49
	db	54		; "2" 50
	db	55		; "3" 51
	db	56		; "4" 52
	db	57		; "5" 53
	db	58		; "6" 54
	db	59		; "7" 55
	db	60		; "8" 56
	db	61		; "9" 57
	db	0		; ":" 58
	db	0		; ";" 59
	db	0		; "<" 60
	db	0		; "=" 61
	db	0		; ">" 62
	db	0		; "?" 63
	db	0		; "@" 64
	db	0		; "A" 65
	db	1		; "B"
	db	2		; "C"
	db	3		; "D"
	db	4		; "E"
	db	5		; "F"
	db	6		; "G"
	db	7		; "H"
	db	8		; "I"
	db	9		; "J"
	db	10		; "K"
	db	11		; "L"
	db	12		; "M"
	db	13		; "N"
	db	14		; "O"
	db	15		; "P"
	db	16		; "Q"
	db	17		; "R"
	db	18		; "S"
	db	19		; "T"
	db	20		; "U"
	db	21		; "V"
	db	22		; "W"
	db	23		; "X"
	db	24		; "Y"
	db	25		; "Z" 90
	db	0		; "(" 91
	db	0		; "\" 92
	db	0		; ")" 93
	db	0		; "^" 94
	db	0		; "_" 95
	db	0		; "`" 96
	db	26		; "a" 97
	db	27		; "b"
	db	28		; "c"
	db	29		; "d"
	db	30		; "e"
	db	31		; "f"
	db	32		; "g"
	db	33		; "h"
	db	34		; "i"
	db	35		; "j"
	db	36		; "k"
	db	37		; "l"
	db	38		; "m"
	db	39		; "n"
	db	40		; "o"
	db	41		; "p"
	db	42		; "q"
	db	43		; "r"
	db	44		; "s"
	db	45		; "t"
	db	46		; "u"
	db	47		; "v"
	db	48		; "w"
	db	49		; "x"
	db	50		; "y"
	db	51		; "z" 122
	db	0		; "{" 123
	db	0		; "|" 124
	db	0		; "}" 125
	db	0		; "~" 126
	db	0		;     127
	ds	128,0		; 128-255


; --------------------------------------------------------------------------


; **MUST BE 256 BYTE ALIGNED**
	ALIGN 256

encode256tab:

 db "AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJKKKKLLLLMMMM"
 db "NNNNOOOOPPPPQQQQRRRRSSSSTTTTUUUUVVVVWWWWXXXXYYYYZZZZ"
 db "aaaabbbbccccddddeeeeffffgggghhhhiiiijjjjkkkkllllmmmm"
 db "nnnnooooppppqqqqrrrrssssttttuuuuvvvvwwwwxxxxyyyyzzzz"
 db "0000111122223333444455556666777788889999++++////"

encode64tab:

 db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


; --------------------------------------------------------------------------

