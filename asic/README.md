# Proyecto 3 — Implementación ASIC del SoC Pochoco

Implementación del SoC Pochoco mediante LibreLane y la tecnología GF180MCU.

El proyecto estudia dos arquitecturas de memoria, su síntesis, implementación
física, temporización, optimización y verificación funcional.

## 1. Herramientas y entorno

- LibreLane: 3.0.17
- PDK: GF180MCU (`gf180mcuD`)
- Revisión del PDK: `54435919abffb937387ec956209f9cf5fd2dfbee`
- Biblioteca de celdas estándar: `gf180mcu_fd_sc_mcu7t5v0`
- Yosys
- OpenROAD
- Icarus Verilog
- Python 3
- Docker

El flujo se ejecutó utilizando LibreLane mediante Docker.

El módulo superior del diseño es `asic_top`.

## 2. Arquitecturas de memoria

### Arquitectura A

Utiliza memorias separadas:

- ROM combinacional de instrucciones.
- RAM de datos de 64 palabras de 32 bits.

La ROM contiene el programa ensamblado del juego.

### Arquitectura B

Utiliza una memoria unificada de 128 palabras de 32 bits,
implementada mediante flip-flops.

Ambas arquitecturas utilizan el mismo procesador y periféricos.

## 3. Configuración

Configuración base:

- Período de reloj: 100 ns.
- Frecuencia de reloj: 10 MHz.
- Utilización objetivo: 40 %.
- Top: `asic_top`.

Configuraciones disponibles:

| Archivo | Propósito |
|---|---|
| `config/config_A.json` | Arquitectura A original |
| `config/config_B.json` | Arquitectura B |
| `config/config_A_hierarchical.json` | Análisis jerárquico |
| `config/config_A_util30.json` | Utilización objetivo 30 % |
| `config/config_A_util50.json` | Utilización objetivo 50 % |
| `config/config_A_timing_80.json` | Período de 80 ns |
| `config/config_A_timing_60.json` | Período de 60 ns |
| `config/config_A_optimized.json` | Experimento de optimización RTL |
| `config/config_A_optimized_antenna.json` | Implementación A optimizada final |
| `config/config_A_test.json` | Síntesis para verificación funcional |

## 4. Generación del programa y memorias

Desde la raíz del repositorio:

```bash
python3 tools/assembler.py sw/game.s sw/game.hex \
  --rom asic/rtl/memory/game_rom.v

python3 asic/scripts/generate_unified_memory.py
```

El programa definitivo utiliza los siguientes valores:

- Tres segundos: 30 000 000 ciclos.
- Una décima de segundo: 1 000 000 ciclos.

Estos valores corresponden a un reloj de 10 MHz.

## 5. Reproducción de la síntesis

Arquitectura A:

```bash
librelane --dockerized --pdk gf180mcuD \
  --flow classic --run-tag architecture_A \
  --to Yosys.Synthesis asic/config/config_A.json
```

Arquitectura B:

```bash
librelane --dockerized --pdk gf180mcuD \
  --flow classic --run-tag architecture_B \
  --to Yosys.Synthesis asic/config/config_B.json
```

## 6. Reproducción de la implementación física

Arquitectura A original:

```bash
librelane --dockerized --pdk gf180mcuD \
  --flow classic --run-tag physical_A \
  asic/config/config_A.json
```

Arquitectura B:

```bash
librelane --dockerized --pdk gf180mcuD \
  --flow classic --run-tag physical_B \
  asic/config/config_B.json
```

Arquitectura A optimizada final:

```bash
librelane --dockerized --pdk gf180mcuD \
  --flow classic --run-tag architecture_A_optimized_antenna \
  asic/config/config_A_optimized_antenna.json
```

Los archivos intermedios se generan en `asic/config/runs/`
y no se incluyen en el repositorio.

## 7. Comparación de arquitecturas

Resultados de las implementaciones originales:

