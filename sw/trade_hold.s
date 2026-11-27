.text
.globl _start

# ==========================================
# Proyecto 4 - Pochoco Trader
# Primera versión: mantener siempre
# ==========================================

# Registros SPI
.equ SPI_STATUS,   0x80010000
.equ SPI_PRICE,    0x80010004
.equ SPI_DECISION, 0x80010008

_start:
    # x5 = Dirección base del periférico SPI
    li x5, SPI_STATUS

    # x6 = Decisión (0 = mantener)
    li x6, 0

    # Inicializar DECISION
    sw x6, 8(x5)

main_loop:

    # Esperar hasta recibir un precio nuevo
wait_price:
    lw x7, 0(x5)

    # STATUS bit 0 = nuevo precio disponible
    andi x7, x7, 1

    beq x7, x0, wait_price

    # Leer precio recibido
    lw x8, 4(x5)

    # Escribir decisión: mantener
    sw x6, 8(x5)

    # Repetir
    j main_loop