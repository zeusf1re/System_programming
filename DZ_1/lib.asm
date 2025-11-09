format elf64

public InitHeap
public PushBack
public PopHead
public FillRand
public PrintOdd
public CountEven

; Переименованная структура, чтобы избежать конфликта с FASM
S_Queue.head equ 0
S_Queue.tail equ 8

section '.data' writable
	urandomPath db '/dev/urandom', 0

section '.bss' writable
	p_heapStart rq 1
	p_heap rq 1

section '.text' executable

; IN: rdi = указатель на начало арены, rsi = размер арены
InitHeap:
    mov [p_heap], rdi
    mov [p_heapStart], rdi
    ret

; rdi - S_Queue*
; rsi - int
PushBack:
    push rbx
    push rax

    mov rbx, [p_heap]
    add qword [p_heap], 16

    mov [rbx], rsi
    mov qword [rbx + 8], 0

    cmp qword [rdi + S_Queue.head], 0
    je .noHead

    jmp .fullQueue

    .noHead:
        mov [rdi + S_Queue.head], rbx
        mov [rdi + S_Queue.tail], rbx
        jmp .end
    
    .fullQueue:
        mov rax, [rdi + S_Queue.tail]
        mov [rax + 8], rbx
        mov [rdi + S_Queue.tail], rbx

    .end:
        pop rax
        pop rbx
        ret

; rdi - S_Queue*
PopHead:
    push rbx
    push r12

    mov  rbx, [rdi + S_Queue.head]
    cmp  rbx, 0
    je   .pop_empty

    mov  rax, [rbx]

    mov  r12, [rbx + 8]
    mov  [rdi + S_Queue.head], r12

    cmp  r12, 0
    jne  .pop_done

    mov  qword [rdi + S_Queue.tail], 0
    jmp  .pop_done

    .pop_empty:
        mov  rax, -1

    .pop_done:
        pop  r12
        pop  rbx
        ret

; rdi - S_Queue*
FillRand:
    ; --- Сохраняем только те "callee-saved" регистры, которые мы используем ---
    push rbx
    push r12
    push r13

    ; Сохраняем указатель на очередь в r13
    mov r13, rdi

    ; Открываем файл
    mov  rax, 2
    mov  rdi, urandomPath
    xor  rsi, rsi
    syscall
    mov  r12, rax ; fd в r12

    ; Начинаем итерацию
    mov  rbx, [r13 + S_Queue.head]

.loop:
    cmp  rbx, 0
    je   .end_loop

    ; Читаем в узел
    mov  rax, 0
    mov  rdi, r12   ; Перезаписываем "расходный" rdi, это нормально
    mov  rsi, rbx
    mov  rdx, 8
    syscall

    ; Переходим к следующему узлу
    mov  rbx, [rbx + 8]
    jmp  .loop

.end_loop:
    ; Закрываем файл
    mov  rax, 3
    mov  rdi, r12
    syscall

    ; --- Восстанавливаем регистры в обратном порядке ---
    pop r13
    pop r12
    pop rbx
    ret

;rdi = Queue*
CountEven:
    push rbx
    push r10
    xor rax, rax
    mov rbx, [rdi] ; node* (head)

    .loop:
        cmp rbx, 0
        je .end

        mov r10, [rbx] ; r10 int (value) 
        test r10, 1
        jnz .loop_inc
        inc rax

    .loop_inc:
        mov rbx, [rbx + 8] ; rbx node* (tail)
        jmp .loop

    .end:
        pop r10
        pop rbx
        ret


; rdi = Queue*
PrintOdd:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    ; Выделяем буфер на 32 байта.
    sub rsp, 32

    mov rbx, [rdi] ; rbx = q->head

.mailLoop:
    test rbx, rbx
    jz .end
    
    mov r10, [rbx] ; r10 = current_node->value 
    test r10, 1
    jz .mainLoop_inc  ; Пропускаем четные

    ;print
    mov rax, r10
    mov r11, 10
    xor r12, r12      ; r12  счетчик символов

    .divLoop:
        xor rdx, rdx
        div r11 
        add rdx, '0'
        push rdx      
        inc r12
        test rax, rax
        jnz .divLoop

    lea r13, [rbp - 64] ; 64 потом что сохранили 4 регистра пушами(каждый по 8) а потом выделили еще 32
    
    mov r14, r12      ; сохраням r12 - counter

    .popLoop:
        pop rax       
        mov [r13], al 
        inc r13
        dec r12
        jnz .popLoop
        
    mov byte [r13], 10 ;\n
    inc r14

    mov rax, 1
    mov rdi, 1
    lea rsi, [rbp - 64]  ; lea в целом как move, только не вычисляет значение, то есть юзает только адресса
    mov rdx, r14       
    syscall
    
    jmp .mainLoop_inc

.mainLoop_inc:
    mov rbx, [rbx + 8] ; current_node = current_node->next
    jmp .mailLoop

.end:
    add rsp, 32      
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret


