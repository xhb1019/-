  .data

# Length of Input Message
# A 32-bit integer specifying the exact number of bytes in 'message'.
  .globl length_of_input_message
length_of_input_message:
  .word 6

# Input Message
# ASCII string to be processed by the MD5 hash function.
# Ensure the length matches the integer specified above (excluding the null terminator).
  .globl message
message:
  .asciiz "CS110P"

# Message digest
md:
  .word 0, 0, 0, 0

# Initial buffer value
initial_buffer:
  .word 0x67452301 # A
  .word 0xefcdab89 # B
  .word 0x98badcfe # C
  .word 0x10325476 # D

# 64-element table constructed from the sine function.
K:
  .word 0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee
  .word 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501
  .word 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be
  .word 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821
  .word 0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa
  .word 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8
  .word 0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed
  .word 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a
  .word 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c
  .word 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70
  .word 0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05
  .word 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665
  .word 0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039
  .word 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1
  .word 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1
  .word 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391

# Per-round shift amounts
S:
  .word 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22
  .word 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20
  .word 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23
  .word 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21

  .text
  .globl main

main:
  la a0, message
  lw a1, length_of_input_message
  la a2, md
  jal ra, md5
  
  la a0, md
  jal ra, print_message_digest

  add a1, x0, x0
  addi a0, x0, 17
  ecall

  .globl md5
md5:
  addi sp, sp, -96
  sw ra, 92(sp)
  sw s0, 88(sp)
  sw s1, 84(sp)
  sw s2, 80(sp)
  sw s3, 76(sp)
  sw s4, 72(sp)
  sw s5, 68(sp)
  sw s6, 64(sp)
  sw s7, 60(sp)
  sw s8, 56(sp)
  sw s9, 52(sp)
  sw s10, 48(sp)
  sw s11, 44(sp)
  
  mv s0, a0        # 消息指针
  mv s1, a1        # 消息长度
  mv s2, a2        # 输出缓冲区
  
  addi s3, sp, 0   # 消息块缓冲区
  jal ra, prepare_message
  
  # 初始化MD缓冲区
  la t0, initial_buffer
  lw s4, 0(t0)     # A
  lw s5, 4(t0)     # B
  lw s6, 8(t0)     # C
  lw s7, 12(t0)    # D
  
  # 处理每个512位块
  li t0, 0
md5_process_blocks:
  addi t1, sp, 0   # 当前块指针
  
  # 保存初始缓冲区值
  mv s8, s4        # AA = A
  mv s9, s5        # BB = B
  mv s10, s6       # CC = C
  mv s11, s7       # DD = D
  
  # 第一轮
  li t2, 0         # i = 0
round1_loop:
  li t3, 16
  bge t2, t3, round1_end
  
  # F = (B & C) | (~B & D)
  and t3, s5, s6
  not t4, s5
  and t4, t4, s7
  or t3, t3, t4
  
  # 计算索引: M[i]
  slli t4, t2, 2
  add t4, t4, t1
  lw t5, 0(t4)     # M[i]
  
  # 计算: A + F(B,C,D) + M[i] + K[i]
  add t6, s4, t3
  add t6, t6, t5
  
  # 获取K[i]
  la t3, K
  slli t4, t2, 2
  add t3, t3, t4
  lw t3, 0(t3)
  add t6, t6, t3
  
  # 获取S[i]
  la t3, S
  slli t4, t2, 2
  add t3, t3, t4
  lw t3, 0(t3)
  
  # 循环左移
  sll t4, t6, t3
  li t5, 32
  sub t5, t5, t3
  srl t5, t6, t5
  or t4, t4, t5
  
  # 加B
  add t4, t4, s5
  
  # 更新ABCD
  mv s4, s7
  mv s7, s6
  mv s6, s5
  mv s5, t4
  
  addi t2, t2, 1
  j round1_loop
round1_end:

  # 第二轮
  li t2, 0
