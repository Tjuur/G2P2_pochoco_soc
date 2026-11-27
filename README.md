# Proyecto 4 — Pochoco Trader

## V24-T

**Universidad:** Universidad de los Andes  
**Asignatura:** Arquitectura de Computadores  
**Grupo:** 2  
**Procesador:** Espino Core (RV32E)  
**Plataforma:** Go Board — Lattice iCE40 HX1K  
**Frecuencia de operación:** 25 MHz

## 1. Descripción

Pochoco Trader es un agente de inversión automatizado que recibe
precios mediante SPI, analiza su comportamiento y genera órdenes
de compra, venta o mantención.

La versión final, V24-T, combina dos estrategias de inversión
mediante un selector dinámico basado en su desempeño y en las
condiciones del mercado.

Toda la lógica de predicción, contabilidad y decisión se ejecuta
en assembly sobre Espino Core.

## 2. Algoritmo

V24-T utiliza dos motores de decisión:

### P12 — Reversión a la media

Busca oportunidades de compra después de caídas de precio,
utilizando la diferencia entre el precio actual y el recibido
ocho ticks antes.

Incorpora:

- Stop loss.
- Trailing stop.
- Períodos de bloqueo después de pérdidas.
- Evaluación virtual de rentabilidad.
- Presupuesto acumulado de pérdidas.

P12 debe demostrar rentabilidad virtual antes de ser habilitado
para operar con el patrimonio real.

### V17 — Seguimiento de tendencias

Clasifica el comportamiento del mercado utilizando diferencias
de precio a 8 y 64 ticks, además de máximos, mínimos y precios
de cierre de bloques de 128 ticks.

Identifica tendencias alcistas, bajistas y laterales, y utiliza
señales de recuperación y ruptura para determinar oportunidades.

### Selector V24-T

Selecciona entre ambos motores según sus señales y el estado
del patrimonio.

Incluye trailing stops dinámicos para proteger ganancias de P12
y deshabilita permanentemente dicho motor durante la ronda
cuando se alcanza su presupuesto de pérdidas.

El presupuesto no garantiza una pérdida máxima efectiva,
debido a la ejecución diferida de las órdenes.

Las órdenes solicitan hasta 63 acciones. La cantidad realmente
ejecutada está limitada por el patrimonio disponible, la comisión
y las acciones mantenidas.

## 3. Arquitectura

El sistema conserva Espino Core como procesador principal.

```text
FPGA maestra
     |
     | SPI
     v
Pochoco SPI Slave
     |
     | MMIO
     v
Espino Core RV32E
     |         |
     v         v
    ROM       RAM
```

| Componente | Capacidad |
|---|---:|
| ROM de instrucciones | 1024 palabras de 32 bits |
| RAM de datos | 256 palabras de 32 bits |
| Programa | 772 instrucciones |
| Registros | 16 de 32 bits |
| Historial circular | 64 precios |
| Frecuencia | 25 MHz |

La separación de ROM y RAM permite implementar un algoritmo
más complejo sin superar los recursos físicos de la FPGA.

La versión final no utiliza el acelerador de precios anterior.
Espino realiza todos los cálculos del algoritmo.

Las operaciones de multiplicación, división y desplazamiento
se resuelven mediante instrucciones soportadas por el procesador,
incluyendo sumas, operaciones lógicas y comparaciones.

## 4. Protocolo SPI

- Modo 0: CPOL = 0, CPHA = 0.
- Palabras de 8 bits.
- Transmisión MSB-first.
- SCLK máximo de 1 MHz.
- Precios enteros entre 1 y 255.
- Una transacción por tick.

La decisión calculada después del tick n se ejecuta al precio
recibido en el tick n+1.

| Decisión | Byte |
|---|---|
| HOLD | 0x00 |
| BUY 63 | 0x7F |
| SELL 63 | 0xBF |

### Mapa MMIO

Base del periférico SPI: `0x80010000`.

| Offset | Registro |
|---|---|
| 0x00 | Estado |
| 0x04 | Precio recibido |
| 0x08 | Decisión |

## 5. Contabilidad

