#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
  if (argc != 4) {
    fprintf(stderr, "Usage: %s a b c\n", argv[0]);
    return 1;
  }

  int a = atoi(argv[1]);
  int b = atoi(argv[2]);
  int c = atoi(argv[3]);

  // Вычисление: (((b * a) / a) * b) * c
  int result = (((b * a) / a) * b) * c;

  printf("Result of (((b * a) / a) * b) * c = %d\n", result);

  return 0;
}
