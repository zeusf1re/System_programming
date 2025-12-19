format ELF64
extrn std_print_string

public _start

section '.data' writable
    msg_enter_ip    db "Enter Server IP: ", 0
    wait_msg        db "Connecting to server...", 10, 0
    ask             db "K" 
    err_msg         db "Connection failed!", 10, 0
    
    server_addr:
        dw 2              ; AF_INET
        db 0x1F, 0x90     ; Port 8080
        dd 0              ; IP будет заполнен
        dq 0

section '.bss' writable
    sock_fd         rq 1
    buffer          rb 256
    ip_input        rb 32  

section '.text' executable
_start:
    ; === Ввод IP ===
    mov rdi, msg_enter_ip
    call std_print_string

    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    lea rsi, [ip_input]
    mov rdx, 31
    syscall
    
    ; Парсинг IP
    lea rsi, [ip_input] 
    lea rdi, [server_addr + 4] 
    call parse_ip

    mov rdi, wait_msg
    call std_print_string

    ; === Подключение ===
    mov rax, 41         ; socket
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov [sock_fd], rax

    mov rax, 42         ; connect
    mov rdi, [sock_fd]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    
    test rax, rax
    js conn_error       ; <--- ИСПРАВЛЕНО: убрана точка, теперь это глобальная метка

game_loop:
    ; === 1. Получение данных ===
    mov rax, 0             
    mov rdi, [sock_fd]
    mov rsi, buffer
    mov rdx, 255
    syscall

    test rax, rax
    jz server_disconnected ; <--- Тоже лучше сделать глобальной или убедиться в области видимости
    
    ; Ставим null-терминатор
    mov byte [buffer + rax], 0
    
    ; Печать (пропускаем байт типа сообщения)
    mov rdi, buffer
    inc rdi 
    call std_print_string

    ; === 2. Подтверждение (ACK) ===
    mov rax, 1 
    mov rdi, [sock_fd]
    lea rsi, [ask] 
    mov rdx, 1
    syscall

    ; === 3. Логика ===
    cmp byte [buffer], 1
    je .do_turn
    
    cmp byte [buffer], 2
    je exit_game           ; <--- Глобальная метка

    jmp game_loop

.do_turn:
    ; Читаем ввод
    mov rax, 0     
    mov rdi, 0     
    lea rsi, [buffer]
    mov rdx, 2      
    syscall
    
    ; Отправляем
    mov rax, 1          
    mov rdi, [sock_fd] 
    lea rsi, [buffer] 
    mov rdx, 1       
    syscall
    
    jmp game_loop

; === Обработчики выхода (сделаны глобальными для надежности) ===

server_disconnected:
exit_game:
    mov rax, 3
    mov rdi, [sock_fd]
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall

conn_error:             ; <--- Глобальная метка (без точки в начале)
    mov rdi, err_msg
    call std_print_string

    mov rax, 60
    mov rdi, 1
    syscall

; === Parse IP ===
parse_ip:
    push rbx
    push rcx
    push rdx
    
    xor eax, eax    
    xor ecx, ecx    
    xor rdx, rdx    

    .next_char:
        mov bl, [rsi]
        inc rsi
        
        cmp bl, '.' 
        je .save_byte
        cmp bl, 10      
        je .finish
        cmp bl, 0       
        je .finish
        
        sub bl, '0'
        movzx rbx, bl
        
        imul ecx, 10
        add ecx, ebx
        jmp .next_char

    .save_byte:
        mov [rdi], cl
        inc rdi
        xor ecx, ecx
        jmp .next_char

    .finish:
        mov [rdi], cl
        pop rdx
        pop rcx
        pop rbx
        ret