;////////////////////////////////////////////////
;// contains the save data 
;// 

save_blob_start:

version_bl      db 0,0              ; version number 

last_good:      db 0                ; last good speed
                ;   0   115,200     default 
                ;   1   56k 
                ;   2   38k
                ;   3   31250
                ;   4   19200
                ;   5   9600
                ;   6   4800
                ;   7   2400
                ;   8   230400
                ;   9   460800 
                ;   10  576000      flip to this
                ;   11  921600
                ;   12  1152000
                ;   13  1500000
                ;   14  2000000 

use_banks:      db 0                ; re use previous banks 

bank_order_orig:
                ds  8, 0 

bank_reserved:
                ds  8, 0 

save_blob_end:

