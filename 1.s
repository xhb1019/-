.data
initial_buffer:
  .word 0x67452301
  .word 0xefcdab89
  .word 0x98badcfe
  .word 0x10325476
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
S:
  .word 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22
  .word 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20
  .word 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23
  .word 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
message_buffer:
  .zero 64

.text
.globl md5
md5:
  addi sp, sp, -24
  sw ra, 20(sp)
  sw s0, 16(sp)
  sw s1, 12(sp)
  sw s2, 8(sp)
  sw s4, 4(sp)
  sw s5, 0(sp)
  
  mv s0, a0        
  mv s1, a1        
  mv s2, a2        
  
  la t6, message_buffer
  mv a0, s0
  mv a1, s1
  mv a2, t6
  jal ra, prepare_message
  
  la t0, initial_buffer
  lw s4, 0(t0)     
  lw s5, 4(t0)     
  lw t0, 8(t0)     
  lw t1, 12(t0)    
  
  la t2, message_buffer   
  
  mv a6, s4        
  mv a7, s5       
  mv a4, t0     
  mv a5, t1      

  li t3, 0      
round1_loop:
  li t6, 16
  bge t3, t6, round1_end
  
  and t6, s5, t0
  not a0, s5
  and a0, a0, t1
  or t6, t6, a0
  
  slli a0, t3, 2
  add a0, a0, t2
  lw a1, 0(a0)    
  
  add a2, s4, t6
  add a2, a2, a1

  la a0, K
  slli a1, t3, 2
  add a0, a0, a1
  lw a0, 0(a0)
  add a2, a2, a0
  
  la a0, S
  slli a1, t3, 2
  add a0, a0, a1
  lw a0, 0(a0)
  
  sll a1, a2, a0
  li a3, 32
  sub a3, a3, a0
  srl a3, a2, a3
  or a1, a1, a3
  
  add a1, a1, s5
  
  mv s4, t1
  mv t1, t0
  mv t0, s5
  mv s5, a1
  
  addi t3, t3, 1
  j round1_loop
round1_end:

  li t3, 0
round2_loop:
  li t6, 16
  bge t3, t6, round2_end
  
  and t6, s5, t1
  not a0, t1
  and a0, t0, a0
  or t6, t6, a0

  li a0, 5
  mul a0, a0, t3
  addi a0, a0, 1
  li a1, 16
  rem a0, a0, a1
  slli a0, a0, 2
  add a0, a0, t2
  lw a1, 0(a0)
  
  add a2, s4, t6
  add a2, a2, a1
  
  la a0, K
  addi a1, t3, 16
  slli a1, a1, 2
  add a0, a0, a1
  lw a0, 0(a0)
  add a2, a2, a0
  
  la a0, S
  addi a1, t3, 16
  slli a1, a1, 2
  add a0, a0, a1
  lw a0, 0(a0)
  
  sll a1, a2, a0
  li a3, 32
  sub a3, a3, a0
  srl a3, a2, a3
  or a1, a1, a3
  
  add a1, a1, s5
  
  mv s4, t1
  mv t1, t0
  mv t0, s5
  mv s5, a1
  
  addi t3, t3, 1
  j round2_loop
round2_end:

  li t3, 0
round3_loop:
  li t6, 16
  bge t3, t6, round3_end
  
  xor t6, s5, t0
  xor t6, t6, t1

  li a0, 3
  mul a0, a0, t3
  addi a0, a0, 5
  li a1, 16
  rem a0, a0, a1
  slli a0, a0, 2
  add a0, a0, t2
  lw a1, 0(a0)
  
  add a2, s4, t6
  add a2, a2, a1
  
  la a0, K
  addi a1, t3, 32
  slli a1, a1, 2
  add a0, a0, a1
  lw a0, 0(a0)
  add a2, a2, a0
  
  la a0, S
  addi a1, t3, 32
  slli a1, a1, 2
  add a0, a0, a1
  lw a0, 0(a0)
  
  sll a1, a2, a0
  li a3, 32
  sub a3, a3, a0
  srl a3, a2, a3
  or a1, a1, a3
  
  add a1, a1, s5
  
  mv s4, t1
  mv t1, t0
  mv t0, s5
  mv s5, a1
  
  addi t3, t3, 1
  j round3_loop
round3_end:

  li t3, 0
