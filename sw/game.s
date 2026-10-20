.text
.globl _start

# ============================================================
# Pochoco Reflex Game - RV32E
# ============================================================

# MMIO
.equ DISPLAY, 0x80000000
.equ LEDS,    0x80000004
.equ BUTTONS, 0x80000008
.equ TIMER,   0x8000000C

# Reloj de 25 MHz
.equ THREE_SECONDS, 75000000
.equ DECISECOND,     2500000

# Registros:
# x5  = base MMIO
# x6  = contador de respuestas correctas
# x7  = suma de tiempos en decisegundos
# x8  = tiempo inicial / auxiliar
# x9  = tiempo actual / auxiliar
# x10 = LED y botón esperado
# x11 = botones presionados
# x12 = auxiliar
# x13 = auxiliar
# x14 = auxiliar
# x15 = auxiliar

_start:
    li x5, DISPLAY

    li x6, 0
    li x7, 0

new_round:

    # Apagar display
    sw x0, 0(x5)

    # Encender los cuatro LEDs
    li x8, 15
    sw x8, 4(x5)

    # Registrar inicio de espera
    lw x8, 12(x5)

    li x9, THREE_SECONDS

wait_three_seconds:
    lw x12, 12(x5)
    sub x13, x12, x8

    bltu x13, x9, wait_three_seconds

    # Esperar que no haya botones presionados
wait_release:
    lw x11, 8(x5)
    bne x11, x0, wait_release

    # Elegir LED mediante bits bajos del contador
    lw x8, 12(x5)
    andi x8, x8, 3

    # Convertir índice 0-3 a máscara 1,2,4,8
    li x10, 1
    beq x8, x0, selected

    li x10, 2
    li x12, 1
    beq x8, x12, selected

    li x10, 4
    li x12, 2
    beq x8, x12, selected

    li x10, 8

selected:
    # Encender LED seleccionado
    sw x10, 4(x5)

    # Registrar comienzo de reacción
    lw x8, 12(x5)

wait_button:
    lw x11, 8(x5)

    beq x11, x0, wait_button

    # Registrar tiempo inmediatamente
    lw x9, 12(x5)

    # Comprobar botón correcto
    bne x11, x10, wrong_button

    # Tiempo transcurrido en ciclos
    sub x9, x9, x8

    # Convertir ciclos a decisegundos
    li x12, DECISECOND
    li x13, 0

convert_time:
    bltu x9, x12, time_converted

    sub x9, x9, x12
    addi x13, x13, 1

    j convert_time

time_converted:
    # Acumular tiempo
    add x7, x7, x13

    # Mostrar tiempo (máximo 99)
    li x14, 99
    bltu x14, x13, display_max

    mv x14, x13
    j display_time

display_max:
    li x14, 99

display_time:
    # Convertir decimal a BCD para los displays
    li x15, 0

bcd_loop:
    li x12, 10
    bltu x14, x12, bcd_done

    sub x14, x14, x12
    addi x15, x15, 16

    j bcd_loop

bcd_done:
    add x15, x15, x14
    sw x15, 0(x5)

    # Una respuesta correcta adicional
    addi x6, x6, 1

    # ¿Llegamos a 10?
    li x12, 10
    beq x6, x12, calculate_average

    # Esperar que suelte el botón
release_correct:
    lw x11, 8(x5)
    bne x11, x0, release_correct

    j new_round


# ============================================================
# Botón incorrecto
# ============================================================

wrong_button:
    # Apagar LEDs
    sw x0, 4(x5)

    # Mostrar EE como señal de error
    li x12, 238
    sw x12, 0(x5)

    # Esperar que suelte el botón
release_wrong:
    lw x11, 8(x5)
    bne x11, x0, release_wrong

    # Repetir ronda sin incrementar correctas
    j new_round


# ============================================================
# Promedio final
# ============================================================

calculate_average:
    # Apagar LEDs
    sw x0, 4(x5)

    # Promedio = suma / 10
    # División por restas sucesivas
    li x13, 0
    li x12, 10

average_loop:
    bltu x7, x12, average_done

    sub x7, x7, x12
    addi x13, x13, 1

    j average_loop

average_done:
    # Limitar visualización a 99
    li x14, 99
    bltu x14, x13, average_max

    mv x14, x13
    j average_display

average_max:
    li x14, 99

average_display:
    # Convertir promedio a BCD
    li x15, 0

average_bcd_loop:
    li x12, 10
    bltu x14, x12, average_bcd_done

    sub x14, x14, x12
    addi x15, x15, 16

    j average_bcd_loop

average_bcd_done:
    add x15, x15, x14
    sw x15, 0(x5)

finished:
    j finished
