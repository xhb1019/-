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

hex_digits:
  .ascii "0123456789abcdef"

  .align 4
padded_message:
  .space 1024

.text

  .globl md5
md5:
  addi sp, sp, -48
  sw ra, 0(sp)
  sw s0, 4(sp)
  sw s1, 8(sp)
  sw s2, 12(sp)
  sw s3, 16(sp)
  sw s4, 20(sp)
  sw s5, 24(sp)
  sw s6, 28(sp)
  sw s7, 32(sp)
  sw s8, 36(sp)
  sw s9, 40(sp)
  sw s10, 44(sp)

  mv s0, a0
  mv s1, a1
  mv s2, a2

  jal ra, pad_message

  la t0, initial_buffer
  lw s3, 0(t0)
  lw s4, 4(t0)
  lw s5, 8(t0)
  lw s6, 12(t0)

  la s7, padded_message
  li s8, 0
  
  add t0, s1, 8
  addi t0, t0, 1
  li t1, 64
  div t2, t0, t1
  rem t3, t0, t1
  beqz t3, no_extra_block
  addi t2, t2, 1
no_extra_block:
  mv s9, t2

process_blocks_loop:
  beq s8, s9, md5_done
  
  mv s10, s3
  mv t1, s4
  mv t2, s5
  mv t3, s6

  li t4, 0

md5_operation_loop:
  li t5, 16
  bge t4, t5, round2_check
  
  mv t5, s4
  and t5, t5, s5
  not t6, s4
  and t6, t6, s6
  or t5, t5, t6
  j compute_operation

round2_check:
  li t5, 32
  bge t4, t5, round3_check
  
  mv t5, s4
  and t5, t5, s6
  not t6, s6
  and t6, t6, s5
  or t5, t5, t6
  j compute_operation

round3_check:
  li t5, 48
  bge t4, t5, round4_operations
  
  mv t5, s4
  xor t5, t5, s5
  xor t5, t5, s6
  j compute_operation

round4_operations:
  not t6, s6
  or t5, s4, t6
  xor t5, s5, t5

compute_operation:
  li t6, 16
  bge t4, t6, get_mi_round2
  
  mv t6, t4
  j got_mi_index
  
get_mi_round2:
  li t6, 32
  bge t4, t6, get_mi_round3
  
  li t6, 5
  mul t6, t6, t4
  addi t6, t6, 1
  li t7, 16
  rem t6, t6, t7
  j got_mi_index
  
get_mi_round3:
  li t6, 48
  bge t4, t6, get_mi_round4
  
  li t6, 3
  mul t6, t6, t4
  addi t6, t6, 5
  li t7, 16
  rem t6, t6, t7
  j got_mi_index
  
get_mi_round4:
  li t6, 7
  mul t6, t6, t4
  li t7, 16
  rem t6, t6, t7

got_mi_index:
  slli t6, t6, 2
  add t6, s7, t6
  add t6, t6, s8
  slli t7, s8, 6
  add t6, t6, t7
  lw t7, 0(t6)
  
  la t6, K
  slli t8, t4, 2
  add t6, t6, t8
  lw t8, 0(t6)
  
  la t6, S
  slli t9, t4, 2
  add t6, t6, t9
  lw t9, 0(t6)
  
  add t5, t5, s3
  add t5, t5, t7
  add t5, t5, t8
  
  sll t6, t5, t9
  li t8, 32
  sub t7, t8, t9
  srl t7, t5, t7
  or t5, t6, t7
  
  add t5, t5, s4
  mv s3, s6
  mv s6, s5
  mv s5, s4
  mv s4, t5
  
  addi t4, t4, 1
  li t5, 64
  bne t4, t5, md5_operation_loop

  add s3, s3, s10
  add s4, s4, t1
  add s5, s5, t2
  add s6, s6, t3
  
  addi s8, s8, 1
  j process_blocks_loop

md5_done:
  sw s3, 0(s2)
  sw s4, 4(s2)
  sw s5, 8(s2)
  sw s6, 12(s2)
  
  lw ra, 0(sp)
  lw s0, 4(sp)
  lw s1, 8(sp)
  lw s2, 12(sp)
  lw s3, 16(sp)
  lw s4, 20(sp)
  lw s5, 24(sp)
  lw s6, 28(sp)
  lw s7, 32(sp)
  lw s8, 36(sp)
  lw s9, 40(sp)
  lw s10, 44(sp)
  addi sp, sp, 48
  ret

pad_message:
  la t0, padded_message
  mv t1, s0
  mv t2, s1
  li t3, 0

copy_message_loop:
  beq t3, t2, copy_done
  lbu t4, 0(t1)
  sb t4, 0(t0)
  addi t0, t0, 1
  addi t1, t1, 1
  addi t3, t3, 1
  j copy_message_loop

copy_done:
  li t4, 0x80
  sb t4, 0(t0)
  addi t0, t0, 1
  addi t3, t3, 1
  
  li t4, 56
  li t5, 64
  rem t6, t3, t5
  sub t6, t4, t6
  bgez t6, add_zeros
  add t6, t6, t5

add_zeros:
  beqz t6, zeros_done
  sb zero, 0(t0)
  addi t0, t0, 1
  addi t3, t3, 1
  addi t6, t6, -1
  j add_zeros

zeros_done:
  slli t4, s1, 3
  sb t4, 0(t0)
  srli t5, t4, 8
  sb t5, 1(t0)
  srli t5, t4, 16
  sb t5, 2(t0)
  srli t5, t4, 24
  sb t5, 3(t0)
  sb zero, 4(t0)
  sb zero, 5(t0)
  sb zero, 6(t0)
  sb zero, 7(t0)
  addi t0, t0, 8
  addi t3, t3, 8
  
  ret

  .globl print_message_digest
print_message_digest:
  addi sp, sp, -8
  sw ra, 0(sp)
  sw s0, 4(sp)
  
  mv s0, a0
  
  li t0, 16
  li t1, 0

print_byte_loop:
  beq t1, t0, print_done
  
  add t2, s0, t1
  lbu t3, 0(t2)
  
  srli t4, t3, 4
  andi t5, t3, 0xF
  
  la t6, hex_digits
  add t4, t6, t4
  add t5, t6, t5
  
  lbu t4, 0(t4)
  lbu t5, 0(t5)
  
  li a0, 11
  mv a1, t4
  ecall
  
  li a0, 11
  mv a1, t5
  ecall

  addi t1, t1, 1
  j print_byte_loop

print_done:
  lw ra, 0(sp)
  lw s0, 4(sp)
  addi sp, sp, 8
  ret
