	

version			db		22,21,0,16,3,VERS,22,0,0,255
help_text		db		".pisend 3 - ",VERS,13,13,"usage :",13,13,"pisend [-q][-c][-s][-S][-r][file]",13,13
				db		"pisend is used for interacting  "
				db		"with NextPi. pisend can base64  "
				db		"encode files and transmit to the"
				db		"pi0, issue commands, read the pi"
				db		"console output etc.             ",13,13
				

linetwo			db 		"use:",13,13
				
				db 		".pisend -c {cmd}",13
				db		" sends a command to the pi0, eg:",13,13
				
				db 		".pisend -c nextpi-tzx_load rbc.tzx ",13
				db 		".pisend -c nextpi-play_sid sing*",13
				
				db 		13,13 

				db 		".pisend -c nextpi-tzx_load rbc.tzx ",13
				db 		".pisend -c nextpi-play_sid sing*",13,13
				
				db 		".pisend -q",13,13
				db		" discovers pi0 and sets baud    ",13
				db 		13,13 
				
				db 		"You must send this -q first to  discover the pi0. Reg $7f",13
				db 		"is set on successful exit",13
				db 		13,13

				db 		".pisend -r",13,13
				db		"flush what is in the uart buffer",13
				db		" to $c000 / 49152 with 512 bytes",13
				db 		13,13 

				db 		"pisend {filename}",13,13
				db		"pisend will base64 encode and   ",13
				db		"trasnmit to the pi0             ",13
				db 		13,13 

				
				db 		"Thanks to kevb, TimG, Big D and all the rest...",13,0
header 			db 		"begin-base64 644 data.uue",$0A
headerend 
enablecatcher 	db 		'nextpi-file_stream > "/ram/',0

failedbaudtest
				db 		"Failed to detect baud rate,   ",13
				db 		"Did you run '.pisend -q'?     ",13
				db 		0 
failedsup		db 		22,10,1,"Unable to read SUP> from Pi!",13,"Is the Pi ready? try .pisend -q"," to clear pi job.",22,1,1," ",0
faileduart		db 		"failed to find uart?",0
trylowboaud		db 		22, 0, 0,"Trying 115,200...",255
tryhighbaud		db 		22, 0, 0,"Trying 576,000...",255
trysuccess		db		22, 0, 0,"COMMS@ "
				db		22, 0, 17,"Connected OK!",255
txtsize			db		22,4,1,"size   : ",13,22,4,11,0
txtchunks		db		22,5,1,"chunks :       ",0
txtchunks2		db		22,5,18,"   ",0
txtfinal		db		22,6,1,"final  : ",13,22,6,11,0
txtfname		db		22,1,1,"file   :",255
_2mbto115:		db 		13,"Swapping 576,000 to 115,200",0
_115to2mb: 		db 		13,"Swapping 115,200 to 576,000",0
update2mb		db "nextpi-admin_enable",$0d,$0a
				db "cp /boot/cmdline.txt /boot/cmdline.bak",$0d,$0a
				db "echo dwc_otg.lpm_enable=0 console=serial0,576000 console=tty1 root=PARTUUID=b8ef7a27-02 "
				db "rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait > /boot/cmdline.txt"
				db $0d,$0a
				db "nextpi-admin_disable",$0d,$0a
				db "reboot",$0d,$0a
end2mb
update115		db "nextpi-admin_enable",$0d,$0a
				db "cp /boot/cmdline.txt /boot/cmdline.bak",$0d,$0a
				db "echo dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 "
				db "root=PARTUUID=b8ef7a27-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait > /boot/cmdline.txt"
				db $0d,$0a
				db "nextpi-admin_disable",$0d,$0a
				db "reboot",$0d,$0a
end115
updatetext		db 13,"Baud update + rebooting pi"
				db 13,"Use .term to confirm",0
open_text		db "Open Pi0 UART....",0
open_done		db "Connected!                 ",13,0
command_buffer
		ds		256,0
