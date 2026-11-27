.text
.globl _start

.equ SPI_BASE, 0x80010000
.equ ACCEL_BASE, 0x80020000

_start:
    li x5, SPI_BASE
    li x6, ACCEL_BASE

    li x9, 0

    sw x0, 8(x5)

main_loop:
wait_price:
    lw x7, 0(x5)
    andi x7, x7, 1
    beq x7, x0, wait_price

    lw x8, 4(x5)
    sw x8, 0(x6)

    lw x12, 12(x6)

    andi x13, x12, 1
    beq x13, x0, hold

    beq x9, x0, check_buy

check_sell:
    andi x13, x12, 4
    beq x13, x0, hold

    li x14, 0xBF
    li x9, 0
    j write_decision

check_buy:
    andi x13, x12, 2
    beq x13, x0, hold

    li x14, 0x7F
    li x9, 1
    j write_decision

hold:
    li x14, 0

write_decision:
    sw x14, 8(x5)
    j main_loop
