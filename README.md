# Proyecto 2 — Juego de Reflejos en RISC-V

**Asignatura:** Arquitectura de Computadores  
**Plataforma:** Lattice iCE40 HX1K — Go Board  
**Procesador:** Espino Core (RV32E)  
**Sistema:** Pochoco SoC

## 1. Descripción del proyecto

Este proyecto implementa un juego de reflejos en una FPGA Go Board mediante el procesador RISC-V Espino Core y el sistema Pochoco SoC.

El jugador debe presionar el botón correspondiente al LED que se enciende. El sistema mide el tiempo de reacción, registra diez respuestas correctas y muestra su promedio.

El juego está programado en Assembly RISC-V. Además, se desarrolló un assembler propio en Python que genera el archivo hexadecimal utilizado para inicializar la memoria del procesador.

## 2. Funcionamiento del juego

1. Al comenzar cada ronda, se encienden los cuatro LEDs durante al menos tres segundos.
2. Una vez transcurrida la espera y liberados los botones, se selecciona un LED mediante el estado del contador de ciclos.
3. Los otros LEDs se apagan y comienza la medición del tiempo de reacción.
4. El usuario presiona el botón correspondiente.

**Si la respuesta es correcta:**

- Se calcula y muestra el tiempo de reacción en decisegundos.
- Se incrementa el contador de respuestas correctas.
- El tiempo permanece visible mientras el botón está presionado.
- Al soltarlo, comienza la siguiente ronda.

**Si la respuesta es incorrecta:**

- Los LEDs se apagan y los displays muestran `EE`.
- La respuesta no se contabiliza.
- Al soltar el botón, se reinicia la ronda sin perder el progreso anterior.

Al completar **10 respuestas correctas**, los LEDs se apagan y los displays muestran el promedio de los tiempos. El programa permanece en ese estado hasta reiniciar la placa.

## 3. Arquitectura

| Componente | Función |
|---|---|
| Espino Core | Ejecuta el programa RISC-V. |
| Pochoco SoC | Integra procesador, RAM y periféricos. |
| Pochoco RAM | Almacena las instrucciones generadas por el assembler. |
| Pochoco Periph | Controla LEDs, botones y displays mediante MMIO. |
| Cycle Counter | Cuenta ciclos de reloj para medir intervalos. |
| Game Top | Conecta el SoC con las señales físicas de la Go Board. |

El banco de registros del procesador utiliza **16 registros** (`x0` a `x15`), correspondientes a RV32E. El juego no requiere multiplicación, división ni instrucciones de desplazamiento.

En esta configuración, la memoria dispone de **512 palabras de 32 bits** para el programa. El archivo `sw/game.hex` generado contiene **87 instrucciones**.

## 4. Periféricos mediante MMIO

Los periféricos se acceden mediante direcciones de memoria (*Memory-Mapped I/O*):

| Dirección | Periférico | Operación |
|---|---|---|
| `0x80000000` | Displays de siete segmentos | Escritura |
| `0x80000004` | LEDs | Escritura |
| `0x80000008` | Botones | Lectura |
| `0x8000000C` | Contador de ciclos | Lectura |

### LEDs y botones

Los cuatro bits menos significativos representan los cuatro LEDs o botones:

| Máscara | Elemento |
|---|---|
| `0x1` | LED/botón 1 |
| `0x2` | LED/botón 2 |
| `0x4` | LED/botón 3 |
| `0x8` | LED/botón 4 |
| `0xF` | Cuatro LEDs encendidos |

La respuesta es correcta solo cuando la máscara de botones leída coincide exactamente con la máscara del LED seleccionado.

### Displays

Cada display recibe un dígito hexadecimal de cuatro bits. Para representar un número decimal de dos cifras se convierte a dígitos empaquetados: por ejemplo, para mostrar `25` se escribe `0x25`, no el valor binario decimal 25 (`0x19`).

## 5. Medición del tiempo

El contador de ciclos es un registro de **32 bits** que se incrementa en cada ciclo del reloj del sistema. El programa consulta su valor mediante MMIO.

La implementación utiliza una frecuencia nominal de **25 MHz**:

- **1 segundo:** 25.000.000 ciclos.
- **3 segundos:** 75.000.000 ciclos.
- **1 decisegundo:** 2.500.000 ciclos.

El tiempo transcurrido se obtiene restando dos lecturas del contador:

```text
ciclos_transcurridos = contador_final - contador_inicial
```

El tiempo en decisegundos se calcula mediante:

```text
tiempo_ds = piso(ciclos_transcurridos / 2.500.000)
```

Como el juego no utiliza una instrucción de división, la conversión se realiza mediante restas sucesivas. Para mostrar el resultado, se convierte a dos dígitos decimales. Los valores superiores a `99` se limitan a `99` **solo para la visualización**.

La resta de lecturas permite calcular intervalos cortos incluso si el contador pasa por cero. A 25 MHz, el contador de 32 bits se desborda aproximadamente cada 171,8 segundos.

**Nota de precisión:** las pruebas con cronómetro fueron manuales; no constituyen una calibración instrumental de la frecuencia ni de la precisión temporal.

## 6. Selección del LED

El programa utiliza los dos bits menos significativos del contador de ciclos:

```asm
lw x8, 12(x5)
andi x8, x8, 3
```

El valor obtenido está entre 0 y 3 y se transforma en una máscara (`1`, `2`, `4` u `8`). Así se evita utilizar una lista fija de LEDs. La selección depende del instante de lectura del contador y no constituye un generador aleatorio criptográfico.

## 7. Assembler propio en Python

