format ELF64 executable 3
entry _start

; --- Константы ---
SYS_READ    = 0
SYS_WRITE   = 1
SYS_OPEN    = 2
SYS_CLOSE   = 3
SYS_EXIT    = 60

O_RDONLY    = 0
O_WRONLY    = 1
O_CREAT     = 64
O_TRUNC     = 512
O_PERMS     = 420   ; 0644

BUF_SIZE    = 4096

segment readable executable

_start:
    ; Стек: [rsp]=argc, [rsp+8]=argv[0], [rsp+16]=argv[1]...
    mov     rcx, [rsp]
    cmp     rcx, 4
    jne     .usage

    mov     rbx, rsp          ; rbx = указатель на стек

    ; === Очистка памяти (карт символов) ===
    call    clear_maps

    ; === ФАЙЛ 1 ===
    mov     rdi, [rbx + 16]   ; argv[1]
    call    process_file1

    ; === ФАЙЛ 2 ===
    mov     rdi, [rbx + 24]   ; argv[2]
    call    process_file2

    ; === ЗАПИСЬ РЕЗУЛЬТАТА ===
    mov     rdi, [rbx + 32]   ; argv[3]
    call    write_result

    ; Выход (успех)
    xor     rdi, rdi
    call    exit_prog

.usage:
    ; Вывод "Usage..."
    mov     rax, SYS_WRITE
    mov     rdi, 1
    lea     rsi, [msg_usage]
    mov     rdx, msg_usage_len
    syscall
    
    mov     rdi, 1
    call    exit_prog

; --- Процедуры ---

process_file1:
    ; Открыть
    mov     rax, SYS_OPEN
    mov     rsi, O_RDONLY
    xor     rdx, rdx
    syscall
    test    rax, rax
    js      .err
    mov     r12, rax          ; fd

    ; Читать
    mov     rax, SYS_READ
    mov     rdi, r12
    lea     rsi, [buffer]
    mov     rdx, BUF_SIZE
    syscall
    test    rax, rax
    js      .err
    mov     r13, rax          ; bytes read

    ; Закрыть
    mov     rax, SYS_CLOSE
    mov     rdi, r12
    syscall

    ; Заполнить map1
    lea     rdi, [map1]
    mov     rsi, buffer
    mov     rcx, r13
    call    fill_map
    ret
.err:
    mov     rdi, 2
    call    exit_prog

process_file2:
    ; Открыть
    mov     rax, SYS_OPEN
    mov     rsi, O_RDONLY
    xor     rdx, rdx
    syscall
    test    rax, rax
    js      .err
    mov     r12, rax

    ; Читать
    mov     rax, SYS_READ
    mov     rdi, r12
    lea     rsi, [buffer]
    mov     rdx, BUF_SIZE
    syscall
    test    rax, rax
    js      .err
    mov     r13, rax

    ; Закрыть
    mov     rax, SYS_CLOSE
    mov     rdi, r12
    syscall

    ; Заполнить map2
    lea     rdi, [map2]
    mov     rsi, buffer
    mov     rcx, r13
    call    fill_map
    ret
.err:
    mov     rdi, 3
    call    exit_prog

write_result:
    ; Открыть на запись
    mov     rax, SYS_OPEN
    mov     rsi, O_WRONLY or O_CREAT or O_TRUNC
    mov     rdx, O_PERMS
    syscall
    test    rax, rax
    js      .err
    mov     r12, rax          ; fd

    ; Цикл по всем ASCII символам (0..255)
    xor     rcx, rcx          ; счетчик i
.loop:
    cmp     rcx, 256
    ge      .done

    ; Проверяем map1[i]
    lea     rbx, [map1]
    mov     al, [rbx + rcx]
    test    al, al
    jz      .next

    ; Проверяем map2[i]
    lea     rbx, [map2]
    mov     al, [rbx + rcx]
    test    al, al
    jz      .next

    ; Если есть в обоих -> пишем
    mov     [char_buf], cl    ; сохраняем символ в буфер

    ; SYSCALL WRITE (сохраняем rcx!)
    push    rcx
    
    mov     rax, SYS_WRITE
    mov     rdi, r12          ; fd
    lea     rsi, [char_buf]
    mov     rdx, 1
    syscall

    pop     rcx               ; восстанавливаем rcx

.next:
    inc     rcx
    jmp     .loop

.done:
    ; Закрыть
    mov     rax, SYS_CLOSE
    mov     rdi, r12
    syscall
    ret
.err:
    mov     rdi, 4
    call    exit_prog

; rdi = адрес карты, rsi = адрес буфера, rcx = длина
fill_map:
    xor     rax, rax          ; чистим rax целиком
.fm_loop:
    test    rcx, rcx
    jz      .fm_ret
    
    movzx   rax, byte [rsi]   ; берем байт, расширяем нулями
    mov     byte [rdi + rax], 1 ; отмечаем
    
    inc     rsi
    dec     rcx
    jmp     .fm_loop
.fm_ret:
    ret

clear_maps:
    mov     rcx, 256
    xor     al, al
    lea     rdi, [map1]
    rep     stosb             ; заполнить map1 нулями
    
    mov     rcx, 256
    lea     rdi, [map2]
    rep     stosb             ; заполнить map2 нулями
    ret

exit_prog:
    mov     rax, SYS_EXIT
    syscall

segment readable writeable
    msg_usage db "Usage: ./lab file1 file2 outfile", 10
    msg_usage_len = $ - msg_usage

    buffer    rb BUF_SIZE
    map1      rb 256
    map2      rb 256
    char_buf  rb 1
