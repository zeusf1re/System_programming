TARGET = demo

# Компилятор
CC = gcc

# ассемблер
AS = fasm

# файлы с исходным кодом
C_SOURCE = main.c
ASM_SOURCE = lib.asm

C_OBJECT = $(C_SOURCE:.c=.o)
ASM_OBJECT = $(ASM_SOURCE:.asm=.o)

# правило по умолчанию: собрать всё
all: $(TARGET)

# правило для линковки: исполняемый файл зависит от C и ASM объектных файлов
$(TARGET): $(C_OBJECT) $(ASM_OBJECT)
	$(CC) -no-pie $(C_OBJECT) $(ASM_OBJECT) -o $(TARGET)
	@echo "Программа '$(TARGET)' успешно собрана!"

# правила что c.o от с и asm от asm
$(C_OBJECT): $(C_SOURCE)
	$(CC) -no-pie -c -g $(C_SOURCE) -o $(C_OBJECT)

$(ASM_OBJECT): $(ASM_SOURCE)
	$(AS) $(ASM_SOURCE) $(ASM_OBJECT)

clean:
	rm -f *.o $(TARGET)
	@echo "Очистка завершена."
