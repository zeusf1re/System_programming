TARGET = demo

# Компилятор C (обычно gcc)
CC = gcc

# Ассемблер
AS = fasm

# Файлы с исходным кодом
C_SOURCE = main.c
ASM_SOURCE = lib.asm

C_OBJECT = $(C_SOURCE:.c=.o)
ASM_OBJECT = $(ASM_SOURCE:.asm=.o)

# Правило по умолчанию: собрать всё
all: $(TARGET)

# Правило для линковки: исполняемый файл зависит от C и ASM объектных файлов
$(TARGET): $(C_OBJECT) $(ASM_OBJECT)
	$(CC) $(C_OBJECT) $(ASM_OBJECT) -o $(TARGET)
	@echo "Программа '$(TARGET)' успешно собрана!"

# Правило для компиляции C-кода: main.o зависит от main.c
$(C_OBJECT): $(C_SOURCE)
	$(CC) -c -g $(C_SOURCE) -o $(C_OBJECT)

# Правило для ассемблирования: queue.o зависит от queue.asm
$(ASM_OBJECT): $(ASM_SOURCE)
	$(AS) $(ASM_SOURCE) $(ASM_OBJECT)

# Правило для очистки: удалить все скомпилированные файлы
clean:
	rm -f *.o $(TARGET)
	@echo "Очистка завершена."
