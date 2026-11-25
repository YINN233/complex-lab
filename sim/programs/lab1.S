    .option norvc
    .option norelax
    .text
    .globl _start, LAB1_FIB10, LAB1_FIB60, LAB1_ASCII

_start:
LAB1_FIB10:
    # Store the first ten Fibonacci words at 0x80400000.
    lui     t2, 0x80400
    li      t3, 1
    li      t4, 1
    li      t5, 10
1:
    sw      t3, 0(t2)
    add     t6, t3, t4
    mv      t3, t4
    mv      t4, t6
    addi    t2, t2, 4
    addi    t5, t5, -1
    bne     t5, zero, 1b
    ret

LAB1_FIB60:
    # Compute F60 using two 32-bit halves.
    lui     t2, 0x80400
    li      a1, 1
    li      a2, 0
    li      a3, 1
    li      a4, 0
    li      a5, 58
2:
    add     a6, a1, a3
    sltu    a7, a6, a1
    add     t3, a2, a4
    add     t3, t3, a7
    mv      a1, a3
    mv      a2, a4
    mv      a3, a6
    mv      a4, t3
    addi    a5, a5, -1
    bne     a5, zero, 2b
    sw      a3, 0(t2)
    sw      a4, 4(t2)
    ret

LAB1_ASCII:
    # Send the printable ASCII range using the monitor's MMIO convention.
    lui     t0, 0x10000
    li      a0, 0x21
    li      t4, 0x7f
3:
    lb      t1, 5(t0)
    andi    t1, t1, 0x20
    beq     t1, zero, 3b
    sb      a0, 0(t0)
    addi    a0, a0, 1
    bne     a0, t4, 3b
    ret
