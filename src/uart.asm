senduart:	
	; in a char to send 

			ld 		bc,UART_TX_P_133B 						; write to uart 
			ld 		d,a 
			ld 		e,100
.toutb:		; if busy do a little loop 
			dec 	e 			; but not forever 
			ld		a, e 
			or 		a
			jr		z, .nomorewaiting
			in 		a,(c) 
			and	 	%10000
			jr 		z,.toutb	; bit 4 = 1 when tx empty 
.nomorewaiting:
			out 	(c),d
			ret 


;////////////////////////
;// senduartmemory 
;// in HL address 
;// 

senduartmemory:
			di 
			push bc : push hl : push de 

			xor 	a
			ld 		(dolinefeed),a 				; reset line feed flag 
			ld 		de,(filesize)				; chunk size 
			ld 		bc,$133b					; TX 
outb:	
			in a,(c) : and %10 : jr nz,outb		; check if busy? if so loop 
			ld a,(hl) : inc hl : out (c),a		; else send byte to uart 

			and 7 : out (254),a   				; border effect 
			ld 		a,(dolinefeed)
			inc 	a
			cp 		128							; 128 lines written?
			jr 		z,linefeed 					; then do line feed 
			
			ld 		(dolinefeed),a 	
			jr 		nolinefeed
			
dolinefeed: db 0 

linefeed: 	in a,(c) : and %10 : jr nz,linefeed	; loop if uart is busy 
			ld a,$0a : out (c),a				; send $0a LF 
			xor a : ld (dolinefeed),a 			; reset linefeed counter 

nolinefeed:			
			dec 	de							; dec filesize and check for 0
			ld 		a,e
			or 		d
			jr 		nz,outb

			pop de : pop hl : pop bc 
			ret 



; sets baud rat 

setbaud115200:	
			xor     a
			
setbaudrate:		
			ld      a, (curbaud)

;now we calculate the prescaler value to set for our vga timing.

			push    af
			pop     af						; a board = 0 			
   
			ld      d,0
			sla     a		; *2
			rl      d
			sla     a		; *4
			rl      d
			sla     a		; *8
			rl      d
			sla     a		; *16
			rl      d	
			ld      e,a		
			ld      hl,baudprescale	; hl now points at the baud to use.
			add     hl,de						; vector for baud values 
			ld      bc,9275	;now adjust for the set video timing.
			ld      a,17			; reg $11 
			out     (c),a
			ld      bc,9531	
			in      a,(c)	;get timing adjustment
			ld      e,a
			rlc     e		;*2 guaranteed as <127
			ld      d,0
			add     hl,de
			ld      e,(hl)
			inc     hl
			ld      d,(hl)
			ex      de,hl

			push    hl		; this is prescaler		
			push    af		; and value
						
			ld      bc,UART_RX_P_143B					; 
			ld      a,l
			and     %01111111	; res bit 7 to request write to lower 7 bits
			out     (c),a
			ld      a,h
			rl      l		; bit 7 in carry
			rla		; now in bit 0
			or      %10000000	; set msb to request write to upper 7 bits
			out     (c),a

			pop     af
			ld      l,a
			ld      h,0

			pop     hl
			ret

baudprescale:

			defw 243,248,256,260,269,278,286,234 			; was 0 - 115200 adjust for 0-7
			DEFW 49,50,51,52,54,56,57,47 ;576000 -10
			defw 14,14,15,15,16,16,17,14 					;2000000 -14


			DEFW 243,248,256,260,269,278,286,234 ; Was 0 - 115200 adjust for 0-7
			DEFW 486,496,512,521,538,556,573,469 ; 56k
			DEFW 729,744,767,781,807,833,859,703 ; 38k
			DEFW 896,914,943,960,992,1024,1056,864 ; 31250 (MIDI)
			DEFW 1458,1488,1535,1563,1615,1667,1719,1406 ; 19200
			DEFW 2917,2976,3069,3125,3229,3333,3438,2813 ; 9600
			DEFW 5833,5952,6138,6250,6458,6667,6875,5625 ; 4800
			DEFW 11667,11905,12277,12500,12917,13333,13750,11250 ; 2400
			DEFW 122,124,128,130,135,139,143,117 ; 230400 -8
			DEFW 61,62,64,65,67,69,72,59 ;460800 -9
			DEFW 49,50,51,52,54,56,57,47 ;576000 -10
			DEFW 30,31,32,33,34,35,36,29 ;921600 -11
			DEFW 24,25,26,26,27,28,29,23 ;1152000 -12
			DEFW 19,19,20,20,21,21,22,18 ;1500000 -13
			DEFW 14,14,15,15,16,16,17,14 ;2000000 -14


