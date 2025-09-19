format ELF
public _start

nameText:
	db "Канаев", 10
	db "Андрей", 10
	db "Ильич", 10, 0
nameTextEnd:
	nameTextLength equ nameTextEnd - nameText

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, nameText
    mov edx, nameTextLength 
    int 0x80

    mov eax, 1
    mov ebx, 0
    int 0x80
