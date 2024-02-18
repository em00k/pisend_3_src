	
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
	
setdrv		ld a,'$':rst $08:db $89:xor a:ld (handle),a:ret
fopen		ld	b,$01:ld a,'$'
			push ix:pop hl:ld a,'$':rst $08:db $9a:ld (handle),a:ret
fcreate		ld	b,$0e:push ix:pop hl:ld a,'*':rst $08:db $9a:ld (handle),a:ret
fread		push ix:pop hl:db 62 ; db 62 = ld a, 0
handle		db	0:or a:ret z:rst $08:db $9d:ret
fwrite		push ix:pop hl:ld a,(handle):or a:ret z:rst $08:db $9e:ret
fclose		ld a,(handle):or a:ret z:rst $08:db $9b:ret
fseek		ld a,(handle):rst $08:db $9f:ret

openfile:	
			call 	fopen
			jr 		c, fail_open 
			ld 		a,(handle)
			or 		a
			ret 	z
			ld 		bc, 0
			ld 		de, 0
			ld 		ixl,0
			call 	fseek
			ret 
fail_open:
			LOG "FAILED OPEN"
			call 	show_error
			ret 
loadfile: 	
			ld 		ix,loadbuff
			ld 		a,(handle)
			call 	fread		
			ret 

savefile: 	; ix = filename 
			call	fcreate 
			ld 		a,(handle)
			ld		ix,config_file
			push 	ix
			pop		hl 
			ld		bc, 16
			call	fwrite 
			call	fclose 
			ret 

load_config_file:
			ld		ix,config_file_name
			call	openfile 
			jr		c, failed_to_open_config
			ld 		ix,	config_file
			ld 		bc, 16 	
			ld	 	a, (handle)
			call 	fread
			ld	 	a, (handle)
			call 	fclose
			ret 

failed_to_open_config:
			LOG		"FAILED TO OPEN CONFIG"
			ret 

get_cwd:
			ld 		hl, dir_buffer 
			ld		a, '$'
			ld 		b, 0
			rst 	8
			db		$a8				; f_getcwd
			jr 		c,failopen
			ret 

change_dir:
			ld		a, 0 
			rst 	8
			db 		$89
			ld 		hl, dir_buffer
			;ld 		a, '$'
			ld 		b, 0
			rst 	8
			db		$a9
			jr 		c,failopen
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
			call 	show_error
			jr 		c,failopen
			;a = error code 
			jr 		donefsizefs
; data

bufferfs:
			defs 	11,0
failopen: 
			call 	show_error 
			jr 		donefsizefs

successfs: 		
			;LOG 	"SIZE SUCCESS"
			ld 		a,4
			out 	($fe),a
			jr 		donefsizefs
show_error: 
			; a = error code 
			push 	af 
			call 	prthex8
			ld 		a,' '
			rst 	16
			pop 	af 
			add		a,a

			ld 		hl,exsdos_errors
			add 	hl,a 
			ld 		a, (hl)
			inc 	hl 
			ld 		h, (hl)
			ld 		l, a 
			call	print_rst16
			ld		a, 13 
			rst 	16 
			ret 

donefsizefs:
			ret 	
		
input_handle: 
			db 		0
output_handle:
			db 		0 

config_file:
			db 		0 			; last working baud rate 
			ds		15,$FF
config_file_name:
			db 		"c:/sys/p3.cfg",0

exsdos_errors:

	dw error_0
	dw error_1
	dw error_2
	dw error_3
	dw error_4
	dw error_5
	dw error_6
	dw error_7
	dw error_8
	dw error_9
	dw error_10
	dw error_11
	dw error_12
	dw error_13
	dw error_14
	dw error_15
	dw error_16
	dw error_17
	dw error_18
	dw error_19
	dw error_20
	dw error_21
	dw error_22
	dw error_23
	dw error_24
	dw error_25
	dw error_26
	dw error_27
	dw error_28
	dw error_29
	dw error_30
	dw error_31

error_0:
	db "Unknown error",0 ; 0, esx_ok
error_1:
	db "OK",0 ; 1, esx_eok
error_2:	
	db "Nonsense in esxDOS",0 ; 2, esx_nonsense
error_3:
	db "Statement end error",0 ; 3, esx_estend
error_4:
	db "Wrong file type",0 ; 4, esx_ewrtype
error_5:
	db "No such file or dir",0 ; 5, esx_enoent
error_6:
	db "I/O error",0 ; 6, esx_eio
error_7:
	db "Invalid filename",0 ; 7, esx_einval
error_8:
	db "Access denied",0 ; 8, esx_eacces
error_9:
	db "Drive full",0 ; 9, esx_enospc
error_10:
	db "Invalid i/o request",0 ; 10, esx_enxio
error_11:
	db "No such drive",0 ; 11, esx_enodrv
error_12:
	db "Too many files open",0 ; 12, esx_enfile
error_13:
	db "Bad file number",0 ; 13, esx_ebadf
error_14:
	db "No such device",0 ; 14, esx_enodev
error_15:
	db "File pointer overflow",0 ; 15, esx_eoverflow
error_16:
	db "Is a directory",0 ; 16, esx_eisdir
error_17:
	db "Not a directory",0 ; 17, esx_enotdir
error_18
	db "Already exists",0 ; 18, esx_eexist
error_19:
	db "Invalid path",0 ; 19, esx_epath
error_20:
	db "Missing system",0 ; 20, esx_esys
error_21:
	db "Path too long",0 ; 21, esx_enametoolong
error_22:
	db "No such command",0 ; 22, esx_enocmd
error_23:
	db "In use",0 ; 23, esx_einuse
error_24:
	db "Read only",0 ; 24, esx_erdonly
error_25:
	db "Verify failed",0
error_26:
	db "Sys file load error",0 ; 26, esx_eloadingko
error_27:
	db "Directory in use",0 ; 27, esx_edirinuse
error_28:
	db "MAPRAM is active",0 ; 28, esx_emapramactive
error_29:
	db "Drive busy",0 ; 29, esx_edrivebusy
error_30:
	db "Unknown filesystem",0 ; 30, esx_efsunknown
error_31:
	db "Device busy",0 ; 31, esx_edevicebus