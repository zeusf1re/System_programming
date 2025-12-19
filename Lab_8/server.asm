format ELF64
extrn std_print_string
public _start

section '.data' writable
    msg_wait_1      db 0, "Waiting for Player 1 (X)...", 10, 0
    msg_wait_2      db 0, "Waiting for Player 2 (O)...", 10, 0
    msg_start       db 0, "Both players connected! Game starts!", 10, 0
    
    ; Байт 0=Wait, 1=Turn, 2=Game Over
    net_msg_wait    db 0, "Waiting for opponent...", 10, 0 
    net_msg_turn    db 1, "Your turn (0-8): ", 0        
    net_msg_win     db 2, "You WIN!", 10, 0
    net_msg_lose    db 2, "You LOSE!", 10, 0
    net_msg_draw    db 2, "Draw!", 10, 0    ; Сообщение о ничьей
    
    server_addr:
        dw 2
        db 0x1F, 0x90 
        dd 0          
        dq 0

section '.bss' writable
    server_sock     rq 1
    sock_p1         rq 1
    sock_p2         rq 1
    board           rb 9
    buffer          rb 256
    current_turn    db 0
    moves_cnt       db 0    ; <-- СЧЕТЧИК ХОДОВ

section '.text' executable
_start:
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

    ; === Подключение игроков ===
    mov rdi, msg_wait_1
    inc rdi
    call std_print_string
    
    mov rax, 43         ; accept P1
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [sock_p1], rax

    mov rdi, msg_wait_2
    inc rdi
    call std_print_string
    
    mov rax, 43         ; accept P2
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [sock_p2], rax

    mov rdi, msg_start
    inc rdi
    call std_print_string

game_loop:
    ; === 1. Рассылка карты ===
    call create_map   
    mov rdx, rax      
    
    mov rax, 1
    mov rdi, [sock_p1]
    mov rsi, buffer
    syscall
    
    mov rax, 1
    mov rdi, [sock_p2]
    mov rsi, buffer
    syscall

    call wait_ack_p1
    call wait_ack_p2

    ; === 2. Проверка итогов ===
    call check_win
    cmp rax, 1 
    je win_p1
    cmp rax, 2 
    je win_p2
    
    ; === ПРОВЕРКА НИЧЬЕЙ ===
    cmp byte [moves_cnt], 9
    je draw_game

    ; === 3. Ход ===
    cmp byte [current_turn], 0
    je turn_player_1
    jmp turn_player_2

turn_player_1:
    ; P2 ждет
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_wait]
    mov rdx, 24
    syscall

    ; P1 ходит
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_turn]
    mov rdx, 18
    syscall

    call wait_ack_p1
    call wait_ack_p2
    
    ; Читаем ход P1
    mov rax, 0
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 1         
    syscall

    mov al, [buffer]
    sub al, '0'
    
    cmp al, 8
    ja turn_player_1   
    
    movzx rbx, al
    cmp byte [board + rbx], 0
    jne turn_player_1  

    mov byte [board + rbx], 1 
    inc byte [moves_cnt]       ; <-- УВЕЛИЧИВАЕМ СЧЕТЧИК
    mov byte [current_turn], 1
    jmp game_loop

turn_player_2:
    ; P1 ждет
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_wait]
    mov rdx, 24
    syscall

    ; P2 ходит
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_turn]
    mov rdx, 18
    syscall

    call wait_ack_p1
    call wait_ack_p2
    
    ; Читаем ход P2
    mov rax, 0
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 1         
    syscall
    
    mov al, [buffer]
    sub al, '0'
    
    cmp al, 8
    ja turn_player_2
    
    movzx rbx, al
    cmp byte [board + rbx], 0
    jne turn_player_2

    mov byte [board + rbx], 2 
    inc byte [moves_cnt]       ; <-- УВЕЛИЧИВАЕМ СЧЕТЧИК
    mov byte [current_turn], 0
    jmp game_loop

; === Утилиты ===
wait_ack_p1:
    mov rax, 0 
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall
    ret

wait_ack_p2:
    mov rax, 0 
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall 
    ret

win_p1:
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_win]
    mov rdx, 10 
    syscall
    
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_lose]
    mov rdx, 11
    syscall
    jmp game_over       

win_p2:
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_lose]
    mov rdx, 11
    syscall
    
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_win]
    mov rdx, 10
    syscall
    jmp game_over

