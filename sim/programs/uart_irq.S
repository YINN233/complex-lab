    .option norvc
    .option norelax
    .text
    .globl _start

_start:
    lui     s1, 0x10000      # UART data, IER and LSR at offsets 0, 1 and 5.
    li      s0, 0            # Number of completed receive interrupts.
    la      t0, uart_handler
    csrw    mtvec, t0
    li      t0, 0x800        # mie.MEIE
    csrw    mie, t0
    csrsi   mstatus, 8       # mstatus.MIE
    lb      t1, 1(s1)
    bne     t1, zero, fail

    li      a0, 'R'
    jal     putc
wait_pending:
    lb      t0, 5(s1)
    andi    t0, t0, 1
    beq     t0, zero, wait_pending
    bne     s0, zero, fail   # RX arrived while IER was off.
    csrr    t0, mip
    li      t1, 0x800
    and     t0, t0, t1
    bne     t0, zero, fail

    li      t0, 1
    sb      t0, 1(s1)
wait_first_irq:
    beq     s0, zero, wait_first_irq
    bne     s0, t0, fail
    lb      t1, 1(s1)
    bne     t0, t1, fail
    li      t1, 'Z'
    bne     t6, t1, fail

    li      a0, 'A'
    jal     putc
wait_second_irq:
    beq     s0, t0, wait_second_irq
    li      t1, 2
    bne     s0, t1, fail
    li      t1, 'm'
    bne     t6, t1, fail
    li      a0, 'P'
    jal     putc
pass:
    j       pass

uart_handler:
    # Mainline leaves t3-t6 reserved for this handler.
    csrr    t3, mcause
    li      t4, 0x8000000b
    bne     t3, t4, fail
    csrr    t3, mip
    li      t4, 0x800
    and     t3, t3, t4
    beq     t3, zero, fail
    lb      t6, 0(s1)
    csrr    t3, mip
    and     t3, t3, t4
    bne     t3, zero, fail
    addi    s0, s0, 1
    mret

fail:
    li      a0, 'F'
    jal     putc
    j       fail

putc:
    lb      t2, 5(s1)
    andi    t2, t2, 0x20
    beq     t2, zero, putc
    sb      a0, 0(s1)
    ret
