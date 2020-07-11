section .rodata

section .bss
    SPMAIN: resd 1      ;pointer to main
    SPT: resd 1         ;temp stack pointer
    global CURR
    CURR: resd 1
section .data
    global RR_counter
    RR_counter dd 0     ;using as a roud-robin index
    print_counter dd 0
    

section .text
    align 16
    global scheduler
    extern ass3
    extern sscanf
    extern printf 
    extern malloc 
    extern free 
    extern stdin
    extern num_of_Drones
    global start_co
    extern print_iterations_schedule
    extern printer
    extern printer_index
    extern scheduler_index
    extern index
    extern CORS
    global endCo
    global resume
    

start_co:       
    pushad ; save registers of main ()
    mov [SPMAIN], esp ; save ESP of main ()
    mov ebx, [scheduler_index] ; gets ID of a scheduler co-routine
    jmp do_resume ; resume a scheduler co-routine    

scheduler:
    mov dword ebx,[RR_counter]          ;we want to resume with the given co-routine (as in rr_counter)
    call resume
    inc dword [RR_counter]      ;next time we will do resume the rr_counter will be the next one
    mov eax,[RR_counter]
    cmp dword eax,[num_of_Drones]   ;check if the rr_counter is no bigger than the number of drones
    jl no_change_RR     ;if so jump to this label
    mov dword [RR_counter],0    ;else (it's equal) start again with the 0's co-routine
    no_change_RR:
    inc dword [print_counter]   ;increase the number of drones playing move (because every k drones move we need to print)
    mov dword eax,[print_counter]
    cmp dword eax, [print_iterations_schedule]  ;check if we played enough turns to print (depeneds on the givven K )
    jl scheduler    ;if not, go to scheduler to continue the game without printing
    mov dword [print_iterations_schedule],0     ;else clear the number of drones movments and go to print!!! 
    mov dword ebx, [printer_index]      ;tell the scheduler we want to print
    call resume
    jmp scheduler



resume: ; save state of current co-routine
    pushfd
    pushad
    mov edx, [CURR]
    mov eax, [CORS]
    mov dword [eax+8*edx+4], esp ; save current ESP
do_resume: ; load ESP for resumed co-routine
    mov eax, [CORS]
    mov dword esp, [ebx*8 + eax + 4]
    mov dword [CURR], ebx
    label2:
    popad ; restore resumed co-routine state
    popfd
    ret ; "return" to resumed co-routine


    
endCo:
mov ESP, [SPMAIN] ; restore ESP of main()
popad ; restore registers of main()