curbaud:	
			defb 0			;start at 115200
			defb 0			;zero for easy load at 16bits


open_uart: 
			ld bc,UART_CTRL_P_153B : ld a,64 : out (c),a 
			ld bc,$163B : ld a,%00111000 : out (c),a
			nextreg PI_PERIPHERALS_ENABLE_NR_A0, $30
			nextreg PI_I2S_AUDIO_CONTROL_NR_A2, $d2			
			call    flushuart
			ret 
	
clear_uart: 
			; sends a clear command 
			push bc : ld b,200			; this is purely to slow stuff down 
.wtl		ld (tempsup),ix : djnz .wtl : pop bc 
			ld a, 13 : call senduart
			ld a, $03 : call senduart
			ld a, $03 : call senduart
			ret 


swap_pi_baud: 	
			ld a,$7f : call getreg : and 15 : cp 8 : jp z,.set2mbit
			cp 2 : jp z,.dotnset	; 115200 
			ld hl,failedbaudtest : jp printfailed
		
.set2mbit:
			ld hl,_2mbto115 : call print_rst16
			ld hl,update115
			jr .overdotnset
.dotnset:			
			ld hl,_115to2mb : call print_rst16
			ld hl,update2mb
.overdotnset:			
			ld de,command_buffer : ld bc,end115-update115: ldir 
			ld hl,updatetext : call print_rst16
		
configdone:
			ld a,(silent_prog) : cp 1 : jr z,justsend 
			; this bit just sends a command  to nextpi and quits 
			ld a,$7f :call getreg : and 15: cp 8 : jr z,.set2mbit
			cp 2 : jr z,.dotnset	; 115200 
			ld hl,failedbaudtest : jp printfailed
.set2mbit:
			ld a,1 : ld (curbaud),a 
.dotnset:			
			
			call open_uart			
			call clear_uart   ; ctrl+c				
			ld a,$0d : call senduart
justsend:			
			ld hl,command_buffer+1 : call streamuart
			ld a,$0a : call senduart
			jp finish


;////////////////////////
;// hard_clear_uart 
;// clears and re-inits the UART 
;// tests for low and fast baud speed 

hard_clear_uart:
			
        ;    LOG "OPENING UART"
			call    open_uart
		;	LOG "CLEAR UART"
			call    clear_uart
		;	LOG "SET BAUD"
			ld      a,3 : ld bc,UART_TX_P_133B : out (c),a 
			call    setbaud115200
			nextreg $7f,0
			ld      hl,trylowboaud : call print_at
			ld      a,13 : call senduart
			ld      a,4 : call senduart
			
            ; try 115200 first 
			call    waitforsup				; sup flag will = 2 if a sup was found. 
			ld      a,(supbaudflag) : cp 2 : nextreg $7f,2 : ld hl,trysuccess : jr z,correctbaud

			; try 2MBit 
			ld      hl,tryhighbaud: call print_at
			ld      a,1 : ld (curbaud),a 
			call    setbaudrate		
			call    clear_uart
			ld      a,13 : call senduart
			ld      a,4 : call senduart
			call    waitforsup
			
			ld      a,(supbaudflag) : cp 2 : nextreg $7f,8+128 : ld hl,trysuccess : jr z,correctbaud
			nextreg $7f,0			; set to 0 if failed 
			ld      hl,failedsup

printfailed call    print_rst16 : jp finish 
correctbaud:
			call    print_at
			jp      finish


flushuart:
			; KevB https://www.specnext.com/forum/search.php?author_id=1315&sr=posts
			; Empty the 512 BYTE FIFO.
			nextreg $7,3
			ld      e,255
			;ld	bc,$143B : ld hl,512				;     ; FIFO (Read 512 BYTES)