El agente mantiene una copia local de la contabilidad oficial:

- Caja inicial: 10000.
- Acciones iniciales: 0.
- Comisión: 5 por orden ejecutada.
- Máximo de 63 acciones por orden.
- Compras parciales cuando el efectivo es insuficiente.
- Sin ventas en corto.
- Sin endeudamiento.

El patrimonio se calcula como:

```text
Patrimonio = Caja + Acciones * Precio
```

Los portfolios virtuales se utilizan exclusivamente para
evaluar señales. No representan operaciones reales.

## 6. Estructura del repositorio

```text
rtl/
    espino_core/
    pochoco_soc.v
    pochoco_v24_mem.v

sw/
    trade.s
    trade.hex
    v24/
        reference_port.c
        isa_check.c
        build_firmware.sh
        manifest.json

sim/
    v24_acceptance/
        reference.py
        acceptance.py
        check_isa.py
        tb_v24_acceptance.sv
        tb_v24_mem.sv
        run_rtl.sh
        synth_v24.sh
        results/

docs/
    README_pre_v24.md
```

El directorio `results/` original conserva evidencia de
implementaciones anteriores.

## 7. Herramientas requeridas

- Python 3.9 o posterior.
- Compilador C.
- GNU RISC-V Toolchain.
- Icarus Verilog.
- Yosys.
- NextPNR iCE40.
- IceStorm: icepack e iceprog.

El modelo de referencia Python utiliza únicamente la biblioteca
estándar.

## 8. Ensamblaje del firmware

Desde la raíz del repositorio:

```bash
bash sw/v24/build_firmware.sh
```

Este script ensambla `sw/trade.s` utilizando RV32E e ILP32E
y verifica que el resultado coincida byte por byte con el
firmware entregado en `sw/trade.hex`.

No reemplaza el firmware validado si encuentra diferencias.

Si la toolchain utiliza otro prefijo:

```bash
PREFIX=riscv64-unknown-elf- bash sw/v24/build_firmware.sh
```

## 9. Modelo de referencia y datos de prueba

La versión de referencia se encuentra en:

```text
sim/v24_acceptance/reference.py
```

La función `candidate()` selecciona la configuración definitiva
V24-T.

Los datos históricos y sintéticos se utilizan exclusivamente
para desarrollo y validación fuera de la FPGA.

No se incorporan series de precios externas al firmware ni
se utiliza información futura durante la toma de decisiones.

### Reproducir META desde un clon limpio

La serie de precios puede recuperarse desde el CSV de evidencia
RTL incluido en el repositorio.

```bash
python3 - <<'PY'
import csv
from pathlib import Path

src = Path("sim/v24_acceptance/results/META_20000_100000_500_7_1.csv")
dst = Path("sim/data/practica_meta.csv")

with src.open() as f:
    rows = list(csv.DictReader(f))

assert len(rows) == 20000
assert all(int(r["tick"]) == i for i, r in enumerate(rows))

dst.parent.mkdir(parents=True, exist_ok=True)

with dst.open("w") as f:
    w = csv.writer(f)
    w.writerow(["tick", "price"])
    w.writerows((r["tick"], r["precio"]) for r in rows)
PY
```

Verificar el código máquina RV32E con META:

```bash
python3 sim/v24_acceptance/check_isa.py --meta-only
```

Generar las decisiones esperadas utilizando Python:

```bash
PYTHONPATH=sim/v24_acceptance python3 - <<'PY'
from pathlib import Path
from acceptance import load, simulate, export, compare

prices = load(Path("sim/data/practica_meta.csv"))
result = simulate(prices)

assert result["wealth"] == 19239

out = Path("build/v24_acceptance")
export(out, "META", result)

compare(
    out / "META/expected.csv",
    Path("sim/v24_acceptance/results/META_20000_100000_500_7_1.csv")
)
PY
```

### Validación extendida

Con los datasets históricos y sintéticos disponibles localmente:

```bash
python3 sim/v24_acceptance/acceptance.py
python3 sim/v24_acceptance/check_isa.py
```

La validación extendida requiere:

