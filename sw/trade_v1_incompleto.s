.text
.globl _start

.equ SPI_STATUS, 0x80010000

_start:
    li x5, SPI_STATUS
    li x6, 0
    sw x6, 8(x5)

    li x9, 0
    li x10, 0

    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0

main_loop:
wait_price:
    lw x7, 0(x5)
    andi x7, x7, 1
    beq x7, x0, wait_price

    lw x8, 4(x5)

    addi x9, x9, 1

    li x6, 0

    li x7, 9
    blt x9, x7, update_history

    sub x7, x8, x11

    beq x10, x0, check_buy

check_sell:
    li x6, 4
    blt x7, x6, update_history

    li x6, 191
    li x10, 0
    j update_history

check_buy:
    li x6, -4
    blt x6, x7, update_history

    li x6, 127
    li x10, 1

update_history:
    mv x11, x12
    mv x12, x13
    mv x13, x14
    mv x14, x15
    mv x15, x8

    sw x6, 8(x5)
    j main_loop
