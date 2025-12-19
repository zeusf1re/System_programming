format ELF64
public _start

section '.data' writeable
    array_ptr       dq 0
    array_len       dq 0
    child1_pid      dq 0
    child2_pid      dq 0
    msg_usage       db 'Args: ./program <N>', 10, 0
    msg_array_label db 'Sorted array: ', 0
    msg_array_label0 db 'Unsorted array: ', 0
    msg_space       db ' ', 0
    newline         db 10, 0
    dev_urandom     db '/dev/urandom', 0


section '.bss' writable
    child1_stack    rb 8192
    child2_stack    rb 8192
    fmt_num_buf     rb 20

section '.text' executable

_start:
    mov rdi, [rsp]
    cmp rdi, 2
    jne show_usage

    mov rsi, [rsp+16]
    call atoi
    mov [array_len], rax

    ; --- Выделение памяти ---
    mov rdi, [array_len]
    shl rdi, 3          ; *8 
    mov rax, 9          ; SYS_MMAP
    mov rsi, rdi        ; length
    mov rdx, 3          ; PROT_READ | PROT_WRITE
    mov r10, 33         ; MAP_SHARED | MAP_ANONYMOUS (33 = 0x21)
    mov r8, -1
    mov r9, 0
    syscall

    test rax, rax
    js exit_error       ; Если ошибка (отрицательный результат)
    mov [array_ptr], rax

    ; --- Заполнение рандомом ---
    
    mov rax, 2          ; SYS_OPEN
    lea rdi, [dev_urandom] 
    mov rsi, 0          ; O_RDONLY
    syscall
    mov r8, rax         

    ; Читаем N*8 байт прямо в массив
    mov rax, 0          ; SYS_READ
    mov rdi, r8
    mov rsi, [array_ptr]
    mov rdx, [array_len]
    shl rdx, 3          ; *8 байт
    syscall

    
    mov rax, 3          ; SYS_CLOSE
    mov rdi, r8
    syscall
    
    ;нормализация
    mov rcx, [array_len]
    mov rbx, [array_ptr]
    .norm_loop:
        mov rax, [rbx]
        and rax, 0x7FFFFFFF ; Убираем знак
        xor rdx, rdx
        mov rdi, 100
        div rdi
        mov [rbx], rdx      
        add rbx, 8
        loop .norm_loop

    mov rsi, msg_array_label0
    call print_string
    mov rcx, [array_len]
    mov rbx, [array_ptr]
    .print_loop:
        mov rax, [rbx]
        call print_uint
        mov rsi, msg_space
        call print_string
        add rbx, 8
        loop .print_loop

        call print_newline


    ; Ребенок 1 (Четные)
    mov rax, 56         ; SYS_CLONE
    mov rdi, 0x100 or 17 ; CLONE_VM | SIGCHLD
    lea rsi, [child1_stack + 8192] ; Вершина стека
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall

    test rax, rax
    jz process_even     
    mov [child1_pid], rax

    ; Ребенок 2 (Нечетные)
    mov rax, 56
    mov rdi, 0x100 or 17
    lea rsi, [child2_stack + 8192]
    xor rdx, rdx
    xor r10, r10
    xor r8, r8
    syscall

    test rax, rax
    jz process_noteven
    mov [child2_pid], rax

    
    mov r12, 2
    .wait_loop:
        mov rax, 61
        mov rdi, -1
        mov rsi, 0
        mov rdx, 0
        mov r10, 0
        syscall

        dec r12
        jnz .wait_loop

        mov rsi, msg_array_label
        call print_string

        mov rcx, [array_len]
        mov rbx, [array_ptr]
    .print1_loop:
        mov rax, [rbx]
        call print_uint
        mov rsi, msg_space
        call print_string
        add rbx, 8
        loop .print1_loop

        call print_newline
        call exit

show_usage:
    mov rsi, msg_usage
    call print_string
    call exit_error

process_even:
    mov rbx, [array_ptr] 
    mov rcx, [array_len] 
    
    .outer_loop:
        mov r8, 0        ; четный
        mov r9, 0        ; n_swap
    .inner_loop:
        mov r10, r8
        add r10, 2       
        
        cmp r10, rcx    
        jge .check_swap
        
        ; arr[i] ? arr[j]
        mov rax, [rbx + r8*8]
        mov rdx, [rbx + r10*8]
        
        cmp rax, rdx
        jle .noswap
        
       
        mov [rbx + r8*8], rdx
        mov [rbx + r10*8], rax
        mov r9, 1        
        
    .noswap:
        add r8, 2 ; step = 2
        jmp .inner_loop
        
    .check_swap:
        cmp r9, 0        
        jne .outer_loop  
        
    call exit_thread

process_noteven:
    mov rbx, [array_ptr] 
    mov rcx, [array_len] 
    
    .outer_loop:
        mov r8, 1        ; нечетный
        mov r9, 0        ;n_swap = 0
    .inner_loop:
        mov r10, r8
        add r10, 2       
        
        cmp r10, rcx     
        jge .check_swap
        
        
        mov rax, [rbx + r8*8]
        mov rdx, [rbx + r10*8]
        
        cmp rax, rdx
        jle .noswap      
        
        
        mov [rbx + r8*8], rdx
        mov [rbx + r10*8], rax
        mov r9, 1        
        
    .noswap:
        add r8, 2        
        jmp .inner_loop
        
    .check_swap:
        cmp r9, 0        
        jne .outer_loop  
        
    call exit_thread
atoi:
    xor rax, rax

    .atoi_loop:
        movzx rdi, byte [rsi]
        inc rsi
        cmp rdi, '0'
        jb .atoi_done
        cmp rdi, '9'
        ja .atoi_done
        sub rdi, '0'
        imul rax, 10
        add rax, rdi
        jmp .atoi_loop
    .atoi_done:
        ret

print_string:
    push rdi
    push rax
    push rdx
    push rcx
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rax
    pop rdi
    ret

print_newline:
    mov rsi, newline
    call print_string
    ret

print_uint:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov rbx, 10
    mov rcx, fmt_num_buf
    add rcx, 19
    mov byte [rcx], 0

    .convert_loop:
        dec rcx
        xor rdx, rdx
        div rbx
        add dl, '0'
        mov [rcx], dl
        test rax, rax
        jnz .convert_loop
        mov rsi, rcx
        call print_string
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        ret

strlen:
    xor rax, rax

    .loop:
        cmp byte [rdi + rax], 0
        je .done
        inc rax
        jmp .loop
    .done:
        ret

exit_thread:
    mov rax, 60
    xor rdi, rdi
    syscall

exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