| Métrica | Arquitectura A | Arquitectura B |
|---|---:|---:|
| Celdas sintetizadas | 10693 | 22121 |
| Flip-flops | 2851 | 4901 |
| Área de síntesis (um²) | 365107.86 | 688796.68 |
| Área del die (um²) | 955993 | 1781200 |
| Peor setup WNS (ns) | 28.12 | 18.86 |
| Violaciones de hold | 0 | 0 |
| Errores LVS | 0 | 0 |
| Violaciones de antena reportadas | 0 | 1 |

La arquitectura A presenta menor área y mayor margen temporal.

La arquitectura B conserva una violación de antena reportada
en la implementación final. Su evidencia está disponible en
`reports/antenna_B/`.

Los resultados detallados están disponibles en:

- `reports/physical_comparison.csv`
- `reports/top5_standard_cells.csv`

## 8. Experimento de utilización

Se implementó la arquitectura A con tres objetivos de utilización:

| Objetivo | Área del die (um²) | Violaciones de antena |
|---|---:|---:|
| 30 % | 1266870 | 1 |
| 40 % | 955993 | 0 |
| 50 % | 768917 | 0 |

Las tres implementaciones completaron el flujo físico
sin errores Magic DRC ni LVS.

La evidencia se encuentra en:

- `reports/utilization_comparison.csv`
- `reports/utilization/utilization_vs_area.png`
- `reports/utilization/utilization_vs_cost.png`
- `reports/utilization/utilization_vs_timing.png`
- `reports/utilization/utilization_vs_violations.png`

El costo estimado del área se calculó utilizando
23 000 USD/mm².

## 9. Experimento de timing

Se evaluaron tres períodos de reloj:

| Período (ns) | Setup WNS slow (ns) | Setup TNS slow (ns) |
|---|---:|---:|
| 100 | 28.119 | 0 |
| 80 | 8.119 | 0 |
| 60 | -11.881 | -4373 |

La configuración de 60 ns presenta violaciones de setup.

Los resultados completos, incluyendo las esquinas typical
y las comprobaciones de hold, están disponibles en:

- `reports/timing_sweep.csv`

La ruta crítica original está documentada en:

- `reports/critical_path/baseline_A_100ns.rpt`

Esta ruta conecta lógica de lectura de instrucciones
con el registro de lectura de periféricos.

## 10. Optimización RTL

Se evaluó una implementación segmentada del contador
de ciclos de 32 bits.

Resultados de síntesis:

- Contador original: 3714.28 um².
- Contador segmentado: 3813.06 um².

La alternativa incrementó el área aproximadamente 2.66 %,
por lo que se conservó el contador original.

Posteriormente se optimizó la lógica de lectura de
periféricos en `rtl/pochoco_periph.v`.

Se reemplazó la selección mediante `case` por una
implementación de selección y combinación mediante
máscaras de bits.

La equivalencia lógica de esta modificación se verificó
mediante Yosys.

Comparación física entre la arquitectura A original
y la versión optimizada:

| Métrica | Original | Optimizada |
|---|---:|---:|
| Área de celdas (um²) | 464441 | 465747 |
| Área del die (um²) | 955993 | 958919 |
| Setup WNS slow (ns) | 28.119 | 39.410 |
| Setup TNS (ns) | 0 | 0 |
| Errores Magic DRC | 0 | 0 |
| Errores LVS | 0 | 0 |
| Violaciones de antena | 0 | 0 |

La optimización mejoró el setup WNS en aproximadamente
11.291 ns, con un aumento del área de celdas del 0.28 %.

Evidencia:

- `reports/optimization_comparison.csv`
- `reports/optimization/`
- `verification/check_periph_equiv.sh`

## 11. Verificación funcional

Se realizaron pruebas RTL de ambas arquitecturas.

También se verificó la equivalencia del contador original
y su alternativa segmentada durante 100000 ciclos.

Para la arquitectura A se realizó una comparación funcional
entre simulación RTL y simulación gate-level post-síntesis.

