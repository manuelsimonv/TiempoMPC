#include <stdio.h>
#include <time.h>

// Función para medir la resolución del temporizador
double get_timer_resolution() {
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    do {
        clock_gettime(CLOCK_MONOTONIC, &end);
    } while (end.tv_nsec == start.tv_nsec && end.tv_sec == start.tv_sec);

    double diff = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    return diff;
}

int main() {
    struct timespec tic, toc;

    // Medir resolución
    double resolution = get_timer_resolution();
    printf("Resolución aproximada del temporizador: %.9f microsegundos\n", resolution * 1e6);

    // Medir tiempo transcurrido en un bloque de código
    clock_gettime(CLOCK_MONOTONIC, &tic);

    // Bloque de código a medir (ejemplo: espera activa de ~100ms)
    struct timespec wait_time = {0, 100000000}; // 100 ms
    nanosleep(&wait_time, NULL);

    clock_gettime(CLOCK_MONOTONIC, &toc);

    double elapsed = (toc.tv_sec - tic.tv_sec) + (toc.tv_nsec - tic.tv_nsec) / 1e9;
    printf("Tiempo transcurrido en bloque de código: %.9f segundos\n", elapsed);

    return 0;
}
