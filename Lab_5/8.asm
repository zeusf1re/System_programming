format ELF64
public _start

BUFFER_SIZE equ 4096

section '.text' executable

include 'func.asm'

_start:
    pop    rcx ; rcx - кол-во аргументов (вкл. имя программы)
    cmp    rcx, 4
    jne    .wrong_args

    pop    rdi
    pop    rdi ;кладём указатель на имя первого файла в rdi
    pop    rsi
    pop    rdx

    mov    [file1_name], rdi
    mov    [file2_name], rsi
    mov    [file3_name], rdx

    mov    rax, 2 ; open
    mov    rdi, [file1_name]
    mov    rsi, 0 ; only for r
    mov    rdx, 0
    syscall
    cmp    rax, 0
    jl     .open_error1

    mov    [fd1], rax

.read_loop1:
    mov    rax, 0
    mov    rdi, [fd1]
    mov    rsi, buffer
    mov    rdx, BUFFER_SIZE
    syscall
    cmp    rax, 0 ;в rax - количество прочитанных байт
    jle    .close1

    mov    rcx, rax
    mov    rsi, buffer
    xor    rbx, rbx
.populate_loop1:
    movzx  rdx, byte [rsi + rbx] ;в rdx находится ASCII-код символа
    mov    byte [presence1 + rdx], 1 ;записывает по этому адресу байт `1`
    inc    rbx
    dec    rcx
    jnz    .populate_loop1
    jmp    .read_loop1

.close1:
    mov    rax, 3 ;close
    mov    rdi, [fd1]
    syscall

    mov    rax, 2
    mov    rdi, [file2_name]
    mov    rsi, 0
    syscall
    cmp    rax, 0
    jl     .open_error2

    mov    [fd2], rax

.read_loop2:
    mov    rax, 0 ; 0 - read
    mov    rdi, [fd2]
    mov    rsi, buffer
    mov    rdx, BUFFER_SIZE
    syscall
    cmp    rax, 0
    jle    .close2

    mov    rcx, rax
    mov    rsi, buffer
    xor    rbx, rbx
.populate_loop2:
    movzx  rdx, byte [rsi + rbx]
    cmp    byte [presence1 + rdx], 1 ;проверяем: есть ли 1 по этому ascii-адресу?
    jne    .next_char_in_f2
    mov    byte [presence_common + rdx], 1
.next_char_in_f2:
    inc    rbx
    dec    rcx
    jnz    .populate_loop2
    jmp    .read_loop2

.close2:
    mov    rax, 3 ; 3 - close
    mov    rdi, [fd2]
    syscall


    mov    rdi, result_buffer
    xor    rcx, rcx
.build_result_loop:
    cmp    byte [presence_common + rcx], 1
    jne    .next_common_char
    mov    dl, cl
    mov    [rdi], dl
    inc    rdi
.next_common_char:
    inc    rcx
    cmp    rcx, 256
    jne    .build_result_loop

    mov    rax, rdi
    sub    rax, result_buffer
    mov    [result_len], rax
    cmp    rax, 0
    je     .exit_program






    mov    rax, 2 ; 2 - open
    mov    rdi, [file3_name]
    mov    rsi, 1 + 64 + 512 ;Флаги для открытия на запись: O_WRONLY (1, только запись) + O_CREAT (64, создать, если нет) + O_TRUNC (512, обрезать до нуля, если существует).
    mov    rdx, 0644o ;Права доступа для создаваемого файла в восьмеричном формате (rw-r--r--)
    syscall
    cmp    rax, 0;в rax находится файловый дескриптор (положительное число, идентификатор открытого файла)
    jl     .open_error3

    mov    [fd3], rax

    mov    rax, 1 ; 1 - write
    mov    rdi, [fd3]
    mov    rsi, result_buffer
    mov    rdx, [result_len]
    syscall

    mov    rax, 3 ; 3 -close
    mov    rdi, [fd3]
    syscall

    jmp    .exit_program

.wrong_args:
    mov    rsi, wrong_args_msg
    call   print_str
    mov    rdi, 1
    call   exit

.open_error1:
    mov    rsi, open_error_msg
    call   print_str
    mov    rdi, [file1_name]
    mov    rsi, rdi
    call   print_str
    call   new_line
    mov    rdi, 1 ; exit code — завершение с ошибкой
    call   exit

.open_error2:
    mov    rsi, open_error_msg
    call   print_str
    mov    rdi, [file2_name]
    mov    rsi, rdi
    call   print_str
    call   new_line
    mov    rdi, 1
    call   exit

.open_error3:
    mov    rsi, open_error_msg
    call   print_str
    mov    rdi, [file3_name]
    mov    rsi, rdi
    call   print_str
    call   new_line
    mov    rdi, 1; exit code — завершение с ошибкой
    call   exit

.exit_program:
    call   exit

section '.data' writeable

wrong_args_msg  db 'Использование: ./8 <файл1> <файл2> <файл3>', 0xA, 0
open_error_msg  db 'Ошибка: не удалось открыть файл: ', 0
file1_name      dq 0
file2_name      dq 0
file3_name      dq 0
fd1             dq 0
fd2             dq 0
fd3             dq 0
result_len      dq 0

section '.bss' writeable

buffer          rb BUFFER_SIZE
presence1       rb 256
presence_common rb 256
result_buffer   rb 256
