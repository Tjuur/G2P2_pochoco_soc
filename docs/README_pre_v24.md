# Proyecto 4 — Pochoco Trader

**Asignatura:** Arquitectura de Computadores
**Plataforma:** Lattice iCE40 HX1K — Go Board
**Procesador:** Espino Core (RV32E)
**Sistema:** Pochoco SoC
**Frecuencia objetivo:** 25 MHz

## 1. Descripción

Pochoco Trader es un sistema de trading automatizado implementado mediante codiseño hardware/software.

El procesador Espino recibe precios mediante SPI, ejecuta una estrategia de trading y genera decisiones de compra, venta o espera.

Se implementaron tres arquitecturas para evaluar el impacto de trasladar operaciones desde software hacia hardware:

1. Implementación completamente software.
2. Acelerador de historial y diferencia de precios.
3. Acelerador de historial, diferencia y evaluación de umbrales.

El procesador Espino mantiene la responsabilidad de generar la decisión final.

## 2. Arquitectura

El sistema está compuesto por:

- Espino Core RV32E.
- Memoria RAM de 128 palabras de 32 bits.
- Periférico SPI.
- Acelerador de precios conectado mediante MMIO.
- Firmware RISC-V Assembly.

Flujo de procesamiento:

```text
SPI → Pochoco SoC → Espino → Acelerador → Espino → SPI
```

El acelerador no sustituye al procesador: únicamente realiza operaciones específicas de la estrategia.

## 3. Protocolo SPI

La comunicación utiliza SPI modo 0, con palabras de 8 bits transmitidas MSB-first.

La frecuencia máxima especificada es de 1 MHz.

Cada precio recibido corresponde a un valor entero entre 1 y 255.

La decisión generada utiliza el siguiente formato:

| Bits | Significado |
|---|---|
| 7:6 | Acción |
| 5:0 | Cantidad |

Acciones:

| Bits | Acción |
|---|---|
| 00 | HOLD |
| 01 | BUY |
| 10 | SELL |

La cantidad máxima por orden es 63.

La decisión calculada después del tick n se aplica en el tick n+1.

## 4. Mapa de memoria MMIO

### Periférico SPI

Base: `0x80010000`

| Offset | Registro |
|---|---|
| 0x00 | Estado |
| 0x04 | Precio recibido |
| 0x08 | Decisión |

### Acelerador

Base: `0x80020000`

| Offset | Registro |
|---|---|
| 0x00 | Escritura del precio |
| 0x04 | Diferencia de precios (acelerador 1) |
| 0x08 | Historial listo (acelerador 1) |
| 0x0C | Flags de decisión (acelerador 2) |

Los flags del acelerador 2 son:

| Bit | Significado |
|---|---|
| 0 | Historial válido |
| 1 | Diferencia <= -4 |
| 2 | Diferencia >= 4 |

## 5. Estrategia de trading

Se utiliza una estrategia de reversión basada en la diferencia entre el precio actual y el precio recibido ocho ticks antes.

```text
delta = precio_actual - precio_hace_8_ticks
```

Reglas:

- Durante los primeros ocho ticks: HOLD.
- Si no existe una posición abierta y delta <= -4: BUY 63.
- Si existe una posición abierta y delta >= 4: SELL 63.
- En cualquier otro caso: HOLD.

El firmware controla el estado de la posición.

Las decisiones se codifican como:

| Decisión | Valor |
|---|---|
| HOLD | 0x00 |
| BUY 63 | 0x7F |
| SELL 63 | 0xBF |

El simulador financiero aplica las restricciones de capital, disponibilidad de acciones y comisión.

## 6. Implementaciones

### Software

Archivo: `sw/trade_baseline_comparable.s`

El procesador mantiene el historial circular en RAM, calcula la diferencia y evalúa los umbrales.

El historial ocupa ocho palabras desde la dirección `0x1E0`.

### Acelerador 1

Firmware: `sw/trade_accel1.s`

RTL: `rtl/pochoco_price_accel_v1.v.bak`

El hardware almacena el historial y calcula la diferencia de precios.

Espino interpreta el resultado y determina la decisión.

### Acelerador 2

Firmware: `sw/trade.s`

RTL: `rtl/pochoco_price_accel.v`

El hardware mantiene el historial, calcula la diferencia y evalúa los umbrales.

Espino consulta los flags, controla la posición y escribe la decisión final.

Esta es la arquitectura seleccionada para la implementación principal.

## 7. Compilación del firmware

Se requiere una toolchain RISC-V con:

- `riscv64-elf-as`
- `riscv64-elf-ld`
- `riscv64-elf-objcopy`

Para generar los tres programas:

```bash
make -C sw trade_baseline_comparable
make -C sw trade_accel1
make -C sw trade
```

Los programas utilizan RV32E y ABI ILP32E.

No requieren instrucciones de multiplicación, división ni desplazamiento.

## 8. Simulación

Se requiere Icarus Verilog y el modelo de primitivas iCE40 de Yosys.

