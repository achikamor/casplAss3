section .rodata
    format_string_1: db "%d",0    ;format string for decimal
    global STKSZ
    STKSZ: dd 16384
    n: dd 0xFFFF
    
section .bss
    global num_of_Drones
    num_of_Drones: resd 1
    global num_of_Targets
    num_of_Targets: resd 1
    global print_iterations_schedule
    print_iterations_schedule: resd 1
    global AngleOfView
    AngleOfView: resd 1
    global distance
    distance: resd 1
    global seed
    seed: resw 1
    global stack_array
    stack_array: resd 1
    global CORS
    CORS: resd 1 
    global drones_data
    drones_data: resd 1
    SPT: resd 1
    SPMAIN: resd 1
    global scheduler_index
    scheduler_index:resd 1
    global printer_index
    printer_index:resd 1
    global scheduler_stack
    scheduler_stack: resb 16384
    global target_stack
    target_stack: resb 16384
    global printer_stack
    printer_stack: resb 16384
    global target_index
    target_index: resd 1
section .data
    global x_target_loc
    x_target_loc dd 0
    global y_target_loc
    y_target_loc dd 0
    winner db 0
    result dd 0
    extended_seed dd 0 
    
section .text
    align 16
    extern scheduler
    extern sscanf
    extern printf 
    extern malloc 
    extern free 
    extern stdin
    global main
    global generate_random
    global printer_index
    extern scheduler
    extern start_co
    extern drone
    extern printer
    extern target
main:
    mov ebx,[esp+8]
    pushad
    push num_of_Drones
    push format_string_1
    push dword [ebx+4]
    call sscanf     ;copying the argument in argv[1] into num of drones
    add esp,12
    popad
    pushad
    push num_of_Targets
    push format_string_1
    push dword [ebx+8]
    call sscanf     ;copying the argument in argv[2] into num of targets
    add esp,12
    popad
    pushad
    push print_iterations_schedule
    push format_string_1
    push dword [ebx+12]
    call sscanf     ;copying the argument in argv[3] into print iterations
    add esp,12
    popad
    pushad
    push AngleOfView
    push format_string_1
    push dword [ebx+16]
    call sscanf     ;copying the argument in argv[4] into format string
    add esp,12
    popad
    pushad
    push distance
    push format_string_1
    push dword [ebx+20]
    call sscanf     ;copying the argument in argv[5] into seed
    add esp,12
    popad
    pushad
    push seed
    push format_string_1
    push dword [ebx+24]
    call sscanf     ;copying the argument in argv[5] into seed
    add esp,12
    popad
    mov dword eax,[num_of_Drones]
    mov dword ebx,[STKSZ]
    mul ebx      ;the result will be in eax - the drones stack for their proccesses
    pushad
    push eax
    call malloc
    mov dword [stack_array], eax
    add esp,4
    popad
    pushad
    mov eax,[num_of_Drones]
    mov ebx,16
    mul ebx          ;each drone will save it's 4byte x_loc, 4byte y_loc,4 byte angel,4byte number_of_targets
    push eax
    call malloc
    mov [drones_data],eax
    add esp,4       
    popad
    pushad
    mov eax,[num_of_Drones]
    add eax,3     ;add the scheduler printer and target
    mov ebx,8       ;2 adresses each needs 4 bytes
    mul ebx      ;every cor will have 2 pointers
    push eax
    call malloc
    mov dword [CORS],eax
    add esp,4
    popad
    pushad
    call generate_target    ;we generate our first target
    popad
    
    mov edx,[CORS]
    mov ecx, [num_of_Drones]
    add ecx, 2                  ;in the cors array we need extra 3 spaces 1 for scheduler 1 for printer 1 for target

    mov esi, scheduler                      ;save scheduler label(first instruction pointer) in esi 
    mov dword [scheduler_index],ecx         ;save the index inside the COrs array of the scheduler in a label
    mov ebx,scheduler_stack                 ;mov scheduler stack pointer to ebx
    add ebx,[STKSZ]                         ;make it point to the top of the stack
    mov dword [edx+ecx*8],esi               ;put the scheduler pointer in CORS
    mov dword [edx+ecx*8+4],ebx             ;put the scheduler stack in CORS
    dec ecx


    mov esi, target                         ;save target label(first instruction pointer) in esi
    mov dword [target_index],ecx            ;save the index inside the COrs array of the target in a label
    mov dword ebx,target_stack              ;mov target stack pointer to ebx
    add dword ebx,[STKSZ]                   ;make it point to the top of the stack
    mov dword [edx+ecx*8],esi               ;put the target pointer in CORS
    mov dword [edx+ecx*8+4],ebx             ;put the target stack in CORS
    dec ecx

    mov esi, printer                        ;save printer label(first instruction pointer) in esi
    mov dword [printer_index],ecx           ;save the index inside the COrs array of the printer in a label
    mov dword ebx,printer_stack             ;mov printer stack pointer to ebx
    add dword ebx,[STKSZ]                   ;make it point to the top of the stack
    mov dword [edx+ecx*8],esi               ;put the printer pointer in CORS
    mov dword [edx+ecx*8+4],ebx             ;put the printer stack in CORS
    dec ecx


    mov eax, [num_of_Drones]                
    mov esi , [STKSZ]
    mul esi                                 ;now eax holds the offset from the bottom of drone 1 stack to the top of the last drone stack
    
    mov ebx,[stack_array]
    add eax,ebx                             ;now eax points to the top of the last stack inside stack array
    mov edx,[CORS]                          
    Cors_loop:
    mov dword [edx+ecx*8], drone            ;put the drone pointer in CORS fo drone[ecx]
    mov dword [edx+ecx*8+4],eax             ;put the top of stack pointer of drone[ecx] in CORS
    sub eax, [STKSZ]                        ;eax now points to top of the previous drone
    dec ecx         
    cmp ecx, 0 
    jnl Cors_loop
    mov ecx,[num_of_Drones]
    add ecx,2
    init_loop:                              ;init each Co -routine in a loop that runs from num_of_drones+2 to 0
    pushad
    push ecx
    call init_cors
    add esp,4
    popad
    dec ecx
    cmp ecx, 0
    jnl init_loop
    
    call start_co                           ;we start the fun by calling start_co who will tell our scheduler that he can start doing its job

