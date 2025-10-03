
format ELF 
public _start


macro syscall {
    int 0x80
}

macro safeExit {
	mov eax, 1
	mov ebx, 0
	syscall
}

macro exitWithError _code {
    mov eax, 1
    mov ebx, _code
    syscall
}

macro clearScreen {
    mov eax, 4
    mov ebx, 1
    mov ecx, clearSeq
    mov edx, 7
	syscall
}

macro newLine {
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
}

macro cout _data, _length {
    mov eax, 4
    mov ebx, 1
    mov ecx, _data
    mov edx, _length
    int 0x80
}

macro cin _buffer, _length {
    mov eax, 3
    mov ebx, 0
    mov ecx, _buffer
    mov edx, _length
    int 0x80
}

macro cerr _data, _length {
    mov eax, 4
    mov ebx, 2          
    mov ecx, _data
    mov edx, _length
    syscall
}

macro clearBuffer _name, _size {
    push eax
    push ecx
    push edi
    
    mov edi, _name
    mov ecx, _size 
    xor eax, eax
    rep stosb   ; записываем AL в [EDI], ECX раз
    
    pop edi
    pop ecx
    pop eax
}

macro intCast _buffer, _inputLen{ ; буфер с числом в виде строки, в ebx будет это число в переведенное в UInt
	local ..loop, ..safeExit, ..nextChar
	push esi 
	push ecx
	push eax
	
	xor ebx, ebx          ; res = 0 
	mov esi, _buffer      ; esi начало буффера  
	mov ecx, _inputLen       ; ecx длина буффера

	test ecx, ecx         ; len != 0
	jz ..safeExit

	..loop:
		mov al, [esi]
		
		cmp al, 10
		je ..nextChar
		
		cmp al, '0'
		jl ..nextChar  
		cmp al, '9'
		jg ..nextChar 
; это все очень опасно, т.к. нет проверки на НЕ 1-9, но тогда логика разрушится, хз че делать 
; надо верить, что тут только цифры

		sub al, '0'          
		imul ebx, 10
		add bl, al         
; тут есть небольшой риск переполнения, но не волнуемся просто и оно пройдет)

	..nextChar:
		inc esi              ; переходим к следующему символу

		dec ecx
		jnz ..loop

	..safeExit:
		pop eax 
		pop ecx
		pop esi
}
macro charCast _number, _buffer {
; использовать нужно с буфером >10, лучше специальный 12байтный и для ввода числа, там есть коммент
	local ..convertLoop, ..done, ..safeExit
	
	push eax ; целая часть
	push ebx ; res
	push ecx 
	push edx ; остатки от /10
	push edi ; будет указателем, его двигаю
	
	mov eax, _number
	mov edi, _buffer
	add edi, 11          ; конец буфера
	mov byte [edi], 0    ; '\0' в 10 слот
	dec edi
	
	mov ecx, 10          ; oснование системы
	
	; Обработка нуля
	test eax, eax
	jnz ..convertLoop

	mov byte [edi], '0' ; начало с 0
	jmp ..safeExit
	
..convertLoop:
	xor edx, edx
	div ecx              ; eax / 10  ==> edx - остаток, eax - целая
	add dl, '0'          ; ascii -> int
	mov [edi], dl        ; записываем символ
	dec edi              
	
	test eax, eax
	jnz ..convertLoop   ; Продолжаем пока EAX ≠ 0
	
	inc edi
	
..safeExit:
	; Теперь EDI указывает на начало строки
	; Можно скопировать в нужное место если нужно
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
}

section '.data' writeable
	noArgsErrText:
		db "Error: no command-line arguments", 10, 0
	noArgsErrTextEnd:
		noArgsErrTextLen = noArgsErrTextEnd - noArgsErrText

	manyArgsErrText:
		db "Error: more than one command-line arguments", 10, 0
	manyArgsErrTextEnd:
		manyArgsErrTextLen = manyArgsErrTextEnd - manyArgsErrText

	newline db 10

section '.bss' writeable
	b_char rb 2 ; + \0
	b_out rb 256
	b_regOut rd 1


section '.text' executable
_start:
	pop eax ; Args
	pop esi ; argv[0]
	
	cmp eax, 1
	je .noArgs
	cmp eax, 2
	jg .manyArgs	

	jmp .processArgs


	.processArgs:
		pop esi
		mov al, [esi]
		movzx eax, al ; это все чтобы взять один символ, при этом вернуть его в esi, потому что он не используется в charCast, типо переменную сэкономил 
		mov esi, eax
		charCast esi, b_out
		cout b_out, 256
		safeExit



	.noArgs:
		cerr noArgsErrText, noArgsErrTextLen
		exitWithError 1
	.manyArgs:
		cerr manyArgsErrText, manyArgsErrTextLen	
		exitWithError 2

	.exit:
		safeExit
