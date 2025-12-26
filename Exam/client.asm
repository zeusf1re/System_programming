; read(intro)
; loop:
;   send 1 int
;   if q -> quit
;   jmp loop
; 
; read
; print
; exit
format ELF64

public main

extrn atoi
extrn printf ; Используем libc для удобного вывода (или можно свои write)
extrn exit

section '.data' writable
    server_addr:
        dw 2            ; AF_INET
        db 0x1F, 0x90   ; Port 8080 (0x1F90 big endian -> 8080)
        dd 0x0100007F   ; IP 127.0.0.1 (0x7F000001 little endian)
        dq 0

    prompt_msg db "Enter number (or 'q' to finish): ", 0
    result_msg db 10, "Server sent median: ", 0
    newline    db 10, 0
    
    fmt_str    db "%s", 0 ; Для printf

section '.bss' writable
    sock_fd     rq 1
    buffer      rb 256
    len         rq 1

section '.text' executable

main:
    
    mov rax, 41         ; sys_socket
    mov rdi, 2          ; AF_INET
    mov rsi, 1          ; SOCK_STREAM
    xor rdx, rdx        ; protocol 0
    syscall
    
    test rax, rax
    js .error           
    mov [sock_fd], rax

    
    mov rax, 42         
    mov rdi, [sock_fd]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    
    test rax, rax
    js .error

    
    mov rax, 0          
    mov rdi, [sock_fd]
    lea rsi, [buffer]
    mov rdx, 255
    syscall
    
    
    mov rdx, rax        
    mov rax, 1          
    mov rdi, 1          
    lea rsi, [buffer]
    syscall

    
.main_loop:
    
    mov rax, 0          
    mov rdi, 0          
    lea rsi, [buffer]
    mov rdx, 20         
    syscall
    
    test rax, rax
    jle .error          

    mov [len], rax      

    
    cmp byte [buffer], 'q'
    je .send_quit

    
    mov rax, 1          
    mov rdi, [sock_fd]
    lea rsi, [buffer]
    mov rdx, [len]      
    syscall

    jmp .main_loop

.send_quit:
    
    
    mov rax, 1
    mov rdi, [sock_fd]
    lea rsi, [buffer]   
    mov rdx, [len]
    syscall

    
    
    
    mov rax, 1
    mov rdi, 1
    lea rsi, [result_msg]
    mov rdx, 21
    syscall

    
    mov rax, 0          
    mov rdi, [sock_fd]
    lea rsi, [buffer]
    mov rdx, 255
    syscall
    
    
    cmp rax, 0
    jle .close
    
    mov rdx, rax        
    mov rax, 1          
    mov rdi, 1          
    lea rsi, [buffer]
    syscall
    
    
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

.close:
    
    mov rax, 3          
    mov rdi, [sock_fd]
    syscall

    xor rdi, rdi        
    call exit

.error:
    mov rdi, 1         
    call exit