- `sim/data/practica_meta.csv`
- 48 series históricas bajo `sim/data/pochoco_v16/`
- 3 series sintéticas bajo `sim/data/pochoco_tests_20000/`

Estos datasets adicionales no forman parte del firmware
ni se incluyen en el repositorio principal.

## 10. Simulación RTL

Prueba inicial:

```bash
bash sim/v24_acceptance/run_rtl.sh smoke
```

Validación completa de META y pruebas adicionales:

```bash
bash sim/v24_acceptance/run_rtl.sh quick
```

Pruebas extendidas, con todos los datasets disponibles:

```bash
bash sim/v24_acceptance/run_rtl.sh full
bash sim/v24_acceptance/run_rtl.sh all
```

Las últimas dos modalidades requieren tiempos de simulación
considerablemente mayores.

El testbench verifica:

- Protocolo SPI.
- Ausencia de bits indefinidos en MISO.
- Lectura de cada precio.
- Escritura de cada decisión.
- Equivalencia con la referencia Python.
- Contabilidad interna.
- Cumplimiento de deadlines.
- Reinicio del algoritmo.
- IC, ciclos, CPI y tiempo de procesamiento.

La memoria ROM/RAM cuenta además con un testbench independiente.

## 11. Resultados financieros

Serie oficial META de 20000 ticks.

| Métrica | No operar | Buy & Hold | V24-T |
|---|---:|---:|---:|
| Patrimonio inicial | 10000 | 10000 | 10000 |
| Patrimonio final | 10000 | 9695 | 19239 |
| Rentabilidad | 0% | -3.05% | +92.39% |
| Órdenes | 0 | 1 | 76 |
| Comisiones | 0 | 5 | 380 |
| Drawdown absoluto máximo | 0 | 9300 | 3815 |
| Drawdown relativo máximo | 0% | 60.41% | 23.97% |

Buy & Hold solicita 63 acciones al comienzo y adquiere
60 al precio del segundo tick, respetando la comisión y
el efectivo disponible.

La versión final reproduce exactamente las decisiones de
Python sobre los 20000 ticks de META en simulación RTL.

## 12. Resultados de rendimiento

Mediciones sobre RTL real de Espino, utilizando META completa
con un período de 100 microsegundos.

| Métrica | Resultado |
|---|---:|
| IC promedio | 229.4485 |
| IC máximo | 411 |
| Ciclos promedio | 537.8539 |
| Ciclos máximos | 927 |
| CPI agregado | 2.344116 |
| Tiempo promedio | 21.514 us |
| Tiempo máximo | 37.080 us |
| Deadlines incumplidos | 0 |
| Diferencias respecto a Python | 0 |

El presupuesto bruto de la ronda más exigente es de 2500 ciclos.

El peor caso observado consume 927 ciclos de procesamiento,
equivalentes al 37.08% del período total, sin contabilizar
por separado el tiempo de transmisión SPI.

## 13. Recursos FPGA

Resultados de síntesis y Place & Route:

| Recurso | Utilización |
|---|---:|
| LUTs de cuatro entradas | 817 |
| Celdas lógicas | 899 / 1280 |
| Ocupación lógica | 70.23% |
| BRAM | 14 / 16 |
| Ocupación BRAM | 87.50% |
| Fmax post-route | 48.37 MHz |
| Frecuencia de operación | 25 MHz |
| Timing | PASS |

La implementación cumple las restricciones físicas de la
Go Board y el objetivo de frecuencia.

## 14. Síntesis y generación del bitstream

```bash
bash sim/v24_acceptance/synth_v24.sh
```

El script utiliza Yosys, NextPNR e Icepack, verifica los hashes
del código validado y genera:

```text
build/v24_acceptance/synth/game_top.bin
```

No programa automáticamente la FPGA.

SHA-256 del bitstream de competición validado:

```text
a063fe8ad4c216156cd6e904e856f45d44e3470c4339ed96da907b958c79f2aa
```

Una nueva síntesis con diferentes versiones de herramientas
puede generar un bitstream con otro hash.

## 15. Programación de la FPGA

Conectar la Go Board por USB y ejecutar:

