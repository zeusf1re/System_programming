#include <stdio.h>
#include <stdlib.h> // malloc  free

typedef struct Node {
    long value;
    struct Node* next;
} Node;

typedef struct Queue {
    Node* head;
    Node* tail;
} Queue;

extern void InitHeap(void* ptr, long size);
extern void PushBack(Queue* q, long value);
extern long PopHead(Queue* q);
extern void FillRand(Queue* q);

int main() {
    const long HEAP_SIZE = 65536; // 64KB
    void* heapMemory = malloc(HEAP_SIZE);
    if (heapMemory == NULL) {
        printf("Ошибка: не удалось выделить память для кучи!\n");
        return 1;
    }

    InitHeap(heapMemory, HEAP_SIZE);

    Queue myQueue;
    myQueue.head = NULL;
    myQueue.tail = NULL;

    printf("--- Демонстрация PushBack и PopHead ---\n");
    printf("Добавляем 5, 10, 15\n");
    PushBack(&myQueue, 5);
    PushBack(&myQueue, 10);
    PushBack(&myQueue, 15);

    long val = PopHead(&myQueue);
    printf("Извлечено: %ld (ожидаем 5)\n", val);

    val = PopHead(&myQueue);
    printf("Извлечено: %ld (ожидаем 10)\n", val);
    
    PopHead(&myQueue); // извлекаем 15
    printf("\nОчередь очищена.\n");

    printf("\n--- Демонстрация FillRand ---\n");
    printf("Добавляем 1, 2, 3\n");
    PushBack(&myQueue, 1);
    PushBack(&myQueue, 2);
    PushBack(&myQueue, 3);
    
    printf("Заменяем значения на случайные...\n");
    FillRand(&myQueue);

    printf("Извлекаем три случайных значения:\n");
    val = PopHead(&myQueue);
    printf("Извлечено: %ld\n", val);
    val = PopHead(&myQueue);
    printf("Извлечено: %ld\n", val);
    val = PopHead(&myQueue);
    printf("Извлечено: %ld\n", val);

    val = PopHead(&myQueue);
    printf("\nПробуем извлечь из пустой очереди: %ld (ожидаем -1)\n", val);

    free(heapMemory);

    return 0;
}