generate_target:
    push ebp
    mov ebp,esp 
    pushad
    push 100                                ;push the top number that will is our top limit to randomize
    call generate_random                    
    mov dword [x_target_loc], eax           ;save the calculated x value of target
    add esp,4
    push 100                                ;push the top number that will is our top limit to randomize
    call generate_random
    mov dword [y_target_loc], eax           ;save the calculated y value of target
    add esp,4
    popad
    mov esp,ebp
    pop ebp
    ret

generate_random:
    push ebp
    mov ebp,esp 
    call LFSR                               ;generate next psuedo 16 bit number
    mov eax,0                       
    mov word ax,[seed]
    mov dword [extended_seed],eax           ;we move the 16 bit number to eax and from there to extended seed which is the same number but in a 32 bit so it will be positive
    fild dword [extended_seed]              ;load seed now 32 bit to the floating point regiseters
    fidiv dword [n]                         ;divide it by 0xFFFF (positive max short int)
    fimul word [ebp+8]                      ;multiply it by the scaling parameter 
    mov eax, 0
    FSTP dword [result]                     ;store result
    mov dword eax,[result]                  ;move it to eax
    mov dword [extended_seed],0             ;zero extended seed
    finit                                   ;make sure float registers are as new
    mov esp,ebp
    pop ebp
    ret

LFSR:
    push ebp
    mov ebp,esp
    mov ecx, 16
    LFSR_loop:
    mov word ax,[seed]
    and ax,1                        ;ax holds lsb and will be our accumulator
    mov word bx,[seed]
    shr bx,2                         
    and bx,1                         ;bx holds byte "14"   
    xor ax, bx                       ;xor them   
    mov word bx,[seed]
    shr bx,3                         
    and bx,1                         ;bx holds byte "13"
    xor ax,bx                          
    mov word bx,[seed]
    shr bx,5    
    and bx,1                         ;bx holds byte "11"
    xor ax,bx
    mov word bx,[seed]                
    shr bx,1                         ;make place in bx for new lsb
    shl ax,15                        ;align new lsb
    add bx,ax                        ;put new lsb in place
    mov word [seed],bx               
    loop LFSR_loop, ecx
    mov esp,ebp
    pop ebp
    ret


init_cors:
push ebp
mov ebp,esp
mov ebx, [ebp+8] ; get co-routine ID number
mov eax,[CORS]
mov edx, [8*ebx + eax] ; get initial EIP value – pointer to COi function
mov [SPT], esp ; save ESP value
mov esp, [8*ebx + eax+4] ; get initial ESP value – pointer to COi stack
push edx ; push initial “return” address
pushfd ; push flags
pushad ; push all other registers
mov [8*ebx + eax+4], esp ; save new SPi value (after all the pushes)
mov esp, [SPT] ; restore ESP value
mov esp,ebp
pop ebp
ret
