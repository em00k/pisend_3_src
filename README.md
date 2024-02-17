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


- not implemented 



    reserving banks 

    memory protection 

    -s silent key

![alt text](https://raw.githubusercontent.com/em00k/pisend_src/main/pisend3.png)


    