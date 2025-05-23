#include "mercha.h"
#include <immintrin.h>
#include <omp.h>

static void chacha_quarter_round(uint32_t x[16], size_t a, size_t b, size_t c, size_t d) {
    x[a] = x[a] + x[b]; x[d] = ROTL32(x[d] ^ x[a], 16);
    x[c] = x[c] + x[d]; x[b] = ROTL32(x[b] ^ x[c], 12);
    x[a] = x[a] + x[b]; x[d] = ROTL32(x[d] ^ x[a], 8);
    x[c] = x[c] + x[d]; x[b] = ROTL32(x[b] ^ x[c], 7);
}

static void chacha20_block(uint32_t state[16], uint8_t out[64]) {
    
    uint32_t working_state[16];
    memcpy(working_state, state, 64);

    for (int i = 0; i < 10; i++) {
        chacha_quarter_round(working_state, 0, 4, 8, 12);
        chacha_quarter_round(working_state, 1, 5, 9, 13);
        chacha_quarter_round(working_state, 2, 6, 10, 14);
        chacha_quarter_round(working_state, 3, 7, 11, 15);
        
        chacha_quarter_round(working_state, 0, 5, 10, 15);
        chacha_quarter_round(working_state, 1, 6, 11, 12);
        chacha_quarter_round(working_state, 2, 7, 8, 13);
        chacha_quarter_round(working_state, 3, 4, 9, 14);
    }

    for (int i = 0; i < 16; i++) {
        working_state[i] += state[i];
    }

    for (int i = 0; i < 16; i++) {
        out[i*4 + 0] = (uint8_t)(working_state[i] >> 0);
        out[i*4 + 1] = (uint8_t)(working_state[i] >> 8);
        out[i*4 + 2] = (uint8_t)(working_state[i] >> 16);
        out[i*4 + 3] = (uint8_t)(working_state[i] >> 24);
    }
}

// 我们不再使用这个函数，但保留SIMD优化代码参考
#if 0
static inline void chacha_simd_quarter_round_x4(__m128i* a, __m128i* b, __m128i* c, __m128i* d) {
    *a = _mm_add_epi32(*a, *b);
    *d = _mm_xor_si128(*d, *a);
    *d = _mm_or_si128(_mm_slli_epi32(*d, 16), _mm_srli_epi32(*d, 16));
    
    *c = _mm_add_epi32(*c, *d);
    *b = _mm_xor_si128(*b, *c);
    *b = _mm_or_si128(_mm_slli_epi32(*b, 12), _mm_srli_epi32(*b, 20));
    
    *a = _mm_add_epi32(*a, *b);
    *d = _mm_xor_si128(*d, *a);
    *d = _mm_or_si128(_mm_slli_epi32(*d, 8), _mm_srli_epi32(*d, 24));
    
    *c = _mm_add_epi32(*c, *d);
    *b = _mm_xor_si128(*b, *c);
    *b = _mm_or_si128(_mm_slli_epi32(*b, 7), _mm_srli_epi32(*b, 25));
}

