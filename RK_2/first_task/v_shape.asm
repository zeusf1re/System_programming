format ELF64


extrn initscr
extrn endwin
extrn refresh
extrn move
extrn addch
extrn getch
extrn noecho
extrn curs_set
extrn napms

extrn start_color
extrn init_pair
extrn attron
extrn attroff
extrn getmaxy
extrn getmaxx
extrn stdscr

public _start

section '.data' writable
    delay_ms dq 50
    
    yMax     dq 0
    xMax     dq 0
    
    base_y   dq 0
    base_x   dq 0
    
    curr_y   dq 0
    curr_x   dq 0

    
    COLOR_BLUE  equ 4
    COLOR_WHITE equ 7
    PAIR_ID     equ 1

section '.text' executable

_start:
    
    call initscr
    call noecho
    mov rdi, 0
    call curs_set

    
    call start_color
    
    
    mov rdi, PAIR_ID
    mov rsi, COLOR_WHITE 
    mov rdx, COLOR_BLUE  
    call init_pair

    
    
    mov rdi, 0x100 
    call attron

    
    mov rdi, [stdscr]
    call getmaxy
    mov [yMax], rax

    mov rdi, [stdscr]
    call getmaxx
    mov [xMax], rax

    
    
    mov rax, [yMax]
    sub rax, 4
    mov [base_y], rax
    
    
    mov rax, [xMax]
    shr rax, 1
    mov [base_x], rax

    
    
    mov r12, [base_y]  
    mov r13, [base_x]  

.left_loop:
    
    cmp r12, 4
    jle .start_right
    cmp r13, 4
    jle .start_right

    
    mov rdi, r12
    mov rsi, r13
    call move

    
    mov rdi, ' '
    call addch

    call refresh

    
    mov rdi, [delay_ms]
    call napms

    
    dec r12
    dec r13
    jmp .left_loop

    
.start_right:
    
    mov r12, [base_y]
    mov r13, [base_x]
    
    
    dec r12
    inc r13

.right_loop:
    
    cmp r12, 4
    jle .finish

    
    mov rax, [xMax]
    sub rax, 4
    cmp r13, rax
    jge .finish

    
    mov rdi, r12
    mov rsi, r13
    call move

    
    mov rdi, ' '
    call addch

    call refresh

    mov rdi, [delay_ms]
    call napms

    
    dec r12
    inc r13
    jmp .right_loop

    
.finish:
    
    mov rdi, 0x100
    call attroff

    call getch
    call endwin
    
    
    mov rax, 60
    xor rdi, rdi
    syscall
