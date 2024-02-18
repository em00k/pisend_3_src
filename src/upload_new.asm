do_file_upload:		

        ; clear the top of the screen 
        ; call    clear_screen          no longer went to clear screen

    ; find the current baud 

    ; open the file 

        call    print_version

        call    setdrv 

        call    get_cwd
        
        ld      hl, dir_buffer

        //call    print_rst16

        call    load_config_file 

        call    get_cwd

        
        jp      c, .not_valid_supwait               ; no carry then we failed to open
        
        ld      a, (config_file)
        ; and     7 
        
        cp      8                       ; check if over 8 
        jp      nc, .not_valid_supwait  ; do not skip if under 8 
        dec     a                       ; check if 0<
        jp      nc, .not_valid_supwait           
        
        nextreg $7f, 2                  ; set nextreg 

        ld      a,  (config_file)
        ld      (curbaud), a 
        call    setbaudrate 

.fix_char:
        ld      (hl), 0 
        
        call    change_dir
        
        ld      ix, command_buffer

        call    openfile

        call    getfilesize		; get size of file of handle from openfil
        jp      c, fail_to_open
        

.not_valid_supwait:
        ld      a, $7F                  ; user register 
        call    getreg 
        ld      b, a 
        ;and     15                      ; bottom bits only 
        ;cp      8                       ; is it set to 8? 
        ;jr      z, .set_to_2mbit
        ;cp      2                       ; or set to 2?
        ;jr      z, .set_to_115k

.set_to_2mbit:

.set_to_115k:

        push    bc 
        ;LOG "USING 115k"
        ld      hl, open_text
        call    print_rst16
        call    open_uart               ; open the uart 
        ;pop     af 
        ;and     $F0 
        ;cp      128
        ;jr      z,.skip_supwait
        call    waitforsup

.skip_supwait
        ld      hl, open_done
        call    print_rst16

    ; now we will backup current mmu slots 

        ld a, $53 : call getreg : ld (bank3orig),a	          
        ld a, $54 : call getreg : ld (bank4orig),a	          
        ld a, $55 : call getreg : ld (bank5orig),a	          
        ld a, $56 : call getreg : ld (bank6orig),a	          
        ld a, $57 : call getreg : ld (bank7orig),a

    ; now request a free mmu bank 

        call getbank : ld (bank3),a 
        call getbank : ld (bank4),a 
        call getbank : ld (bank5),a 
        call getbank : ld (bank6),a 
        ld      hl, banks_set  
        ld      (hl), 1 
    ;    call getbank : ld (bank7),a 

    ; and now set those banks 

        ld a,(bank3) : nextreg $53,a
        ld a,(bank4) : nextreg $54,a
        ld a,(bank5) : nextreg $55,a
        ld a,(bank6) : nextreg $56,a
    ;    ld a,(bank7) : nextreg $57,a

        ; print the filename 
        ld      hl,txtfname : call print_at
        ld      hl, dir_buffer
        call    print_rst16
        ld      a, 13 : rst 16
        ld      hl,command_buffer : call print_fname 

        ; print text "Size"
        ld      hl,txtsize : call print_rst16

        ; print the filesize - filesize is in bufferfs bytes 7-10
        ld      de,(bufferfs+9)                         ; get the fs in hlde
        ld      hl,(bufferfs+7)
        call    b2d32                                   ; convert to ascii 

        call    print_rst16                             ; print 
        ld      a,13 : rst 16                           ; new line 

        ld      hl, txtchunks : call print_rst16

        ; check fs isnt 0 

        ld      de,(bufferfs+9)		; get back 32bize to check it isnt 0 
        ld      hl,(bufferfs+7)
        ; check for zero bytes 
        ld a,l : or h : jr z,.yes_zero
        jr      .file_size_ok
.yes_zero:
        ld a,e : or d : jr z,.fs_null 
        jr      .file_size_ok
.fs_null:
        ; exit out of routine 
        LOG     "ERROR WITH FS"
        ;ret 
        ;pop     hl                  ; get the ret off the stack 
        jp      finish

