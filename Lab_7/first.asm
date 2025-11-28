format ELF64

extrn std_print_string
extrn std_read_line

public _start
; функции из моей библиотеки

section '.data' writable
	t_entry:
		db "Enter filename, which You want to execute(q - quit programm): ", 0
	t_entryEnd:
		t_entryLen equ t_entryEnd - t_entry

	t_readErr:
		db "Error while reading filename!", 10, 0
	t_readErrEnd:
		t_readErrLen equ t_readErrEnd - t_readErr

    t_test:
        db "debug test", 10, 0

section '.bss' writable
	b_filename rb 256
	m_filenameLen rq 1

	argv rq 16

    envp rq 1

section 'text' executable
	_start:
		mov rcx, [rsp]          ; argc
		lea rax, [rsp + 16]     ; Пропускаем argc и NULL терминатор argv (базовое смещение)
		lea rax, [rax + rcx*8]  ; Добавляем длину argv
        mov [envp], rax

		main_loop:
			
			mov rdi, t_entry
			call std_print_string 

			mov rdi, b_filename
			mov rsi, 255
			call std_read_line

			mov [m_filenameLen], rax

            mov rdi, b_filename
            call std_print_string
			
			
			mov al, byte [b_filename]
			cmp al, 'q'
			je exit_programm

			mov rax, 57
			syscall
			
			cmp rax, 0
			je child_process   ; Мы ребенок

			;мы родитель, ждем
			mov rdi, rax       ; PID ребенка
			mov rsi, 0         ; игнорим статус завершения
			mov rdx, 0         ; ждем и ниче не делаем
			mov r10, 0         ; rusage(статистика ненужна)
			mov rax, 61        ; sys_wait4
			syscall
			
			jmp main_loop      ; Повторяем цикл

		child_process:
			mov rax, b_filename
			mov [argv], rax    
			mov qword [argv+8], 0 

			mov rax, 59        ; sys_execve
			mov rdi, b_filename; filename
			mov rsi, argv      ; argv (массив указателей)
			mov rdx, [envp]        ; envp
			syscall

			mov rdi, 2
			mov rax, 60        ; sys_exit
			syscall

		exit_programm:
			mov rax, 60
            mov rdi, 0
			syscall
