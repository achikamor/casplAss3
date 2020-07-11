section .rodata
    format_string_float: db "%d,%.2lf,%.2lf,%.2lf,%d",10,0     ;printing the target data
    format_string_target: db "%.2lf %.2lf",10,0         ;printing drone dtata
    
section .bss
    
section .data

section .text
    align 16
    extern scheduler
    extern ass3
    extern printf
    extern stdin
    extern drones_data
    extern scheduler_index
    extern num_of_Drones
    extern x_target_loc
    extern y_target_loc
    global printer     
    extern resume

printer:          ;that will print only the target location x,y (they will be float)
        pushad
        fld dword [y_target_loc]        ;to print floats we need to load it to x87 stack and store it directly in the 'regular' stack
        sub esp,8
        fstp qword [esp]
        fld dword [x_target_loc]        ;same note as in line 25
        sub esp,8
        fstp qword [esp]
        push format_string_target
        call printf
        add esp, 20
        popad

    mov dword ebx,0         ;clearing ebx before looping
    mov dword eax,[drones_data]       ;now eax has the data of all drones
    
    looping:                        ;that will print the data of each drone by the asked format
        cmp ebx,[num_of_Drones]     ;check if this is the last drone
        je finish_printing          ;if so, jump to finish the printing
        inc ebx                     ;else increase in 1 the number of printed drones
        mov dword ecx,[eax+12]      ;ecx now holds number of wins of the current drone
        pushad
        
        push dword [eax+12]            ;number of wins of this drone             
        fld dword [eax+8]   ;the angel of the drone (because this is a float!)
        sub esp,8           ;saving space for the next argument we gonna store in the stack (y_location)
        fstp qword [esp]    ;store in the stack the float (of the current drone angel)
        fld dword [eax+4]   ;y_loc of the drone
        sub esp,8           ;saving space in the stack for x_location of the curren drone
        fstp qword [esp]    ;store the y_location in the stack (because this is a float!)
        fld dword [eax] ;x_loc of the drone
        sub esp,8
        fstp qword [esp]    ;store the y_location in the stack (because this is a float!)
                                          
        push ebx        ;the drone index (forst argument that printed)     
        push format_string_float
        call printf
        add esp,36                  ;pushed 5 arguments
        popad
        add eax,16                  ;point to the next drone's data
        jmp looping

    finish_printing:
        mov dword ebx,[scheduler_index] ;we would like to continue with the scheduler co-routine
        call resume
        jmp printer

       
        