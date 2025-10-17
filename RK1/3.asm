format ELF64 executable
entry _start

segment readable writeable
    buf_out rb 32

segment readable executable

_start:
    mov rcx, [rsp]
    cmp rcx, 2
    jne .bad_argc

    mov rsi, [rsp+16]
    call my_atoi            ; n теперь в rax

    mov r12, rax            ; n -> 12
    mov rcx, 1              ; 
    xor rbx, rbx            ; res = 0

.loop:
    cmp rcx, r12
    jg .end

    mov rsi, rcx            
    call reverse           

    add rbx, rax          
    inc rcx
    jmp .loop

.end:
    mov rsi, rbx            ; rsi - res
    mov rdi, buf_out
    call int_to_str

    mov rax, 1
    mov rdi, 1
    mov rsi, buf_out
    mov rdx, 32
    syscall               

    mov rax, 60
    xor rdi, rdi
    syscall            

.bad_argc:
    mov rax, 60
    mov rdi, 1
    syscall          ; err code 1 

my_atoi:
    xor rax, rax
.atoi_loop:
    movzx rcx, byte [rsi]
    cmp cl, '0'
    jb .atoi_done
    cmp cl, '9'
    ja .atoi_done
    sub cl, '0'
    imul rax, rax, 10
    add rax, rcx
    inc rsi
    jmp .atoi_loop
.atoi_done:
    ret

reverse:
    push rbx
    push rcx
    push rdx
    
    mov rax, rsi
    xor rbx, rbx

.rev_loop:
    xor rdx, rdx
    mov rcx, 10
    div rcx
    
    imul rbx, rbx, 10
    add rbx, rdx
    
    test rax, rax
    jnz .rev_loop

    mov rax, rbx

    pop rdx
    pop rcx
    pop rbx
    ret

int_to_str:
    mov rax, rsi
    mov rcx, 10
    lea rdi, [rdi+31]
    mov byte [rdi], 10
    dec rdi
.its_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    test rax, rax
    jnz .its_loop
    inc rdi
    ret
