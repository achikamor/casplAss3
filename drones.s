%macro deg_to_rad 0
;mul with pi and div with 180
fldpi       ;store pi in x87
fidiv dword [one_80]    ;divide with 180
fimul dword [temp_alpha]    ;multiply with the angel (degree)
%endmacro

section .rodata
    one_80: dd 80
    printing_winner: db "Drone id %d: I am a winner",10,0
    hundred:dw 100
    sixty: dw 60
    three60: dw 360
    zero: dw 0

section .bss
    temp: resd 1
    sec_temp:resd 1
    

section .data
    temp_x_loc dd 0
    temp_y_loc dd 0
    temp_alpha dd 0
    temp_dis dd 0
    flag db 0
    calc_temp_x dd 0
    calc_temp_y dd 0
    gamma dd 0
    x2MINx1 dd 0
    y2MINy1 dd 0
    alphaMINgamma dd 0
    POWy2MINy1 dd 0
    POWx2MINx1 dd 0
    calc_res dd 0
    can_destroy db 0
    
section .text
    align 16
    extern x_target_loc
    extern y_target_loc
    extern generate_random
    extern drones_data
    extern RR_counter
    extern num_of_Drones
    extern malloc
    global drone
    extern print_iterations_schedule
    extern target
    extern num_of_Targets
    extern scheduler_index
    extern AngleOfView
    extern distance
    extern resume
    extern endCo
    extern printf
    extern CORS
    extern free
    extern stack_array
    extern target_index

drone:  
    push 100    ;the limit of x_loc   (0-100)
    call generate_random
    mov [temp_x_loc],eax    ;save the result in this label(floats)
    add esp,4               ;clearing the stack
    push 100    ;the limit of y_loc   (0-100)
    call generate_random
    add esp,4
    mov [temp_y_loc],eax    ;save the result in this label(floats)
    push 360        ;the first angel of the drone (0-360)
    call generate_random
    add esp,4
    mov dword [temp_alpha],eax
    mov ebx,[drones_data]   ;ebx hold the addres of the beggining of the structure drones_data
    
    mov eax,[RR_counter]        ;in wich co-routine are we...  this is the same drone number
    mov esi,16                  ;each drone is in the size of 16 byte
    mul esi                     ;now eax+ebx will point to the beggining of the data of the curren drone
    mov ecx,[temp_x_loc]
   
    mov dword [ebx+eax],ecx     ;store in the current drone x_location the temp_x_loc
    mov ecx,[temp_y_loc]
    mov dword [ebx+eax+4],ecx   ;store in the current drone y_location the temp_y_loc
    mov dword ecx, [temp_alpha]
    mov dword [ebx+eax+8],ecx   ;store in the current drone angel the temp_alpha
    mov dword [ebx+eax+12],0    ;initialize the number of wins of this drone to be 0
    
    
