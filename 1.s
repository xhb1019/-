  .data

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

hex_chars: .asciiz "0123456789abcdef"
buffer: .space 64  # 512位缓冲区
padding: .byte 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
         .byte    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
         .byte    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
         .byte    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

  .text

# -----------------------------------------------------------------
# Function: md5
#
# Description:
#   Computes the MD5 hash of an input message using the MD5 algorithm.
#   The computed digest is stored in memory.
#
# Parameters:
#   a0 - Pointer to the beginning of the input message.
#   a1 - Length of the input message in bytes.
#   a2 - Pointer to a memory region where the resulting MD5 digest
#        will be stored.
# -----------------------------------------------------------------
  .globl md5
md5:
  # 保存寄存器
  addi sp, sp, -64
  sw ra, 60(sp)
  sw s0, 56(sp)
  sw s1, 52(sp)
  sw s2, 48(sp)
  sw s3, 44(sp)
  sw s4, 40(sp)
  sw s5, 36(sp)
  sw s6, 32(sp)
  sw s7, 28(sp)
  sw s8, 24(sp)
  sw s9, 20(sp)
  sw s10, 16(sp)
  sw s11, 12(sp)
  
  # 保存参数
  mv s0, a0    # 输入消息指针
  mv s1, a1    # 消息长度(字节)
  mv s2, a2    # 结果指针
  
  # 初始化哈希值
  la t0, initial_buffer
  lw s3, 0(t0)   # A
  lw s4, 4(t0)   # B
  lw s5, 8(t0)   # C
  lw s6, 12(t0)  # D
  
  # 初始化缓冲区
  la s7, buffer
  
  # 计算需要处理的块数
  addi t0, s1, 9     # 长度 + 1(0x80) + 8(长度信息)
  li t1, 64
  addi t0, t0, 63    # 取上限
  div t0, t0, t1     # 块数
  mv s8, t0          # 保存块数
  
  li s9, 0           # 当前处理的块索引
  li s10, 0          # 已处理的字节数
  
process_blocks:
  # 检查是否处理完所有块
  beq s9, s8, md5_done
  
  # 清空缓冲区
  li t0, 0
  li t1, 64
clear_buffer:
  sb zero, 0(s7)
  addi s7, s7, 1
  addi t0, t0, 1
  bne t0, t1, clear_buffer
  la s7, buffer  # 重置缓冲区指针
  
  # 计算当前块类型
  bge s10, s1, padding_block
  
  # 计算可以复制多少字节到当前块
  sub t0, s1, s10    # 剩余字节数
  li t1, 64
  min t0, t0, t1     # 取最小值
  
  # 复制数据到缓冲区
  mv t1, s0          # 源指针 + 偏移
  add t1, t1, s10
  mv t2, s7          # 目标指针
  li t3, 0           # 已复制的字节数
copy_data:
  beq t3, t0, copy_done
  lb t4, 0(t1)
  sb t4, 0(t2)
  addi t1, t1, 1
  addi t2, t2, 1
  addi t3, t3, 1
  j copy_data
  
copy_done:
  add s10, s10, t0   # 更新已处理的字节数
  
  # 检查这个块是否需要添加填充
  bne s10, s1, process_block
  
  # 添加0x80填充
  add t0, s7, t0
  li t1, 0x80
  sb t1, 0(t0)
  
  # 检查是否有足够空间添加长度
  addi t0, t0, 1     # 跳过0x80
  sub t1, s7, t0     # 剩余空间
  addi t1, t1, 64
  li t2, 8
  bge t1, t2, add_length
  j process_block    # 不够空间，先处理当前块
  
padding_block:
  # 检查是否是最后一个块
  addi t0, s8, -1
  bne s9, t0, process_block
  
  # 在最后8个字节添加长度(以位为单位)
  slli t0, s1, 3     # 长度(位) = 长度(字节) * 8
  addi t1, s7, 56    # 偏移到最后8个字节
  sw t0, 0(t1)       # 存储低32位
  sw zero, 4(t1)     # 高32位为0(假设长度不超过2^32-1)
  
add_length:
  # 在最后8个字节添加长度(以位为单位)
  slli t0, s1, 3     # 长度(位) = 长度(字节) * 8
  addi t1, s7, 56    # 偏移到最后8个字节
  sw t0, 0(t1)       # 存储低32位
  sw zero, 4(t1)     # 高32位为0(假设长度不超过2^32-1)
  
process_block:
  # 保存原始哈希值
  mv t0, s3    # A
  mv t1, s4    # B
  mv t2, s5    # C
  mv t3, s6    # D
  
  # 进行64轮转换操作
  li s11, 0    # 轮次索引
  
md5_loop:
  li t4, 64
  bge s11, t4, md5_loop_done
  
  # 确定使用哪个函数和消息索引
  li t4, 16
  bge s11, t4, check_second_round
  
  # 第一轮: F(x,y,z) = (x & y) | (~x & z)
  and t4, s4, s5
  not t5, s4
  and t5, t5, s6
  or t4, t4, t5
  
  # g = i
  mv t5, s11
  j process_round
  