round4_loop:
  li t6, 16
  bge t3, t6, round4_end
  
  not a0, t1
  or a0, s5, a0
  xor t6, t0, a0
  
  li a0, 7
  mul a0, a0, t3
  li a1, 16
  rem a0, a0, a1
  slli a0, a0, 2
  add a0, a0, t2
  lw a1, 0(a0)
  
  add a2, s4, t6
  add a2, a2, a1
  
  la a0, K
  addi a1, t3, 48
  slli a1, a1, 2
  add a0, a0, a1
  lw a0, 0(a0)
  add a2, a2, a0
  
  la a0, S
  addi a1, t3, 48
  slli a1, a1, 2
  add a0, a0, a1
  lw a0, 0(a0)
  
  sll a1, a2, a0
  li a3, 32
  sub a3, a3, a0
  srl a3, a2, a3
  or a1, a1, a3
  
  add a1, a1, s5
  
  mv s4, t1
  mv t1, t0
  mv t0, s5
  mv s5, a1
  
  addi t3, t3, 1
  j round4_loop
round4_end:

  add s4, s4, a6
  add s5, s5, a7
  add t0, t0, a4
  add t1, t1, a5
  
  sw s4, 0(s2)
  sw s5, 4(s2)
  sw t0, 8(s2)
  sw t1, 12(s2)
  
  lw ra, 20(sp)
  lw s0, 16(sp)
  lw s1, 12(sp)
  lw s2, 8(sp)
  lw s4, 4(sp)
  lw s5, 0(sp)
  addi sp, sp, 24
  ret

prepare_message:
  addi sp, sp, -8
  sw ra, 4(sp)
  sw s0, 0(sp)
  
  mv s0, a0
  li t0, 56
  bge a1, t0, message_too_long
  
  li t0, 0
copy_loop:
  bge t0, a1, copy_done
  add t1, s0, t0
  lb t1, 0(t1)
  add t2, a2, t0
  sb t1, 0(t2)
  addi t0, t0, 1
  j copy_loop
copy_done:

  add t1, a2, a1
  li t2, 0x80
  sb t2, 0(t1)
  addi t0, a1, 1
  
  li t1, 56
  blt t0, t1, padding_zeros
  
  li t1, 64
  sub t2, t1, t0
  add t3, a2, t0
  
zero_first_block:
  beqz t2, set_length
  sb zero, 0(t3)
  addi t3, t3, 1
  addi t2, t2, -1
  j zero_first_block
  
padding_zeros:
  li t1, 56
  sub t2, t1, t0
  add t3, a2, t0
  
zero_pad_loop:
  beqz t2, set_length
  sb zero, 0(t3)
  addi t3, t3, 1
  addi t2, t2, -1
  j zero_pad_loop
  
set_length:
  slli t0, a1, 3       
  addi t1, a2, 56      
  
  sb t0, 0(t1)
  srli t0, t0, 8
  sb t0, 1(t1)
  srli t0, t0, 8
  sb t0, 2(t1)
  srli t0, t0, 8
  sb t0, 3(t1)
  
  sb zero, 4(t1)
  sb zero, 5(t1)
  sb zero, 6(t1)
  sb zero, 7(t1)
  
  li t0, 0
byte_to_word_loop:
  li t1, 16
  bge t0, t1, prepare_done
  
  slli t1, t0, 2
  add t1, t1, a2
  lbu t2, 0(t1)
  lbu t3, 1(t1)
  lbu t4, 2(t1)
  lbu t5, 3(t1)
  
  slli t3, t3, 8
  slli t4, t4, 16
  slli t5, t5, 24
  or t2, t2, t3
  or t2, t2, t4
  or t2, t2, t5
  
  sw t2, 0(t1)
  
  addi t0, t0, 1
  j byte_to_word_loop
  
message_too_long:
  li a1, 55
  j copy_loop
  
prepare_done:
  lw ra, 4(sp)
  lw s0, 0(sp)
  addi sp, sp, 8
  ret

.globl print_message_digest
print_message_digest:
  addi sp, sp, -8
  sw ra, 4(sp)
  sw s0, 0(sp)
  
  mv s0, a0    
  li t0, 0    
  
print_loop:
  li t1, 16
  bge t0, t1, print_done
  
  add t1, s0, t0
  lbu t1, 0(t1)
  
  srli t2, t1, 4
  andi t3, t1, 0xf
  
  li t4, 10
  blt t2, t4, high_digit
  addi t2, t2, 87    
  j print_high
high_digit:
  addi t2, t2, 48    
print_high:
  li a0, 11
  mv a1, t2
  ecall
  
  li t4, 10
  blt t3, t4, low_digit
  addi t3, t3, 87  
  j print_low
low_digit:
  addi t3, t3, 48    
print_low:
  li a0, 11
  mv a1, t3
  ecall
  
  addi t0, t0, 1
  j print_loop
  
print_done:
  lw ra, 4(sp)
  lw s0, 0(sp)
  addi sp, sp, 8
  ret
