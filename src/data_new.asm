	

version			db		".pisend 3 - ",VERS,13,255
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
				db 		".pisend -c nextpi-play_sid song*",13
				
				db 		13,13 
				
				db 		".pisend -e {cmd}",13
				db		" sends a command to the pi0 and",13
				db		" prints the output to the screen",13
				
				db 		13,13 
				db 		".pisend -q",13
				db		" Hard clear the UART",13
				
				db 		13,13 
				db 		".pisend -S",13
				db		" Sends a script and sets chmod   +X",13
				
				db 		13,13 
				db 		".pisend -s",13
				db		" Silent mode",13

				db 		13,13 
				db 		".pisend -U",13
				db		" Swap baud rate betweeen 115K &",13
				db		" 2MB",13,13
				
				db 		".pisend -l",13
				db		" List baud speeds for -b",13
				db 		13,13 
				
				db 		".pisend -b {n}",13
				db		" Set UART speed to {n}",13
				db 		13,13 				

				db 		".pisend -q",13
				db		" Query UART for the pi0 and ",13
				db		" sets REG$7F on success. ",13
				db		" 1 for 115,200",13
				db		" 8 for 2,000,000",13
				db 		13,13 

				db 		"You must send this -q first to  discover the pi0. Reg $7f",13
				db 		"is set on successful exit",13
				db 		13,13

				db 		".pisend {filename}",13,13
				db		" pisend will base64 encode and   ",13
				db		" trasnmit to the pi0             ",13
				db 		13,13 

				
				db 		"Thanks to kevb, TimG, Big D and all the rest...",13,0
header 			db 		"begin-base64 644 data.uue",$0A
headerend 
enablecatcher 	db 		'nextpi-file_stream > "/ram/',0

failedbaudtest
				db 		"Failed to detect baud rate,   ",13
				db 		"Did you run '.pisend -q'?     ",13
				db 		0 
failedsup		db 		"Unable to read SUP> from Pi!",13,"Is the Pi ready? try .pisend -q"," to clear pi job.",0
faileduart		db 		"failed to find uart?",0
trylowboaud		db 		"Trying 115,200...",13,255
tryhighbaud		db 		"Trying 576,000...",13,255
tryingtext      db      "Trying Baud : ",13,255
trysuccess		db		"COMMS@ "
				db		"Connected OK!",255

txtsize			db		13,"File size :	      ",0
txtchunks		db		   "chunks    :       ",0
txtchunks2		db		"   ",0
txtfinal		db		"final  : ",13,0
txtfname		db		"File : ",13,255
_2mbto115:		db 		13,"Swapping 576,000 to 115,200",0
_115to2mb: 		db 		13,"Swapping 115,200 to 576,000",0
update2mb		db		 "nextpi-admin_enable",$0d,$0a
				db		 "cp /boot/cmdline.txt /boot/cmdline.bak",$0d,$0a
				db		 "echo dwc_otg.lpm_enable=0 console=serial0,576000 console=tty1 root=PARTUUID=b8ef7a27-02 "
				db		 "rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait > /boot/cmdline.txt"
				db		 $0d,$0a
				db		 "nextpi-admin_disable",$0d,$0a
				db		 "reboot",$0d,$0a
end2mb		
update115		db		 "nextpi-admin_enable",$0d,$0a
				db		 "cp /boot/cmdline.txt /boot/cmdline.bak",$0d,$0a
				db		 "echo dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 "
				db		 "root=PARTUUID=b8ef7a27-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait > /boot/cmdline.txt"
				db		 $0d,$0a
				db		 "nextpi-admin_disable",$0d,$0a
				db		 "reboot",$0d,$0a
end115		
updatetext		db		 13,"Baud update + rebooting pi"
				db		 13,"Use .term to confirm",0

failed_open		db		"Failed to open file",0

open_text		db		 13,"Open Pi0 UART....",0
open_done		db		 "connected!",13,0
connect_txt		db		 13,"Connected to pi0 UART at ",255
check_md5_txt	db		 'printf "\xFF\xFF" > /tmp/_ps.txt',$0a,'md5sum ',0 
check_md5_end	db		 " | awk '{print $1}' >> /tmp/_ps.txt",$0a,0
get_fsize_txt	db		 'echo "Bytes uploaded : \n\n" >> /tmp/_ps.txt',$0a
				db		 'stat -c "%s" "',0
				; 		stream fname
get_fsize_end	db		 '" >> /tmp/_ps.txt',10
				db		 'printf "\xFE" >> /tmp/_ps.txt',$0a
cat_output		db		 "cat /tmp/_ps.txt",0
blankline_at	db		 	22, 0, 0 , 255 
blankline_txt	ds			32, 32
				db			0
echo_off		db		 "stty -echo",13,0
echo_on			db		 "stty echo",13,0

set_tty_sp		db		 'stty -F /dev/ttyAMA0 ',0

; get tty baud 		
				db		 "stty </dev/ttyAMA0",0

file_hash_txt	db		 13,"MD5hash:",13,13,0

command_ln_txt	db		 'printf "\xFF\xFF" > /tmp/_ps.txt',$0a,0
				; 		stream command line
command_ln_txt2	db		 ' &>> /tmp/_ps.txt',$0a 
				db		 'printf "\xFE" >> /tmp/_ps.txt',$0a,0

send_script_txt	db		 'chmod +x ',0 
				; 		stream filename 
send_script_end	db		 $0a,0

set_speed_buffer		
				db		 0,0,0

command_buffer		
				ds		256,0
banks_set       db      0
ret_code		db 		0,0
cpu_speed		db 		0  

dir_buffer		ds 		256, 0 