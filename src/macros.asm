	macro 	PRINT 	text 
	
		call	sprint 
		db 		text 
		db 		0 
	endm 

    macro 	LOG 	text 
        IFDEF   DEBUGLOG
            push    af
		    call	sprint 
    		db 		text
            db      13 
		    db 		0
            pop     af 
        ENDIF
	endm 

