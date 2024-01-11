	
M_GETSETDRV 	equ $89
F_OPEN 			equ $9a
F_CLOSE 		equ $9b
F_READ 			equ $9d
F_WRITE 		equ $9e
F_SEEK 			equ $9f
F_GET_DIR 		equ $a8
F_SET_DIR 		equ $a9

FA_READ 		equ $01
FA_APPEND 		equ $06
FA_OVERWRITE 	equ $0C

	macro ESXDOS command
		rst 	8
		db 		command
	endm

getsetdrive:
		xor 	a                           ; A=0, get the default drive
		ESXDOS M_GETSETDRV
		ld 		(DefaultDrive),a
		ret

DefaultDrive:
		db   '*'

readfile: 
		; 		hl = filename zero term, out a = file handle 
		ld 		a, (DefaultDrive) 				; use current drive
		ld 		b, FA_READ 						; set mode
		ESXDOS 	F_OPEN
		ret 	
	

writefile: 
		; 		hl = filename zero term,  a = file handle 
		ld 		a, (DefaultDrive) 				; use current drive
		ld 		b, FA_OVERWRITE 			; set mode
		
		ESXDOS 	F_OPEN
		ret 	
	
setdrv		ld a,'*':rst $08:db $89:xor a:ld (handle),a:ret
fopen		ld	b,$01:db 33 ;: ret 
     		;ld	b,$0c:push ix:pop hl:ld a,42:rst $08:db $9a:ld (handle),a:ret
fcreate		ld	b,$0e:push ix:pop hl:ld a,42:rst $08:db $9a:ld (handle),a:ret
fread		push ix:pop hl:db 62
handle		db	0:or a:ret z:rst $08:db $9d:ret
fwrite		push ix:pop hl:ld a,(handle):or a:ret z:rst $08:db $9e:ret
fclose		ld a,(handle):or a:ret z:rst $08:db $9b:ret
fseek		ld a,(handle):rst $08:db $9f:ret;

openfile:
			push de:call fopen:pop de:ret c:
			ld a,(handle):or a:ret z
			ld bc, 0 : ld de, 0: ld ixl,0
			call fseek
			ret 
loadfile: 	
			ld ix,loadbuff
			ld a,(handle)
			call fread		
			ret 
getfilesize_stat: 
		; ix = filespec hl in dotland 
		ld 		de,bufferfs
		ld 		a,'*'
		rst 	$08
		db 		$ac
		jr 		nc,successfs
		jr 		c,failopen
		;a = error code 
		jr 		donefsizefs

getfilesize: 
		; ix = filespec hl in dotland 
		ld 		hl,bufferfs
		ld 		a,(handle)
		rst 	$08
		db 		$a1
		jr 		nc,successfs
		jr 		c,failopen
		;a = error code 
		jr 		donefsizefs
; data

bufferfs:
		defs 	11,0
failopen: 
		ld 		a,1
		out 	($fe),a
		jr 		donefsizefs
successfs: 		
		ld 		a,4
		out 	($fe),a
		jr 		donefsizefs
donefsizefs:
		ret 	
		
input_handle: 
		db 		0
output_handle:
		db 		0 