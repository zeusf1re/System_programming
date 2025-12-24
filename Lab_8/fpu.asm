format ELF64

extrn printf
extrn scanf
extrn exit
extrn exp

public main

section '.data' writeable

    t_ask_x         db "Hello, enter x: ", 0
    t_ask_prec      db "Enter precision (number of digits after comma): ", 0
    
    fmt_lf          db "%lf", 0     
    fmt_d           db "%d", 0      
    
    fmt_res         db 10, "Result (Taylor): Sum = %.*lf", 10, "Iterations = %d", 10, 0 
    fmt_exact       db "Exact: .*lf", 10, 0
    
    const_10        dd 10           
    const_1         dq 1.0

section '.bss' writeable

    x               dq ?            
    k_prec          dd ?            
    n_counter       dq ?            
    eps             dt ?            
    res_exact       dq ?            

section '.text' executable

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16            


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
    call scanf              


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


    ;  (1 + 2x^2)
    movsd xmm0, [x]
    mulsd xmm0, xmm0        ; xmm0 = x^2
    
    movsd xmm1, xmm0  
    addsd xmm1, xmm1 
    addsd xmm1, [const_1]   ; 1 + 2x^2
    movsd [res_exact], xmm1 


    call exp                ; xmm0 = exp(x^2)
    

    mulsd xmm0, [res_exact] 
    movsd [res_exact], xmm0 

    
    fld qword [x]          ; ST0 = x
    fmul st0, st0          
    
    fld1                   ; будет суммой
    fld1                   ; а это qurr
    
    ;  a(1.0), Sum(1.0), x^2
    
    mov rcx, 1      

.main_loop:
    mov [n_counter], rcx    
    
   ; k
    fld st2                 ; push x^2
    fidiv dword [n_counter] ; x^2 / n
    
    fild qword [n_counter]  
    fadd st0, st0           ; 2n
    fld st0                 
    fld1
    faddp st1, st0          ; 2n+1
    fxch st1                ; 2n, 2n+1           exhange типо
    fld1
    fsubp st1, st0          
    fdivp st1, st0          
    
    fmulp st1, st0          ; K = Coeff * (x^2/n)
    
    ; new a
    fmul st0, st1         
    fstp st1                ; pop a_old
    

    fld st0      
    fadd st0, st2 
    fstp st2   
    
	;precision
    fld st0   
    fabs           
    fld tbyte [eps] 
    fcomip st1              
    fstp st0                
    
    ja .loop_finish  
                            
    inc rcx       
    jmp .main_loop

.loop_finish:
    fstp st0 
    
    fstp qword [rsp]  
    movsd xmm0, [rsp]      
    
    fstp st0         ; ниче не осталось

    ; Print Taylor
    lea rdi, [fmt_res]
    mov esi, [k_prec]   
    mov rdx, rcx           
    mov rax, 1             
    call printf

    ; Print Exact
    movsd xmm0, [res_exact]
    lea rdi, [fmt_exact]
    mov esi, [k_prec]
    mov rax, 1
    call printf

    add rsp, 16            
    xor rax, rax           
    pop rbp                 
    ret
