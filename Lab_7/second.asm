; 652 числа в массиве

format ELF64

public _start
extrn std_print_int
extrn std_print_string

macro newline {
    mov rax, 1
    mov rdi, 1
    mov rsi, t_newline
    mov rdx, 1
    syscall
}

section '.data' writeable
    urandom_path db "/dev/urandom", 0
    m_seed dq 0
    
    ; Константы LCG
    LCG_A dq 6364136223846793005
    LCG_C dq 1442695040888963407
    LIMIT dq 100000000 

    t_first:
        db "First task(0.75 квантиль): ", 0 
    t_second:
        db "Second task(пятое после мин.): ", 0
    t_third:
        db "Third task(наиболее частая цифра): ", 0 
    t_fourth:
        db "Fourth task(наиболее редкая цифра): ", 0
    t_newline:
        db 10

section '.bss' writeable
    array_ptr rq 1
    stack1_top rq 1
    stack2_top rq 1
    stack3_top rq 1
    stack4_top rq 1

section '.text' executable

_start:
    
    mov rax, 2          
    mov rdi, urandom_path
    mov rsi, 0          
    syscall
    
    mov rbx, rax        

    
    mov rax, 0          
    mov rdi, rbx        
    mov rsi, m_seed       
    mov rdx, 8          
    syscall

    
    mov rax, 3          
    mov rdi, rbx
    syscall

    mov rax, 12         
    mov rdi, 0          
    syscall
    
    
    mov [array_ptr], rax ; Сохраняем, это будет начало нашего массива

    prepare_memory:
        mov rax, 12
        mov rdi, 0
        syscall
        mov [array_ptr], rax
        
        ; RDI = array_ptr
        mov rdi, rax
        
        ; Основной массив (5216)
        add rdi, 5216
        
        ; Стек 1 (16 КБ). Стек растет ВНИЗ, поэтому clone нужно давать КОНЕЦ области.
        add rdi, 16384
        mov [stack1_top], rdi  ; Это вершина стека 1
        
        ; Стек 2 (16 КБ)
        add rdi, 4096
        mov [stack2_top], rdi
        
        ; Стек 3 (4 КБ)
        add rdi, 4096
        mov [stack3_top], rdi
        
        ; Стек 4 (4 КБ)
        add rdi, 4096
        mov [stack4_top], rdi
        
        
        mov rax, 12         ; sys_brk
        syscall

    fill_array:
        mov rdi, [array_ptr]
        
        ; Вычисляем конец массива
        mov rcx, rdi
        add rcx, 5216       
        
    .loop:
        cmp rdi, rcx        ; Текущий ptr >= Конец ptr?
        jge init_threads

        call get_random_number
        mov qword [rdi], rax
        add rdi, 8
        jmp .loop

    init_threads:
        mov rdi, 0xF11      ; Flags: CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|SIGCHLD
                            ; (0x100 | 0x200 | 0x400 | 0x800 | 17)
        mov rsi, [stack1_top] 
        mov rax, 56         ; sys_clone
        syscall
        
        cmp rax, 0
        je first_task  
        
        
        

        
        mov rdi, 0xF11
        mov rsi, [stack2_top]
        mov rax, 56
        syscall
        
        cmp rax, 0
        je secondTask      

        
        mov rdi, 0xF11
        mov rsi, [stack3_top]
        mov rax, 56
        syscall
        
        cmp rax, 0
        je third_task

        
        mov rdi, 0xF11
        mov rsi, [stack4_top]
        mov rax, 56
        syscall
        
        cmp rax, 0
        je fourth_task

        
        ; Ждем завершения всех 4 детей
        mov rcx, 4
    .wait_loop:
        push rcx
        mov rdi, -1     ; Ждать любого ребенка
        mov rsi, 0
        mov rdx, 0
        mov r10, 0
        mov rax, 61     ; sys_wait4
        syscall
        pop rcx
        loop .wait_loop

        
        mov rax, 60
        xor rdi, rdi
        syscall

    
    
    

first_task:
    sub rsp, 5216
    mov rdi, rsp
    mov rsi, [array_ptr]
    mov rcx, 652
    rep movsq
    
    mov rdi, rsp
    mov rsi, 652
    call bubble_sort 
    
    mov rax, [rsp + 489*8] 
    
    push rax               
    
    mov rdi, t_first
    call std_print_string
    
    pop rdi                
    call std_print_int
    newline

    mov rax, 60
    syscall