.fifo:		ld	    bc,UART_RX_P_143B
			in	    d,(c) : in	d,(c)  					; : dec	hl : jr	nz,fifo
			ld	    bc,UART_TX_P_133B							; TX 
			in	    a,(c)								; read 
			and     1 									; bit 0 = 0 fifo is empty or bit 0 = 1 data to get 
			or      a   	
			jr      nz,.fifo 								; no more data we're done 	;;
			dec     e 
			or      a 
			jr      nz,.fifo 
			nextreg $7,3
			ret 

waituart:
			ld 		h,0
waituartlp:
			ld      a, $0d : ld bc,UART_TX_P_133B : out (c),a 
			in      a,(c) : and 1 : cp 1 : jr z,founduart
			
			ld      b,25	
ml2:	    halt 
			djnz    ml2 
			inc     h : ld a,h : cp 10 : jr z,giveup
			out     ($fe),a 
			jp      waituartlp			

giveup:		ld      a,2 : out ($fe),a : ld hl,faileduart : call print_rst16
			jp      finish
			
founduart:	ret 		

;////////////////////////
;// waitforsup 
;// resets the terminal and waits for special text 
;//  

waitforsup:
            ; clears uart buffers and re-inits the console 
            ; and waits for the text "DietPi for the SpecNext"

			xor     a
            ld      (supbaudflag),a
            ld      (supcounter), a
            ld      hl,0
            ld      (suploops), hl 		; resets baudflag, supcounter, suploops
			
            call    flushuart           ; flush the uart buffer 

			ld      a,4                 ; send ctrl+d 
            call    senduart

			ld      de,65535

			nextreg $7,1
			call    delay                  ; wait for delay 4 frames 

readuart:   ld      bc,UART_RX_P_143B : ld hl,uartstring
.uartlp		in      a,(c) : cp (hl) : jr nz,notachar

			call    delay 

			inc     hl : ld a,(hl) : or a 
			jp      z,readone
			jp      .uartlp

uartstring	
			db "DietPi for the SpecNext", 0 

tempsup		dw      0 			

notachar:	and     7 
			out	    (254),a             ; Set border color
			dec     de 
			ld	    bc,UART_TX_P_133B : in	a,(c) : and 1 : cp 1
			jp      z,readuart
			ld      a,d : or e : jr z,notfound1
			jp      readuart
keeplooking: 			
			ld      a,(supcounter) : cp 255 : jp c,readone
			jr      readuart
			
notfound1: 	ld      hl,(suploops) : inc hl : ld (suploops),hl : ld a,h : or l : jr z,keeplooking	
notfound: 	;ld hl,failedsup : call print_rst16
notfound2:  ld      a,1 : out (254),a : jp timedout

readone:	ld      a, 2: ld (supbaudflag),a
			;ld hl,foundsup : call print_rst16		
			nextreg $7,3
			ret 
timedout:	
			nextreg $7,3
			;pop hl : jp finish
			ret 
delay:			
			push    bc : push de : ld b,4			; we need a bit of a wait 
.wtl		call    RasterWait : djnz .wtl : pop de : pop bc : ret 

RasterWait:
			push    bc 
			ld      e,190 : ld a,$1f : ld bc,$243b : out (c),a : inc b
		
.waitforlinea:	
			in      a,(c) : cp e : jr nz,.waitforlinea		
			pop     bc 
			ret 

supcounter:  db 0
supbuffer:   db "SUP>"
suploops: 	 dw 0 		
supbaudflag: db 0 	
silent_prog: db 0 

streamuart	ld a,(hl):inc hl:or a:ret z:  

			ld bc,$133b 						; write to uart 
			ld d,a 
.koutb:		; if busy do a little loop 
			in a,(c) : and 2 : jr nz,.koutb : ld a,d : out (c),a
			jr streamuart


;////////////////////////
;// send_command_line 
;// in HL address of command line 
;// 

send_command_line:

			inc 	hl
			push 	hl 
			call 	open_uart
			call 	clear_uart
			ld 		a,$0d : call senduart
			pop 	hl 
			call	streamuart
			ld 		a,$0a : call senduart
			jp 		finish




