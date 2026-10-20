.text
.globl _start

.equ LEDS, 0x80000004

_start:
    li x5, LEDS
    li x6, 15
    sw x6, 0(x5)

loop:
    addi x6, x6, -1
    bne x6, x0, loop

    li x6, 0
    sw x6, 0(x5)

end:
    j end
