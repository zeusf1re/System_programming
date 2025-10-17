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


macro charToInt _buffer{ ;  res to ebx, MUST have \0 in end
	local ..positive, ..neg, ..errNotNumber, ..loop, ..negFlag, ..end

	push esi
	push eax
	push 0 ; flag
	xor ebx, ebx

	mov esi, _buffer
	mov al, [esi]
	cmp al, '-'
	je ..negFlag
	cmp al, '0'
	jl ..errNotNumber
	cmp al, '9'
	jg ..errNotNumber
	jmp ..loop

	..loop:
		mov al, [esi]
		cmp al, 0
		je ..end

		; cmp al, '0'
		; jl ..errNotNumber
		; cmp al, '9'
		; jg ..errNotNumber
		sub al, '0'

		imul ebx, 10
		movzx eax, al
		add ebx, eax

		inc esi
		jmp ..loop

	..negFlag:
		add esp, 4 ; чистим последний пуш(4 bytes)
		push 1
		inc esi
		jmp ..loop
	..neg:
		neg ebx
		push 1
		jmp ..end	

	..errNotNumber:
		cerr t_notNumber, t_notNumberLen
		exitWithError 3
	..end:
		pop eax
		cmp eax, 0
		pop eax
		pop esi


}

macro intToChar { ; from esi to edi, buffer length in ecx -- это под вопросом, пока не буду использовать
	local ..neg, ..pushLoop, ..popLoop

	push eax
	push ebx
	push ecx
	push edx
	xor ebx, ebx ; counter

	; mov eax, ecx 
	; shr eax, 2
	; mov ecx, eax
	; xor eax, eax
	; rep stosd
	
	;cleared
	
	mov eax, esi
	mov ecx, 10

	push 0 ; типо конец строки
	cmp eax, 0
	jge ..pushLoop

	..neg:
		push '-'
		inc ebx
		neg eax

	..pushLoop:
		xor edx, edx
		div ecx ; edx - остаток, eax - целая
		add dl, '0'
		movzx edx, dl
		push edx
		inc ebx
		cmp eax, 0
		jne ..pushLoop
	
	..popLoop:

		pop edx 
		mov [edi], edx
		cmp edx, 0
		inc edi
		dec ebx
		cmp ebx, 0
		jne ..popLoop

		pop edx	
		pop ecx
		pop ebx
		pop eax

	
}

section ".bss" writeable
	b_in rb 256
	b_out rb 256
	m_n dd 0

section ".data" writeable
	t_entry:
		db "Enter your positive number: ", 0
	t_entryEnd:
		t_entryLen equ t_entryEnd - t_entry

	t_notNumber:
		db "Error: not a number", 10, 0
	t_notNumberEnd:
		t_notNumberLen equ t_notNumberEnd- t_notNumber
	newline db 10

; сколько НЕ делятся на 5, 11
section ".programm" executable
	_start:
		cout t_entry, t_entryLen
		clearBuffer b_in, 256
		cin b_in, 256
		mov ecx, eax ; entered len
		mov edi, b_in
		mov byte [edi + ecx - 1], 0

		charToInt b_in
		mov [m_n], ebx

		mov eax, [m_n]
		xor edx, edx

		;ebx -- res
		mov ebx, eax

		mov ecx, 5
		div ecx
		sub ebx, eax

		mov eax, [m_n]
		xor edx, edx
		mov ecx, 11
		div ecx
		sub ebx, eax

		; n / 55
		mov eax, [m_n] 
		xor edx, edx
		mov ecx, 55
		div ecx
		add ebx, eax
					
		mov esi, ebx
		mov edi, b_out
		mov ecx, 256
		intToChar
		
		cout b_out, 256
		newLine
		safeExit
