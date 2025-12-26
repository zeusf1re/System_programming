format ELF64

extrn std_print_string
extrn atoi

public main

section '.data' writable
    net_msg_wait    db "Waiting for client...", 10, 0 
    net_msg_entry   db "Hi, send me some numbers (one in one row)", 10, "q -  to exit", 10, 0

    server_addr:
        dw 2
        db 0x1F, 0x90 
        dd 0          
        dq 0

    capacity        dq 5
    size            dq 0

section '.bss' writable
    server_sock     rq 1
    client_sock     rq 1
    buffer          rb 12 ; вроде верно посчитал 2^32

    p_vec_start     rq 1

section '.text' executable
main:
    ; === Инициализация сети ===
    mov rax, 41         
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    mov [server_sock], rax
    
    mov rax, 1          ; reuse addr
    mov rdi, [server_sock]
    mov rsi, 2          ; SOL_SOCKET
    mov rdx, 2          ; SO_REUSEADDR (примерно, зависит от системы, можно пропустить)
    
    mov rax, 49         ; bind
    mov rdi, [server_sock]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    
    mov rax, 50         ; listen
    mov rdi, [server_sock]
    mov rsi, 2
    syscall


    mov rdi, net_msg_wait
    inc rdi
    call std_print_string
    
    mov rax, 43         ; accept P1
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [client_sock], rax


    mov rax, 1
    mov rdi, [client_sock]
    lea rsi, [net_msg_entry]
    mov rdx, 33
    syscall


    mov rax, 12
    mov rdi, 0
    syscall

    mov [p_vec_start], rax
    mov [size], 0

    mov rdi, [capacity]
    shl rdi, 2
    add rdi, [p_vec_start]
    mov rax, 12
    syscall


    main_loop:

        ;read
        mov rax, 0
        mov rdi, [client_sock]
        lea rsi, [buffer]
        mov rdx, 11     
        syscall
        dec rax
        mov byte [buffer + rax], 0

        cmp byte [buffer], 'q'
        je exit

        lea rdi, [buffer]
        call atoi

        call PushBack

        jmp main_loop

exit:
    mov rdi, [p_vec_start]
    mov rsi, [size]
    call BubbleSort

    xor rdx, rdx
    mov rax, [size]
    mov rcx, 2
    div rcx

    mov rbx, [p_vec_start]
    
    movsxd rax, dword [rbx + rax * 4]; расиширяет и знак в отличии от movzx
    
    mov rdi, buffer + 11
    call int_to_str

    mov rsi, rax 
    ;rdx from int_to_str
    
    mov rax, 1
    mov rdi, [client_sock]
    syscall

.real_exit:
    mov rax, 60
    mov rdi, 0
    syscall
        

;sys_brk(addr)
PushBack:
    push rax 


    mov rcx, [size]
    cmp rcx, [capacity]
    jl .write_value 

    mov rax, [capacity]
    shl rax, 1  
    mov [capacity], rax 
    
    mov rdi, rax
    shl rdi, 2 
    
    mov rax, 12
    xor rdi, rdi
    syscall     
    
    mov rdi, [p_vec_start]
    mov rsi, [capacity]
    shl rsi, 2    
    add rdi, rsi 
    
    mov rax, 12   ; sys_brk
    syscall
    


    .write_value:
        pop rax 
        
        mov rbx, [p_vec_start]
        mov rcx, [size]
        

        mov [rbx + rcx*4], eax  
        
        inc qword [size]
        ret

;rdi - array, rsi - count
BubbleSort:
    push rbp
    mov rbp, rsp

    push rbx

    
    mov r8, 0; i
    mov r9, 1; j
    ; 0 < i < c - 1 
    ; i + 1 < j < c    j идет вниз от последнего до i + 1
    .big_loop:
        inc r8
        cmp r8, rsi
        je .end
        dec r8

        mov r9, rsi
        dec r9
        .small_loop:
            dec r9
            cmp r9, r8
            je .big_inc
            inc r9

            dec r9
            mov eax, dword [rdi + r9 * 4]; arr[j - 1]
            inc r9
            mov ebx, dword [rdi + r9 * 4] ; arr[j]

            cmp eax, ebx
            jle .small_inc

            dec r9
            mov dword [rdi + r9 * 4], ebx; arr[j - 1]
            inc r9
            mov dword [rdi + r9 * 4], eax ; arr[j]
            
            .small_inc:
                dec r9
                jmp .small_loop

        .big_inc:
            inc r8
            jmp .big_loop

        .end:
            pop rbx

            mov rsp, rbp
            pop rbp
            ret

; input RAX = число, RDI = конец буфера (например buffer + 32)
; ret RAX = указатель на начало полученной строки, RDX = длина
int_to_str:
    mov rbx, 10
    mov rcx, rdi  
    dec rdi
    mov byte [rdi], 10 

    .loop:
        dec rdi
        xor rdx, rdx
        div rbx       
        add dl, '0'  
        mov [rdi], dl
        test rax, rax
        jnz .loop
        
        mov rax, rdi  
        

        mov rdx, rcx
        sub rdx, rax
        ret