check_second_round:
  li t4, 32
  bge s11, t4, check_third_round
  
  # 第二轮: G(x,y,z) = (x & z) | (y & ~z)
  and t4, s4, s6
  not t5, s6
  and t5, s5, t5
  or t4, t4, t5
  
  # g = (5*i + 1) % 16
  li t5, 5
  mul t5, t5, s11
  addi t5, t5, 1
  li t6, 16
  rem t5, t5, t6
  j process_round
  
check_third_round:
  li t4, 48
  bge s11, t4, fourth_round
  
  # 第三轮: H(x,y,z) = x ^ y ^ z
  xor t4, s4, s5
  xor t4, t4, s6
  
  # g = (3*i + 5) % 16
  li t5, 3
  mul t5, t5, s11
  addi t5, t5, 5
  li t6, 16
  rem t5, t5, t6
  j process_round
  
fourth_round:
  # 第四轮: I(x,y,z) = y ^ (x | ~z)
  not t4, s6
  or t4, s4, t4
  xor t4, s5, t4
  
  # g = (7*i) % 16
  li t5, 7
  mul t5, t5, s11
  li t6, 16
  rem t5, t5, t6
  
process_round:
  # 获取K[i]
  la t6, K
  slli t7, s11, 2    # i * 4
  add t6, t6, t7
  lw t6, 0(t6)       # K[i]
  
  # 获取S[i]
  la t7, S
  slli t8, s11, 2    # i * 4
  add t7, t7, t8
  lw t7, 0(t7)       # S[i]
  
  # 获取M[g]
  slli t8, t5, 2     # g * 4
  add t8, s7, t8
  lw t8, 0(t8)       # M[g]
  
  # F = F + A + K[i] + M[g]
  add t4, t4, s3
  add t4, t4, t6
  add t4, t4, t8
  
  # 循环左移
  sll t6, t4, t7
  li t8, 32
  sub t8, t8, t7
  srl t7, t4, t8
  or t4, t6, t7
  
  # 更新值
  add t4, t4, s4
  mv s3, s6
  mv s6, s5
  mv s5, s4
  mv s4, t4
  
  # 继续下一轮
  addi s11, s11, 1
  j md5_loop
  
md5_loop_done:
  # 更新哈希值
  add s3, s3, t0
  add s4, s4, t1
  add s5, s5, t2
  add s6, s6, t3
  
  # 处理下一个块
  addi s9, s9, 1
  j process_blocks
  
md5_done:
  # 存储最终哈希值
  sw s3, 0(s2)
  sw s4, 4(s2)
  sw s5, 8(s2)
  sw s6, 12(s2)
  
  # 恢复寄存器
  lw ra, 60(sp)
  lw s0, 56(sp)
  lw s1, 52(sp)
  lw s2, 48(sp)
  lw s3, 44(sp)
  lw s4, 40(sp)
  lw s5, 36(sp)
  lw s6, 32(sp)
  lw s7, 28(sp)
  lw s8, 24(sp)
  lw s9, 20(sp)
  lw s10, 16(sp)
  lw s11, 12(sp)
  addi sp, sp, 64
  
  ret

# -----------------------------------------------------------------
# Function: print_message_digest
#
# Description:
#   Prints the 16-byte MD5 message digest in a human-readable hexadecimal format.
#   Each byte of the digest is converted to its two-digit hexadecimal representation,
#   resulting in a 32-character string that represents the hash.
#
# Parameters:
#   a0 - Pointer to the MD5 digest.
# -----------------------------------------------------------------
  .globl print_message_digest
print_message_digest:
  # 保存寄存器
  addi sp, sp, -32
  sw ra, 28(sp)
  sw s0, 24(sp)
  sw s1, 20(sp)
  sw s2, 16(sp)
  sw s3, 12(sp)
  sw s4, 8(sp)
  
  # 保存参数
  mv s0, a0          # 消息摘要指针
  li s1, 0           # 字节索引
  la s3, hex_chars   # 16进制字符表
  
print_digest_loop:
  li t0, 16          # MD5摘要总共16字节
  beq s1, t0, print_digest_done
  
  # 获取当前字节
  add t1, s0, s1
  lb s2, 0(t1)
  
  # 打印高4位
  srli t2, s2, 4     # 获取高4位
  andi t2, t2, 0xF
  add t3, s3, t2     # 获取对应的16进制字符
  lb a0, 0(t3)
  
  # 打印字符
  li a7, 11          # 打印字符的系统调用
  ecall
  
  # 打印低4位
  andi t2, s2, 0xF   # 获取低4位
  add t3, s3, t2     # 获取对应的16进制字符
  lb a0, 0(t3)
  
  # 打印字符
  li a7, 11          # 打印字符的系统调用
  ecall
  
  # 继续下一个字节
  addi s1, s1, 1
  j print_digest_loop
  
print_digest_done:
  # 打印换行
  li a0, 10          # 换行符
  li a7, 11          # 打印字符的系统调用
  ecall
  
  # 恢复寄存器
  lw ra, 28(sp)
  lw s0, 24(sp)
  lw s1, 20(sp)
  lw s2, 16(sp)
  lw s3, 12(sp)
  lw s4, 8(sp)
  addi sp, sp, 32
  
  ret
