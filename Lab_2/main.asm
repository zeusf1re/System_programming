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
	menuText:
		db "=======================", 10
		db "          Menu         ", 10
		db "-----------------------", 10
		db "1 - Get reversed string", 10
		db "2 - Get matrix", 10
		db "3 - Get triangle", 10
		db "4 - Get sum of digits", 10
		db "c - Clear", 10
		db "q - quit", 10 
		db "=======================", 10
		db 10, "> "
	menuTextEnd:
		menuTextLength = menuTextEnd - menuText

    entryText:
        db "Enter your string: "
    entryTextEnd:
		entryTextLength equ entryTextEnd - entryText

	stringOutputText:
		db "Your string: "
	stringOutputTextEnd:
		stringOutputTextLength equ stringOutputTextEnd - stringOutputText
	
	reversedStringText:
		db "Reversed string: ", 0
	reversedStringTextEnd:
		reversedStringTextLength equ reversedStringTextEnd - reversedStringText

	emptyStringErrorText:
		db "Error: Your string is empty", 10, 0
	emptyStringErrorTextEnd:
		emptyStringErrorTextLength equ emptyStringErrorTextEnd - emptyStringErrorText 

	invalidChoiceErrText:
		db "Error: invalid choice", 10, 0
	invalidChoiceErrTextEnd:
		invalidChoiceErrTextLength equ invalidChoiceErrTextEnd - invalidChoiceErrText 
	
	inputNumberText:
		db "Enter positive number, less than : "
	inputNumberTextEnd:
		inputNumberTextLength equ inputNumberTextEnd - inputNumberText
	
	sumOfDigitsText:
		db "Sum of your number: "
	sumOfDigitsTextEnd:
		sumOfDigitsTextLength equ sumOfDigitsTextEnd - sumOfDigitsText

	notIntTextErr:
		db "This is not an integer", 10, 0
	notIntTextErrEnd:
		notIntTextErrLength equ notIntTextErrEnd - notIntTextErr

	thirdNFourthTaskGreeting_1:
		db "Enter your favorite character: "
	thirdNFourthTaskGreeting_1End:
		thirdNFouthTaskGreeting_1Length equ thirdNFourthTaskGreeting_1End - thirdNFourthTaskGreeting_1
	thirdNFourthTaskGreeting_2:
		db "Enter number of characters to print: "
	thirdNFourthTaskGreeting_2End:
		thirdNFouthTaskGreeting_2Length equ thirdNFourthTaskGreeting_2End - thirdNFourthTaskGreeting_2
	thirdNFourthTaskGreeting_3:
		db "Enter width of the matrix: "
	thirdNFourthTaskGreeting_3End:
		thirdNFouthTaskGreeting_3Length equ thirdNFourthTaskGreeting_3End - thirdNFourthTaskGreeting_3
	thirdNFourthTaskGreeting_4:
		db "Enter height of the matrix: "
	thirdNFourthTaskGreeting_4End:
		thirdNFouthTaskGreeting_4Length equ thirdNFourthTaskGreeting_4End - thirdNFourthTaskGreeting_4

	newline db 10

    clearSeq db 0x1B, '[', '2', 'J', 0x1B, '[', 'H' 

section '.bss' writeable
	b_userChoice rb 2  ; symbol + \n
	b_input rb 256
	b_output rb 256

	bufferNumberOutput rb 11
	bufferNumberOutputLength rd 1

    b_intInput rb 12  ;int <4,294,967,295 + '\0' + trash(1 symbol)
    m_inputLen dd 0 
    m_intX dd 4
    m_intY dd 4
    m_intZ dd 4


section '.error' executable
	emptyStringErr:
		cerr emptyStringErrorText, emptyStringErrorTextLength
		exitWithError 1

	notDigitErr:
		cerr notIntTextErr, notIntTextErrLength
		exitWithError 4