static void chacha20_blocks_simd(uint32_t state[16], uint8_t* output, size_t num_blocks) {
    __m128i state0 = _mm_loadu_si128((__m128i*)&state[0]);
    __m128i state1 = _mm_loadu_si128((__m128i*)&state[4]);
    __m128i state2 = _mm_loadu_si128((__m128i*)&state[8]);
    __m128i state3 = _mm_loadu_si128((__m128i*)&state[12]);
    
    for (size_t b = 0; b < num_blocks; b++) {
        __m128i x0 = state0;
        __m128i x1 = state1;
        __m128i x2 = state2;
        __m128i x3 = state3;
        
        if (b > 0) {
            __m128i inc = _mm_set_epi32(0, 0, 0, b);
            x3 = _mm_add_epi32(x3, inc);
        }
        
        for (int i = 0; i < 10; i++) {
            chacha_simd_quarter_round_x4(&x0, &x1, &x2, &x3);
            
            x1 = _mm_shuffle_epi32(x1, _MM_SHUFFLE(0, 3, 2, 1));
            x2 = _mm_shuffle_epi32(x2, _MM_SHUFFLE(1, 0, 3, 2));
            x3 = _mm_shuffle_epi32(x3, _MM_SHUFFLE(2, 1, 0, 3));
            
            chacha_simd_quarter_round_x4(&x0, &x1, &x2, &x3);
            
            x1 = _mm_shuffle_epi32(x1, _MM_SHUFFLE(2, 1, 0, 3));
            x2 = _mm_shuffle_epi32(x2, _MM_SHUFFLE(1, 0, 3, 2));
            x3 = _mm_shuffle_epi32(x3, _MM_SHUFFLE(0, 3, 2, 1));
        }
        
        x0 = _mm_add_epi32(x0, state0);
        x1 = _mm_add_epi32(x1, state1);
        x2 = _mm_add_epi32(x2, state2);
        x3 = _mm_add_epi32(x3, state3);
        
        _mm_storeu_si128((__m128i*)(output + b*64 + 0), x0);
        _mm_storeu_si128((__m128i*)(output + b*64 + 16), x1);
        _mm_storeu_si128((__m128i*)(output + b*64 + 32), x2);
        _mm_storeu_si128((__m128i*)(output + b*64 + 48), x3);
    }
}
#endif

void chacha20_encrypt(const uint8_t key[32], const uint8_t nonce[12], uint32_t initial_counter, uint8_t *buffer, size_t length) {
    uint32_t key_words[8];
    uint32_t nonce_words[3];

    for (int i = 0; i < 8; i++) {
        key_words[i] = (uint32_t)key[i*4 + 0]      |
                      ((uint32_t)key[i*4 + 1] << 8)  |
                      ((uint32_t)key[i*4 + 2] << 16) |
                      ((uint32_t)key[i*4 + 3] << 24);
    }

    for (int i = 0; i < 3; i++) {
        nonce_words[i] = (uint32_t)nonce[i*4 + 0]      |
                        ((uint32_t)nonce[i*4 + 1] << 8)  |
                        ((uint32_t)nonce[i*4 + 2] << 16) |
                        ((uint32_t)nonce[i*4 + 3] << 24);
    }

    uint32_t state[16] = {
        0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,             
        key_words[0], key_words[1], key_words[2], key_words[3],     
        key_words[4], key_words[5], key_words[6], key_words[7],     
        initial_counter,                                            
        nonce_words[0], nonce_words[1], nonce_words[2]              
    };

    if (length >= 256) {
        const size_t block_size = 64;
        const size_t num_blocks = (length + block_size - 1) / block_size;
        
        uint8_t *keystream = (uint8_t*)malloc(num_blocks * block_size);
        
        #pragma omp parallel
        {
            #pragma omp for schedule(dynamic)
            for (size_t block = 0; block < num_blocks; block++) {
                uint32_t local_state[16];
                memcpy(local_state, state, sizeof(local_state));
                local_state[12] += block;
                
                chacha20_block(local_state, keystream + block * block_size);
            }
            
            #pragma omp for schedule(dynamic)
            for (size_t i = 0; i < length; i++) {
                buffer[i] ^= keystream[i];
            }
        }
        
        free(keystream);
    } else {
        uint8_t key_stream[64];
        size_t offset = 0;

        while (length > 0) {
            chacha20_block(state, key_stream);
            size_t block_size = length < 64 ? length : 64;
            
            for (size_t i = 0; i < block_size; i += 8) {
                if (i + 8 <= block_size) {
                    buffer[offset + i]   ^= key_stream[i];
                    buffer[offset + i+1] ^= key_stream[i+1];
                    buffer[offset + i+2] ^= key_stream[i+2];
                    buffer[offset + i+3] ^= key_stream[i+3];
                    buffer[offset + i+4] ^= key_stream[i+4];
                    buffer[offset + i+5] ^= key_stream[i+5];
                    buffer[offset + i+6] ^= key_stream[i+6];
                    buffer[offset + i+7] ^= key_stream[i+7];
                } else {
                    for (size_t j = i; j < block_size; j++) {
                        buffer[offset + j] ^= key_stream[j];
                    }
                    break;
                }
            }

            offset += block_size;
            length -= block_size;
            state[12]++;
        }
    }
}