Se utilizó un programa de prueba acelerado de 85 instrucciones,
con un período de reloj de 100 ns.

Eventos verificados:

| Evento | Ciclo RTL | Ciclo gate-level |
|---|---:|---:|
| Arranque | 20 | 20 |
| Primera selección | 146 | 146 |
| Pulsación correcta | 146 | 146 |
| Avance correcto | 210 | 210 |
| Segunda selección | 335 | 335 |
| Pulsación incorrecta | 335 | 335 |
| Reinicio por error | 365 | 365 |

Todos los eventos coincidieron exactamente.

La prueba cubre las secuencias indicadas, pero no
constituye una verificación exhaustiva de todas las
instrucciones y situaciones posibles.

Tampoco corresponde a una simulación con retardos
de propagación extraídos del layout.

Evidencia:

- `verification/verification_results.txt`
- `verification/tb_compare.v`
- `verification/game_rom_test.v`
- `verification/rtl_results.log`
- `verification/gate_results.log`

## 12. Implementación física y signoff

La arquitectura A optimizada completó el flujo físico
de LibreLane.

Resultados reportados:

- Errores de ruteo DRC: 0.
- Errores Magic DRC: 0.
- Errores LVS: 0.
- Violaciones de antena: 0.
- Setup TNS: 0.
- Hold WNS positivo.

La ejecución independiente de KLayout DRC no se realizó.

Las advertencias de slew y capacitancia observadas en
los reportes deben considerarse al evaluar el cierre físico.

## 13. Trazabilidad física

Se analizaron las posiciones de celdas del diseño final
mediante el netlist y el DEF.

Resultados:

- Register File: 480 flip-flops localizados.
- Contador de ciclos: 32 flip-flops localizados.
- Pines: 30 posiciones extraídas del DEF.

Evidencia:

- `reports/layout/register_file_coordinates.csv`
- `reports/layout/cycle_counter_coordinates.csv`
- `reports/layout/pin_coordinates.csv`
- `reports/layout/register_file_distribution.png`
- `reports/layout/cycle_counter_distribution.png`
- `reports/layout/asic_component_locations.png`

El script utilizado es:

- `scripts/locate_registers.py`

### Limitación: localización física de la ALU

La ALU está identificada en el RTL como la instancia
`u_alu` del módulo `espino_alu`.

Durante la síntesis, Yosys aplanó y optimizó la lógica,
eliminando la identificación jerárquica de la ALU
en el netlist final.

El flujo no fue configurado para preservar explícitamente
la trazabilidad física de este bloque.

Se investigaron conexiones entre registros, multiplexores
y puertas aritméticas, pero no fue posible identificar
con suficiente certeza el conjunto de celdas que
implementa la ALU en el layout final.

Por tanto, no se declara una ubicación física verificada
para la ALU.

Los gráficos de distribución de celdas se generaron
a partir de coordenadas del DEF. No constituyen
capturas directas del layout desde KLayout u OpenROAD GUI.

## 14. Layouts entregados

- `gds/architecture_A.gds`: implementación A optimizada final.
- `gds/architecture_B.gds`: implementación B original.

El GDS de la arquitectura A corresponde a la ejecución
`architecture_A_optimized_antenna`.

Las comparaciones originales A/B utilizan las métricas
de las ejecuciones `physical_A` y `physical_B`.

Los archivos GDSII pueden inspeccionarse con un
visualizador compatible.

## 15. Organización de la evidencia

- `config/`: configuraciones de LibreLane.
- `rtl/`: módulos RTL adaptados para ASIC.
- `scripts/`: generación de memoria y análisis físico.
- `tb/`: testbenches.
- `reports/`: métricas, comparaciones y gráficos.
- `verification/`: evidencia de verificación funcional.
- `gds/`: layouts finales.

Los archivos intermedios de LibreLane no se incluyen
en Git debido a su tamaño.

