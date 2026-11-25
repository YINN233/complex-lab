    .option norvc
    .option norelax
    .text
    .globl _start

_start:
    lui     t5, 0x80400
    li      t0, 0
    li      t1, 31
    .word   0x286293b3       # sbset t2,t0,t1
    sw      t2, 0x100(t5)   # 0x80000000
    li      t1, 63
    .word   0x486393b3       # sbclr t2,t2,t1
    sw      t2, 0x104(t5)   # 0
    .word   0x60039e13       # clz t3,t2
    sw      t3, 0x108(t5)   # 32
    li      t1, 32
    .word   0x286393b3       # sbset t2,t2,t1
    .word   0x60039e13       # clz t3,t2
    sw      t3, 0x10c(t5)   # 31
    ret
