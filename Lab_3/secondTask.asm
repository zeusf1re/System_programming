;                     (((b*a) / a) * b) * c
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
;      -123\0

section ".data" writeable
	t_result:
		db "Result of (((b * a) / a) * b) * c  =  ", 0
	t_resultEnd:
		t_resultLen equ t_resultEnd - t_result

	t_noArgs:
		db "No command-line arguments", 10, 0
	t_noArgsEnd:
		t_noArgslLen equ t_noArgsEnd - t_noArgs

	t_ferArgs:
		db "Less then 3 command-line arguments", 10, 0
	t_ferArgsEnd:
		t_ferArgsLen equ t_ferArgsEnd - t_ferArgs

	t_notNumber:
		db "Not a number", 10, 0
	t_notNumberEnd:
		t_notNumberLen equ t_notNumberEnd - t_notNumber
	
	newline db 10, 0
	
section ".bss" writeable
	b_in rb 256
	b_out rb 256
	m_a dd ? ; мусор
	m_b dd ? ; мусор
	m_c dd ? ; мусор

section ".text" executable
	_start:
		pop ecx

		cmp ecx, 1
		je errNoArgs

		cmp ecx, 4
		jl errFewArgs

		jmp ProcessArguments

	ProcessArguments:
		clearBuffer b_in, 256
		clearBuffer b_out, 256
		pop esi

		pop esi
		mov eax, [esi]
		mov dword [b_in], eax
		charToInt b_in
		mov [m_a], ebx

		pop esi
		mov eax, [esi]
		mov dword [b_in], eax
		charToInt b_in
		mov [m_b], ebx

		pop esi
		mov eax, [esi]
		mov dword [b_in], eax
		charToInt b_in
		mov [m_c], ebx
		
		cout t_result, t_resultLen

		;   (((b*a) / a) * b) * c
		xor edx, edx
		mov eax, [m_b]
		imul dword [m_a]     ; edx:eax = b * a

		;	edx:eax / m_a
		idiv dword [m_a]     ; eax = (b*a)/a, edx = остаток

		imul dword [m_b]     ; eax = ((b*a)/a) * b

		imul dword [m_c]     ; eax = res 
		mov esi, eax
		mov edi, b_out
		mov ecx, 256
		intToChar
		cout b_out, 256
		safeExit

	errNoArgs:
		cerr t_noArgs, t_noArgslLen
		exitWithError 1
	
	errFewArgs:
		cerr t_ferArgs, t_ferArgsLen
		exitWithError 2