round2_loop:
  li t3, 16
  bge t2, t3, round2_end
  
  # G = (B & D) | (C & ~D)
  and t3, s5, s7
  not t4, s7
  and t4, s6, t4
  or t3, t3, t4
  
  # 计算索引: M[(5*i + 1) % 16]
  li t4, 5
  mul t4, t4, t2
  addi t4, t4, 1
  li t5, 16
  rem t4, t4, t5
  slli t4, t4, 2
  add t4, t4, t1
  lw t5, 0(t4)
  
  # 计算: A + G(B,C,D) + M[idx] + K[i+16]
  add t6, s4, t3
  add t6, t6, t5
  
  # 获取K[i+16]
  la t3, K
  addi t4, t2, 16
  slli t4, t4, 2
  add t3, t3, t4
  lw t3, 0(t3)
  add t6, t6, t3
  
  # 获取S[i+16]
  la t3, S
  addi t4, t2, 16
  slli t4, t4, 2
  add t3, t3, t4
  lw t3, 0(t3)
  
  # 循环左移
  sll t4, t6, t3
  li t5, 32
  sub t5, t5, t3
  srl t5, t6, t5
  or t4, t4, t5
  
  # 加B
  add t4, t4, s5
  
  # 更新ABCD
  mv s4, s7
  mv s7, s6
  mv s6, s5
  mv s5, t4
  
  addi t2, t2, 1
  j round2_loop
round2_end:

  # 第三轮
  li t2, 0
round3_loop:
  li t3, 16
  bge t2, t3, round3_end
  
  # H = B ^ C ^ D
  xor t3, s5, s6
  xor t3, t3, s7
  
  # 计算索引: M[(3*i + 5) % 16]
  li t4, 3
  mul t4, t4, t2
  addi t4, t4, 5
  li t5, 16
  rem t4, t4, t5
  slli t4, t4, 2
  add t4, t4, t1
  lw t5, 0(t4)
  
  # 计算: A + H(B,C,D) + M[idx] + K[i+32]
  add t6, s4, t3
  add t6, t6, t5
  
  # 获取K[i+32]
  la t3, K
  addi t4, t2, 32
  slli t4, t4, 2
  add t3, t3, t4
  lw t3, 0(t3)
  add t6, t6, t3
  
  # 获取S[i+32]
  la t3, S
  addi t4, t2, 32
  slli t4, t4, 2
  add t3, t3, t4
  lw t3, 0(t3)
  
  # 循环左移
  sll t4, t6, t3
  li t5, 32
  sub t5, t5, t3
  srl t5, t6, t5
  or t4, t4, t5
  
  # 加B
  add t4, t4, s5
  
  # 更新ABCD
  mv s4, s7
  mv s7, s6
  mv s6, s5
  mv s5, t4
  
  addi t2, t2, 1
  j round3_loop
round3_end:

  # 第四轮
  li t2, 0
round4_loop:
  li t3, 16
  bge t2, t3, round4_end
  
  # I = C ^ (B | ~D)
  not t3, s7
  or t3, s5, t3
  xor t3, s6, t3
  
  # 计算索引: M[(7*i) % 16]
  li t4, 7
  mul t4, t4, t2
  li t5, 16
  rem t4, t4, t5
  slli t4, t4, 2
  add t4, t4, t1
  lw t5, 0(t4)
  
  # 计算: A + I(B,C,D) + M[idx] + K[i+48]
  add t6, s4, t3
  add t6, t6, t5
  
  # 获取K[i+48]
  la t3, K
  addi t4, t2, 48
  slli t4, t4, 2
  add t3, t3, t4
  lw t3, 0(t3)
  add t6, t6, t3
  
  # 获取S[i+48]
  la t3, S
  addi t4, t2, 48
  slli t4, t4, 2
  add t3, t3, t4
  lw t3, 0(t3)
  
  # 循环左移
  sll t4, t6, t3
  li t5, 32
  sub t5, t5, t3
  srl t5, t6, t5
  or t4, t4, t5
  
  # 加B
  add t4, t4, s5
  
  # 更新ABCD
  mv s4, s7
  mv s7, s6
  mv s6, s5
  mv s5, t4
  
  addi t2, t2, 1
  j round4_loop
round4_end:

  # 更新缓冲区最终值
  add s4, s4, s8
  add s5, s5, s9
  add s6, s6, s10
  add s7, s7, s11
  
  addi t0, t0, 1
  li t1, 1
  blt t0, t1, md5_process_blocks
  
  # 保存最终摘要
  sw s4, 0(s2)
  sw s5, 4(s2)
  sw s6, 8(s2)
  sw s7, 12(s2)
  
  lw ra, 92(sp)
  lw s0, 88(sp)
  lw s1, 84(sp)
  lw s2, 80(sp)
  lw s3, 76(sp)
  lw s4, 72(sp)
  lw s5, 68(sp)
  lw s6, 64(sp)
  lw s7, 60(sp)
  lw s8, 56(sp)
  lw s9, 52(sp)
  lw s10, 48(sp)
  lw s11, 44(sp)
  addi sp, sp, 96
  ret