El testbench principal está en:

```text
sim/tb_proyecto_4.sv
```

Para ejecutar la arquitectura final:

```bash
iverilog -g2012 \
  -s tb_proyecto_4 \
  -o build/tb_p4 \
  /opt/homebrew/share/yosys/ice40/cells_sim.v \
  sim/tb_proyecto_4.sv \
  rtl/*.v \
  rtl/espino_core/*.v

vvp build/tb_p4
```

La ruta de `cells_sim.v` depende de la instalación de Yosys.

El testbench permite verificar la recepción de precios, generación de decisiones, ausencia de valores desconocidos y cumplimiento del plazo de respuesta.

## 9. Pruebas unitarias

El testbench unitario está en:

```text
tb/tb_price_accel.sv
```

Acelerador 1:

```bash
iverilog -g2012 \
  -s tb_price_accel \
  -Ptb_price_accel.VERSION=1 \
  -o build/tb_price_accel_v1.vvp \
  tb/tb_price_accel.sv \
  rtl/pochoco_price_accel_v1.v.bak

vvp build/tb_price_accel_v1.vvp
```

Acelerador 2:

```bash
iverilog -g2012 \
  -s tb_price_accel \
  -Ptb_price_accel.VERSION=2 \
  -o build/tb_price_accel_v2.vvp \
  tb/tb_price_accel.sv \
  rtl/pochoco_price_accel.v

vvp build/tb_price_accel_v2.vvp
```

Ambas implementaciones aprobaron cinco verificaciones funcionales.

## 10. Verificación Python

La referencia de decisiones está implementada en:

```text
trading/verify.py
```

Después de ejecutar la simulación completa:

```bash
python3 trading/verify.py
```

El programa compara las decisiones generadas por Espino con las decisiones calculadas en Python.

La simulación completa de 20.000 ticks del acelerador 2 produjo cero diferencias respecto a la referencia.

## 11. Resultados de rendimiento

Comparación con 2.000 ticks, frecuencia de 25 MHz e instrumentación homogénea:

| Métrica | Software | Acelerador 1 | Acelerador 2 |
|---|---:|---:|---:|
| Ciclos/tick | 45.094 | 33.099 | 33.084 |
| Instrucciones/tick | 20.203 | 14.208 | 14.198 |
| Latencia máxima (ciclos) | 54 | 43 | 41 |
| Speedup | 1.000x | 1.362x | 1.363x |

El acelerador 2 reduce aproximadamente un 26,6 % los ciclos de procesamiento respecto al software.

## 12. Recursos FPGA

Resultados de síntesis y Place & Route con firmware correspondiente a cada arquitectura:

| Recurso | Software | Acelerador 1 | Acelerador 2 |
|---|---:|---:|---:|
| Logic Cells | 1035 | 1243 | 1215 |
| BRAM | 8 | 8 | 8 |
| Fmax | 43.47 MHz | 44.37 MHz | 41.43 MHz |

Las tres implementaciones cumplen la frecuencia objetivo de 25 MHz.

Los resultados y bitstreams se encuentran en:

```text
results/synthesis/final/
```

## 13. Resultados financieros

En la simulación completa de 20.000 ticks del acelerador 2:

| Métrica | Resultado |
|---|---:|
| Patrimonio inicial | 10000 |
| Patrimonio final | 16584 |
| Órdenes ejecutadas | 183 |
| Máxima pérdida desde un máximo | 4802 |
| No operar | 10000 |
| Comprar y mantener | 9695 |

La simulación considera una comisión de 5 unidades monetarias por operación ejecutada.

## 14. Generación del bitstream

Herramientas:

- Yosys.
- NextPNR iCE40.
- IceStorm.

El Makefile principal permite sintetizar, realizar Place & Route y generar el bitstream:

```bash
make game_top.bin
```

Para programar una Go Board conectada:

```bash
make prog
```

**Advertencia:** `make prog` programa físicamente la FPGA.

La arquitectura final utiliza `sw/trade.hex`.

Los bitstreams de las tres arquitecturas se encuentran en:

```text
results/synthesis/final/
```

La generación del bitstream y el cumplimiento de timing fueron verificados. La prueba física de trading mediante SPI en la placa no está documentada como completada.

## 15. Limitaciones

- La estrategia utiliza un historial fijo de ocho precios.
- La comparación de rendimiento se realizó mediante simulación RTL.
- El throughput sostenido depende del período de llegada de los precios.
- Los testbenches unitarios cubren los casos funcionales básicos, pero no constituyen verificación exhaustiva.
- No se ha documentado una validación física completa del protocolo SPI en la FPGA.
- Los modelos analíticos de rendimiento deben distinguirse de las mediciones experimentales.

## 16. Documentación anterior

El README del Proyecto 2 se conserva en:

```text
docs/README_proyecto_2.md
```

El informe anterior se encuentra en:

```text
docs/informe_G2_P2.pdf
```
