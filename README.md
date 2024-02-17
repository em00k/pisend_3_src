# pisend_src WIP

Sources for pisend 3

- whats implemented 

        .p3 -q 

    clears uart and determines baud rate


        .p3 [filename]

    uploads [filename] to the pi0 


        .p3 -c [command]

    executes [command] on the pi0, no output 


        .p3 -e [command]

    executes [command] on the pi0 echo output to screen


        .p3 -U

    swaps between low and high baud rates 
        (currently 115,200 & 576,000)

        .p3 -s

    Just sents chars to the UART, no clear or detection

    Capture the output of a command to a variable v$

        10 DIM v$(768)
        20 OPEN #2, "v>v$"
        30 .p3 -e ls
        40 CLOSE #2
        50 PRINT "*";v$;"*"


![alt text](https://raw.githubusercontent.com/em00k/pisend_src/main/pisend3.png)



    