```bash
iceprog build/v24_acceptance/synth/game_top.bin
```

La programación del bitstream de competición fue realizada
exitosamente, obteniendo:

```text
VERIFY OK
cdone: high
```

No ejecutar `make` sin especificar un objetivo, ya que puede
programar automáticamente la FPGA.

## 16. Reinicio entre rondas

El sistema utiliza un contador de power-on reset de
250000 ciclos, equivalente aproximadamente a 10 ms.

El firmware inicializa su memoria, contabilidad y estado
antes de comenzar a recibir precios.

Se requiere reiniciar la FPGA entre rondas para asegurar
que la caja, las acciones y el estado del algoritmo coincidan
con la contabilidad oficial.

Se recomienda dejar al menos 11 ms desde el encendido
antes de comenzar las transacciones SPI.

## 17. Validación adicional

V24-T fue evaluado mediante Python y emulación funcional RV32E:

- Serie oficial META.
- 48 ventanas históricas.
- 3 series sintéticas.
- 10 escenarios de stress.
- 1240000 ticks verificados.

Resultados sobre las 48 ventanas históricas:

| Métrica | Resultado |
|---|---:|
| Rentabilidad promedio | +16.29% |
| Rentabilidad mediana | +12.71% |
| Series positivas | 34 / 48 |
| Mejor rentabilidad | +101.18% |
| Peor rentabilidad | -18.23% |
| Drawdown relativo promedio | 20.42% |

Las ventanas históricas fueron utilizadas durante el
desarrollo, por lo que no constituyen un conjunto de
validación completamente independiente.

## 18. Evidencia experimental

Los resultados de la implementación definitiva se encuentran en:

```text
sim/v24_acceptance/results/
```

Incluyen las decisiones y contabilidad de los 20000 ticks
de META, las métricas RTL y los reportes de síntesis
y Place & Route.

## 19. Co-diseño hardware/software

Durante el desarrollo se implementaron versiones de software
y aceleradores de historial, diferencias de precio y umbrales.

La documentación de estas versiones anteriores se conserva en
[README_pre_v24.md](docs/README_pre_v24.md).

La arquitectura seleccionada para la competencia utiliza
V24-T con memorias separadas y sin acelerador de trading.

Esta implementación prioriza la calidad del algoritmo,
el cumplimiento de deadlines y la utilización eficiente
de recursos físicos.

Las comparaciones anteriores corresponden a otra estrategia.
No constituyen una comparación controlada de aceleradores
ejecutando V24-T.

## 20. Limitaciones

- La rentabilidad depende del comportamiento del mercado.
- Los resultados históricos no garantizan ganancias futuras.
- Las pruebas RTL completas corresponden a META.
- Las 62 series fueron verificadas funcionalmente en RV32E,
  no todas mediante simulación RTL.
- La programación física fue exitosa, pero la comunicación
  con la FPGA maestra física todavía requiere validación.
- Se asume un reinicio de la placa entre rondas.
- La comparación de dos alternativas hardware sobre V24-T
  y el análisis completo de Amdahl y roofline están pendientes.

## 21. Referencias

- Enunciado Proyecto 4 — Arquitectura de Computadores.
- Repositorio original Pochoco SoC.
- Especificación RISC-V RV32E.
- Documentación de Yosys, NextPNR e IceStorm.
- Documentación de Nandland Go Board.

## 22. Versiones de herramientas

```text
Python 3.13.2
Apple clang version 21.0.0 (clang-2100.1.1.101)
GNU assembler (GNU Binutils) 2.47.20260726
GNU ld (GNU Binutils) 2.47.20260726
Icarus Verilog version 13.0 (stable) (v13_0)
Yosys 0.70+post (git sha1 0c11ea098be065e585a90a06e7b7da49936cf231, Release, AppleClang clang++ 21.0.0.21000334)
"nextpnr-ice40" -- Next Generation Place and Route (Version )
icarus-verilog 13.0
icestorm 1.1_1
nextpnr-ice40 0.11.1_2
riscv64-elf-binutils 2.47
yosys 0.70
```
