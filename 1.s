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

hex_chars: .asciiz "0123456789abcdef"
buffer: .space 64
padding: .byte 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
         .byte    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
         .byte    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
         .byte    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

  .text

  .globl md5
md5:
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
  
  mv s0, a0
  mv s1, a1
  mv s2, a2
  
  la t0, initial_buffer
  lw s3, 0(t0)
  lw s4, 4(t0)
  lw s5, 8(t0)
  lw s6, 12(t0)
  
  la s7, buffer
  
  addi t0, s1, 9
  li t1, 64
  addi t0, t0, 63
  div t0, t0, t1
  mv s8, t0
  
  li s9, 0
  li s10, 0
  
process_blocks:
  beq s9, s8, md5_done
  
  li t0, 0
  li t1, 64
clear_buffer:
  sb zero, 0(s7)
  addi s7, s7, 1
  addi t0, t0, 1
  bne t0, t1, clear_buffer
  la s7, buffer
  
  bge s10, s1, padding_block
  
  sub t0, s1, s10
  li t1, 64
  min t0, t0, t1
  
  mv t1, s0
  add t1, t1, s10
  mv t2, s7
  li t3, 0
copy_data:
  beq t3, t0, copy_done
  lb t4, 0(t1)
  sb t4, 0(t2)
  addi t1, t1, 1
  addi t2, t2, 1
  addi t3, t3, 1
  j copy_data
  
copy_done:
  add s10, s10, t0
  
  bne s10, s1, process_block
  
  add t0, s7, t0
  li t1, 0x80
  sb t1, 0(t0)
  
  addi t0, t0, 1
  sub t1, s7, t0
  addi t1, t1, 64
  li t2, 8
  bge t1, t2, add_length
  j process_block
  
padding_block:
  addi t0, s8, -1
  bne s9, t0, process_block
  
  slli t0, s1, 3
  addi t1, s7, 56
  sw t0, 0(t1)
  sw zero, 4(t1)
  
add_length:
  slli t0, s1, 3
  addi t1, s7, 56
  sw t0, 0(t1)
  sw zero, 4(t1)
  
process_block:
  mv t0, s3
  mv t1, s4
  mv t2, s5
  mv t3, s6
  
  li s11, 0
  
md5_loop:
  li t4, 64
  bge s11, t4, md5_loop_done
  
  li t4, 16
  bge s11, t4, check_second_round
  
  and t4, s4, s5
  not t5, s4
  and t5, t5, s6
  or t4, t4, t5
  
  mv t5, s11
  j process_round
  
check_second_round:
  li t4, 32
  bge s11, t4, check_third_round
  
  and t4, s4, s6
  not t5, s6
  and t5, s5, t5
  or t4, t4, t5
  
  li t5, 5
  mul t5, t5, s11
  addi t5, t5, 1
  li t6, 16
  rem t5, t5, t6
  j process_round
  
check_third_round:
  li t4, 48
  bge s11, t4, fourth_round
  
  xor t4, s4, s5
  xor t4, t4, s6
  
  li t5, 3
  mul t5, t5, s11
  addi t5, t5, 5
  li t6, 16
  rem t5, t5, t6
  j process_round
  
fourth_round:
  not t4, s6
  or t4, s4, t4
  xor t4, s5, t4
  
  li t5, 7
  mul t5, t5, s11
  li t6, 16
  rem t5, t5, t6
  
process_round:
  la t6, K
  slli t0, s11, 2
  add t6, t6, t0
  lw t6, 0(t6)
  
  la t0, S
  slli t1, s11, 2
  add t0, t0, t1
  lw t0, 0(t0)
  
  slli t1, t5, 2
  add t1, s7, t1
  lw t1, 0(t1)
  
  add t4, t4, s3
  add t4, t4, t6
  add t4, t4, t1
  
  sll t1, t4, t0
  li t2, 32
  sub t2, t2, t0
  srl t0, t4, t2
  or t4, t1, t0
  
  add t4, t4, s4
  mv s3, s6
  mv s6, s5
  mv s5, s4
  mv s4, t4
  
  addi s11, s11, 1
  j md5_loop
  
md5_loop_done:
  add s3, s3, t0
  add s4, s4, t1
  add s5, s5, t2
  add s6, s6, t3
  
  addi s9, s9, 1
  j process_blocks
  
md5_done:
  sw s3, 0(s2)
  sw s4, 4(s2)
  sw s5, 8(s2)
  sw s6, 12(s2)
  
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

  .globl print_message_digest
print_message_digest:
  addi sp, sp, -32
  sw ra, 28(sp)
  sw s0, 24(sp)
  sw s1, 20(sp)
  sw s2, 16(sp)
  sw s3, 12(sp)
  sw s4, 8(sp)
  
  mv s0, a0
  li s1, 0
  la s3, hex_chars
  
print_digest_loop:
  li t0, 16
  beq s1, t0, print_digest_done
  
  add t1, s0, s1
  lb s2, 0(t1)
  
  srli t2, s2, 4
  andi t2, t2, 0xF
  add t3, s3, t2
  lb a0, 0(t3)
  
  li a7, 11
  ecall
  
  andi t2, s2, 0xF
  add t3, s3, t2
  lb a0, 0(t3)
  
  li a7, 11
  ecall
  
  addi s1, s1, 1
  j print_digest_loop
  
print_digest_done:
  li a0, 10
  li a7, 11
  ecall
  
  lw ra, 28(sp)
  lw s0, 24(sp)
  lw s1, 20(sp)
  lw s2, 16(sp)
  lw s3, 12(sp)
  lw s4, 8(sp)
  addi sp, sp, 32
  
  ret