.file_size_ok:

        ; we need to divide the filesize / buffersize 
        ; to get number of chunks and remainder 
        ld      hl,(bufferfs+9)
        ld      ix,(bufferfs+7)
        ld      bc, buffersize 
        call    div32_16 

        ; the result is stored in hlix, the remainder in de
        ld      (overrun), de 
        ld      b, ixh 
        ld      c, ixl                      ; get loops into bc
        ld      (nr_loops), bc              ; store number of loops 
        
        ld      a, "0"                      ; print the chunks 
        ld      (b2dfilc),a 
        ld      hl, (nr_loops)
        call    b2d16
        call    print_rst16
        ;call    print_AA
        ld      a, '/'
        rst     16
        
        ld      hl,enablecatcher : call streamuart		        ; prepare nextpi to receive 
        ld      hl,command_buffer : call streamuart			; and the output file 
			      
        ld      a,'"' : call senduart					; send closing quote 
        ld      a,13 : call senduart						; send a LF 

        ; print chunks 

        ; send the header 

        ld      hl,headerend-header : ld (filesize),hl : ld hl,header : call senduartmemory

        ; is the file over our max buffersize ($4000)?
        ; if not we do not require any loops 

        ld      hl, (nr_loops)
        ld      a, h 
        or      l 
        jr      z, no_loops_required

        ; LOG     "LOOP REQUIRED"

outer_loop:

        call    update_info

        ld      bc, buffersize 
        ld      (filesize), bc 

        ; load a chunk 
        call    loadfile 

        ;encode buffer 
        ld      hl, loadbuff 
        ld      de, ba64buff 

        ld      a, 6 : out ($fe), a 
        call    encodebase64
        ; on exit bc will be number of bytes for base64 encoded buffer 

        ; now send to uart 
        ld      hl, ba64buff
        ld      (filesize), bc        
        call    senduartmemory 

        call    check_break

        ; decrease loop counter 
        ld      hl, (nr_loops)
        dec     hl
        ld      (nr_loops),hl
        ld      a, h 
        or      l 
        jr      nz,outer_loop
        
no_loops_required:

        call    update_info

        ld      bc, (overrun)
        ld      (filesize), bc

        call    show_remainder_text

        ld      bc,(overrun)	
        call    loadfile

        ld      hl, loadbuff
        ld      de, ba64buff
        call    encodebase64

        ld      hl,ba64buff
        ld      (filesize), bc
        call    senduartmemory


        ld      a,$0a : call senduart			; make sure a return was sent 
        ld      a,$0a : call senduart			; doubley make sure 

        call    fclose

        ld      a,$0d : call senduart			; ctrl + c 
        ld      a,$0d : call senduart			; ctrl + c 


        call    rast_delay 
        di 
        ld      sp, $5B8A+32    
        nextreg $56, 0 
        nextreg $57, 1

        call    check_md5sum 
        call    read_uart_bank
        
       
        ld      hl,$a000

        ei 
        call 	print_rst16 
        di

        jp      finish 

fail_to_open:
        ld      hl, failed_open
        call 	print_rst16 
        ret     

nr_loops:
        dw 00 

check_md5sum:
        ld      a, 13 : rst 16                          ; new line

        ld      hl,file_hash_txt
        call    print_rst16

        ld      hl,echo_off 
        call    streamuart 
        ld      a,$0a : call senduart			; make sure a return was sent 
     ;   ld      a,$0d : call senduart			; doubley make sure 
        call    flushuart
        call    flushuart
        
        ld      hl, check_md5_txt                       ; send command line
        call    streamuart

        ld      hl,command_buffer                       ; send filename 
        call    streamuart

        ld      hl, check_md5_end 
        call    streamuart

        ld      hl, get_fsize_txt
        call    streamuart
        
        ld      hl,command_buffer                       ; send filename 
        call    streamuart
        
        ld      hl,get_fsize_end                       ; send filename 
        call    streamuart


        ld      a,$0a : call senduart			; make sure a return was sent 
     ;   ld      a,$0d : call senduart			; doubley make sure 
        ld      hl,echo_on
        call    streamuart 
        ld      a,$0a : call senduart			; make sure a return was sent 

        ret


update_info:


        
        ld      hl,(nr_loops)
        call    b2d16
        call    print_rst16

        ld      b, 1
1:      ld      a, 8
        rst     16 
        djnz    1B 

        ret 


show_remainder_text:
        
        ld   a, 13 : rst 16 
        call b2d16 : call print_rst16
        ret 
.at:
        db      22, 7, 16, 0 