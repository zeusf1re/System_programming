format ELF64 executable ; не создаст .o
entry _start        


macro safeExit {
    mov rax, 60                 ; sys_exit — системный вызов выхода из программы
    xor rdi, rdi      
    syscall          
}


macro exitWithError _code {
    mov rax, 60                 ; sys_exit
    mov rdi, _code  
    syscall
}


macro clearScreen {
    mov rax, 1  
    mov rdi, 1 
    mov rsi, clearSeq 
    mov rdx, 7                  ; Длина последовательности "\033[2J\033[H"
    syscall
}


macro newLine {
    mov rax, 1 
    mov rdi, 1
    mov rsi, newline 
    mov rdx, 1
    syscall
}

macro cout _data, _length {
    mov rax, 1      
    mov rdi, 1     
    mov rsi, _data
    mov rdx, _length 
    syscall
}

macro cin _buffer, _length {
    mov rax, 0      
    mov rdi, 0     
    mov rsi, _buffer 
    mov rdx, _length  
    syscall
}

macro cerr _data, _length {
    mov rax, 1       
    mov rdi, 2      
    mov rsi, _data  
    mov rdx, _length 
    syscall
}

macro clearBuffer _name, _size {
    push rdi        
    push rcx
    
    mov rdi, _name  
    mov rcx, _size 
    xor eax, eax  
    rep stosb   ; al = 0 
    
    pop rcx     
    pop rdi
}


macro charToInt _buffer {
    local .loop, .end, .errNotNumber

    push rsi
    push rax
    xor rbx, rbx

    mov rsi, _buffer

    mov al, [rsi]
    cmp al, '0'
    jl .errNotNumber
    cmp al, '9'
    jg .errNotNumber

    .loop:
        mov al, [rsi]
        cmp al, 0
        je .end

        cmp al, '0'
        jl .errNotNumber
        cmp al, '9'
        jg .errNotNumber

        sub al, '0'
        imul rbx, rbx, 10
        movzx rax, al
        add rbx, rax

        inc rsi
        jmp .loop

    .errNotNumber:
        cerr t_notNumber, t_notNumberLen
        exitWithError 3

    .end:
        pop rax
        pop rsi
}

macro copyString _dBuffer { ; from esi     ! \0  !
    local ..loop
    push rdi
    push rsi

    mov rdi, _dBuffer  

    ..loop:
        mov al, [rsi]
        mov [rdi], al
        inc rsi
        inc rdi
        test al, al; тип cmp 0, но быстрее
        jnz ..loop 

        pop rsi
        pop rdi
}

segment readable writable
    clearSeq db 27, '[', '2', 'J', 27, '[', 'H' ;  clear screen code (ANSI), и кстати курсор перемещает в начало
    newline db 10 

	t_entry:
		db "Enter your positive number: ", 0
	t_entryEnd:
		t_entryLen equ t_entryEnd - t_entry

    t_fewArgs:
        db "You gave too few args, 3 needed", 10, 0
    t_fewArgsEnd:
        t_fewArgsLen equ t_fewArgsEnd - t_fewArgs
    


segment readable writeable
    b_in rb 256
    b_out rb 256
    b_sourceFileName rb 256
    b_destFileName rb 256 
    b_buffer rb 4096
    m_sourceFD dq 0
    m_destFD dq 0


segment readable executable
    _start:
        mov rcx, [rsp]
        cmp rcx, 5
        jne .ErrFewArgs

        mov rsi, [rsp + 16]
        copyString b_sourceFileName

        mov rsi, [rsp + 24]
        copyString b_destFileName

        mov rax, 2 ; open for r
        mov rdi, b_sourceFileName
        mov rsi, 0
        mov rdx, 0
        syscall
        mov [m_sourceFD], rax ; в rax возвр. файловый дескриптор

        mov rax, 2 ; open for w
        mov rdi, b_destFileName
        mov rsi, 577  ; O_WRONLY | O_CREAT | O_TRUNC(стирает если чтот было)
        mov rdx, 0644 ; права 644
        syscall
        mov [m_destFD], rax

    .loop:
        mov rax, 0 ;  read
        mov rdi, [m_sourceFD]
        mov rsi, b_buffer
        mov rdx, 4096 ; дефолт размер страницы в linux >.<
        syscall
        mov rdi, rax ; сколько байт прочитали
        cmp rax, 0
        je .end

        mov rax, 1 ; write
        mov rdi, [m_destFD]
        mov rsi, b_buffer
        mov rdx, rdi          ; сюда нужно передать число байт, прочитанных
        syscall
        jmp .loop

    .end:
        mov rax, 3; close
        mov rdi, [m_sourceFD]
        syscall
        mov rax, 3
        mov rdi, [m_destFD]
        syscall
        safeExit

    .ErrFewArgs:
        cerr t_fewArgs, t_fewArgsLen
        exitWithError 1
