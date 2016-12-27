
/*
  Very simple program for testing some C functions and linux syscall.
  TODO add a dynamic memory test
  TODO command-line options
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <sys/utsname.h>
#include <time.h>

/* prototypes */
static void shellsort(int[], const unsigned int);

int main(int argc, char* argv[]) {
  /* Local variables */
  bool talk = true;
  int i = 0;
  struct utsname name;
  const unsigned int arr_size = 1000;
  int arr[arr_size];
  /* Print test */
  printf("I can print something, not bad....\n");
  /* argc and argv test */
  printf("Oh well, I'm.... %s? Apparently yes, this is my name\n", argv[0]);
  if (argc > 1 && argv[1][0] == '-') {
    switch (argv[1][1]) {
      case 'm':
        talk = false;
        printf("and you have NOT TIME FOR TALK, this is a problem....\n");
        break;
      default:
        printf("I don't recognize this option: %c\n", argv[1][1]);
    }
  }
  /* Input test */
  if (talk) {
    char str[100];
    printf("Anyway, tell me something nice: ");
    scanf("%s", str);
    printf("You have said \"%s\"? OK man.... this will have consequences\n", str);
  }
  /* Sleep and fflush test */
  for (i=0; i < 4; i++) {
    sleep(1);
    printf(".");
    fflush(stdout);
  }
  printf("\nbut not today, I don't really care about your opinions.\n");
  /* sizeof test */
  printf("Now it's my turn to say something nice: here where I am\n"
    "a char has a size of %u,\n"
    "a int has a size of %u,\n"
    "a float has a size of %u,\n"
    "and a double has a size of %u.\n",
    sizeof(char), sizeof(int), sizeof(float), sizeof(double)
  );
  /* retrive some info from a syscall */
  i = uname(&name);
  if (i < 0) printf("I cannot tell you something more because of an error");
  else {
    printf("Infact I'm in %s %s (%s) on %s\n", name.sysname, name.release,
      name.nodename, name.machine);
  }
  /* rand() test */
  srand(time(NULL));
  for (i = 0; i < arr_size; i++) {
    arr[i] = rand() % (arr_size/2);
  }
  printf("Here I'have been able to generate random numbers like %i\n", arr[0]);
  /* shellsort() test (in-place, constant memory usage) */
  shellsort(arr, arr_size);
  printf("and sort them with shellsort:\n[");
  for (i = 0; i < arr_size; i += arr_size/10) {
    printf("%i .. ", arr[i]);
  } printf("]\n");
  return 0;
}

/*
  Implementation of shellsort; it's a sorting algorithm with no recursion or
  memory usage (except few integer variables) so it should be good for embedded
  systems. With the Knuth sequence, it has a complexity of O(n^1.5) but with
  other sequences can do better; this sequences can be saved in a file instead
  of re-generate them every time.
*/
static void shellsort(int v[], const unsigned int size) {
  /* Knuth sequence - 1, 4, 13, 40, 121, 364, 1093, ... , 3*k_(i-1) +1 */
  int i, j;
  int tmp;
  int gap = 1;
  while (gap < size) gap = 3*gap +1;
  gap /= 3;
  for (; gap>=1; gap/=3)
    for (i = gap; i < size; i++) {
      tmp = v[i];
      for (j = i; (gap <= j) && (v[j-gap] > tmp); j -= gap)
        v[j] = v[j-gap];
      v[j] = tmp;
    }
}
