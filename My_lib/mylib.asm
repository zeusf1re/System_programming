format ELF64

public std_print_string
public std_read_line
public std_print_int

section '.text' executable

; ==========================================================
; std_print_string
; Описание: Выводит null-terminated строку в stdout.
; Аргументы: 
;   RDI - адрес строки
; return:
;   rax - колво вписанных символов

; ssize_t write(int fd, const void *buf, size_t count);
; ==========================================================
std_print_string:
    ;prolog
    push rbp   
    mov rbp, rsp   
    
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    push rdi    
    push rsi    
    push rdx    
    push rcx    
    push r11    

    xor rcx, rcx
.len_loop:
    cmp byte [rdi + rcx], 0
    je .len_done
    inc rcx
    jmp .len_loop
.len_done:

    mov rdx, rcx
    mov rsi, rdi
    mov rdi, 1
    mov rax, 1
    syscall

    pop r11
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    ;epilog
    mov rsp, rbp 
    pop rbp     
    
    ret





; ==========================================================
; std_read_line
; Описание: Cчитывает строку из stdin
; Аргументы: 
;   RDI - адрес буффера
;   RSI - размер буффера
; return:
;   rax - колво счиатнных символов

;ssize_t read(int fd, void *buf, size_t count) with fd=0 (stdin).
; ==========================================================
std_read_line:
    push rbp
    mov rbp, rsp

    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

	mov rbx, rdi

    mov rax, 0     
    mov rdx, rsi   
    mov rsi, rdi   
    mov rdi, 0     
    syscall
    
    test rax, rax
    jz .read_error


	dec rax ;затираем \n
    mov [rbx + rax], byte 0
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx

    mov rsp, rbp
    pop rbp
    ret

    .read_error:

        pop r15
        pop r14
        pop r13
        pop r12
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx

        mov rax, 60
        mov rdi, 1  ; error code
        syscall
; TODO сделать вывод ошибки через стек


; ==========================================================
; std_print_int
; Описание: Выводит null-terminated строку с int в stdout.
; Аргументы: 
;   RDI - int64
; return:
;   rax - колво вписанных символов
; ==========================================================

std_print_int:
    push rbp
    mov rbp, rsp

    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    sub rsp, 32
    lea rsi, [rsp + 31]
    
    xor rcx, rcx

    test rdi, rdi
    jns .pos

    .neg:
        push rdi
        push '-' 

        mov rax, 1 
        mov rdi, 1 
        mov rsi, rsp   
        mov rdx, 1
        syscall       

        pop rax   
        pop rdi  
        neg rdi 

    .pos:
        mov r8, 10
        mov rax, rdi  


        .loop:
            xor rdx, rdx
            div r8       ; rax / 10

            add dl, '0'
            mov byte [rsi], dl

            inc rcx
            dec rsi
            
            test rax, rax
            jnz .loop

    .end:
        inc rsi        

        mov rax, 1    
        mov rdi, 1 
        mov rdx, rcx 

        syscall

    add rsp, 32

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx

    mov rsp, rbp
    pop rbp
    ret
