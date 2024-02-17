; This is no longer used but here for reference. 
;


do_file_upload:			

			;call reservebank
			; this bit sends the filename on command line to nextpi 
			; command_buffer now has our filename 
			;call reservebank	
			;break 


			ld a,$7f : call getreg : cp 8 : jr z,.set2mbit
			cp 2 : jr z,.set115 : jp finish
.set2mbit:
			ld a,1 : ld (curbaud),a 
.set115:	
			;ld a,6 : out (254),a 
			; 
			call open_uart			; opens uart port 
			
			; call waitforsup
			; stores all current memory banks and requests new ones 
			; this is split up for testing puposes 
			ld a, $53 : call getreg : ld (bank3orig),a	          
			ld a, $54 : call getreg : ld (bank4orig),a	          
			ld a, $55 : call getreg : ld (bank5orig),a	          
			ld a, $56 : call getreg : ld (bank6orig),a	          
			ld a, $57 : call getreg : ld (bank7orig),a
			call getbank : ld (bank3),a 
			call getbank : ld (bank4),a 
			call getbank : ld (bank5),a 
			call getbank : ld (bank6),a 
			call getbank : ld (bank7),a 
			ld a,(bank3) : nextreg $53,a
			ld a,(bank4) : nextreg $54,a
			ld a,(bank5) : nextreg $55,a
			ld a,(bank6) : nextreg $56,a
			ld a,(bank7) : nextreg $57,a

			call    setdrv
			ld      ix,command_buffer			; filename 
		
			call    openfile			; open 

			call    getfilesize		; get size of file into bufferfs 
			
			; print the file name top right 
			
			ld      hl,command_buffer : call print_fname
rst1: 		ld      a,13 : rst 16 
			
			; txtsize label 
			ld      hl,txtsize : call print_rst16

			; print file size 
			ld      de,(bufferfs+9) : ld hl,(bufferfs+7)
			call    b2d32
		2:	ld 		a, (hl)
			cp 		' '
			jr 		nz, 1F
			inc 	hl
			jr		2B
		1:	call print_rst16

rst2:		ld      a,13 : rst 16
			
			; file size is in bufferfs as a 32bit long 
			ld      hl,(bufferfs+9)
			ld      ix,(bufferfs+7)
		
			; ixhl = 32bit size in bytes 
			; we need to divide the size by <8192> buffersize to work out how many chunks to send 
			; and get the remainder in de for the last chunk 
			; 
			ld bc,buffersize : call div32_16
			
			; de remainder 
			ld (overrun),de 		; save the offset (push to stack?)
			; ix * buffersize + de  
			push ix 				; get ix into hl 
			
			ld de,(bufferfs+9)		; get back 32bize to check it isnt 0 
			ld hl,(bufferfs+7)
			; check for zero bytes 
			ld a,l : or h : jr z,yesitwaszero
			jr wasnt0
yesitwaszero:
			ld a,e : or d : jr z,weatzeroman 
			jr wasnt0
weatzeroman:
			pop hl					; get this off stack before quitting
			jp finish			
wasnt0: 
			pop hl
			; we only want l otherwise the file is crazy 
			; now we want h as well 
			; lets save hl on to bc 
			push hl
			; we can push twice then pop into bc 
			ld a,l 					
			push af 
			
			ld hl,enablecatcher : call streamuart		; this gets nextpi ready for to recieve  
			ld hl,command_buffer : call streamuart			; and the output file 
			
			ld a,'"' : call senduart					; send closing quote 
			ld a,13 : call senduart						; send a LF 
;

			; quick check to see if anything way echoed back 

;
			pop af
			push af 

			ld b,a
			; print textchunk label 
			;ld a,(quietmode) : bit 0,a : jp nz,.noprint			
			ld hl,txtchunks2 : call print_rst16
			; prints number of chunk
			ld a,b 
			;call b2d8 : ld hl,b2dend-3 : call print_rst16
			ld h,b : ld l,c : call b2d16 : ld hl,b2dend-5 :
			ld hl,txtchunks : call print_rst16
			
			;ld hl,(overrun) : call b2d16 : ld hl,b2dend-5 : call print_rst16
			ld a,13 : rst 16
			
			;call b2d8 : ld hl,b2dend-3 : call print_rst16
			
			; sends the header of the base64 
			push bc 
			ld hl,headerend-header : ld (filesize),hl : ld hl,header : call senduartmemory
			;ld a,$0A : call senduart			; make sure a return was sent 
			pop bc 
;.noprint			
			pop af 

			; now we pop bc back we puch from hl up above 

			pop bc 
			ld a,b 
			or c 					; check if bc = 0 
			jr z,noloopneeded		; if so no loop needed 
			
			ld a,2 : out (254),a 
			
			; write header 
			
			
outermain:	; how many times we need to loop to upload the data 

			push bc								; push so we can reuse bc  
						
			ld bc, buffersize
			ld (filesize),bc 
			
			;load section 
			call loadfile	  					; loads a <8192> buffersize to loadbuff

			ld hl,loadbuff : ld de,ba64buff
			; hl source de dest bc length of bytes (8192 normally)
			ld a,6: out ($fe),a 
			call encodebase64
			; now bc = number of bytes to send, 
			ld hl,ba64buff : ld (filesize),bc  
			nextreg $7,2
			call senduartmemory 				; need to write; sends it 
			nextreg $7,3
			pop bc 								; pop back 
			;ld a,b
			dec bc 
			push bc 
			; print it 
			; position of chunks 
			;ld a,(quietmode) : bit 0,a : jp nz,.noprint
			ld a,22 : rst 16 : ld a,5  : rst 16 : ld a, 11 : rst 16
			ld h,b : ld l,c : call b2d16 : ld hl,b2dend-5 : call print_rst16 
;.noprint			
			pop bc 
			ld a,b 
			or c
			jr nz,outermain 

			ld hl,txtfinal : call print_rst16
noloopneeded:
			ld bc,(overrun)						; final bit 
			ld (filesize),bc 
			
			ld hl,bc : call b2d16 : ld hl,b2dend-5 : call print_rst16
			
			ld bc,(overrun)	
			call loadfile
			
			ld hl,loadbuff : ld de,ba64buff
			call encodebase64
			ld hl,ba64buff : ld (filesize),bc  
			nextreg $7,2
			call senduartmemory 				; need to write ; sends it 
			nextreg $7,3
			ld a,$0A : call senduart			; make sure a return was sent 
			ld a,$0A : call senduart			; doubly make sure 
            
           

			;call setdrv 
						
			call fclose

			ld a,$0d : call senduart			; ctrl + c 
			ld a,$0d : call senduart			; ctrl + c 
			
            di 
            
			; put all the ram back man 

            ret 


