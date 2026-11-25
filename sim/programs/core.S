    .option norvc
    .option norelax
    .section .text
    .globl _start

    .macro expect reg, value
    li      t6, \value
    bne     \reg, t6, fail
    .endm

_start:
    lui     s0, 0x80001
    addi    zero, zero, 7
    expect  zero, 0
    addi    a0, zero, -7
    addi    a1, a0, 10
    add     a2, a0, a1
    expect  a2, -4
    and     a3, a2, a1
    expect  a3, 0
    andi    a3, a2, 15
    expect  a3, 12
    or      a4, a1, a3
    expect  a4, 15
    ori     a4, a4, 16
    expect  a4, 31
    xor     a5, a4, a3
    expect  a5, 19
    slli    a5, a1, 31
    srli    a5, a5, 31
    expect  a5, 1
    sltu    a5, a1, a0
    expect  a5, 1

    addi    a6, zero, 9
    sw      a4, 0(s0)
    addi    a6, a6, 1       # WB producer leaves while this consumer waits for MEM.
    expect  a6, 10
    lw      a6, 0(s0)
    add     a7, a6, a1
    sw      a7, 4(s0)
    expect  a7, 34
    li      a6, 0x80
    sb      a6, 5(s0)
    lb      a7, 5(s0)
    expect  a7, -128
    lw      a7, 4(s0)
    expect  a7, 0x8022

    li      t0, 0
    li      t1, 31
    .word   0x286293b3       # sbset t2,t0,t1
    expect  t2, 0x80000000
    li      t1, 63
    .word   0x486393b3       # sbclr t2,t2,t1
    .word   0x60039413       # clz s0,t2
    expect  s0, 32
    li      t1, 32
    .word   0x286393b3       # sbset t2,t2,t1
    .word   0x60039493       # clz s1,t2
    expect  s1, 31
    li      t1, 0
    .word   0x486393b3       # sbclr t2,t2,t1
    expect  t2, 0
    lui     t2, 0x80000
    .word   0x60039493       # clz s1,t2
    expect  s1, 0
    lui     s0, 0x80001

    beq     a1, zero, fail
    beq     a1, a1, 1f
    sw      a1, 12(s0)
    addi    a3, zero, 1
1:
    expect  a3, 12
    bne     a1, zero, 2f
    sw      a1, 12(s0)
2:
    jal     ra, subroutine
3:
    lla     t0, 3b
    bne     ra, t0, fail
    lla     t0, indirect
    addi    t0, t0, 1
    jalr    a2, 0(t0)
4:
    sw      a1, 12(s0)
    j       fail

subroutine:
    jalr    zero, 0(ra)
    sw      a1, 12(s0)

indirect:
    lla     t0, 4b
    bne     a2, t0, fail
    lw      t0, 12(s0)
    bne     t0, zero, fail
    li      t0, 0x123
    sw      t0, 8(s0)
    j       .

fail:
    lui     s0, 0x80001
    li      t0, 0xBAD
    sw      t0, 8(s0)
    j       .
