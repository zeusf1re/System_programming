format ELF64
public InitHeap
public PushBack
public PopHead
public FillRand

; Переименованная структура, чтобы избежать конфликта с FASM
S_Queue.head equ 0
S_Queue.tail equ 8

section '.data' readable
	urandomPath db '/dev/urandom', 0

section '.bss' writable
	p_heapStart resq 1
	p_heap resq 1

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
    pushaq
    
    mov r13, rdi

    mov  rax, 2
    mov  rdi, urandomPath
    xor  rsi, rsi
    syscall
    mov  r12, rax

    mov  rbx, [r13 + S_Queue.head] 

    .loop:
        cmp  rbx, 0
        je   .end_loop

        mov  rax, 0
        mov  rdi, r12
        mov  rsi, rbx
        mov  rdx, 8
        syscall        

        mov  rbx, [rbx + 8]
        jmp  .loop

    .end_loop:
        mov  rax, 3
        mov  rdi, r12
        syscall

        popaq
        ret
