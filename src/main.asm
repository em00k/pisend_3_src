
; source code for pisend 3
; em00k 2003.9.18
; http://github.com/em00k/pisend3

; This is a rewrite of pisend 2.41, this will hopefully be a cleaner implementaion 
; with considerations for extensions. 

        
        SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
        DEVICE ZXSPECTRUMNEXT
        CSPECTMAP "pisend_src.map"

        DEFINE VERS "2003.9.18.1"
        DEFINE DEBUGLOG 

        org     $2000
        jp      main 
        ;db      ".pisend-3.em00k.",VERS
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
        ld      (fixstack+1),sp                 ; save stack for exit 


        ; push    iy,ix,hl,de,bc,af               ; we need to check we return to basic cleanly
        ; exx 	
        ; push    hl,de,bc                        ; so i reserve everything 
        ; ex      af,af' 		
        ; push    af

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
        ld      sp, $fffe                   ; some space I found....

        ld      hl, (command_line)               ; ensure hl is pointing to command_line
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
.parse_args:
        ld      a, (hl)
        inc     hl 
        cp      '-'
        jr      z, .found_arg                   ; found start of an argument 
        jp      nz, upload_mode                 
.found_arg:
        ld      a,(hl)
        cp      'c'
        jp      z, send_command_line

        cp      'q'
        jp      z, hard_clear_uart 

        cp      's'
        jr      z, silent_key

        cp      'U'
        jp      z, swap_pi_baud

        jp      upload_mode
         
silent_key:

upload_mode:
        call    do_file_upload

;------------------------------------------------------------------------------
; Epilogue 
        ; ld a,(bank3orig) : nextreg MMU3_6000_NR_53, a
        ; ld a,(bank4orig) : nextreg MMU4_8000_NR_54, a
        ; ld a,(bank5orig) : nextreg MMU5_A000_NR_55, a
        ; ld a,(bank6orig) : nextreg MMU6_C000_NR_56, a
        ; ld a,(bank7orig) : nextreg MMU7_E000_NR_57, a 

finish:	

        di 	
fixstack:	
        ld      sp,0000	
;         pop     af
;         ex      af,af' 
;       ;  call    freebank						; now safe to freebanks
;         pop     bc,de,hl
;         exx 
;         pop     af,bc,de,hl,ix,iy

        xor     a 
        ei 
        ret 

; END OF PROGRAM 

;------------------------------------------------------------------------------
; includes

        include "utils.asm"
        include "uart.asm"
        include "esxdos.asm"
        include "base64.asm"
        include "upload_new.asm"
        include "data.asm"

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
;------------------------------------------------------------------------------
; Stack reservation
STACK_SIZE      equ     100

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
        savebin "h:/dot/p3", $2000, end_of_main-$2000