section '.text' executable
    _start:
		clearScreen
		call MainLoop
		
	MainLoop:
        cout menuText, menuTextLength
		call GetChoice
		call ProcessChoice
		jmp MainLoop
	

	GetChoice:
		cin b_userChoice, 2
		ret

	ProcessChoice:
		mov al, [b_userChoice]

		cmp al, '1'
		je FirstTask

		cmp al, '2'
		je PrintMatrix

		cmp al, '3'
        je PrintTriangle

		cmp al, '4'
		je SumOfDigits

		cmp al, 'c'
		je Clear 

		cmp al, 'q'
		je ExitProgram

		cerr invalidChoiceErrText, invalidChoiceErrTextLength
		exitWithError 2

    FirstTask:
		cout entryText, entryTextLength

		cin b_input, 255
		cmp eax, 0           
	    jle emptyStringErr  
		push eax; len

        clearBuffer b_output, 255
       
        pop ecx
        mov esi, b_input
        mov edi, b_output
        add esi, ecx
        dec esi
        
        je .loop


        .loop:
            mov al, [esi]
            mov [edi], al

            inc edi
            dec esi
            
            dec ecx
            jnz .loop

        .loopEnd:
            dec ecx
            mov byte [edi], 0
            cout b_output, 255 
            newLine
            newLine
            ret

	SumOfDigits:
		cout inputNumberText, inputNumberTextLength	

		cin b_input, 255
		mov esi, eax

		cmp esi, 0
		jle emptyStringErr 

	    xor ebx, ebx          ; EBX = 0 (наша сумма)
		mov ecx, esi          ; ECX = счётчик цикла
		mov esi, b_input  ; ESI указывает на начало строки

	.loop:
		mov al, [esi]
		
		; Пропускаем символы переноса строки
		cmp al, 10
		je .nextChar
		
		; Проверяем что это цифра (от '0' до '9')
		cmp al, '0'
		jl .notDigitErr
		cmp al, '9'
		jg .notDigitErr
		
		; Преобразуем символ в число и добавляем к сумме
		sub al, '0'          ; AL = AL - '0' (получаем число 0-9)
		add bl, al           ; Добавляем к сумме (в BL)
		
		jmp .nextChar

	.notDigitErr:
		cerr notIntTextErr, notIntTextErrLength
		exitWithError 4

	.nextChar:
		inc esi     
		loop .loop ; Повторяем ECX раз
		
		call .numberToString
		
		newLine
		cout sumOfDigitsText, sumOfDigitsTextLength 
		cout bufferNumberOutput, 10  ; Выводим число (максимум 10 цифр)
		newLine
		newLine
		
		ret

	.numberToString:
		xor eax, eax
		mov al, bl         
		mov edi, bufferNumberOutput + 10  ; EDI указывает на конец буфера
		mov byte [edi], 0   ; Записываем нулевой байт в конец
		
		mov ecx, 10         

	.convertLoop:
		dec edi             
		xor edx, edx       
		div ecx             ; EDX:EAX / ECX = EAX (частное), EDX (остаток)
		
		; Преобразуем остаток в символ
		add dl, '0'         ; DL = остаток (0-9) + '0' = '0'-'9'
		mov [edi], dl     
		
		; Проверяем закончили ли
		test eax, eax
		jnz .convertLoop 
		
		; Вычисляем длину результата
		mov esi, edi     
		mov ecx, bufferNumberOutput + 10
		sub ecx, esi    
		mov [bufferNumberOutputLength], ecx
		
		ret

	PrintMatrix:
		cout thirdNFourthTaskGreeting_1, thirdNFouthTaskGreeting_1Length
		cin b_userChoice, 2  ;   b_userChoice: char
		mov esi, eax       ; в esi теперь длина входящего буфера
		test esi, esi
	    jz emptyStringErr

		cout thirdNFourthTaskGreeting_2, thirdNFouthTaskGreeting_2Length
		cin b_intInput, 12 
		push esi
		mov esi, eax
		test esi, esi ; в esi оставлю длину userChoice, а длина этого ввода не нужна
	    jz emptyStringErr  
		pop esi
		;ignore number of chars, 
		clearBuffer b_intInput, 12	


		cout thirdNFourthTaskGreeting_3, thirdNFouthTaskGreeting_3Length
		cin b_intInput, 12 
		test eax, eax    ; eax - длина ввода длины строки
	    jz emptyStringErr  

		mov [m_inputLen], eax  ;   
		intCast b_intInput, [m_inputLen] ; ebx - int
		mov [m_intX], ebx
		clearBuffer b_intInput, 12	
		
		clearBuffer b_output, 256
		mov edi, b_output
		mov ecx, [m_intX]
		mov al, [b_userChoice]
		
		rep stosb  ; тут ecx уже 0
		
		mov byte [edi], 0


		cout thirdNFourthTaskGreeting_4, thirdNFouthTaskGreeting_4Length
		clearBuffer b_intInput, 12
		cin b_intInput, 12  ; кол-во строк матрицы, надо оставить "интом" в буфере, сначала перевести из чаров
		test eax, eax           
		jz emptyStringErr  
		mov [m_inputLen], eax
		intCast b_intInput, [m_inputLen]
		mov [m_intY], ebx
		clearBuffer b_intInput, 12	
		
		newLine
		mov ecx, [m_intY]

		.loop:
			test ecx, ecx
			jz .loopEnd
			push ecx

			cout b_output, [m_intX]
			newLine

			pop ecx
			dec ecx
			jnz .loop
		.loopEnd:
			clearBuffer b_output, 256
			newLine
			newLine
			ret

	PrintTriangle:
        
		cout thirdNFourthTaskGreeting_1, thirdNFouthTaskGreeting_1Length
		cin b_userChoice, 2  ;   b_userChoice: char
		mov esi, eax       ; в esi теперь длина входящего буфера
		test esi, esi
	    jz emptyStringErr

		cout thirdNFourthTaskGreeting_2, thirdNFouthTaskGreeting_2Length
		cin b_intInput, 12 
		test eax, eax
	    jz emptyStringErr  
        mov [m_inputLen], eax
        intCast b_intInput, [m_inputLen]
        mov [m_intX], ebx ; x - кол-во всех символов
		clearBuffer b_intInput, 12	
        

        ; внешний счетчик (all symbols) Y
        ; внутренний (symbols/row) Z
		clearBuffer b_output, 256
        mov esi, 0 
        mov ecx, 1 ; буду в него все скидывать
		mov [m_intZ], ecx
		mov [m_intY], esi
		mov [m_intZ], esi
		mov edi, b_output ; будет указывать на конец строки, поэтому его НЕЛЬЗЯ ПОТЕРЯТЬ
		push edi
		
        .loop:
			mov ecx, [m_intY] 
            cmp ecx, [m_intX]
            jge .loopEnd

			mov al, [b_userChoice]
			pop edi
            mov byte [edi], al
			inc edi ; уже на следующий
			push edi
            cout b_output, [m_intZ]
            newLine
; не пушил ecx... так как переписал cin, cout, но все их использования в других заданиях не переписал пока что  TODO 
; уже нет
			mov ecx, [m_intY]
            add ecx, [m_intZ]
			mov [m_intY], ecx
			mov ecx, [m_intZ]   ; тяжело написано, но тут просто y += z, ++z
            inc ecx
			mov [m_intZ], ecx

            jmp .loop

        .loopEnd:
			pop edi
            ret

	ExitProgram:
		safeExit
	
	Clear:
		clearScreen
		ret
