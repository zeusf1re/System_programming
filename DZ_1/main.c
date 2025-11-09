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

extern void InitHeap(void* ptr, long size);
extern void PushBack(Queue* q, long value);
extern long PopHead(Queue* q);
extern void FillRand(Queue* q);
extern long CountEven(Queue* q);
//extern long CountEndsByOne(Queue* q);
extern void PrintOdd(Queue* q);

int main() {
    const long HEAP_SIZE = 65536;
    void* heapMemory = malloc(HEAP_SIZE);
    if (heapMemory == NULL) {
        return 1;
    }

    InitHeap(heapMemory, HEAP_SIZE);

    Queue myQueue;
    myQueue.head = NULL;
    myQueue.tail = NULL;

    PushBack(&myQueue, 1);
    PushBack(&myQueue, 12);
    PushBack(&myQueue, 21);
    PushBack(&myQueue, 33);
    PushBack(&myQueue, 44);
    PushBack(&myQueue, 51);
    PushBack(&myQueue, 68);
    PushBack(&myQueue, 71);
    
    printf("Количество четных: %ld\n", CountEven(&myQueue));
 //   printf("Количество оканчивающихся на 1: %ld\n", CountEndsByOne(&myQueue));
    
    printf("Нечетные числа из очереди:\n");
    PrintOdd(&myQueue);

    while (myQueue.head != NULL) {
        PopHead(&myQueue);
    }
    
    free(heapMemory);

    return 0;
}
