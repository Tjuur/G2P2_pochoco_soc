.text
.globl _start

.equ SPI_BASE, 0x80010000
.equ ACCEL_BASE, 0x80020000

_start:
    li x5, SPI_BASE
    li x6, ACCEL_BASE

    li x9, 0
    li x11, 0
    li x15, 0
    li x12, 0

    sw x0, 8(x5)

main_loop:
wait_price:
    lw x7, 0(x5)
    andi x7, x7, 1
    beq x7, x0, wait_price

    lw x8, 4(x5)
    sw x8, 0(x6)


    # x9: estado
    # 0 = sin posicion
    # 1 = compra pendiente
    # 2 = posicion abierta

    li x7, 1
    bne x9, x7, check_cooldown

    # Registrar precio de ejecucion estimado
    addi x11, x8, 0
    li x15, 0
    li x9, 2

check_cooldown:
    # x12: contador cooldown
    beq x12, x0, read_signals
    addi x12, x12, -1

read_signals:
    lw x13, 12(x6)
    andi x7, x13, 1
    beq x7, x0, hold

    li x7, 2
    beq x9, x7, check_sell

check_buy:
    bne x12, x0, hold

    andi x7, x13, 2
    beq x7, x0, hold

    li x14, 0x7F
    li x9, 1
    j write_decision

check_sell:
    # Incrementar permanencia hasta 32
    li x7, 32
    bge x15, x7, evaluate_sell
    addi x15, x15, 1

evaluate_sell:
    # Stop-loss: price <= entry - 16
    addi x7, x11, -16
    bge x7, x8, stop_loss

    # Requiere señal alcista
    andi x7, x13, 4
    beq x7, x0, hold

    # Si lleva 32 ticks, vender
    li x7, 32
    bge x15, x7, sell

    # Ganancia minima: price >= entry + 2
    addi x7, x11, 2
    blt x8, x7, hold

sell:
    li x14, 0xBF
    li x9, 0
    j write_decision

stop_loss:
    li x12, 16
    j sell

hold:
    li x14, 0

write_decision:
    sw x14, 8(x5)
    j main_loop
