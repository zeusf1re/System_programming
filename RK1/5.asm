format ELF64 
public _start
public exit

section '.data' writeable
    dirFd       dq 0
    bytesRead   dq 0
    dirBuffer   rb 4096
    pathBuffer  rb 256
    dirNameBuf  rb 256

section '.text' executable
_start:
    cmp qword [rsp], 2
    jne exitError

    mov rdi, dirNameBuf
    mov rsi, [rsp+16]
    call strcpy

    mov rax, 2
    mov rdi, dirNameBuf
    mov rsi, 0x10000
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl exitError
    mov [dirFd], rax

    mov rax, 217
    mov rdi, [dirFd]
    mov rsi, dirBuffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .cleanup
    mov [bytesRead], rax

    mov rbx, dirBuffer
    mov rcx, 3

.mainLoop:
    cmp rcx, 0
    je .cleanup

    mov rax, rbx
    sub rax, dirBuffer
    cmp rax, [bytesRead]
    jge .cleanup

    cmp byte [rbx+18], 8
    jne .nextEntry

    call buildFullPath

    rdrand rdx
    and rdx, 777o

    mov rax, 90
    mov rdi, pathBuffer
    mov rsi, rdx
    syscall

    dec rcx

.nextEntry:
    movzx rdx, word [rbx+16]
    add rbx, rdx
    jmp .mainLoop

.cleanup:
    mov rax, 3
    mov rdi, [dirFd]
    syscall
    call exit

buildFullPath:
    mov rdi, pathBuffer
    mov rsi, dirNameBuf
.copyDir:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .copyDir
    dec rdi

    mov byte [rdi], '/'
    inc rdi

    mov rsi, rbx
    add rsi, 19
.copyFile:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .copyFile
    ret

strcpy:
.loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .loop
    ret

exitError:
    mov rax, 60
    mov rdi, 1
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
