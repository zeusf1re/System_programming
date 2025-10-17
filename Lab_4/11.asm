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
    push ecx
    push edx
    push eax
    push ebx

    mov ecx, _data
    mov edx, _length
    mov eax, 4
    mov ebx, 1
    int 0x80

    pop ebx
    pop eax
    pop edx
    pop ecx
}

macro cin _buffer, _length {

    mov ecx, _buffer
    mov edx, _length
    mov eax, 3
    mov ebx, 0
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
		pop edx	
		pop ecx
		pop ebx
		pop eax

	
}

section ".bss" writeable
	b_in rb 256
	b_out rb 256
    b_char rb 2
	m_n dd 0 
	m_for dd 0
	m_against dd 0

section ".data" writeable
    t_entry:
        db "Enter number of judges: ", 0
    t_entryEnd:
        t_entryLen equ t_entryEnd - t_entry
    t_win:
        db "Judges won.", 10, 0
    t_winEnd:
       t_winLen equ t_winEnd - t_win 
    t_lost:
        db "Judges lost.", 10, 0
    t_lostEnd:
       t_lostLen equ t_lostEnd - t_lost 
    t_draw:
        db "Draw, need do it again, I suppose...", 10, 0
    t_drawEnd:
        t_drawLen equ t_draw - t_draw
    t_judge:
        db "Judge ", 0
    t_judgeEnd:
        t_judgeLen equ t_judgeEnd - t_judge
    t_afterJudge:
        db ": ", 0
    t_afterJudgeEnd:
        t_afterJudgeLen equ t_afterJudgeEnd - t_afterJudge

    t_notNumber:
        db "Error: not a number", 10, 0
    t_notNumberEnd:
        t_notNumberLen equ t_notNumberEnd - t_notNumber

section ".text" writeable
    _start:
        cout t_entry, t_entryLen
        cin b_in, 256
        mov byte [b_in + eax - 1], 0; кстати так только для w\ Enter

        charToInt b_in
        mov [m_n], ebx

		push 0 
        .loop:
			pop ecx
            cmp ecx, [m_n]
            je .end
            inc ecx
			push ecx

			cout t_judge, t_judgeLen
			mov edi, b_out
			pop ecx
			mov esi, ecx
			push ecx
			intToChar
			pop ecx
			push ecx
			cout b_out, 256
			cout t_afterJudge, t_afterJudgeLen

			xor eax, eax
			cin b_char, 2
			mov al, [b_char]
			cmp al, '0'
			je .add0
			cmp al, '1'
			je .add1

			jmp .loop

        .add0:
			mov ebx, [m_against]
            inc ebx
			mov [m_against], ebx

            jmp .loop
        .add1:
		
			mov edx, [m_for]
            inc edx
			mov [m_for], edx
            jmp .loop

        .end:
			mov ebx, [m_against]
			mov edx, [m_for]
            cmp ebx, edx
            jg .lost
            jl .won
            cout t_draw, t_drawLen
            jmp .exit
        .won:
            cout t_win, t_winLen
            jmp .exit

        .lost:
            cout t_lost, t_lostLen
			jmp .exit

        .exit:
            safeExit
