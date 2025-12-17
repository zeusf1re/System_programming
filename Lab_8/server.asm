format ELF64
extrn std_print_string

public _start

section '.data' writable
    msg_wait_1      db 0, "Waiting for Player 1 (X)...", 10, 0
    msg_wait_2      db 0, "Waiting for Player 2 (O)...", 10, 0
    msg_p1_join     db 0, "Player 1 connected! Waiting for Player 2...", 10, 0
    msg_start       db 0, "Both players connected! Game starts!", 10, 0
    
    ; Сообщения для отправки клиентам
    net_msg_wait    db 0, "Waiting for opponent...", 10, 0
    net_msg_your_turn db 1, "Your turn (0-8): ", 0
    net_msg_win     db 0, "You WIN!", 0
    net_msg_lose    db 0, "You LOSE!", 0
    net_msg_draw    db 0, "Draw!", 0
    
    server_addr:
        dw 2
        db 0x1F, 0x90 ; 8080
        dd 0             ; 0.0.0.0
        dq 0

section '.bss' writable
    server_sock     rq 1
    sock_p1         rq 1  ; Сокет игрока 1 (X)
    sock_p2         rq 1  ; Сокет игрока 2 (O)
    
    board           rb 9
    buffer          rb 256
    
    current_turn    db 0  ; 0 = ход X, 1 = ход O

section '.text' executable
_start:
    ; === 1. Инициализация сети ===
    ; socket()
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    mov [server_sock], rax
    
    ; bind()
    mov rax, 49
    mov rdi, [server_sock]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    
    ; listen()
    mov rax, 50
    mov rdi, [server_sock]
    mov rsi, 2          ; Очередь на 2 человека
    syscall

    ; === 2. Подключение Игрока 1 ===
    mov rdi, msg_wait_1
	inc rdi
    call std_print_string
    
    mov rax, 43         ; accept
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [sock_p1], rax  ; Сохранили X

    ; === 3. Подключение Игрока 2 ===
    mov rdi, msg_wait_2
    inc rdi
    call std_print_string
    
    mov rax, 43         ; accept
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [sock_p2], rax  ; Сохранили O

    mov rdi, msg_start

    inc rdi
    call std_print_string
    

;game_loop:
;	send(0, board)
;	get_msg("k")
;	send(0/1, turn)
;	get_msg("k")
;	get_turn("0-8") ; у того, у кого ход
;
;	jmp game_loop

game_loop:
    call create_map     
    push rax
    mov rdx, rax ; len
	;================SEND_MAP==================
    mov rax, 1
    mov rdi, [sock_p1]
    mov rsi, buffer
    syscall
    

    mov rax, 1
    mov rdi, [sock_p2]
    mov rsi, buffer
    pop rdx
    syscall


    ;===================ASK==================
    mov rax, 0 
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall

    mov rax, 0 
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall 
    
    call check_win

    cmp rax, 1 
    je win_p1

    cmp rax, 2 
    je win_p2
    

    cmp byte [current_turn], 0
    je turn_player_1
    jmp turn_player_2

turn_player_1:
	;===================SEND_TURN==================
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_wait]
    mov rdx, 22 ; длина
    syscall
    

    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_your_turn]
    mov rdx, 18
    syscall

    ;===================ASK==================
    mov rax, 0 
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall

    mov rax, 0 
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall 
    
	;==================GET_ANS==================
    mov rax, 0
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 10
    syscall
    

    mov al, [buffer]
    sub al, '0'
    mov byte [board + rax], 1 
    
    mov byte [current_turn], 1
    jmp game_loop

turn_player_2:

	;===================SEND_TURN==================
    mov rax,  1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_wait]
    mov rdx, 22 ; длина
    syscall
    

    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_your_turn]
    mov rdx, 18
    syscall

    ;===================ASK==================
    mov rax, 0 
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall

    mov rax, 0 
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall 
	
	;==================GET_ANS==================
    mov rax, 0
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 10
    syscall
    
    mov al, [buffer]
    sub al, '0'
    mov byte [board + rax], 2 
    
    mov byte [current_turn], 0
    jmp game_loop



win_p1:

    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_win]
    mov rdx, 9 
    syscall

    
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_lose]
    mov rdx, 10         
    syscall
    
    jmp game_over       

win_p2:
    
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_lose]
    mov rdx, 10
    syscall

    
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_win]
    mov rdx, 9
    syscall
    
    jmp game_over

draw:
    
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_draw]
    mov rdx, 6
    syscall

    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_draw]
    mov rdx, 6
    syscall
    
    jmp game_over
