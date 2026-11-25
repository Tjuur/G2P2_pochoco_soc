.text
.globl _start

.equ SPI_BASE, 0x80010000
.equ ACCEL_BASE, 0x80020000

_start:
    li x5, SPI_BASE
    li x6, ACCEL_BASE

    sw x0, 8(x5)

main_loop:
wait_price:
    lw x7, 0(x5)
    andi x7, x7, 1
    beq x7, x0, wait_price

    lw x8, 4(x5)

    sw x8, 0(x6)

    lw x12, 12(x6)

    sw x12, 8(x5)

    j main_loop