prepare_message:
  addi sp, sp, -16
  sw ra, 12(sp)
  sw s0, 8(sp)
  sw s1, 4(sp)
  sw s2, 0(sp)
  
  # 复制原始消息
  li t0, 0
copy_loop:
  bge t0, s1, copy_done
  add t1, s0, t0
  lb t1, 0(t1)
  add t2, s3, t0
  sb t1, 0(t2)
  addi t0, t0, 1
  j copy_loop
copy_done:

  # 添加单个1位
  add t1, s3, s1
  li t2, 0x80
  sb t2, 0(t1)
  addi t0, s1, 1
  
  # 添加0位直到长度达到56字节
  li t1, 56
  bge t0, t1, need_extra_block
  j padding_zeros
  
need_extra_block:
  li t1, 64
  sub t2, t1, t0
  add t3, s3, t0
  
zero_first_block:
  beqz t2, set_length
  sb zero, 0(t3)
  addi t3, t3, 1
  addi t0, t0, 1
  addi t2, t2, -1
  j zero_first_block
  
padding_zeros:
  li t1, 56
  sub t2, t1, t0
  add t3, s3, t0
  
zero_pad_loop:
  beqz t2, set_length
  sb zero, 0(t3)
  addi t3, t3, 1
  addi t2, t2, -1
  j zero_pad_loop
  
set_length:
  # 设置长度（小端序）
  slli t0, s1, 3        # 长度(比特)
  addi t1, s3, 56       # 最后8字节的位置
  
  # 存储64位长度
  sb t0, 0(t1)
  srli t0, t0, 8
  sb t0, 1(t1)
  srli t0, t0, 8
  sb t0, 2(t1)
  srli t0, t0, 8
  sb t0, 3(t1)
  
  # 高32位全为0
  sb zero, 4(t1)
  sb zero, 5(t1)
  sb zero, 6(t1)
  sb zero, 7(t1)
  
  # 将字节转换为小端序的字
  li t0, 0
byte_to_word_loop:
  li t1, 16
  bge t0, t1, prepare_done
  
  # 获取四个字节
  slli t1, t0, 2
  add t1, t1, s3
  lb t2, 0(t1)
  lb t3, 1(t1)
  lb t4, 2(t1)
  lb t5, 3(t1)
  
  # 确保字节为无符号
  andi t2, t2, 0xff
  andi t3, t3, 0xff
  andi t4, t4, 0xff
  andi t5, t5, 0xff
  
  # 组合为32位字（小端序）
  slli t3, t3, 8
  slli t4, t4, 16
  slli t5, t5, 24
  or t2, t2, t3
  or t2, t2, t4
  or t2, t2, t5
  
  # 存储字
  sw t2, 0(t1)
  
  addi t0, t0, 1
  j byte_to_word_loop
  
prepare_done:
  lw ra, 12(sp)
  lw s0, 8(sp)
  lw s1, 4(sp)
  lw s2, 0(sp)
  addi sp, sp, 16
  ret

  .globl print_message_digest
print_message_digest:
  addi sp, sp, -16
  sw ra, 12(sp)
  sw s0, 8(sp)
  sw s1, 4(sp)
  
  mv s0, a0    # 摘要指针
  li s1, 0     # 字节计数器
  
print_loop:
  li t0, 16
  bge s1, t0, print_done
  
  # 加载当前字节
  add t1, s0, s1
  lb t1, 0(t1)
  andi t1, t1, 0xff
  
  # 提取高4位和低4位
  srli t2, t1, 4
  andi t3, t1, 0xf
  
  # 将高4位转换为十六进制字符
  li t0, 10
  blt t2, t0, high_digit
  addi t2, t2, 87    # 'a'-10
  j print_high
high_digit:
  addi t2, t2, 48    # '0'
print_high:
  li a0, 11
  mv a1, t2
  ecall
  
  # 将低4位转换为十六进制字符
  li t0, 10
  blt t3, t0, low_digit
  addi t3, t3, 87    # 'a'-10
  j print_low
low_digit:
  addi t3, t3, 48    # '0'
print_low:
  li a0, 11
  mv a1, t3
  ecall
  
  addi s1, s1, 1
  j print_loop
  
print_done:
  lw ra, 12(sp)
  lw s0, 8(sp)
  lw s1, 4(sp)
  addi sp, sp, 16
  ret
