.section .text
.globl _start
_start:
    lui  t0, 0x80000
    sw   zero, 0x100(t0)
    addi t1, zero, 0x80
    sb   t1, 0x101(t0)
    lb   t2, 0x101(t0)
    sw   t2, 0x104(t0)
    addi t3, zero, 0x7f
    sb   t3, 0x102(t0)
    lb   t4, 0x102(t0)
    sw   t4, 0x108(t0)
end:
    beq  zero, zero, end