game_over:
    
    mov rax, 3          ; sys_close
    mov rdi, [sock_p1]
    syscall

    mov rax, 3          ; sys_close
    mov rdi, [sock_p2]
    syscall

    ; Закрываем серверный сокет
    mov rax, 3          ; sys_close
    mov rdi, [server_sock]
    syscall

    ; Выход из программы
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; code 0
    syscall

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

        ;хахахах, ну я решил так сделать, потому что быстрее чем цикл, меньше inc и нет cmp, то есть pipeline не сможет ошибиться
        mov rax, 0x2D2D2D2D2D2D2D2D ; 8 тире
        mov qword [buffer + rbx], rax
        add rbx, 8

        mov eax, 0x2D2D2D2D         ; 4 тире
        mov dword [buffer + rbx], eax
        add rbx, 4

        mov byte [buffer + rbx], 0x2D ; 1 тире
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
            add r8, rdx ; index ячейки поля
            movzx rax, byte [board + r8] ; movzx расширяет нулями
            cmp rax, 0
            jne .not_empty

            mov byte [buffer + rbx], ' '
            inc rbx
            jmp .small_inc

            .not_empty:
            cmp rax, 1
            jne .X

            mov byte [buffer + rbx], 'O'
            inc rbx
            jmp .small_inc

            .X:
            mov byte [buffer + rbx], 'X'
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

        mov rax, 0x2D2D2D2D2D2D2D2D ; 8 тире
        mov qword [buffer + rbx], rax
        add rbx, 8

        mov eax, 0x2D2D2D2D         ; 4 тире
        mov dword [buffer + rbx], eax
        add rbx, 4

        mov byte [buffer + rbx], 0x2D ; 1 тире
        inc rbx

        mov byte [buffer + rbx], 10 
        inc rbx

        mov byte [buffer + rbx], 0
        inc rbx
        mov rax, rbx ; ret

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
    ; Строка 1 (индексы 0, 1, 2)
    mov al, [board + 0]
    cmp al, 0           ; Если пустая клетка, линию не проверяем
    je .check_row2
    cmp al, [board + 1] ; Сравниваем 0 и 1
    jne .check_row2
    cmp al, [board + 2] ; Сравниваем 0 и 2
    je .win_found       ; Если 0==1 и 0==2, то победа того, кто в al

.check_row2:
    ; Строка 2 (индексы 3, 4, 5)
    mov al, [board + 3]
    cmp al, 0
    je .check_row3
    cmp al, [board + 4]
    jne .check_row3
    cmp al, [board + 5]
    je .win_found

.check_row3:
    ; Строка 3 (индексы 6, 7, 8)
    mov al, [board + 6]
    cmp al, 0
    je .check_cols
    cmp al, [board + 7]
    jne .check_cols
    cmp al, [board + 8]
    je .win_found

    ; --- ПРОВЕРКА СТОЛБЦОВ ---

.check_cols:
    ; Столбец 1 (0, 3, 6)
    mov al, [board + 0]
    cmp al, 0
    je .check_col2
    cmp al, [board + 3]
    jne .check_col2
    cmp al, [board + 6]
    je .win_found

.check_col2:
    ; Столбец 2 (1, 4, 7)
    mov al, [board + 1]
    cmp al, 0
    je .check_col3
    cmp al, [board + 4]
    jne .check_col3
    cmp al, [board + 7]
    je .win_found

.check_col3:
    ; Столбец 3 (2, 5, 8)
    mov al, [board + 2]
    cmp al, 0
    je .check_diagonals
    cmp al, [board + 5]
    jne .check_diagonals
    cmp al, [board + 8]
    je .win_found

    ; --- ПРОВЕРКА ДИАГОНАЛЕЙ ---

.check_diagonals:
    ; Главная диагональ (0, 4, 8)
    mov al, [board + 0]
    cmp al, 0
    je .check_diag2
    cmp al, [board + 4]
    jne .check_diag2
    cmp al, [board + 8]
    je .win_found

.check_diag2:
    ; Побочная диагональ (2, 4, 6)
    mov al, [board + 2]
    cmp al, 0
    je .no_win
    cmp al, [board + 4]
    jne .no_win
    cmp al, [board + 6]
    je .win_found

.no_win:
    xor rax, rax        ; Никто не победил (rax = 0)
    mov rsp, rbp
    pop rbp
    ret

.win_found:
    movzx rax, al       ; Возвращаем ID победителя (1 или 2)
    mov rsp, rbp
    pop rbp
    ret
    
