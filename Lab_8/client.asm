format ELF64

extrn std_print_string
extrn std_read_line

public _start

section '.data' writable
    prompt_msg      db "Enter message to send to server: ", 0
    wait_msg        db "Connecting to localhost:8080...", 10, 0
    server_reply    db "Server replied: ", 0
    ask             db "K"
    msg_enter_ip db "Enter Server IP: ", 0
    
    ; (X.X.X.X:8080)
    server_addr:
        dw 2              ; AF_INET
        db 0x1F, 0x90     ; Port 8080
        db 127,0,0,1      ; 127.0.0.1 для локалки
        dq 0              ; padding

section '.bss' writable
    sock_fd         rq 1
    buffer          rb 256
    msg_len         rq 1
    ip_input rb 32  

section '.text' executable
_start:

    mov rdi, msg_enter_ip
    call std_print_string

    mov rax, 0          
    mov rdi, 0         
    lea rsi, [ip_input]
    mov rdx, 31
    syscall
    

    lea rsi, [ip_input] 
    lea rdi, [server_addr + 4] 
    call parse_ip

    mov rdi, wait_msg
    call std_print_string

    mov rax, 41           ; sys_socket
    mov rdi, 2            ; AF_INET
    mov rsi, 1            ; SOCK_STREAM
    mov rdx, 0
    syscall
    
    mov [sock_fd], rax

    mov rax, 42           ; sys_connect
    mov rdi, [sock_fd]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall


;    game_loop:
;        read_socket(buffer)
;        print(buffer)
;        write_socket("K")
;
;        if buffer contains "Your turn":
;           read_keyboard(input)
;           write_socket(input)
;
;        jmp loop

    game_loop:
        ;==============GET(0/1)===============
        mov rax, 0            
        mov rdi, [sock_fd]
        mov rsi, buffer
        mov rdx, 255
        syscall

        test rax, rax
        jz .server_disconnected
        
        ;print
        add rax, buffer
        mov byte [rax], 0
        mov rdi, buffer
        inc rdi
        call std_print_string

        ;==================SAY==================
        mov rax, 1 
        mov rdi, [sock_fd]
        lea rsi, [ask] 
        mov rdx, 1
        syscall

        ;===============IF(0 or 1)==============
        cmp byte [buffer], 0
        je game_loop

        ; 1 -> send
        mov rax, 0    
        mov rdi, 0     
        lea rsi, [buffer]
        mov rdx, 2      
        syscall
        

        mov rax, 1          
        mov rdi, [sock_fd] 
        lea rsi, [buffer] 
        mov rdx, 1       
        syscall
        jmp game_loop

    mov rax, 3
    mov rdi, [sock_fd]
    syscall

.server_disconnected:
    mov rdi, 0
    mov rax, 60
    syscall



;int parse_ip(char* buffer)         кстати она не фига не сишная))), тут нет сохранения stack frame и выравнивания по 16 байтной гранце

; rsi - адрес откуда берем массив чаров
; eax - res, причем в нем каждый байт это число, и уже в нотации big-endian
parse_ip:
    push rbx
    push rcx
    push rdx
    
    xor eax, eax    ; res
    xor ecx, ecx    ; current int
    xor rdx, rdx    ; counter bytes

    .next_char:
        mov bl, [rsi]
        inc rsi
        
        cmp bl, '.' 
        je .save_byte
        cmp bl, 10      ; Enter
        je .finish
        cmp bl, 0       ; eof or \0
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
        mov [rdi], cl ; Последний байт
        
        pop rdx
        pop rcx
        pop rbx
        ret