secondTask:
    mov rcx, [array_ptr]       
    
    mov rdx, rcx
    add rdx, 652*8  
    
    mov r8, 0x7FFFFFFFFFFFFFFF 
                               
    mov rsi, rcx               
        
    .loop:
        cmp rcx, rdx        
        jge .search_done
        
        mov rax, [rcx]     
        cmp rax, r8
        jge .next         
        
        mov r8, rax      
        mov rsi, rcx    
        
        .next:
            add rcx, 8
            jmp .loop

    .search_done:
        
        ; Нам нужно (min_ptr + 5*8).
        
        add rsi, 40                
        
        mov rdi, t_second
        call std_print_string
        
        
        mov rdi, [rsi]
        call std_print_int

        newline
        mov rax, 60
        syscall


third_task:
    push rbp
    mov rbp, rsp

    ;  Выделяем память под 10 счетчиков (80 байт)
    sub rsp, 80
    
    ; Зануляем счетчики
    mov rdi, rsp
    xor rax, rax
    mov rcx, 10
    rep stosq
    
    
    mov rsi, rsp 

    
    mov rcx, [array_ptr]       
    mov r15, rcx               ; R15 = Конец массива
    add r15, 5216              ; 652 * 8
    
    mov rbx, 10                

.big_loop:
    cmp rcx, r15               
    jge .calc_max              
    
    mov rax, [rcx]             
    
    
    test rax, rax
    jnz .div_loop_start
    
    inc qword [rsi]
    jmp .next_number

.div_loop_start:
    
    .div_loop:
        test rax, rax          
        jz .next_number
        
        xor rdx, rdx
        div rbx                
        
        
        inc qword [rsi + rdx*8]
        
        jmp .div_loop

.next_number:
    add rcx, 8
    jmp .big_loop

.calc_max:
    
    ; RSI = массив, RCX = индекс (0..9)
    xor rcx, rcx
    xor rax, rax        ; Текущий макс count
    mov rdi, -1         ; Индекс макс цифры (результат)
    
.max_loop:
    cmp rcx, 10         
    jge .print_result
    
    mov r8, [rsi + rcx*8] ; Загружаем count[i]
    
    cmp r8, rax
    jle .skip_update    
    
    
    mov rax, r8         
    mov rdi, rcx        
    
.skip_update:
    inc rcx
    jmp .max_loop

.print_result:
    
    push rdi
    mov rdi, t_third
    call std_print_string
    pop rdi
    call std_print_int
    newline

    mov rax, 60
    syscall




fourth_task:
    push rbp
    mov rbp, rsp

    sub rsp, 80
    
    mov rdi, rsp
    xor rax, rax
    mov rcx, 10
    rep stosq
    
    mov rsi, rsp 

    mov rcx, [array_ptr]
    mov r15, rcx
    add r15, 5216
    
    mov rbx, 10

.big_loop:
    cmp rcx, r15
    jge .calc_min
    
    mov rax, [rcx]
    
    test rax, rax
    jnz .div_loop_start
    inc qword [rsi]
    jmp .next_number

.div_loop_start:
    .div_loop:
        test rax, rax
        jz .next_number
        
        xor rdx, rdx
        div rbx
        
        inc qword [rsi + rdx*8]
        
        jmp .div_loop

.next_number:
    add rcx, 8
    jmp .big_loop

.calc_min:
    xor rcx, rcx
    mov rax, 0x7FFFFFFFFFFFFFFF 
    mov rdi, -1
    
.min_loop:
    cmp rcx, 10
    jge .print_result
    
    mov r8, [rsi + rcx*8]
    
    cmp r8, rax
    jge .skip_update
    
    mov rax, r8
    mov rdi, rcx
    
.skip_update:
    inc rcx
    jmp .min_loop

.print_result:
    push rdi             
    
    mov rdi, t_fourth    
    call std_print_string
    
    pop rdi              
    call std_print_int
    newline

    mov rax, 60
    syscall
;return rax - randomint
get_random_number:
    push rdx
    push rbx

    mov rax, [m_seed]
    mov rbx, [LCG_A]
    mul rbx         
    
    add rax, [LCG_C] 
    mov [m_seed], rax

    
    xor rdx, rdx        
    div qword [LIMIT] 
    
    mov rax, rdx    

    pop rbx
    pop rdx
    ret

;rdi - array, rsi - count
bubble_sort:
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
            mov rax, qword [rdi + r9 * 8]; arr[j - 1]
            inc r9
            mov rbx, qword [rdi + r9 * 8] ; arr[j]

            cmp rax, rbx
            jle .small_inc

            dec r9
            mov qword [rdi + r9 * 8], rbx; arr[j - 1]
            inc r9
            mov qword [rdi + r9 * 8], rax ; arr[j]
            
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
