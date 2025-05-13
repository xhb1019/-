#include <emmintrin.h> /* header file for the SSE intrinsics */
#include <time.h>
#include <stdio.h>
#include <math.h>

float **a;
float **b;
float **c;
float **c2;

int n = 10000;
int p = 8000;

void init(void) {
    a = malloc(n * sizeof(float *));
    b = malloc(4 * sizeof(float *));
    c = malloc(n * sizeof(float *));
    c2 = malloc(n * sizeof(float *));
    for (int i = 0; i < n; ++i) {
        a[i] = malloc(4 * sizeof(float));
        c[i] = malloc(p * sizeof(float));
        c2[i] = malloc(p * sizeof(float));
    }
    for (int i = 0; i < 4; ++i) {
        b[i] = malloc(p * sizeof(float));
    }

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < 4; ++j) {
            a[i][j] = (float) rand() / (float) RAND_MAX;
        }
    }

    for (int i = 0; i < 4; ++i) {
        for (int j = 0; j < p; ++j) {
            b[i][j] = (float) rand() / (float) RAND_MAX;
        }
    }
}

void check_correctness(char *msg) {
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < p; ++j) {
            if (fabs(c[i][j] - c2[i][j]) > 1/1e6) {
                printf("%s incorrect!\n", msg);
                return;
            }
        }
    }
}

void naive_matmul(void) {
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    // c = a * b
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < p; ++j) {
            c[i][j] = 0;
            for (int k = 0; k < 4; ++k) {
                c[i][j] += a[i][k] * b[k][j];
            }
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    printf("naive: %f\n", (float) (end.tv_sec - start.tv_sec) + (float) (end.tv_nsec - start.tv_nsec) / 1000000000.0f);
}

void loop_unroll_matmul(void) {
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    // c2 = a * b
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < p; ++j) {
            c2[i][j] = a[i][0] * b[0][j] + 
                       a[i][1] * b[1][j] + 
                       a[i][2] * b[2][j] + 
                       a[i][3] * b[3][j];
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    printf("unroll: %f\n", (float) (end.tv_sec - start.tv_sec) + (float) (end.tv_nsec - start.tv_nsec) / 1000000000.0f);
    check_correctness("loop_unroll_matmul");
}

void simd_matmul(void) {
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    // c2 = a * b
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < p; j += 4) {
            __m128 sum = _mm_setzero_ps();  // 初始化为0
            for (int k = 0; k < 4; ++k) {
                __m128 a_val = _mm_set1_ps(a[i][k]);  // 将a[i][k]广播到128位寄存器的所有元素
                __m128 b_val = _mm_loadu_ps(&b[k][j]);  // 加载b[k][j:j+3]到寄存器
                sum = _mm_add_ps(sum, _mm_mul_ps(a_val, b_val));  // sum += a[i][k] * b[k][j:j+3]
            }
            _mm_storeu_ps(&c2[i][j], sum);  // 将结果存回c2[i][j:j+3]
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    printf("simd: %f\n", (float) (end.tv_sec - start.tv_sec) + (float) (end.tv_nsec - start.tv_nsec) / 1000000000.0f);
    check_correctness("simd_matmul");
}

void loop_unroll_simd_matmul(void) {
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    // c2 = a * b
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < p; j += 4) {
            __m128 a0 = _mm_set1_ps(a[i][0]);
            __m128 a1 = _mm_set1_ps(a[i][1]);
            __m128 a2 = _mm_set1_ps(a[i][2]);
            __m128 a3 = _mm_set1_ps(a[i][3]);
            
            __m128 b0 = _mm_loadu_ps(&b[0][j]);
            __m128 b1 = _mm_loadu_ps(&b[1][j]);
            __m128 b2 = _mm_loadu_ps(&b[2][j]);
            __m128 b3 = _mm_loadu_ps(&b[3][j]);
            
            __m128 sum = _mm_mul_ps(a0, b0);
            sum = _mm_add_ps(sum, _mm_mul_ps(a1, b1));
            sum = _mm_add_ps(sum, _mm_mul_ps(a2, b2));
            sum = _mm_add_ps(sum, _mm_mul_ps(a3, b3));
            
            _mm_storeu_ps(&c2[i][j], sum);
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    printf("unroll+simd: %f\n", (float) (end.tv_sec - start.tv_sec) + (float) (end.tv_nsec - start.tv_nsec) / 1000000000.0f);
    check_correctness("loop_unroll_simd_matmul");
}

void deallocate(){
    for (int i = 0; i < n; ++i) {
        free(a[i]);
        free(c[i]);
        free(c2[i]);

    }
    for (int i = 0; i < 4; ++i) {
        free(b[i]);
    }
    free(a);
    free(b);
    free(c);
    free(c2);
    a = NULL;
    b = NULL;
    c = NULL;
    c2 = NULL;
}

int main(void) {
    init();

    naive_matmul();
    simd_matmul();
    loop_unroll_matmul();
    loop_unroll_simd_matmul();

    deallocate();
    return 0;
}

