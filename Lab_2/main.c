#include <stdio.h>

int main(int argc, char **argv) {
  long int n = 5277616985;
  int sum = 0;
  int digit = 0;

  while (n > 0) {
    digit = n % 10;
    sum += digit;
    n /= 10;
  }

  printf("Сумма цифр: %d\n", sum);

  return 0;
}
