
format ELF64

extrn printf
extrn scanf
extrn exit

public main

section '.data' writeable


    t_ask_x         db "Hello, enter x: ", 0
    t_ask_prec      db "Enter precision (number of digits after comma): ", 0
    

    fmt_lf          db "%lf", 0     ; для double а звездочко для precision
    fmt_d           db "%d", 0      ; для int
    
    fmt_res         db 10, "Result: Sum = %.*lf", 10, "Iterations = %d", 10, 0 

    
    const_10        dd 10           

section '.bss' writeable

    x               dq ?            ; double
    k_prec          dd ?            ; int
    n_counter       dq ?            ; int
    eps             dt ?            ; 80bits
    

section '.text' executable

main:
    push rbp
    mov rbp, rsp

    lea rdi, [t_ask_x]      
    xor rax, rax            
    call printf

    lea rdi, [fmt_lf]       
    lea rsi, [x]            
    xor rax, rax
    call scanf              

    
    
    
    lea rdi, [t_ask_prec]
    xor rax, rax
    call printf

    lea rdi, [fmt_d]        
    lea rsi, [k_prec]       
    xor rax, rax
    call scanf              ; scanf("%d", &k_prec)


    fld1                    
    mov ecx, [k_prec]       
    
    test ecx, ecx           
    jz .eps_done            

.calc_eps_loop:
    fidiv dword [const_10]  
    dec ecx                 
    jnz .calc_eps_loop      

.eps_done:
    fstp tbyte [eps]      
                         
    fld qword [x]           ; Грузим x из памяти (64 -> 80 бит). ST0 = x
    fmul st0, st0           ; ST0 = x * x
  
    fld1   
    fld1  
    ; ST0 = 1.0 a_current
    ; ST1 = 1.0 sum
    ; ST2 = x^2 const
    
    mov rcx, 1      

    ; K_n = [(2n+1)/(2n-1)] * [x^2 / n]
.main_loop:
   
    mov [n_counter], rcx    
    
    ; x^2 / n
    fld st2  ; Стек: x^2, a_old, Sum, x^2
                            
    fidiv dword [n_counter] 
                            ; Стек: (x^2/n), a_old, Sum, x^2
    
    ; (2n + 1) / (2n - 1) 
    fild qword [n_counter]  ;st0 = n
    fadd st0, st0           
    
    fld st0                 ;copy st0
    fld1                   
    faddp st1, st0          ; 2n + 1. 
    
    fxch st1                ; Меняем местами. Стек: 2n, (2n+1), ...
    fld1                    
    fsubp st1, st0          ; 2n - 1.       Стек: (2n-1), (2n+1), ...
    
    fdivp st1, st0          ; st0 = 2n - 1 / 2n + 1
                            ; Стек: Coeff_Part1, Coeff_Part2(x^2/n), a_old, Sum, x^2
    
    fmul st0, st1           ; st0 = res, no v st1 lezhit k2
    

    fxch st1                ; Стек: Trash, K, a_old...
    fstp st0                ; Выкидываем Trash. 
                            ; Стек: K, a_old, Sum, x^2. (Идеально!)


    fmul st0, st1           ; ST0 = K * a_old = a_new.   ST1 = a_old.
    
    ; переносим первый во второй и попаем
    fstp st1             
                            ; Стек: a_new, Sum, x^2.
    

    ;sum
    fld st0   
    faddp st2, st0   
                            ; Стек: a_new, Sum_new, x^2.

    ;check precision
    fld st0                 ; Копия a_new
    fabs           
    fld tbyte [eps] 
    
    fcomip st1              ; сравнивает и попает, причем у меня даже флаги cpu ставятся

    fstp st0          
                            ; Стек: a_new, Sum, x^2.

    ja .loop_finish  
                    
                   
                            
    inc rcx       
    jmp .main_loop

.loop_finish:
    
    fstp st0    ; был a_new
    

    ; FPU -> Память -> XMM0
    fstp qword [rsp]      
                         
    movsd xmm0, [rsp]     
    
    fstp st0                ; clear fpu
    

    lea rdi, [fmt_res]    
    mov esi, [k_prec]
                            ; float уже в xmm0
    mov rdx, rcx            
    mov rax, 1 ; кол-во векторных регистров              
    call printf

    xor rax, rax           
    pop rbp                 
    ret                     ; Возврат из main (в libc start)
