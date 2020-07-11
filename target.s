section .data
    extern x_target_loc
    extern y_target_loc

section .text
    align 16
    extern generate_random
    extern scheduler_index
    extern resume
    global target

target:
    pushad
    push word 100           ;the length of the board... needed to use generate random
    call generate_random
    mov dword [x_target_loc],eax    ;the answer returned to eax (as a float) and stored in x_target_loc
    add esp,4                       ;clearing the stack from the 100
    push word 100           ;the high of the board
    call generate_random
    mov dword [y_target_loc],eax
    add esp,4               ;clearing stack from the 100
    popad
    mov dword ebx,[scheduler_index]     ;before we call to resume we put in ebx the index of the co-routine we would like to run
    call resume             
    jmp target                  ;next time we will be perform this co-routine we will continue from this place, that's wyh we jmt to the beggining of the 'function'
