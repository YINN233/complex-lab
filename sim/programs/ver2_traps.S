    .option norvc
    .option norelax
    .text
    .globl _start, VER2_EBREAK, VER2_ILLEGAL, VER2_ILLEGAL_PC

_start:
VER2_EBREAK:
    lui     t0, 0x80400
    li      t1, 0x135
    sw      t1, 0x120(t0)
    ebreak
    sw      zero, 0x120(t0)  # Younger store must be squashed.

VER2_ILLEGAL:
    lui     t0, 0x80400
    li      t1, 0x246
    sw      t1, 0x124(t0)
VER2_ILLEGAL_PC:
    .word   0x0000007b       # Unimplemented custom-3 opcode.
    sw      zero, 0x124(t0)  # Younger store must be squashed.
1:
    j       1b
