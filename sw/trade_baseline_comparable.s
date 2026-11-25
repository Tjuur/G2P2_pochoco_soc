.text
.globl _start

.equ SPI_BASE, 0x80010000
.equ HISTORY_BASE, 0x1E0

_start:
    li x5, SPI_BASE
    li x6, HISTORY_BASE

    li x9, 0
    li x10, 0
    li x11, 0

    sw x0, 8(x5)

main_loop:
wait_price:
    lw x7, 0(x5)
    andi x7, x7, 1
    beq x7, x0, wait_price

    lw x8, 4(x5)

    li x12, 0

    add x13, x9, x9
    add x13, x13, x13
    add x13, x13, x6

    lw x14, 0(x13)

    sw x8, 0(x13)

    addi x9, x9, 1
    andi x9, x9, 7

    li x15, 8
    blt x11, x15, warming_up

    sub x14, x8, x14

    beq x10, x0, check_buy

check_sell:
    li x15, 4
    blt x14, x15, write_decision

    li x12, 191
    li x10, 0
    j write_decision

check_buy:
    li x15, -4
    blt x15, x14, write_decision

    li x12, 127
    li x10, 1
    j write_decision

warming_up:
    addi x11, x11, 1

write_decision:
    sw x12, 8(x5)
    j main_loop
