
; source code for pisend 3
; em00k 2003.9.18
; http://github.com/em00k/pisend3

; This is a rewrite of pisend 2.41, this will hopefully be a cleaner implementaion 
; with considerations for extensions. 

        
        SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
        DEVICE ZXSPECTRUMNEXT
        CSPECTMAP "pisend_src.map"

        DEFINE VERS "2024.17.02.02"
        DEFINE DEBUGLOG 

        org     $2000

        jp      main 
        db      ".pisend-3.em00k.",VERS
        include "hardware.inc"
        include "macros.asm"

loadbuff		equ $6000				; this is where the load buffer is 
ba64buff		equ $a000				; this is where we encode the load buffer to 
buffersize		equ $4000				; this is how much to load 

main:
        ; we are working with a dotcommand so we need to process the cmd line

	di 
       
        nextreg TURBO_CONTROL_NR_07, 3          ; set to 28mhz 
        ld      (command_line),hl                ; save cmd line add
       
        push    iy,ix,hl,de,bc,af               ; we need to check we return to basic cleanly
        exx 	
        push    hl,de,bc                        ; so i reserve everything 
        ex      af,af' 		
        push    af

        ;rst     $18                            ; this is needed to be able to post 
        ;dw      $0daf                          ; to #2 but it breaks 64/84 mode ?!
        ; ld      a, 2                            ; opens chan 2
        ; rst     $18
        ; dw      $1601

        ld      (fixstack+1),sp                 ; save stack for exit 
        ld      sp,$5BBF                        ; very temp stack 

        call    saveAllBanks                    ; save all banks 

        ld      hl, (command_line)               ; get start command line address 

        ; check if command line has args 

        ld      a, h 
        or      l 
        jr      nz, process_args

        ; no args set so show help text and exit 
        ei 
        ld      hl, help_text 
        call    print_rst16 
        jp      finish

process_args:
       

        ; get a new bank to move the stack into 
        ld      a, $57                          ; get MMU7
        call    getreg 
        ld      (bank7orig),a                   ; save it
        call    getbank                         ; get a new bank for mmu7
        ld      (bank7),a 
        ld      a,(bank7) 
        nextreg $57,a                           ; put it in place 
        ld      sp, $fffe                       ; some space I found....

        ld      hl, (command_line)              ; ensure hl is pointing to command_line
        ld      de, command_buffer 
.cmd_copy:                                      ; copy from command_line to command buffer
        ld      a, (hl)
        cp      $0d                             ; EOL marker 
        jr      z, .found_eol
        cp      ':'
        jr      z, .found_eol
        ld      (de), a 
        ldi 
        xor     a 
        ld      (de), a                         ; always ensures zero terminated 
        jr      .cmd_copy

.found_eol:
        ld      hl, command_buffer


; Parse Arguments 

.parse_args:
        ld      a, (hl)
        inc     hl 
        cp      '-'
        jr      z, .found_arg                   ; found start of an argument 
        jp      nz, upload_mode                 
.found_arg:

        ld      a,(hl)                          ; move to argument 
        cp      'c'
        jp      z, send_command_line

        cp      'e'                             ; send command line and echo output
        jp      z, send_command_line_echo

        cp      'q'
        jp      z, hard_clear_uart 

        cp      'S'
        jp      z, send_script

        cp      's'
        jr      z, silent_key

        cp      'U'
        jp      z, swap_pi_baud

        cp      'b'
        jp      z, set_baud_speed 

        cp      'l'
        jp      z, show_baud_speeds 

        jp      upload_mode
         
silent_key:
        ; this sets a flag to send without clearing uart / reinit
        ld      a, 1                            ; 
        ld      (silent_key_flag), a 
        inc     hl 
        inc     hl 
        jp      process_args.parse_args

upload_mode:
        call    do_file_upload
        
        jr $

finish:	di 
        ;ld      ix,config_file_name
        ;call    savefile

        ld      sp,$5BBF

        call    restoreAllBanks
        call    freebanks
        
        
;------------------------------------------------------------------------------
; Epilogue 
        ; ld a,(bank3orig) : nextreg MMU3_6000_NR_53, a
        ; ld a,(bank4orig) : nextreg MMU4_8000_NR_54, a
        ; ld a,(bank5orig) : nextreg MMU5_A000_NR_55, a
        ; ld a,(bank6orig) : nextreg MMU6_C000_NR_56, a
        ; ld a,(bank7orig) : nextreg MMU7_E000_NR_57, a 

fixstack	
        ld      sp,0000			
        
        pop     af      
        ex      af,af' 
        pop     bc,de,hl
        exx 
        pop     af,bc,de,hl,ix,iy

        xor     a 
        ;ld      a,1
        ;scf 
        ei 
        ret 

; END OF PROGRAM 

show_baud_speeds:

        ld      hl,baud_help_txt
        call    print_rst16
        xor     a 
        ld      (show_loop),a  
        ld      a, 13 : rst 16 
.show_loop:

        ld      a,(show_loop)
        call    print_A

        ld      a, 32 : rst 16 

        ld      a,(show_loop)
        ld 	hl, baud_txt
        add	hl,a 
        add	hl,a 

        ld	a,(hl)					; (hl) > hl
        inc	hl
        ld 	h,(hl)
        inc	hl 
        ld 	l,a								; hl now points to baud ascii +zero       
        call    print_rst16             ; print text 

        ld      a,(show_loop)
        or      a 
        jr      nz, .not_def
        LOG     "    Default"
        jr      .no_lf
.not_def:
        ld      a, 13 : rst 16 
.no_lf:
        ld      a,(show_loop)
        inc     a
        ld      (show_loop),a 
        cp      8
        jp      z,finish

        jp      .show_loop
show_loop:
        db      0 
baud_help_txt:
        db ".p3 -b [n]",13
        db "This will set the baud rate    ",13
        db "between the pi0 and Next. Hard ",13
        db "reset the pi to go back to def. ",13,13,0
      
;------------------------------------------------------------------------------
; includes

        include "utils.asm"
        include "uart.asm"
        include "esxdos.asm"
        include "base64.asm"
        include "upload_new.asm"
        include "data_new.asm"
        include "save_blob.asm"

;------------------------------------------------------------------------------
; variables 

filesize	dw	0000
last_speed      db      0 
command_line    dw      0000 
bank3orig       db      0
bank4orig       db      0
bank5orig       db      0
bank6orig       db      0
bank7orig       db      0
overrun		dw      0000
silent_key_flag db      0 
;------------------------------------------------------------------------------
; Stack reservation
STACK_SIZE      equ     200

stack_bottom:
        defs    STACK_SIZE * 2
stack_top:
        defw    0
        defw    0


end_of_main:

;------------------------------------------------------------------------------
; Output configuration
        ; SAVENEX OPEN "pisend_src.nex", main, stack_top 
        ; SAVENEX CORE 2,0,0
        ; SAVENEX CFG 7,0,0,0
        ; SAVENEX AUTO 
        ; SAVENEX CLOSE

        savebin "p3", $2000, end_of_main-$2000
    ;    savebin "h:/dot/p3", $2000, end_of_main-$2000
