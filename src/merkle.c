#include "mercha.h"
#include <immintrin.h>
#include <omp.h>

// SIMD优化的merge_hash函数
void merge_hash(const uint8_t block1[64], 
               const uint8_t block2[64],
               uint8_t output[64]) {

    uint32_t state[16] = {0};
    
    const uint32_t *w1 = (const uint32_t*)block1;
    const uint32_t *w2 = (const uint32_t*)block2;
    
    // 使用SIMD指令加载和处理数据
    __m128i b1_0 = _mm_loadu_si128((__m128i*)&w1[0]);
    __m128i b1_1 = _mm_loadu_si128((__m128i*)&w1[4]);
    __m128i b2_0 = _mm_loadu_si128((__m128i*)&w2[0]);
    __m128i b2_1 = _mm_loadu_si128((__m128i*)&w2[4]);
    
    // 反转并XOR
    __m128i b2_0_rev = _mm_shuffle_epi32(b2_0, _MM_SHUFFLE(0, 1, 2, 3));
    __m128i b2_1_rev = _mm_shuffle_epi32(b2_1, _MM_SHUFFLE(0, 1, 2, 3));
    __m128i b1_0_rev = _mm_shuffle_epi32(b1_0, _MM_SHUFFLE(0, 1, 2, 3));
    __m128i b1_1_rev = _mm_shuffle_epi32(b1_1, _MM_SHUFFLE(0, 1, 2, 3));
    
    __m128i s0 = _mm_xor_si128(b1_0, b2_1_rev);
    __m128i s1 = _mm_xor_si128(b1_1, b2_0_rev);
    __m128i s2 = _mm_xor_si128(b2_0, b1_1_rev);
    __m128i s3 = _mm_xor_si128(b2_1, b1_0_rev);
    
    _mm_storeu_si128((__m128i*)&state[0], s0);
    _mm_storeu_si128((__m128i*)&state[4], s1);
    _mm_storeu_si128((__m128i*)&state[8], s2);
    _mm_storeu_si128((__m128i*)&state[12], s3);
    
    // 执行10轮混合
    for (int round = 0; round < 10; ++round) {
        // 第一阶段混合
        __m128i st0 = _mm_loadu_si128((__m128i*)&state[0]);
        __m128i st1 = _mm_loadu_si128((__m128i*)&state[4]);
        __m128i st2 = _mm_loadu_si128((__m128i*)&state[8]);
        __m128i st3 = _mm_loadu_si128((__m128i*)&state[12]);
        
        st0 = _mm_add_epi32(st0, st1);
        st0 = _mm_or_si128(_mm_slli_epi32(st0, 7), _mm_srli_epi32(st0, 25));
        
        st2 = _mm_add_epi32(st2, st3);
        st2 = _mm_or_si128(_mm_slli_epi32(st2, 7), _mm_srli_epi32(st2, 25));
        
        _mm_storeu_si128((__m128i*)&state[0], st0);
        _mm_storeu_si128((__m128i*)&state[8], st2);
        
        // 第二阶段混合
        st0 = _mm_loadu_si128((__m128i*)&state[0]);
        st1 = _mm_loadu_si128((__m128i*)&state[8]);
        st2 = _mm_loadu_si128((__m128i*)&state[4]);
        st3 = _mm_loadu_si128((__m128i*)&state[12]);
        
        st0 = _mm_add_epi32(st0, st1);
        st0 = _mm_or_si128(_mm_slli_epi32(st0, 9), _mm_srli_epi32(st0, 23));
        
        st2 = _mm_add_epi32(st2, st3);
        st2 = _mm_or_si128(_mm_slli_epi32(st2, 9), _mm_srli_epi32(st2, 23));
        
        _mm_storeu_si128((__m128i*)&state[0], st0);
        _mm_storeu_si128((__m128i*)&state[4], st2);
    }
    
    // 最终加和阶段
    __m128i st0 = _mm_loadu_si128((__m128i*)&state[0]);
    __m128i st1 = _mm_loadu_si128((__m128i*)&state[4]);
    __m128i st2 = _mm_loadu_si128((__m128i*)&state[8]);
    __m128i st3 = _mm_loadu_si128((__m128i*)&state[12]);
    
    // 反转并相加
    __m128i st3_rev = _mm_shuffle_epi32(st3, _MM_SHUFFLE(0, 1, 2, 3));
    __m128i st2_rev = _mm_shuffle_epi32(st2, _MM_SHUFFLE(0, 1, 2, 3));
    
    st0 = _mm_add_epi32(st0, st3_rev);
    st1 = _mm_add_epi32(st1, st2_rev);
    
    _mm_storeu_si128((__m128i*)&state[0], st0);
    _mm_storeu_si128((__m128i*)&state[4], st1);
    
    // 复制结果到输出
    memcpy(output, state, 64);
}

// 缓存优化的Merkle树实现
void merkel_tree(const uint8_t *input, uint8_t *output, size_t length) {
    // 确保长度是64的倍数
    size_t aligned_length = length;
    if (aligned_length % 64 != 0) {
        aligned_length = (aligned_length / 64 + 1) * 64;
    }
    
    uint8_t *cur_buf = malloc(aligned_length);
    uint8_t *prev_buf = malloc(aligned_length);
    
    // 将输入数据复制到prev_buf
    memcpy(prev_buf, input, length);
    if (length < aligned_length) {
        memset(prev_buf + length, 0, aligned_length - length);
    }
    
    length /= 2;
    
    while (length >= 64) {
        const size_t num_pairs = length / 64;
        
        // 使用OpenMP并行处理merge_hash
        #pragma omp parallel for
        for (size_t i = 0; i < num_pairs; ++i) {
            merge_hash(prev_buf + (2*i)*64, prev_buf + (2*i+1)*64, cur_buf + i*64);
        }
        
        length /= 2;
        
        // 交换缓冲区
        uint8_t *tmp = cur_buf;
        cur_buf = prev_buf;
        prev_buf = tmp;
    }
    
    // 如果只剩一个节点，直接复制到输出
    memcpy(output, prev_buf, 64);
    
    free(cur_buf);
    free(prev_buf);
}
