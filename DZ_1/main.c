#include <stdio.h>
#include <stdlib.h>

typedef struct Node {
    long value;
    struct Node* next;
} Node;

typedef struct Queue {
    Node* head;
    Node* tail;
} Queue;

void PrintQueue(Queue* q) {
    printf("Содержимое очереди: [ ");
    Node* current = q->head;
    while (current != NULL) {
        printf("%ld ", current->value);
        current = current->next;
    }
    printf("]\n");
}

extern void InitHeap();
extern void PushBack(Queue* q, long value);
extern long PopHead(Queue* q);
extern void FillRand(Queue* q);
extern long CountEven(Queue* q);
extern long CountEndWith1(Queue* q);
extern void PrintOdd(Queue* q);


int main() {

    InitHeap();

    Queue myQueue;
    myQueue.head = NULL;
    myQueue.tail = NULL;

    printf("1. Добавляем 5 элементов...\n");
    PushBack(&myQueue, 11);
    PushBack(&myQueue, -22);
    PushBack(&myQueue, 31);
    PushBack(&myQueue, 45);
    PushBack(&myQueue, -51);

    printf("\n2. Текущее состояние очереди:\n");
    PrintQueue(&myQueue);

    printf("\n3. Извлекаем один элемент...\n");
    long val = PopHead(&myQueue);
    printf("Извлечено: %ld\n", val);

    printf("\n4. Состояние очереди после извлечения:\n");
    PrintQueue(&myQueue);

    printf("\n9. Считаем числа, оканчивающиеся на 1:\n");
    printf("Количество оканчивающихся на 1: %ld\n", CountEndWith1(&myQueue));

    printf("\n5. Вывод нечетных чисел (из ассемблера):\n");
    PrintOdd(&myQueue);

    printf("\n6. Заменяем значения на случайные...\n");
    FillRand(&myQueue);

    printf("\n7. Состояние очереди после FillRand:\n");
    PrintQueue(&myQueue);

    printf("\n8. Считаем четные числа:\n");
    printf("Количество четных: %ld\n", CountEven(&myQueue));


    while (myQueue.head != NULL) {
        PopHead(&myQueue);
    }
    
    printf("\nПрограмма завершена.\n");

    return 0;
}