drones_loop:
    push 120            ;FIRST WE RANDOMIZE AN ANGEL  (from 0 to 120)
    call generate_random
    add esp,4           ;clear the stack
    mov dword[temp_alpha],eax
    fld dword[temp_alpha]
    fisub word [sixty]  ;reduce from the randomized angel 60 because the angel should be from -60 to 60 and not from 0 to 120
    fstp dword [temp_alpha] ;save the correct randomized angel in this variable

    push 50             ;THEN WE RANDOMIZE A DISTANCE (0-50)
    call generate_random
    mov [temp_dis],eax
    add esp,4
    mov ebx,[drones_data]
    mov eax,[RR_counter]
    mov edx,16
    mul edx
    
    fld dword [temp_alpha]
    fadd dword [eax+8+ebx]  ;add to the current drone angel the randomized new angel
    fild word [three60]     ;push to x87 the number 360
    fcomip              ;compare between the new angel of the drone(previuse angel+new angel) and 360
    ja less_360         ;check if 360>curren drone's angel
    fisub word [three60]    ;if not (drone's angel>360) reduce from it 360
    less_360:       ;else  (360> drone's angel)
    fild word [zero] ;push 0 to x87
    fcomip ;compare between 0 and the angel
    jb legal_angle  ;check if angel>0  if so jump to this label
    fiadd word [three60]    ;else, add to the angel 360
    legal_angle:
    fst dword [eax+ebx+8]   ;store the fixed new angel in the drones_data structure (in the current drone's angel place)
    fstp dword [temp_alpha] ;store and pop from x87 the angel in this label (to get it easier in the next lines!)
   ;NOW WE HAVE THE NEW CALCULATED ALPHA IN DEGREES ,THE DRONE IS READY TO MOVE BY IT

    FLD dword [temp_alpha]           ;pushing to the float stack the angel in degrees
    deg_to_rad                  ;the angel in rad now in ax
    fsin    ;sin the angel (in radians)
    fmul dword [temp_dis]   ;mul the sin-angel with the distance to check the x_movment
    fadd dword [eax+ebx]   ;add the x_movment distance to the corrent drone's x_location  

    fild word [hundred]     ;store in x87 the number 100
    fcomip  ;compare between the new x_location(of the current drone) and 100
    jae not_more_x  ;check if 100>= new x_location
    fisub word [hundred]    ;if x_loc > 100 reduce from it 100
    jmp legal_x     ;now the x_location is less than 100 
    not_more_x:     
    fild word [zero]    ;store 0 in x87
    fcomip  ;compare x_loc and 0
    jbe legal_x ;check x_loc >= 0
    fiadd word [hundred]    ;if 0 > x_lox add to x_locc 100 
    legal_x:
    fstp dword [eax+ebx]    ;store the new fixed x_location in the drones_data structure
    ;now we have the new x location after movment

    FLD dword [temp_alpha]  ;store in x87 the angel (in degrees)  
    deg_to_rad              ;change it to rads
    fcos    ;cosinos it
    fmul dword [temp_dis]   ;multiply the cosinos with the distance of movement
    fadd dword [eax+ebx+4]  ;add the drone's y_location the new y_movement

    fild word [hundred]     ;again as in the x_movement we check if the new y_location is >=0 and <=100  (  0=< y_loc <= 100  )
    fcomip
    jae not_more_y
    fisub word [hundred]
    jmp legal_y
    not_more_y:
    fild word [zero]
    fcomip
    jbe legal_y
    fiadd word [hundred] 
    legal_y:
    fstp dword [eax+ebx+4]
    ;now we have the new y location after movment
   
    
    mayDestroy:         ;after calculate the new x_loc and y_loc check if the drone can hit the target! (check by the given fornula in the task instructions)
    fld dword [y_target_loc]    
    fsub dword [eax+ebx+4]
    fstp dword [y2MINy1]    ;target_y_loc - drone's_y_loc

    fld dword [x_target_loc]
    fsub dword [eax+ebx]
    fstp dword [x2MINx1]    ;target_x_loc - drone's_x_loc

    fld dword [y2MINy1]
    fld dword [x2MINx1]
    fpatan          ;do arctan2(y2-y1, x2-x1)

    fstp dword [gamma]  ;the result of the arctan is gamma
    fld dword [eax+ebx+8]   ;load the angel of the drone
    fsub dword [gamma]  ;reduce from the drone's angel gamma
    fabs    ;absulote value
    fild dword [AngleOfView]    ;store the angel of view who's givven us in the arguments of this program
    fcomip
    jb end_loop ;if the abs is greater than the given beta we can't hit the target

    finit       ;else check the other condition of hiting the target...  clean x87 first just to be sure
    fld dword [y2MINy1]
    fmul dword [y2MINy1]
    fstp dword [y2MINy1]        ;(y2-y1)^2 is now in this label

    fld dword [x2MINx1]
    fmul dword [x2MINx1]        ;now we have in x87 (x2-x1)^2
    fadd dword [y2MINy1]        ;add to it the (y2-y1)^2
    fsqrt   
    
    fild dword [distance]
    fcomip     ;compare between distance and sqrt[(y2-y1)^2 + (x2-x1)^2]

    ja destroy_target   ;if distance is greater , we can hit the target
    end_loop:       ;else we can't and we want to continue the scheduler running
    mov dword ebx,[scheduler_index]
    call resume
    jmp drones_loop


destroy_target:
inc dword [eax+ebx+12]       ;NOW THE CURRENT DRONE NUMBER OF WINS INCREASED
mov dword ecx,[eax+ebx+12]  ;ecx holds the increased number of wins of the current drone
cmp ecx,[num_of_Targets]       ;CHECK IF THIS DRONE JUST WON!      
je has_winner       ;check if the drone have the wanted number of hit to be the winner, if so jump to has_winner
mov dword ebx,[target_index]  ;else keep the running of the scheduler
call resume
jmp end_loop


has_winner:         ;the corrent drone is the winner!  print the requested data and clean all malloced space/variables/pointers
mov eax,[RR_counter]
inc eax
push eax    ;the winner drone number is in eax
push printing_winner
call printf
add esp,8
;cleaning all the malloced data
push dword[stack_array] 
call free
add esp,4
push dword [drones_data]
call free
add esp,4
push dword [CORS]
call free
add esp,4
mov eax,1
mov ebx,0
int 0x80





