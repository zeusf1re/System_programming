format ELF 
public _start


macro syscall 
    int 0x80
}

macro safeExit {
	mov eax, 1
	mov ebx, 0
	syscall
}

macro newLine {
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    syscall
}

macro cout _data, _length {
    mov eax, 4
    mov ebx, 1
    mov ecx, _data
    mov edx, _length
    syscall
}

macro cin _bufferInput, _length {
    mov eax, 3
    mov ebx, 0
    mov ecx, _bufferInput
    mov edx, _length
    syscall
}

macro cerr _data, _length {
    mov eax, 4
    mov ebx, 2          ; ⚠️ Вот ключевое отличие: 2 = stderr!
    mov ecx, _data
    mov edx, _length
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

	thirdNFourthTaskGreeting:
		db "Enter your string(array of chars): "
	thirdNFourthTaskGreetingEnd:
		thirdNFouthTaskGreetingLength equ thirdNFourthTaskGreetingEnd - thirdNFourthTaskGreeting

	newline db 10

    clearSeq db 0x1B, '[', '2', 'J', 0x1B, '[', 'H'  ; ESC [2J ESC [H

section '.bss' writeable
	userChoice rb 2  ; symbol + \n
	bufferInput rb 256
	bufferOutput rb 256

	bufferNumberOutput rb 11
	bufferNumberOutputLength rd 1


section '.error' executable
	emptyStringErr:
		cerr emptyStringErrorText, emptyStringErrorTextLength
		exitWithError 1
		
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
		cin userChoice, 2
		ret

	ProcessChoice:
		mov al, [userChoice]

		cmp al, '1'
		je ReversedStrTask

		cmp al, '2'
		je ReversedStrTask

		cmp al, '3'
		je ReversedStrTask

		cmp al, '4'
		je SumOfDigits

		cmp al, 'c'
		je Clear 

		cmp al, 'q'
		je ExitProgram

		cerr invalidChoiceErrText, invalidChoiceErrTextLength
		exitWithError 2

	ReversedStrTask:
		cout entryText, entryTextLength

		cin bufferInput, 255
		mov esi, eax
		newLine

		cmp esi, 0           
	    jle emptyStringErr  
    
	    cmp byte [bufferInput + esi - 1], 10
		jne .reverseStrStart
		dec esi            
    
	
	.reverseStrStart:
		; 4. Разворачиваем строку
		mov ecx, esi          ; ECX = счётчик (длина строки)
		mov esi, bufferInput  ; ESI указывает на начало входной строки
		mov edi, bufferOutput ; EDI указывает на начало выходного буфера

		push ecx ; пушим в стек длину строки

		add esi, ecx          ; ESI переходим к КОНЦУ входной строки
		dec esi               ; ESI теперь на последнем символе

	.reverseStrLoop:
		; Копируем символы в обратном порядке
		mov al, [esi]         ; Берём символ с конца входной строки
		mov [edi], al         ; Записываем в начало выходной строки
		dec esi               ; Двигаемся назад по входной строке
		inc edi               ; Двигаемся вперед по выходной строке

		dec ecx
		jnz .reverseStrLoop
		
		; 5. Выводим результат
		newLine

		pop edx ; Длина
		cout reversedStringText, reversedStringTextLength
		cout bufferOutput, edx             ; Развернутая строка (ECX содержит длину)
		newLine
		ret
	 
	SumOfDigits:
		cout inputNumberText, inputNumberTextLength	

		cin bufferInput, 255
		mov esi, eax

		cmp esi, 0
		jle .emptyErr

	    xor ebx, ebx          ; EBX = 0 (наша сумма)
		mov ecx, esi          ; ECX = счётчик цикла
		mov esi, bufferInput  ; ESI указывает на начало строки

	.loop:
		; Берём текущий символ
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
		inc esi              ; Переходим к следующему символу
		loop .loop ; Повторяем ECX раз
		
		call .numberToString
		
		; Выводим результат
		newLine
		cout sumOfDigitsText, sumOfDigitsTextLength 
		cout bufferNumberOutput, 10  ; Выводим число (максимум 10 цифр)
		newLine
		newLine
		
		ret

	.numberToString:
		xor eax, eax
		mov al, bl          ; AL = наша сумма (0-255)
		mov edi, bufferNumberOutput + 10  ; EDI указывает на конец буфера
		mov byte [edi], 0   ; Записываем нулевой байт в конец
		
		mov ecx, 10         ; Основание системы (десятичная)

	.convertLoop:
		dec edi             ; Двигаемся назад по буферу
		xor edx, edx        ; Очищаем EDX
		div ecx             ; EDX:EAX / ECX = EAX (частное), EDX (остаток)
		
		; Преобразуем остаток в символ
		add dl, '0'         ; DL = остаток (0-9) + '0' = '0'-'9'
		mov [edi], dl       ; Записываем символ в буфер
		
		; Проверяем закончили ли
		test eax, eax
		jnz .convertLoop   ; Если частное != 0, продолжаем
		
		; Вычисляем длину результата
		mov esi, edi        ; Начало строки
		mov ecx, bufferNumberOutput + 10
		sub ecx, esi        ; ECX = длина строки
		mov [bufferNumberOutputLength], ecx
		
		ret
	.emptyErr:
		cerr emptyStringErrorText, emptyStringErrorTextLength
		exitWithError 3

	PrintMatrix:
		cout thirdNFourthTaskGreeting, thirdNFouthTaskGreetingLength
		cin bufferInput, 255
		mov esi, eax ; в esi теперь длина входящего буфера

		cmp esi, 0           
	    jle emptyStringErr  
		
		
		

	ExitProgram:
		safeExit
	
	Clear:
		clearScreen
		ret
