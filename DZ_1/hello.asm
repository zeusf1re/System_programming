
    format ELF64 executable

    ; СНАЧАЛА СЕКЦИИ ДАННЫХ
    section '.data' readable writable
        msg db "Hello World!", 0x0a
        msg_len = $ - msg ; Используй "=", а не "equ", для длин это стандарт

    ; ПОТОМ СЕКЦИЯ КОДА
    section '.text' readable executable
        entry _start
        _start:
            mov rax, 1
            mov rdi, 1
            mov rsi, msg
            mov rdx, msg_len
            syscall

            mov rax, 60
            xor rdi, rdi
            syscall
