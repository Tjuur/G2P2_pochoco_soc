.text
.globl _start

.equ SPI_BASE, 0x80010000
.equ ACCEL_BASE, 0x80020000

_start:
    li x5, SPI_BASE
    li x6, ACCEL_BASE
    li x10, 0
    li x11, 0

    sw x0, 8(x5)

main_loop:
wait_price:
    lw x7, 0(x5)
    andi x7, x7, 1
    beq x7, x0, wait_price

    lw x8, 4(x5)

    sw x8, 0(x6)
    lw x14, 4(x6)

    li x12, 0

    li x15, 8
    blt x11, x15, warming_up

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