draw_game:              ; <-- ОБРАБОТЧИК НИЧЬЕЙ
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_draw]
    mov rdx, 8          
    syscall

    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_draw]
    mov rdx, 8
    syscall
    jmp game_over

game_over:
    mov rax, 60
    xor rdi, rdi
    syscall

; === Оставляем функции create_map и check_win без изменений ===
create_map:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push r8

    xor rcx, rcx
    mov byte [buffer], 0
    mov rbx, 1
    .big_loop:
        cmp rcx, 3
        jge .end 
        mov rax, 0x2D2D2D2D2D2D2D2D
        mov qword [buffer + rbx], rax
        add rbx, 8
        mov eax, 0x2D2D2D2D
        mov dword [buffer + rbx], eax
        add rbx, 4
        mov byte [buffer + rbx], 0x2D
        inc rbx
        mov byte [buffer + rbx], 10 
        inc rbx
        mov byte [buffer + rbx], '|' 
        inc rbx
        xor rdx, rdx
        .small_loop:
            cmp rdx, 3
            jge .big_inc
            mov byte [buffer + rbx], ' '
            inc rbx
            mov r8, rcx
            imul r8, 3
            add r8, rdx
            movzx rax, byte [board + r8]
            cmp rax, 0
            jne .not_empty
            mov byte [buffer + rbx], ' '
            inc rbx
            jmp .small_inc
            .not_empty:
            cmp rax, 1
            jne .X
            mov byte [buffer + rbx], 'X'
            inc rbx
            jmp .small_inc
            .X:
            mov byte [buffer + rbx], 'O'
            inc rbx
            .small_inc:
                mov byte [buffer + rbx], ' '
                inc rbx
                mov byte [buffer + rbx], '|'
                inc rbx
                inc rdx
                jmp .small_loop
    .big_inc:
        mov byte [buffer + rbx], 10
        inc rbx
        inc rcx
        jmp .big_loop
    .end:
        mov rax, 0x2D2D2D2D2D2D2D2D
        mov qword [buffer + rbx], rax
        add rbx, 8
        mov eax, 0x2D2D2D2D
        mov dword [buffer + rbx], eax
        add rbx, 4
        mov byte [buffer + rbx], 0x2D
        inc rbx
        mov byte [buffer + rbx], 10 
        inc rbx
        mov byte [buffer + rbx], 0
        inc rbx
        mov rax, rbx
        pop r8
        pop rdx
        pop rcx
        pop rbx
        mov rsp, rbp
        pop rbp
        ret

check_win:
    push rbp
    mov rbp, rsp
    mov al, [board + 0]
    cmp al, 0
    je .check_row2
    cmp al, [board + 1]
    jne .check_row2
    cmp al, [board + 2]
    je .win_found
.check_row2:
    mov al, [board + 3]
    cmp al, 0
    je .check_row3
    cmp al, [board + 4]
    jne .check_row3
    cmp al, [board + 5]
    je .win_found
.check_row3:
    mov al, [board + 6]
    cmp al, 0
    je .check_cols
    cmp al, [board + 7]
    jne .check_cols
    cmp al, [board + 8]
    je .win_found
.check_cols:
    mov al, [board + 0]
    cmp al, 0
    je .check_col2
    cmp al, [board + 3]
    jne .check_col2
    cmp al, [board + 6]
    je .win_found
.check_col2:
    mov al, [board + 1]
    cmp al, 0
    je .check_col3
    cmp al, [board + 4]
    jne .check_col3
    cmp al, [board + 7]
    je .win_found
.check_col3:
    mov al, [board + 2]
    cmp al, 0
    je .check_diagonals
    cmp al, [board + 5]
    jne .check_diagonals
    cmp al, [board + 8]
    je .win_found
.check_diagonals:
    mov al, [board + 0]
    cmp al, 0
    je .check_diag2
    cmp al, [board + 4]
    jne .check_diag2
    cmp al, [board + 8]
    je .win_found
.check_diag2:
    mov al, [board + 2]
    cmp al, 0
    je .no_win
    cmp al, [board + 4]
    jne .no_win
    cmp al, [board + 6]
    je .win_found
.no_win:
    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret
.win_found:
    movzx rax, al
    mov rsp, rbp
    pop rbp
    ret