El assembler se encuentra en `tools/assembler.py` y traduce el código fuente `sw/game.s` a palabras de máquina de 32 bits.

Utiliza **dos pasadas**:

1. Identifica constantes y etiquetas, calcula direcciones y contempla la expansión de pseudoinstrucciones como `li`.
2. Codifica instrucciones, resuelve desplazamientos de saltos y escribe el archivo hexadecimal.

Admite las siguientes instrucciones:

| Categoría | Instrucciones |
|---|---|
| Aritméticas | `add`, `sub`, `addi`, `slt`, `sltu` |
| Lógicas | `and`, `or`, `xor`, `andi`, `ori`, `xori`, `slti`, `sltiu` |
| Memoria | `lw`, `sw`, `lb`, `lh`, `lbu`, `lhu`, `sb`, `sh` |
| Branches | `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` |
| Saltos | `jal`, `jalr` |
| Inmediatos superiores | `lui`, `auipc` |
| Pseudoinstrucciones | `li`, `mv`, `j`, `nop`, `ret` |

El assembler valida los registros RV32E (`x0` a `x15`), los rangos de inmediatos y el tamaño máximo del programa. Las instrucciones no reconocidas producen un error explícito.

**Generación del programa:**

```bash
python3 tools/assembler.py sw/game.s sw/game.hex
```

**Verificación del tamaño:**

```bash
wc -l sw/game.hex
```

También se incluye un programa de prueba del assembler en `tests/test.s`, con su salida `tests/test.hex`.

## 8. Compilación y programación de la FPGA

### Herramientas

- Python 3
- Yosys
- NextPNR para iCE40
- IceStorm (`icepack`, `iceprog`)
- Make

### Procedimiento

Desde la raíz del repositorio:

**1. Generar las instrucciones del juego:**

```bash
python3 tools/assembler.py sw/game.s sw/game.hex
```

**2. Limpiar los archivos de compilación anteriores:**

```bash
make clean
```

**3. Sintetizar y ejecutar Place & Route:**

```bash
make game_top.asc
```

**4. Generar el bitstream:**

```bash
make game_top.bin
```

**5. Programar la placa conectada por USB:**

```bash
make prog
```

El Makefile utiliza `game_top` como módulo superior y `iceprog` para programar la placa.

**Importante:** al modificar `sw/game.s`, hay que regenerar `sw/game.hex` y reconstruir el bitstream. El Makefile actual no declara `game.hex` como dependencia de síntesis; por eso se recomienda ejecutar `make clean` antes de recompilar.

## 9. Pruebas realizadas

Las pruebas funcionales se ejecutaron sobre la Go Board.

| Prueba | Resultado observado |
|---|---|
| 10 respuestas correctas consecutivas | Se muestra el promedio final. |
| 3 errores iniciales y luego 10 aciertos | Los errores no se cuentan y se muestra el promedio. |
| 2 errores, 5 aciertos, 2 errores y 5 aciertos | Se conserva el progreso y se muestra el promedio. |
| Mantener un botón durante el inicio | El juego espera el tiempo inicial y la liberación del botón. |
| Mantener presionado el botón después de acertar | El tiempo permanece visible y no se registra otro acierto. |
| Mantener un botón entre rondas | La selección del siguiente LED espera la liberación del botón. |
| Comparación manual con cronómetro | Diferencias aproximadas de 350–450 ms, compatibles con el inicio manual del cronómetro; no es una calibración precisa. |
| Dos botones simultáneos | La comparación de máscaras indica error por inspección del código; no se realizó prueba física controlada. |

## 10. Utilización de recursos

La síntesis y el proceso de Place & Route finalizaron correctamente:

| Recurso | Utilización |
|---|---|
| ICESTORM_LC | 1175 / 1280 (91%) |
| ICESTORM_RAM | 12 / 16 (75%) |
| SB_IO | 27 / 72 (37%) |
| SB_GB | 3 / 8 (37%) |

## 11. Estructura del repositorio

```text
G2P2_pochoco_soc/
├── Makefile
├── goboard.pcf
├── README.md
├── rtl/
│   ├── game_top.v
│   ├── cycle_counter.v
│   ├── pochoco_soc.v
│   ├── pochoco_ram.v
│   ├── pochoco_periph.v
│   ├── pochoco_spi_slave.v
│   └── espino_core/
│       └── ...
├── sw/
│   ├── game.s
│   ├── game.hex
│   └── ...
├── tools/
│   └── assembler.py
└── tests/
    ├── test.s
    └── test.hex
```

## 12. Limitaciones y consideraciones

- La resolución de visualización es de un decisegundo.
- Los displays muestran valores entre `00` y `99`.
- Los tiempos superiores a 99 decisegundos se saturan para su presentación.
- La selección del LED utiliza el estado del contador, no un PRNG independiente.
- La división se realiza mediante restas sucesivas.
- La medición depende de la frecuencia efectiva del reloj de la placa.
- El contador de 32 bits se desborda periódicamente.
- La partida finaliza después de diez aciertos y requiere reiniciar la placa para comenzar otra.

## 13. Conclusión

Se implementó un juego de reflejos funcional en Assembly RISC-V sobre Espino Core y Pochoco SoC, utilizando los periféricos físicos de la Go Board. El proyecto integra software de bajo nivel, acceso a periféricos mediante MMIO, un contador de ciclos incorporado al hardware y un assembler propio en Python. Las pruebas realizadas confirmaron el funcionamiento de las rondas, la recuperación frente a errores, el manejo de botones mantenidos y la presentación del promedio final.
